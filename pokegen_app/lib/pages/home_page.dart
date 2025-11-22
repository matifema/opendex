import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../config.dart';
import '../models/pokemon_models.dart';
import '../services/ai/ai_service.dart';
import '../services/ai/google_text_service.dart';
import '../services/ai/http_image_service.dart';
import '../services/ai/human_detected_exception.dart';
import '../services/ai/prompts.dart';
import '../services/storage_service.dart';
import '../widgets/capture_animation.dart';
import '../widgets/sprite_sheet_animation.dart';
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
  Uint8List? _generatedPng;
  final List<Creature> _creatures = [];

  late final AiTextService _textService;
  late final AiImageService _imageService;
  final _storage = StorageService();
  SettingsService? _settingsService;

  @override
  void initState() {
    super.initState();
    _initSettings();
  }

  Future<void> _initSettings() async {
    _settingsService = await SettingsService.init();
    _updateServices();
  }

  void _updateServices() {
    if (_settingsService == null) return;
    setState(() {
      _textService = GoogleTextService(apiKey: _settingsService!.geminiApiKey);
      _imageService = HttpImageService(baseUrl: _settingsService!.apiBaseUrl);
    });
  }

  Future<void> _handleAddPhoto() async {
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
      imageQuality: 100,
    );
    if (image != null) {
      setState(() => _photos.add(image));
    }
  }

  Future<void> _handleGenerate() async {
    final description = _descController.text.trim().isEmpty ? 'a real-world animal' : _descController.text.trim();
    if (_photos.isEmpty) {
      _showSnack('Add at least one photo.');
      return;
    }
    setState(() {
      _isGenerating = true;
      _generatedPng = null;
    });

    try {
      // 1. Safety Check & Stats Generation (Text Model)
      // We do this FIRST to avoid generating an image if it's a human.
      final spec = await _textService.generateNameAndStats(animalDescription: description);

      // 2. Build prompt for the image model
      final prompt = buildImagePrompt(animalDescription: description);

      // 3. Generate pixel-art sprite sheet
      final pngBytes = await _imageService.generateCreatureImage(
        photos: _photos.map((x) => File(x.path)).toList(),
        prompt: prompt,
        size: PixelArtSize.medium,
      );

      // 4. Persist PNG to storage
      final savedPath = await _storage.savePngBytes(pngBytes);

      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final c = Creature(
        id: id,
        name: spec.name,
        primaryType: spec.primaryType,
        secondaryType: spec.secondaryType,
        stats: spec.stats,
        imagePath: savedPath,
        originalPhotoPaths: _photos.map((x) => x.path).toList(),
        createdAt: DateTime.now(),
        flavorText: spec.flavorText,
      );

      setState(() {
        _generatedPng = pngBytes;
        _creatures.insert(0, c); // Add to top
      });
    } on HumanDetectedException catch (e) {
      _showSnack(e.message);
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
    final theme = Theme.of(context);
    final canGenerate = _photos.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet Battler'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              if (_settingsService != null) {
                final changed = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => SettingsPage(settings: _settingsService!),
                  ),
                );
                if (changed == true) {
                  _updateServices();
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.sports_mma),
            tooltip: 'Battle!',
            onPressed: _creatures.length >= 2
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _handleAddPhoto,
        icon: const Icon(Icons.add_a_photo),
        label: const Text('Add Photo'),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              Text(
                'Snap an animal and create a fantasy creature!',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Animal description (e.g., "striped tiger cub")',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.pets),
                ),
              ),
              const SizedBox(height: 12),
              _buildPhotoStrip(),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: canGenerate && !_isGenerating ? _handleGenerate : null,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Generate Creature'),
              ),
              const SizedBox(height: 24),
              if (_generatedPng != null) ...[
                Center(child: SpriteSheetAnimation(imageBytes: _generatedPng!, size: 200)),
                const SizedBox(height: 12),
              ],
              if (_creatures.isNotEmpty) ...[
                Text('Your Creatures (${_creatures.length})', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                ..._creatures.map(_buildCreatureCard),
              ],
              const SizedBox(height: 32),
              _buildEnvHints(),
            ],
          ),
          if (_isGenerating)
            Container(
              color: Colors.black.withValues(alpha: 0.4),
              child: const Center(child: CaptureAnimation(playing: true)),
            ),
        ],
      ),
    );
  }

  Widget _buildPhotoStrip() {
    if (_photos.isEmpty) {
      return const Card(
        child: SizedBox(
          height: 100,
          child: Center(child: Text('No photos yet. Tap "Add Photo" to capture.')),
        ),
      );
    }
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _photos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final x = _photos[i];
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(x.path),
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: InkWell(
                  onTap: () => setState(() => _photos.removeAt(i)),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: const Icon(Icons.close, color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCreatureCard(Creature c) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<Uint8List>(
              future: File(c.imagePath).readAsBytes(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return SpriteSheetAnimation(imageBytes: snapshot.data!, size: 100);
                }
                return const SizedBox(width: 100, height: 100, child: Center(child: CircularProgressIndicator()));
              },
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.name, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    [
                      c.primaryType.name[0].toUpperCase() + c.primaryType.name.substring(1),
                      if (c.secondaryType != null)
                        ' / ${c.secondaryType!.name[0].toUpperCase()}${c.secondaryType!.name.substring(1)}'
                    ].join(),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  if (c.flavorText.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(c.flavorText, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                  const Divider(height: 12),
                  _buildStatsGrid(c.stats),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(CreatureStats s) {
    Text stat(String label, int v) => Text('$label: $v');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        stat('HP', s.hp),
        stat('Attack', s.attack),
        stat('Defense', s.defense),
        stat('Speed', s.speed),
      ],
    );
  }

  Widget _buildEnvHints() {
    if (_settingsService == null) return const SizedBox.shrink();
    final missingKey = _settingsService!.geminiApiKey.isEmpty;
    final missingApi = _settingsService!.apiBaseUrl.isEmpty;
    if (!missingKey && !missingApi) return const SizedBox.shrink();
    return Card(
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Configuration hints'),
            if (missingKey) const Text('• Set Gemini API Key in Settings (top right)'),
            if (missingApi) const Text('• Set API Base URL in Settings (top right)'),
          ],
        ),
      ),
    );
  }
}
