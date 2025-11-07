import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cka_question.dart';

// SetupScreen의 선택 상태를 관리
class SetupNotifier extends StateNotifier<QuizSetupSettings> {
  SetupNotifier()
      : super(QuizSetupSettings(
          topicIds: {'pods'}, // 기본 선택
          questionCount: 10,
          quizType: 'random',
          timeLimitInMinutes: 30,
        ));

  void toggleTopic(String topicId) {
    final newTopics = Set<String>.from(state.topicIds);
    if (newTopics.contains(topicId)) {
      newTopics.remove(topicId);
    } else {
      newTopics.add(topicId);
    }
    state = state.copyWith(topicIds: newTopics);
  }

  void setQuestionCount(int count) {
    state = state.copyWith(questionCount: count);
  }

  void setQuizType(String type) {
    state = state.copyWith(quizType: type);
  }

  void setTimeLimit(int minutes) {
    state = state.copyWith(timeLimitInMinutes: minutes);
  }
}

final setupProvider = StateNotifierProvider<SetupNotifier, QuizSetupSettings>((ref) {
  return SetupNotifier();
});