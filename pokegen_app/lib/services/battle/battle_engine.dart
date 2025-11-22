import 'dart:math';

import '../../models/pokemon_models.dart';

class BattleLog {
  final String message;
  final bool isPlayerMove;

  BattleLog(this.message, {this.isPlayerMove = true});
}

class BattleState {
  final Creature player;
  final Creature opponent;
  int playerHp;
  int opponentHp;
  final List<BattleLog> logs;
  bool isPlayerTurn;
  bool isGameOver;
  String? winnerId;

  BattleState({
    required this.player,
    required this.opponent,
  })  : playerHp = player.stats.hp,
        opponentHp = opponent.stats.hp,
        logs = [],
        isPlayerTurn = player.stats.speed >= opponent.stats.speed,
        isGameOver = false;
}

class BattleEngine {
  final Random _rng = Random();

  BattleState initBattle(Creature player, Creature opponent) {
    return BattleState(player: player, opponent: opponent);
  }

  BattleState nextTurn(BattleState state, {String? playerMove}) {
    if (state.isGameOver) return state;

    if (state.isPlayerTurn) {
      if (playerMove == null) return state; // Waiting for player input
      _executeMove(state, state.player, state.opponent, playerMove, true);
      if (!_checkGameOver(state)) {
        state.isPlayerTurn = false;
        // AI turn happens immediately or handled by UI delay?
        // For simplicity, let's make AI move immediately if we want,
        // but usually UI wants to show animation.
        // Let's keep it turn-by-turn.
      }
    } else {
      // AI Turn
      final aiMove = _chooseAiMove(state.opponent);
      _executeMove(state, state.opponent, state.player, aiMove, false);
      if (!_checkGameOver(state)) {
        state.isPlayerTurn = true;
      }
    }
    return state;
  }

  void _executeMove(
      BattleState state, Creature attacker, Creature defender, String moveName, bool isPlayer) {
    // Simple damage formula
    // Damage = (Attack * Power / Defense) * TypeEffectiveness * Random
    // We don't have move power, so assume standard attack is power 50.
    const movePower = 50;
    
    // Type effectiveness
    final effectiveness = _getEffectiveness(attacker.primaryType, defender.primaryType);
    
    // Random factor 0.85 to 1.0
    final random = 0.85 + _rng.nextDouble() * 0.15;

    final damage = ((attacker.stats.attack * movePower / defender.stats.defense) * effectiveness * random).ceil();
    
    // Apply damage
    if (isPlayer) {
      state.opponentHp = max(0, state.opponentHp - damage);
    } else {
      state.playerHp = max(0, state.playerHp - damage);
    }

    // Log
    String effectText = '';
    if (effectiveness > 1.0) effectText = ' It\'s super effective!';
    if (effectiveness < 1.0) effectText = ' It\'s not very effective...';
    
    state.logs.add(BattleLog(
      '${attacker.name} used $moveName! Dealt $damage damage.$effectText',
      isPlayerMove: isPlayer,
    ));
  }

  bool _checkGameOver(BattleState state) {
    if (state.playerHp <= 0) {
      state.isGameOver = true;
      state.winnerId = state.opponent.id;
      state.logs.add(BattleLog('${state.player.name} fainted! You lost!', isPlayerMove: false));
      return true;
    }
    if (state.opponentHp <= 0) {
      state.isGameOver = true;
      state.winnerId = state.player.id;
      state.logs.add(BattleLog('${state.opponent.name} fainted! You won!', isPlayerMove: true));
      return true;
    }
    return false;
  }

  String _chooseAiMove(Creature aiCreature) {
    return 'Attack'; // Placeholder for more complex AI
  }

  double _getEffectiveness(CreatureType attackType, CreatureType defenseType) {
    // Simple Rock-Paper-Scissors logic for demo
    // Fire > Nature > Water > Fire
    // Light > Shadow > Light
    // Earth > Air > Earth
    
    if (attackType == CreatureType.fire && defenseType == CreatureType.nature) return 2.0;
    if (attackType == CreatureType.nature && defenseType == CreatureType.water) return 2.0;
    if (attackType == CreatureType.water && defenseType == CreatureType.fire) return 2.0;
    
    if (attackType == CreatureType.nature && defenseType == CreatureType.fire) return 0.5;
    if (attackType == CreatureType.water && defenseType == CreatureType.nature) return 0.5;
    if (attackType == CreatureType.fire && defenseType == CreatureType.water) return 0.5;

    if (attackType == CreatureType.light && defenseType == CreatureType.shadow) return 2.0;
    if (attackType == CreatureType.shadow && defenseType == CreatureType.light) return 2.0;

    return 1.0;
  }
}
