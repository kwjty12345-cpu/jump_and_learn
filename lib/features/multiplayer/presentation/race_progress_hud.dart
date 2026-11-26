import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/multiplayer_models.dart';
import '../providers/multiplayer_providers.dart';

class RaceProgressHud extends ConsumerWidget {
  final String roomCode;
  final int totalPlatforms;
  final String? currentUid;

  const RaceProgressHud({
    super.key,
    required this.roomCode,
    required this.totalPlatforms,
    this.currentUid,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = currentUid ?? ref.watch(multiplayerIdentityProvider).uid;
    final roomAsync = ref.watch(roomStreamProvider(roomCode));

    return IgnorePointer(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.22),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: roomAsync.when(
              loading: () => _buildLoadingRow(context),
              error: (_, _) => _buildOfflineRow(context),
              data: (room) {
                if (room == null) return _buildOfflineRow(context);
                final me = room.playerByUid(uid);
                final opponent = room.opponentOf(uid);
                return _buildRaceContent(context, room, me, opponent);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 8),
        Text(
          'Syncing Room #$roomCode...',
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ],
    );
  }

  Widget _buildOfflineRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.wifi_off_rounded, size: 16, color: Colors.orange.shade700),
        const SizedBox(width: 8),
        Text(
          'Room #$roomCode · Waiting for live sync',
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ],
    );
  }

  Widget _buildRaceContent(
    BuildContext context,
    MultiplayerRoom room,
    MultiplayerPlayer? me,
    MultiplayerPlayer? opponent,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final safeTotal = totalPlatforms <= 0 ? 1 : totalPlatforms;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'ROOM #${room.roomCode}',
                style: textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.primary,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            const Spacer(),
            Icon(
              Icons.flag_rounded,
              size: 15,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              'Goal: $safeTotal platforms',
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _PlayerProgressRow(
          label: me != null ? '${me.displayName} (You)' : 'You',
          player: me,
          totalPlatforms: safeTotal,
          barColor: colorScheme.primary,
        ),
        const SizedBox(height: 6),
        _PlayerProgressRow(
          label: opponent?.displayName ?? 'Opponent',
          player: opponent,
          totalPlatforms: safeTotal,
          barColor: const Color(0xFF00ACC1),
        ),
      ],
    );
  }
}

class _PlayerProgressRow extends StatelessWidget {
  final String label;
  final MultiplayerPlayer? player;
  final int totalPlatforms;
  final Color barColor;

  const _PlayerProgressRow({
    required this.label,
    required this.player,
    required this.totalPlatforms,
    required this.barColor,
  });

  String _formatMs(int ms) {
    final totalSeconds = ms / 1000;
    final minutes = totalSeconds ~/ 60;
    final seconds = (totalSeconds % 60).toStringAsFixed(1).padLeft(4, '0');
    return minutes > 0 ? '$minutes:$seconds' : '${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final index = (player?.platformIndex ?? 0).clamp(0, totalPlatforms);
    final progress = (index / totalPlatforms).clamp(0.0, 1.0);
    final isRespawning = player?.isRespawning ?? false;
    final finishMs = player?.finishTimeMs;
    final isConnected = player?.connected ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isConnected ? barColor : Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (finishMs != null)
              _StatusBadge(
                text: 'FINISHED ${_formatMs(finishMs)}',
                color: Colors.green.shade700,
              )
            else if (isRespawning)
              _StatusBadge(
                text: 'RESPAWNING',
                color: Colors.orange.shade800,
              )
            else if (player != null && !isConnected)
              const _StatusBadge(
                text: 'OFFLINE',
                color: Colors.grey,
              ),
            const SizedBox(width: 8),
            Text(
              '$index / $totalPlatforms',
              style: textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: barColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(end: progress),
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            builder: (context, animatedValue, _) {
              return LinearProgressIndicator(
                value: animatedValue,
                minHeight: 7,
                backgroundColor: barColor.withValues(alpha: 0.16),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isRespawning ? Colors.orange.shade600 : barColor,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusBadge({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}