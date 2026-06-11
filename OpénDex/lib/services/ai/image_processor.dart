import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart';

/// Post-processes a raw PNG image (e.g. from Gemini) into a 256x64 transparent-background sprite sheet.
///
/// Instead of a flood-fill + morphological close pipeline, we use a simple global white-keying pass:
/// pixels whose darkest channel is near-white become transparent. This removes the background,
/// anti-aliased halos, and enclosed white holes in one pass. The result is resized to 256x64.
Future<Uint8List> processSpriteSheet(Uint8List imageBytes) {
  return compute(_processSpriteSheetIsolate, imageBytes);
}

Future<Uint8List> _processSpriteSheetIsolate(Uint8List imageBytes) async {
  final Image? decoded = decodeImage(imageBytes);
  if (decoded == null) {
    throw ArgumentError('Unable to decode image from provided bytes');
  }

  final Image img = decoded.numChannels != 4
      ? _cloneToRgba(decoded)
      : copyCrop(decoded, x: 0, y: 0, width: decoded.width, height: decoded.height);

  final int w = img.width;
  final int h = img.height;
  final Uint8List px = img.getBytes();

  // Thresholds tuned for pure-white (#FFFFFF) backgrounds while preserving
  // legitimate near-white creature highlights (#E0E0E0 and darker).
  const int whiteThreshold = 235;   // min channel >= this => fully transparent
  const int opaqueThreshold = 210;  // min channel <= this => fully opaque
  const int ramp = whiteThreshold - opaqueThreshold; // 25

  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      final int o = (y * w + x) * 4;
      final int r = px[o];
      final int g = px[o + 1];
      final int b = px[o + 2];

      // "How non-white is this pixel?" measured by the darkest channel.
      final int minCh = r < g ? (r < b ? r : b) : (g < b ? g : b);

      final int alpha;
      if (minCh >= whiteThreshold) {
        alpha = 0;
      } else if (minCh <= opaqueThreshold) {
        alpha = 255;
      } else {
        alpha = ((whiteThreshold - minCh) * 255 ~/ ramp).clamp(0, 255);
      }

      px[o + 3] = alpha;
    }
  }

  final Image resized = copyResize(
    img,
    width: 256,
    height: 64,
    interpolation: Interpolation.nearest,
  );

  return Uint8List.fromList(encodePng(resized));
}

Image _cloneToRgba(Image src) {
  final int ch = src.numChannels;
  final Uint8List srcBuf = src.getBytes();
  final int pxCount = src.width * src.height;
  final Uint8List rgba = Uint8List(pxCount * 4);

  for (int i = 0; i < pxCount; i++) {
    final int so = i * ch;
    final int d = i * 4;
    rgba[d] = srcBuf[so];
    rgba[d + 1] = ch > 1 ? srcBuf[so + 1] : srcBuf[so];
    rgba[d + 2] = ch > 2 ? srcBuf[so + 2] : srcBuf[so];
    rgba[d + 3] = 255;
  }

  return Image.fromBytes(
    width: src.width,
    height: src.height,
    bytes: rgba.buffer,
    numChannels: 4,
  );
}
