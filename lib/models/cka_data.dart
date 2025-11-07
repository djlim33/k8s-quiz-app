// 1. 메인 화면: 전체 진행도
class OverallProgress {
  final double progressPercent; // 0.0 ~ 1.0
  final double accuracyPercent; // 0.0 ~ 1.0

  OverallProgress({required this.progressPercent, required this.accuracyPercent});
}

// 2. 메인 화면: 주제별 진행도
class TopicSummary {
  final String id;
  final String name;
  final String icon;
  final double progressPercent;

  TopicSummary({
    required this.id,
    required this.name,
    required this.icon,
    required this.progressPercent,
  });
}

// 3. 메인 화면: 최근 응시 목록
class RecentExamSummary {
  final String id;
  final String title;
  final bool isCompleted;
  final double? score; // 완료된 경우에만 점수
  final String status; // 예: "85/100점 - 완료", "5/10 문제 - 진행 중"

  RecentExamSummary({
    required this.id,
    required this.title,
    required this.isCompleted,
    this.score,
    required this.status,
  });
}

// TODO: 2단계에서 사용할 문제/해설 모델들
// class CkaQuestion { ... }
// class CkaTopic { ... }

// 5. 메인 화면: 쿠버네티스 기본 개념
class BasicConceptSummary {
  final String id;
  final String title;
  final String description;

  BasicConceptSummary({
    required this.id,
    required this.title,
    required this.description,
  });
}

// 4. 개념 학습 화면: 토픽별 상세 개념
class Concept {
  final String topicId;
  final String topicName;
  final String description;
  final String commandExample;
  final String yamlExample;

  Concept({
    required this.topicId,
    required this.topicName,
    required this.description,
    required this.commandExample,
    required this.yamlExample,
  });
}

// 6. 메인 화면: 주차별 기본 개념
class WeeklyConceptSummary {
  final String id; // 예: 'week1'
  final String title; // 예: 'Week 1'
  final String description; // 예: 'Pod, Service의 기본 개념을 학습합니다.'

  WeeklyConceptSummary({
    required this.id,
    required this.title,
    required this.description,
  });
}