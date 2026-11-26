import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/providers/game_session_provider.dart';
import '../data/multiplayer_repository.dart';
import '../domain/multiplayer_models.dart';

class MultiplayerIdentity {
  final String uid;
  final String displayName;
  final bool isGuestFallback;

  const MultiplayerIdentity({
    required this.uid,
    required this.displayName,
    this.isGuestFallback = false,
  });

  MultiplayerIdentity copyWith({String? displayName}) {
    return MultiplayerIdentity(
      uid: uid,
      displayName: displayName ?? this.displayName,
      isGuestFallback: isGuestFallback,
    );
  }
}

final firebaseAuthUserProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.userChanges();
});

class MultiplayerIdentityNotifier extends Notifier<MultiplayerIdentity> {
  @override
  MultiplayerIdentity build() {
    final authAsync = ref.watch(firebaseAuthUserProvider);
    final user = switch (authAsync) {
      AsyncData(:final value) => value,
      _ => FirebaseAuth.instance.currentUser,
    };

    if (user != null) {
      final fallbackName = (user.email != null && user.email!.contains('@'))
          ? user.email!.split('@').first
          : 'Player ${user.uid.substring(0, 4).toUpperCase()}';
      return MultiplayerIdentity(
        uid: user.uid,
        displayName:
            (user.displayName != null && user.displayName!.trim().isNotEmpty)
                ? user.displayName!.trim()
                : fallbackName,
        isGuestFallback: user.isAnonymous,
      );
    }

    final shortId = const Uuid().v4().replaceAll('-', '').substring(0, 6);
    return MultiplayerIdentity(
      uid: 'guest_$shortId',
      displayName: 'Player ${shortId.substring(0, 4).toUpperCase()}',
      isGuestFallback: true,
    );
  }

  void setDisplayName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    state = state.copyWith(displayName: trimmed);
  }
}

final multiplayerIdentityProvider =
    NotifierProvider<MultiplayerIdentityNotifier, MultiplayerIdentity>(
  MultiplayerIdentityNotifier.new,
);

final multiplayerRepositoryProvider = Provider<MultiplayerRepository>((ref) {
  return FirebaseMultiplayerRepository();
});

final roomStreamProvider =
    StreamProvider.autoDispose.family<MultiplayerRoom?, String>((ref, roomCode) {
  return ref.watch(multiplayerRepositoryProvider).watchRoom(roomCode);
});

final opponentStreamProvider = StreamProvider.autoDispose
    .family<MultiplayerPlayer?, String>((ref, roomCode) {
  final identity = ref.watch(multiplayerIdentityProvider);
  return ref.watch(multiplayerRepositoryProvider).watchOpponent(
        roomCode: roomCode,
        currentUid: identity.uid,
      );
});

class MultiplayerActionState {
  final String? activeRoomCode;
  final bool isLoading;
  final String? errorMessage;

  const MultiplayerActionState({
    this.activeRoomCode,
    this.isLoading = false,
    this.errorMessage,
  });

  MultiplayerActionState copyWith({
    String? activeRoomCode,
    bool clearActiveRoom = false,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MultiplayerActionState(
      activeRoomCode:
          clearActiveRoom ? null : (activeRoomCode ?? this.activeRoomCode),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class MultiplayerController extends Notifier<MultiplayerActionState> {
  @override
  MultiplayerActionState build() => const MultiplayerActionState();

  MultiplayerRepository get _repo => ref.read(multiplayerRepositoryProvider);
  MultiplayerIdentity get _identity => ref.read(multiplayerIdentityProvider);

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void clearActiveRoom() {
    state = state.copyWith(clearActiveRoom: true, clearError: true);
  }

  Future<bool> createRoom() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final session = ref.read(gameSessionProvider);
      final room = await _repo.createRoom(
        hostUid: _identity.uid,
        hostName: _identity.displayName,
        discipline: session.discipline,
        topicId: session.topicId,
        difficulty: session.difficulty,
      );

      ref.read(gameSessionProvider.notifier).setRoomCode(room.roomCode);
      state = state.copyWith(
        activeRoomCode: room.roomCode,
        isLoading: false,
      );
      return true;
    } on MultiplayerRoomException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to create room: $e',
      );
      return false;
    }
  }

  Future<bool> joinRoom(String rawCode) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final room = await _repo.joinRoom(
        roomCode: rawCode,
        uid: _identity.uid,
        displayName: _identity.displayName,
      );

      final sessionNotifier = ref.read(gameSessionProvider.notifier);
      sessionNotifier.setConfig(
        discipline: room.discipline,
        topicId: room.topicId,
        difficulty: room.difficulty,
        isMultiplayer: true,
      );
      sessionNotifier.setRoomCode(room.roomCode);

      state = state.copyWith(
        activeRoomCode: room.roomCode,
        isLoading: false,
      );
      return true;
    } on MultiplayerRoomException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to join room: $e',
      );
      return false;
    }
  }

  Future<void> toggleReady(MultiplayerRoom room) async {
    final currentPlayer = room.playerByUid(_identity.uid);
    if (currentPlayer == null) return;

    try {
      await _repo.setPlayerReady(
        roomCode: room.roomCode,
        uid: _identity.uid,
        isReady: !currentPlayer.isReady,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Could not update ready state: $e');
    }
  }

  Future<void> startWarmup(String roomCode) async {
    try {
      await _repo.startWarmup(roomCode);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Could not start warm-up: $e');
    }
  }

  Future<void> markWarmupDone({
    required String roomCode,
    required int warmupTimeMs,
  }) async {
    await _repo.markWarmupDone(
      roomCode: roomCode,
      uid: _identity.uid,
      warmupTimeMs: warmupTimeMs,
    );
  }

  Future<void> startGameplay(String roomCode) async {
    await _repo.startGameplay(roomCode);
  }

  Future<void> updateProgress({
    required String roomCode,
    required int platformIndex,
    bool isRespawning = false,
  }) async {
    await _repo.updatePlayerProgress(
      roomCode: roomCode,
      uid: _identity.uid,
      platformIndex: platformIndex,
      isRespawning: isRespawning,
    );
  }

  Future<void> setRespawning({
    required String roomCode,
    required bool isRespawning,
  }) async {
    await _repo.setRespawning(
      roomCode: roomCode,
      uid: _identity.uid,
      isRespawning: isRespawning,
    );
  }

  Future<void> submitFinishTime({
    required String roomCode,
    required int finishTimeMs,
  }) async {
    await _repo.submitFinishTime(
      roomCode: roomCode,
      uid: _identity.uid,
      finishTimeMs: finishTimeMs,
    );
  }

  Future<void> leaveRoom() async {
    final code = state.activeRoomCode;
    if (code == null) return;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.leaveRoom(roomCode: code, uid: _identity.uid);
    } finally {
      state = state.copyWith(
        clearActiveRoom: true,
        isLoading: false,
      );
    }
  }
}

final multiplayerControllerProvider =
    NotifierProvider<MultiplayerController, MultiplayerActionState>(
  MultiplayerController.new,
);