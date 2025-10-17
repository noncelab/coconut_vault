import 'package:coconut_vault/constants/method_channel.dart';
import 'package:flutter/services.dart';

abstract class SecureZoneKeystore {
  final MethodChannel ch = const MethodChannel(methodChannelTEE);

  Future<void> generateKey({required String alias, bool userAuthRequired = false, bool perUseAuth = false});

  Future<void> deleteKey({required String alias});

  Future<Map<String, dynamic>> encrypt({required String alias, required Uint8List plaintext});

  Future<Uint8List?> decrypt({required String alias, required Uint8List ciphertext, required Uint8List iv});
}
