classDiagram
direction LR

class Pokemon {
  +String id
  +String name
  +PokemonType primaryType
  +PokemonType? secondaryType
  +PokemonStats stats
  +String imagePath
  +List~String~ originalPhotoPaths
  +DateTime createdAt
  +String flavorText
}

class PokemonStats {
  +int hp
  +int attack
  +int defense
  +int specialAttack
  +int specialDefense
  +int speed
}

class GeneratedSpec {
  +String name
  +String flavorText
  +PokemonType primaryType
  +PokemonType? secondaryType
  +PokemonStats stats
}

class PokemonType {
  <<enumeration>>
  normal
  fire
  water
  electric
  grass
  ice
  fighting
  poison
  ground
  flying
  psychic
  bug
  rock
  ghost
  dragon
}

Pokemon --> PokemonStats
GeneratedSpec --> PokemonStats
Pokemon --> PokemonType : primaryType
Pokemon --> PokemonType : secondaryType
GeneratedSpec --> PokemonType : primaryType
GeneratedSpec --> PokemonType : secondaryType
