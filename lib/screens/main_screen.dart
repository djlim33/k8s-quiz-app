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
    final weeklyConceptsAsync = ref.watch(weeklyConceptsProvider); // [수정] Provider 변경

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
          ref.invalidate(weeklyConceptsProvider); // [수정] Provider 새로고침
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(), // 스크롤을 위해
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 나의 CKA 합격 현황 카드
              // 5. AsyncValue의 when을 사용하여 로딩/에러/데이터 처리
              progressAsync.when(
                data: (progress) => _buildProgressCard(context, progress), // [수정]
                loading: () => _LoadingCard(height: 150), // [수정] const 제거
                error: (err, stack) => _ErrorCard(message: err.toString()), // [수정] const 제거
              ),

              // [순서 변경] 쿠버네티스 기본 개념 이해
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 10),
                child: Text(
                  '쿠버네티스 기본 개념 이해',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              weeklyConceptsAsync.when(
                data: (weeklyConcepts) =>
                    _buildWeeklyConceptsSection(context, weeklyConcepts),
                loading: () => _LoadingCard(height: 180), // [수정] const 제거
                error: (err, stack) => _ErrorCard(message: err.toString()), // [수정] const 제거
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
                data: (topics) => _buildTopicSection(context, topics), // [수정]
                loading: () => _LoadingCard(height: 120), // [수정] const 제거
                error: (err, stack) => _ErrorCard(message: err.toString()), // [수정] const 제거
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
                data: (exams) => _buildRecentExamsSection(context, exams), // [수정]
                loading: () => _LoadingCard(height: 200), // [수정] const 제거
                error: (err, stack) => _ErrorCard(message: err.toString()), // [수정] const 제거
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
                  '정답률: ${(progress.accuracyPercent * 100).toInt()}%', 
                  style: TextStyle(color: Colors.green.shade600), // [수정] 밝은 테마에 맞는 색상
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
            context, // context 전달
            topic.icon,
            topic.name,
            topic.progressPercent,
            topic.id, // topicId 전달
          );
        },
      ),
    );
  }

  // 주제별 카드 위젯 (onTap 추가)
  Widget _buildTopicCard(BuildContext context, String icon, String title, double progress, String topicId) {
    return SizedBox(
      width: 150,
      child: Card(
        clipBehavior: Clip.antiAlias, // InkWell의 Ripple 효과가 보이도록
        child: InkWell(
          onTap: () {
            // 개념 학습 화면으로 이동
            Navigator.pushNamed(context, '/concept', arguments: topicId);
          },
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
        final exam = exams[index];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            leading: Icon(
              exam.isCompleted
                  ? Icons.check_circle_outline
                  : Icons.pending_outlined,
              color: exam.isCompleted
                  ? Colors.green.shade600
                  : Colors.orange.shade600,
            ),
            title: Text(exam.title),
            subtitle: Text(exam.status),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              if (exam.isCompleted) {
                Navigator.pushNamed(context, '/result', arguments: exam.id);
              } else {
                Navigator.pushNamed(context, '/quiz', arguments: exam.id);
              }
            },
          ),
        );
      },
    );
  }

  // [수정] 주차별 기본 개념 섹션
  Widget _buildWeeklyConceptsSection(
      BuildContext context, List<WeeklyConceptSummary> weeklyConcepts) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: weeklyConcepts.length,
      itemBuilder: (context, index) {
        final weeklyConcept = weeklyConcepts[index];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            leading: const Icon(Icons.school_outlined),
            title: Text(weeklyConcept.title),
            subtitle: Text(weeklyConcept.description),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.pushNamed(context, '/weekly-concepts',
                  arguments: weeklyConcept.id);
            },
          ),
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
      child: Card( // [수정]
        child: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
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
      color: Colors.red.shade100, // [수정]
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('오류가 발생했습니다: $message',
              style: TextStyle(color: Colors.red.shade900)),
        ),
      ),
    );
  }
}