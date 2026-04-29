import 'dart:typed_data';

import 'package:flutter/material.dart';

class PixelArtPreview extends StatelessWidget {
  final Uint8List imageBytes;
  final double maxSize;

  const PixelArtPreview({super.key, required this.imageBytes, this.maxSize = 512});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        color: Colors.black12,
        padding: const EdgeInsets.all(8),
        child: Image.memory(
          imageBytes,
          width: maxSize,
          height: maxSize,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.none, // keep pixels crisp
          isAntiAlias: false,
        ),
      ),
    );
  }
}
