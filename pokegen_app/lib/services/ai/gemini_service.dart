import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;

import '../../models/pokemon_models.dart';
import '../settings_service.dart';
import 'human_detected_exception.dart';
import 'move_database.dart';

/// Direct Gemini API service using the classic google_generative_ai SDK.
///
/// Requires only an API key from Google AI Studio — no Firebase project needed.
class GeminiService {
  final String _apiKey;

  GeminiService({required String apiKey}) : _apiKey = apiKey;

  /// Factory constructor that creates a service from SettingsService.
  factory GeminiService.fromSettings(SettingsService settings) {
    return GeminiService(apiKey: settings.geminiApiKey);
  }

  /// Creates a configured GenerativeModel for text/multimodal analysis.
  GenerativeModel _createAnalysisModel() {
    return GenerativeModel(
      model: 'gemini-3.1-flash-lite-preview',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.8,
      ),
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
      ],
    );
  }

  /// Generates a creature from a photo and description.
  ///
  /// Pipeline:
  /// 1. Analyze photo with Gemini (multimodal) -> JSON stats + visual spec
  /// 1.5. Select moves based on creature types
  /// 2. Generate sprite sheet image with Gemini image model
  /// 3. Return combined result
  Future<GenerationResult> generateCreature({
    required File photo,
    required String description,
  }) async {
    if (_apiKey.isEmpty) {
      throw StateError(
        'GEMINI_API_KEY is not set. Configure it in Settings.',
      );
    }

    // --- Step 1: Analysis & Spec Generation ---
    final spec = await _analyzePhoto(photo, description);

    // --- Step 1.5: Select Moves ---
    final moves = MoveDatabase.selectMovesForCreature(
      spec.primaryType,
      spec.secondaryType,
    );

    final specWithMoves = GeneratedSpec(
      name: spec.name,
      flavorText: spec.flavorText,
      primaryType: spec.primaryType,
      secondaryType: spec.secondaryType,
      stats: spec.stats,
      moves: moves,
    );

    // --- Step 2: Image Generation ---
    final imageBytes = await _generateImage(specWithMoves);

    return GenerationResult(
      spec: specWithMoves,
      imageBytes: imageBytes,
    );
  }

  /// Step 1: Analyze photo and generate creature stats via JSON.
  Future<GeneratedSpec> _analyzePhoto(File photo, String description) async {
    final analysisPrompt = '''You are a retro game designer specializing in 16-bit pixel art creatures. Analyze this image and the user description: "$description".

**TASK 1 - SAFETY CHECK:**
Is this a photo of a human/person? If yes, set "isHuman" to true.

**TASK 2 - CREATURE STATS:**
Generate creative fantasy creature stats inspired by the subject. The creature should feel like a Pokemon or fantasy RPG monster with:
- A creative Name (inspired by the subject + elemental/attribute fusion)
- 1-2 Types from this exact list: fire, water, earth, air, light, shadow, nature, metal, arcane, beast
- Flavor text describing the creature's behavior or habitat (1-2 sentences)
- Balanced stats: HP (30-100), Attack (20-80), Defense (20-80), Speed (20-80)

**TASK 3 - VISUAL SPECIFICATION FOR PIXEL ART:**
Create a DETAILED specification for generating a 4-frame pixel art sprite sheet (256x64 px total):

- **Subject**: Describe the creature as a pixel art sprite (e.g., "A small fire salamander with flame tail")
- **Palette**: Provide 4-6 specific colors in hex format or color names suited for 16-bit pixel art
  - Include outline/border color (usually black or dark)
  - Main body colors (2-3 colors)
  - Accent/detail colors (1-2 colors)
  - NO pure white (#FFFFFF) in the creature palette

- **Animation**: Describe EACH of the 4 frames specifically for an idle looping animation:
  - Frame 1: [starting pose, e.g., "body centered, wings up"]
  - Frame 2: [intermediate movement, e.g., "body slightly down, wings at middle"]
  - Frame 3: [peak movement, e.g., "body lowest, wings fully down"]
  - Frame 4: [return movement, e.g., "body rising, wings starting to go up - loops back to frame 1"]

- **Details**: Key visual features (eyes, limbs, special effects like flames/sparkles, proportions)
  - Describe the creature's silhouette and key identifying features
  - Mention any special effects (fire, electricity, aura, etc.)
  - Note size relative to the 64x64 frame (small, medium, fills frame)

Return ONLY valid JSON matching this schema:
{
  "isHuman": boolean,
  "stats": {
    "name": "string",
    "types": ["string", "string"],
    "flavorText": "string",
    "hp": int, "attack": int, "defense": int, "speed": int
  },
  "visualSpec": {
    "subject": "detailed pixel art creature description",
    "palette": ["#hexcolor1", "#hexcolor2", "color name", ...],
    "animation": "Frame 1: [pose]. Frame 2: [pose]. Frame 3: [pose]. Frame 4: [pose].",
    "details": "key visual features, proportions, special effects"
  }
}

Note: Moves will be automatically selected based on the creature's types.''';

    final photoBytes = await photo.readAsBytes();
    final mimeType = _detectMimeType(photoBytes);

    final model = _createAnalysisModel();

    final response = await model.generateContent([
      Content.multi([
        TextPart(analysisPrompt),
        DataPart(mimeType, photoBytes),
      ]),
    ]);

    final text = response.text;
    if (text == null || text.isEmpty) {
      throw StateError('Failed to analyze image: empty response from Gemini');
    }

    final data = jsonDecode(text) as Map<String, dynamic>;

    // Check for human detection
    if (data['isHuman'] == true) {
      throw HumanDetectedException();
    }

    // Parse stats
    final statsData = data['stats'] as Map<String, dynamic>;
    final types = (statsData['types'] as List?)
            ?.cast<String>()
            .map(parseCreatureType)
            .toList() ??
        <CreatureType>[];

    final primaryType = types.isNotEmpty ? types.first : CreatureType.beast;
    final CreatureType? secondaryType = types.length > 1 ? types[1] : null;

    final stats = CreatureStats(
      hp: _clampStat(statsData['hp']),
      attack: _clampStat(statsData['attack']),
      defense: _clampStat(statsData['defense']),
      speed: _clampStat(statsData['speed']),
    );

    return GeneratedSpec(
      name: statsData['name'] as String? ?? 'Unknown',
      flavorText: statsData['flavorText'] as String? ?? '',
      primaryType: primaryType,
      secondaryType: secondaryType,
      stats: stats,
    );
  }

  /// Step 2: Generate sprite sheet image from visual spec.
  ///
  /// Uses the raw HTTP API directly because google_generative_ai 0.4.7
  /// cannot parse inlineData parts in model responses (throws UnimplementedError).
  Future<Uint8List> _generateImage(GeneratedSpec spec) async {
    final imagePrompt = '''Create a pixel art sprite sheet for a fantasy creature with PRECISE specifications:

CRITICAL REQUIREMENTS:
- Canvas: EXACTLY 256 pixels wide x 64 pixels tall
- Layout: 4 animation frames displayed horizontally side by side, each frame is 64 x 64 pixels
- Frame positions: Frame 1 (x:0-63), Frame 2 (x:64-127), Frame 3 (x:128-191), Frame 4 (x:192-255)
- Background: Pure white (#FFFFFF) - this will be made transparent later

CREATURE SPECIFICATION:
- Name: ${spec.name}
- Subject: A ${spec.primaryType.name}${spec.secondaryType != null ? '/${spec.secondaryType!.name}' : ''} type fantasy creature
- Style: Classic 16-bit JRPG pixel art (like Pokemon Gen 2-3)
- Flavor: ${spec.flavorText}

PIXEL ART RULES:
- NO anti-aliasing or blur effects
- NO gradients (use dithering patterns if needed)
- Sharp, crisp edges on every pixel
- Limited color palette
- Each frame must be clearly separated and properly aligned
- The creature should be centered in each 64 x 64 frame
- Maintain consistent size and position across all frames
- Use dithering for shading, not smooth gradients
- The creature itself must NOT use pure white pixels - use off-white or light grays
- Only the background should be pure white (#FFFFFF)

OUTLINE RULES (CRITICAL):
- Use dark outlines ONLY for internal features (eyes, mouth, limb separations, wing segments)
- DO NOT draw a black or dark border/outline around the entire creature silhouette
- The creature edges should blend directly into the white background — no outer stroke, no halo, no dark rim
- Think Pokemon Gen 2-3 sprites: the character outline is defined by color contrast, NOT by a black border

Create a wide horizontal sprite sheet with 4 distinct idle animation frames showing smooth looping movement.''';

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-image-preview:generateContent?key=$_apiKey',
    );

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': imagePrompt},
            ],
          },
        ],
        'generationConfig': {
          'temperature': 1.0,
          'topP': 0.95,
        },
        'safetySettings': [
          {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_NONE'},
          {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_NONE'},
          {'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'threshold': 'BLOCK_NONE'},
          {'category': 'HARM_CATEGORY_DANGEROUS_CONTENT', 'threshold': 'BLOCK_NONE'},
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw StateError(
        'Image generation failed: HTTP ${response.statusCode}\n${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = data['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw StateError('No candidates returned from image generation');
    }

    final content = candidates.first['content'] as Map<String, dynamic>?;
    if (content == null) {
      throw StateError('No content in image generation response');
    }

    final parts = content['parts'] as List?;
    if (parts == null || parts.isEmpty) {
      throw StateError('No parts in image generation response');
    }

    // Find the inlineData part containing the image
    for (final part in parts) {
      if (part is Map<String, dynamic> && part.containsKey('inlineData')) {
        final inlineData = part['inlineData'] as Map<String, dynamic>;
        final base64Data = inlineData['data'] as String;
        return base64Decode(base64Data);
      }
    }

    throw StateError(
      'No image generated: the model did not return any image data',
    );
  }

  /// Detects MIME type from file bytes (JPEG magic bytes check).
  String _detectMimeType(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'image/jpeg';
    }
    if (bytes.length >= 4 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes.length >= 4 &&
        bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46) {
      return 'image/gif';
    }
    return 'image/jpeg'; // Default fallback
  }

  /// Clamps a stat value to the valid range (1-255).
  int _clampStat(dynamic value) {
    if (value is num) {
      return value.toInt().clamp(1, 255);
    }
    return 1;
  }
}
