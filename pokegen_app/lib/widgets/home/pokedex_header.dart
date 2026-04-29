import 'package:flutter/material.dart';

class PokedexHeader extends StatelessWidget {
  final VoidCallback onSettingsPressed;
  final VoidCallback onBattlePressed;
  final bool canBattle;

  const PokedexHeader({
    super.key,
    required this.onSettingsPressed,
    required this.onBattlePressed,
    required this.canBattle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 120,
      child: CustomPaint(
        painter: PokedexHeaderPainter(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 80),
              Expanded(
                child: Text(
                  'OpénDex',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 50,
                      shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.5),
                        offset: const Offset(2, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  _buildHardwareButton(
                    icon: Icons.settings,
                    color: Colors.blue.shade700,
                    onPressed: onSettingsPressed,
                  ),
                  const SizedBox(width: 12),
                  _buildHardwareButton(
                    icon: Icons.sports_mma,
                    color: Colors.red.shade700,
                    onPressed: onBattlePressed,
                  ),
                ],
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
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}

class PokedexHeaderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFDC0A2D);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Blue Lens (larger, more detailed)
    final lensPaint = Paint()
      ..color = Colors.blue.shade700
      ..style = PaintingStyle.fill;

    final lensHighlight = Paint()
      ..color = Colors.blue.shade300
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    // Main lens
    canvas.drawCircle(const Offset(50, 60), 35, lensPaint);
    // Highlight
    canvas.drawCircle(const Offset(45, 55), 12, lensHighlight);
    // Border
    canvas.drawCircle(const Offset(50, 60), 35, borderPaint);

    // Small indicator lights
    final lights = [
      Colors.red.shade700,
      Colors.yellow.shade700,
      Colors.green.shade700
    ];
    for (int i = 0; i < 3; i++) {
      final lightPaint = Paint()..color = lights[i];
      final lightBorder = Paint()
        ..color = Colors.white70
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(Offset(110.0 + (i * 28), 30), 10, lightPaint);
      canvas.drawCircle(Offset(110.0 + (i * 28), 30), 10, lightBorder);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
