import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

class SpriteSheetAnimation extends StatefulWidget {
  final Uint8List imageBytes;
  final int frameCount;
  final double size;
  final Duration frameDuration;
  final bool playOnTap;

  const SpriteSheetAnimation({
    super.key,
    required this.imageBytes,
    this.frameCount = 4,
    this.size = 256,
    this.frameDuration = const Duration(milliseconds: 300),
    this.playOnTap = true,
  });

  @override
  State<SpriteSheetAnimation> createState() => _SpriteSheetAnimationState();
}

class _SpriteSheetAnimationState extends State<SpriteSheetAnimation> {
  int _currentFrame = 0;
  Timer? _timer;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    // Play one cycle when the widget is first loaded
    _playOneCycle();
  }

  void _playOneCycle() {
    if (_isPlaying) return; // Prevent multiple taps during animation
    
    setState(() {
      _isPlaying = true;
      _currentFrame = 0;
    });

    int frameCounter = 0;
    _timer = Timer.periodic(widget.frameDuration, (timer) {
      if (mounted) {
        frameCounter++;
        if (frameCounter < widget.frameCount) {
          setState(() {
            _currentFrame = frameCounter;
          });
        } else {
          timer.cancel();
          setState(() {
            _currentFrame = 0;
            _isPlaying = false;
          });
        }
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
    final imageWidget = Container(
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
                fit: BoxFit.fill,
                filterQuality: FilterQuality.none,
                isAntiAlias: false,
              ),
            ),
          ],
        ),
      ),
    );

    if (widget.playOnTap) {
      return GestureDetector(
        onTap: _playOneCycle,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}
