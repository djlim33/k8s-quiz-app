import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cka_question.dart';
import '../providers/cka_repository.dart';
import '../providers/setup_provider.dart';
import '../providers/quiz_controller.dart';
import 'package:collection/collection.dart'; // groupBy 사용을 위해 pub add collection

// 1. ConsumerWidget으로 변경
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  bool _isGenerating = false; // 퀴즈 생성 중 로딩 상태

  // 퀴즈 생성 시작
  Future<void> _startQuiz() async {
    setState(() { _isGenerating = true; });

    final settings = ref.read(setupProvider);
    
    // 퀴즈 컨트롤러의 generateQuiz 호출
    await ref.read(quizControllerProvider.notifier).generateQuiz(settings);

    setState(() { _isGenerating = false; });

    // 퀴즈 생성 후 상태 확인
    final quizState = ref.read(quizControllerProvider);
    if (quizState is AsyncData && quizState.value != null) {
      // 성공: 퀴즈 화면으로 이동
      Navigator.popAndPushNamed(context, '/quiz');
    } else if (quizState is AsyncError) {
      // 실패: 에러 스낵바 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('퀴즈 생성 실패: ${quizState.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 2. Provider watch
    final setupState = ref.watch(setupProvider);
    final topicsAsync = ref.watch(availableTopicsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🎯 주제별 집중 학습'),
      ),
      body: topicsAsync.when(
        data: (topics) => _buildSetupForm(context, topics, setupState),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('토픽 로드 실패: $e')),
      ),
      // 하단 고정 CTA 버튼
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          // 3. 퀴즈 생성 버튼 로직
          onPressed: _isGenerating ? null : _startQuiz,
          child: _isGenerating
              ? const CircularProgressIndicator()
              : Text('${setupState.questionCount}문제 학습 시작하기'),
        ),
      ),
    );
  }

  Widget _buildSetupForm(BuildContext context, List<CkaTopic> topics, QuizSetupSettings setupState) {
    // CKA 토픽을 부모별로 그룹화
    final topicsByParent = groupBy(topics, (topic) => topic.parentName);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. CKA 출제 범위 선택 (동적 생성)
          const Text(
            '심도 있게 학습할 주제를 선택하세요.',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ...topicsByParent.entries.map((entry) {
            final parentName = entry.key;
            final subTopics = entry.value;
            return ExpansionTile(
              title: Text(parentName),
              controlAffinity: ListTileControlAffinity.leading,
              children: subTopics.map((topic) {
                return CheckboxListTile(
                  title: Text(topic.name),
                  // 4. setupProvider의 상태와 연동
                  value: setupState.topicIds.contains(topic.id),
                  onChanged: (val) {
                    // 5. setupProvider의 메서드 호출
                    ref.read(setupProvider.notifier).toggleTopic(topic.id);
                  },
                );
              }).toList(),
            );
          }),

          const SizedBox(height: 24),

          // 2. 학습 방법 설정 (동적 연동)
          const Text(
            '문제 수',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 10, label: Text('10개')),
              ButtonSegment(value: 20, label: Text('20개')),
              ButtonSegment(value: 30, label: Text('30개')),
            ],
            selected: {setupState.questionCount},
            onSelectionChanged: (val) {
              ref.read(setupProvider.notifier).setQuestionCount(val.first);
            },
          ),
          
          const SizedBox(height: 20),

          const Text(
            '문제 유형 (CKA 핵심)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'random', label: Text('🎲 전체 랜덤')),
              ButtonSegment(value: 'cmd', label: Text('🍃 기본 명령어')),
              ButtonSegment(value: 'yaml', label: Text('📜 YAML 생성')),
            ],
            selected: {setupState.quizType},
            onSelectionChanged: (val) {
              ref.read(setupProvider.notifier).setQuizType(val.first);
            },
          ),
          // ... (시간 제한 토글 등)
        ],
      ),
    );
  }
}