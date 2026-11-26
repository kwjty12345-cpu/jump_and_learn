enum RoomStatus {
  waiting,
  warmup,
  playing,
  finished;

  static RoomStatus fromString(String? value) {
    return RoomStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => RoomStatus.waiting,
    );
  }
}

Map<String, dynamic> _asStringMap(dynamic raw) {
  if (raw is Map) {
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

int? _asNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

class MultiplayerPlayer {
  final String uid;
  final String displayName;
  final bool isHost;
  final bool isReady;
  final bool warmupDone;
  final int warmupTimeMs;
  final int platformIndex;
  final bool isRespawning;
  final int? finishTimeMs;
  final bool connected;
  final int updatedAt;

  const MultiplayerPlayer({
    required this.uid,
    required this.displayName,
    required this.isHost,
    this.isReady = false,
    this.warmupDone = false,
    this.warmupTimeMs = 0,
    this.platformIndex = 0,
    this.isRespawning = false,
    this.finishTimeMs,
    this.connected = true,
    this.updatedAt = 0,
  });

  bool get hasFinished => finishTimeMs != null;

  factory MultiplayerPlayer.fromMap(String uid, Map<String, dynamic> map) {
    return MultiplayerPlayer(
      uid: (map['uid'] as String?) ?? uid,
      displayName: (map['displayName'] as String?) ?? 'Player',
      isHost: (map['isHost'] as bool?) ?? false,
      isReady: (map['isReady'] as bool?) ?? false,
      warmupDone: (map['warmupDone'] as bool?) ?? false,
      warmupTimeMs: _asInt(map['warmupTimeMs']),
      platformIndex: _asInt(map['platformIndex']),
      isRespawning: (map['isRespawning'] as bool?) ?? false,
      finishTimeMs: _asNullableInt(map['finishTimeMs']),
      connected: (map['connected'] as bool?) ?? true,
      updatedAt: _asInt(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'isHost': isHost,
      'isReady': isReady,
      'warmupDone': warmupDone,
      'warmupTimeMs': warmupTimeMs,
      'platformIndex': platformIndex,
      'isRespawning': isRespawning,
      'finishTimeMs': finishTimeMs,
      'connected': connected,
      'updatedAt': updatedAt,
    };
  }

  MultiplayerPlayer copyWith({
    String? displayName,
    bool? isHost,
    bool? isReady,
    bool? warmupDone,
    int? warmupTimeMs,
    int? platformIndex,
    bool? isRespawning,
    int? finishTimeMs,
    bool? connected,
    int? updatedAt,
  }) {
    return MultiplayerPlayer(
      uid: uid,
      displayName: displayName ?? this.displayName,
      isHost: isHost ?? this.isHost,
      isReady: isReady ?? this.isReady,
      warmupDone: warmupDone ?? this.warmupDone,
      warmupTimeMs: warmupTimeMs ?? this.warmupTimeMs,
      platformIndex: platformIndex ?? this.platformIndex,
      isRespawning: isRespawning ?? this.isRespawning,
      finishTimeMs: finishTimeMs ?? this.finishTimeMs,
      connected: connected ?? this.connected,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class MultiplayerRoom {
  final String roomCode;
  final String hostUid;
  final String discipline;
  final String topicId;
  final String difficulty;
  final RoomStatus status;
  final int createdAt;
  final int? warmupStartedAt;
  final int? gameplayStartedAt;
  final Map<String, MultiplayerPlayer> players;

  const MultiplayerRoom({
    required this.roomCode,
    required this.hostUid,
    required this.discipline,
    required this.topicId,
    required this.difficulty,
    required this.status,
    this.createdAt = 0,
    this.warmupStartedAt,
    this.gameplayStartedAt,
    this.players = const {},
  });

  List<MultiplayerPlayer> get orderedPlayers {
    final list = players.values.toList();
    list.sort((a, b) {
      if (a.isHost != b.isHost) return a.isHost ? -1 : 1;
      return a.displayName.compareTo(b.displayName);
    });
    return list;
  }

  MultiplayerPlayer? get hostPlayer {
    for (final player in players.values) {
      if (player.isHost) return player;
    }
    return players[hostUid];
  }

  MultiplayerPlayer? get guestPlayer {
    for (final player in players.values) {
      if (!player.isHost) return player;
    }
    return null;
  }

  MultiplayerPlayer? playerByUid(String uid) => players[uid];

  MultiplayerPlayer? opponentOf(String uid) {
    for (final player in players.values) {
      if (player.uid != uid) return player;
    }
    return null;
  }

  bool get isFull => players.length >= 2;

  bool get allPlayersReady =>
      players.length == 2 &&
      players.values.every((p) => p.isReady && p.connected);

  bool get allWarmupDone =>
      players.length == 2 && players.values.every((p) => p.warmupDone);

  bool get allFinished =>
      players.isNotEmpty && players.values.every((p) => p.hasFinished);

  factory MultiplayerRoom.fromMap(String roomCode, Map<String, dynamic> map) {
    final rawPlayers = _asStringMap(map['players']);
    final parsedPlayers = <String, MultiplayerPlayer>{};
    for (final entry in rawPlayers.entries) {
      final playerMap = _asStringMap(entry.value);
      if (playerMap.isNotEmpty) {
        parsedPlayers[entry.key] = MultiplayerPlayer.fromMap(
          entry.key,
          playerMap,
        );
      }
    }

    return MultiplayerRoom(
      roomCode: (map['roomCode'] as String?) ?? roomCode,
      hostUid: (map['hostUid'] as String?) ?? '',
      discipline: (map['discipline'] as String?) ?? 'Computer Science',
      topicId: (map['topicId'] as String?) ?? 'cs_01',
      difficulty: (map['difficulty'] as String?) ?? 'medium',
      status: RoomStatus.fromString(map['status'] as String?),
      createdAt: _asInt(map['createdAt']),
      warmupStartedAt: _asNullableInt(map['warmupStartedAt']),
      gameplayStartedAt: _asNullableInt(map['gameplayStartedAt']),
      players: parsedPlayers,
    );
  }
}