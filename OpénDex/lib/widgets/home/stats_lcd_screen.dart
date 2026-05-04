import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/pokemon_models.dart';

/// LCD color palette
class _LcdColors {
  static const background = Color(0xFF1A1A1A);
  static const screenBg = Color(0xFF0D1A0D);
  static const border = Color(0xFF555555);
  static const borderInner = Color(0xFF2A2A2A);
  static const phosphor = Color(0xFF33FF33);
  static const phosphorDim = Color(0xFF1A801A);
  static const phosphorMid = Color(0xFF99FF33);
  static const phosphorHigh = Color(0xFFFFCC33);
  static const segmentOff = Color(0xFF1A2A1A);
  static const gridLine = Color(0x0A33FF33);
}

class StatsLcdScreen extends StatelessWidget {
  final Creature? creature;
  final int creatureCount;

  const StatsLcdScreen({
    super.key,
    required this.creature,
    required this.creatureCount,
  });

  TextStyle _lcdTextStyle({
    required double fontSize,
    FontWeight fontWeight = FontWeight.normal,
    double letterSpacing = 1.5,
  }) {
    return GoogleFonts.vt323(
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      color: _LcdColors.phosphor,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      decoration: BoxDecoration(
        color: _LcdColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _LcdColors.border, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSpeciesCounter(creatureCount),
            const SizedBox(height: 6),
            // Inner LCD screen recess
            Container(
              decoration: BoxDecoration(
                color: _LcdColors.screenBg,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: _LcdColors.borderInner,
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              child: Stack(
                children: [
                  // Faint LCD grid overlay
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _LcdGridPainter(),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: creature != null
                        ? _buildCreaturePanel(creature!)
                        : _buildEmptyState(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeciesCounter(int count) {
    return Row(
      children: [
        Text(
          'SPECIES CAUGHT',
          style: _lcdTextStyle(fontSize: 11, letterSpacing: 2),
        ),
        const Spacer(),
        Text(
          count.toString().padLeft(3, '0'),
          style: _lcdTextStyle(fontSize: 16, letterSpacing: 2),
        ),
      ],
    );
  }

  Widget _buildCreaturePanel(Creature creature) {
    final header = _buildCreatureHeader(creature);
    final stats = _buildStats(creature.stats);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        const SizedBox(height: 6),
        // Divider line
        Container(
          height: 1,
          color: _LcdColors.phosphorDim.withValues(alpha: 0.4),
        ),
        const SizedBox(height: 6),
        stats,
      ],
    );
  }

  Widget _buildCreatureHeader(Creature creature) {
    final number = creature.id.isNotEmpty
        ? int.tryParse(creature.id) ?? 0
        : 0;
    final paddedNumber = number.toString().padLeft(3, '0');
    final displayName = creature.name.toUpperCase();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '#$paddedNumber',
          style: _lcdTextStyle(fontSize: 13, letterSpacing: 1),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            displayName,
            style: _lcdTextStyle(
              fontSize: 16,
              letterSpacing: 2,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStats(CreatureStats s) {
    final stats = [
      ('HP', s.hp),
      ('ATK', s.attack),
      ('DEF', s.defense),
      ('SPD', s.speed),
    ];

    return Column(
      children: stats.map((stat) {
        final (label, value) = stat;
        return Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 32,
                child: Text(
                  label,
                  style: _lcdTextStyle(fontSize: 12, letterSpacing: 1.5),
                ),
              ),
              SizedBox(
                width: 30,
                child: Text(
                  value.toString().padLeft(3, '0'),
                  textAlign: TextAlign.right,
                  style: _lcdTextStyle(fontSize: 14, letterSpacing: 1),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildLcdBar(value, 255),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLcdBar(int value, int max) {
    final ratio = value / max;
    final filledSegments = (ratio * 12).clamp(0, 12).toInt();
    final barColor = _getBarColor(ratio);

    return SizedBox(
      height: 14,
      child: CustomPaint(
        size: Size.infinite,
        painter: _LcdBarPainter(
          totalSegments: 12,
          filledSegments: filledSegments,
          barColor: barColor,
          offColor: _LcdColors.segmentOff,
        ),
      ),
    );
  }

  Color _getBarColor(double ratio) {
    if (ratio <= 0.35) {
      return _LcdColors.phosphor;
    } else if (ratio <= 0.65) {
      return _LcdColors.phosphorMid;
    } else {
      return _LcdColors.phosphorHigh;
    }
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: 72,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'NO DATA',
              style: _lcdTextStyle(fontSize: 16, letterSpacing: 3),
            ),
            const SizedBox(width: 4),
            // Static block cursor (LCD-style)
            Text(
              '\u2588',
              style: _lcdTextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

/// Paints a faint grid pattern to simulate an LCD pixel matrix.
class _LcdGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = _LcdColors.gridLine
      ..strokeWidth = 0.5;

    const spacing = 4.0;

    // Vertical lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }

    // Horizontal lines
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LcdGridPainter oldDelegate) => false;
}

/// Paints a segmented LCD stat bar with pronounced segment gaps.
class _LcdBarPainter extends CustomPainter {
  final int totalSegments;
  final int filledSegments;
  final Color barColor;
  final Color offColor;

  _LcdBarPainter({
    required this.totalSegments,
    required this.filledSegments,
    required this.barColor,
    required this.offColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const gapWidth = 2.0;
    final segmentWidth =
        (size.width - (gapWidth * (totalSegments - 1))) / totalSegments;

    final fillPaint = Paint()..color = barColor;
    final offPaint = Paint()..color = offColor;

    for (int i = 0; i < totalSegments; i++) {
      final dx = i * (segmentWidth + gapWidth);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(dx, 0, segmentWidth, size.height),
        const Radius.circular(1),
      );

      canvas.drawRRect(
        rect,
        i < filledSegments ? fillPaint : offPaint,
      );
    }

    // Subtle inner glow on filled segments for LCD phosphor effect
    if (filledSegments > 0) {
      final glowPaint = Paint()
        ..color = barColor.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      final glowWidth =
          filledSegments * segmentWidth + (filledSegments - 1) * gapWidth;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, glowWidth, size.height),
          const Radius.circular(2),
        ),
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LcdBarPainter oldDelegate) {
    return oldDelegate.filledSegments != filledSegments ||
        oldDelegate.barColor != barColor;
  }
}
