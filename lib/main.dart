import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 1. Riverpod import
import 'screens/main_screen.dart';
import 'screens/setup_screen.dart';
import 'screens/quiz_screen.dart';
import 'screens/result_screen.dart';
import 'screens/concept_screen.dart'; // 1. 새로운 화면 import
import 'screens/weekly_concepts_screen.dart';

void main() {
  // 2. ProviderScope로 앱을 감싸기
  runApp(const ProviderScope(child: CkaMasterApp()));
}

class CkaMasterApp extends StatelessWidget {
  const CkaMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CKA Master',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        // [수정] 밝은 테마로 변경
        brightness: Brightness.light, 
        scaffoldBackgroundColor: const Color(0xFFFDFCF5), // 연한 베이지 배경
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: const Color(0xFFFAFAFA), // [수정] 카드 배경을 보기 좋은 오프화이트 색상으로 변경
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const MainScreen(),
        '/setup': (context) => const SetupScreen(),
        '/quiz': (context) => const QuizScreen(),
        '/result': (context) => const ResultScreen(),
        '/concept': (context) => const ConceptScreen(),
        '/weekly-concepts': (context) => const WeeklyConceptsScreen(), // [수정] const 제거
      },
    );
  }
}