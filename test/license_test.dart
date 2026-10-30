import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  // 앱에 번들되는 라이선스 고지는 저장소 루트 LICENSE와 같아야 합니다.
  test('bundled LICENSE matches the repository LICENSE', () {
    expect(File('assets/files/LICENSE').readAsStringSync(), File('LICENSE').readAsStringSync());
  });
}
