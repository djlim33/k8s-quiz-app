// lib/providers/cka_repository.dart (수정본)

import 'dart:convert'; // [오류 수정] dart.convert -> dart:convert
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/cka_data.dart'; 
import '../models/cka_question.dart';

// 1. Gemini API와 통신하는 실제 Repository 클래스
class CkaRepository {
  final GenerativeModel? _model;
  final bool _isMockMode;

  // 생성자에서 API 키를 사용하여 Gemini 모델을 초기화합니다.
  CkaRepository()
      : _isMockMode = dotenv.env['APP_MODE'] == 'mock',
        _model = dotenv.env['APP_MODE'] != 'mock'
            ? GenerativeModel( // 'gemini-pro'는 가장 안정적이고 널리 지원되는 표준 모델입니다.
                model: 'gemini-2.5-flash',
                apiKey: dotenv.env['GEMINI_API_KEY']!,
                // 안전 설정을 조정하여 부적절한 콘텐츠 생성을 방지합니다.
                safetySettings: [
                    SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none)
                  ])
            : null;
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

  // 💥 실제 Gemini API 호출 💥
  Future<List<CkaQuestion>> generateQuiz(QuizSetupSettings settings) async {
    // APP_MODE에 따라 분기
    if (_isMockMode) {
      print("--- [Running in MOCK mode] ---");
      return _generateMockQuiz(settings);
    } else {
      print("--- [Running in LIVE mode] ---");
      return _generateLiveQuiz(settings);
    }
  }

  // Live 모드: Gemini API를 호출하여 퀴즈 생성
  Future<List<CkaQuestion>> _generateLiveQuiz(QuizSetupSettings settings) async {
    // 1. Gemini에게 보낼 프롬프트 생성
    final prompt = """
      You are a CKA (Certified Kubernetes Administrator) exam simulator.
      Generate ${settings.questionCount} questions for the following topics: ${settings.topicIds.join(', ')}.
      The quiz type should be: ${settings.quizType}.
      The response MUST be a valid JSON list of objects. Do not include any text outside of the JSON list. 
      Each object in the JSON list must strictly follow this format, including Korean translations for 'task' and 'explanation':
      [
        {
          "id": "A unique identifier for the question",
          "topicId": "The topic id from the request, e.g., 'pods'",
          "context": "The context for the question, e.g., 'kubectl config use-context k8s-cluster-1'",
          "task": "The specific task for the user to complete in English.",
          "task_ko": "The specific task for the user to complete in Korean.",
          "solutionCommands": ["An array of strings with the imperative command(s) to solve the task."],
          "solutionYaml": "A string containing the full declarative YAML solution. Use '\\n' for newlines.",
          "explanation": "A detailed explanation of the solution and related concepts in English.",
          "explanation_ko": "A detailed explanation of the solution and related concepts in Korean."
        }
      ]
    """;

    try {
      // 2. Gemini API 호출
      final content = [Content.text(prompt)];
      // _model이 null이 아님을 보장 (live 모드이므로)
      final response = await _model!.generateContent(content);

      // 3. 응답 텍스트에서 JSON 부분만 추출
      // Gemini가 응답에 ```json ... ``` 같은 마크다운을 포함할 수 있으므로, 순수 JSON만 파싱합니다.
      final responseText = response.text ?? '';
      final jsonRegex = RegExp(r'```json\s*([\s\S]*?)\s*```|([\s\S]*)');
      final match = jsonRegex.firstMatch(responseText);
      final jsonString = (match?.group(1) ?? match?.group(2) ?? '').trim();

      if (jsonString.isEmpty) {
        throw Exception('Failed to parse JSON from Gemini response. Response was empty or invalid.');
      }

      // 4. JSON 파싱 및 객체 변환
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final questions = jsonList.map((json) => CkaQuestion.fromJson(json)).toList();
      return questions;
    } on GenerativeAIException catch (e) {
      // API 키, 권한, 모델 이름 등 API 관련 특정 오류를 잡습니다.
      print('--- [GEMINI API EXCEPTION] ---');
      print('A specific API error occurred: ${e.message}');
      print('------------------------------');
      // UI에서 에러 메시지를 표시할 수 있도록 예외를 다시 던집니다.
      rethrow;
    } on Exception catch (e) {
      // 네트워크, JSON 파싱 등 일반적인 예외를 잡습니다.
      print('--- [GEMINI GENERAL ERROR] ---');
      print('An error occurred while generating the quiz: $e');
      print('------------------------------');
      rethrow;
    }
  }

  // Mock 모드: 하드코딩된 Mock 데이터를 반환
  Future<List<CkaQuestion>> _generateMockQuiz(QuizSetupSettings settings) async {
    await Future.delayed(const Duration(seconds: 1)); // API 호출 시뮬레이션
    const mockJsonResponse = '''
    [
      {
        "id": "q-mock-123",
        "topicId": "pods",
        "context": "kubectl config use-context mock-cluster",
        "task": "[MOCK] Create a new Pod named 'mock-pod' using the 'busybox' image.",
        "task_ko": "[MOCK] 'busybox' 이미지를 사용하여 'mock-pod'라는 새 파드를 생성하세요.",
        "solutionCommands": ["kubectl run mock-pod --image=busybox"],
        "solutionYaml": "apiVersion: v1\\nkind: Pod\\nmetadata:\\n  name: mock-pod\\nspec:\\n  containers:\\n  - name: busybox\\n    image: busybox",
        "explanation": "This is a mock question for testing purposes. The `kubectl run` command is used to quickly create a pod.",
        "explanation_ko": "이것은 테스트 목적의 모의 문제입니다. `kubectl run` 명령어는 파드를 빠르게 생성할 때 사용됩니다."
      },
      {
        "id": "q-mock-456",
        "topicId": "services",
        "context": "kubectl config use-context mock-cluster",
        "task": "[MOCK] Expose the deployment 'mock-deploy' as a NodePort service on port 80.",
        "task_ko": "[MOCK] 'mock-deploy' 디플로이먼트를 80번 포트의 NodePort 서비스로 노출하세요.",
        "solutionCommands": ["kubectl expose deployment mock-deploy --type=NodePort --port=80"],
        "solutionYaml": "apiVersion: v1\\nkind: Service\\n...",
        "explanation": "This is another mock question. Use `kubectl expose` to create a service from a deployment.",
        "explanation_ko": "이것은 또 다른 모의 문제입니다. `kubectl expose`를 사용하여 디플로이먼트로부터 서비스를 생성할 수 있습니다."
      }
    ]
    ''';
    final List<dynamic> jsonList = jsonDecode(mockJsonResponse);
    return jsonList.map((json) => CkaQuestion.fromJson(json)).take(settings.questionCount).toList();
  }
}

// --- Provider 정의 (MockCkaRepository -> CkaRepository) ---
final ckaRepositoryProvider = Provider<CkaRepository>((ref) {
  return CkaRepository();
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