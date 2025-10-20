import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../../config.dart';
import '../../models/pokemon_models.dart';
import 'ai_service.dart';
import 'prompts.dart';

class GoogleTextService implements AiTextService {
  GoogleTextService()
      : _model = GenerativeModel(
          model: 'gemini-1.5-flash-latest',
          apiKey: kGeminiApiKey,
          generationConfig: const GenerationConfig(
            responseMimeType: 'application/json',
            temperature: 0.9,
          ),
        );

  final GenerativeModel _model;

  @override
  Future<GeneratedSpec> generateNameAndStats({required String animalDescription}) async {
    if (kGeminiApiKey.isEmpty) {
      throw StateError('GEMINI_API_KEY is not set. Pass via --dart-define=GEMINI_API_KEY=...');
    }

    final prompt = buildStatsPrompt(animalDescription: animalDescription);
    final response = await _model.generateContent([Content.text(prompt)]);
    final text = response.text?.trim();
    if (text == null || text.isEmpty) {
      throw StateError('Empty response from text model');
    }

    // Ensure pure JSON (some models may add code fences despite mime type)
    final jsonString = _extractJson(text);
    final Map<String, dynamic> data = jsonDecode(jsonString) as Map<String, dynamic>;

    final types = ((data['types'] as List?)?.cast<String>() ?? <String>[])
        .map(parsePokemonType)
        .toList();

    final primaryType = types.isNotEmpty ? types.first : PokemonType.normal;
    final PokemonType? secondaryType = types.length > 1 ? types[1] : null;

    final stats = PokemonStats.fromJson((data['stats'] as Map).cast<String, dynamic>());

    return GeneratedSpec(
      name: (data['name'] as String).trim(),
      flavorText: ((data['flavorText'] as String?) ?? '').trim(),
      primaryType: primaryType,
      secondaryType: secondaryType,
      stats: stats,
    );
  }

  String _extractJson(String input) {
    final fenceStart = input.indexOf('{');
    final fenceEnd = input.lastIndexOf('}');
    if (fenceStart != -1 && fenceEnd != -1 && fenceEnd > fenceStart) {
      return input.substring(fenceStart, fenceEnd + 1);
    }
    return input;
  }
}
