// 1. 퀴즈 생성 시 설정값
class QuizSetupSettings {
  final Set<String> topicIds; // 'pods', 'services' 등
  final int questionCount;
  final String quizType; // 'random', 'cmd', 'yaml'

  QuizSetupSettings({
    required this.topicIds,
    required this.questionCount,
    required this.quizType,
  });

  // 설정값 복사를 위한 helper
  QuizSetupSettings copyWith({
    Set<String>? topicIds,
    int? questionCount,
    String? quizType,
  }) {
    return QuizSetupSettings(
      topicIds: topicIds ?? this.topicIds,
      questionCount: questionCount ?? this.questionCount,
      quizType: quizType ?? this.quizType,
    );
  }
}

// 2. SetupScreen에 표시될 토픽 (하위 토픽 포함)
class CkaTopic {
  final String id;
  final String name;
  final String parentId; // 'workloads', 'services' 등
  final String parentName;

  CkaTopic({
    required this.id,
    required this.name,
    required this.parentId,
    required this.parentName,
  });
}

// 3. Gemini가 생성할 개별 문제 모델
class CkaQuestion {
  final String id;
  final String topicId;
  final String context; // 예: "Use context cluster-1"
  final String task; // 예: "Create a pod named..."
  final List<String> solutionCommands; // 모범 답안 (명령어)
  final String solutionYaml; // 모범 답안 (YAML)
  final String explanation; // 해설

  CkaQuestion({
    required this.id,
    required this.topicId,
    required this.context,
    required this.task,
    required this.solutionCommands,
    required this.solutionYaml,
    required this.explanation,
  });

  // Gemini가 반환할 JSON을 파싱하기 위한 팩토리 생성자
  factory CkaQuestion.fromJson(Map<String, dynamic> json) {
    return CkaQuestion(
      id: json['id'] ?? 'q-${DateTime.now().millisecondsSinceEpoch}',
      topicId: json['topicId'] as String,
      context: json['context'] as String,
      task: json['task'] as String,
      solutionCommands: List<String>.from(json['solutionCommands'] as List),
      solutionYaml: json['solutionYaml'] as String,
      explanation: json['explanation'] as String,
    );
  }
}

// 4. 생성된 퀴즈 세션 (현재 진행 상태 포함)
class QuizSession {
  final String id;
  final List<CkaQuestion> questions;
  final int currentIndex;
  final Map<String, String> userAnswers; // <QuestionID, UserAnswer>

  QuizSession({
    required this.id,
    required this.questions,
    this.currentIndex = 0,
    this.userAnswers = const {},
  });

  QuizSession copyWith({
    int? currentIndex,
    Map<String, String>? userAnswers,
  }) {
    return QuizSession(
      id: id,
      questions: questions,
      currentIndex: currentIndex ?? this.currentIndex,
      userAnswers: userAnswers ?? this.userAnswers,
    );
  }
}