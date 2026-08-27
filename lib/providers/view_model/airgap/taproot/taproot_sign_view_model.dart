import 'dart:async';
import 'dart:convert';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/isolates/sign_isolates.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/taproot/taproot_participant.dart';
import 'package:coconut_vault/model/taproot/taproot_seed_key_identifier.dart';
import 'package:coconut_vault/model/taproot/taproot_vault_list_item.dart';
import 'package:coconut_vault/providers/sign_provider.dart';
import 'package:coconut_vault/providers/view_model/airgap/taproot/taproot_musig2_sign_session.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/utils/coconut/transaction_util.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/utils/print_util.dart';
import 'package:flutter/foundation.dart';

/// Taproot(P2TR) 지갑이 서명해야 하는 spending 종류.
/// - PSBT inputs에 tapLeafScript가 없으면 keyPath(internal key) 서명
/// - PSBT inputs 모두 tapLeafScript가 있으면 scriptPath(inheritance policy) 서명
enum TaprootSignType { singleKeyPath, musig2KeyPath, scriptPath }

enum TaprootScriptPathType { inheritance }

/// MultisigSignViewModel을 참고하여 작성한 Taproot 전용 서명 ViewModel.
///
/// 지원하는 Taproot 지갑 유형(상속 대비용):
///   1. keyPath 1개 / scriptPath(inheritancePolicy) 1개
///   2. keyPath 2개(MuSig2) / scriptPath(inheritancePolicy) 1개
///
/// 서명 가능 여부(요구사항 1, 2 공통):
///   - keyPath 서명(모든 input의 tapLeafScript == null)
///       - isParent              => 서명 가능
///       - !isParent             => 서명 불가능
///   - scriptPath 서명(모든 input의 tapLeafScript != null)
///       - scriptPathSeedInfos.isNotEmpty => 서명 가능
///       - scriptPathSeedInfos.isEmpty    => 서명 불가능
class TaprootSignViewModel extends ChangeNotifier {
  late final WalletProvider _walletProvider;
  late final SignProvider _signProvider;
  late final TaprootVaultListItem _vaultListItem;
  late final TaprootVault _coconutVault;
  final bool _isSigningOnlyMode;
  TaprootMusig2SignSession? _musig2SignSession;

  late String _psbtForSigning;
  bool _signStateInitialized = false;

  /// 현재 PSBT가 요구하는 서명 종류. initPsbtSignState()에서 결정됨.
  TaprootSignType? _signType;
  String? _resolveSignTypeErrorMessage;

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

  /// ViewModel 초기화 완료 여부. initPsbtSignState() 호출 후 true.
  bool get isInitialized => _signStateInitialized && _signType != null;

  /// 현재 PSBT의 서명 종류. [isInitialized]가 true일 때만 접근 가능.
  /// 미초기화 상태에서 접근 시 [StateError] 발생.
  TaprootSignType get signType {
    _ensureInitialized();
    return _signType!;
  }

  TaprootMusig2SignSession? get musig2SignSession => _musig2SignSession;

  String get firstRecipientAddress =>
      _signProvider.recipientAddress != null
          ? _signProvider.recipientAddress!
          : _signProvider.recipientAmounts!.keys.first;
  int get recipientCount => _signProvider.recipientAddress != null ? 1 : _signProvider.recipientAmounts!.length;
  int get sendingAmount => _signProvider.sendingAmount!;

  /// 현재 서명 종류에서 화면에 노출할 서명자 목록.
  /// keyPath: owners(keyPath participants), scriptPath: beneficiaries
  List<TaprootParticipant> get signers {
    if (!isInitialized) return const [];
    switch (_signType) {
      case TaprootSignType.singleKeyPath:
      case TaprootSignType.musig2KeyPath:
        return _vaultListItem.owners;
      case TaprootSignType.scriptPath:
        return _vaultListItem.beneficiaries;
      case null:
        return const [];
    }
  }

  List<bool> get signersApproved => _signerApproved;

  /// 요구사항 1, 2의 서명 가능/불가능 판단.
  /// - keyPath 서명: 이 지갑이 keyPath seed를 보유(isParent)해야 가능.
  /// - scriptPath 서명: 이 지갑이 scriptPath seed를 보유해야 가능.
  /// - 미초기화 상태: null 반환
  bool? get canSign {
    if (!isInitialized) return null;
    switch (_signType) {
      case TaprootSignType.singleKeyPath:
      case TaprootSignType.musig2KeyPath:
        return _vaultListItem.isParent;
      case TaprootSignType.scriptPath:
        return _vaultListItem.scriptPathSeedInfos.isNotEmpty;
      case null:
        return null;
    }
  }

  String? get exceptionMessage {
    if (_resolveSignTypeErrorMessage != null) return _resolveSignTypeErrorMessage;
    if (canSign != false) return null;

    switch (_signType) {
      case TaprootSignType.singleKeyPath:
      case TaprootSignType.musig2KeyPath:
        return t.exceptions.taproot.invalid_psbt_sign_type.key_path;
      case TaprootSignType.scriptPath:
        return t.exceptions.taproot.invalid_psbt_sign_type.script_path;
      case null:
        return null;
    }
  }

  /// 트랜잭션 완성에 필요한 서명 개수.
  /// - keyPath: 단일키(1) 또는 MuSig2(2) 모두 owners 전원이 서명해야 함.
  /// - scriptPath: inheritance policy의 beneficiary 1명이 서명.
  /// - 미초기화 상태: 0 반환
  int get requiredSignatureCount {
    if (!isInitialized) return 0;
    // isInitialized 체크로 _signType이 non-null임이 보장됨
    switch (_signType!) {
      case TaprootSignType.singleKeyPath:
      case TaprootSignType.musig2KeyPath:
        return signers.length;
      case TaprootSignType.scriptPath:
        return 1;
    }
  }

  int get remainingSignatures => requiredSignatureCount - _signerApproved.where((bool isApproved) => isApproved).length;

  bool get isSignatureCompleted {
    if (_signType == null) return false;
    if (_signType == TaprootSignType.musig2KeyPath &&
        _musig2SignSession != null &&
        !_musig2SignSession!.isFirstSigner) {
      return _musig2SignSession!.secondSignerStep == TaprootMusig2SecondSignerStep.signed;
    }
    return remainingSignatures <= 0;
  }

  /// index번째 서명자의 seed가 이 지갑에 저장되어 있는지(내부 서명 가능 여부).
  bool isSeedStored(int index) => signers[index].isSeedStored;

  bool getHasPassphrase(int index) => signers[index].isPassphraseSet;

  /// index번째 서명자의 seed를 secure storage에서 찾기 위한 키 식별자.
  TaprootSeedKeyIdentifier getSeedIdentifier(int index) => signers[index].seedKeyIdentifier;

  /// 서명자 버튼에 표시할 텍스트를 반환한다.
  /// - [isSignerApproved]: 이미 서명 완료된 서명자인지
  /// - [isInnerWallet]: 이 지갑에 seed가 저장된 내부 서명자인지
  String getSignerButtonText(int index, bool isSignerApproved, bool isInnerWallet) {
    if (isSignerApproved) {
      return t.sign_completion;
    }
    if (!isInnerWallet) {
      return t.add_sign;
    }

    // MuSig2 특수 처리
    if (_signType == TaprootSignType.musig2KeyPath && _musig2SignSession != null) {
      if (_musig2SignSession!.isFirstSigner) {
        return _getFirstSignerButtonText(_musig2SignSession!.firstSignerStep!);
      } else {
        return _getSecondSignerButtonText(_musig2SignSession!.secondSignerStep!);
      }
    }

    return t.sign;
  }

  String _getFirstSignerButtonText(TaprootMusig2FirstSignerStep step) {
    switch (step) {
      case TaprootMusig2FirstSignerStep.none:
        return t.taproot_sign_screen.musig2_sign.button.prepare_sign;
      case TaprootMusig2FirstSignerStep.localNonceCreated:
        return t.taproot_sign_screen.musig2_sign.button.ready;
      case TaprootMusig2FirstSignerStep.readyToLocalSign:
        return t.sign;
      case TaprootMusig2FirstSignerStep.completed:
        return t.sign_completion;
    }
  }

  String _getSecondSignerButtonText(TaprootMusig2SecondSignerStep step) {
    switch (step) {
      case TaprootMusig2SecondSignerStep.remoteNonceCreated:
        return t.taproot_sign_screen.musig2_sign.button.prepare_sign;
      case TaprootMusig2SecondSignerStep.signed:
        return t.sign_completion;
    }
  }

  // MARK: - 초기화

  /// PSBT에 이미 서명이 존재하는지 확인 (Taproot 전용)
  /// - keyPath: tapKeySig 존재 여부
  /// - scriptPath: tapScriptSig 존재 여부
  /// - MuSig2: muSig2PartialSigs 존재 여부
  bool _hasSignature(Psbt psbt) {
    for (final input in psbt.inputs) {
      // Key-path spending 서명 (P2TR key-path, single sig)
      if (input.tapKeySig != null) return true;

      // Script-path spending 서명 (P2TR script-path)
      if (input.tapScriptSig != null && input.tapScriptSig!.isNotEmpty) return true;

      // MuSig2 partial signatures
      if (input.muSig2PartialSigs != null && input.muSig2PartialSigs!.isNotEmpty) return true;
    }
    return false;
  }

  /// 화면 진입 직후 1회 호출.
  /// PSBT input의 tapLeafScript 여부로 서명 종류를 결정하고,
  /// 이미 서명된 서명자가 있으면 승인 상태로 반영한다.
  void initPsbtSignState() {
    if (_signStateInitialized) {
      throw StateError(
        'initPsbtSignState() has already been called. '
        'This method can only be invoked once per ViewModel instance.',
      );
    }
    _signStateInitialized = true;

    final psbt = _signProvider.psbt!;

    // 1) 서명 종류 결정 (tapLeafScript 존재 여부)
    try {
      _signType = _resolveSignType(psbt);
      _resolveSignTypeErrorMessage = null;
    } on FormatException catch (e) {
      _signType = null;
      _signerApproved = const [];
      _resolveSignTypeErrorMessage = e.message;
      notifyListeners();
      return;
    }

    // 2) 서명자 승인 상태 배열 초기화
    _signerApproved = List<bool>.filled(signers.length, false);

    // 3) MuSig2 서명 세션 초기화
    if (_signType == TaprootSignType.musig2KeyPath) {
      _musig2SignSession = TaprootMusig2SignSession(vault: _vaultListItem, initialPsbt: psbt);
    } else {
      if (_hasSignature(psbt)) {
        throw ArgumentError(t.exceptions.transaction.already_has_sign);
      }
    }

    notifyListeners();
  }

  /// PSBT inputs의 tapLeafScript 유무로 서명 종류를 판정.
  ///
  /// Taproot PSBT는 모든 input이 keyPath이거나 모든 input이 scriptPath여야 한다.
  /// 일부 input에만 tapLeafScript가 있으면 이 화면에서는 서명할 수 없는 PSBT로 본다.
  TaprootSignType _resolveSignType(Psbt psbt) {
    final hasTapLeafScript = psbt.inputs.map((input) => input.tapLeafScript != null);
    final hasAnyTapLeafScript = hasTapLeafScript.any((hasScript) => hasScript);
    final hasEveryTapLeafScript = hasTapLeafScript.every((hasScript) => hasScript);

    if (hasAnyTapLeafScript && !hasEveryTapLeafScript) {
      throw FormatException(t.taproot_sign_screen.exceptions.mixed_path_psbt_error);
    }

    if (hasEveryTapLeafScript) {
      return TaprootSignType.scriptPath;
    }

    bool hasMusig2Property = psbt.inputs[0].muSig2AggregatedPublicKey?.isNotEmpty == true;
    if (hasMusig2Property) {
      if (_vaultListItem.owners.length != 2) {
        throw StateError('서명할 수 없는 Musig2 지갑의 PSBT가 서명 대상이 되었음');
      }

      return TaprootSignType.musig2KeyPath;
    } else {
      if (_vaultListItem.owners.length != 1) {
        throw StateError('서명할 수 없는 단일 서명자 지갑의 PSBT가 서명 대상이 되었음');
      }

      return TaprootSignType.singleKeyPath;
    }
  }

  /// 초기화 완료 여부를 검증하는 방어적 헬퍼.
  /// 미초기화 상태에서 호출 시 명확한 [StateError]를 발생시킴.
  void _ensureInitialized() {
    if (!isInitialized) {
      throw StateError(
        'TaprootSignViewModel is not initialized. '
        'Call initPsbtSignState() before accessing signType or signing.',
      );
    }
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
    assert(!_isSigningOnlyMode);
    return await _walletProvider.getTaprootSecret(vaultId, getSeedIdentifier(index));
  }

  Future<Seed> getSeedInSigningOnlyMode(int index) async {
    assert(_isSigningOnlyMode);
    return await _walletProvider.getTaprootSeedInSigningOnlyMode(vaultId, getSeedIdentifier(index));
  }

  // MARK: - 서명 액션

  ///   - scriptPath: beneficiary keyStore로 tapLeafScript sighash 서명 (addSignatureToPsbt 1회)
  ///   - keyPath(단일키): internal key 서명 (addSignatureToPsbt 1회)
  Future<void> sign(int index, Seed seed) async {
    assert(_signType != TaprootSignType.musig2KeyPath, 'sign() should not be called for MuSig2.');
    _ensureInitialized();
    try {
      switch (signType) {
        case TaprootSignType.singleKeyPath:
          final signedPsbtBase64 = await compute(SignIsolates.signWithSingleKeyPath, [
            seed,
            _psbtForSigning,
            _vaultListItem.coordinatorBsms,
          ]);
          Logger.log('--> singleKeyPath signed:');
          printLongString(signedPsbtBase64);

          final signedPsbt = Psbt.parse(signedPsbtBase64);
          Logger.log('--> Signed PSBT inputs count: ${signedPsbt.inputs.length}');
          for (int i = 0; i < signedPsbt.inputs.length; i++) {
            Logger.log('--> Signed Input[$i] tapKeySig?: ${signedPsbt.inputs[i].tapKeySig != null}');
            Logger.log('--> Signed Input[$i] partialSig?: ${signedPsbt.inputs[i].partialSig?.isNotEmpty ?? false}');
            final derivationPathList = signedPsbt.inputs[i].derivationPathList;
            if (derivationPathList.isNotEmpty) {
              Logger.log('--> Signed Input[$i] derivationPath: ${derivationPathList.first}');
            }
          }

          try {
            final signedTx = signedPsbt.getSignedTransaction(AddressType.p2tr);
            Logger.log('--> getSignedTransaction 성공: ${signedTx.transactionHash}');
            _psbtForSigning = signedPsbtBase64;
          } catch (e) {
            Logger.error('--> getSignedTransaction 실패: $e');
            Logger.error('--> Signed PSBT 상세 정보:');
            Logger.error('--> Descriptor: ${_coconutVault.descriptor}');
            for (int i = 0; i < signedPsbt.inputs.length; i++) {
              final input = signedPsbt.inputs[i];
              Logger.error('--> Input[$i]:');
              Logger.error('  - witnessUtxo: ${input.witnessUtxo?.scriptPubKey}');
              Logger.error('  - tapKeySig: ${input.tapKeySig}');
              Logger.error('  - tapScriptSig: ${input.tapScriptSig}');
              Logger.error('  - partialSig: ${input.partialSig}');
            }
            rethrow;
          }
        case TaprootSignType.scriptPath:
          // 현재 앱에서 InheritancePolicy만 지원함
          final signedPsbtBase64 = await compute(SignIsolates.signWithBeneficiary, [
            seed,
            _psbtForSigning,
            _vaultListItem.coordinatorBsms,
          ]);
          // 서명 검증 후 할당
          final signedPsbt = Psbt.parse(signedPsbtBase64);
          signedPsbt.getSignedTransaction(AddressType.p2tr);
          _psbtForSigning = signedPsbtBase64;
        case TaprootSignType.musig2KeyPath:
          throw StateError('MuSig2 keyPath signing is not supported in sign()');
      }

      updateSignState(index);
    } finally {
      seed.wipe();
    }
  }

  // MARK: - MuSig2 서명

  /// MuSig2: 현재 signer가 first signer인지 확인
  bool isMusig2FirstSigner(int index) {
    if (_signType != TaprootSignType.musig2KeyPath || _musig2SignSession == null) {
      return false;
    }
    return _musig2SignSession!.isFirstSigner;
  }

  /// MuSig2 서명 완료 여부 확인
  bool isMusig2Completed() {
    if (_musig2SignSession == null) return true;
    if (_musig2SignSession!.isFirstSigner) {
      return _musig2SignSession!.firstSignerStep == TaprootMusig2FirstSignerStep.completed;
    } else {
      return _musig2SignSession!.secondSignerStep == TaprootMusig2SecondSignerStep.signed;
    }
  }

  /// MuSig2 First Signer: Step 1 - nonce 생성
  /// [seed]로 public nonce를 생성하고 세션 상태를 업데이트
  Future<String> musig2FirstSignerCreateNonce(int index, Seed seed) async {
    assert(_signType == TaprootSignType.musig2KeyPath);
    assert(_musig2SignSession != null);
    assert(_musig2SignSession!.isFirstSigner);

    _psbtForSigning = await _musig2SignSession!.addNonceForFirstSigner(seed);
    return _psbtForSigning;
  }

  void _updateAllSignState() {
    for (int i = 0; i < _signerApproved.length; i++) {
      _signerApproved[i] = true;
    }
    notifyListeners();
  }

  /// MuSig2 First Signer: 두 번째 폰의 QR(PSBT) 스캔 후 aggregation으로 최종 서명 완성
  /// [secondSignerPsbt]: 두 번째 폰이 QR로 공유한 PSBT (이미 nonce + partial sig 포함)
  Future<String> musig2FirstSignerFinalize(String secondSignerPsbt) async {
    assert(_signType == TaprootSignType.musig2KeyPath);
    assert(_musig2SignSession != null);
    assert(_musig2SignSession!.isFirstSigner);

    final finalizedPsbt = await _musig2SignSession!.finalizeByScanningSecondSignerPsbt(secondSignerPsbt);
    _psbtForSigning = finalizedPsbt;
    _updateAllSignState();
    return finalizedPsbt;
  }

  /// MuSig2 Second Signer: 첫 번째 폰 PSBT 스캔 후 nonce + partial signature 생성하여 PSBT에 추가
  /// [seed]: 두 번째 폰의 seed
  /// 반환: nonce와 partial signature가 추가된 PSBT (이 PSBT를 QR로 공유)
  Future<String> musig2SecondSignerSign(Seed seed) async {
    assert(_signType == TaprootSignType.musig2KeyPath);
    assert(_musig2SignSession != null);
    assert(!_musig2SignSession!.isFirstSigner);

    final signedPsbt = await _musig2SignSession!.signAsSecondSigner(seed);
    _psbtForSigning = signedPsbt;
    updateSignState(_musig2SignSession!.mySignerIndex);
    return signedPsbt;
  }

  /// MuSig2: First Signer의 local nonce 반환 (QR로 공유하기 위함)
  String? getMusig2LocalNonce() {
    return _musig2SignSession?.localPublicNonce;
  }

  /// MuSig2: 서명 완료된 PSBT 반환 (QR로 공유하기 위함)
  /// - Second Signer: 자신의 nonce + partial sig가 추가된 PSBT
  /// - First Signer: aggregation 완료된 최종 PSBT
  String? getMusig2SignedPsbtForQr() {
    return _musig2SignSession?.signedPsbtForQr;
  }

  // MARK: - 저장 / 리셋

  void saveSignedResult() {
    _signProvider.saveSignedPsbt(_psbtForSigning);
  }

  void clearSignedResultInSignProvider() {
    _signProvider.resetSignedPsbt();
    _signProvider.resetSignedRawTxHexString();
  }

  @override
  void dispose() {
    // dispose()는 ChangeNotifier 규약상 void이므로 await할 수 없습니다.
    // isolate 정리는 백그라운드에서 완료됩니다.
    unawaited(_musig2SignSession?.dispose() ?? Future.value());
    super.dispose();
  }
}
