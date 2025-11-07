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

// --- [신규] 개념 학습 관련 모델 ---

// 4. 메인 화면: 주차별 기본 개념 요약
class WeeklyConceptSummary {
  final String id; // 예: "week1"
  final String title; // 예: "Week 1"
  final String description; // 예: "Pod, Service 등 핵심 오브젝트를 학습합니다."

  WeeklyConceptSummary({
    required this.id,
    required this.title,
    required this.description,
  });
}

// 5. 주차별 화면: 기본 개념 목록 요약
class BasicConceptSummary {
  final String id; // 예: "pods"
  final String title; // 예: "Pod란 무엇인가?"
  final String description; // 예: "쿠버네티스 배포의 가장 작은 단위입니다."

  BasicConceptSummary({
    required this.id,
    required this.title,
    required this.description,
  });
}

// 6. 상세 개념 화면: 상세 설명 데이터
class Concept {
  final String topicId;
  final String topicName;
  final String description;
  final String commandExample;
  final String yamlExample;

  Concept(
      {required this.topicId, required this.topicName, required this.description, required this.commandExample, required this.yamlExample});
}