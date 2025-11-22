import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

class SpriteSheetAnimation extends StatefulWidget {
  final Uint8List imageBytes;
  final int frameCount;
  final double size;
  final Duration frameDuration;

  const SpriteSheetAnimation({
    super.key,
    required this.imageBytes,
    this.frameCount = 4,
    this.size = 128, // Display size
    this.frameDuration = const Duration(milliseconds: 200),
  });

  @override
  State<SpriteSheetAnimation> createState() => _SpriteSheetAnimationState();
}

class _SpriteSheetAnimationState extends State<SpriteSheetAnimation> {
  int _currentFrame = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  void _startAnimation() {
    _timer = Timer.periodic(widget.frameDuration, (timer) {
      if (mounted) {
        setState(() {
          _currentFrame = (_currentFrame + 1) % widget.frameCount;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // We assume the sprite sheet is horizontal: (width = height * frameCount)
    // We want to show 1 frame.
    // We use a Stack with a Positioned Image to "crop" the view.
    
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRect(
        child: Stack(
          children: [
            Positioned(
              left: -_currentFrame * widget.size,
              top: 0,
              child: Image.memory(
                widget.imageBytes,
                width: widget.size * widget.frameCount,
                height: widget.size,
                fit: BoxFit.fill, // Stretch to fill the calculated strip size
                filterQuality: FilterQuality.none,
                isAntiAlias: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
