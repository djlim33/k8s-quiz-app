import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/cka_repository.dart';

class WeeklyConceptsScreen extends ConsumerWidget {
  const WeeklyConceptsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ModalRoute를 통해 MainScreen에서 전달받은 weekId를 가져옵니다.
    final weekId = ModalRoute.of(context)!.settings.arguments as String;

    // weekId를 사용하여 해당 주의 개념 목록을 구독합니다.
    final conceptsAsync = ref.watch(conceptsForWeekProvider(weekId));

    return Scaffold(
      appBar: AppBar(
        // AppBar 제목을 동적으로 설정 (예: "Week 1")
        title: Text(weekId.toUpperCase()),
      ),
      body: conceptsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('개념 목록 로딩 실패: $err')),
        data: (concepts) {
          if (concepts.isEmpty) {
            return const Center(child: Text('이 주차에는 학습할 개념이 없습니다.'));
          }
          // 개념 목록을 리스트로 표시합니다.
          return ListView.builder(
            itemCount: concepts.length,
            itemBuilder: (context, index) {
              final concept = concepts[index];
              return Card(
                clipBehavior: Clip.antiAlias,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  leading: const Icon(Icons.article_outlined),
                  title: Text(concept.title),
                  subtitle: Text(concept.description),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // 상세 개념 학습 화면으로 이동합니다.
                    Navigator.pushNamed(context, '/concept', arguments: concept.id);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}