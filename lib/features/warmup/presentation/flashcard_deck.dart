import 'package:flutter/material.dart';
import '../data/warmup_mock_data.dart';

class FlashcardDeck extends StatefulWidget {
  const FlashcardDeck({super.key});

  @override
  State<FlashcardDeck> createState() => _FlashcardDeckState();
}

class _FlashcardDeckState extends State<FlashcardDeck> {
  int currentIndex = 0;
  bool showAnswer = false;

  @override
  Widget build(BuildContext context) {
    final card = flashcards[currentIndex];

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Flashcard ${currentIndex + 1}/${flashcards.length}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              showAnswer ? card.back : card.front,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                setState(() {
                  showAnswer = !showAnswer;
                });
              },
              child: Text(
                showAnswer
                    ? 'Show Question'
                    : 'Show Answer',
              ),
            ),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: currentIndex > 0
                      ? () {
                          setState(() {
                            currentIndex--;
                            showAnswer = false;
                          });
                        }
                      : null,
                  child: const Text('Previous'),
                ),

                const SizedBox(width: 10),

                ElevatedButton(
                  onPressed: currentIndex < flashcards.length - 1
                      ? () {
                          setState(() {
                            currentIndex++;
                            showAnswer = false;
                          });
                        }
                      : null,
                  child: const Text('Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}