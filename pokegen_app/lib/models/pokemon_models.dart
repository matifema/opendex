import 'dart:convert';

enum PokemonType {
  normal,
  fire,
  water,
  electric,
  grass,
  ice,
  fighting,
  poison,
  ground,
  flying,
  psychic,
  bug,
  rock,
  ghost,
  dragon,
}

PokemonType parsePokemonType(String value) {
  final v = value.trim().toLowerCase();
  switch (v) {
    case 'normal':
      return PokemonType.normal;
    case 'fire':
      return PokemonType.fire;
    case 'water':
      return PokemonType.water;
    case 'electric':
      return PokemonType.electric;
    case 'grass':
      return PokemonType.grass;
    case 'ice':
      return PokemonType.ice;
    case 'fighting':
      return PokemonType.fighting;
    case 'poison':
      return PokemonType.poison;
    case 'ground':
      return PokemonType.ground;
    case 'flying':
      return PokemonType.flying;
    case 'psychic':
      return PokemonType.psychic;
    case 'bug':
      return PokemonType.bug;
    case 'rock':
      return PokemonType.rock;
    case 'ghost':
      return PokemonType.ghost;
    case 'dragon':
      return PokemonType.dragon;
    default:
      return PokemonType.normal;
  }
}

String pokemonTypeToString(PokemonType t) => t.name;

class PokemonStats {
  final int hp;
  final int attack;
  final int defense;
  final int specialAttack;
  final int specialDefense;
  final int speed;

  const PokemonStats({
    required this.hp,
    required this.attack,
    required this.defense,
    required this.specialAttack,
    required this.specialDefense,
    required this.speed,
  });

  factory PokemonStats.fromJson(Map<String, dynamic> json) {
    int clamp(int v) => v.clamp(1, 255);
    return PokemonStats(
      hp: clamp(json['hp'] is num ? (json['hp'] as num).toInt() : 1),
      attack: clamp(json['attack'] is num ? (json['attack'] as num).toInt() : 1),
      defense: clamp(json['defense'] is num ? (json['defense'] as num).toInt() : 1),
      specialAttack: clamp(json['specialAttack'] is num ? (json['specialAttack'] as num).toInt() : 1),
      specialDefense: clamp(json['specialDefense'] is num ? (json['specialDefense'] as num).toInt() : 1),
      speed: clamp(json['speed'] is num ? (json['speed'] as num).toInt() : 1),
    );
  }

  Map<String, dynamic> toJson() => {
        'hp': hp,
        'attack': attack,
        'defense': defense,
        'specialAttack': specialAttack,
        'specialDefense': specialDefense,
        'speed': speed,
      };
}

class Pokemon {
  final String id;
  final String name;
  final PokemonType primaryType;
  final PokemonType? secondaryType;
  final PokemonStats stats;
  final String imagePath; // local path to generated PNG (transparent BG)
  final List<String> originalPhotoPaths;
  final DateTime createdAt;
  final String flavorText;

  const Pokemon({
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

  factory Pokemon.fromJson(Map<String, dynamic> json) => Pokemon(
        id: json['id'] as String,
        name: json['name'] as String,
        primaryType: parsePokemonType(json['primaryType'] as String),
        secondaryType: (json['secondaryType'] as String?) != null
            ? parsePokemonType(json['secondaryType'] as String)
            : null,
        stats: PokemonStats.fromJson(json['stats'] as Map<String, dynamic>),
        imagePath: json['imagePath'] as String,
        originalPhotoPaths: (json['originalPhotoPaths'] as List).cast<String>(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        flavorText: json['flavorText'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'primaryType': pokemonTypeToString(primaryType),
        'secondaryType': secondaryType != null ? pokemonTypeToString(secondaryType!) : null,
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
  final PokemonType primaryType;
  final PokemonType? secondaryType;
  final PokemonStats stats;

  const GeneratedSpec({
    required this.name,
    required this.flavorText,
    required this.primaryType,
    required this.secondaryType,
    required this.stats,
  });
}
