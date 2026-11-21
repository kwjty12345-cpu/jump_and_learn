import 'package:flutter/material.dart';
// 成员 4、5、6 交付后取消注释：
// import 'package:flame/game.dart';
// import 'jump_learn_game.dart';
// import 'overlays/respawn_banner.dart';
// import '../features/quiz/presentation/quiz_overlay_dialog.dart';
// import '../features/multiplayer/presentation/race_progress_hud.dart';

class GamePage extends StatelessWidget {
  final String topicId;
  final String difficulty;
  final String? roomCode;
  final int totalPlatforms;
  final void Function(int gameplayTimeMs) onGameCompleted;

  const GamePage({
    super.key,
    required this.topicId,
    required this.difficulty,
    required this.onGameCompleted,
    this.roomCode,
    this.totalPlatforms = 10,
  });

  @override
  Widget build(BuildContext context) {
    final modeText = roomCode == null ? 'Solo Mode' : 'Multiplayer · Room $roomCode';

    return Scaffold(
      appBar: AppBar(title: const Text('Jump & Learn · Gameplay')),
      body: Stack(
        children: [
          // TODO: 成员 5 & 成员 4 交付后替换为 GameWidget(game: ..., overlayBuilderMap: ...)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.sports_esports_outlined,
                    size: 72,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '游戏容器已就绪\n等待接入 成员5(Flame引擎) + 成员4(答题弹窗) + 成员6(联机进度)',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Text('Topic: $topicId | Difficulty: $difficulty | $modeText'),
                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed: () => onGameCompleted(120000),
                    child: const Text('模拟跳完全程 (用时 120 秒) → 结算页'),
                  ),
                ],
              ),
            ),
          ),

          // TODO: 成员 6 交付后取消注释，叠加多人竞速进度条
          // if (roomCode != null)
          //   Positioned(
          //     top: 16,
          //     left: 16,
          //     right: 16,
          //     child: RaceProgressHud(
          //       roomCode: roomCode!,
          //       totalPlatforms: totalPlatforms,
          //     ),
          //   ),
        ],
      ),
    );
  }
}