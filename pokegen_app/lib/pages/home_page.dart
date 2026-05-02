import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/pokemon_models.dart';
import '../services/ai/gemini_service.dart';
import '../services/ai/image_processor.dart';
import '../services/storage_service.dart';
import '../services/pokedex_storage_service.dart';
import '../widgets/home/control_panel.dart';
import '../widgets/home/pokedex_header.dart';
import '../widgets/home/pokedex_screen.dart';
import 'settings_page.dart';
import '../services/settings_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _picker = ImagePicker();
  final List<XFile> _photos = [];
  final _descController = TextEditingController(text: '');

  bool _isGenerating = false;
  final List<Creature> _creatures = [];
  int _currentIndex = 0;

  GeminiService? _geminiService;
  final _storage = StorageService();
  final _pokedexStorage = PokedexStorageService();
  SettingsService? _settingsService;

  @override
  void initState() {
    super.initState();
    _initSettings();
  }

  Future<void> _initSettings() async {
    _settingsService = await SettingsService.init();
    _geminiService = GeminiService.fromSettings(_settingsService!);
    // Restore previously caught creatures from disk
    _loadCreatures();
  }

  /// Load saved creatures from persistent catalog.
  Future<void> _loadCreatures() async {
    final loaded = await _pokedexStorage.loadCreatures();
    if (!mounted) return;
    setState(() {
      _creatures.clear();
      _creatures.addAll(loaded);
      _currentIndex = 0;
    });
  }

  Future<void> _reloadServices() async {
    _settingsService = await SettingsService.init();
    _geminiService = GeminiService.fromSettings(_settingsService!);
  }

  Future<void> _handleAddPhoto() async {
    final imageSource = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (imageSource == null) return;

    final image = await _picker.pickImage(
      source: imageSource,
      preferredCameraDevice: CameraDevice.rear,
      imageQuality: 100,
    );
    if (image != null) {
      setState(() {
        _photos.clear();
        _photos.add(image);
      });
      _handleGenerate();
    }
  }

  Future<void> _handleGenerate() async {
    final description = _descController.text.trim().isEmpty ? 'a real-world animal' : _descController.text.trim();
    if (_photos.isEmpty) {
      _showSnack('Take a photo first!');
      return;
    }
    setState(() {
      _isGenerating = true;
    });

    try {
      final result = await _geminiService!.generateCreature(
        photo: File(_photos.first.path),
        description: description,
      );

      final processedBytes = await processSpriteSheet(result.imageBytes);
      final savedPath = await _storage.savePngBytes(processedBytes);

      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final c = Creature(
        id: id,
        name: result.spec.name,
        primaryType: result.spec.primaryType,
        secondaryType: result.spec.secondaryType,
        stats: result.spec.stats,
        imagePath: savedPath,
        originalPhotoPaths: _photos.map((x) => x.path).toList(),
        createdAt: DateTime.now(),
        flavorText: result.spec.flavorText,
        moves: result.spec.moves,
      );

      setState(() {
        _creatures.insert(0, c);
        _currentIndex = 0;
        _photos.clear();
        _descController.clear();
      });

      // Persist immediately after adding a new creature
      unawaited(_pokedexStorage.saveCreatures(_creatures));
    } catch (e) {
      _showSnack('Generation failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _navigateLeft() {
    if (_creatures.length <= 1) return;
    setState(() {
      _currentIndex = (_currentIndex - 1 + _creatures.length) % _creatures.length;
    });
  }

  void _navigateRight() {
    if (_creatures.length <= 1) return;
    setState(() {
      _currentIndex = (_currentIndex + 1) % _creatures.length;
    });
  }

  void _onKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _navigateLeft();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _navigateRight();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentCreature = _creatures.isNotEmpty ? _creatures[_currentIndex] : null;

    return KeyboardListener(
      onKeyEvent: _onKeyEvent,
      focusNode: FocusNode(),
      child: Scaffold(
        backgroundColor: const Color(0xFFDC0A2D),
        body: SafeArea(
          child: Column(
            children: [
              // Header with lens, title, and settings
              PokedexHeader(
                onSettingsPressed: () async {
                  if (_settingsService != null) {
                    final changed = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => SettingsPage(settings: _settingsService!),
                      ),
                    );
                    if (changed == true) {
                      await _reloadServices();
                    }
                  }
                },
              ),

              // Main screen area
              Expanded(
                child: PokedexScreen(
                  creature: currentCreature,
                  isGenerating: _isGenerating,
                  creatureIndex: _currentIndex,
                  creatureCount: _creatures.length,
                ),
              ),

              // Control panel
              ControlPanel(
                onCapturePressed: _handleAddPhoto,
                onDPadLeft: _navigateLeft,
                onDPadRight: _navigateRight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
