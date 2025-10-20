const String pixelArtStyleGuidelines = '''
Generate a front-facing, 3/4 view pixel-art creature in the aesthetic of early Pokémon (Gen 1–2 era):
- Output MUST be a PNG with a 100% transparent background (no background pixels).
- Resolution: square canvas (prefer 256x256); design with crisp pixels and no anti-aliasing.
- Use limited colors with simple cel shading and 1px dark outline where appropriate.
- No text, no borders, no drop shadows, no UI, no background scene.
- Pose: idle battle stance facing slightly right. Keep full body in frame.
- The creature should be inspired by the described real-world animal but stylized and original.
''';

String buildImagePrompt({
  required String animalDescription,
}) {
  return '''
Create a single transparent-background PNG of a pixel-art creature.

Subject: $animalDescription

Constraints:
$pixelArtStyleGuidelines
''';
}

const String statsJsonContract = '''
You are a game stat designer. Return ONLY valid JSON (no extra text, no markdown) matching this schema:

{
  "name": "string, short and evocative",
  "types": ["PrimaryType", "OptionalSecondaryType or omit"],
  "flavorText": "string, max 140 chars, Pokédex-style",
  "stats": {
    "hp": 1-255,
    "attack": 1-255,
    "defense": 1-255,
    "specialAttack": 1-255,
    "specialDefense": 1-255,
    "speed": 1-255
  }
}

- Types must be chosen from: Normal, Fire, Water, Electric, Grass, Ice, Fighting, Poison, Ground, Flying, Psychic, Bug, Rock, Ghost, Dragon.
- Keep total stats in a plausible early-generation range (sum ~ 250–500).
- Ensure all integers are within [1, 255].
- Output JSON only.
''';

String buildStatsPrompt({required String animalDescription}) {
  return '''
Design a Gen-1 style monster concept from this real animal: "$animalDescription".
Choose suitable one or two types from the allowed list and balanced base stats.

$statsJsonContract
''';
}
