import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config.dart';
import '../models/pokemon_models.dart';

class BackendService {
  final String baseUrl;

  BackendService({String? baseUrl}) : baseUrl = baseUrl ?? kApiBaseUrl;

  Future<BackendGenerationResult> generateCreature({
    required File photo,
    required String description,
  }) async {
    if (baseUrl.isEmpty) {
      throw StateError('API_BASE_URL is not set. Configure it in Settings.');
    }

    final url = Uri.parse('${baseUrl.replaceAll(RegExp(r"/$"), "")}/generate/creature');
    final request = http.MultipartRequest('POST', url)
      ..fields['description'] = description;


    final stream = http.ByteStream(photo.openRead());
    final length = await photo.length();
    request.files.add(http.MultipartFile(
      'photo',
      stream,
      length,
      filename: 'photo.jpg',
      contentType: MediaType('image', 'jpeg'),
    ));

    final response = await http.Response.fromStream(await request.send());

    if (response.statusCode != 200) {
      // Try to parse error message
      try {
        final errorData = jsonDecode(response.body);
        throw HttpException(errorData['error'] ?? response.body);
      } catch (_) {
        throw HttpException('Generation failed: ${response.statusCode} ${response.body}');
      }
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    
    // Parse Stats
    final statsData = data['stats'] as Map<String, dynamic>;
    final types = ((statsData['types'] as List?)?.cast<String>() ?? <String>[])
        .map(parseCreatureType)
        .toList();
    
    final primaryType = types.isNotEmpty ? types.first : CreatureType.beast;
    final CreatureType? secondaryType = types.length > 1 ? types[1] : null;
    
    final stats = CreatureStats(
      hp: statsData['hp'] as int,
      attack: statsData['attack'] as int,
      defense: statsData['defense'] as int,
      speed: statsData['speed'] as int,
    );

    final spec = GeneratedSpec(
      name: statsData['name'] as String,
      flavorText: statsData['flavorText'] as String,
      primaryType: primaryType,
      secondaryType: secondaryType,
      stats: stats,
    );

    // Parse Image (Base64)
    final imageBytes = base64Decode(data['image'] as String);

    return BackendGenerationResult(spec: spec, imageBytes: imageBytes);
  }
}

class BackendGenerationResult {
  final GeneratedSpec spec;
  final Uint8List imageBytes;

  BackendGenerationResult({required this.spec, required this.imageBytes});
}
