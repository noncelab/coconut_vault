import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:flutter/material.dart';

class SeedQrConfirmationScreen extends StatelessWidget {
  final String scannedData;
  const SeedQrConfirmationScreen({
    super.key,
    required this.scannedData, // 필수 매개변수로 설정
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CoconutAppBar.build(
        context: context,
        title: 'QR 스캔 결과 확인',
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '스캔된 데이터:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                scannedData,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 32),
            const Text('패스프레이즈 쓸건지?'),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // 취소 시 이전 화면으로 돌아가기
                      Navigator.pop(context);
                    },
                    child: const Text('취소'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // 확인 시 다음 단계로 진행
                      // 여기에 다음 화면으로 이동하는 로직 추가
                      Navigator.pop(context, scannedData); // 결과와 함께 이전 화면으로 돌아가기
                    },
                    child: const Text('확인'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
