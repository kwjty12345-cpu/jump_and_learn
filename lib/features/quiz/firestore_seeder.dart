import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class FirestoreSeeder {
  static Future<void> uploadSeedData({FirebaseFirestore? firestore}) async {
    final db = firestore ?? FirebaseFirestore.instance;
    final jsonString =
        await rootBundle.loadString('assets/seed_data/seed_data.json');
    final Map<String, dynamic> data = jsonDecode(jsonString);
    final List<dynamic> topics = data['topics'] as List<dynamic>;

    final batch = db.batch();

    for (final rawTopic in topics) {
      final topic = Map<String, dynamic>.from(rawTopic as Map);
      final topicId = topic['id'] as String;
      final questions = (topic['questions'] as List<dynamic>?) ?? [];

      final topicRef = db.collection('topics').doc(topicId);
      batch.set(topicRef, {
        'discipline': topic['discipline'],
        'title': topic['title'],
        'difficulty': topic['difficulty'],
        'summaryMarkdown': topic['summaryMarkdown'],
        'flashcards': topic['flashcards'],
      });

      for (final rawQ in questions) {
        final q = Map<String, dynamic>.from(rawQ as Map);
        final qId = q['id'] as String;
        final qRef = topicRef.collection('questions').doc(qId);
        batch.set(qRef, {
          'difficulty': q['difficulty'] ?? topic['difficulty'],
          'prompt': q['prompt'],
          'options': q['options'],
          'correctIndex': q['correctIndex'],
          'explanation': q['explanation'],
        });
      }
    }

    await batch.commit();
  }
}