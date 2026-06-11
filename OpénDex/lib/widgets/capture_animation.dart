import 'dart:math' as math;

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
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _scale = Tween<double>(begin: 0.7, end: 1.25)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_controller);
    _rotation = Tween<double>(begin: 0, end: 2)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _glow = Tween<double>(begin: 0.15, end: 0.45)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_controller);

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
      builder: (context, child) => Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.redAccent.withValues(alpha: _glow.value),
            ),
          ),
          // Inner glow
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: _glow.value * 0.5),
            ),
          ),
          // Main icon
          Transform.rotate(
            angle: _rotation.value * math.pi,
            child: Transform.scale(
              scale: _scale.value,
              child: const _PokeballIcon(
                size: 72,
                color: Colors.white,
              ),
            ),
          ),
          // Text below
          Positioned(
            bottom: -40,
            child: Text(
              'GENERATING...',
              style: TextStyle(
                fontFamily: 'VT323',
                fontSize: 18,
                color: Colors.white.withValues(alpha: 0.9),
                letterSpacing: 2,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 4,
                    offset: const Offset(1, 1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Custom Pokeball Icon ──────────────────────────────────────────────────
class _PokeballIcon extends StatelessWidget {
  final double size;
  final Color color;

  const _PokeballIcon({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _PokeballIconPainter(color: color),
    );
  }
}

class _PokeballIconPainter extends CustomPainter {
  final Color color;

  _PokeballIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    // Top half
    final topPaint = Paint()
      ..color = const Color(0xFFDC0A2D)
      ..style = PaintingStyle.fill;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi,
      math.pi,
      true,
      topPaint,
    );

    // Bottom half
    final bottomPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      math.pi,
      true,
      bottomPaint,
    );

    // Center line
    final linePaint = Paint()
      ..color = const Color(0xFF2A2A2A)
      ..strokeWidth = 3;
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      linePaint,
    );

    // Center button
    final buttonBorder = Paint()
      ..color = const Color(0xFF2A2A2A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, radius * 0.3, buttonBorder);

    final buttonFill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.24, buttonFill);

    // Inner button
    final innerButton = Paint()
      ..color = const Color(0xFFDC0A2D).withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.14, innerButton);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
