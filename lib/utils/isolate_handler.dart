import 'dart:async';
import 'dart:isolate';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/model/common/spawn_isolate_dto.dart';
import 'package:flutter/services.dart';

enum InitializeType {
  addVault,
  addMultisigVault,
  loadVaultList,
  getAddressList,
  canSign,
  addSign,
  getSignerIndex,
  importMultisigVault,
  fromKeyStore,
  extractSignerBsms,
  initializeWallet
}

class IsolateHandler<T, R> {
  final FutureOr<R> Function(T, void Function(dynamic)?) _handler;
  late Isolate _isolate;
  late ReceivePort _receivePort;
  SendPort? _sendPort;
  late RootIsolateToken _rootIsolateToken;
  bool _isInitialized = false;

  IsolateHandler(this._handler);

  Future<void> initialize({InitializeType initialType = InitializeType.loadVaultList}) async {
    _receivePort = ReceivePort();
    _rootIsolateToken = RootIsolateToken.instance!;
    final data = SpawnIsolateDto(
        _receivePort.sendPort, _rootIsolateToken, _handler, NetworkType.currentNetworkType);
    switch (initialType) {
      case InitializeType.addVault:
      case InitializeType.addMultisigVault:
      // case InitializeType.getAddressList:
      case InitializeType.canSign:
      case InitializeType.addSign:
      case InitializeType.extractSignerBsms:
      case InitializeType.getSignerIndex:
      case InitializeType.importMultisigVault:
      case InitializeType.fromKeyStore:
      case InitializeType.initializeWallet:
        _isolate = await Isolate.spawn<SpawnIsolateDto>(_entryPoint, data);
        break;
      default:
        _isolate = await Isolate.spawn(
            _defaultEntryPoint, [_receivePort.sendPort, _rootIsolateToken, _handler]);
        break;
    }

    _sendPort = await _receivePort.first as SendPort;
    _isInitialized = true;
  }

  bool get isInitialized => _isInitialized;

  static void _defaultEntryPoint(List<dynamic> args) {
    final SendPort mainSendPort = args[0];
    final RootIsolateToken rootIsolateToken = args[1];
    final handler = args[2] as FutureOr<dynamic> Function(dynamic, void Function(dynamic)?);
    final port = ReceivePort();
    mainSendPort.send(port.sendPort);

    port.listen((message) async {
      final data = message[0];
      final sendPort = message[1] as SendPort;
      final SendPort? progressCallbackSendPort =
          message.length > 3 ? message[3] as SendPort? : null;

      void progressCallback(dynamic progress) {
        if (progressCallbackSendPort != null) {
          progressCallbackSendPort.send(progress);
        }
      }

      // Ensure the background isolate is properly initialized
      BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);

      final result =
          await (handler)(data, progressCallbackSendPort != null ? progressCallback : null);

      sendPort.send(result);
    });
  }

  static void _entryPoint(SpawnIsolateDto data) {
    final SendPort mainSendPort = data.sendPort;
    final RootIsolateToken rootIsolateToken = data.rootIsolateToken;
    final handler = data.handler;
    final port = ReceivePort();
    NetworkType.setNetworkType(data.networkType);
    mainSendPort.send(port.sendPort);

    port.listen((message) async {
      final data = message[0];
      final sendPort = message[1] as SendPort;

      // Ensure the background isolate is properly initialized
      BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);

      final result = await handler(data, null);
      sendPort.send(result);
    });
  }

  Future<R> run(T data, {void Function(List<dynamic>)? progressCallback}) async {
    if (_sendPort == null) {
      throw Exception('Isolate not initialized. Call initialize() first.');
    }

    final receivePort = ReceivePort();
    final progressPort = ReceivePort();

    if (progressCallback != null) {
      progressPort.listen((progress) {
        progressCallback(progress as List<dynamic>);
      });
    }

    _sendPort!.send([
      data,
      receivePort.sendPort,
      _handler,
      progressCallback != null ? progressPort.sendPort : null
    ]);
    final result = await receivePort.first as R;

    receivePort.close();
    progressPort.close();
    return result;
  }

  Future<R> runAddVault(T data) async {
    if (_sendPort == null) {
      throw Exception('Isolate not initialized. Call initialize() first.');
    }
    final receivePort = ReceivePort();

    _sendPort!.send([
      data,
      receivePort.sendPort,
      _handler,
    ]);

    final result = await receivePort.first as R;
    receivePort.close();

    return result;
  }

  void dispose() {
    _receivePort.close();
    _isolate.kill(priority: Isolate.immediate);
  }
}
