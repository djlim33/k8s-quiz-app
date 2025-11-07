// lib/providers/cka_repository.dart (수정본)

import 'dart:convert'; // [오류 수정] dart.convert -> dart:convert
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cka_data.dart'; 
import '../models/cka_question.dart';

// 1. 가짜 데이터를 제공하는 Mock Repository 클래스
class MockCkaRepository {
  
  // --- [오류 수정] 기존 메서드 본체 복원 ---
  Future<OverallProgress> getOverallProgress() async {
    // 1초 지연 (네트워크 호출 시뮬레이션)
    await Future.delayed(const Duration(milliseconds: 300));
    return OverallProgress(progressPercent: 0.75, accuracyPercent: 0.82);
  }

  Future<List<TopicSummary>> getTopicSummaries() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return [
      TopicSummary(id: 'workloads', name: 'Workloads', icon: '📦', progressPercent: 0.8),
      TopicSummary(id: 'services', name: 'Services', icon: '🌐', progressPercent: 0.6),
      TopicSummary(id: 'storage', name: 'Storage', icon: '💾', progressPercent: 0.7),
      TopicSummary(id: 'troubleshooting', name: 'Trouble', icon: '🔧', progressPercent: 0.5),
    ];
  }

  Future<List<RecentExamSummary>> getRecentExamSummaries() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return [
      RecentExamSummary(
        id: 'exam1',
        title: '실전 모의고사 1 (120분)',
        isCompleted: true,
        score: 85.0,
        status: '85/100점 - 완료',
      ),
      RecentExamSummary(
        id: 'exam2',
        title: 'Troubleshooting 집중 학습',
        isCompleted: false,
        score: null,
        status: '5/10 문제 - 진행 중',
      ),
      RecentExamSummary(
        id: 'exam3',
        title: 'Workloads 기출 변형 (30분)',
        isCompleted: true,
        score: 70.0,
        status: '70/100점 - 완료',
      ),
    ];
  }

  // --- [신규 추가 코드] ---

  // SetupScreen에 표시할 전체 CKA 토픽 목록
  Future<List<CkaTopic>> getAvailableTopics() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      CkaTopic(id: 'pods', name: 'Pods (생성, 라이프사이클)', parentId: 'workloads', parentName: '📦 Workloads & Scheduling'),
      CkaTopic(id: 'deployments', name: 'Deployments (생성, 롤백)', parentId: 'workloads', parentName: '📦 Workloads & Scheduling'),
      CkaTopic(id: 'services', name: 'Services (NodePort, ClusterIP)', parentId: 'networking', parentName: '🌐 Services & Networking'),
      CkaTopic(id: 'ingress', name: 'Ingress', parentId: 'networking', parentName: '🌐 Services & Networking'),
      CkaTopic(id: 'pv-pvc', name: 'PV & PVC', parentId: 'storage', parentName: '💾 Storage'),
      CkaTopic(id: 'app-debug', name: '애플리케이션 트러블슈팅', parentId: 'troubleshooting', parentName: '🔧 Troubleshooting'),
    ];
  }

  // 💥 Gemini API 호출 시뮬레이션 💥
  Future<List<CkaQuestion>> generateQuiz(QuizSetupSettings settings) async {
    // 1. Gemini에게 보낼 프롬프트 생성 (시뮬레이션)
    final prompt = """
      You are a CKA (Certified Kubernetes Administrator) exam simulator.
      Generate ${settings.questionCount} questions for the following topics: ${settings.topicIds.join(', ')}.
      The quiz type should be: ${settings.quizType}.
      Respond ONLY with a JSON list, matching this format:
      [
        {
          "id": "q1",
          "topicId": "pods",
          "context": "kubectl config use-context cluster-1",
          "task": "Create a new Pod named 'nginx-pod' using the 'nginx:1.21' image.",
          "solutionCommands": ["kubectl run nginx-pod --image=nginx:1.21"],
          "solutionYaml": "apiVersion: v1\\nkind: Pod\\n...",
          "explanation": "kubectl run is the fastest way to create a pod..."
        },
        ...
      ]
    """;
    
    print("--- [Gemini 프롬프트 (시뮬레이션)] ---");
    print(prompt);
    print("----------------------------------");

    // 2. Gemini API 응답 대기 (시뮬레이션)
    await Future.delayed(const Duration(seconds: 2)); // 2초 딜레이

    // 3. Gemini가 반환한 JSON 응답 (시뮬레이션)
    const mockJsonResponse = '''
    [
      {
        "id": "q-123",
        "topicId": "pods",
        "context": "kubectl config use-context cluster-1",
        "task": "Create a new Pod named 'nginx-pod' using the 'nginx:1.21' image in the 'dev' namespace.",
        "solutionCommands": ["kubectl run nginx-pod --image=nginx:1.21 -n dev"],
        "solutionYaml": "apiVersion: v1\\nkind: Pod\\nmetadata:\\n  name: nginx-pod\\n  namespace: dev\\nspec:\\n  containers:\\n  - name: nginx\\n    image: nginx:1.21",
        "explanation": "Use 'kubectl run' with the '-n' or '--namespace' flag to specify the namespace."
      },
      {
        "id": "q-456",
        "topicId": "services",
        "context": "kubectl config use-context cluster-2",
        "task": "Expose the 'my-deployment' (which has label 'app=web') as a NodePort service on port 80, targeting pod port 8080.",
        "solutionCommands": ["kubectl expose deployment my-deployment --type=NodePort --port=80 --target-port=8080"],
        "solutionYaml": "apiVersion: v1\\nkind: Service\\n...",
        "explanation": "Use 'kubectl expose' to quickly create a service. 'port' is the service port, 'target-port' is the container port."
      }
    ]
    ''';
    
    // 4. JSON 파싱
    final List<dynamic> jsonList = jsonDecode(mockJsonResponse);
    final questions = jsonList.map((json) => CkaQuestion.fromJson(json)).toList();
    
    // 설정에서 요청한 만큼만 반환 (시뮬레이션이므로 2개만 반환됨)
    return questions.take(settings.questionCount).toList();
  }

  // [수정] ConceptScreen에 표시할 특정 '상위' 토픽에 속한 '여러' 개념 데이터
  Future<List<Concept>> fetchConceptsByParentTopicId(String parentTopicId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // parentTopicId에 따라 다른 데이터를 반환합니다.
    // 여기서는 'workloads'에 대한 예시 데이터만 구현합니다.
    if (parentTopicId == 'workloads') {
      return [
        Concept(
          topicId: 'pods',
          topicName: 'Pod의 이해',
          description: 'Pod는 쿠버네티스에서 생성하고 관리할 수 있는 배포 가능한 가장 작은 컴퓨팅 단위입니다. 하나 이상의 컨테이너 그룹을 나타냅니다.',
          commandExample: '# nginx 이미지를 사용하는 \'my-pod\' Pod 생성\n'
              'kubectl run my-pod --image=nginx',
          yamlExample: 'apiVersion: v1\n'
              'kind: Pod\n'
              'metadata:\n'
              '  name: my-pod\n'
              'spec:\n'
              '  containers:\n'
              '  - name: nginx-container\n'
              '    image: nginx:latest',
        ),
        Concept(
          topicId: 'deployments',
          topicName: 'Deployment의 역할',
          description: 'Deployment는 Pod와 ReplicaSet에 대한 선언적 업데이트를 제공합니다. Deployment를 통해 Pod의 복제본 수를 관리하고, 롤링 업데이트 및 롤백을 수행할 수 있습니다.',
          commandExample: '# nginx Deployment 생성 (3개의 복제본)\n'
              'kubectl create deployment nginx-deployment --image=nginx --replicas=3',
          yamlExample: 'apiVersion: apps/v1\n'
              'kind: Deployment\n'
              'metadata:\n'
              '  name: nginx-deployment\n'
              '# ... (이하 생략)',
        ),
      ];
    }
    // 'workloads'가 아닌 다른 토픽은 빈 리스트 반환
    return [];
  }

  // [수정] 메인 화면에 표시할 '주차별' 기본 개념 목록
  Future<List<WeeklyConceptSummary>> getWeeklyConcepts() async {
    await Future.delayed(const Duration(milliseconds: 350));
    return [
      WeeklyConceptSummary(
        id: 'week1',
        title: 'Week 1',
        description: 'Pod, Service 등 핵심 오브젝트를 학습합니다.',
      ),
      WeeklyConceptSummary(
        id: 'week2',
        title: 'Week 2',
        description: 'Deployment, Ingress 등 컨트롤러를 학습합니다.',
      ),
    ];
  }

  // [신규] 특정 주차에 해당하는 개념 목록
  Future<List<BasicConceptSummary>> getConceptsForWeek(String weekId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // weekId에 따라 다른 데이터를 반환합니다.
    if (weekId == 'week1') {
      return [
        BasicConceptSummary(
          id: 'pods',
          title: 'Pod란 무엇인가?',
          description: '쿠버네티스 배포의 가장 작은 단위입니다.',
        ),
        BasicConceptSummary(
          id: 'services',
          title: 'Service의 역할',
          description: 'Pod 집합에 접근할 수 있는 안정적인 엔드포인트를 제공합니다.',
        ),
      ];
    }
    // 다른 주차에 대한 데이터 (현재는 비어 있음)
    return [];
  }
}

// --- Provider 정의 (변경 없음) ---
final ckaRepositoryProvider = Provider<MockCkaRepository>((ref) {
  return MockCkaRepository();
});

final overallProgressProvider = FutureProvider<OverallProgress>((ref) {
  final repository = ref.watch(ckaRepositoryProvider);
  return repository.getOverallProgress();
});

final topicSummariesProvider = FutureProvider<List<TopicSummary>>((ref) {
  final repository = ref.watch(ckaRepositoryProvider);
  return repository.getTopicSummaries();
});

final recentExamsProvider = FutureProvider<List<RecentExamSummary>>((ref) {
  final repository = ref.watch(ckaRepositoryProvider);
  return repository.getRecentExamSummaries();
});

// SetupScreen에 표시할 토픽 목록 Provider
final availableTopicsProvider = FutureProvider<List<CkaTopic>>((ref) {
  return ref.watch(ckaRepositoryProvider).getAvailableTopics();
});

// [수정] 메인 화면에 표시할 '주차별' 기본 개념 목록 Provider
final weeklyConceptsProvider = FutureProvider<List<WeeklyConceptSummary>>((ref) {
  return ref.watch(ckaRepositoryProvider).getWeeklyConcepts();
});

// [신규] 특정 주차의 개념 목록을 가져오는 Provider
final conceptsForWeekProvider =
    FutureProvider.family<List<BasicConceptSummary>, String>((ref, weekId) {
  return ref.watch(ckaRepositoryProvider).getConceptsForWeek(weekId);
});