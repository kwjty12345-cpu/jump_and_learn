class UserProfile {
  final String uid;
  final String displayName;
  final String email;
  final String major;

  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.major,
  });

  factory UserProfile.fromMap(String uid, Map<String, dynamic> map) {
    return UserProfile(
      uid: uid,
      displayName: (map['displayName'] as String?) ?? 'Student',
      email: (map['email'] as String?) ?? '',
      major: (map['major'] as String?) ?? 'Computer Science',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'email': email,
      'major': major,
    };
  }
}

class FlashcardItem {
  final String front;
  final String back;

  const FlashcardItem({
    required this.front,
    required this.back,
  });

  factory FlashcardItem.fromMap(Map<String, dynamic> map) {
    return FlashcardItem(
      front: (map['front'] as String?) ?? '',
      back: (map['back'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() => {'front': front, 'back': back};
}

class TopicModel {
  final String id;
  final String discipline;
  final String title;
  final String difficulty; // 'easy' | 'medium' | 'hard'
  final String summaryMarkdown;
  final List<FlashcardItem> flashcards;

  const TopicModel({
    required this.id,
    required this.discipline,
    required this.title,
    required this.difficulty,
    required this.summaryMarkdown,
    required this.flashcards,
  });

  factory TopicModel.fromMap(String id, Map<String, dynamic> map) {
    final rawCards = (map['flashcards'] as List<dynamic>?) ?? const [];
    return TopicModel(
      id: id,
      discipline: (map['discipline'] as String?) ?? 'Computer Science',
      title: (map['title'] as String?) ?? '',
      difficulty: (map['difficulty'] as String?) ?? 'medium',
      summaryMarkdown: (map['summaryMarkdown'] as String?) ?? '',
      flashcards: rawCards
          .map((e) => FlashcardItem.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'discipline': discipline,
      'title': title,
      'difficulty': difficulty,
      'summaryMarkdown': summaryMarkdown,
      'flashcards': flashcards.map((c) => c.toMap()).toList(),
    };
  }
}

class QuestionModel {
  final String id;
  final String prompt;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const QuestionModel({
    required this.id,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  factory QuestionModel.fromMap(String id, Map<String, dynamic> map) {
    final rawOptions = (map['options'] as List<dynamic>?) ?? const [];
    return QuestionModel(
      id: id,
      prompt: (map['prompt'] as String?) ?? '',
      options: rawOptions.map((e) => e.toString()).toList(),
      correctIndex: (map['correctIndex'] as int?) ?? 0,
      explanation: (map['explanation'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'prompt': prompt,
      'options': options,
      'correctIndex': correctIndex,
      'explanation': explanation,
    };
  }
}

class LeaderboardEntry {
  final String id;
  final String uid;
  final String displayName;
  final String discipline;
  final String topicId;
  final String difficulty;
  final String mode; // 'solo' | 'multiplayer'
  final int warmupTimeMs;
  final int gameplayTimeMs;
  final int totalTimeMs;

  const LeaderboardEntry({
    required this.id,
    required this.uid,
    required this.displayName,
    required this.discipline,
    required this.topicId,
    required this.difficulty,
    required this.mode,
    required this.warmupTimeMs,
    required this.gameplayTimeMs,
    required this.totalTimeMs,
  });

  factory LeaderboardEntry.fromMap(String id, Map<String, dynamic> map) {
    return LeaderboardEntry(
      id: id,
      uid: (map['uid'] as String?) ?? '',
      displayName: (map['displayName'] as String?) ?? 'Anonymous',
      discipline: (map['discipline'] as String?) ?? '',
      topicId: (map['topicId'] as String?) ?? '',
      difficulty: (map['difficulty'] as String?) ?? 'medium',
      mode: (map['mode'] as String?) ?? 'solo',
      warmupTimeMs: (map['warmupTimeMs'] as int?) ?? 0,
      gameplayTimeMs: (map['gameplayTimeMs'] as int?) ?? 0,
      totalTimeMs: (map['totalTimeMs'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'discipline': discipline,
      'topicId': topicId,
      'difficulty': difficulty,
      'mode': mode,
      'warmupTimeMs': warmupTimeMs,
      'gameplayTimeMs': gameplayTimeMs,
      'totalTimeMs': totalTimeMs,
    };
  }
}