import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─── Opéndex Control Panel Colors ─────────────────────────────────────────────
const _kPokedexRed = Color(0xFFDC0A2D);
const _kPokedexDarkRed = Color(0xFFB80828);
const _kButtonRed = Color(0xFFE83050);
const _kDPadColor = Color(0xFF2A2A2A);
const _kDPadPressed = Color(0xFF3A3A3A);

enum DPadDirection { up, down, left, right }

// ─── Control Panel ────────────────────────────────────────────────────────────
class ControlPanel extends StatelessWidget {
  final VoidCallback onCapturePressed;
  final VoidCallback onDPadLeft;
  final VoidCallback onDPadRight;

  const ControlPanel({
    super.key,
    required this.onCapturePressed,
    required this.onDPadLeft,
    required this.onDPadRight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      height: 140,
      decoration: BoxDecoration(
        color: _kPokedexRed,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Recessed button area
            Positioned(
              top: 16,
              left: 12,
              right: 12,
              bottom: 12,
              child: Container(
                decoration: BoxDecoration(
                  color: _kPokedexDarkRed,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _CaptureButton(onPressed: onCapturePressed),
                    _DPad(
                      onLeft: onDPadLeft,
                      onRight: onDPadRight,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Capture Button ───────────────────────────────────────────────────────────
class _CaptureButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _CaptureButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: SizedBox(
        width: 64,
        height: 64,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _kButtonRed,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: CustomPaint(
              size: const Size(28, 28),
              painter: _PokeballIconPainter(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Pokéball Icon Painter ────────────────────────────────────────────────────
class _PokeballIconPainter extends CustomPainter {
  final Color color;

  _PokeballIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 1;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Top half
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi,
      math.pi,
      true,
      paint,
    );

    // Bottom half (slightly transparent)
    paint.color = color.withValues(alpha: 0.7);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      math.pi,
      true,
      paint,
    );

    // Center line
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      linePaint,
    );

    // Center button
    canvas.drawCircle(center, radius * 0.25, paint);
  }

  @override
  bool shouldRepaint(covariant _PokeballIconPainter oldDelegate) =>
      oldDelegate.color != color;
}

// ─── D-Pad (Left/Right active, Up/Down visual) ────────────────────────────────
class _DPad extends StatefulWidget {
  final VoidCallback onLeft;
  final VoidCallback onRight;

  const _DPad({required this.onLeft, required this.onRight});

  @override
  State<_DPad> createState() => _DPadState();
}

class _DPadState extends State<_DPad> {
  DPadDirection? _pressedDirection;

  void _onPress(DPadDirection dir) {
    setState(() => _pressedDirection = dir);
  }

  void _onRelease(DPadDirection dir) {
    setState(() => _pressedDirection = null);
    switch (dir) {
      case DPadDirection.left:
        widget.onLeft();
      case DPadDirection.right:
        widget.onRight();
      case DPadDirection.up:
      case DPadDirection.down:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    const size = 96.0;
    const armW = 32.0;
    const armL = 48.0;
    final cx = size / 2;
    final cy = size / 2;

    Widget arm({
      required DPadDirection direction,
      required double left,
      required double top,
      required double width,
      required double height,
      required IconData icon,
      required bool interactive,
    }) {
      final isPressed = _pressedDirection == direction;
      final color = isPressed ? _kDPadPressed : _kDPadColor;

      final child = Container(
        width: width,
        height: height,
        color: color,
        child: Center(
          child: Icon(
            icon,
            size: 16,
            color: Colors.white.withValues(
              alpha: isPressed ? 0.6 : 0.35,
            ),
          ),
        ),
      );

      return interactive
          ? GestureDetector(
              onTapDown: (_) => _onPress(direction),
              onTapUp: (_) => _onRelease(direction),
              onTapCancel: () => setState(() => _pressedDirection = null),
              child: child,
            )
          : child;
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Up arm (visual only)
          Positioned(
            left: cx - armW / 2,
            top: 0,
            child: arm(
              direction: DPadDirection.up,
              left: cx - armW / 2,
              top: 0,
              width: armW,
              height: armL,
              icon: Icons.arrow_upward,
              interactive: false,
            ),
          ),
          // Down arm (visual only)
          Positioned(
            left: cx - armW / 2,
            bottom: 0,
            child: arm(
              direction: DPadDirection.down,
              left: cx - armW / 2,
              top: 0,
              width: armW,
              height: armL,
              icon: Icons.arrow_downward,
              interactive: false,
            ),
          ),
          // Left arm (interactive)
          Positioned(
            top: cy - armW / 2,
            left: 0,
            child: arm(
              direction: DPadDirection.left,
              left: 0,
              top: cy - armW / 2,
              width: armL,
              height: armW,
              icon: Icons.arrow_back,
              interactive: true,
            ),
          ),
          // Right arm (interactive)
          Positioned(
            top: cy - armW / 2,
            right: 0,
            child: arm(
              direction: DPadDirection.right,
              left: 0,
              top: cy - armW / 2,
              width: armL,
              height: armW,
              icon: Icons.arrow_forward,
              interactive: true,
            ),
          ),
          // Center circle
          Positioned(
            left: cx - 12,
            top: cy - 12,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: _kDPadColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
