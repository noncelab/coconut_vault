import 'dart:async';
import 'dart:isolate';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/isolates/wallet_isolates/wallet_isolates.dart';

/// MuSig2 첫 번째 서명자를 위한 long-running isolate.
///
/// 첫 번째 서명자는 다음 두 단계 사이에 [KeyStore] 인스턴스(그리고 그 안의
/// `_muSig2SecretNonces`)를 유지해야 합니다.
///   1. public nonce 생성
///   2. 두 번째 서명자의 partial signature를 받은 뒤 자신의 partial signature 생성
///
/// 이 isolate는 한 번 생성된 [TaprootVault]/[KeyStore]를 내부에 살려두고,
/// 명령 기반으로 두 단계를 처리합니다.
class MuSig2FirstSignerIsolate {
  Isolate? _isolate;
  late SendPort _sendPort;
  final _initPort = ReceivePort();
  bool _disposed = false;

  /// isolate를 생성하고 초기화가 완료될 때까지 기다립니다.
  Future<void> initialize() async {
    if (_disposed) throw StateError('Isolate already disposed');
    _isolate = await Isolate.spawn(_isolateEntry, _initPort.sendPort);
    _sendPort = await _initPort.first as SendPort;
  }

  /// BSMS로 볼트를 복원하고 [seed]를 바인딩한 뒤, [psbt]에 첫 번째 서명자의
  /// public nonce를 추가한 PSBT 문자열을 반환합니다.
  Future<String> addPublicNonce(String bsms, String psbt, Seed seed) async {
    return _request(_IsolateMessageType.addNonce, {'bsms': bsms, 'psbt': psbt, 'seed': seed});
  }

  /// 두 번째 서명자의 nonce + partial signature가 포함된 [psbt]를 받아,
  /// 첫 번째 서명자의 partial signature를 추가하고 최종 PSBT를 반환합니다.
  Future<String> addSignature(String psbt) async {
    return _request(_IsolateMessageType.addSignature, {'psbt': psbt});
  }

  Future<String> _request(_IsolateMessageType type, Map<String, dynamic> payload) async {
    _ensureReady();
    final responsePort = ReceivePort();
    _sendPort.send(_IsolateMessage(type: type, payload: payload, replyPort: responsePort.sendPort));
    try {
      final result = await responsePort.first;
      if (result is _IsolateError) throw result.error;
      return result as String;
    } finally {
      responsePort.close();
    }
  }

  /// isolate를 종료하고 내부에 남아 있던 seed, derived key, secret nonce 등을
  /// 메모리에서 제거합니다.
  ///
  /// isolate에게 정리를 지시한 뒤, 정리가 완료되었다는 ack를 받을 때까지
  /// 기다립니다. ack가 오지 않으면 최대 2초 후 강제 종료합니다.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    final ackPort = ReceivePort();
    try {
      _sendPort.send(_IsolateMessage(type: _IsolateMessageType.exit, payload: {'ackPort': ackPort.sendPort}));
      // isolate이 seed/secret nonce를 모두 지우고 ack를 보낼 때까지 기다립니다.
      await ackPort.first.timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          // 정상적으로 정리되지 않으면 강제 종료합니다.
          _isolate?.kill(priority: Isolate.immediate);
          return null;
        },
      );
    } catch (_) {
      // 메시지 전달/수신 실패 시에도 isolate을 강제 종료합니다.
      _isolate?.kill(priority: Isolate.immediate);
    } finally {
      ackPort.close();
      _initPort.close();
      _isolate = null;
    }
  }

  void _ensureReady() {
    if (_disposed) throw StateError('Isolate is disposed');
    if (_isolate == null) throw StateError('Isolate not initialized');
  }

  static void _isolateEntry(SendPort mainSendPort) {
    WalletIsolates.setNetworkType();

    final receivePort = ReceivePort();
    mainSendPort.send(receivePort.sendPort);

    TaprootVault? vault;

    receivePort.listen((message) {
      if (message is! _IsolateMessage) return;

      switch (message.type) {
        case _IsolateMessageType.addNonce:
          try {
            vault = TaprootVault.fromCoordinatorBsms(message.payload['bsms'] as String);
            vault!.bindSeedToKeyStore(message.payload['seed'] as Seed);
            final psbt = vault!.addPublicNonce(message.payload['psbt'] as String);
            message.replyPort!.send(psbt);
          } catch (e) {
            message.replyPort!.send(_IsolateError(e));
          }
          break;
        case _IsolateMessageType.addSignature:
          try {
            if (vault == null) {
              message.replyPort!.send(_IsolateError(StateError('addNonce must be called before addSignature.')));
              return;
            }
            final psbt = vault!.addSignatureToPsbt(message.payload['psbt'] as String);
            message.replyPort!.send(psbt);
          } catch (e) {
            message.replyPort!.send(_IsolateError(e));
          }
          break;
        case _IsolateMessageType.exit:
          for (final keyStore in vault?.keyStoreList ?? <KeyStore>[]) {
            keyStore.wipeSeed();
          }
          final ackPort = message.payload['ackPort'] as SendPort;
          ackPort.send(null); // 정리 완료 ack
          receivePort.close();
          break;
      }
    });
  }
}

enum _IsolateMessageType { addNonce, addSignature, exit }

class _IsolateMessage {
  final _IsolateMessageType type;
  final Map<String, dynamic> payload;
  final SendPort? replyPort;

  const _IsolateMessage({required this.type, this.payload = const {}, this.replyPort});
}

class _IsolateError {
  final Object error;

  const _IsolateError(this.error);
}
