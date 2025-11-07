// lib/screens/main_screen.dart (수정본)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cka_data.dart';
// [오류 수정] main_data_provider.dart -> cka_repository.dart
import '../providers/cka_repository.dart'; 

// 1. StatelessWidget -> ConsumerWidget으로 변경
class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  // 2. build 메서드에 'WidgetRef ref' 추가
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 3. Provider를 'watch'하여 데이터 스트림을 구독
    // [오류 수정] 이제 overallProgressProvider 등이 정상적으로 인식됩니다.
    final progressAsync = ref.watch(overallProgressProvider);
    final topicsAsync = ref.watch(topicSummariesProvider);
    final examsAsync = ref.watch(recentExamsProvider);
    final weeklyConceptsAsync = ref.watch(weeklyConceptsProvider); // [신규]

    return Scaffold(
      appBar: AppBar(
        title: const Text('CKA 실기 마스터'),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: RefreshIndicator(
        // 4. 화면을 당겨서 새로고침하는 기능 추가
        onRefresh: () async {
          // 모든 Provider를 무효화(refresh)하여 다시 호출
          ref.invalidate(overallProgressProvider);
          ref.invalidate(topicSummariesProvider);
          ref.invalidate(recentExamsProvider);
          ref.invalidate(weeklyConceptsProvider); // [신규]
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(), // 스크롤을 위해
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 나의 CKA 합격 현황 카드
              // 5. AsyncValue의 when을 사용하여 로딩/에러/데이터 처리
              progressAsync.when(
                data: (progress) => _buildProgressCard(context, progress),
                loading: () => const _LoadingCard(height: 150),
                error: (err, stack) => _ErrorCard(message: err.toString()),
              ),

              // 2. 주제별 심화 학습 (가로 스크롤)
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 10),
                child: Text(
                  '주제별 심화 학습',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              topicsAsync.when(
                data: (topics) => _buildTopicSection(context, topics),
                loading: () => const _LoadingCard(height: 120),
                error: (err, stack) => _ErrorCard(message: err.toString()),
              ),

              // [신규] 주차별 기본 개념
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 10),
                child: Text(
                  '주차별 기본 개념',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              weeklyConceptsAsync.when(
                data: (concepts) => _buildWeeklyConceptsSection(context, concepts),
                loading: () => const _LoadingCard(height: 150),
                error: (err, stack) => _ErrorCard(message: err.toString()),
              ),

              // 3. 최근 생성한 모의고사 (세로 리스트)
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 10),
                child: Text(
                  '최근 모의고사',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              examsAsync.when(
                data: (exams) => _buildRecentExamsSection(context, exams),
                loading: () => const _LoadingCard(height: 200),
                error: (err, stack) => _ErrorCard(message: err.toString()),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/setup');
        },
        child: const Icon(Icons.add),
        tooltip: '문제 생성',
      ),
    );
  }
  
  // --- [이하 헬퍼 위젯들은 변경 사항 없음] ---

  // 1. 합격 현황 카드 (데이터 주입)
  Widget _buildProgressCard(BuildContext context, OverallProgress progress) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '나의 CKA 자격증 준비',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress.progressPercent, // *데이터 사용*
              minHeight: 10,
              borderRadius: const BorderRadius.all(Radius.circular(5)),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('전체 진행도: ${(progress.progressPercent * 100).toInt()}%'), // *데이터 사용*
                Text(
                  '정답률: ${(progress.accuracyPercent * 100).toInt()}%', // *데이터 사용*
                  style: TextStyle(color: Colors.green.shade300),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 2. 주제별 심화 학습 섹션 (데이터 주입)
  Widget _buildTopicSection(BuildContext context, List<TopicSummary> topics) {
    return SizedBox(
      height: 120, // 가로 스크롤 영역 높이
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: topics.length, // *데이터 사용*
        itemBuilder: (context, index) {
          final topic = topics[index]; // *데이터 사용*
          return _buildTopicCard(
            topic.icon,
            topic.name,
            topic.progressPercent,
          );
        },
      ),
    );
  }

  // 주제별 카드 위젯 (변경 없음, 데이터는 위에서 주입)
  Widget _buildTopicCard(String icon, String title, double progress) {
    return SizedBox(
      width: 150,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                borderRadius: const BorderRadius.all(Radius.circular(3)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 3. 최근 생성한 모의고사 섹션 (데이터 주입)
  Widget _buildRecentExamsSection(
      BuildContext context, List<RecentExamSummary> exams) {
    return ListView.builder(
      shrinkWrap: true, // SingleChildScrollView 안의 ListView
      physics: const NeverScrollableScrollPhysics(), // 부모 스크롤 사용
      itemCount: exams.length,
      itemBuilder: (context, index) {
        final exam = exams[index]; // *데이터 사용*
        return ListTile(
          leading: Icon(
            exam.isCompleted // *데이터 사용*
                ? Icons.check_circle_outline
                : Icons.pending_outlined,
            color: exam.isCompleted ? Colors.green : Colors.yellow,
          ),
          title: Text(exam.title), // *데이터 사용*
          subtitle: Text(exam.status), // *데이터 사용*
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            // *로직 분기*
            if (exam.isCompleted) {
              Navigator.pushNamed(context, '/result', arguments: exam.id);
            } else {
              Navigator.pushNamed(context, '/quiz', arguments: exam.id);
            }
          },
        );
      },
    );
  }

  // [신규] 주차별 기본 개념 섹션
  Widget _buildWeeklyConceptsSection(
      BuildContext context, List<WeeklyConceptSummary> concepts) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: concepts.length,
      itemBuilder: (context, index) {
        final concept = concepts[index];
        return ListTile(
          leading: CircleAvatar(child: Text('${index + 1}')),
          title: Text(concept.title),
          subtitle: Text(concept.description),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            // 주차별 개념 목록 화면으로 이동
            Navigator.pushNamed(context, '/concept-list', arguments: concept);
          },
        );
      },
    );
  }
}

// --- 로딩 및 에러 처리를 위한 공용 위젯 ---

class _LoadingCard extends StatelessWidget {
  final double height;
  const _LoadingCard({required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: const Card(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.shade900,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('오류가 발생했습니다: $message'),
        ),
      ),
    );
  }
}