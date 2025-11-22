import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../config.dart';
import 'ai_service.dart';

class HttpImageService implements AiImageService {
  final String baseUrl;

  HttpImageService({required this.baseUrl});

  @override
  Future<Uint8List> generateCreatureImage({
    required List<File> photos,
    required String prompt,
    int size = 256,
  }) async {
    final url = Uri.parse('${baseUrl.replaceAll(RegExp(r"/$"), "")}/generate/pixelmon');
    if (baseUrl.isEmpty) {
      throw StateError('API_BASE_URL is not set. Configure it in Settings.');
    }
    final request = http.MultipartRequest('POST', url)
      ..fields['prompt'] = prompt
      ..fields['size'] = size.toString();

    for (var i = 0; i < photos.length; i++) {
      final file = photos[i];
      final stream = http.ByteStream(file.openRead());
      final length = await file.length();
      request.files.add(http.MultipartFile('photos', stream, length, filename: 'photo_$i.jpg'));
    }

    final response = await http.Response.fromStream(await request.send());

    if (response.statusCode != 200) {
      throw HttpException('Image generation failed: ${response.statusCode} ${response.reasonPhrase} ${response.body}');
    }

    // Expect raw PNG bytes
    return response.bodyBytes;
  }
}
