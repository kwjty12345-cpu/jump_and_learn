class Flashcard {
  final String front;
  final String back;

  const Flashcard({
    required this.front,
    required this.back,
  });
}

const flashcards = [
  Flashcard(
    front: 'What is Encapsulation?',
    back: 'Bundling data and methods together.',
  ),
  Flashcard(
    front: 'What is Inheritance?',
    back: 'A child class inherits properties from a parent class.',
  ),
  Flashcard(
    front: 'What is Polymorphism?',
    back: 'Objects can take many forms.',
  ),
];

const String summaryNotes = '''
Object-Oriented Programming (OOP)

1. Encapsulation
   Bundling data and methods together.

2. Inheritance
   Child classes can inherit from parent classes.

3. Polymorphism
   Objects can take multiple forms.

4. Abstraction
   Hide implementation details and show only essentials.
''';