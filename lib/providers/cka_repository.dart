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

  // [수정] 특정 '하위' 토픽 ID에 대한 상세 개념 데이터
  Future<Concept> fetchConceptById(String topicId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final allConcepts = {
      'pods': Concept(
        topicId: 'pods',
        topicName: 'Pod의 이해',
        description: 'Pod는 쿠버네티스에서 생성하고 관리할 수 있는 배포 가능한 가장 작은 컴퓨팅 단위입니다. 하나 이상의 컨테이너 그룹을 나타내며, 이 컨테이너들은 스토리지와 네트워크를 공유하고 동일한 노드에서 함께 실행됩니다.\n\n'
            'CKA 시험의 모든 문제의 기초가 되는 가장 중요한 오브젝트입니다. Pod의 생명주기(Pending, Running, Succeeded, Failed, Unknown)를 이해하고, 상태를 확인하며 문제를 진단하는 능력이 필수적입니다.',
        commandExample: '# nginx 이미지를 사용하는 \'my-pod\' Pod 생성\n'
            'kubectl run my-pod --image=nginx\n\n'
            '# 생성된 Pod 목록 확인\n'
            'kubectl get pods -o wide\n\n'
            '# Pod의 상세 정보 확인 (이벤트 확인에 필수)\n'
            'kubectl describe pod my-pod\n\n'
            '# Pod의 로그 확인 (-f 플래그로 실시간 로그 추적)\n'
            'kubectl logs my-pod -f\n\n'
            '# 실행 중인 Pod의 컨테이너에 접속\n'
            'kubectl exec -it my-pod -- /bin/sh\n\n'
            '# Pod 삭제\n'
            'kubectl delete pod my-pod',
        yamlExample: 'apiVersion: v1\n'
            'kind: Pod\n'
            'metadata:\n'
            '  name: my-pod\n'
            '  labels:\n'
            '    app: my-app\n'
            'spec:\n'
            '  containers:\n'
            '  - name: nginx-container\n'
            '    image: nginx:latest\n'
            '    ports:\n'
            '    - containerPort: 80\n'
            '  restartPolicy: Always # Always, OnFailure, Never',
      ),
      'services': Concept(
        topicId: 'services',
        topicName: 'Service의 역할',
        description: 'Service는 변동성이 큰 Pod의 IP 주소 대신, 안정적인 단일 엔드포인트(IP 주소와 DNS 이름)를 통해 Pod 집합에 접근할 수 있도록 해주는 추상화 계층입니다. Service는 `selector`를 사용하여 어떤 레이블을 가진 Pod들을 그룹으로 묶을지 결정합니다.\n\n'
            '주요 타입:\n'
            '- **ClusterIP (기본값)**: 클러스터 내부에서만 접근 가능한 가상 IP를 할당합니다. 다른 서비스와의 통신에 사용됩니다.\n'
            '- **NodePort**: 모든 노드의 특정 포트를 통해 외부에서 서비스에 접근할 수 있게 합니다. 테스트나 간단한 노출에 유용합니다.\n'
            '- **LoadBalancer**: 클라우드 제공업체(GCP, AWS 등)의 외부 로드 밸런서를 프로비저닝하여 서비스를 외부에 노출합니다.',
        commandExample: '# "app=my-app" 레이블을 가진 Deployment를 NodePort 타입으로 노출\n'
            'kubectl expose deployment my-app-deploy --port=80 --target-port=8080 --type=NodePort\n\n'
            '# 생성된 Service 목록 확인\n'
            'kubectl get svc # svc는 services의 단축어\n\n'
            '# Service의 상세 정보 및 엔드포인트(연결된 Pod IP) 확인\n'
            'kubectl describe service my-service',
        yamlExample: 'apiVersion: v1\n'
            'kind: Service\n'
            'metadata:\n'
            '  name: my-service\n'
            'spec:\n'
            '  selector:\n'
            '    app: my-app\n'
            '  ports:\n'
            '    - protocol: TCP\n'
            '      port: 80       # Service 자체의 포트\n'
            '      targetPort: 8080 # Pod 컨테이너가 리스닝하는 포트\n'
            '  type: NodePort',
      ),
      'namespace': Concept(
        topicId: 'namespace',
        topicName: 'Namespace 활용',
        description: 'Namespace는 단일 물리 클러스터를 여러 가상 클러스터로 분할하는 방법입니다. 이를 통해 여러 팀이나 프로젝트가 리소스를 격리하여 사용할 수 있습니다.\n\n'
            '주요 사용 목적:\n'
            '- **이름 범위(Scope)**: 다른 Namespace에 있다면 리소스 이름이 같아도 충돌하지 않습니다.\n'
            '- **접근 제어**: RBAC(Role-Based Access Control)을 통해 특정 Namespace에 대한 사용자 권한을 제한할 수 있습니다.\n'
            '- **리소스 할당량**: ResourceQuota를 사용하여 Namespace별로 사용할 수 있는 컴퓨팅 리소스(CPU, Memory)나 오브젝트 수(Pod, Service 개수)를 제한할 수 있습니다.',
        commandExample: '# "development" Namespace 생성\n'
            'kubectl create namespace development\n\n'
            '# "development" Namespace에 Pod 생성\n'
            'kubectl run my-pod --image=nginx -n development\n\n'
            '# 특정 Namespace의 Pod 목록 확인\n'
            'kubectl get pods --namespace development\n\n'
            '# 현재 컨텍스트의 기본 Namespace를 변경 (매우 유용!)\n'
            'kubectl config set-context --current --namespace=development',
        yamlExample: 'apiVersion: v1\n'
            'kind: Namespace\n'
            'metadata:\n'
            '  name: production',
      ),
      'deployment': Concept(
        topicId: 'deployment',
        topicName: 'Deployment 관리',
        description: 'Deployment는 Pod와 ReplicaSet에 대한 선언적 업데이트를 제공하는 핵심 컨트롤러입니다. 애플리케이션의 원하는 상태(예: 실행할 Pod의 수, 사용할 컨테이너 이미지)를 정의하면, Deployment 컨트롤러가 현재 상태를 원하는 상태와 일치하도록 변경합니다. 롤링 업데이트, 롤백, 배포 확장/축소 등의 기능은 반드시 숙지해야 합니다.',
        commandExample: '# 3개의 복제본을 가진 nginx Deployment 생성\n'
            'kubectl create deployment nginx-deploy --image=nginx --replicas=3\n\n'
            '# Deployment의 이미지 업데이트 (롤링 업데이트 트리거)\n'
            'kubectl set image deployment/nginx-deploy nginx=nginx:1.25.0\n\n'
            '# Deployment 롤백\n'
            'kubectl rollout undo deployment/nginx-deploy',
        yamlExample: 'apiVersion: apps/v1\n'
            'kind: Deployment\n'
            'metadata:\n'
            '  name: nginx-deployment\n'
            'spec:\n'
            '  replicas: 3\n'
            '  selector:\n'
            '    matchLabels:\n'
            '      app: nginx\n'
            '  template:\n'
            '    metadata:\n'
            '      labels:\n'
            '        app: nginx\n'
            '    spec:\n'
            '      containers:\n'
            '      - name: nginx\n'
            '        image: nginx:1.24.0\n'
            '        ports:\n'
            '        - containerPort: 80',
      ),
      'persistentvolume': Concept(
        topicId: 'persistentvolume',
        topicName: 'PersistentVolume (PV)과 PersistentVolumeClaim (PVC)',
        description: 'PV는 관리자가 프로비저닝한 클러스터의 스토리지 조각으로, Pod의 라이프사이클과 독립적으로 데이터를 영속적으로 저장합니다. PVC는 사용자가 PV에 요청하는 명세입니다. Pod는 PVC를 볼륨으로 마운트하여 사용하며, 쿠버네티스는 PVC의 요구사항(용량, 접근 모드)에 맞는 PV를 찾아 바인딩해줍니다. 이 분리된 구조는 스토리지 관리와 사용을 유연하게 만듭니다.',
        commandExample: '# PV와 PVC는 보통 YAML 파일로 생성합니다.\n'
            'kubectl apply -f my-pv.yaml\n'
            'kubectl apply -f my-pvc.yaml\n\n'
            '# PV 및 PVC 목록 확인\n'
            'kubectl get pv\n'
            'kubectl get pvc',
        yamlExample: '# PersistentVolume (PV) 예제\n'
            'apiVersion: v1\n'
            'kind: PersistentVolume\n'
            'metadata:\n'
            '  name: my-pv\n'
            'spec:\n'
            '  capacity:\n'
            '    storage: 5Gi\n'
            '  accessModes:\n'
            '    - ReadWriteOnce\n'
            '  hostPath:\n'
            '    path: "/mnt/data"\n\n'
            '---\n'
            '# PersistentVolumeClaim (PVC) 예제\n'
            'apiVersion: v1\n'
            'kind: PersistentVolumeClaim\n'
            'metadata:\n'
            '  name: my-pvc\n'
            'spec:\n'
            '  accessModes:\n'
            '    - ReadWriteOnce\n'
            '  resources:\n'
            '    requests:\n'
            '      storage: 2Gi',
      ),
      'ingress': Concept(
        topicId: 'ingress',
        topicName: 'Ingress 라우팅',
        description: 'Ingress는 클러스터 외부에서 내부 서비스로의 HTTP 및 HTTPS 경로를 관리하는 API 오브젝트입니다. URL 경로 또는 호스트 이름을 기반으로 트래픽을 다른 서비스로 라우팅하는 규칙을 정의할 수 있습니다. Ingress가 작동하려면 클러스터에 Ingress Controller(예: NGINX Ingress Controller, Traefik)가 먼저 실행되고 있어야 합니다.',
        commandExample: '# Ingress는 복잡한 규칙을 포함하므로 YAML로 정의하는 것이 일반적입니다.\n'
            'kubectl apply -f my-ingress.yaml\n\n'
            '# 생성된 Ingress 확인\n'
            'kubectl get ingress',
        yamlExample: 'apiVersion: networking.k8s.io/v1\n'
            'kind: Ingress\n'
            'metadata:\n'
            '  name: my-ingress\n'
            'spec:\n'
            '  rules:\n'
            '  - host: "example.com"\n'
            '    http:\n'
            '      paths:\n'
            '      - path: /app\n'
            '        pathType: Prefix\n'
            '        backend:\n'
            '          service:\n'
            '            name: my-app-service\n'
            '            port:\n'
            '              number: 80',
      ),
    };
    if (allConcepts.containsKey(topicId)) {
      return allConcepts[topicId]!;
    }
    throw Exception('Concept not found for id: $topicId');
  }

  // [수정] 메인 화면에 표시할 '주차별' 기본 개념 목록
  Future<List<WeeklyConceptSummary>> getWeeklyConcepts() async {
    await Future.delayed(const Duration(milliseconds: 350));
    return [
      WeeklyConceptSummary(
        id: 'week1',
        title: '1주차: 핵심 오브젝트',
        description: 'Pod, Service, Namespace 등 쿠버네티스의 기본 구성 요소를 학습합니다.',
      ),
      WeeklyConceptSummary(
        id: 'week2',
        title: '2주차: 워크로드와 컨트롤러',
        description: 'Deployment, ReplicaSet, DaemonSet 등 애플리케이션 배포 및 관리를 학습합니다.',
      ),
      WeeklyConceptSummary(
        id: 'week3',
        title: '3주차: 스토리지와 설정',
        description: 'PV, PVC, ConfigMap, Secret 등 데이터 영속성과 설정을 관리하는 방법을 학습합니다.',
      ),
      WeeklyConceptSummary(
        id: 'week4',
        title: '4주차: 네트워킹과 보안',
        description: 'Ingress, NetworkPolicy, RBAC 등 서비스 노출과 접근 제어를 학습합니다.',
      ),
      WeeklyConceptSummary(
        id: 'week5',
        title: '5주차: 클러스터 관리와 트러블슈팅',
        description: '노드 관리, 클러스터 업그레이드, 문제 해결 기법을 학습합니다.',
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
          title: 'Pod의 이해',
          description: '쿠버네티스 배포의 가장 작은 단위입니다.',
        ),
        BasicConceptSummary(
          id: 'services',
          title: 'Service의 역할과 종류',
          description: 'Pod 집합에 접근할 수 있는 안정적인 엔드포인트를 제공합니다.',
        ),
        BasicConceptSummary(
          id: 'namespace',
          title: 'Namespace를 이용한 리소스 격리',
          description: '클러스터 내의 리소스를 논리적으로 그룹화하고 격리합니다.',
        ),
      ];
    } else if (weekId == 'week2') {
      return [
        BasicConceptSummary(
          id: 'deployment',
          title: 'Deployment를 이용한 배포 관리',
          description: '애플리케이션의 롤링 업데이트와 롤백을 관리합니다.',
        ),
      ];
    } else if (weekId == 'week3') {
      return [
        BasicConceptSummary(
          id: 'persistentvolume',
          title: 'PersistentVolume & PersistentVolumeClaim',
          description: 'Pod의 생명주기와 무관하게 데이터를 영속적으로 저장합니다.',
        ),
      ];
    } else if (weekId == 'week4') {
      return [
        BasicConceptSummary(
          id: 'ingress',
          title: 'Ingress를 이용한 외부 트래픽 라우팅',
          description: 'HTTP/HTTPS 트래픽을 클러스터 내부 서비스로 연결합니다.',
        ),
      ];
    } else if (weekId == 'week5') {
      return [
        BasicConceptSummary(
          id: 'troubleshooting',
          title: '기본 트러블슈팅',
          description: 'logs, describe, exec 명령어를 사용한 문제 해결 방법을 학습합니다.',
        ),
      ];
    }
    // 다른 주차에 대한 데이터 (현재는 비어 있음)
    return [];
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

// [신규] 특정 개념의 상세 정보를 가져오는 Provider
final conceptDetailProvider =
    FutureProvider.family<Concept, String>((ref, topicId) {
  return ref.watch(ckaRepositoryProvider).fetchConceptById(topicId);
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