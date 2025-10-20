import 'package:flutter/material.dart';

class CaptureAnimation extends StatefulWidget {
  final bool playing;

  const CaptureAnimation({super.key, required this.playing});

  @override
  State<CaptureAnimation> createState() => _CaptureAnimationState();
}

class _CaptureAnimationState extends State<CaptureAnimation> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _scale = Tween<double>(begin: 0.8, end: 1.2).chain(CurveTween(curve: Curves.easeInOut)).animate(_controller);
    _rotation = Tween<double>(begin: 0, end: 2).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.playing) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant CaptureAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playing && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.playing && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => Transform.rotate(
        angle: _rotation.value * 3.14159,
        child: Transform.scale(
          scale: _scale.value,
          child: Icon(
            Icons.catching_pokemon,
            color: Colors.redAccent.shade200,
            size: 72,
          ),
        ),
      ),
    );
  }
}
