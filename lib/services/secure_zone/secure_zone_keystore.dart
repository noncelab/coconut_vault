import 'package:coconut_vault/constants/method_channel.dart';
import 'package:flutter/services.dart';

abstract class SecureZoneKeystore {
  final MethodChannel ch = const MethodChannel(methodChannelSecureModule);

  Future<void> generateKey({required String alias, bool userAuthRequired = false, bool perUseAuth = false});

  Future<void> deleteKey({required String alias});

  Future<void> deleteKeys({required List<String> aliasList});

  Future<Map<String, dynamic>> encrypt({required String alias, required Uint8List plaintext});

  /// Decrypts data using the secure zone key.
  ///
  /// [autoAuth] is only used on Android to control automatic authentication.
  /// On iOS, authentication is always handled by the system.
  Future<Uint8List?> decrypt({
    required String alias,
    required Uint8List ciphertext,
    required Uint8List iv,
    bool autoAuth = true,
  });
}
