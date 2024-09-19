import 'package:coconut_lib/coconut_lib.dart';

bool isValidMnemonic(String words) {
  try {
    return WalletUtility.validateMnemonic(words);
  } catch (_) {
    return false;
  }
}
