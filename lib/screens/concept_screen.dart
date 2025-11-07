import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cka_data.dart';
import '../providers/cka_repository.dart';

class ConceptScreen extends ConsumerStatefulWidget {
  const ConceptScreen({super.key});

  @override
  ConsumerState<ConceptScreen> createState() => _ConceptScreenState();
}

class _ConceptScreenState extends ConsumerState<ConceptScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page?.round() ?? 0;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // MainScreen에서 전달받은 상위 토픽 ID (예: 'workloads')
    final parentTopicId = ModalRoute.of(context)!.settings.arguments as String;
 
    // Provider를 사용하여 데이터 구독
    final conceptsAsync = ref.watch(conceptDetailProvider(parentTopicId));
 
    return Scaffold(
      appBar: AppBar(
        // [수정] 제목을 동적으로 표시
        title: conceptsAsync.when(
          // [수정] 페이지가 변경되어도 제목이 바뀌지 않도록 첫 번째 개념의 상위 토픽 이름을 표시합니다.
          // 'Pod의 이해' 대신 'Workloads & Scheduling'과 같은 상위 카테고리 이름이 들어가면 더 좋습니다.
          // 현재 데이터 구조상 상위 토픽 이름이 없으므로, 첫 페이지의 제목을 사용합니다.
          data: (concept) => Text(concept.topicName),
          loading: () => const Text(''),
          error: (e, s) => const Text('오류'),
        ),
      ),
      body: conceptsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('개념을 불러오는 중 오류 발생: $err')),
        data: (concept) {
          // [수정] PageView와 인디케이터를 포함하는 UI
          return Column(
            children: [
              Expanded(
                child: _ConceptPage(concept: concept),
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }
}

// [신규] 개별 개념 페이지를 그리는 위젯
class _ConceptPage extends StatelessWidget {
  final Concept concept;
  const _ConceptPage({required this.concept});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            concept.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
          ),
          const SizedBox(height: 24),
          Text(
            '💡 핵심 명령어 예제',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildCodeBlock(context, concept.commandExample),
          const SizedBox(height: 24),
          Text(
            '📜 YAML 예제',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildCodeBlock(context, concept.yamlExample),
        ],
      ),
    );
  }

  Widget _buildCodeBlock(BuildContext context, String code) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF282C34), // 어두운 코드 블록 배경색
        borderRadius: BorderRadius.circular(8),
      ),
      child: SelectableText(
        code,
        style: const TextStyle(
          fontFamily: 'Courier',
          color: Color(0xFFABB2BF), // 코드 텍스트 색상
          fontSize: 14,
        ),
      ),
    );
  }
}