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
  final VoidCallback? onDPadUp;
  final VoidCallback? onDPadDown;

  const ControlPanel({
    super.key,
    required this.onCapturePressed,
    required this.onDPadLeft,
    required this.onDPadRight,
    this.onDPadUp,
    this.onDPadDown,
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
                      onUp: onDPadUp,
                      onDown: onDPadDown,
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
  final VoidCallback? onUp;
  final VoidCallback? onDown;

  const _DPad({
    required this.onLeft,
    required this.onRight,
    this.onUp,
    this.onDown,
  });

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
    const cx = size / 2;
    const cy = size / 2;
    const cornerRadius = 5.0;

    // Subtle bevel gradient for each arm based on direction
    LinearGradient armGradient(DPadDirection dir, bool pressed) {
      final base = pressed ? _kDPadPressed : _kDPadColor;
      final light = base.withValues(alpha: pressed ? 0.95 : 1.0);
      final dark = base.withValues(alpha: pressed ? 0.85 : 0.92);
      switch (dir) {
        case DPadDirection.up:
          return LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [light, dark],
          );
        case DPadDirection.down:
          return LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [light, dark],
          );
        case DPadDirection.left:
          return LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [light, dark],
          );
        case DPadDirection.right:
          return LinearGradient(
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
            colors: [light, dark],
          );
      }
    }

    Widget arm({
      required DPadDirection direction,
      required double width,
      required double height,
      required IconData icon,
      required bool interactive,
      required BorderRadius borderRadius,
    }) {
      final isPressed = _pressedDirection == direction;

      final child = Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          gradient: armGradient(direction, isPressed),
          boxShadow: [
            // Top-left highlight (bevel effect)
            BoxShadow(
              color: Colors.white.withValues(alpha: isPressed ? 0.02 : 0.06),
              offset: const Offset(-1, -1),
              blurRadius: 0,
              spreadRadius: 0,
            ),
            // Bottom-right shadow (bevel effect)
            BoxShadow(
              color: Colors.black.withValues(alpha: isPressed ? 0.15 : 0.25),
              offset: const Offset(1, 1),
              blurRadius: 0,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: Icon(
            icon,
            size: 16,
            color: Colors.white.withValues(
              alpha: isPressed ? 0.75 : 0.5,
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

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: _kPokedexDarkRed.withValues(alpha: 0.15),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Up arm (visual only)
          Positioned(
            left: cx - armW / 2,
            top: 0,
            child: arm(
              direction: DPadDirection.up,
              width: armW,
              height: armL,
              icon: Icons.arrow_upward,
              interactive: false,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(cornerRadius),
                topRight: Radius.circular(cornerRadius),
              ),
            ),
          ),
          // Down arm (visual only)
          Positioned(
            left: cx - armW / 2,
            bottom: 0,
            child: arm(
              direction: DPadDirection.down,
              width: armW,
              height: armL,
              icon: Icons.arrow_downward,
              interactive: false,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(cornerRadius),
                bottomRight: Radius.circular(cornerRadius),
              ),
            ),
          ),
          // Left arm (interactive)
          Positioned(
            top: cy - armW / 2,
            left: 0,
            child: arm(
              direction: DPadDirection.left,
              width: armL,
              height: armW,
              icon: Icons.arrow_back,
              interactive: true,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(cornerRadius),
                bottomLeft: Radius.circular(cornerRadius),
              ),
            ),
          ),
          // Right arm (interactive)
          Positioned(
            top: cy - armW / 2,
            right: 0,
            child: arm(
              direction: DPadDirection.right,
              width: armL,
              height: armW,
              icon: Icons.arrow_forward,
              interactive: true,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(cornerRadius),
                bottomRight: Radius.circular(cornerRadius),
              ),
            ),
          ),
          // Center pivot point (multi-layered for hardware feel)
          Positioned(
            left: cx - 14,
            top: cy - 14,
            child: SizedBox(
              width: 28,
              height: 28,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer ring (raised edge)
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _kDPadColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          offset: const Offset(0, 2),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                  ),
                  // Middle ring (slight recess)
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _kDPadPressed.withValues(alpha: 0.7),
                          _kDPadColor,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          offset: const Offset(0, 1),
                          blurRadius: 2,
                        ),
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.04),
                          offset: const Offset(-1, -1),
                          blurRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  // Center dot (pivot indentation)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _kDPadPressed.withValues(alpha: 0.6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          offset: const Offset(0, 1),
                          blurRadius: 1,
                        ),
                      ],
                    ),
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
