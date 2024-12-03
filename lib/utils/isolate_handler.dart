import 'dart:async';
import 'dart:isolate';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/model/data/multisig_vault_list_item.dart';
import 'package:coconut_vault/model/data/singlesig_vault_list_item.dart';
import 'package:coconut_vault/model/data/vault_list_item_base.dart';
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

  Future<void> initialize(
      {InitializeType initialType = InitializeType.loadVaultList}) async {
    _receivePort = ReceivePort();
    _rootIsolateToken = RootIsolateToken.instance!;
    switch (initialType) {
      case InitializeType.addVault:
        _isolate = await Isolate.spawn(_entryPointAddVault,
            [_receivePort.sendPort, _rootIsolateToken, _handler]);
        break;
      case InitializeType.addMultisigVault:
        _isolate = await Isolate.spawn(_entryPointAddMultisigVault,
            [_receivePort.sendPort, _rootIsolateToken, _handler]);
        break;
      // case InitializeType.getAddressList:
      //   _isolate = await Isolate.spawn(
      //       _entryPointAddressList, [_receivePort.sendPort, _rootIsolateToken]);
      //   break;
      case InitializeType.canSign:
        _isolate = await Isolate.spawn(_entryPointCanSign,
            [_receivePort.sendPort, _rootIsolateToken, _handler]);
        break;
      case InitializeType.addSign:
        _isolate = await Isolate.spawn(_entryPointAddSign,
            [_receivePort.sendPort, _rootIsolateToken, _handler]);
        break;
      case InitializeType.extractSignerBsms:
        _isolate = await Isolate.spawn(_entryPointExtractBsms,
            [_receivePort.sendPort, _rootIsolateToken, _handler]);
        break;
      case InitializeType.getSignerIndex:
        _isolate = await Isolate.spawn(_entryPointGetSignerIndex,
            [_receivePort.sendPort, _rootIsolateToken, _handler]);
        break;
      case InitializeType.importMultisigVault:
        _isolate = await Isolate.spawn(_entryPointImportMultisigVault,
            [_receivePort.sendPort, _rootIsolateToken, _handler]);
        break;
      case InitializeType.fromKeyStore:
        _isolate = await Isolate.spawn(_entryPointFromKeyStore,
            [_receivePort.sendPort, _rootIsolateToken, _handler]);
        break;
      case InitializeType.initializeWallet:
        _isolate = await Isolate.spawn(_entryPointIntializeWallet,
            [_receivePort.sendPort, _rootIsolateToken, _handler]);
        break;
      default:
        _isolate = await Isolate.spawn(
            _entryPoint, [_receivePort.sendPort, _rootIsolateToken, _handler]);
        break;
    }

    _sendPort = await _receivePort.first as SendPort;
    _isInitialized = true;
  }

  bool get isInitialized => _isInitialized;

  static void _entryPoint(List<dynamic> args) {
    final SendPort mainSendPort = args[0];
    final RootIsolateToken rootIsolateToken = args[1];
    final handler =
        args[2] as FutureOr<dynamic> Function(dynamic, void Function(dynamic)?);
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

      final result = await (handler)(
          data, progressCallbackSendPort != null ? progressCallback : null);

      sendPort.send(result);
    });
  }

  static void _entryPointAddVault(List<dynamic> args) {
    final SendPort mainSendPort = args[0];
    final RootIsolateToken rootIsolateToken = args[1];
    final handler = args[2] as FutureOr<List<SinglesigVaultListItem>> Function(
        Map<String, dynamic>, void Function(dynamic)?);
    final port = ReceivePort();
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

  static void _entryPointAddMultisigVault(List<dynamic> args) {
    final SendPort mainSendPort = args[0];
    final RootIsolateToken rootIsolateToken = args[1];
    final handler = args[2] as FutureOr<MultisigVaultListItem> Function(
        Map<String, dynamic>, void Function(dynamic)?);
    final port = ReceivePort();
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

  static void _entryPointCanSign(List<dynamic> args) {
    final SendPort mainSendPort = args[0];
    final RootIsolateToken rootIsolateToken = args[1];
    final handler = args[2] as FutureOr<bool> Function(
        List<dynamic>, void Function(dynamic)?);
    final port = ReceivePort();
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

  static void _entryPointAddSign(List<dynamic> args) {
    final SendPort mainSendPort = args[0];
    final RootIsolateToken rootIsolateToken = args[1];
    final handler = args[2] as FutureOr<String> Function(
        List<dynamic>, void Function(dynamic)?);
    final port = ReceivePort();
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

  static void _entryPointExtractBsms(List<dynamic> args) {
    final SendPort mainSendPort = args[0];
    final RootIsolateToken rootIsolateToken = args[1];
    final handler = args[2] as FutureOr<List<String>> Function(
        List<dynamic>, void Function(dynamic)?);
    final port = ReceivePort();
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

  static void _entryPointGetSignerIndex(List<dynamic> args) {
    final SendPort mainSendPort = args[0];
    final RootIsolateToken rootIsolateToken = args[1];
    final handler = args[2] as FutureOr<int> Function(
        Map<String, dynamic>, void Function(dynamic)?);
    final port = ReceivePort();
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

  static void _entryPointImportMultisigVault(List<dynamic> args) {
    final SendPort mainSendPort = args[0];
    final RootIsolateToken rootIsolateToken = args[1];
    final handler = args[2] as FutureOr<MultisigVaultListItem> Function(
        Map<String, dynamic>, void Function(dynamic)?);
    final port = ReceivePort();
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

  static void _entryPointFromKeyStore(List<dynamic> args) {
    final SendPort mainSendPort = args[0];
    final RootIsolateToken rootIsolateToken = args[1];
    final handler = args[2] as FutureOr<MultisignatureVault> Function(
        Map<String, dynamic>, void Function(dynamic)?);
    final port = ReceivePort();
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

  static void _entryPointIntializeWallet(List<dynamic> args) {
    final SendPort mainSendPort = args[0];
    final RootIsolateToken rootIsolateToken = args[1];
    final handler = args[2] as FutureOr<VaultListItemBase> Function(
        Map<String, dynamic>, void Function(dynamic)?);
    final port = ReceivePort();
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
  // static void _entryPointAddressList(List<dynamic> args) {
  //   final SendPort mainSendPort = args[0];
  //   final RootIsolateToken rootIsolateToken = args[1];
  //   final port = ReceivePort();
  //   mainSendPort.send(port.sendPort);

  //   port.listen((message) async {
  //     final data = message[0];
  //     final sendPort = message[1] as SendPort;
  //     final handler = message[2] as FutureOr<List<Address>> Function(
  //         Map<String, dynamic>, void Function(dynamic)?);

  //     // Ensure the background isolate is properly initialized
  //     BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);

  //     final result = await handler(data, null);
  //     sendPort.send(result);
  //   });
  // }

  Future<R> run(T data,
      {void Function(List<dynamic>)? progressCallback}) async {
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
    _isolate.kill(priority: Isolate.immediate);
  }
}
