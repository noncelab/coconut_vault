import 'package:flutter/foundation.dart';

/// Test-only failure injection for wallet deletion integration tests.
class DeletionFailureInjector {
  static const String _stage = String.fromEnvironment('WALLET_DELETE_FAILURE', defaultValue: 'none');

  static void throwIfConfigured(String stage, String key) {
    if (!kDebugMode || _stage != stage) return;
    throw StateError('Injected wallet deletion failure: stage=$stage, key=$key');
  }
}
