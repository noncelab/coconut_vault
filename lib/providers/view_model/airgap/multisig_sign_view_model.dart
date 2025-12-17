import 'dart:convert';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/isolates/sign_isolates.dart';
import 'package:coconut_vault/model/multisig/multisig_import_detail.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/model/multisig/multisig_vault_list_item.dart';
import 'package:coconut_vault/providers/sign_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/utils/bip/normalized_multisig_config.dart';
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
  bool _signStateInitialized = false;
  final bool _isSigningOnlyMode;

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
  bool get isSignatureComplete => remainingSignatures <= 0;
  List<MultisigSigner> get signers => _vaultListItem.signers;
  String get psbtForSigning => _psbtForSigning;
  int getInnerVaultId(int index) => _vaultListItem.signers[index].innerVaultId!;
  bool getHasPassphrase(int index) => _hasPassphraseList[index];
  bool get isSigningOnlyMode => _isSigningOnlyMode;
  String get unsignedPsbtBase64 => _signProvider.unsignedPsbtBase64!;
  Map<String, String>? get unsignedInputsMap => _signProvider.unsignedInputsMap;
  Map<String, String>? get unsignedPubkeyMap => _signProvider.unsignedPubkeyMap;
  Map<String, String>? get signedInputsMap => _signProvider.signedInputsMap;
  String get signingPublicKey => _signProvider.signingPublicKey!;
  void initPsbtSignState() {
    assert(!_signStateInitialized); // 오직 한번만 호출
    _signStateInitialized = true;

    final psbt = _signProvider.psbt!;
    for (var entry in _coconutVault.keyStoreList.asMap().entries) {
      if (psbt.isSigned(entry.value) && !_signerApproved[entry.key]) {
        updateSignState(entry.key);
      }
    }

    // multisig sign인 경우, 서명 시 각 지갑에 대한 서명이 맞는지 확인하기 위해 inputsMap을 저장합니다.
    if (_signProvider.isMultisig == true) {
      // {mfp, derivationPath}
      Map<String, String> inputsMap = {};
      Map<String, String> pubkeyMap = {};
      final unsignedPsbt = Psbt.parse(unsignedPsbtBase64);

      for (int i = 0; i < unsignedPsbt.extendedPublicKeyList.length; i++) {
        inputsMap[unsignedPsbt.extendedPublicKeyList[i].masterFingerprint] =
            unsignedPsbt.inputs[0].derivationPathList[i].path.toString();
        pubkeyMap[unsignedPsbt.extendedPublicKeyList[i].masterFingerprint] =
            unsignedPsbt.inputs[0].bip32Derivation![i].publicKey.toString();
      }
      saveUnsignedInputsMap(inputsMap);
      saveUnsignedPubkeyMap(pubkeyMap);
    }
  }

  void updateSignState(int? index) {
    if (index != null) {
      _signerApproved[index] = true;
      notifyListeners();
    }
  }

  /// 스캔된 PSBT에서 실제로 서명한 signer index를 찾습니다.
  /// 외부 하드웨어 지갑에서 서명한 경우, psbt.isSigned()를 사용하여 어떤 signer가 서명했는지 확인합니다.
  int? findSignerIndexByMfp(String psbtBase64) {
    try {
      final psbt = Psbt.parse(psbtBase64);

      // signers 리스트를 순회하며 실제로 서명한 signer를 찾습니다.
      for (int i = 0; i < _vaultListItem.signers.length; i++) {
        if (psbt.isSigned(_vaultListItem.signers[i].keyStore)) {
          // TODO: 순서상으로는 정확하지 않을 수도 있음. 개선/검증 필요해보임
          return i;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  String getPsbtBase64() {
    return _signProvider.signedPsbtBase64 ?? _signProvider.unsignedPsbtBase64!;
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

  Future<void> updateSignerSource(int signerIndex, HardwareWalletType source) async {
    if (_vaultListItem.signers[signerIndex].signerSource != source) {
      await _walletProvider.updateExternalSignerSource(_vaultListItem.id, signerIndex, source);
      notifyListeners();
    }
  }

  /// [Krux, Keystone]외부 하드웨어 지갑에서 서명한 PSBT를 현재 PSBT에 추가합니다.
  void addSignSignature(String signedPsbtBase64) {
    try {
      final currentPsbt = Psbt.parse(_psbtForSigning);
      final scannedPsbt = Psbt.parse(signedPsbtBase64);

      // 각 input에 대해 스캔한 PSBT의 서명을 현재 PSBT에 추가
      for (int i = 0; i < currentPsbt.inputs.length && i < scannedPsbt.inputs.length; i++) {
        final scannedInput = scannedPsbt.inputs[i];
        final currentInput = currentPsbt.inputs[i];

        // 스캔한 input의 모든 partialSig를 현재 input에 추가
        if (scannedInput.partialSig != null && scannedInput.partialSig!.isNotEmpty) {
          for (var sig in scannedInput.partialSig!) {
            // 이미 존재하는 서명인지 확인 (중복 방지)
            bool alreadyExists =
                currentInput.partialSig?.any((existingSig) => existingSig.publicKey == sig.publicKey) ?? false;

            if (!alreadyExists) {
              currentInput.addPartialSig(sig.signature, sig.publicKey);
            }
          }
        }
      }

      // 서명을 추가한 후 PSBT를 base64로 변환하여 저장
      _psbtForSigning = currentPsbt.serialize();
    } catch (e) {
      debugPrint('addSignSignature error: $e');
      // 파싱 실패 시, 스캔한 PSBT를 그대로 사용
      _psbtForSigning = signedPsbtBase64;
    }
  }

  void saveSignedPsbt() {
    _signProvider.saveSignedPsbt(_psbtForSigning);
  }

  void saveUnsignedInputsMap(Map<String, String> inputsMap) {
    _signProvider.saveUnsignedInputsMap(inputsMap);
  }

  void saveUnsignedPubkeyMap(Map<String, String> pubkeyMap) {
    _signProvider.saveUnsignedPubkeyMap(pubkeyMap);
  }

  void saveSignedInputsMap(Map<String, String> signedInputsMap) {
    _signProvider.saveSignedInputsMap(signedInputsMap);
  }

  void saveSigningPublicKey(String publicKey) {
    _signProvider.saveSigningPublicKey(publicKey);
  }

  void reset() {
    _signProvider.resetSignedPsbt();
  }

  void resetAll() {
    _signProvider.resetPsbt();
    _signProvider.resetRecipientAddress();
    _signProvider.resetRecipientAmounts();
    _signProvider.resetSendingAmount();
    _signProvider.resetSignedPsbt();
    _signProvider.resetUnsignedInputsMap();
    _signProvider.resetUnsignedPubkeyMap();
    _signProvider.resetSignedInputsMap();
    _signProvider.resetSigningPublicKey();
  }

  HardwareWalletType? getSignerHwwType(int index) {
    return _vaultListItem.signers[index].signerSource;
  }

  String? getMultisigInfoQrData(HardwareWalletType hwwType) {
    switch (hwwType) {
      case HardwareWalletType.keystone3Pro:
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
    final regex = RegExp(r'\[([0-9A-Fa-f]{8})/[^\]]+\]((?:Z|V)pub[A-Za-z0-9]+)');

    final result = <String, String>{};

    for (final match in regex.allMatches(descriptor)) {
      final fp = match.group(1)!.toUpperCase(); // fingerprint
      final xpub = match.group(2)!; // Zpub or Vpub...
      result[fp] = xpub;
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
    final config = NormalizedMultisigConfig(
      name: name,
      requiredCount: _vaultListItem.requiredSignatureCount,
      signerBsms: _vaultListItem.signers.map((signer) => signer.signerBsms!).toList(),
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
}
