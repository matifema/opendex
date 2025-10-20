import 'dart:io';
import 'dart:typed_data';

import '../../models/pokemon_models.dart';

abstract class AiImageService {
  Future<Uint8List> generatePixelMon({
    required List<File> photos,
    required String prompt,
    int size = 256,
  });
}

abstract class AiTextService {
  Future<GeneratedSpec> generateNameAndStats({
    required String animalDescription,
  });
}
