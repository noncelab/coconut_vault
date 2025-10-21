// lib/tee_smoke_test.dart
import 'dart:convert';
import 'package:coconut_vault/constants/method_channel.dart';
import 'package:coconut_vault/repository/secure_zone_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TeeSmokeTest extends StatefulWidget {
  const TeeSmokeTest({super.key});
  @override
  State<TeeSmokeTest> createState() => _TeeSmokeTestState();
}

class _TeeSmokeTestState extends State<TeeSmokeTest> {
  static const _ch = MethodChannel(methodChannelTEE);
  final SecureZoneRepository _secureZoneRepo = SecureZoneRepository();

  Uint8List? _ct;
  Uint8List? _iv;
  String _log = '';

  @override
  void initState() {
    super.initState();
  }

  static void _println(Object? msg) {
    debugPrint('[TEE TEST] $msg');
    //setState(() => _log = '[TEE TEST] $msg\n$_log');
  }

  Future<void> _isStrongBoxSupported() async {
    try {
      final r = await _ch.invokeMethod<bool>('isStrongBoxSupported');
      _println('isStrongBoxSupported -> $r');
    } catch (e) {
      _println('isStrongBoxSupported error: $e');
    }
  }

  Future<void> _generateKey() async {
    try {
      await _ch.invokeMethod('generateKey', {
        'alias': 'KEK_ALIAS',
        'userAuthRequired': true, // 필요 없으면 false
        'perUseAuth': false, // 매 사용 인증 불필요
      });
      _println('generateKey -> OK');
    } catch (e) {
      _println('generateKey error: $e');
    }
  }

  Future<void> _encrypt() async {
    try {
      final r = await _secureZoneRepo.encrypt(
        alias: 'KEK_ALIAS',
        plaintext: Uint8List.fromList(utf8.encode('hello-암호화테스트')),
      );
      _println('encrypt -> $r');
      final usedStrongBox = r.extra?['usedStrongBox'] as bool? ?? false;

      // 네이티브가 byte[]로 준 값은 Dart에서 Uint8List로 도착
      _ct = r.ciphertext;
      _iv = r.iv;

      _println('encrypt.usedStrongBox -> $usedStrongBox, ct=$_ct, ivLen=$_iv');
    } catch (e) {
      _println('encrypt error: $e');
    }
  }

  Future<void> _decrypt() async {
    try {
      final r = await _secureZoneRepo.decrypt(alias: 'KEK_ALIAS', ciphertext: _ct!, iv: _iv!);
      _println('decrypt -> $r');
    } catch (e) {
      _println('decrypt error: $e');
    }
  }

  Future<void> _decryptDemo() async {
    try {
      // 실제로는 직전에 받은 ciphertext/iv를 사용해야 함.
      // 데모를 위해 일단 encrypt를 한 번 호출해서 그 결과로 복호화까지 연결:
      final enc = await _secureZoneRepo.encrypt(
        alias: 'KEK_ALIAS',
        plaintext: Uint8List.fromList(utf8.encode('hello-암호화테스트')),
      );
      final Uint8List ct = enc.ciphertext;
      final Uint8List iv = enc.iv;

      _println('ct=$ct, iv=$iv');

      final dec = await _secureZoneRepo.decrypt(alias: 'KEK_ALIAS', ciphertext: ct, iv: iv);
      _println('decrypt -> $dec');
    } catch (e) {
      _println('decrypt error: $e');
    }
  }

  Future<void> _deleteKey() async {
    try {
      await _ch.invokeMethod('deleteKey', {'alias': 'KEK_ALIAS'});
      _println('deleteKey -> OK');
    } catch (e) {
      _println('deleteKey error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton(onPressed: _isStrongBoxSupported, child: const Text('isStrongBoxSupported')),
            ElevatedButton(onPressed: _generateKey, child: const Text('generateKey')),
            ElevatedButton(onPressed: _encrypt, child: const Text('encrypt')),
            ElevatedButton(onPressed: _decrypt, child: const Text('decrypt')),
            ElevatedButton(onPressed: _deleteKey, child: const Text('deleteKey')),
            ElevatedButton(onPressed: _decryptDemo, child: const Text('decrypt (roundtrip)')),
          ],
        ),
        const Divider(),
        SingleChildScrollView(child: Text(_log)),
      ],
    );
  }
}
