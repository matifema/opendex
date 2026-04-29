import 'dart:typed_data';

import 'package:image/image.dart';

/// Post-processes a raw PNG image (e.g., from Gemini image generation) by:
/// 1. Converting near-white background pixels to transparent
/// 2. Resizing to exactly 256×64 pixels using nearest-neighbor interpolation
///
/// Replicates the Python PIL/Pillow logic:
///   - if R > 240 and G > 240 and B > 240: set alpha to 0
///   - resize to (256, 64) with NEAREST resampling
Future<Uint8List> processSpriteSheet(Uint8List imageBytes) async {
  // Decode the input image
  final Image? image = decodeImage(imageBytes);
  if (image == null) {
    throw ArgumentError('Unable to decode image from provided bytes');
  }

  // Ensure we work with RGBA (4 channels)
  final Image workingImage = image.numChannels != 4
      ? _convertToRgba(image)
      : image;

  // Iterate all pixels: make near-white pixels transparent
  final int width = workingImage.width;
  final int height = workingImage.height;
  final Uint8List pixels = workingImage.data!.getBytes();
  for (int i = 0; i < width * height; i++) {
    final int offset = i * 4;
    final int r = pixels[offset];
    final int g = pixels[offset + 1];
    final int b = pixels[offset + 2];
    if (r > 240 && g > 240 && b > 240) {
      pixels[offset + 3] = 0; // Set alpha to 0 (transparent)
    }
  }

  // Resize to exactly 256×64 using nearest-neighbor (no smoothing)
  final Image resized = copyResize(
    workingImage,
    width: 256,
    height: 64,
    interpolation: Interpolation.nearest,
  );

  // Encode as PNG and return bytes
  return encodePng(resized);
}

/// Converts an image with fewer than 4 channels to RGBA.
Image _convertToRgba(Image image) {
  final int channels = image.numChannels;
  final Uint8List src = image.data!.getBytes();
  final int pixelCount = image.width * image.height;
  final Uint8List rgba = Uint8List(pixelCount * 4);

  for (int i = 0; i < pixelCount; i++) {
    final int srcOffset = i * channels;
    final int dstOffset = i * 4;
    rgba[dstOffset] = src[srcOffset]; // R
    rgba[dstOffset + 1] = channels > 1 ? src[srcOffset + 1] : src[srcOffset]; // G
    rgba[dstOffset + 2] = channels > 2 ? src[srcOffset + 2] : src[srcOffset]; // B
    rgba[dstOffset + 3] = channels > 3 ? src[srcOffset + 3] : 255; // A (default opaque)
  }

  return Image.fromBytes(
    width: image.width,
    height: image.height,
    bytes: rgba.buffer,
    numChannels: 4,
  );
}
