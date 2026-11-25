class Flashcard {
  final String front;
  final String back;

  const Flashcard({
    required this.front,
    required this.back,
  });
}

const summaryNotes = '''
Object-Oriented Programming

- Encapsulation
- Inheritance
- Polymorphism
- Abstraction
''';

const flashcards = [
  Flashcard(
    front: 'What is Encapsulation?',
    back: 'Bundling data and methods.',
  ),
  Flashcard(
    front: 'What is Inheritance?',
    back: 'A class inherits from another class.',
  ),
];