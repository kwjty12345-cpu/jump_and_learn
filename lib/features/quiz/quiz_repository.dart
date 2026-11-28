import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jump_and_learn/core/models/app_models.dart';

class QuizRepository {
  final FirebaseFirestore _firestore;
  final Random _random = Random();

  QuizRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<QuestionModel>> fetchRandomizedQuestions({
    required String topicId,
    String? difficulty,
  }) async {
    final collection = _firestore
        .collection('topics')
        .doc(topicId)
        .collection('questions');

    final snapshot = (difficulty != null && difficulty.isNotEmpty)
        ? await collection
            .where('difficulty', isEqualTo: difficulty.toLowerCase())
            .get()
        : await collection.get();

    final docs = snapshot.docs.isNotEmpty
        ? snapshot.docs
        : (await collection.get()).docs;

    final questions = docs
        .map((doc) => QuestionModel.fromMap(doc.id, doc.data()))
        .toList();

    questions.shuffle(_random);
    return questions;
  }
}