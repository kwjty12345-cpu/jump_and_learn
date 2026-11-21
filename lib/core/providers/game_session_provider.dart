import 'package:flutter_riverpod/flutter_riverpod.dart';

class GameSession {
  final String discipline;
  final String topicId;
  final String difficulty;
  final bool isMultiplayer;
  final String? roomCode;
  final int warmupTimeMs;
  final int gameplayTimeMs;

  const GameSession({
    this.discipline = 'Computer Science',
    this.topicId = 'cs_01',
    this.difficulty = 'medium',
    this.isMultiplayer = false,
    this.roomCode,
    this.warmupTimeMs = 0,
    this.gameplayTimeMs = 0,
  });

  int get totalTimeMs => warmupTimeMs + gameplayTimeMs;

  GameSession copyWith({
    String? discipline,
    String? topicId,
    String? difficulty,
    bool? isMultiplayer,
    String? roomCode,
    bool clearRoomCode = false,
    int? warmupTimeMs,
    int? gameplayTimeMs,
  }) {
    return GameSession(
      discipline: discipline ?? this.discipline,
      topicId: topicId ?? this.topicId,
      difficulty: difficulty ?? this.difficulty,
      isMultiplayer: isMultiplayer ?? this.isMultiplayer,
      roomCode: clearRoomCode ? null : (roomCode ?? this.roomCode),
      warmupTimeMs: warmupTimeMs ?? this.warmupTimeMs,
      gameplayTimeMs: gameplayTimeMs ?? this.gameplayTimeMs,
    );
  }
}

class GameSessionNotifier extends Notifier<GameSession> {
  @override
  GameSession build() => const GameSession();

  void setConfig({
    required String discipline,
    required String topicId,
    required String difficulty,
    required bool isMultiplayer,
  }) {
    state = state.copyWith(
      discipline: discipline,
      topicId: topicId,
      difficulty: difficulty,
      isMultiplayer: isMultiplayer,
      clearRoomCode: !isMultiplayer,
    );
  }

  void setRoomCode(String code) => state = state.copyWith(roomCode: code);
  void setWarmupTime(int ms) => state = state.copyWith(warmupTimeMs: ms);
  void setGameplayTime(int ms) => state = state.copyWith(gameplayTimeMs: ms);
  void reset() => state = const GameSession();
}

final gameSessionProvider =
    NotifierProvider<GameSessionNotifier, GameSession>(GameSessionNotifier.new);