import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../domain/multiplayer_models.dart';
import '../providers/multiplayer_providers.dart';

class WarmupSyncOverlay extends ConsumerStatefulWidget {
  final String roomCode;
  final int myWarmupTimeMs;
  final VoidCallback? onStartGameplay;

  const WarmupSyncOverlay({
    super.key,
    required this.roomCode,
    required this.myWarmupTimeMs,
    this.onStartGameplay,
  });

  @override
  ConsumerState<WarmupSyncOverlay> createState() => _WarmupSyncOverlayState();
}

class _WarmupSyncOverlayState extends ConsumerState<WarmupSyncOverlay> {
  bool _hasTransitioned = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(multiplayerControllerProvider.notifier).markWarmupDone(
            roomCode: widget.roomCode,
            warmupTimeMs: widget.myWarmupTimeMs,
          );
    });
  }

  void _enterGameplay() {
    if (_hasTransitioned || !mounted) return;
    _hasTransitioned = true;
    if (widget.onStartGameplay != null) {
      widget.onStartGameplay!();
    } else {
      context.go(AppRoutes.play);
    }
  }

  @override
  Widget build(BuildContext context) {
    final identity = ref.watch(multiplayerIdentityProvider);
    final roomAsync = ref.watch(roomStreamProvider(widget.roomCode));
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    ref.listen<AsyncValue<MultiplayerRoom?>>(
      roomStreamProvider(widget.roomCode),
      (_, next) {
        next.whenData((room) {
          if (room != null && room.status == RoomStatus.playing) {
            _enterGameplay();
          }
        });
      },
    );

    final room = switch (roomAsync) {
      AsyncData(:final value) => value,
      _ => null,
    };
    final opponent = room?.opponentOf(identity.uid);
    final opponentReady = opponent?.warmupDone ?? false;

    return ColoredBox(
      color: Colors.black54,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Card(
            margin: const EdgeInsets.all(24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: colorScheme.primary),
                  const SizedBox(height: 18),
                  Text(
                    opponentReady
                        ? 'Opponent is ready — launching race!'
                        : 'Waiting for ${opponent?.displayName ?? 'opponent'}...',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your Warm-Up time is locked at ${(widget.myWarmupTimeMs / 1000).toStringAsFixed(1)}s. '
                    'Both players will jump into the arena at the exact same moment.',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}