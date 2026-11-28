import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jump_and_learn/core/models/app_models.dart';
import 'package:jump_and_learn/features/quiz/quiz_repository.dart';

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  return QuizRepository();
});

final randomizedQuestionsProvider = FutureProvider.autoDispose
    .family<List<QuestionModel>, ({String topicId, String? difficulty})>(
  (ref, params) async {
    final repo = ref.watch(quizRepositoryProvider);
    return repo.fetchRandomizedQuestions(
      topicId: params.topicId,
      difficulty: params.difficulty,
    );
  },
);