# Replicable Prompts

## Image Generation (Pixel Art PNG, Transparent Background)

Use with an image-generation model capable of returning PNG bytes. Send the prompt as plain text and include the captured photos as references (multipart form-data). The model must return a single PNG with a fully transparent background.

Prompt:
```
Create a single transparent-background PNG of a pixel-art creature.

Subject: <describe the real animal in brief, e.g., "striped tiger cub" or "golden retriever puppy">

Constraints:
Generate a front-facing, 3/4 view pixel-art creature in the aesthetic of early Pokémon (Gen 1–2 era):
- Output MUST be a PNG with a 100% transparent background (no background pixels).
- Resolution: square canvas (prefer 256x256); design with crisp pixels and no anti-aliasing.
- Use limited colors with simple cel shading and 1px dark outline where appropriate.
- No text, no borders, no drop shadows, no UI, no background scene.
- Pose: idle battle stance facing slightly right. Keep full body in frame.
- The creature should be inspired by the described real-world animal but stylized and original.
```

Return: raw PNG bytes.

## Text Generation (Name and Stats JSON)

Use with a text model (e.g., Gemini). Require JSON-only output using the schema below.

System/Instruction:
```
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
```

User:
```
Design a Gen-1 style monster concept from this real animal: "<your brief animal description>".
Choose suitable one or two types from the allowed list and balanced base stats.
```

Return: JSON object adhering to the schema above.
