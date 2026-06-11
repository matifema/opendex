import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;

import '../../models/pokemon_models.dart';
import '../settings_service.dart';
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

    // --- Step 2: Image Generation ---
    final imageBytes = await _generateImage(spec, description);

    return GenerationResult(
      spec: spec,
      imageBytes: imageBytes,
    );
  }

  /// Step 1: Analyze photo and generate creature stats via JSON.
  Future<GeneratedSpec> _analyzePhoto(File photo, String description) async {
    final analysisPrompt = '''You are a retro game designer specializing in 16-bit pixel art creatures. Analyze this image and the user description: "$description".

**TASK 1 - CREATURE STATS:**
Generate creative fantasy creature stats inspired by the subject in the photo. The creature should feel like a Pokemon or fantasy RPG monster with:
- A creative Name (inspired by the subject + elemental/attribute fusion)
- 1-2 Types from this exact list: fire, water, earth, air, light, shadow, nature, metal, arcane, beast
- Flavor text describing the creature's behavior or habitat (1-2 sentences)
- Balanced stats: HP (30-100), Attack (20-80), Defense (20-80), Speed (20-80)

**TASK 2 - CREATURE DESCRIPTION:**
Write a RICH, DETAILED description of the creature's physical appearance as inspired by the subject in the photo. This will be used to generate the sprite sheet. Include:
- Body shape, proportions, posture
- Distinctive features (horns, wings, tail, fins, etc.)
- Color patterns and markings
- Texture details (scales, fur, feathers, slime, stone, metal, etc.)
- Expressive features (eyes, mouth, ears)
- Any elemental/magical effects (flames, sparks, aura, glow)
- How it relates to the original subject (what features are preserved, what are fantastical additions)

**TASK 3 - VISUAL SPECIFICATION FOR PIXEL ART:**
Create a DETAILED specification for generating a 4-frame pixel art sprite sheet (256x64 px total):

- **Subject**: Describe the creature as a pixel art sprite (e.g., "A small fire salamander with flame tail")
- **Palette**: Provide 4-6 specific colors in hex format or color names suited for 16-bit pixel art
  - Include outline/border color (usually black or dark)
  - Main body colors (2-3 colors)
  - Accent/detail colors (1-2 colors)
  - NO pure white (#FFFFFF) in the creature palette

- **Animation**: Describe EACH of the 4 frames as a COHERENT idle breathing loop. The frames must be nearly identical — only 2-3 pixels should shift between frames. Think Pokemon idle sprites: subtle breathing, slight body bob, minor tail/ear flick. NOT different poses.
  - Frame 1: [base/neutral pose — this is the reference frame, e.g., "creature standing centered, body at rest, tail neutral"]
  - Frame 2: [Frame 1 but with minimal change — body shifted DOWN by 1-2 pixels, slight compression, e.g., "same as Frame 1 but body pressed slightly lower, tail droops a fraction"]
  - Frame 3: [Frame 1 but with opposite minimal change — body shifted UP by 1-2 pixels, slight stretch, e.g., "same as Frame 1 but body rises slightly, tail lifts a fraction"]
  - Frame 4: [returns to Frame 1 exactly — identical pose, e.g., "identical to Frame 1, completing the loop"]
  CRITICAL: All four frames must show the SAME creature in the SAME position. Only subtle breathing/bobbing animation is allowed. The creature's outline, limb positions, and overall pose should be nearly identical across all frames.

- **Details**: Key visual features (eyes, limbs, special effects like flames/sparkles, proportions)
  - Describe the creature's silhouette and key identifying features
  - Mention any special effects (fire, electricity, aura, etc.)
  - Note size relative to the 64x64 frame (small, medium, fills frame)

Return ONLY valid JSON matching this schema:
{
  "stats": {
    "name": "string",
    "types": ["string", "string"],
    "flavorText": "string",
    "hp": int, "attack": int, "defense": int, "speed": int
  },
  "creatureDescription": "rich detailed physical description of the creature",
  "visualSpec": {
    "subject": "detailed pixel art creature description",
    "palette": ["#hexcolor1", "#hexcolor2", "color name", ...],
    "animation": "Frame 1: [pose]. Frame 2: [pose, nearly identical to Frame 1 with minor shift]. Frame 3: [pose, nearly identical to Frame 1 with opposite shift]. Frame 4: [identical to Frame 1].",
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

    var text = response.text;
    if (text == null || text.isEmpty) {
      throw StateError('Failed to analyze image: empty response from Gemini');
    }

    // Strip markdown code fences if the model wrapped JSON in them
    text = text.trim();
    if (text.startsWith('```')) {
      text = text.replaceFirst(RegExp(r'^```(?:json)?\s*'), '');
      text = text.replaceFirst(RegExp(r'\s*```$'), '');
    }

    final Map<String, dynamic> data;
    try {
      data = jsonDecode(text) as Map<String, dynamic>;
    } on FormatException catch (e) {
      throw StateError('Could not parse creature data: $e');
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

    final stats = CreatureStats.fromJson(statsData);
    final moves = MoveDatabase.selectMovesForCreature(primaryType, secondaryType);

    // Extract visual spec fields
    final visualSpec = data['visualSpec'] as Map<String, dynamic>?;
    final creatureDescription = data['creatureDescription'] as String? ?? '';
    final visualSubject = visualSpec?['subject'] as String? ?? '';
    final visualPalette = (visualSpec?['palette'] as List?)
            ?.cast<String>()
            .toList() ??
        <String>[];
    final visualAnimation = visualSpec?['animation'] as String? ?? '';
    final visualDetails = visualSpec?['details'] as String? ?? '';

    return GeneratedSpec(
      name: statsData['name'] as String? ?? 'Unknown',
      flavorText: statsData['flavorText'] as String? ?? '',
      primaryType: primaryType,
      secondaryType: secondaryType,
      stats: stats,
      moves: moves,
      creatureDescription: creatureDescription,
      visualSubject: visualSubject,
      visualPalette: visualPalette,
      visualAnimation: visualAnimation,
      visualDetails: visualDetails,
    );
  }

  /// Step 2: Generate sprite sheet image from visual spec.
  ///
  /// Uses the raw HTTP API directly because google_generative_ai 0.4.7
  /// cannot parse inlineData parts in model responses (throws UnimplementedError).
  /// Retries once on transient failures or when the model returns text-only.
  Future<Uint8List> _generateImage(GeneratedSpec spec, String sourceDescription) async {
    try {
      return await _generateImageOnce(spec, sourceDescription);
    } on StateError catch (e) {
      if (e.toString().contains('No image generated')) {
        return await _generateImageOnce(spec, sourceDescription);
      }
      rethrow;
    }
  }

  Future<Uint8List> _generateImageOnce(GeneratedSpec spec, String sourceDescription) async {
    final paletteStr = spec.visualPalette.isNotEmpty
        ? spec.visualPalette.join(', ')
        : 'appropriate 16-bit colors';

    final imagePrompt = '''You are an expert pixel artist creating a Pokemon-style sprite sheet. Generate the sprite sheet based on the EXACT specifications below.

SOURCE INSPIRATION: The creature is inspired by the subject in this photo: "$sourceDescription"

CREATURE DESCRIPTION:
${spec.creatureDescription.isNotEmpty ? spec.creatureDescription : 'A ${spec.primaryType.name}${spec.secondaryType != null ? '/${spec.secondaryType!.name}' : ''} type fantasy creature named ${spec.name}.'}

PIXEL ART SUBJECT:
${spec.visualSubject.isNotEmpty ? spec.visualSubject : '${spec.name}, a ${spec.primaryType.name} type fantasy creature'}

PALETTE (use these EXACT colors for the creature, NO pure white):
$paletteStr

ANIMATION (4-frame idle loop, each frame 64x64px):
${spec.visualAnimation.isNotEmpty ? spec.visualAnimation : 'Frame 1: neutral pose. Frame 2: slight movement. Frame 3: peak movement. Frame 4: return to neutral.'}

ANIMATION CONTINUITY RULES (CRITICAL):
- All 4 frames must show the EXACT same creature in the EXACT same position
- Only 2-3 pixels should differ between consecutive frames — this is a subtle breathing/bobbing animation, NOT a pose change
- The creature's outline, limb positions, eye placement, and overall silhouette must be nearly identical across all frames
- Think Pokemon Gen 2-3 idle sprites: the creature breathes, slightly compresses and expands, but never changes pose
- Frame 4 should be pixel-identical to Frame 1 to create a seamless loop
- DO NOT draw different poses, different limb positions, or different facial expressions across frames

KEY VISUAL DETAILS:
${spec.visualDetails.isNotEmpty ? spec.visualDetails : 'Centered creature with distinctive features matching its type.'}

CREATURE INFO:
- Name: ${spec.name}
- Types: ${spec.primaryType.name}${spec.secondaryType != null ? ' / ${spec.secondaryType!.name}' : ''}
- Flavor: ${spec.flavorText}

CRITICAL REQUIREMENTS:
- Canvas: EXACTLY 256 pixels wide x 64 pixels tall
- Layout: 4 animation frames displayed horizontally side by side, each frame is 64 x 64 pixels
- Frame positions: Frame 1 (x:0-63), Frame 2 (x:64-127), Frame 3 (x:128-191), Frame 4 (x:192-255)
- Background: SOLID, UNIFORM Pure white (#FFFFFF) — every single background pixel must be exactly #FFFFFF, no exceptions
- Margin: Leave at least 4 pixels of pure white (#FFFFFF) border around the creature on ALL sides — the creature must NEVER touch the canvas edge
- Style: Classic 16-bit JRPG pixel art (like Pokemon Gen 2-3)

PIXEL ART RULES:
- NO anti-aliasing or blur effects — especially NO gray/semi-transparent pixels at the creature-to-background boundary
- NO gradients (use dithering patterns if needed)
- Sharp, crisp edges on every pixel
- Limited color palette matching the specified colors above
- Each frame must be clearly separated and properly aligned
- The creature should be centered in each 64 x 64 frame
- Maintain consistent size and position across all frames
- Use dithering for shading, not smooth gradients
- The creature itself must NOT use pure white (#FFFFFF) or near-white pixels (#F0F0F0 or brighter) — use mid-tone grays or off-whites (#E0E0E0 or darker) for highlights
- Only the background area should be pure white (#FFFFFF)
- NO anti-aliased edge pixels: the transition from creature to background must be a hard, single-pixel boundary — no intermediate gray pixels

OUTLINE RULES (CRITICAL):
- Use dark outlines ONLY for internal features (eyes, mouth, limb separations, wing segments)
- DO NOT draw a black or dark border/outline around the entire creature silhouette
- The creature edges should blend directly into the white background — no outer stroke, no halo, no dark rim
- Think Pokemon Gen 2-3 sprites: the character outline is defined by color contrast, NOT by a black border

Create a wide horizontal sprite sheet with 4 distinct idle animation frames showing smooth looping movement. The creature must visually match the description above.''';

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
}
