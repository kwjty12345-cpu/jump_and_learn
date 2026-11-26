import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/game_session_provider.dart';
import '../../../core/router/app_router.dart';
import '../domain/multiplayer_models.dart';
import '../providers/multiplayer_providers.dart';

class RoomLobbyScreen extends ConsumerStatefulWidget {
  final VoidCallback? onEnterWarmup;
  final VoidCallback? onExitToLobby;

  const RoomLobbyScreen({
    super.key,
    this.onEnterWarmup,
    this.onExitToLobby,
  });

  @override
  ConsumerState<RoomLobbyScreen> createState() => _RoomLobbyScreenState();
}

class _RoomLobbyScreenState extends ConsumerState<RoomLobbyScreen> {
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  Timer? _countdownTimer;
  int? _countdownSeconds;
  bool _hasNavigatedToWarmup = false;

  @override
  void initState() {
    super.initState();
    final identity = ref.read(multiplayerIdentityProvider);
    _nameController.text = identity.displayName;
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _cancelCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    if (_countdownSeconds != null && mounted) {
      setState(() => _countdownSeconds = null);
    }
  }

  void _syncCountdown(MultiplayerRoom room, String currentUid) {
    if (room.status != RoomStatus.waiting || !room.allPlayersReady) {
      _cancelCountdown();
      return;
    }

    if (_countdownTimer != null) return;

    setState(() => _countdownSeconds = 3);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final next = (_countdownSeconds ?? 1) - 1;
      if (next <= 0) {
        timer.cancel();
        _countdownTimer = null;
        setState(() => _countdownSeconds = 0);
        if (room.hostUid == currentUid) {
          ref
              .read(multiplayerControllerProvider.notifier)
              .startWarmup(room.roomCode);
        }
      } else {
        setState(() => _countdownSeconds = next);
      }
    });
  }

  void _navigateToWarmup() {
    if (_hasNavigatedToWarmup || !mounted) return;
    _hasNavigatedToWarmup = true;
    _cancelCountdown();

    if (widget.onEnterWarmup != null) {
      widget.onEnterWarmup!();
    } else {
      context.go(AppRoutes.warmup);
    }
  }

  Future<void> _handleBackToLobby() async {
    _cancelCountdown();
    await ref.read(multiplayerControllerProvider.notifier).leaveRoom();
    if (!mounted) return;
    if (widget.onExitToLobby != null) {
      widget.onExitToLobby!();
    } else {
      context.go(AppRoutes.lobby);
    }
  }

  Future<void> _copyRoomCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Room code $code copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(gameSessionProvider);
    final identity = ref.watch(multiplayerIdentityProvider);
    final actionState = ref.watch(multiplayerControllerProvider);
    final activeCode = actionState.activeRoomCode;

    if (activeCode != null) {
      ref.listen<AsyncValue<MultiplayerRoom?>>(
        roomStreamProvider(activeCode),
        (_, next) {
          next.whenData((room) {
            if (!mounted) return;
            if (room == null) {
              _cancelCountdown();
              ref
                  .read(multiplayerControllerProvider.notifier)
                  .clearActiveRoom();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('The room was closed by the host.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }

            if (room.status == RoomStatus.warmup ||
                room.status == RoomStatus.playing) {
              _navigateToWarmup();
              return;
            }

            _syncCountdown(room, identity.uid);
          });
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(activeCode == null ? 'Multiplayer Room' : 'Room #$activeCode'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back to Lobby',
          onPressed: actionState.isLoading ? null : _handleBackToLobby,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: activeCode == null
                  ? _buildEntryView(context, session, identity, actionState)
                  : _buildWaitingRoomView(context, activeCode, identity),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEntryView(
    BuildContext context,
    GameSession session,
    MultiplayerIdentity identity,
    MultiplayerActionState actionState,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MatchConfigBanner(
          discipline: session.discipline,
          topicId: session.topicId,
          difficulty: session.difficulty,
        ),
        const SizedBox(height: 16),
        if (identity.isGuestFallback) ...[
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(Icons.badge_outlined, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Player Display Name',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => ref
                          .read(multiplayerIdentityProvider.notifier)
                          .setDisplayName(value),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (actionState.errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    actionState.errorMessage!,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        Card(
          elevation: 0,
          color: colorScheme.primaryContainer.withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: colorScheme.primary.withValues(alpha: 0.25),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.add_circle_outline, color: colorScheme.primary),
                    const SizedBox(width: 10),
                    Text(
                      'Host a New Race',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Generate a 6-digit room code and invite a classmate to race head-to-head on this topic.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: actionState.isLoading
                      ? null
                      : () async {
                          _hasNavigatedToWarmup = false;
                          await ref
                              .read(multiplayerControllerProvider.notifier)
                              .createRoom();
                        },
                  icon: actionState.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.meeting_room_outlined),
                  label: const Text('Create 6-Digit Room'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'OR JOIN EXISTING',
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.login_rounded, color: colorScheme.primary),
                    const SizedBox(width: 10),
                    Text(
                      'Join by Room Code',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall?.copyWith(
                    letterSpacing: 8,
                    fontWeight: FontWeight.w700,
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: '000000',
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onSubmitted: (_) => _submitJoin(),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: actionState.isLoading ? null : _submitJoin,
                  icon: const Icon(Icons.group_add_outlined),
                  label: const Text('Join Room'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitJoin() async {
    _hasNavigatedToWarmup = false;
    await ref
        .read(multiplayerControllerProvider.notifier)
        .joinRoom(_codeController.text);
  }

  Widget _buildWaitingRoomView(
    BuildContext context,
    String roomCode,
    MultiplayerIdentity identity,
  ) {
    final roomAsync = ref.watch(roomStreamProvider(roomCode));
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return roomAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 64),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Column(
        children: [
          Icon(Icons.cloud_off, size: 48, color: colorScheme.error),
          const SizedBox(height: 12),
          Text('Connection error: $error', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _handleBackToLobby,
            child: const Text('Return to Lobby'),
          ),
        ],
      ),
      data: (room) {
        if (room == null) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: Text('Room closed.')),
          );
        }

        final me = room.playerByUid(identity.uid);
        final host = room.hostPlayer;
        final guest = room.guestPlayer;
        final isMeReady = me?.isReady ?? false;
        final isHost = room.hostUid == identity.uid;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _MatchConfigBanner(
              discipline: room.discipline,
              topicId: room.topicId,
              difficulty: room.difficulty,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'SHARE ROOM CODE',
                    style: textTheme.labelMedium?.copyWith(
                      letterSpacing: 1.4,
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SelectableText(
                        room.roomCode,
                        style: textTheme.displaySmall?.copyWith(
                          letterSpacing: 8,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        onPressed: () => _copyRoomCode(room.roomCode),
                        icon: const Icon(Icons.copy_rounded),
                        tooltip: 'Copy room code',
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    room.isFull
                        ? '2/2 players joined — toggle Ready to launch Warm-Up together'
                        : 'Waiting for opponent to join (1/2)...',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _PlayerSlotCard(
              label: 'Host',
              player: host,
              isCurrentUser: host?.uid == identity.uid,
            ),
            const SizedBox(height: 12),
            _PlayerSlotCard(
              label: 'Challenger',
              player: guest,
              isCurrentUser: guest?.uid == identity.uid,
            ),
            const SizedBox(height: 20),
            if (_countdownSeconds != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.rocket_launch_rounded, color: Colors.green),
                    const SizedBox(width: 10),
                    Text(
                      _countdownSeconds! > 0
                          ? 'Both ready! Entering Warm-Up in $_countdownSeconds...'
                          : 'Launching Warm-Up...',
                      style: textTheme.titleSmall?.copyWith(
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            FilledButton.icon(
              onPressed: me == null
                  ? null
                  : () => ref
                      .read(multiplayerControllerProvider.notifier)
                      .toggleReady(room),
              style: FilledButton.styleFrom(
                backgroundColor:
                    isMeReady ? Colors.green.shade600 : colorScheme.primary,
              ),
              icon: Icon(
                isMeReady
                    ? Icons.check_circle_rounded
                    : Icons.pan_tool_alt_outlined,
              ),
              label: Text(isMeReady ? 'Ready! (Tap to Cancel)' : 'I am Ready'),
            ),
            if (isHost && room.allPlayersReady) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => ref
                    .read(multiplayerControllerProvider.notifier)
                    .startWarmup(room.roomCode),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start Warm-Up Now'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () async {
                _cancelCountdown();
                await ref
                    .read(multiplayerControllerProvider.notifier)
                    .leaveRoom();
              },
              icon: const Icon(Icons.exit_to_app_rounded),
              label: Text(isHost ? 'Close Room' : 'Leave Room'),
            ),
          ],
        );
      },
    );
  }
}

class _MatchConfigBanner extends StatelessWidget {
  final String discipline;
  final String topicId;
  final String difficulty;

  const _MatchConfigBanner({
    required this.discipline,
    required this.topicId,
    required this.difficulty,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        Chip(
          avatar:
              Icon(Icons.school_outlined, size: 18, color: colorScheme.primary),
          label: Text(discipline),
        ),
        Chip(
          avatar:
              Icon(Icons.topic_outlined, size: 18, color: colorScheme.primary),
          label: Text(topicId),
        ),
        Chip(
          avatar:
              Icon(Icons.speed_rounded, size: 18, color: colorScheme.primary),
          label: Text(difficulty.toUpperCase()),
        ),
      ],
    );
  }
}

class _PlayerSlotCard extends StatelessWidget {
  final String label;
  final MultiplayerPlayer? player;
  final bool isCurrentUser;

  const _PlayerSlotCard({
    required this.label,
    required this.player,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final occupied = player != null;
    final isReady = player?.isReady ?? false;
    final isConnected = player?.connected ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: occupied
            ? (isReady
                ? Colors.green.withValues(alpha: 0.08)
                : colorScheme.surface)
            : colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isReady
              ? Colors.green.shade400
              : (occupied
                  ? colorScheme.outlineVariant
                  : colorScheme.outlineVariant.withValues(alpha: 0.5)),
          width: isReady ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: occupied
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHigh,
            child: Icon(
              occupied ? Icons.person_rounded : Icons.hourglass_empty_rounded,
              color: occupied ? colorScheme.primary : colorScheme.outline,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  occupied
                      ? '${player!.displayName}${isCurrentUser ? ' (You)' : ''}'
                      : 'Waiting for opponent...',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: occupied
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  occupied
                      ? '$label · ${isConnected ? 'Online' : 'Reconnecting...'}'
                      : '$label slot open',
                  style: textTheme.bodySmall?.copyWith(
                    color: occupied && !isConnected
                        ? Colors.orange.shade800
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (occupied)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isReady
                    ? Colors.green.shade600
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isReady ? 'READY' : 'NOT READY',
                style: textTheme.labelSmall?.copyWith(
                  color: isReady ? Colors.white : colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}