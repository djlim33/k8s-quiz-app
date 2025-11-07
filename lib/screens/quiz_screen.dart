import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async'; // [신규]
import '../models/cka_question.dart';
import '../providers/quiz_controller.dart';

// 1. ConsumerWidget으로 변경
class QuizScreen extends ConsumerWidget {
  const QuizScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 2. 퀴즈 컨트롤러 상태를 watch
    final quizState = ref.watch(quizControllerProvider);

    return Scaffold(
      // 3. 비동기 상태(로딩, 에러, 데이터) 처리
      body: quizState.when(
        data: (session) {
          if (session == null || session.questions.isEmpty) {
            return _buildEmptyState(context, ref);
          }
          // 현재 문제 가져오기
          final question = session.questions[session.currentIndex];
          return _buildQuizUI(context, ref, session, question);
        },
        loading: () => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.blue))),
        error: (e, s) => Center(child: Text('퀴즈 로드 실패: $e')),
      ),
    );
  }

  // 퀴즈 UI
  Widget _buildQuizUI(BuildContext context, WidgetRef ref, QuizSession session, CkaQuestion question) {
    // 현재 문제에 대한 사용자 답안 가져오기
    final userAnswer = session.userAnswers[question.id] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text('문제 ${session.currentIndex + 1}/${session.questions.length}'),
        actions: [
          // [수정] 타이머 UI
          Consumer(
            builder: (context, ref, child) {
              // 타이머 Provider 구독
              final timerAsync = ref.watch(quizTimerProvider);

              // 시간이 다 되면 퀴즈 종료
              ref.listen<AsyncValue<Duration>>(quizTimerProvider, (previous, next) {
                if (next.value?.inSeconds == 0) {
                  ref.read(quizControllerProvider.notifier).endQuiz();
                  if (ModalRoute.of(context)?.isCurrent ?? false) {
                    Navigator.popAndPushNamed(context, '/result');
                  }
                }
              });

              return Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Text(
                    '남은 시간: ${timerAsync.when(data: (d) => _formatDuration(d), error: (e,s) => '오류', loading: () => '...')}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. 문제 지문 (동적 데이터)
          _buildProblemStatement(context, question),
          
          // 2. 가상 터미널 (동적 데이터)
          _buildMockTerminal(context, ref, question.id, userAnswer),
          
          // 3. 하단 버튼
          _buildControlButtons(context, ref, session),
        ],
      ),
    );
  }

  // 1. 문제 지문
  Widget _buildProblemStatement(BuildContext context, CkaQuestion question) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      height: MediaQuery.of(context).size.height * 0.3,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.context, // *데이터*
              style: const TextStyle(color: Colors.yellow, fontFamily: 'Courier'),
            ),
            const SizedBox(height: 10),
            const Text(
              'Task:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              question.task, // *데이터*
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  // 2. 가상 터미널
  Widget _buildMockTerminal(BuildContext context, WidgetRef ref, String questionId, String userAnswer) {
    // 4. TextEditingController를 사용하여 답안 관리
    final controller = TextEditingController(text: userAnswer);
    controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));

    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(16.0),
        padding: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade700),
        ),
        child: TextField(
          controller: controller,
          maxLines: null,
          expands: true,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Courier',
            fontSize: 16,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: '여기에 커맨드를 입력하세요...',
            hintStyle: TextStyle(color: Colors.grey),
          ),
          // 5. 텍스트가 변경될 때마다 답안 저장
          onChanged: (text) {
            ref.read(quizControllerProvider.notifier).submitAnswer(questionId, text);
          },
        ),
      ),
    );
  }

  // 3. 하단 버튼
  Widget _buildControlButtons(BuildContext context, WidgetRef ref, QuizSession session) {
    final bool isLastQuestion = session.currentIndex == session.questions.length - 1;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () { /* TODO: 치트시트 */ },
            child: const Text('kubectl 치트시트'),
          ),
          ElevatedButton(
            // 6. 퀴즈 컨트롤러 메서드 호출
            onPressed: () {
              if (isLastQuestion) {
                // TODO: 퀴즈 종료 및 결과 화면 이동
                ref.read(quizControllerProvider.notifier).endQuiz();
                Navigator.popAndPushNamed(context, '/result'); // (임시)
              } else {
                ref.read(quizControllerProvider.notifier).nextQuestion();
              }
            },
            child: Text(isLastQuestion ? '결과 보기' : '다음 문제로'),
          ),
        ],
      ),
    );
  }

  // 퀴즈 세션이 없을 때 (예: 퀴즈 종료 후)
  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('퀴즈 세션이 종료되었거나 없습니다.'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // 메인 화면으로 돌아가기
            },
            child: const Text('메인으로 돌아가기'),
          ),
        ],
      ),
    );
  }

  // Duration을 MM:SS 형태로 포맷하는 헬퍼 함수
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}