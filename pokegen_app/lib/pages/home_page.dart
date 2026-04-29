import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/pokemon_models.dart';
import '../services/ai/gemini_service.dart';
import '../services/ai/image_processor.dart';
import '../services/storage_service.dart';
import '../widgets/home/control_panel.dart';
import '../widgets/home/info_panel.dart';
import '../widgets/home/pokedex_header.dart';
import '../widgets/home/pokedex_screen.dart';
import 'battle_page.dart';
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

  GeminiService? _geminiService;
  final _storage = StorageService();
  SettingsService? _settingsService;
  
  // UI state
  bool _showStats = false;
  int _gymBadges = 0;
  int _battlesWon = 0;
  int _battlesLost = 0;

  @override
  void initState() {
    super.initState();
    _initSettings();
  }

  Future<void> _initSettings() async {
    _settingsService = await SettingsService.init();
    _geminiService = GeminiService.fromSettings(_settingsService!);
  }

  Future<void> _reloadServices() async {
    _settingsService = await SettingsService.init();
    _geminiService = GeminiService.fromSettings(_settingsService!);
  }

  Future<void> _handleAddPhoto() async {
    // Show dialog to select image source
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
      // Immediately show dialog for description
      _showDescriptionDialog();
    }
  }

  Future<void> _showDescriptionDialog() async {
    final descController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Describe the creature'),
        content: TextField(
          controller: descController,
          decoration: const InputDecoration(
            hintText: 'e.g., "striped tiger cub"',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Generate'),
          ),
        ],
      ),
    );
    
    if (result == true && mounted) {
      _descController.text = descController.text;
      await _handleGenerate();
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

      // Post-process: white→transparent + resize to 128x32
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
        _photos.clear();
        _descController.clear();
      });
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

  @override
  Widget build(BuildContext context) {
    final currentCreature = _creatures.isNotEmpty ? _creatures.first : null;

    return Scaffold(
      backgroundColor: const Color(0xFFDC0A2D), // Pokedex Red
      body: SafeArea(
        child: Column(
          children: [
            // Header with lens and lights
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
              onBattlePressed: _creatures.length >= 2
                  ? () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => BattlePage(
                            player: _creatures[0],
                            opponent: _creatures[1],
                          ),
                        ),
                      );
                    }
                  : () => _showSnack('Generate at least 2 creatures to battle!'),
              canBattle: _creatures.length >= 2,
            ),
            
            // Main screen area
            Expanded(
              child: PokedexScreen(
                creature: currentCreature,
                isGenerating: _isGenerating,
                showStats: _showStats,
                creatureIndex: _creatures.indexOf(currentCreature ?? Creature(
                  id: '',
                  name: '',
                  primaryType: CreatureType.beast,
                  secondaryType: null,
                  stats: const CreatureStats(hp: 0, attack: 0, defense: 0, speed: 0),
                  imagePath: '',
                  originalPhotoPaths: [],
                  createdAt: DateTime.now(),
                  flavorText: '',
                )),
              ),
            ),
            
            // Bottom info panel
            InfoPanel(
              creatureCount: _creatures.length,
              gymBadges: _gymBadges,
              battlesWon: _battlesWon,
              battlesLost: _battlesLost,
            ),
            
            // Control panel with buttons
            ControlPanel(
              onCapturePressed: _handleAddPhoto,
              onDPadUp: () {
                if (_creatures.length > 1) {
                  setState(() {
                    final creature = _creatures.removeAt(0);
                    _creatures.add(creature);
                  });
                }
              },
              onDPadDown: () {
                if (_creatures.length > 1) {
                  setState(() {
                    final creature = _creatures.removeLast();
                    _creatures.insert(0, creature);
                  });
                }
              },
              onDPadLeft: () {},
              onDPadRight: () {},
              onAPressed: () {
                setState(() {
                  _showStats = !_showStats;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}



