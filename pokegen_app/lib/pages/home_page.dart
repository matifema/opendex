import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../config.dart';
import '../models/pokemon_models.dart';
import '../services/ai/ai_service.dart';
import '../services/ai/google_text_service.dart';
import '../services/ai/http_image_service.dart';
import '../services/ai/prompts.dart';
import '../services/storage_service.dart';
import '../widgets/capture_animation.dart';
import '../widgets/pixel_art_preview.dart';

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
  Pokemon? _pokemon;

  late final AiTextService _textService;
  late final AiImageService _imageService;
  final _storage = StorageService();

  @override
  void initState() {
    super.initState();
    _textService = GoogleTextService();
    _imageService = HttpImageService();
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
      _pokemon = null;
    });

    try {
      // Build prompt for the image model
      final prompt = buildImagePrompt(animalDescription: description);

      // Generate pixel-art PNG
      final pngBytes = await _imageService.generatePixelMon(
        photos: _photos.map((x) => File(x.path)).toList(),
        prompt: prompt,
        size: PixelArtSize.medium,
      );

      // Generate name and stats via text model
      final spec = await _textService.generateNameAndStats(animalDescription: description);

      // Persist PNG to storage
      final savedPath = await _storage.savePngBytes(pngBytes);

      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final p = Pokemon(
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
        _pokemon = p;
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
    final theme = Theme.of(context);
    final canGenerate = _photos.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PokéSnap PixelMon'),
        centerTitle: true,
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
                'Snap an animal and create a Gen‑1 style pixel monster!',
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
                label: const Text('Generate PixelMon'),
              ),
              const SizedBox(height: 24),
              if (_generatedPng != null) ...[
                Center(child: PixelArtPreview(imageBytes: _generatedPng!, maxSize: 256)),
                const SizedBox(height: 12),
                if (_pokemon != null) _buildPokemonCard(_pokemon!),
              ],
              const SizedBox(height: 32),
              _buildEnvHints(),
            ],
          ),
          if (_isGenerating)
            Container(
              color: Colors.black.withOpacity(0.4),
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

  Widget _buildPokemonCard(Pokemon p) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(p.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              [
                p.primaryType.name[0].toUpperCase() + p.primaryType.name.substring(1),
                if (p.secondaryType != null)
                  ' / ${p.secondaryType!.name[0].toUpperCase()}${p.secondaryType!.name.substring(1)}'
              ].join(),
              style: Theme.of(context).textTheme.labelLarge,
            ),
            if (p.flavorText.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(p.flavorText, style: Theme.of(context).textTheme.bodyMedium),
            ],
            const Divider(height: 24),
            _buildStatsGrid(p.stats),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(PokemonStats s) {
    Text stat(String label, int v) => Text('$label: $v');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        stat('HP', s.hp),
        stat('Attack', s.attack),
        stat('Defense', s.defense),
        stat('Sp. Atk', s.specialAttack),
        stat('Sp. Def', s.specialDefense),
        stat('Speed', s.speed),
      ],
    );
  }

  Widget _buildEnvHints() {
    final missingKey = kGeminiApiKey.isEmpty;
    final missingApi = kApiBaseUrl.isEmpty;
    if (!missingKey && !missingApi) return const SizedBox.shrink();
    return Card(
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Configuration hints'),
            if (missingKey) const Text('• Set GEMINI_API_KEY via --dart-define to enable name/stat generation'),
            if (missingApi) const Text('• Set API_BASE_URL via --dart-define pointing to your image generator backend'),
          ],
        ),
      ),
    );
  }
}
