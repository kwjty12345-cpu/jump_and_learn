import 'package:flutter/material.dart';

class FlashcardDeck extends StatelessWidget {
  const FlashcardDeck({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: const Text(
          'What is Encapsulation?',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}