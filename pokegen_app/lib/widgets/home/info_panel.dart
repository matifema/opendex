import 'package:flutter/material.dart';

class InfoPanel extends StatelessWidget {
  final int creatureCount;
  final int gymBadges;
  final int battlesWon;
  final int battlesLost;

  const InfoPanel({
    super.key,
    required this.creatureCount,
    required this.gymBadges,
    required this.battlesWon,
    required this.battlesLost,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF8B7355), width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem('POKÉMON', '$creatureCount'),
          _buildInfoItem('BADGES', '$gymBadges/8'),
          _buildInfoItem('BATTLES', '$battlesWon W / $battlesLost L'),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF88FF88),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF88FF88),
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}
