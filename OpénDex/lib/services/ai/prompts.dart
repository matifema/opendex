const String pixelArtStyleGuidelines = '''
Generate a pixel-art sprite sheet of a fantasy creature in the aesthetic of 16-bit RPGs:
- Canvas Size: 256x64 pixels.
- Layout: 4 frames of 64x64 pixels arranged horizontally.
- Content: An idle animation loop of the creature (e.g., breathing, bobbing, tail wag).
- Style: Crisp pixels, no anti-aliasing, vibrant colors, simple cel shading.
- Subject: Living animals only. NO HUMANS.
- The creature should be inspired by the described real-world animal but stylized and original.
''';

String buildImagePrompt({
  required String animalDescription,
}) {
  return '''
Create a transparent-background pixel-art sprite sheet.

Subject: $animalDescription

Constraints:
$pixelArtStyleGuidelines
''';
}

const String statsJsonContract = '''
You are a game stat designer. Return ONLY valid JSON (no extra text, no markdown) matching this schema:

{
  "isHuman": boolean,
  "name": "string, short and evocative",
  "types": ["PrimaryType", "OptionalSecondaryType or omit"],
  "flavorText": "string, max 140 chars, fantasy bestiary style",
  "stats": {
    "hp": 1-255,
    "attack": 1-255,
    "defense": 1-255,
    "speed": 1-255
  }
}

- If the input description implies a human, person, or selfie, set "isHuman" to true.
- Types must be chosen from: Fire, Water, Earth, Air, Light, Shadow, Nature, Metal, Arcane, Beast.
- Keep total stats in a plausible range (sum ~ 250–500).
- Ensure all integers are within [1, 255].
- Output JSON only.
''';

String buildStatsPrompt({required String animalDescription}) {
  return '''
Design a fantasy creature concept from this real animal: "$animalDescription".
If the image/description is of a human, flag it using "isHuman": true.

$statsJsonContract
''';
}
