import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cka_question.dart';
import 'cka_repository.dart'; // Repository import

// 퀴즈 생성 및 진행 상태를 모두 관리 (비동기 포함)
class QuizController extends StateNotifier<AsyncValue<QuizSession?>> {
  final Ref _ref;

  QuizController(this._ref) : super(const AsyncData(null)); // 초기 상태: 퀴즈 없음

  // 1. 퀴즈 생성 (SetupScreen에서 호출)
  Future<void> generateQuiz(QuizSetupSettings settings) async {
    state = const AsyncLoading(); // 퀴즈 생성 중...
    try {
      final repository = _ref.read(ckaRepositoryProvider);
      final questions = await repository.generateQuiz(settings); // 💥 Gemini 호출!
      
      final session = QuizSession(
        id: 'session-${DateTime.now().millisecondsSinceEpoch}',
        questions: questions,
        currentIndex: 0,
        userAnswers: {},
        endTime: DateTime.now().add(Duration(minutes: settings.timeLimitInMinutes)), // [수정]
      );
      state = AsyncData(session); // 퀴즈 생성 완료
    } catch (e, stack) {
      state = AsyncError(e, stack); // 퀴즈 생성 실패
    }
  }

  // 2. 다음 문제로 (QuizScreen에서 호출)
  void nextQuestion(void Function(QuizSession) onQuizFinished) {
    state.whenData((session) {
      if (session != null && session.currentIndex < session.questions.length - 1) {
        state = AsyncData(session.copyWith(currentIndex: session.currentIndex + 1));
      } else {
        // 퀴즈 종료: 콜백을 호출하여 결과 화면으로 네비게이션
        onQuizFinished(session!);
      }
    });
  }

  // 3. 사용자 답안 저장 (QuizScreen에서 호출)
  void submitAnswer(String questionId, String answer) {
     state.whenData((session) {
      if (session != null) {
        final newAnswers = Map<String, String>.from(session.userAnswers);
        newAnswers[questionId] = answer;
        state = AsyncData(session.copyWith(userAnswers: newAnswers));
      }
    });
  }

  // 4. 퀴즈 종료 (결과 화면 네비게이션용)
  void endQuiz() {
     state = const AsyncData(null); // 퀴즈 세션 초기화
  }
}

final quizControllerProvider =
    StateNotifierProvider<QuizController, AsyncValue<QuizSession?>>((ref) {
  return QuizController(ref);
});

// [신규] 남은 시간을 1초마다 알려주는 StreamProvider
final quizTimerProvider = StreamProvider<Duration>((ref) {
  // quizControllerProvider의 상태를 감시
  final quizSession = ref.watch(quizControllerProvider).asData?.value;

  if (quizSession == null) {
    return Stream.value(Duration.zero); // 퀴즈가 없으면 0초
  }

  // 1초마다 현재 시간과 종료 시간의 차이를 계산하여 방출
  return Stream.periodic(const Duration(seconds: 1), (computationCount) {
    final remaining = quizSession.endTime.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  });
});