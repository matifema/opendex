import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/pokemon_models.dart';

/// Persists the creature catalog as JSON in the app's support directory.
/// On initial load (no catalog exists), scans for orphaned PNG sprites
/// from previous unrecovered sessions and rehydrates minimal entries.
class PokedexStorageService {
  static const String _catalogFileName = 'creature_catalog.json';
  static const String _spritesDirName = 'pixelmon';

  Future<String> _getSpriteDirPath() async {
    final base = await getApplicationSupportDirectory();
    return '${base.path}/$_spritesDirName';
  }

  /// Loads all saved creatures from the catalog file.
  /// Returns an empty list if no catalog exists yet.
  /// Also migrates any orphaned PNG sprites into minimal entries.
  Future<List<Creature>> loadCreatures() async {
    final spriteDirPath = await _getSpriteDirPath();
    final filePath = '$spriteDirPath/$_catalogFileName';
    final file = File(filePath);

    // --- No catalog exists yet: scan for orphaned PNGs --> rebuild minimal entries ---
    if (!file.existsSync()) {
      await _createMinimalOrphanCatalog(spriteDirPath);
      return [];
    }

    // --- Load existing catalog ---
    try {
      final raw = await file.readAsString();
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => Creature.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList()
          .where((c) => File(c.imagePath).existsSync()) // remove broken references
          .toList();
    } catch (_) {
      // Corrupted catalog — wipe and attempt orphan recovery
      try {
        await file.delete();
      } catch (_) {}
      await _createMinimalOrphanCatalog(spriteDirPath);
      return [];
    }
  }

  /// Overwrites the persistent catalog with the current [creatures] list.
  Future<void> saveCreatures(List<Creature> creatures) async {
    final spriteDirPath = await _getSpriteDirPath();
    final dir = Directory(spriteDirPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final data = creatures.map((c) => c.toJson()).toList();
    final file = File('$spriteDirPath/$_catalogFileName');
    await file.writeAsString(jsonEncode(data), flush: true);
  }

  // ---------------------------------------------------------------------------
  // Orphan migration – runs once when no catalog exists on disk.
  // Builds a fresh catalog from PNG files found in the sprites directory.
  // ---------------------------------------------------------------------------
  Future<void> _createMinimalOrphanCatalog(String spriteDirPath) async {
    final dir = Directory(spriteDirPath);
    if (!await dir.exists()) return;

    final orphans = <Creature>[];
    int counter = 0;
    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      if (!entity.path.toLowerCase().endsWith('.png')) continue;

      orphans.add(Creature(
        id: 'orphan_${DateTime.now().millisecondsSinceEpoch}_$counter',
        name: 'Unknown',
        primaryType: CreatureType.beast,
        secondaryType: null,
        stats: const CreatureStats(hp: 1, attack: 1, defense: 1, speed: 1),
        imagePath: entity.path,
        originalPhotoPaths: [],
        createdAt: DateTime(1970), // epoch sentinal
        flavorText: 'Recovered sprite – generation details unavailable.',
      ));
      counter++;
    }

    // Persist the recovered catalog so the user sees their old creatures
    if (orphans.isNotEmpty) {
      final file = File('$spriteDirPath/$_catalogFileName');
      final data = orphans.map((c) => c.toJson()).toList();
      await file.writeAsString(jsonEncode(data), flush: true);
    }
  }
}
