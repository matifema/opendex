import 'dart:math';

import '../../models/pokemon_models.dart';

/// Gen 1-style move database for creature generation.
/// Contains all 85 moves ported from backend/move_data.py.
class MoveDatabase {
  static const List<Map<String, dynamic>> _gen1Moves = [
    // Normal Type Moves
    {'name': 'Tackle', 'type': 'normal', 'category': 'physical', 'power': 40, 'accuracy': 100},
    {'name': 'Body Slam', 'type': 'normal', 'category': 'physical', 'power': 85, 'accuracy': 100},
    {'name': 'Take Down', 'type': 'normal', 'category': 'physical', 'power': 90, 'accuracy': 85},
    {'name': 'Double-Edge', 'type': 'normal', 'category': 'physical', 'power': 120, 'accuracy': 100},
    {'name': 'Hyper Beam', 'type': 'normal', 'category': 'special', 'power': 150, 'accuracy': 90},
    {'name': 'Quick Attack', 'type': 'normal', 'category': 'physical', 'power': 40, 'accuracy': 100},
    {'name': 'Scratch', 'type': 'normal', 'category': 'physical', 'power': 40, 'accuracy': 100},
    {'name': 'Slash', 'type': 'normal', 'category': 'physical', 'power': 70, 'accuracy': 100},
    {'name': 'Mega Punch', 'type': 'normal', 'category': 'physical', 'power': 80, 'accuracy': 85},
    {'name': 'Mega Kick', 'type': 'normal', 'category': 'physical', 'power': 120, 'accuracy': 75},

    // Fire Type Moves
    {'name': 'Ember', 'type': 'fire', 'category': 'special', 'power': 40, 'accuracy': 100},
    {'name': 'Flamethrower', 'type': 'fire', 'category': 'special', 'power': 95, 'accuracy': 100},
    {'name': 'Fire Blast', 'type': 'fire', 'category': 'special', 'power': 120, 'accuracy': 85},
    {'name': 'Fire Spin', 'type': 'fire', 'category': 'special', 'power': 35, 'accuracy': 85},
    {'name': 'Fire Punch', 'type': 'fire', 'category': 'physical', 'power': 75, 'accuracy': 100},

    // Water Type Moves
    {'name': 'Water Gun', 'type': 'water', 'category': 'special', 'power': 40, 'accuracy': 100},
    {'name': 'Hydro Pump', 'type': 'water', 'category': 'special', 'power': 120, 'accuracy': 80},
    {'name': 'Surf', 'type': 'water', 'category': 'special', 'power': 95, 'accuracy': 100},
    {'name': 'Bubble Beam', 'type': 'water', 'category': 'special', 'power': 65, 'accuracy': 100},
    {'name': 'Waterfall', 'type': 'water', 'category': 'physical', 'power': 80, 'accuracy': 100},
    {'name': 'Bubble', 'type': 'water', 'category': 'special', 'power': 20, 'accuracy': 100},

    // Electric Type Moves
    {'name': 'Thunder Shock', 'type': 'electric', 'category': 'special', 'power': 40, 'accuracy': 100},
    {'name': 'Thunderbolt', 'type': 'electric', 'category': 'special', 'power': 95, 'accuracy': 100},
    {'name': 'Thunder', 'type': 'electric', 'category': 'special', 'power': 120, 'accuracy': 70},
    {'name': 'Thunder Wave', 'type': 'electric', 'category': 'status', 'power': null, 'accuracy': 100},
    {'name': 'Thunder Punch', 'type': 'electric', 'category': 'physical', 'power': 75, 'accuracy': 100},

    // Grass Type Moves
    {'name': 'Vine Whip', 'type': 'grass', 'category': 'physical', 'power': 35, 'accuracy': 100},
    {'name': 'Razor Leaf', 'type': 'grass', 'category': 'physical', 'power': 55, 'accuracy': 95},
    {'name': 'Solar Beam', 'type': 'grass', 'category': 'special', 'power': 120, 'accuracy': 100},
    {'name': 'Mega Drain', 'type': 'grass', 'category': 'special', 'power': 40, 'accuracy': 100},
    {'name': 'Absorb', 'type': 'grass', 'category': 'special', 'power': 20, 'accuracy': 100},
    {'name': 'Petal Dance', 'type': 'grass', 'category': 'special', 'power': 120, 'accuracy': 100},
    {'name': 'Leech Seed', 'type': 'grass', 'category': 'status', 'power': null, 'accuracy': 90},

    // Ice Type Moves
    {'name': 'Ice Beam', 'type': 'ice', 'category': 'special', 'power': 95, 'accuracy': 100},
    {'name': 'Blizzard', 'type': 'ice', 'category': 'special', 'power': 120, 'accuracy': 70},
    {'name': 'Ice Punch', 'type': 'ice', 'category': 'physical', 'power': 75, 'accuracy': 100},
    {'name': 'Aurora Beam', 'type': 'ice', 'category': 'special', 'power': 65, 'accuracy': 100},

    // Fighting Type Moves
    {'name': 'Karate Chop', 'type': 'fighting', 'category': 'physical', 'power': 50, 'accuracy': 100},
    {'name': 'Low Kick', 'type': 'fighting', 'category': 'physical', 'power': 50, 'accuracy': 100},
    {'name': 'Submission', 'type': 'fighting', 'category': 'physical', 'power': 80, 'accuracy': 80},
    {'name': 'Seismic Toss', 'type': 'fighting', 'category': 'physical', 'power': null, 'accuracy': 100},
    {'name': 'High Jump Kick', 'type': 'fighting', 'category': 'physical', 'power': 130, 'accuracy': 90},

    // Poison Type Moves
    {'name': 'Poison Sting', 'type': 'poison', 'category': 'physical', 'power': 15, 'accuracy': 100},
    {'name': 'Sludge', 'type': 'poison', 'category': 'special', 'power': 65, 'accuracy': 100},
    {'name': 'Acid', 'type': 'poison', 'category': 'special', 'power': 40, 'accuracy': 100},
    {'name': 'Poison Gas', 'type': 'poison', 'category': 'status', 'power': null, 'accuracy': 55},
    {'name': 'Toxic', 'type': 'poison', 'category': 'status', 'power': null, 'accuracy': 90},

    // Ground Type Moves
    {'name': 'Earthquake', 'type': 'ground', 'category': 'physical', 'power': 100, 'accuracy': 100},
    {'name': 'Dig', 'type': 'ground', 'category': 'physical', 'power': 80, 'accuracy': 100},
    {'name': 'Bone Club', 'type': 'ground', 'category': 'physical', 'power': 65, 'accuracy': 85},
    {'name': 'Sand Attack', 'type': 'ground', 'category': 'status', 'power': null, 'accuracy': 100},

    // Flying Type Moves
    {'name': 'Peck', 'type': 'flying', 'category': 'physical', 'power': 35, 'accuracy': 100},
    {'name': 'Drill Peck', 'type': 'flying', 'category': 'physical', 'power': 80, 'accuracy': 100},
    {'name': 'Wing Attack', 'type': 'flying', 'category': 'physical', 'power': 60, 'accuracy': 100},
    {'name': 'Fly', 'type': 'flying', 'category': 'physical', 'power': 90, 'accuracy': 95},
    {'name': 'Sky Attack', 'type': 'flying', 'category': 'physical', 'power': 140, 'accuracy': 90},

    // Psychic Type Moves
    {'name': 'Confusion', 'type': 'psychic', 'category': 'special', 'power': 50, 'accuracy': 100},
    {'name': 'Psybeam', 'type': 'psychic', 'category': 'special', 'power': 65, 'accuracy': 100},
    {'name': 'Psychic', 'type': 'psychic', 'category': 'special', 'power': 90, 'accuracy': 100},
    {'name': 'Dream Eater', 'type': 'psychic', 'category': 'special', 'power': 100, 'accuracy': 100},
    {'name': 'Hypnosis', 'type': 'psychic', 'category': 'status', 'power': null, 'accuracy': 60},

    // Bug Type Moves
    {'name': 'Leech Life', 'type': 'bug', 'category': 'physical', 'power': 20, 'accuracy': 100},
    {'name': 'Twineedle', 'type': 'bug', 'category': 'physical', 'power': 25, 'accuracy': 100},
    {'name': 'Pin Missile', 'type': 'bug', 'category': 'physical', 'power': 14, 'accuracy': 85},
    {'name': 'String Shot', 'type': 'bug', 'category': 'status', 'power': null, 'accuracy': 95},

    // Rock Type Moves
    {'name': 'Rock Throw', 'type': 'rock', 'category': 'physical', 'power': 50, 'accuracy': 90},
    {'name': 'Rock Slide', 'type': 'rock', 'category': 'physical', 'power': 75, 'accuracy': 90},

    // Ghost Type Moves
    {'name': 'Lick', 'type': 'ghost', 'category': 'physical', 'power': 20, 'accuracy': 100},
    {'name': 'Night Shade', 'type': 'ghost', 'category': 'special', 'power': null, 'accuracy': 100},
    {'name': 'Confuse Ray', 'type': 'ghost', 'category': 'status', 'power': null, 'accuracy': 100},

    // Dragon Type Moves
    {'name': 'Dragon Rage', 'type': 'dragon', 'category': 'special', 'power': null, 'accuracy': 100},

    // Status/Support Moves (Various Types)
    {'name': 'Growl', 'type': 'normal', 'category': 'status', 'power': null, 'accuracy': 100},
    {'name': 'Tail Whip', 'type': 'normal', 'category': 'status', 'power': null, 'accuracy': 100},
    {'name': 'Leer', 'type': 'normal', 'category': 'status', 'power': null, 'accuracy': 100},
    {'name': 'Roar', 'type': 'normal', 'category': 'status', 'power': null, 'accuracy': 100},
    {'name': 'Sing', 'type': 'normal', 'category': 'status', 'power': null, 'accuracy': 55},
    {'name': 'Supersonic', 'type': 'normal', 'category': 'status', 'power': null, 'accuracy': 55},
    {'name': 'Screech', 'type': 'normal', 'category': 'status', 'power': null, 'accuracy': 85},
    {'name': 'Harden', 'type': 'normal', 'category': 'status', 'power': null, 'accuracy': null},
    {'name': 'Withdraw', 'type': 'water', 'category': 'status', 'power': null, 'accuracy': null},
    {'name': 'Defense Curl', 'type': 'normal', 'category': 'status', 'power': null, 'accuracy': null},
    {'name': 'Agility', 'type': 'psychic', 'category': 'status', 'power': null, 'accuracy': null},
    {'name': 'Swords Dance', 'type': 'normal', 'category': 'status', 'power': null, 'accuracy': null},
    {'name': 'Recover', 'type': 'normal', 'category': 'status', 'power': null, 'accuracy': null},
    {'name': 'Rest', 'type': 'psychic', 'category': 'status', 'power': null, 'accuracy': null},
  ];

  /// Maps CreatureType to Pokemon-style type strings for move lookup.
  static const Map<CreatureType, String> _typeMappings = {
    CreatureType.fire: 'fire',
    CreatureType.water: 'water',
    CreatureType.earth: 'ground',
    CreatureType.air: 'flying',
    CreatureType.light: 'electric',
    CreatureType.shadow: 'ghost',
    CreatureType.nature: 'grass',
    CreatureType.metal: 'rock',
    CreatureType.arcane: 'psychic',
    CreatureType.beast: 'normal',
  };

  static final Random _random = Random();

  /// Selects 4 appropriate moves for a creature based on its types.
  ///
  /// Algorithm:
  /// 1. Get 1-2 moves matching primary/secondary type (prioritize damaging)
  /// 2. Get 1 status/support move for variety
  /// 3. Fill remaining with coverage moves from different types
  static List<Move> selectMovesForCreature(
    CreatureType primaryType, [
    CreatureType? secondaryType,
  ]) {
    final primaryPokemonType = _typeMappings[primaryType] ?? 'normal';
    final secondaryPokemonType =
        secondaryType != null ? (_typeMappings[secondaryType] ?? 'normal') : null;

    final selected = <Map<String, dynamic>>[];

    // 1. Type-matching damaging moves
    final primaryDamaging = _getDamagingMovesByType(primaryPokemonType);
    if (secondaryPokemonType != null && secondaryPokemonType != primaryPokemonType) {
      final secondaryDamaging = _getDamagingMovesByType(secondaryPokemonType);
      if (primaryDamaging.isNotEmpty) {
        selected.add(_randomChoice(primaryDamaging));
      }
      if (secondaryDamaging.isNotEmpty) {
        selected.add(_randomChoice(secondaryDamaging));
      }
    } else {
      if (primaryDamaging.length >= 2) {
        selected.addAll(_randomSample(primaryDamaging, 2));
      } else if (primaryDamaging.isNotEmpty) {
        selected.add(_randomChoice(primaryDamaging));
      }
    }

    // 2. Add 1 status move
    final typeStatus = _getStatusMoves().where((m) {
      final t = m['type'] as String;
      return t == primaryPokemonType || t == secondaryPokemonType;
    }).toList();
    if (typeStatus.isNotEmpty) {
      selected.add(_randomChoice(typeStatus));
    } else {
      final allStatus = _getStatusMoves();
      if (allStatus.isNotEmpty) {
        selected.add(_randomChoice(allStatus));
      }
    }

    // 3. Fill remaining with coverage moves
    final usedNames = selected.map((m) => m['name'] as String).toSet();
    while (selected.length < 4) {
      final available = _getDamagingMoves()
          .where((m) => !usedNames.contains(m['name']))
          .toList();
      if (available.isEmpty) break;

      final coverage = available
          .where((m) =>
              m['type'] != primaryPokemonType && m['type'] != secondaryPokemonType)
          .toList();
      final pool = coverage.isNotEmpty ? coverage : available;
      final chosen = _randomChoice(pool);
      selected.add(chosen);
      usedNames.add(chosen['name'] as String);
    }

    return selected.take(4).map((m) => Move.fromJson(m)).toList();
  }

  static List<Map<String, dynamic>> _getDamagingMovesByType(String type) =>
      _gen1Moves
          .where((m) => m['type'] == type && m['category'] != 'status')
          .toList();

  static List<Map<String, dynamic>> _getStatusMoves() =>
      _gen1Moves.where((m) => m['category'] == 'status').toList();

  static List<Map<String, dynamic>> _getDamagingMoves() =>
      _gen1Moves.where((m) => m['category'] != 'status').toList();

  static T _randomChoice<T>(List<T> list) => list[_random.nextInt(list.length)];

  static List<T> _randomSample<T>(List<T> list, int count) {
    final copy = List<T>.from(list);
    copy.shuffle(_random);
    return copy.take(count).toList();
  }
}
