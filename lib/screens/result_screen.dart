import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cka_question.dart';

class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ModalRoute를 통해 전달받은 QuizSession 객체
    final session = ModalRoute.of(context)!.settings.arguments as QuizSession?;

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('결과')),
        body: const Center(child: Text('퀴즈 결과 데이터를 불러올 수 없습니다.')),
      );
    }

    // 채점 로직
    int correctCount = 0;
    for (var question in session.questions) {
      final userAnswer = session.userAnswers[question.id] ?? '';
      // 정답 판별: solutionCommands 중 하나라도 사용자 답안에 포함되면 정답으로 간주 (더 유연한 채점)
      if (question.solutionCommands.any((cmd) => userAnswer.contains(cmd))) {
        correctCount++;
      }
    }
    final totalQuestions = session.questions.length;
    final score = totalQuestions > 0 ? (correctCount / totalQuestions * 100).round() : 0;

    return Scaffold(
        appBar: AppBar(
          title: const Text('퀴즈 결과'),
          automaticallyImplyLeading: false, // 뒤로가기 버튼 제거
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.popUntil(context, ModalRoute.withName('/')),
            )
          ],
        ),
        body: ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: totalQuestions + 1, // +1 for the summary card
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildSummaryCard(score, correctCount, totalQuestions);
            }
            final question = session.questions[index - 1];
            final userAnswer = session.userAnswers[question.id] ?? '';
            final isCorrect = question.solutionCommands.any((cmd) => userAnswer.contains(cmd));

            return _buildResultItem(
              context: context,
              index: index,
              question: question,
              userAnswer: userAnswer,
              isCorrect: isCorrect,
            );
          },
        ));
  }

  // 전체 결과 요약 카드
  Widget _buildSummaryCard(int score, int correctCount, int totalQuestions) {
    return Card(
      color: const Color(0xFF282C34), // 어두운 코드 블록 배경색
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('종합 점수', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('$score', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: score > 70 ? Colors.green : Colors.orange)),
            const SizedBox(height: 10),
            Text('정답: $correctCount / $totalQuestions', style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  // 개별 문제 결과 위젯
  Widget _buildResultItem({
    required BuildContext context,
    required int index,
    required CkaQuestion question,
    required String userAnswer,
    required bool isCorrect,
  }) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '💡 핵심 해설 및 개념',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Pod는 쿠버네티스에서 가장 작은 배포 단위입니다. `kubectl run` 명령은...",
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 15),
            const Text(
              '관련 CKA 범위:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text('📦 Workloads (18%)'),
            const SizedBox(height: 15),
            const Text(
              '유용한 팁 (Dry Run):',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
              color: const Color(0xFF282C34),
              width: double.infinity,
              margin: const EdgeInsets.only(top: 5),
              child: Text(
                'kubectl run ... --dry-run=client -o yaml > pod.yaml',
                style: TextStyle(color: Colors.white, fontFamily: 'Courier'),
              ),
            ),
          ],
        ),
        title: Text('문제 $index: ${isCorrect ? "정답" : "오답"}', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(question.task_ko, overflow: TextOverflow.ellipsis),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0).copyWith(top: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('문제 지시사항'),
                Text(question.task_ko),
                Text(question.task, style: TextStyle(color: theme.textTheme.bodySmall?.color)),
                const Divider(height: 24),

                _buildSectionTitle('나의 답안'),
                Text(userAnswer.isNotEmpty ? userAnswer : '(미제출)', style: TextStyle(color: userAnswer.isNotEmpty ? null : Colors.grey)),
                const Divider(height: 24),

                _buildSectionTitle('모범 답안 (명령어)'),
                Container(
                  padding: const EdgeInsets.all(8),
                  color: theme.scaffoldBackgroundColor,
                  width: double.infinity,
                  child: Text(
                    question.solutionCommands.join('\n'),
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
                const SizedBox(height: 12),

                _buildSectionTitle('모범 답안 (YAML)'),
                 Container(
                  padding: const EdgeInsets.all(8),
                  color: theme.scaffoldBackgroundColor,
                  width: double.infinity,
                  child: Text(
                    question.solutionYaml,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
                const Divider(height: 24),

                _buildSectionTitle('핵심 해설'),
                Text(question.explanation_ko),
                const SizedBox(height: 8),
                Text(question.explanation, style: TextStyle(color: theme.textTheme.bodySmall?.color)),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }
}