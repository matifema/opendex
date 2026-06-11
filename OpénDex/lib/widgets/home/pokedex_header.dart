import 'package:flutter/material.dart';

class PokedexHeader extends StatelessWidget {
  final VoidCallback onSettingsPressed;

  const PokedexHeader({
    super.key,
    required this.onSettingsPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 140,
      child: CustomPaint(
        painter: PokedexHeaderPainter(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Stack(
            children: [
              // Title aligned vertically with lens center (y≈77) and
              // horizontally starting at the first red dot (x≈115)
              Positioned(
                left: 100,
                top: 40,
                right: 64,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'OpénDex',
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontSize: 62,
                      color: Colors.white,
                      letterSpacing: 1,
                      shadows: const [
                        Shadow(
                          color: Color(0x99000000),
                          offset: Offset(2, 4),
                          blurRadius: 8,
                        ),
                        Shadow(
                          color: Color(0xFFB80828),
                          offset: Offset(0, 2),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Settings button aligned with blue lens center
              Positioned(
                right: 0,
                top: 36,
                child: _buildHardwareButton(
                  icon: Icons.settings,
                  color: const Color(0xFF1976D2),
                  onPressed: onSettingsPressed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHardwareButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color, color.withValues(alpha: 0.7)],
              center: const Alignment(-0.2, -0.2),
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class PokedexHeaderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Base red with slight gradient
    final basePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFDC0A2D), Color(0xFFB80828)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), basePaint);

    // Diagonal accent stripe
    final stripePaint = Paint()
      ..color = const Color(0xFFC00822)
      ..style = PaintingStyle.fill;
    final stripePath = Path()
      ..moveTo(size.width * 0.6, 0)
      ..lineTo(size.width * 0.8, 0)
      ..lineTo(size.width * 0.5, size.height)
      ..lineTo(size.width * 0.3, size.height)
      ..close();
    canvas.drawPath(stripePath, stripePaint);

    // Blue Lens
    final lensCenter = Offset(50, size.height * 0.55);
    final lensRadius = 36.0;

    // Outer shadow
    final lensShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(lensCenter, lensRadius + 2, lensShadowPaint);

    // Main lens body
    final lensPaint = Paint()
      ..color = const Color(0xFF1976D2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(lensCenter, lensRadius, lensPaint);

    // Lens inner gradient for 3D glass effect
    final lensGradientPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.4),
          Colors.transparent,
        ],
        center: const Alignment(-0.3, -0.3),
        radius: 0.6,
      ).createShader(Rect.fromCircle(center: lensCenter, radius: lensRadius));
    canvas.drawCircle(lensCenter, lensRadius, lensGradientPaint);

    // Lens highlight (top-left reflection)
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(lensCenter.dx - 8, lensCenter.dy - 10), 12, highlightPaint);

    // Secondary highlight
    final highlight2Paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(lensCenter.dx - 14, lensCenter.dy - 4), 5, highlight2Paint);

    // Lens border
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(lensCenter, lensRadius, borderPaint);

    // Small indicator lights with glow
    final lightData = [
      (Colors.red.shade600, true),
      (Colors.amber.shade600, false),
      (Colors.green.shade600, false),
    ];

    for (int i = 0; i < 3; i++) {
      final (color, isActive) = lightData[i];
      final pos = Offset(115.0 + (i * 28), 32);

      // Glow effect for active
      if (isActive) {
        final glowPaint = Paint()
          ..color = color.withValues(alpha: 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawCircle(pos, 14, glowPaint);
      }

      // Light body
      final lightPaint = Paint()..color = color;
      canvas.drawCircle(pos, 9, lightPaint);

      // Light highlight (glass)
      final lightHighlight = Paint()
        ..color = Colors.white.withValues(alpha: 0.4)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(pos.dx - 2, pos.dy - 2), 4, lightHighlight);

      // Light border
      final lightBorder = Paint()
        ..color = Colors.white.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(pos, 9, lightBorder);
    }

    // Subtle bottom highlight line
    final bottomHighlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, size.height - 2, size.width, 2), bottomHighlight);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BlinkingDot extends StatefulWidget {
  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _opacity = Tween<double>(begin: 1.0, end: 0.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, child) => Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: const Color(0xFF33FF33).withValues(alpha: _opacity.value),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
