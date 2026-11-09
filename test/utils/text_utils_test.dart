import 'package:coconut_vault/utils/text_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats a master fingerprint in groups of four', () {
    expect(TextUtils.formatMasterFingerprint('B8688DF1'), 'B868 8DF1');
    expect(TextUtils.formatMasterFingerprint('00000000'), '0000 0000');
  });

  test('keeps a value that is not a master fingerprint', () {
    expect(TextUtils.formatMasterFingerprint(''), '');
    expect(TextUtils.formatMasterFingerprint('B8688DF'), 'B8688DF');
  });
}
