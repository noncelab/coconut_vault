import 'package:coconut_vault/constants/method_channel.dart';
import 'package:flutter/services.dart';

class SecureMemory {
  static const _channel = MethodChannel(methodChannelSecureMemory);

  static Future<void> wipe(Uint8List data) async {
    await _channel.invokeMethod('wipe', {'data': data});
  }
}
