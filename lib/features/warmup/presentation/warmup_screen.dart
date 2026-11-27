import 'dart:async';

import 'package:flutter/material.dart';

import '../data/warmup_mock_data.dart';
import 'flashcard_deck.dart';

class WarmupScreen extends StatefulWidget {
  const WarmupScreen({super.key});

  @override
  State<WarmupScreen> createState() => _WarmupScreenState();
}

class _WarmupScreenState extends State<WarmupScreen> {
  int remainingSeconds = 180;

  Timer? timer;

  final Stopwatch stopwatch = Stopwatch();

  bool isPaused = false;

  @override
  void initState() {
    super.initState();

    stopwatch.start();

    timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (!isPaused && remainingSeconds > 0) {
          setState(() {
            remainingSeconds--;
          });
        } else if (remainingSeconds <= 0) {
          showTimeUpDialog();
        }
      },
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  String get formattedTime {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get studyTime {
  final totalSeconds =
      stopwatch.elapsedMilliseconds ~/ 1000;

  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;

  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void showTimeUpDialog() {
    stopwatch.stop();

    timer?.cancel();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Time's Up!"),
          content: const Text(
            'Warm-up phase ended.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);

                // TODO: Start Game
              },
              child: const Text('Start Game'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);

                setState(() {
                  remainingSeconds = 180;
                  isPaused = false;
                });

                stopwatch
                  ..reset()
                  ..start();

                timer = Timer.periodic(
                  const Duration(seconds: 1),
                  (timer) {
                    if (!isPaused && remainingSeconds > 0) {
                      setState(() {
                        remainingSeconds--;
                      });
                    } else if (remainingSeconds <= 0) {
                      showTimeUpDialog();
                    }
                  },
                );
              },
              child: const Text('Study Again'),
            ),
          ],
        );
      },
    );
  }

  void showWarmupCompleteDialog() {
    stopwatch.stop();

    setState(() {
      isPaused = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Warm-Up Complete'),
          content: Text(
            'Study Time Used: $studyTime',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);

                // TODO: Start Game
              },
              child: const Text('Start Game'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);

                stopwatch.start();

                setState(() {
                  isPaused = false;
                });
              },
              child: const Text('Not Yet'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);

                // TODO: Quit
              },
              child: const Text('Quit'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Warm-Up Phase'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  formattedTime,
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const Text(
                '📚 Summary Notes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(summaryNotes),
              ),

              const SizedBox(height: 20),

              const Text(
                '🧠 Flashcards',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const FlashcardDeck(),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: showWarmupCompleteDialog,
                child: const Text("I'm Ready"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}