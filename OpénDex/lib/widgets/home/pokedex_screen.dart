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

  const PokedexScreen({
    super.key,
    required this.creature,
    required this.isGenerating,
    required this.creatureIndex,
    this.creatureCount = 0,
    this.onReleasePressed,
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
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      decoration: BoxDecoration(
        color: _kLcdGreen,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(width: 6, color: _kPokedexBrown),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 5),
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
            if (widget.creature != null)
              _buildCreatureDisplay(context, widget.creature!)
            else
              _buildEmptyState(context),
            if (widget.isGenerating)
              Container(
                color: Colors.black.withValues(alpha: 0.4),
                child: const Center(child: CaptureAnimation(playing: true)),
              ),
          ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _kLcdDarkGreen,
        border: Border.all(color: _kPanelBorder, width: 2),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        children: [
          // Creature number
          Text(
            'No.${_formatNumber(widget.creatureIndex + 1)}',
            style: _pixelText(fontSize: 22, color: _kPokedexRed, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          // Separator dot
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: _kPokedexRed,
              shape: BoxShape.circle,
            ),
          ),
          const Spacer(),
          // Creature name
          Text(
            creature.name.toUpperCase(),
            style: _pixelText(fontSize: 22, color: _kLcdTextDark, fontWeight: FontWeight.bold),
          ),
        ],
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
          const SizedBox(width: 8),
          _buildPixelTypeChip(creature.secondaryType!.name),
        ],
      ],
    );
  }

  Widget _buildPixelTypeChip(String type) {
    final color = _getTypeColor(type);
    final textColor = _isLightColor(color) ? _kLcdTextDark : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: _kPanelBorder, width: 2),
        borderRadius: BorderRadius.circular(2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        type[0].toUpperCase() + type.substring(1),
        style: _pixelText(fontSize: 16, color: textColor, fontWeight: FontWeight.bold),
      ),
    );
  }

  // ─── Stats Panel ─────────────────────────────────────────────────────────
  Widget _buildStatsPanel(CreatureStats stats) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _kLcdDarkGreen,
        border: Border.all(color: _kPanelBorder, width: 2),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STATUS',
            style: _pixelText(fontSize: 16, color: _kLcdTextLight, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          _buildStatRow('HP', stats.hp, 255),
          const SizedBox(height: 4),
          _buildStatRow('ATK', stats.attack, 255),
          const SizedBox(height: 4),
          _buildStatRow('DEF', stats.defense, 255),
          const SizedBox(height: 4),
          _buildStatRow('SPD', stats.speed, 255),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, int value, int maxValue) {
    final ratio = value.clamp(0, maxValue) / maxValue;
    return Row(
      children: [
        SizedBox(
          width: 32,
          child: Text(label, style: _pixelText(fontSize: 15, color: _kLcdTextDark)),
        ),
        const SizedBox(width: 6),
        // Stat bar background
        Expanded(
          child: Container(
            height: 10,
            decoration: BoxDecoration(
              color: _kLcdInnerBg,
              border: Border.all(color: _kPanelBorder, width: 1),
              borderRadius: BorderRadius.circular(1),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: ratio,
                child: Container(
                  decoration: BoxDecoration(
                    color: _getStatBarColor(ratio),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 30,
          child: Text(
            '$value',
            textAlign: TextAlign.right,
            style: _pixelText(fontSize: 15, color: _kLcdTextDark),
          ),
        ),
      ],
    );
  }

  Color _getStatBarColor(double ratio) {
    if (ratio > 0.6) return const Color(0xFF4CAF50); // green
    if (ratio > 0.3) return const Color(0xFFFFC107); // yellow
    return const Color(0xFFF44336); // red
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
                style: _pixelText(fontSize: 16, color: _kLcdTextLight, fontWeight: FontWeight.bold),
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
            style: _pixelText(fontSize: 16, color: _kLcdTextDark),
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
            style: _pixelText(fontSize: 16, color: _kLcdTextLight, fontWeight: FontWeight.bold),
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
                    child: Text('MOVE', style: _pixelText(fontSize: 13, color: _kLcdTextLight)),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Text('TYPE', style: _pixelText(fontSize: 13, color: _kLcdTextLight)),
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Text('PWR', textAlign: TextAlign.center, style: _pixelText(fontSize: 13, color: _kLcdTextLight)),
                ),
                SizedBox(
                  width: 40,
                  child: Text('ACC', textAlign: TextAlign.center, style: _pixelText(fontSize: 13, color: _kLcdTextLight)),
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
                style: _pixelText(fontSize: 14, color: _kLcdTextDark),
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
                  style: _pixelText(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
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
              style: _pixelText(fontSize: 14, color: _kLcdTextDark),
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              move.accuracy != null ? '${move.accuracy}' : '---',
              textAlign: TextAlign.center,
              style: _pixelText(fontSize: 14, color: _kLcdTextDark),
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
            // Pokéball icon
            CustomPaint(
              size: const Size(64, 64),
              painter: _PokeballPainter(),
            ),
            const SizedBox(height: 20),
            Text(
              'NO DATA REGISTERED',
              style: _pixelText(fontSize: 24, color: _kLcdTextDark, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Press the red button to catch\nyour first creature!',
              textAlign: TextAlign.center,
              style: _pixelText(fontSize: 18, color: _kLcdTextLight),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────
  String _formatNumber(int n) => n.toString().padLeft(3, '0');

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

// ─── Pokéball Painter (empty state icon) ─────────────────────────────────────
class _PokeballPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

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
    canvas.drawCircle(center, 8, buttonPaint);
    final buttonBorder = Paint()
      ..color = _kPanelBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, 8, buttonBorder);
    final buttonInner = Paint()..color = _kPokedexRed;
    canvas.drawCircle(center, 4, buttonInner);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
