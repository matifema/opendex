import 'package:flutter/material.dart';

/// Pokédex mechanical opening animation.
///
/// Two large red halves of the Pokédex slide apart over the actual
/// home screen content, revealing the camera viewfinder in the gap.
/// The home screen stays visible behind, dimmed but present.
class DexOpenAnimation extends StatefulWidget {
  final VoidCallback onComplete;

  const DexOpenAnimation({super.key, required this.onComplete});

  @override
  State<DexOpenAnimation> createState() => _DexOpenAnimationState();
}

class _DexOpenAnimationState extends State<DexOpenAnimation>
    with TickerProviderStateMixin {
  late final AnimationController _outerController;
  late final AnimationController _innerController;

  // Panels slide apart
  late final Animation<double> _topPanelY;
  late final Animation<double> _bottomPanelY;
  late final Animation<double> _hingeScale;

  // Inner screen
  late final Animation<double> _screenScale;
  late final Animation<double> _screenOpacity;
  late final Animation<double> _screenRotation;

  // Camera lens iris
  late final Animation<double> _irisRadius;
  late final Animation<double> _cameraFade;

  // Flash
  late final Animation<double> _flashOpacity;

  static const _kPokedexRed = Color(0xFFDC0A2D);
  static const _kPokedexDarkRed = Color(0xFFB80828);
  static const _kLcdGreen = Color(0xFF98CB98);

  @override
  void initState() {
    super.initState();

    _outerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _innerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    final screenH = MediaQuery.of(context).size.height;

    // ── Outer panels (slide apart from center) ──────────────
    // Start covering the screen, then slide away
    _topPanelY = Tween<double>(begin: 0, end: -(screenH * 0.48)).animate(
      CurvedAnimation(
        parent: _outerController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOutCubicEmphasized),
      ),
    );

    _bottomPanelY = Tween<double>(begin: 0, end: -(screenH * 0.48)).animate(
      CurvedAnimation(
        parent: _outerController,
        curve: const Interval(0.1, 0.7, curve: Curves.easeInOutCubicEmphasized),
      ),
    );

    _hingeScale = Tween<double>(begin: 1.0, end: 0.3).animate(
      CurvedAnimation(
        parent: _outerController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );

    // ── Inner screen zoom ───────────────────────────────────
    _screenScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _innerController,
        curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
      ),
    );

    _screenOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _innerController,
        curve: const Interval(0.15, 0.6, curve: Curves.easeOut),
      ),
    );

    _screenRotation = Tween<double>(begin: -0.15, end: 0.0).animate(
      CurvedAnimation(
        parent: _innerController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOutBack),
      ),
    );

    // ── Camera iris / lens ──────────────────────────────────
    _irisRadius = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _innerController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOutCubicEmphasized),
      ),
    );

    _cameraFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _innerController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );

    // ── Lens flash burst ────────────────────────────────────
    _flashOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 5),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.0), weight: 80),
    ]).animate(
      CurvedAnimation(
        parent: _innerController,
        curve: const Interval(0.75, 1.0, curve: Curves.easeInOut),
      ),
    );

    _startAnimation();
  }

  Future<void> _startAnimation() async {
    await _outerController.forward();
    await _innerController.forward();
    if (mounted) widget.onComplete();
  }

  @override
  void dispose() {
    _outerController.dispose();
    _innerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final panelH = screenH * 0.55;

    return AnimatedBuilder(
      animation: Listenable.merge([_outerController, _innerController]),
      builder: (context, child) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // ── Semi-transparent darkening overlay ─────────────
            // Home screen content is visible behind
            Container(
              color: Colors.black.withValues(alpha: 0.45),
            ),

            // ── Mechanical hinge center ──────────────────────
            Center(
              child: Transform.scale(
                scale: _hingeScale.value,
                child: Container(
                  width: 80,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_kPokedexRed, _kPokedexDarkRed],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 24,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFF111111),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFF444444)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: Color(0xFF33FF33),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF4444),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Top panel (slides UP, away from center) ──────
            Positioned(
              top: _topPanelY.value,
              left: 0,
              right: 0,
              child: Container(
                height: panelH,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_kPokedexRed, _kPokedexDarkRed],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Hinge detail at bottom edge
                    Container(
                      height: 14,
                      margin: const EdgeInsets.symmetric(horizontal: 60),
                      decoration: BoxDecoration(
                        color: const Color(0xFF333333),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: const Color(0xFF555555),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(
                          7,
                          (_) => Container(
                            width: 2,
                            height: 8,
                            color: const Color(0xFF222222),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // ── Bottom panel (slides DOWN, away from center) ─
            Positioned(
              bottom: _bottomPanelY.value,
              left: 0,
              right: 0,
              child: Container(
                height: panelH,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_kPokedexDarkRed, Color(0xFF8B001A)],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 16,
                      offset: const Offset(0, -8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    // Hinge detail at top edge
                    Container(
                      height: 14,
                      margin: const EdgeInsets.symmetric(horizontal: 60),
                      decoration: BoxDecoration(
                        color: const Color(0xFF333333),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: const Color(0xFF555555),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(
                          7,
                          (_) => Container(
                            width: 2,
                            height: 8,
                            color: const Color(0xFF222222),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Inner LCD Screen (scales up from center) ─────
            Center(
              child: Opacity(
                opacity: _screenOpacity.value,
                child: Transform.scale(
                  scale: _screenScale.value,
                  child: Transform.rotate(
                    angle: _screenRotation.value,
                    child: Container(
                      width: 280,
                      height: 200,
                      decoration: BoxDecoration(
                        color: _kLcdGreen,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF8B7355),
                          width: 6,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Stack(
                          children: [
                            // Scanlines
                            Positioned.fill(
                              child: CustomPaint(painter: _ScanlinePainter()),
                            ),
                            // Camera iris circle
                            Center(
                              child: SizedBox(
                                width: 160 * _irisRadius.value,
                                height: 160 * _irisRadius.value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF5A6E5A),
                                      width: 3,
                                    ),
                                    gradient: const RadialGradient(
                                      colors: [
                                        Color(0xFF88B888),
                                        _kLcdGreen,
                                      ],
                                    ),
                                  ),
                                  child: Center(
                                    child: Opacity(
                                      opacity: _cameraFade.value,
                                      child: SizedBox(
                                        width: 140,
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.camera_alt,
                                              size: 48,
                                              color: const Color(0xFF2A3A2A)
                                                  .withValues(alpha: 0.6),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'READY\nTO CATCH',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontFamily: 'VT323',
                                                fontSize: 18,
                                                color: const Color(0xFF2A3A2A)
                                                    .withValues(alpha: 0.7),
                                                letterSpacing: 2,
                                                height: 1.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Flash overlay
                            Positioned.fill(
                              child: Container(
                                color: Colors.white.withValues(
                                  alpha: _flashOpacity.value * 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Status text at bottom ────────────────────────
            Positioned(
              bottom: 60 + _bottomPanelY.value.clamp(0, 9999),
              left: 0,
              right: 0,
              child: Center(
                child: Opacity(
                  opacity: _cameraFade.value,
                  child: Text(
                    'DEX OPENING...',
                    style: TextStyle(
                      fontFamily: 'VT323',
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.9),
                      letterSpacing: 3,
                      shadows: const [
                        Shadow(
                          color: Color(0x99000000),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Scanline Painter ───────────────────────────────────────────────────────
class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x1A000000);
    const lineHeight = 3.0;
    for (double y = 0; y < size.height; y += lineHeight * 2) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, lineHeight), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
