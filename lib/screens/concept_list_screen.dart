import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cka_data.dart';
import '../providers/cka_repository.dart';

class ConceptListScreen extends ConsumerWidget {
  const ConceptListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 이전 화면(MainScreen)에서 전달받은 WeeklyConceptSummary 객체
    final weeklyConcept = ModalRoute.of(context)!.settings.arguments as WeeklyConceptSummary;

    // weekId를 사용하여 해당 주차의 개념 목록을 가져옵니다.
    final conceptsAsync = ref.watch(conceptsForWeekProvider(weeklyConcept.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(weeklyConcept.title),
      ),
      body: conceptsAsync.when(
        data: (concepts) {
          if (concepts.isEmpty) {
            return const Center(child: Text('이 주차의 학습 개념이 아직 없습니다.'));
          }
          return ListView.builder(
            itemCount: concepts.length,
            itemBuilder: (context, index) {
              final concept = concepts[index];
              return ListTile(
                title: Text(concept.title),
                subtitle: Text(concept.description),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // 상세 개념 화면으로 이동
                  Navigator.pushNamed(context, '/concept', arguments: concept.id);
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('개념을 불러오는 중 오류가 발생했습니다: $e'),
          ),
        ),
      ),
    );
  }
}