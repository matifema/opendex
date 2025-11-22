import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/pokemon_models.dart';
import '../services/battle/battle_engine.dart';
import '../widgets/sprite_sheet_animation.dart';

class BattlePage extends StatefulWidget {
  final Creature player;
  final Creature opponent;

  const BattlePage({
    super.key,
    required this.player,
    required this.opponent,
  });

  @override
  State<BattlePage> createState() => _BattlePageState();
}

class _BattlePageState extends State<BattlePage> {
  late BattleEngine _engine;
  late BattleState _state;

  @override
  void initState() {
    super.initState();
    _engine = BattleEngine();
    _state = _engine.initBattle(widget.player, widget.opponent);
  }

  void _handleMove(String moveName) {
    setState(() {
      _state = _engine.nextTurn(_state, playerMove: moveName);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Battle Arena'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // Opponent (Top Right)
                Positioned(
                  top: 20,
                  right: 20,
                  child: _buildCreatureView(_state.opponent, _state.opponentHp, false),
                ),
                // Player (Bottom Left)
                Positioned(
                  bottom: 20,
                  left: 20,
                  child: _buildCreatureView(_state.player, _state.playerHp, true),
                ),
              ],
            ),
          ),
          const Divider(),
          SizedBox(
            height: 150,
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(8),
              itemCount: _state.logs.length,
              itemBuilder: (context, index) {
                final log = _state.logs[_state.logs.length - 1 - index];
                return Text(
                  log.message,
                  style: TextStyle(
                    color: log.isPlayerMove ? Colors.blue : Colors.red,
                  ),
                );
              },
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _state.isGameOver
                ? ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Back to Lab'),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: _state.isPlayerTurn ? () => _handleMove('Attack') : null,
                        child: const Text('Attack'),
                      ),
                      // Add more moves here if we had them
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreatureView(Creature c, int currentHp, bool isPlayer) {
    final maxHp = c.stats.hp;
    final hpPercent = currentHp / maxHp;

    return Column(
      crossAxisAlignment: isPlayer ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text('Lv. 50'), // Placeholder level
        const SizedBox(height: 4),
        SizedBox(
          width: 150,
          child: LinearProgressIndicator(
            value: hpPercent,
            backgroundColor: Colors.grey[300],
            color: hpPercent > 0.5 ? Colors.green : (hpPercent > 0.2 ? Colors.orange : Colors.red),
            minHeight: 8,
          ),
        ),
        Text('$currentHp / $maxHp HP'),
        const SizedBox(height: 8),
        FutureBuilder<Uint8List>(
          future: File(c.imagePath).readAsBytes(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return SpriteSheetAnimation(imageBytes: snapshot.data!, size: 150);
            }
            return const SizedBox(width: 150, height: 150, child: Center(child: CircularProgressIndicator()));
          },
        ),
      ],
    );
  }
}
