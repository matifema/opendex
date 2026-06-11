import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../models/pokemon_models.dart';
import '../../widgets/capture_animation.dart';
import '../../widgets/sprite_sheet_animation.dart';

// ─── Pokédex LCD & panel colors ──────────────────────────────────────────────
const _kLcdGreen       = Color(0xFF98CB98);
const _kLcdDarkGreen   = Color(0xFF78A878);
const _kLcdInnerBg     = Color(0xFF88B888);
const _kPanelBorder    = Color(0xFF5A6E5A);
const _kPokedexBrown   = Color(0xFF8B7355);
const _kPokedexRed     = Color(0xFFDC0A2D);
const _kLcdTextDark    = Color(0xFF2A3A2A);
const _kLcdTextLight   = Color(0xFF4A5A4A);
const _kScanlineColor  = Color(0x1A000000);

// ─── Pixel-style text style helper ───────────────────────────────────────────
TextStyle _pixelText({
  required double fontSize,
  Color? color,
  FontWeight? fontWeight,
}) => TextStyle(
  fontSize: fontSize,
  color: color ?? _kLcdTextDark,
  fontWeight: fontWeight ?? FontWeight.normal,
  height: 1.2,
  letterSpacing: 0.5,
);

class PokedexScreen extends StatefulWidget {
  final Creature? creature;
  final bool isGenerating;
  final int creatureIndex;
  final int creatureCount;
  final VoidCallback? onReleasePressed;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;

  const PokedexScreen({
    super.key,
    required this.creature,
    required this.isGenerating,
    required this.creatureIndex,
    this.creatureCount = 0,
    this.onReleasePressed,
    this.onSwipeLeft,
    this.onSwipeRight,
  });

  @override
  State<PokedexScreen> createState() => PokedexScreenState();
}

class PokedexScreenState extends State<PokedexScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Scroll the LCD content up by one section.
  void scrollUp() {
    if (!mounted || !_scrollController.hasClients) return;
    final current = _scrollController.offset;
    final target = (current - 120).clamp(0.0, _scrollController.position.maxScrollExtent);
    if (target == current) return;
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  /// Scroll the LCD content down by one section.
  void scrollDown() {
    if (!mounted || !_scrollController.hasClients) return;
    final current = _scrollController.offset;
    final target = (current + 120).clamp(0.0, _scrollController.position.maxScrollExtent);
    if (target == current) return;
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  // ─── Original Photo Dialog (Pokédex-themed) ──────────────────────────────
  void _showOriginalPhoto(BuildContext context, String photoPath) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: _kPokedexBrown,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: _kPokedexRed, width: 3),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title bar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: const BoxDecoration(
                  color: _kPokedexRed,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(2),
                    topRight: Radius.circular(2),
                  ),
                ),
                child: Text(
                  'ORIGINAL PHOTO',
                  style: _pixelText(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              // Image with LCD frame
              Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _kLcdDarkGreen,
                  border: Border.all(color: _kPanelBorder, width: 2),
                ),
                child: ClipRect(
                  child: Image.file(
                    File(photoPath),
                    fit: BoxFit.contain,
                    width: 280,
                    height: 280,
                  ),
                ),
              ),
              // Close button
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                    backgroundColor: _kLcdDarkGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2),
                      side: const BorderSide(color: _kPanelBorder),
                    ),
                  ),
                  child: Text(
                    'CLOSE',
                    style: _pixelText(fontSize: 18, color: _kLcdTextDark),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Main Build ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Species counter bar (integrated above the LCD) ──
        _buildSpeciesBar(),
        const SizedBox(height: 6),
        // ── Main LCD Panel ──
        Expanded(
          child: GestureDetector(
            onHorizontalDragEnd: (details) {
              if (widget.isGenerating) return;
              final velocity = details.primaryVelocity ?? 0;
              if (velocity < -200) {
                widget.onSwipeRight?.call();
              } else if (velocity > 200) {
                widget.onSwipeLeft?.call();
              }
            },
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              decoration: BoxDecoration(
                color: _kLcdGreen,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(width: 6, color: _kPokedexBrown),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                  // Inner highlight
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.1),
                    blurRadius: 2,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: Stack(
                  children: [
                    // Scanline overlay
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _ScanlinePainter(),
                      ),
                    ),
                    // Subtle vignette
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _VignettePainter(),
                      ),
                    ),
                    if (widget.creature != null)
                      _buildCreatureDisplay(context, widget.creature!)
                    else
                      _buildEmptyState(context),
                    if (widget.isGenerating)
                      Container(
                        color: Colors.black.withValues(alpha: 0.5),
                        child: const Center(child: CaptureAnimation(playing: true)),
                      ),
                    // Navigation dots overlay
                    if (widget.creatureCount > 1 && !widget.isGenerating)
                      Positioned(
                        bottom: 8,
                        left: 0,
                        right: 0,
                        child: _buildNavDots(),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Species Counter Bar (above LCD) ─────────────────────────────────────
  Widget _buildSpeciesBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB80828), Color(0xFF9E0620)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF8B001A), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pokéball icon
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: const Color(0xFF5A6E5A), width: 1.5),
            ),
            child: ClipOval(
              child: Column(
                children: [
                  Expanded(
                    child: Container(color: const Color(0xFFDC0A2D)),
                  ),
                  Container(height: 2, color: const Color(0xFF5A6E5A)),
                  Expanded(
                    child: Container(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'SPECIES REGISTERED',
            style: _pixelText(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          // Counter with metallic hardware styling
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A1A1A), Color(0xFF2A2A2A)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF444444), width: 1.5),
            ),
            child: Row(
              children: [
                _buildDigit(widget.creatureCount.toString().padLeft(3, '0')[0]),
                const SizedBox(width: 4),
                _buildDigit(widget.creatureCount.toString().padLeft(3, '0')[1]),
                const SizedBox(width: 4),
                _buildDigit(widget.creatureCount.toString().padLeft(3, '0')[2]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDigit(String digit) {
    return Container(
      width: 18,
      alignment: Alignment.center,
      child: Text(
        digit,
        style: const TextStyle(
          fontFamily: 'VT323',
          fontSize: 20,
          color: Color(0xFFFFD700),
          letterSpacing: 0,
          height: 1.0,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Color(0x66FFD700),
              blurRadius: 4,
              offset: Offset(0, 0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        widget.creatureCount,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: index == widget.creatureIndex ? 14 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: index == widget.creatureIndex
                ? _kPokedexRed
                : _kLcdTextLight.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(3),
            boxShadow: index == widget.creatureIndex
                ? [
                    BoxShadow(
                      color: _kPokedexRed.withValues(alpha: 0.4),
                      blurRadius: 4,
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }

  // ─── Creature Display ────────────────────────────────────────────────────
  Widget _buildCreatureDisplay(BuildContext context, Creature creature) {
    return FutureBuilder<Uint8List>(
      future: File(creature.imagePath).readAsBytes(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation(_kPokedexRed),
                  ),
                ),
                const SizedBox(height: 12),
                Text('LOADING...', style: _pixelText(fontSize: 18, color: _kLcdTextDark)),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          controller: _scrollController,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Top Bar: Number + Name ────────────────────────────────
                _buildTopBar(creature),
                const SizedBox(height: 10),

                // ── Sprite Panel ──────────────────────────────────────────
                _buildSpritePanel(snapshot.data!),
                const SizedBox(height: 10),

                // ── Type Badges ───────────────────────────────────────────
                _buildTypeBadges(creature),
                const SizedBox(height: 10),

                // ── Stats Panel ───────────────────────────────────────────
                _buildStatsPanel(creature.stats),
                const SizedBox(height: 10),

                // ── Flavor Text Panel ─────────────────────────────────────
                if (creature.flavorText.isNotEmpty) ...[
                  _buildFlavorTextPanel(creature.flavorText),
                  const SizedBox(height: 10),
                ],

                // ── Moves Panel ───────────────────────────────────────────
                if (creature.moves.isNotEmpty)
                  _buildMovesPanel(creature.moves),

                // ── Action Buttons: Photo + Release ───────────────────────
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (creature.originalPhotoPaths.isNotEmpty) ...[
                        Text(
                          'PHOTO',
                          style: _pixelText(fontSize: 14, color: _kLcdTextLight),
                        ),
                        const SizedBox(width: 6),
                        _buildPhotoIconButton(creature.originalPhotoPaths.first),
                        const SizedBox(width: 16),
                      ],
                      Text(
                        'RELEASE',
                        style: _pixelText(fontSize: 14, color: _kLcdTextLight),
                      ),
                      const SizedBox(width: 6),
                      _buildReleaseIconButton(),
                    ],
                  ),
                ),

              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Top Bar ─────────────────────────────────────────────────────────────
  Widget _buildTopBar(Creature creature) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_kLcdDarkGreen, _kLcdInnerBg],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: _kPanelBorder, width: 2),
        borderRadius: BorderRadius.circular(3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          creature.name.toUpperCase(),
          style: _pixelText(fontSize: 24, color: _kLcdTextDark, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  // ─── Sprite Panel ────────────────────────────────────────────────────────
  Widget _buildSpritePanel(Uint8List imageBytes) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _kLcdInnerBg,
        border: Border.all(color: _kPanelBorder, width: 3),
        borderRadius: BorderRadius.circular(3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),

        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // LCD grid background
          Positioned.fill(
            child: CustomPaint(
              painter: _LcdGridPainter(),
            ),
          ),
          // Sprite
          SpriteSheetAnimation(
            imageBytes: imageBytes,
            size: 200,
          ),
        ],
      ),
    );
  }

  // ─── Type Badges ─────────────────────────────────────────────────────────
  Widget _buildTypeBadges(Creature creature) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildPixelTypeChip(creature.primaryType.name),
        if (creature.secondaryType != null) ...[
          const SizedBox(width: 10),
          _buildPixelTypeChip(creature.secondaryType!.name),
        ],
      ],
    );
  }

  Widget _buildPixelTypeChip(String type) {
    final color = _getTypeColor(type);
    final textColor = _isLightColor(color) ? _kLcdTextDark : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: _kPanelBorder, width: 2),
        borderRadius: BorderRadius.circular(3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Small type icon dot
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: textColor.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            type[0].toUpperCase() + type.substring(1),
            style: _pixelText(fontSize: 17, color: textColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // ─── Stats Panel ─────────────────────────────────────────────────────────
  Widget _buildStatsPanel(CreatureStats stats) {
    // Calculate total stats
    final totalStats = stats.hp + stats.attack + stats.defense + stats.speed;
    final avgStat = totalStats / 4;
    final rating = _getStatRating(avgStat);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_kLcdDarkGreen, _kLcdInnerBg],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border.all(color: _kPanelBorder, width: 2),
        borderRadius: BorderRadius.circular(3),
        boxShadow: [
          const BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'STATUS',
                style: _pixelText(fontSize: 18, color: _kLcdTextLight, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              // Total rating badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getRatingColor(rating).withValues(alpha: 0.2),
                  border: Border.all(color: _getRatingColor(rating), width: 1.5),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  'TOTAL: $totalStats - $rating',
                  style: _pixelText(
                    fontSize: 14,
                    color: _getRatingColor(rating),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildStatRow('HP', stats.hp, 100),
          const SizedBox(height: 5),
          _buildStatRow('ATK', stats.attack, 80),
          const SizedBox(height: 5),
          _buildStatRow('DEF', stats.defense, 80),
          const SizedBox(height: 5),
          _buildStatRow('SPD', stats.speed, 80),
        ],
      ),
    );
  }

  String _getStatRating(double avgStat) {
    if (avgStat >= 75) return 'LEGENDARY';
    if (avgStat >= 60) return 'EPIC';
    if (avgStat >= 48) return 'STRONG';
    if (avgStat >= 38) return 'AVERAGE';
    return 'WEAK';
  }

  Color _getRatingColor(String rating) {
    switch (rating) {
      case 'LEGENDARY':
        return const Color(0xFF8B6914);
      case 'EPIC':
        return const Color(0xFF6A1B7A);
      case 'STRONG':
        return const Color(0xFF2E6B2E);
      case 'AVERAGE':
        return const Color(0xFF1A3A6B);
      default:
        return const Color(0xFF5A5A5A);
    }
  }

  Widget _buildStatRow(String label, int value, int maxValue) {
    final ratio = value.clamp(0, maxValue) / maxValue;
    return Row(
      children: [
        SizedBox(
          width: 32,
          child: Text(label, style: _pixelText(fontSize: 17, color: _kLcdTextDark)),
        ),
        const SizedBox(width: 8),
        // Stat bar background
        Expanded(
          child: Container(
            height: 12,
            decoration: BoxDecoration(
              color: _kLcdInnerBg,
              border: Border.all(color: _kPanelBorder, width: 1.5),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: ratio,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getStatBarColor(ratio),
                            _getStatBarColor(ratio).withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                // Subtle shine
                if (ratio > 0.2)
                  Positioned(
                    top: 1,
                    left: 2,
                    right: 2,
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 34,
          child: Text(
            value.toString().padLeft(3, '0'),
            textAlign: TextAlign.right,
            style: _pixelText(fontSize: 17, color: _kLcdTextDark, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Color _getStatBarColor(double ratio) {
    if (ratio > 0.6) return const Color(0xFF4CAF50);
    if (ratio > 0.35) return const Color(0xFFFFB300);
    return const Color(0xFFE53935);
  }

  // ─── Flavor Text Panel ───────────────────────────────────────────────────
  Widget _buildFlavorTextPanel(String flavorText) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _kLcdInnerBg,
        border: Border.all(color: _kPanelBorder, width: 2),
        borderRadius: BorderRadius.circular(3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Small Pokéball icon
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _kPokedexRed,
                  shape: BoxShape.circle,
                  border: Border.all(color: _kPanelBorder, width: 1),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'DESCRIPTION',
                style: _pixelText(fontSize: 18, color: _kLcdTextLight, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Divider line
          Container(
            height: 1,
            color: _kPanelBorder,
          ),
          const SizedBox(height: 6),
          Text(
            flavorText,
            style: _pixelText(fontSize: 18, color: _kLcdTextDark),
          ),
        ],
      ),
    );
  }

  // ─── Moves Panel ─────────────────────────────────────────────────────────
  Widget _buildMovesPanel(List<Move> moves) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _kLcdDarkGreen,
        border: Border.all(color: _kPanelBorder, width: 2),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MOVES',
            style: _pixelText(fontSize: 18, color: _kLcdTextLight, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          // Column headers
          Container(
            padding: const EdgeInsets.symmetric(vertical: 3),
            decoration: BoxDecoration(
              color: _kLcdInnerBg,
              border: Border.all(color: _kPanelBorder, width: 1),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Text('MOVE', style: _pixelText(fontSize: 15, color: _kLcdTextLight)),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Text('TYPE', style: _pixelText(fontSize: 15, color: _kLcdTextLight)),
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Text('PWR', textAlign: TextAlign.center, style: _pixelText(fontSize: 15, color: _kLcdTextLight)),
                ),
                SizedBox(
                  width: 40,
                  child: Text('ACC', textAlign: TextAlign.center, style: _pixelText(fontSize: 15, color: _kLcdTextLight)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Move rows
          ...moves.map((move) => _buildMoveRow(move)),
        ],
      ),
    );
  }

  Widget _buildMoveRow(Move move) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Text(
                move.name,
                style: _pixelText(fontSize: 16, color: _kLcdTextDark),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: _getMoveTypeColor(move.type),
                  border: Border.all(color: _kPanelBorder, width: 1),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  move.type.substring(0, math.min(3, move.type.length)).toUpperCase(),
                  style: _pixelText(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              move.power != null ? '${move.power}' : '---',
              textAlign: TextAlign.center,
              style: _pixelText(fontSize: 15, color: _kLcdTextDark),
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              move.accuracy != null ? '${move.accuracy}' : '---',
              textAlign: TextAlign.center,
              style: _pixelText(fontSize: 15, color: _kLcdTextDark),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Photo Icon Button ───────────────────────────────────────────────────
  Widget _buildPhotoIconButton(String photoPath) {
    return GestureDetector(
      onTap: () => _showOriginalPhoto(context, photoPath),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: _kLcdDarkGreen,
          border: Border.all(color: _kPanelBorder, width: 2),
          borderRadius: BorderRadius.circular(3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: const Icon(
          Icons.camera_alt,
          size: 16,
          color: _kLcdTextDark,
        ),
      ),
    );
  }

  // ─── Release Icon Button ─────────────────────────────────────────────────
  Widget _buildReleaseIconButton() {
    return GestureDetector(
      onTap: () => _showReleaseConfirmation(context),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: _kPokedexRed.withValues(alpha: 0.8),
          border: Border.all(color: _kPanelBorder, width: 2),
          borderRadius: BorderRadius.circular(3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: const Icon(
          Icons.delete_outline,
          size: 16,
          color: Colors.white,
        ),
      ),
    );
  }

  // ─── Release Confirmation Dialog ─────────────────────────────────────────
  void _showReleaseConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: _kPokedexBrown,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: _kPokedexRed, width: 3),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title bar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: const BoxDecoration(
                  color: _kPokedexRed,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(2),
                    topRight: Radius.circular(2),
                  ),
                ),
                child: Text(
                  'RELEASE POKEMON',
                  style: _pixelText(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              // Message
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Text(
                  'Are you sure you want to release ${widget.creature?.name.toUpperCase()}?\nThis cannot be undone.',
                  textAlign: TextAlign.center,
                  style: _pixelText(fontSize: 18, color: _kLcdTextDark),
                ),
              ),
              // Buttons
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Cancel button
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        backgroundColor: _kLcdDarkGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2),
                          side: const BorderSide(color: _kPanelBorder),
                        ),
                      ),
                      child: Text(
                        'CANCEL',
                        style: _pixelText(fontSize: 18, color: _kLcdTextDark),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Release button
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onReleasePressed?.call();
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        backgroundColor: _kPokedexRed,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2),
                          side: const BorderSide(color: _kPanelBorder),
                        ),
                      ),
                      child: Text(
                        'RELEASE',
                        style: _pixelText(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Empty State ─────────────────────────────────────────────────────────
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Pokéball icon
            _AnimatedPokeball(size: 72),
            const SizedBox(height: 24),
            Text(
              'NO DATA REGISTERED',
              style: _pixelText(fontSize: 26, color: _kLcdTextDark, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _kLcdInnerBg,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: _kPanelBorder, width: 1),
              ),
              child: Text(
                'Press the red button\nto catch your first creature!',
                textAlign: TextAlign.center,
                style: _pixelText(fontSize: 18, color: _kLcdTextLight),
              ),
            ),
            const SizedBox(height: 16),
            // Subtle arrow hint
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.arrow_downward,
                  size: 16,
                  color: _kLcdTextLight.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 4),
                Text(
                  'TAP BELOW',
                  style: _pixelText(
                    fontSize: 12,
                    color: _kLcdTextLight.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────
  bool _isLightColor(Color color) {
    return color.computeLuminance() > 0.5;
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'fire':
        return const Color(0xFFF08030);
      case 'water':
        return const Color(0xFF6890F0);
      case 'nature':
      case 'grass':
        return const Color(0xFF78C850);
      case 'earth':
      case 'ground':
        return const Color(0xFFE0C068);
      case 'air':
      case 'flying':
        return const Color(0xFFA890F0);
      case 'light':
        return const Color(0xFFF8D030);
      case 'shadow':
      case 'ghost':
        return const Color(0xFF705898);
      case 'metal':
      case 'rock':
        return const Color(0xFFB8A038);
      case 'arcane':
      case 'psychic':
        return const Color(0xFFF85888);
      case 'beast':
      case 'normal':
        return const Color(0xFFA8A878);
      default:
        return Colors.grey;
    }
  }

  Color _getMoveTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'normal':
        return const Color(0xFFA8A878);
      case 'fire':
        return const Color(0xFFF08030);
      case 'water':
        return const Color(0xFF6890F0);
      case 'electric':
        return const Color(0xFFF8D030);
      case 'grass':
      case 'nature':
        return const Color(0xFF78C850);
      case 'ice':
        return const Color(0xFF98D8D8);
      case 'fighting':
        return const Color(0xFFC03028);
      case 'poison':
        return const Color(0xFFA040A0);
      case 'ground':
      case 'earth':
        return const Color(0xFFE0C068);
      case 'flying':
      case 'air':
        return const Color(0xFFA890F0);
      case 'psychic':
      case 'arcane':
        return const Color(0xFFF85888);
      case 'bug':
        return const Color(0xFFA8B820);
      case 'rock':
      case 'metal':
        return const Color(0xFFB8A038);
      case 'ghost':
      case 'shadow':
        return const Color(0xFF705898);
      case 'dragon':
        return const Color(0xFF7038F8);
      default:
        return Colors.grey;
    }
  }
}

// ─── Scanline Painter (LCD effect) ───────────────────────────────────────────
class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = _kScanlineColor;
    const lineHeight = 3.0;
    for (double y = 0; y < size.height; y += lineHeight * 2) {
      canvas.drawRect(
        Rect.fromLTWH(0, y, size.width, lineHeight),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── LCD Grid Painter (subtle dot matrix behind sprite) ──────────────────────
class _LcdGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x1A000000)
      ..strokeWidth = 0.5;
    const spacing = 8.0;
    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Animated Pokéball Widget (empty state) ────────────────────────────────
class _AnimatedPokeball extends StatefulWidget {
  final double size;

  const _AnimatedPokeball({required this.size});

  @override
  State<_AnimatedPokeball> createState() => _AnimatedPokeballState();
}

class _AnimatedPokeballState extends State<_AnimatedPokeball>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _bounce;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _bounce = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: -8)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -8, end: 0)
            .chain(CurveTween(curve: Curves.bounceOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 0)
            .chain(CurveTween(curve: Curves.linear)),
        weight: 50,
      ),
    ]).animate(_controller);

    _glow = Tween<double>(begin: 0.2, end: 0.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.repeat();
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
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _bounce.value),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Glow effect
            AnimatedBuilder(
              animation: _glow,
              builder: (context, child) => Container(
                width: widget.size + 16,
                height: widget.size + 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kPokedexRed.withValues(alpha: _glow.value),
                ),
              ),
            ),
            // Pokeball
            CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _PokeballPainter(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Pokéball Painter (empty state icon) ─────────────────────────────────────
class _PokeballPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset(center.dx + 2, center.dy + 2), radius, shadowPaint);

    // Outer border
    final borderPaint = Paint()
      ..color = _kPanelBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius, borderPaint);

    // Top half (red)
    final topPaint = Paint()..color = _kPokedexRed;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 2),
      -math.pi,
      math.pi,
      true,
      topPaint,
    );

    // Bottom half (white)
    final bottomPaint = Paint()..color = Colors.white;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 2),
      0,
      math.pi,
      true,
      bottomPaint,
    );

    // Center line
    final linePaint = Paint()
      ..color = _kPanelBorder
      ..strokeWidth = 3;
    canvas.drawLine(
      Offset(center.dx - radius + 2, center.dy),
      Offset(center.dx + radius - 2, center.dy),
      linePaint,
    );

    // Center button
    final buttonPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, 10, buttonPaint);
    final buttonBorder = Paint()
      ..color = _kPanelBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, 10, buttonBorder);
    final buttonInner = Paint()..color = _kPokedexRed;
    canvas.drawCircle(center, 5, buttonInner);

    // Button highlight
    final buttonHighlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(center.dx - 2, center.dy - 2), 3, buttonHighlight);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Blinking Dot Widget ──────────────────────────────────────────────────
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

// ─── Vignette Painter (subtle LCD edge darkening) ─────────────────────────
class _VignettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.08),
        ],
        radius: 0.75,
      ).createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
