import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../game/game_page.dart';
import '../providers/game_session_provider.dart';
import '../widgets/dev_placeholder_screen.dart';

// 队友交付 PR 并合入 dev 后，在这里逐个解除注释：
// import '../../features/auth/presentation/login_screen.dart';
// import '../../features/lobby/presentation/lobby_screen.dart';
// import '../../features/multiplayer/presentation/room_lobby_screen.dart';
// import '../../features/warmup/presentation/warmup_screen.dart';
// import '../../features/leaderboard/presentation/result_screen.dart';
// import '../../features/leaderboard/presentation/leaderboard_screen.dart';

class AppRoutes {
  static const login = '/login';
  static const lobby = '/lobby';
  static const room = '/room';
  static const warmup = '/warmup';
  static const play = '/play';
  static const result = '/result';
  static const leaderboard = '/leaderboard';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.login,
    routes: [
      // 1. 登录页 (成员 1)
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) {
          return DevPlaceholderScreen(
            ownerLabel: '成员 1',
            screenName: '登录 / 注册页',
            nextButtonText: '模拟登录成功 → 进入主大厅',
            onSimulateNext: () => context.go(AppRoutes.lobby),
          );
        },
      ),

      // 2. 主大厅与学科/难度选择 (成员 2)
      GoRoute(
        path: AppRoutes.lobby,
        builder: (context, state) {
          return DevPlaceholderScreen(
            ownerLabel: '成员 2',
            screenName: '主大厅 (学科 / 难度 / 模式)',
            nextButtonText: '模拟 Solo 模式 → 进入 3 分钟复习',
            onSimulateNext: () {
              ref.read(gameSessionProvider.notifier).setConfig(
                    discipline: 'Computer Science',
                    topicId: 'cs_algo_01',
                    difficulty: 'medium',
                    isMultiplayer: false,
                  );
              context.go(AppRoutes.warmup);
            },
            secondaryButtonText: '模拟 Multiplayer 模式 → 进入联机房',
            onSecondaryAction: () {
              ref.read(gameSessionProvider.notifier).setConfig(
                    discipline: 'Computer Science',
                    topicId: 'cs_algo_01',
                    difficulty: 'medium',
                    isMultiplayer: true,
                  );
              context.go(AppRoutes.room);
            },
          );
        },
      ),

      // 3. 多人联机房间 (成员 6)
      GoRoute(
        path: AppRoutes.room,
        builder: (context, state) {
          final session = ref.read(gameSessionProvider);
          return DevPlaceholderScreen(
            ownerLabel: '成员 6',
            screenName: '联机匹配 / 房间页',
            details: '学科: ${session.discipline} | 难度: ${session.difficulty}',
            nextButtonText: '模拟双方就绪 (房号 884210) → 进入复习',
            onSimulateNext: () {
              ref.read(gameSessionProvider.notifier).setRoomCode('884210');
              context.go(AppRoutes.warmup);
            },
          );
        },
      ),

      // 4. 赛前限时复习 (成员 3)
      GoRoute(
        path: AppRoutes.warmup,
        builder: (context, state) {
          final session = ref.read(gameSessionProvider);
          return DevPlaceholderScreen(
            ownerLabel: '成员 3',
            screenName: '赛前 3 分钟复习 (闪卡 & 摘要)',
            details: 'Topic: ${session.topicId} | 模式: ${session.isMultiplayer ? "Multiplayer" : "Solo"}',
            nextButtonText: '模拟复习完毕 (用时 95 秒) → 开始跳一跳',
            onSimulateNext: () {
              ref.read(gameSessionProvider.notifier).setWarmupTime(95000);
              context.go(AppRoutes.play);
            },
          );
        },
      ),

      // 5. 核心游戏页 (成员 4 + 成员 5 + 成员 6 组装容器)
      GoRoute(
        path: AppRoutes.play,
        builder: (context, state) {
          final session = ref.read(gameSessionProvider);
          return GamePage(
            topicId: session.topicId,
            difficulty: session.difficulty,
            roomCode: session.roomCode,
            onGameCompleted: (gameplayTimeMs) {
              ref.read(gameSessionProvider.notifier).setGameplayTime(gameplayTimeMs);
              context.go(AppRoutes.result);
            },
          );
        },
      ),

      // 6. 完赛结算页 (成员 7)
      GoRoute(
        path: AppRoutes.result,
        builder: (context, state) {
          final session = ref.read(gameSessionProvider);
          return DevPlaceholderScreen(
            ownerLabel: '成员 7',
            screenName: '完赛结算页',
            details:
                '复习耗时: ${session.warmupTimeMs ~/ 1000}s\n'
                '游戏耗时: ${session.gameplayTimeMs ~/ 1000}s\n'
                '总完成时间: ${session.totalTimeMs ~/ 1000}s',
            nextButtonText: '查看时间排行榜',
            onSimulateNext: () => context.go(AppRoutes.leaderboard),
            secondaryButtonText: '返回大厅再来一局',
            onSecondaryAction: () {
              ref.read(gameSessionProvider.notifier).reset();
              context.go(AppRoutes.lobby);
            },
          );
        },
      ),

      // 7. 时间排行榜 (成员 7)
      GoRoute(
        path: AppRoutes.leaderboard,
        builder: (context, state) {
          return DevPlaceholderScreen(
            ownerLabel: '成员 7',
            screenName: '时间排行榜 (Total Time ASC)',
            nextButtonText: '返回主大厅',
            onSimulateNext: () {
              ref.read(gameSessionProvider.notifier).reset();
              context.go(AppRoutes.lobby);
            },
          );
        },
      ),
    ],
  );
});