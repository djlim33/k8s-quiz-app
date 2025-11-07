import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('문제 5: Pod 생성 - 정답(✓)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 내가 제출한 커맨드
            _buildAnswerCard(
              context,
              title: '내가 제출한 커맨드',
              command: 'kubectl run my-pod --image=nginx:1.21 --labels=app=my-app',
            ),
            
            // 2. 모범 답안 (정답 커맨드)
            _buildAnswerCard(
              context,
              title: '모범 답안 (Imperative)',
              command:
                  'kubectl run my-pod --image=nginx:1.21 --labels=app=my-app',
            ),
            _buildAnswerCard(
              context,
              title: '모범 답안 (Declarative - YAML)',
              command:
                  'apiVersion: v1\n'
                  'kind: Pod\n'
                  'metadata:\n'
                  '  name: my-pod\n'
                  '  labels:\n'
                  '    app: my-app\n'
                  'spec:\n'
                  '  containers:\n'
                  '  - name: my-container\n'
                  '    image: nginx:1.21',
            ),

            // 3. 핵심 해설 및 개념
            _buildExplanationCard(context),
          ],
        ),
      ),
    );
  }

  // 답안 카드 (재사용)
  Widget _buildAnswerCard(BuildContext context,
      {required String title, required String command}) {
    return Card(
      color: Colors.grey[900], // 터미널과 유사한 배경색
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              color: Colors.black,
              width: double.infinity,
              child: Text(
                command,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Courier',
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 해설 카드
  Widget _buildExplanationCard(BuildContext context) {
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
              padding: const EdgeInsets.all(10),
              color: Colors.grey[850],
              width: double.infinity,
              margin: const EdgeInsets.only(top: 5),
              child: const Text(
                'kubectl run ... --dry-run=client -o yaml > pod.yaml',
                style: TextStyle(color: Colors.white, fontFamily: 'Courier'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}