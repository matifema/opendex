import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

class StorageService {
  Future<String> savePngBytes(Uint8List pngBytes, {String? fileName}) async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/pixelmon');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final name = fileName ?? 'pixelmon_${DateTime.now().millisecondsSinceEpoch}.png';
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(pngBytes, flush: true);
    return file.path;
  }
}
