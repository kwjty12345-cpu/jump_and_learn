
import 'package:flutter/material.dart';

import 'subject_selector.dart';
import 'difficulty_sheet.dart';

typedef LobbyConfigCallback = void Function({
  required String discipline,
  required String topicId,
  required String difficulty,
  required bool isMultiplayer,
});

class LobbyScreen extends StatefulWidget {
  final LobbyConfigCallback onStartGame;
  final VoidCallback onLeaderboardTap;

  const LobbyScreen({
    super.key,
    required this.onStartGame,
    required this.onLeaderboardTap,
  });

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  String selectedDiscipline = 'Computer Science';
  String selectedTopicId = 'cs_algo_01';
  String selectedDifficulty = 'medium';

  static const Color pink = Color(0xFFF06292);
  static const Color darkPink = Color(0xFFDB3975);

  void changeDiscipline(String discipline) {
    final topics = LobbyCatalog.disciplines
        .firstWhere((item) => item.name == discipline)
        .topics;

    setState(() {
      selectedDiscipline = discipline;
      selectedTopicId = topics.first.id;
    });
  }

  void startGame(bool isMultiplayer) {
    widget.onStartGame(
      discipline: selectedDiscipline,
      topicId: selectedTopicId,
      difficulty: selectedDifficulty,
      isMultiplayer: isMultiplayer,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8FA),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 850),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFCE4EC),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.sports_esports,
                          color: pink,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'JUMP & LEARN',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                                color: Color(0xFF333333),
                              ),
                            ),
                            Text(
                              'Learn. Play. Compete.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Leaderboard',
                        onPressed: widget.onLeaderboardTap,
                        icon: const Icon(
                          Icons.emoji_events_outlined,
                          color: darkPink,
                          size: 28,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFF06292),
                          Color(0xFFEC407A),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ready to jump in?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 27,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Choose your subject, set your challenge, '
                          'and see how far you can go!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  SubjectSelector(
                    selectedDiscipline: selectedDiscipline,
                    selectedTopicId: selectedTopicId,
                    onDisciplineChanged: changeDiscipline,
                    onTopicChanged: (topicId) {
                      setState(() {
                        selectedTopicId = topicId;
                      });
                    },
                  ),

                  const SizedBox(height: 28),

                  DifficultySheet(
                    selectedDifficulty: selectedDifficulty,
                    onDifficultyChanged: (difficulty) {
                      setState(() {
                        selectedDifficulty = difficulty;
                      });
                    },
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    'Choose your game mode',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: _ModeButton(
                          title: 'Solo',
                          subtitle: 'Play on your own',
                          icon: Icons.person,
                          onTap: () => startGame(false),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _ModeButton(
                          title: 'Multiplayer',
                          subtitle: 'Compete with friends',
                          icon: Icons.groups,
                          onTap: () => startGame(true),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Center(
                    child: TextButton.icon(
                      onPressed: widget.onLeaderboardTap,
                      icon: const Icon(Icons.leaderboard_outlined),
                      label: const Text('View Leaderboard'),
                      style: TextButton.styleFrom(
                        foregroundColor: darkPink,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Center(
                    child: Text(
                      'Choose wisely and enjoy the game!',
                      style: TextStyle(
                        color: Colors.black45,
                        fontSize: 12,
                      ),
                    ),
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

class _ModeButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ModeButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 20,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFF8BBD0),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 34,
                color: const Color(0xFFF06292),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
