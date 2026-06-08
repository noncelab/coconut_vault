import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/taproot/taproot_participant.dart';
import 'package:coconut_vault/model/taproot/taproot_seed_key_identifier.dart';
import 'package:coconut_vault/model/taproot/taproot_vault_list_item.dart';
import 'package:coconut_vault/providers/sign_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/utils/coconut/transaction_util.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:flutter/foundation.dart';

/// Taproot(P2TR) 지갑이 서명해야 하는 spending 종류.
/// - PSBT input에 tapLeafScript가 없으면 keyPath(internal key) 서명
/// - PSBT input에 tapLeafScript가 있으면 scriptPath(inheritance policy) 서명
enum TaprootSignType { keyPath, scriptPath }

/// MultisigSignViewModel을 참고하여 작성한 Taproot 전용 서명 ViewModel.
///
/// 지원하는 Taproot 지갑 유형(상속 대비용):
///   1. keyPath 1개 / scriptPath(inheritancePolicy) 1개
///   2. keyPath 2개(MuSig2) / scriptPath(inheritancePolicy) 1개
///
/// 서명 가능 여부(요구사항 1, 2 공통):
///   - keyPath 서명(tapLeafScript == null)
///       - isParent              => 서명 가능
///       - !isParent             => 서명 불가능
///   - scriptPath 서명(tapLeafScript != null)
///       - scriptPathSeedInfos.isNotEmpty => 서명 가능
///       - scriptPathSeedInfos.isEmpty    => 서명 불가능
class TaprootSignViewModel extends ChangeNotifier {
  late final WalletProvider _walletProvider;
  late final SignProvider _signProvider;
  late final TaprootVaultListItem _vaultListItem;
  late final TaprootVault _coconutVault;
  final bool _isSigningOnlyMode;

  late String _psbtForSigning;
  String? _signedRawTxHex;
  bool _signStateInitialized = false;

  /// 현재 PSBT가 요구하는 서명 종류. initPsbtSignState()에서 결정됨.
  TaprootSignType? _signType;

  /// 활성화된 서명자(keyPath: owners / scriptPath: beneficiaries)의 승인 상태.
  late List<bool> _signerApproved;

  TaprootSignViewModel(this._walletProvider, this._signProvider, this._isSigningOnlyMode) {
    _vaultListItem = _signProvider.vaultListItem! as TaprootVaultListItem;
    _coconutVault = _vaultListItem.coconutVault as TaprootVault;
    _psbtForSigning = _signProvider.unsignedPsbtBase64!;
    _signerApproved = const [];
  }

  // MARK: - Getters

  int get vaultId => _vaultListItem.id;
  String get walletName => _vaultListItem.name;
  String get psbtForSigning => _psbtForSigning;
  bool get isSigningOnlyMode => _isSigningOnlyMode;
  String get unsignedPsbtBase64 => _signProvider.unsignedPsbtBase64!;

  /// 서명 isolate 등에서 사용할 coconut_lib TaprootVault 인스턴스.
  TaprootVault get coconutVault => _coconutVault;

  TaprootSignType? get signType => _signType;
  bool get isKeyPathSign => _signType == TaprootSignType.keyPath;
  bool get isScriptPathSign => _signType == TaprootSignType.scriptPath;

  String get firstRecipientAddress =>
      _signProvider.recipientAddress != null
          ? _signProvider.recipientAddress!
          : _signProvider.recipientAmounts!.keys.first;
  int get recipientCount => _signProvider.recipientAddress != null ? 1 : _signProvider.recipientAmounts!.length;
  int get sendingAmount => _signProvider.sendingAmount!;

  /// 현재 서명 종류에서 화면에 노출할 서명자 목록.
  /// keyPath: owners(keyPath participants), scriptPath: beneficiaries
  List<TaprootParticipant> get signers =>
      _signType == TaprootSignType.scriptPath ? _vaultListItem.beneficiaries : _vaultListItem.owners;

  List<bool> get signersApproved => _signerApproved;

  /// 요구사항 1, 2의 서명 가능/불가능 판단.
  /// - keyPath 서명: 이 지갑이 keyPath seed를 보유(isParent)해야 가능.
  /// - scriptPath 서명: 이 지갑이 scriptPath seed를 보유해야 가능.
  bool get canSign {
    switch (_signType) {
      case TaprootSignType.keyPath:
        return _vaultListItem.isParent;
      case TaprootSignType.scriptPath:
        return _vaultListItem.scriptPathSeedInfos.isNotEmpty;
      case null:
        return false;
    }
  }

  /// 트랜잭션 완성에 필요한 서명 개수.
  /// - keyPath: 단일키(1) 또는 MuSig2(2) 모두 owners 전원이 서명해야 함.
  /// - scriptPath: inheritance policy의 beneficiary 1명이 서명.
  int get requiredSignatureCount => _signType == TaprootSignType.scriptPath ? 1 : signers.length;

  int get remainingSignatures => requiredSignatureCount - _signerApproved.where((bool isApproved) => isApproved).length;

  bool get isSignatureCompleted => remainingSignatures <= 0 || _signedRawTxHex != null;

  /// index번째 서명자의 seed가 이 지갑에 저장되어 있는지(내부 서명 가능 여부).
  bool isSeedStored(int index) => signers[index].isSeedStored;

  /// index번째 서명자에 passphrase가 설정되어 있는지.
  bool getHasPassphrase(int index) => signers[index].isPassphraseSet;

  /// index번째 서명자의 seed를 secure storage에서 찾기 위한 키 식별자.
  TaprootSeedKeyIdentifier getSeedIdentifier(int index) => signers[index].seedKeyIdentifier;

  // MARK: - 초기화

  /// 화면 진입 직후 1회 호출.
  /// PSBT input의 tapLeafScript 여부로 서명 종류를 결정하고,
  /// 이미 서명된 서명자가 있으면 승인 상태로 반영한다.
  void initPsbtSignState() {
    assert(!_signStateInitialized); // 오직 한번만 호출
    _signStateInitialized = true;

    final psbt = _signProvider.psbt!;

    // 1) 서명 종류 결정 (tapLeafScript 존재 여부)
    _signType = _resolveSignType(psbt);

    // 2) 서명자 승인 상태 배열 초기화
    _signerApproved = List<bool>.filled(signers.length, false);

    // TODO: 이미 서명된 input이 있는 경우 해당 서명자를 승인 상태로 반영.
    //   - keyPath(단일/ MuSig2): tapKeySig 또는 MuSig2 partial sig 보유 여부 확인
    //   - scriptPath: tapScriptSig 보유 여부 확인
    //   (multisig의 _updateSignerApproved처럼 input0의 서명-publicKey 매핑 필요)
    _syncAlreadySignedState(psbt);

    notifyListeners();
  }

  /// PSBT input[0]의 tapLeafScript 유무로 서명 종류를 판정.
  TaprootSignType _resolveSignType(Psbt psbt) {
    final firstInput = psbt.inputs[0];
    return firstInput.tapLeafScript == null ? TaprootSignType.keyPath : TaprootSignType.scriptPath;
  }

  /// TODO: 스캔 진입 시점에 이미 일부 서명이 포함된 PSBT일 수 있으므로
  /// 서명자별 승인 상태를 동기화하는 로직 구현 필요.
  void _syncAlreadySignedState(Psbt psbt) {
    // 구현 예정 (coconut_lib의 tapKeySig / tapScriptSig / muSig2PartialSig 조회 활용)
  }

  void updateSignState(int? index) {
    if (index != null) {
      _signerApproved[index] = true;
      notifyListeners();
    }
  }

  // MARK: - Seed 조회

  /// 안전 저장 모드에서 index번째 서명자의 secret(mnemonic) 조회.
  Future<Uint8List> getSecret(int index) async {
    return await _walletProvider.getTaprootSecret(vaultId, getSeedIdentifier(index));
  }

  // MARK: - 서명 액션

  /// 안전 저장 모드 서명.
  ///
  /// TODO: Taproot 서명 isolate 구현 필요. multisig의 SignIsolates.addSignatureToPsbtWithMultisigVault에 대응.
  ///   keyPath/scriptPath 및 단일키/ MuSig2 여부에 따라 처리가 달라진다.
  ///   - scriptPath: beneficiary keyStore로 tapLeafScript sighash 서명 (addSignatureToPsbt 1회)
  ///   - keyPath(단일키): internal key 서명 (addSignatureToPsbt 1회)
  ///   - keyPath(MuSig2 2키): public nonce 라운드(addPublicNonce) 후 partial 서명 → 두 서명자 nonce 교환 필요
  Future<void> sign(int index, Seed seed) async {
    try {
      // TODO: compute(SignIsolates.addSignatureToPsbtWithTaprootVault, [...]) 형태로 구현
      throw UnimplementedError('Taproot signing(sign) is not implemented yet');
      // ignore: dead_code
      // updateSignState(index);
    } finally {
      seed.wipe();
    }
  }

  /// 서명 전용 모드 서명.
  ///
  /// TODO: getTaprootSeedInSigningOnlyMode로 seed를 얻어 sign()과 동일 로직으로 서명.
  Future<void> signPsbtInSigningOnlyMode(int index) async {
    assert(_isSigningOnlyMode);
    Seed? seed;
    try {
      seed = await _walletProvider.getTaprootSeedInSigningOnlyMode(vaultId, getSeedIdentifier(index));
      // TODO: Taproot 서명 isolate 호출 후 updateSignState(index)
      throw UnimplementedError('Taproot signing(signPsbtInSigningOnlyMode) is not implemented yet');
    } finally {
      seed?.wipe();
    }
  }

  // MARK: - 외부(QR) 서명 결과 반영

  void saveSignedRawTxHex(String hexString) {
    _signedRawTxHex = hexString;
  }

  /// 스캔된 외부 서명 PSBT를 현재 PSBT에 병합.
  ///
  /// TODO: multisig의 onScannedPsbt를 참고하되 Taproot 서명 필드(tapKeySig/tapScriptSig/muSig2)에 맞게 구현.
  void onScannedPsbt(String scannedData, {bool isOverwrite = false}) {
    final exceptionMessages = t.multisig_sign_screen.exception;
    try {
      // 1) unsignedTransaction 동일성 검증
      // 2) Taproot 서명 정보 병합 및 서명자 승인 상태 업데이트
      // 3) _psbtForSigning 갱신
      throw UnimplementedError('Taproot onScannedPsbt is not implemented yet');
    } on FormatException {
      rethrow;
    } catch (e) {
      Logger.error('onScannedPsbt error: $e');
      throw FormatException(exceptionMessages.invalid_sign_error);
    }
  }

  /// Raw signed transaction(hex)이 스캔된 경우는 서명이 완료된 상태.
  ///
  /// TODO: multisig의 validateRawSignedTransaction을 참고하여 Taproot witness 구조에 맞게 검증.
  void validateRawSignedTransaction(String rawSignedTransaction) {
    final exceptionMessages = t.multisig_sign_screen.exception;
    try {
      if (!rawSignedTransaction.substring(8).startsWith(rawTxSegwitField)) {
        throw FormatException(exceptionMessages.not_segwit);
      }
      // TODO: Taproot witness(서명) 개수/유효성 검증 로직 구현
      throw UnimplementedError('Taproot validateRawSignedTransaction is not implemented yet');
    } on FormatException {
      rethrow;
    } catch (e) {
      Logger.error('validateRawSignedTransaction error: $e');
      throw FormatException(exceptionMessages.invalid_sign_error);
    }
  }

  /// 스캔된 PSBT/RawTx의 트랜잭션 본문이 현재 서명중인 PSBT와 동일한지 확인.
  bool hasSameTransactionBody(String scannedData) {
    try {
      final currentTx = Psbt.parse(_psbtForSigning).unsignedTransaction!;
      final scannedTx = Psbt.parse(scannedData).unsignedTransaction!;
      return _isTransactionBodySame(currentTx, scannedTx);
    } catch (e) {
      Logger.error('hasSameTransactionBody error: $e');
      return false;
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

  // MARK: - 저장 / 리셋

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
}
