import 'dart:convert';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/isolates/sign_isolates.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/multisig/multisig_import_detail.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/model/multisig/multisig_vault_list_item.dart';
import 'package:coconut_vault/providers/sign_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/utils/bip/normalized_multisig_config.dart';
import 'package:coconut_vault/utils/bip/signer_bsms.dart';
import 'package:coconut_vault/utils/coconut/transaction_util.dart';
import 'package:coconut_vault/utils/hex_util.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/utils/print_util.dart';
import 'package:flutter/foundation.dart';

class MultisigSignViewModel extends ChangeNotifier {
  late final WalletProvider _walletProvider;
  late final SignProvider _signProvider;
  late final MultisigVaultListItem _vaultListItem;
  late final MultisignatureVault _coconutVault;
  late final List<bool> _signerApproved;
  late final List<bool> _hasPassphraseList;
  late String _psbtForSigning;
  String? _signedRawTxHex;
  bool _signStateInitialized = false;
  final bool _isSigningOnlyMode;
  Map<String, String>? _input0PubkeyBySigner;

  MultisigSignViewModel(this._walletProvider, this._signProvider, this._isSigningOnlyMode) {
    _vaultListItem = _signProvider.vaultListItem! as MultisigVaultListItem;
    _coconutVault = _vaultListItem.coconutVault as MultisignatureVault;
    _signerApproved = List<bool>.filled(_vaultListItem.signers.length, false);
    _hasPassphraseList = List<bool>.filled(_vaultListItem.signers.length, false);

    _psbtForSigning = _signProvider.unsignedPsbtBase64!;
    if (!_isSigningOnlyMode) {
      _checkPassphraseStatus();
    }
  }

  Future<void> _checkPassphraseStatus() async {
    for (int i = 0; i < _vaultListItem.signers.length; ++i) {
      final innerVaultId = _vaultListItem.signers[i].innerVaultId;
      if (innerVaultId != null) {
        _hasPassphraseList[i] = await _walletProvider.hasPassphrase(innerVaultId);
      }
    }
  }

  int get vaultId => _vaultListItem.id;
  int get requiredSignatureCount => _vaultListItem.requiredSignatureCount;
  String get walletName => _signProvider.vaultListItem!.name;
  List<bool> get signersApproved => _signerApproved;
  String get firstRecipientAddress =>
      _signProvider.recipientAddress != null
          ? _signProvider.recipientAddress!
          : _signProvider.recipientAmounts!.keys.first;
  int get recipientCount => _signProvider.recipientAddress != null ? 1 : _signProvider.recipientAmounts!.length;
  int get sendingAmount => _signProvider.sendingAmount!;
  int get remainingSignatures =>
      _vaultListItem.requiredSignatureCount - _signerApproved.where((bool isApproved) => isApproved).length;
  bool get isSignatureCompleted => remainingSignatures <= 0 || _signedRawTxHex != null;
  List<MultisigSigner> get signers => _vaultListItem.signers;
  String get psbtForSigning => _psbtForSigning;
  int getInnerVaultId(int index) => _vaultListItem.signers[index].innerVaultId!;
  bool getHasPassphrase(int index) => _hasPassphraseList[index];
  bool get isSigningOnlyMode => _isSigningOnlyMode;
  String get unsignedPsbtBase64 => _signProvider.unsignedPsbtBase64!;

  void initPsbtSignState() {
    assert(!_signStateInitialized); // 오직 한번만 호출
    assert(_signProvider.isMultisig == true);
    _signStateInitialized = true;

    final psbt = _signProvider.psbt!;
    for (var entry in _coconutVault.keyStoreList.asMap().entries) {
      if (psbt.isSigned(entry.value) && !_signerApproved[entry.key]) {
        updateSignState(entry.key);
      }
    }

    if (_signProvider.isMultisig == true) {
      Map<String, String> input0PubkeyMap = {};
      final unsignedPsbt = Psbt.parse(unsignedPsbtBase64);
      final keystoreList = (_vaultListItem.coconutVault as MultisignatureVault).keyStoreList;
      final input0DerivationPaths = unsignedPsbt.inputs[0].bip32Derivation!;

      for (int i = 0; i < keystoreList.length; i++) {
        input0PubkeyMap[keystoreList[i].masterFingerprint] =
            input0DerivationPaths.firstWhere((element) {
              return element.masterFingerprint.toUpperCase() == keystoreList[i].masterFingerprint.toUpperCase();
            }).publicKey;
      }
      _input0PubkeyBySigner = input0PubkeyMap;
    }
  }

  void updateSignState(int? index) {
    if (index != null) {
      _signerApproved[index] = true;
      notifyListeners();
    }
  }

  void saveSignedResultIfCompleted() {
    if (isSignatureCompleted) {}
  }

  void saveSignedRawTxHex(String hexString) {
    _signedRawTxHex = hexString;
  }

  Future<Uint8List> getSecret(int index) async {
    return await _walletProvider.getSecret(_vaultListItem.signers[index].innerVaultId!);
  }

  Future<void> sign(int index, Seed seed) async {
    try {
      _psbtForSigning = await compute(SignIsolates.addSignatureToPsbtWithMultisigVault, [seed, _psbtForSigning]);
      updateSignState(index);
    } finally {
      seed.wipe();
    }
  }

  Future<void> signPsbtInSigningOnlyMode(int index) async {
    assert(_isSigningOnlyMode);
    Seed? seed;
    try {
      seed = await _walletProvider.getSeedInSigningOnlyMode(_vaultListItem.signers[index].innerVaultId!);
      _psbtForSigning = await compute(SignIsolates.addSignatureToPsbtWithMultisigVault, [seed, _psbtForSigning]);
      updateSignState(index);
    } finally {
      seed?.wipe();
    }
  }

  /// [Krux, Keystone]외부 하드웨어 지갑에서 서명한 PSBT를 현재 PSBT에 추가합니다.
  // void addSignSignature(String signedPsbtBase64) {
  //   try {
  //     final currentPsbt = Psbt.parse(_psbtForSigning);
  //     final scannedPsbt = Psbt.parse(signedPsbtBase64);

  //     // 각 input에 대해 스캔한 PSBT의 서명을 현재 PSBT에 추가
  //     for (int i = 0; i < currentPsbt.inputs.length && i < scannedPsbt.inputs.length; i++) {
  //       final scannedInput = scannedPsbt.inputs[i];
  //       final currentInput = currentPsbt.inputs[i];

  //       // 스캔한 input의 모든 partialSig를 현재 input에 추가
  //       if (scannedInput.partialSig != null && scannedInput.partialSig!.isNotEmpty) {
  //         for (var sig in scannedInput.partialSig!) {
  //           // 이미 존재하는 서명인지 확인 (중복 방지)
  //           bool alreadyExists =
  //               currentInput.partialSig?.any((existingSig) => existingSig.publicKey == sig.publicKey) ?? false;

  //           if (!alreadyExists) {
  //             currentInput.addPartialSig(sig.signature, sig.publicKey);
  //           }
  //         }
  //       }
  //     }

  //     // 서명을 추가한 후 PSBT를 base64로 변환하여 저장
  //     _psbtForSigning = currentPsbt.serialize();
  //   } catch (e) {
  //     debugPrint('addSignSignature error: $e');
  //     // 파싱 실패 시, 스캔한 PSBT를 그대로 사용
  //     // TODO: 제거 !! 원복 !! ??????
  //     _psbtForSigning = signedPsbtBase64;
  //   }
  // }

  void saveSignedResult() {
    if (_signedRawTxHex != null) {
      _signProvider.saveSignedRawTxHexString(_signedRawTxHex!);
      return;
    }

    _signProvider.saveSignedPsbt(_psbtForSigning);
  }

  void reset() {
    _signProvider.resetSignedPsbt();
    _signProvider.resetSignedRawTxHexString();
  }

  void resetAll() {
    _signProvider.resetPsbt();
    _signProvider.resetRecipientAddress();
    _signProvider.resetRecipientAmounts();
    _signProvider.resetSendingAmount();
    _signProvider.resetSignedPsbt();
    _signProvider.resetSignedRawTxHexString();
  }

  HardwareWalletType? getSignerHwwType(int index) {
    return _vaultListItem.signers[index].signerSource;
  }

  String? getMultisigInfoQrData(HardwareWalletType hwwType) {
    switch (hwwType) {
      case HardwareWalletType.keystone:
        return _getKeystoneMultisigInfoQrData();
      case HardwareWalletType.krux:
        return _getKruxMultisigInfoQrData();
      case HardwareWalletType.coconutVault:
        return _getCoconutVaultMultisigInfoQrData();
      default:
        return null;
    }
  }

  // {
  //   "label": "multisig2",
  //   "blockheight": 140309,
  //   "descriptor": "wsh(sortedmulti(2,[73c5da0a/48h/1h/0h/2h]tpubDFH9dgzveyD8zTbPUFuLrGmCydNvxehyNdUXKJAQN8x4aZ4j6UZqGfnqFrD4NqyaTVGKbvEW54tsvPTK2UoSbCC1PJY8iCNiwTL3RWZEheQ,[a0f6ba00/48h/1h/0h/2h]tpubDFX3DiBn9TanpuwxEbfBfPoRDtfGuwRNpkCFf4Yq22SMSGhr4zLhMBFSbTR7jFnLbNdqvtLUyuSAYk4jR8vSa4h2m8qL6zxwU4bYE1wGmDF,[a3b2eb70/48h/1h/0h/2h]tpubDFXHjN6AZbhZd5H6XhMWAKjoCn9r9Uj6sMtyXKTkN3HAaYEMEGKzU836gkxcF7PUT3BgMUj8KPmU447kzo1naMetkyWNRoBapfAbqWqUuzQ))#pmgfjdf3"
  // }
  String _getKruxMultisigInfoQrData() {
    final name = _vaultListItem.name;
    final coordinatorBsms = _vaultListItem.coordinatorBsms;

    final lines = coordinatorBsms.split('\n');
    if (lines.length < 4) {
      throw FormatException('Coordinator BSMS block too short: ${lines.length}');
    }

    final descriptorLine = lines[1].replaceAll("'", "h");

    // Zpub, Vpub 형식인 경우 xpub, tpub으로 변환
    if (descriptorLine.contains('Zpub') || descriptorLine.contains('Vpub')) {
      final quorumM = _extractQuorumM(descriptorLine);
      final fingerprintZpubMap = _extractFingerprintZpubMap(descriptorLine);
      final Map<String, String> xpubMap = {};
      for (var entry in fingerprintZpubMap.entries) {
        final extendedPublicKey = ExtendedPublicKey.parse(entry.value);
        final xpub = extendedPublicKey.serialize(toXpub: true);
        xpubMap[entry.key] = xpub;
      }

      final wshSortedMultiDescriptor = _buildWshSortedMultiDescriptor(m: quorumM, fpXpubMap: xpubMap);

      final coordinatorBsmsJson = {'label': name, 'blockheight': 0, 'descriptor': wshSortedMultiDescriptor};
      return jsonEncode(coordinatorBsmsJson);
    }

    final coordinatorBsmsJson = {'label': name, 'blockheight': 0, 'descriptor': descriptorLine};

    return jsonEncode(coordinatorBsmsJson);
  }

  int _extractQuorumM(String descriptor) {
    final regex = RegExp(r'sortedmulti\s*\(\s*(\d+)\s*,', caseSensitive: false);
    final match = regex.firstMatch(descriptor);

    if (match == null) {
      throw const FormatException('sortedmulti(m, ...) block not found in descriptor');
    }

    return int.parse(match.group(1)!);
  }

  Map<String, String> _extractFingerprintZpubMap(String descriptor) {
    final regex = RegExp(r'\[([0-9A-Fa-f]{8})/[^\]]+\]([A-Za-z]pub[1-9A-HJ-NP-Za-km-z]+)');

    final result = <String, String>{};

    for (final match in regex.allMatches(descriptor)) {
      final fp = match.group(1)!.toUpperCase(); // fingerprint
      final key = match.group(2)!; // Zpub/Vpub/xpub/tpub ...

      // Zpub/Vpub 인 경우만 xpub/tpub 로 변환, 나머지는 그대로 사용
      if (key.startsWith('Zpub') || key.startsWith('Vpub')) {
        final extendedPublicKey = ExtendedPublicKey.parse(key);
        final normalizedXpub = extendedPublicKey.serialize(toXpub: true);
        result[fp] = normalizedXpub;
      } else {
        result[fp] = key;
      }
    }

    return result;
  }

  String _buildWshSortedMultiDescriptor({required int m, required Map<String, String> fpXpubMap}) {
    if (fpXpubMap.isEmpty) {
      throw ArgumentError('Signer map cannot be empty');
    }
    if (m <= 0 || m > fpXpubMap.length) {
      throw ArgumentError('Invalid quorum: $m-of-${fpXpubMap.length}');
    }

    final coin = NetworkType.currentNetworkType == NetworkType.mainnet ? 0 : 1;
    final derivationPath = "48h/${coin}h/0h/2h";

    final sortedEntries = fpXpubMap.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    final signerParts = sortedEntries
        .map((e) {
          final fp = e.key;
          final xpub = e.value;
          return '[$fp/$derivationPath]$xpub';
        })
        .join(',');

    return 'wsh(sortedmulti($m,$signerParts))';
  }

  String _getKeystoneMultisigInfoQrData() {
    final name = _vaultListItem.name;

    // keystone일 때는 zpub 형식으로 변환
    final signerBsmsList =
        _vaultListItem.signers.map((signer) {
          final parsedBsms = SignerBsms.parse(signer.signerBsms!);
          // extendedKey를 zpub 형식으로 변환
          final extendedPublicKey = ExtendedPublicKey.parse(parsedBsms.extendedKey);
          final zpub = extendedPublicKey.serialize(toXpub: true);

          // zpub으로 변환된 extendedKey를 사용하여 새로운 SignerBsms 생성
          final convertedBsms = SignerBsms(
            fingerprint: parsedBsms.fingerprint,
            derivationPath: parsedBsms.derivationPath,
            extendedKey: zpub,
            label: parsedBsms.label,
          );

          return convertedBsms.getSignerBsms(includesLabel: false);
        }).toList();

    final config = NormalizedMultisigConfig(
      name: name,
      requiredCount: _vaultListItem.requiredSignatureCount,
      signerBsms: signerBsmsList,
    );

    return config.getMultisigConfigString();
  }

  String _getCoconutVaultMultisigInfoQrData() {
    final vaultListItem = _walletProvider.getVaultById(_vaultListItem.id) as MultisigVaultListItem;
    String coordinatorBsms = vaultListItem.coordinatorBsms;
    Map<String, dynamic> walletSyncString = jsonDecode(vaultListItem.getWalletSyncString());

    Map<String, String> namesMap = {};
    for (var signer in vaultListItem.signers) {
      if (signer.name == null) continue;
      namesMap[signer.keyStore.masterFingerprint] = signer.name!;
    }

    final qrData = jsonEncode(
      MultisigImportDetail(
        name: walletSyncString['name'],
        colorIndex: walletSyncString['colorIndex'],
        iconIndex: walletSyncString['iconIndex'],
        namesMap: namesMap,
        coordinatorBsms: coordinatorBsms,
      ),
    );

    return qrData;
  }

  /// 스캔된 psbt로 _psbtForSigning을 교체하는 함수
  void updatePsbt(String scannedPsbt) {
    _psbtForSigning = scannedPsbt;
    notifyListeners();
  }

  /// TODO: 코드 리뷰..!!!
  /// 스캔된 PSBT의 partial signature를 기반으로 서명 상태를 동기화합니다.
  // void syncImportedPartialSigs(String psbtBase64) {
  //   if (psbtBase64.startsWith('02000000')) {
  //     // Raw Transaction인 경우 서명 여부 확인을 canUpdatePsbt()에서 이미 진행 완료
  //     // TODO: 이거 하면 안됨......
  //     _signerApproved.fillRange(0, _signerApproved.length, true);
  //     notifyListeners();
  //     return;
  //   }

  //   final scannedPsbtPartialSigs = Psbt.parse(psbtBase64).inputs[0].partialSig?.map((e) => e.publicKey).toList() ?? [];
  //   _signerApproved.fillRange(0, _signerApproved.length, false);

  //   if (scannedPsbtPartialSigs.isEmpty) {
  //     // partialSig가 비어있는 경우 = 서명이 하나도 안된 경우
  //     debugPrint('scannedPsbtPartialSigsMap is empty');
  //     notifyListeners();
  //     return;
  //   }

  //   for (var signer in signers) {
  //     final mfp = signer.keyStore.masterFingerprint;
  //     final pubKey = unsignedPubkeyMap![mfp];
  //     final index = signers.indexOf(signer);

  //     if (scannedPsbtPartialSigs.contains(pubKey)) {
  //       _signerApproved[index] = true;
  //     }
  //   }

  //   notifyListeners();
  // }

  /// Raw tx hex string이 스캔된 경우는 반드시 서명이 완료된 상태
  void validateRawSignedTransaction(String rawSignedTransaction) {
    final exceptionMessages = t.multisig_sign_screen.exception;
    try {
      if (!rawSignedTransaction.substring(8).startsWith(rawTxSegwitField)) {
        throw FormatException(exceptionMessages.not_segwit);
      }

      final currentTx = Psbt.parse(_psbtForSigning).unsignedTransaction!;
      final scannedTx = Transaction.parse(rawSignedTransaction);

      if (!_isTransactionBodySame(currentTx, scannedTx)) {
        throw FormatException(exceptionMessages.invalid_sign_error);
      }

      // 서명 완료 여부 확인
      for (int i = 0; i < currentTx.inputs.length; i++) {
        // 서명 개수 체크
        // n = requiredSignatureCount 일 때,
        // witnessList[0] = dummy
        // witnessList[..] = signature
        // witnessList[..] = signature
        // witnessList[n + 1] = witness script
        if (scannedTx.inputs[i].witnessList.length - 2 != _vaultListItem.requiredSignatureCount) {
          throw FormatException(exceptionMessages.needs_more_signature);
        }
      }
    } on FormatException {
      rethrow;
    } catch (e) {
      Logger.error('validateRawSignedTransaction error: $e');
      throw FormatException(exceptionMessages.invalid_sign_error);
    }
  }

  bool _isTransactionBodySame(Transaction tx1, Transaction tx2) {
    if (tx1.transactionHash != tx2.transactionHash) {
      return false;
    }
    if (tx1.outputs.length != tx2.outputs.length || tx1.inputs.length != tx2.inputs.length) {
      return false;
    }
    for (int i = 0; i < tx1.outputs.length; i++) {
      if (tx1.outputs[i].serialize() != tx2.outputs[i].serialize()) {
        return false;
      }
    }
    for (int i = 0; i < tx1.inputs.length; i++) {
      if (tx1.inputs[i].serialize() != tx2.inputs[i].serialize()) {
        return false;
      }
    }

    return true;
  }

  void onScannedPsbt(String scannedData, {bool isOverwrite = false}) {
    final exceptionMessages = t.multisig_sign_screen.exception;
    try {
      // 1. validate
      final currentPsbt = Psbt.parse(_psbtForSigning);
      final currentTx = currentPsbt.unsignedTransaction!;
      final scannedPsbt = Psbt.parse(scannedData);
      final scannedTx = scannedPsbt.unsignedTransaction!;

      if (!_isTransactionBodySame(currentTx, scannedTx)) {
        throw FormatException(exceptionMessages.invalid_sign_error);
      }

      if (scannedPsbt.inputs.isEmpty) {
        throw FormatException(exceptionMessages.invalid_sign_error);
      }

      // 모든 input에 서명 정보가 1개라도 있고, 서명 개수가 동일한지 확인
      int? signatureCount;
      for (int i = 0; i < scannedPsbt.inputs.length; i++) {
        if (scannedPsbt.inputs[i].partialSig == null || scannedPsbt.inputs[i].partialSig!.isEmpty) {
          throw FormatException(exceptionMessages.no_signature);
        }

        if (signatureCount == null) {
          signatureCount = scannedPsbt.inputs[i].partialSig!.length;
        } else {
          if (scannedPsbt.inputs[i].partialSig!.length != signatureCount) {
            throw FormatException(exceptionMessages.invalid_sign_error);
          }
        }
      }

      // 2. 서명된 정보 업데이트
      int? finalSignatureCount;
      for (int i = 0; i < currentPsbt.inputs.length; i++) {
        final currentInput = currentPsbt.inputs[i];
        final scannedInput = scannedPsbt.inputs[i];

        if (isOverwrite) {
          final Set<String> signaturePubKeySet = scannedInput.partialSig!.map((sig) => sig.publicKey).toSet();
          currentInput.partialSig?.removeWhere((existingSig) => !signaturePubKeySet.contains(existingSig.publicKey));
        }

        for (var sig in scannedInput.partialSig!) {
          // 이미 존재하는 서명인지 확인 (중복 방지)
          bool alreadyExists =
              currentInput.partialSig?.any((existingSig) => existingSig.publicKey == sig.publicKey) ?? false;

          if (alreadyExists) continue;

          if (!currentPsbt.validateSignature(i, sig.signature, sig.publicKey)) {
            throw FormatException(exceptionMessages.invalid_sign_error);
          }

          currentInput.addPartialSig(sig.signature, sig.publicKey);
        }

        // input 별 서명 개수 동일한지 확인
        if (finalSignatureCount == null) {
          finalSignatureCount = currentInput.partialSig!.length;
        } else {
          if (currentInput.partialSig!.length != finalSignatureCount) {
            throw FormatException(exceptionMessages.invalid_sign_error);
          }
        }
      }

      _updateSignerApproved(currentPsbt);
      _psbtForSigning = currentPsbt.serialize();
    } on FormatException catch (_) {
      rethrow;
    } catch (e) {
      Logger.error('validateRawSignedTransaction error: $e');
      throw FormatException(exceptionMessages.invalid_sign_error);
    }
  }

  void _updateSignerApproved(Psbt currentPsbt) {
    if (currentPsbt.inputs[0].partialSig == null || currentPsbt.inputs[0].partialSig!.isEmpty) {
      _signerApproved.fillRange(0, _signerApproved.length, false);
      notifyListeners();
      return;
    }
    final newSignerApproved = List<bool>.filled(_vaultListItem.signers.length, false);
    for (int i = 0; i < currentPsbt.inputs[0].partialSig!.length; i++) {
      // 서명자 인덱스를 찾아서 _signerApproved 업데이트
      final publicKey = currentPsbt.inputs[0].partialSig![i].publicKey;
      final signerIndex = _input0PubkeyBySigner!.values.toList().indexOf(publicKey);

      assert(signerIndex != -1);

      newSignerApproved[signerIndex] = true;
    }
    _signerApproved.setAll(0, newSignerApproved);
    notifyListeners();
  }

  /// 스캔된 PSBT로 현재 SigningPsbt를 교체 할 수 있는지 체크하는 함수(UnsignedTransaction 비교)
  /// rawSignedTransaction hex string일 수도 있음
  bool hasSameTransactionBody(String scannedData) {
    try {
      final currentTx = Psbt.parse(_psbtForSigning).unsignedTransaction!;
      final scannedTx = Psbt.parse(scannedData).unsignedTransaction!;
      return _isTransactionBodySame(currentTx, scannedTx);
    } catch (e) {
      debugPrint('canUpdatePsbt error: $e');
      return false;
    }
  }
}
