import 'dart:convert';

enum CreatureType {
  fire,
  water,
  earth,
  air,
  light,
  shadow,
  nature,
  metal,
  arcane,
  beast,
}

CreatureType parseCreatureType(String value) {
  final v = value.trim().toLowerCase();
  switch (v) {
    case 'fire':
      return CreatureType.fire;
    case 'water':
      return CreatureType.water;
    case 'earth':
      return CreatureType.earth;
    case 'air':
      return CreatureType.air;
    case 'light':
      return CreatureType.light;
    case 'shadow':
      return CreatureType.shadow;
    case 'nature':
    case 'grass': // Mapping legacy/pokemon types just in case
      return CreatureType.nature;
    case 'metal':
    case 'steel':
      return CreatureType.metal;
    case 'arcane':
    case 'psychic':
      return CreatureType.arcane;
    case 'beast':
    case 'normal':
      return CreatureType.beast;
    default:
      return CreatureType.beast;
  }
}

String creatureTypeToString(CreatureType t) => t.name;

class CreatureStats {
  final int hp;
  final int attack;
  final int defense;
  final int speed;

  const CreatureStats({
    required this.hp,
    required this.attack,
    required this.defense,
    required this.speed,
  });

  factory CreatureStats.fromJson(Map<String, dynamic> json) {
    int clamp(int v) => v.clamp(1, 255);
    return CreatureStats(
      hp: clamp(json['hp'] is num ? (json['hp'] as num).toInt() : 1),
      attack: clamp(json['attack'] is num ? (json['attack'] as num).toInt() : 1),
      defense: clamp(json['defense'] is num ? (json['defense'] as num).toInt() : 1),
      speed: clamp(json['speed'] is num ? (json['speed'] as num).toInt() : 1),
    );
  }

  Map<String, dynamic> toJson() => {
        'hp': hp,
        'attack': attack,
        'defense': defense,
        'speed': speed,
      };
}

class Creature {
  final String id;
  final String name;
  final CreatureType primaryType;
  final CreatureType? secondaryType;
  final CreatureStats stats;
  final String imagePath; // local path to generated PNG (transparent BG)
  final List<String> originalPhotoPaths;
  final DateTime createdAt;
  final String flavorText;

  const Creature({
    required this.id,
    required this.name,
    required this.primaryType,
    required this.secondaryType,
    required this.stats,
    required this.imagePath,
    required this.originalPhotoPaths,
    required this.createdAt,
    required this.flavorText,
  });

  factory Creature.fromJson(Map<String, dynamic> json) => Creature(
        id: json['id'] as String,
        name: json['name'] as String,
        primaryType: parseCreatureType(json['primaryType'] as String),
        secondaryType: (json['secondaryType'] as String?) != null
            ? parseCreatureType(json['secondaryType'] as String)
            : null,
        stats: CreatureStats.fromJson(json['stats'] as Map<String, dynamic>),
        imagePath: json['imagePath'] as String,
        originalPhotoPaths: (json['originalPhotoPaths'] as List).cast<String>(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        flavorText: json['flavorText'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'primaryType': creatureTypeToString(primaryType),
        'secondaryType': secondaryType != null ? creatureTypeToString(secondaryType!) : null,
        'stats': stats.toJson(),
        'imagePath': imagePath,
        'originalPhotoPaths': originalPhotoPaths,
        'createdAt': createdAt.toIso8601String(),
        'flavorText': flavorText,
      };

  @override
  String toString() => jsonEncode(toJson());
}

class GeneratedSpec {
  final String name;
  final String flavorText;
  final CreatureType primaryType;
  final CreatureType? secondaryType;
  final CreatureStats stats;

  const GeneratedSpec({
    required this.name,
    required this.flavorText,
    required this.primaryType,
    required this.secondaryType,
    required this.stats,
  });
}
