import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import '../domain/multiplayer_models.dart';

class MultiplayerRoomException implements Exception {
  final String message;
  const MultiplayerRoomException(this.message);

  @override
  String toString() => message;
}

abstract class MultiplayerRepository {
  Future<MultiplayerRoom> createRoom({
    required String hostUid,
    required String hostName,
    required String discipline,
    required String topicId,
    required String difficulty,
  });

  Future<MultiplayerRoom> joinRoom({
    required String roomCode,
    required String uid,
    required String displayName,
  });

  Future<void> leaveRoom({
    required String roomCode,
    required String uid,
  });

  Future<void> setPlayerReady({
    required String roomCode,
    required String uid,
    required bool isReady,
  });

  Future<void> startWarmup(String roomCode);

  Future<void> markWarmupDone({
    required String roomCode,
    required String uid,
    required int warmupTimeMs,
  });

  Future<void> startGameplay(String roomCode);

  Future<void> updatePlayerProgress({
    required String roomCode,
    required String uid,
    required int platformIndex,
    bool isRespawning = false,
  });

  Future<void> setRespawning({
    required String roomCode,
    required String uid,
    required bool isRespawning,
  });

  Future<void> submitFinishTime({
    required String roomCode,
    required String uid,
    required int finishTimeMs,
  });

  Stream<MultiplayerRoom?> watchRoom(String roomCode);

  Stream<MultiplayerPlayer?> watchOpponent({
    required String roomCode,
    required String currentUid,
  });
}

class FirebaseMultiplayerRepository implements MultiplayerRepository {
  final FirebaseDatabase _database;
  final Random _random;

  FirebaseMultiplayerRepository({
    FirebaseDatabase? database,
    Random? random,
  })  : _database = database ?? FirebaseDatabase.instance,
        _random = random ?? Random.secure();

  DatabaseReference _roomRef(String roomCode) =>
      _database.ref('rooms/$roomCode');

  DatabaseReference _playerRef(String roomCode, String uid) =>
      _database.ref('rooms/$roomCode/players/$uid');

  Map<String, dynamic> _snapshotToMap(DataSnapshot snapshot) {
    final value = snapshot.value;
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
    return const {};
  }

  Future<String> _generateUniqueRoomCode() async {
    for (var attempt = 0; attempt < 8; attempt++) {
      final code = (100000 + _random.nextInt(900000)).toString();
      final snap = await _roomRef(code).get();
      if (!snap.exists) {
        return code;
      }
    }
    throw const MultiplayerRoomException(
      'Unable to allocate a unique 6-digit room code. Please try again.',
    );
  }

  Future<void> _attachDisconnectHook(String roomCode, String uid) async {
    final playerRef = _playerRef(roomCode, uid);
    await playerRef.child('connected').onDisconnect().set(false);
    await playerRef.child('isReady').onDisconnect().set(false);
  }

  @override
  Future<MultiplayerRoom> createRoom({
    required String hostUid,
    required String hostName,
    required String discipline,
    required String topicId,
    required String difficulty,
  }) async {
    final roomCode = await _generateUniqueRoomCode();
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    final hostPlayer = MultiplayerPlayer(
      uid: hostUid,
      displayName: hostName,
      isHost: true,
      isReady: false,
      connected: true,
      updatedAt: nowMs,
    );

    final roomPayload = <String, dynamic>{
      'roomCode': roomCode,
      'hostUid': hostUid,
      'discipline': discipline,
      'topicId': topicId,
      'difficulty': difficulty,
      'status': RoomStatus.waiting.name,
      'createdAt': ServerValue.timestamp,
      'players': {
        hostUid: {
          ...hostPlayer.toMap(),
          'updatedAt': ServerValue.timestamp,
        },
      },
    };

    await _roomRef(roomCode).set(roomPayload);
    await _attachDisconnectHook(roomCode, hostUid);

    return MultiplayerRoom(
      roomCode: roomCode,
      hostUid: hostUid,
      discipline: discipline,
      topicId: topicId,
      difficulty: difficulty,
      status: RoomStatus.waiting,
      createdAt: nowMs,
      players: {hostUid: hostPlayer},
    );
  }

  @override
  Future<MultiplayerRoom> joinRoom({
    required String roomCode,
    required String uid,
    required String displayName,
  }) async {
    final sanitized = roomCode.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(sanitized)) {
      throw const MultiplayerRoomException(
        'Please enter a valid 6-digit room code.',
      );
    }

    final snapshot = await _roomRef(sanitized).get();
    if (!snapshot.exists) {
      throw MultiplayerRoomException('Room $sanitized was not found.');
    }

    final room = MultiplayerRoom.fromMap(sanitized, _snapshotToMap(snapshot));
    final alreadyInRoom = room.players.containsKey(uid);

    if (!alreadyInRoom && room.status != RoomStatus.waiting) {
      throw const MultiplayerRoomException(
        'This match has already started and cannot be joined.',
      );
    }

    if (!alreadyInRoom && room.isFull) {
      throw const MultiplayerRoomException(
        'This room is already full (2/2 players).',
      );
    }

    final existing = room.players[uid];
    final player = existing != null
        ? existing.copyWith(
            displayName: displayName,
            connected: true,
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          )
        : MultiplayerPlayer(
            uid: uid,
            displayName: displayName,
            isHost: false,
            isReady: false,
            connected: true,
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          );

    await _playerRef(sanitized, uid).set({
      ...player.toMap(),
      'updatedAt': ServerValue.timestamp,
    });
    await _attachDisconnectHook(sanitized, uid);

    final updatedPlayers = Map<String, MultiplayerPlayer>.from(room.players)
      ..[uid] = player;

    return MultiplayerRoom(
      roomCode: room.roomCode,
      hostUid: room.hostUid,
      discipline: room.discipline,
      topicId: room.topicId,
      difficulty: room.difficulty,
      status: room.status,
      createdAt: room.createdAt,
      warmupStartedAt: room.warmupStartedAt,
      gameplayStartedAt: room.gameplayStartedAt,
      players: updatedPlayers,
    );
  }

  @override
  Future<void> leaveRoom({
    required String roomCode,
    required String uid,
  }) async {
    final playerRef = _playerRef(roomCode, uid);
    await playerRef.child('connected').onDisconnect().cancel();
    await playerRef.child('isReady').onDisconnect().cancel();

    final snapshot = await _roomRef(roomCode).get();
    if (!snapshot.exists) return;

    final room = MultiplayerRoom.fromMap(roomCode, _snapshotToMap(snapshot));
    final isHostLeavingWaitingRoom =
        room.hostUid == uid && room.status == RoomStatus.waiting;

    if (isHostLeavingWaitingRoom || room.players.length <= 1) {
      await _roomRef(roomCode).remove();
    } else {
      await playerRef.remove();
    }
  }

  @override
  Future<void> setPlayerReady({
    required String roomCode,
    required String uid,
    required bool isReady,
  }) async {
    await _playerRef(roomCode, uid).update({
      'isReady': isReady,
      'connected': true,
      'updatedAt': ServerValue.timestamp,
    });
  }

  @override
  Future<void> startWarmup(String roomCode) async {
    await _roomRef(roomCode).update({
      'status': RoomStatus.warmup.name,
      'warmupStartedAt': ServerValue.timestamp,
    });
  }

  @override
  Future<void> markWarmupDone({
    required String roomCode,
    required String uid,
    required int warmupTimeMs,
  }) async {
    await _playerRef(roomCode, uid).update({
      'warmupDone': true,
      'warmupTimeMs': warmupTimeMs,
      'updatedAt': ServerValue.timestamp,
    });

    final snapshot = await _roomRef(roomCode).get();
    if (!snapshot.exists) return;

    final room = MultiplayerRoom.fromMap(roomCode, _snapshotToMap(snapshot));
    if (room.status == RoomStatus.warmup && room.allWarmupDone) {
      await startGameplay(roomCode);
    }
  }

  @override
  Future<void> startGameplay(String roomCode) async {
    await _roomRef(roomCode).update({
      'status': RoomStatus.playing.name,
      'gameplayStartedAt': ServerValue.timestamp,
    });
  }

  @override
  Future<void> updatePlayerProgress({
    required String roomCode,
    required String uid,
    required int platformIndex,
    bool isRespawning = false,
  }) async {
    await _playerRef(roomCode, uid).update({
      'platformIndex': platformIndex,
      'isRespawning': isRespawning,
      'connected': true,
      'updatedAt': ServerValue.timestamp,
    });
  }

  @override
  Future<void> setRespawning({
    required String roomCode,
    required String uid,
    required bool isRespawning,
  }) async {
    await _playerRef(roomCode, uid).update({
      'isRespawning': isRespawning,
      'updatedAt': ServerValue.timestamp,
    });
  }

  @override
  Future<void> submitFinishTime({
    required String roomCode,
    required String uid,
    required int finishTimeMs,
  }) async {
    await _playerRef(roomCode, uid).update({
      'finishTimeMs': finishTimeMs,
      'isRespawning': false,
      'updatedAt': ServerValue.timestamp,
    });

    final snapshot = await _roomRef(roomCode).get();
    if (!snapshot.exists) return;

    final room = MultiplayerRoom.fromMap(roomCode, _snapshotToMap(snapshot));
    if (room.allFinished && room.status != RoomStatus.finished) {
      await _roomRef(roomCode).update({
        'status': RoomStatus.finished.name,
      });
    }
  }

  @override
  Stream<MultiplayerRoom?> watchRoom(String roomCode) {
    return _roomRef(roomCode).onValue.map((event) {
      if (!event.snapshot.exists) return null;
      return MultiplayerRoom.fromMap(roomCode, _snapshotToMap(event.snapshot));
    });
  }

  @override
  Stream<MultiplayerPlayer?> watchOpponent({
    required String roomCode,
    required String currentUid,
  }) {
    return watchRoom(roomCode).map((room) => room?.opponentOf(currentUid));
  }
}