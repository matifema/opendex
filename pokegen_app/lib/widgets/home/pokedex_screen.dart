import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../models/pokemon_models.dart';
import '../../widgets/capture_animation.dart';
import '../../widgets/sprite_sheet_animation.dart';

class PokedexScreen extends StatelessWidget {
  final Creature? creature;
  final bool isGenerating;
  final bool showStats;
  final int creatureIndex;

  const PokedexScreen({
    super.key,
    required this.creature,
    required this.isGenerating,
    required this.showStats,
    required this.creatureIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF98CB98),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(width: 6, color: const Color(0xFF8B7355)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          children: [
            if (creature != null)
              _buildCreatureDisplay(context, creature!)
            else
              _buildEmptyState(context),
            if (isGenerating)
              Container(
                color: Colors.black.withOpacity(0.4),
                child: const Center(child: CaptureAnimation(playing: true)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreatureDisplay(BuildContext context, Creature creature) {
    return FutureBuilder<Uint8List>(
      future: File(creature.imagePath).readAsBytes(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Creature sprite - size changes based on stats view
                Center(
                  child: SpriteSheetAnimation(
                    imageBytes: snapshot.data!,
                    size: showStats ? 150 : 220,
                  ),
                ),
                const SizedBox(height: 16),

                // Always visible: Name, number, types, and flavor text
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.black26),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name and number
                      Text(
                        '#${creatureIndex + 1} ${creature.name}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Types
                      Row(
                        children: [
                          _buildTypeChip(context, creature.primaryType.name),
                          if (creature.secondaryType != null) ...[
                            const SizedBox(width: 8),
                            _buildTypeChip(context, creature.secondaryType!.name),
                          ],
                        ],
                      ),
                      // Flavor text (always visible)
                      if (creature.flavorText.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          creature.flavorText,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.black87,
                          ),
                        ),
                      ],
                      // Detailed stats (toggled by A button)
                      if (showStats) ...[
                        const Divider(height: 24),
                        Text(
                          'Stats',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildStatsGrid(creature.stats),
                      ],
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

  Widget _buildStatsGrid(CreatureStats s) {
    return Column(
      children: [
        _buildStatRow('HP', s.hp),
        _buildStatRow('Attack', s.attack),
        _buildStatRow('Defense', s.defense),
        _buildStatRow('Speed', s.speed),
      ],
    );
  }

  Widget _buildStatRow(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Row(
            children: [
              Text(
                value.toString(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              // Stat bar
              Container(
                width: 100,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (value / 100).clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _getStatColor(value),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatColor(int value) {
    if (value >= 75) return Colors.green;
    if (value >= 50) return Colors.orange;
    return Colors.red;
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.catching_pokemon,
              size: 80,
              color: Colors.black26,
            ),
            const SizedBox(height: 24),
            Text(
              'PokéDex Empty',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.black54,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Press the red button to catch your first creature!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(BuildContext context, String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        type[0].toUpperCase() + type.substring(1),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
