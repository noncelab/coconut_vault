import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/isolates/musig2_first_signer_isolate.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/taproot/taproot_participant.dart';
import 'package:coconut_vault/model/taproot/taproot_vault_list_item.dart';
import 'package:coconut_vault/providers/view_model/airgap/taproot/taproot_sign_exceptions.dart';
import 'package:coconut_vault/utils/coconut/transaction_util.dart';
import 'package:flutter/foundation.dart';

/// 첫 번째 폰(서명 시작자)의 MuSig2 서명 단계
/// none → localNonceCreated → readyToFinalize → completed
enum TaprootMusig2FirstSignerStep {
  none,
  localNonceCreated,
  readyToLocalSign, // 두 번째 폰의 QR 스캔 후 aggregation만 수행
  completed,
}

/// 두 번째 폰(서명 참여자)의 MuSig2 서명 단계
/// remoteNonceCreated(진입점) → signed → completed
enum TaprootMusig2SecondSignerStep {
  remoteNonceCreated, // 첫 번째 폰의 nonce가 이미 있는 상태로 진입
  signed, // nonce + partial 서명 완료 (QR에 표시됨)
}

/// MuSig2 서명 세션 (첫 번째/두 번째 폰 공용)
/// PSBT에 public nonce 존재 여부로 first/second signer 판별
class TaprootMusig2SignSession {
  final TaprootVaultListItem vault;
  final Psbt initialPsbt;

  TaprootMusig2FirstSignerStep? _firstSignerStep;
  TaprootMusig2SecondSignerStep? _secondSignerStep;

  /// 현재 PSBT 상태 (서명 진행에 따라 업데이트됨)
  String _currentPsbt;

  /// 생성된 local public nonce
  String? _localPublicNonce;

  /// 첫 번째 서명자의 KeyStore를 유지하기 위한 long-running isolate
  MuSig2FirstSignerIsolate? _firstSignerIsolate;

  String get _coordinatorBsms => vault.coordinatorBsms;

  /// 현재 세션이 첫 번째 부모 세션인지 여부
  bool get isFirstSigner => _firstSignerStep != null;

  TaprootMusig2FirstSignerStep? get firstSignerStep => _firstSignerStep;
  TaprootMusig2SecondSignerStep? get secondSignerStep => _secondSignerStep;

  /// 현재 PSBT (MuSig2 진행 상태 반영)
  String get currentPsbt => _currentPsbt;

  String? get localPublicNonce => _localPublicNonce;

  /// Second Signer: 서명 완료된 PSBT (QR로 공유)
  /// First Signer: aggregation 완료된 최종 PSBT
  String get signedPsbtForQr => _currentPsbt;

  String get myPublicKey => vault.keyPathSeedInfos[0].extendedPublicKey;
  TaprootParticipant get myOwner => vault.owners.singleWhere((element) => element.extendedPublicKey == myPublicKey);
  TaprootParticipant get otherOwner => vault.owners.singleWhere((element) => element.extendedPublicKey != myPublicKey);
  int get mySignerIndex => vault.owners.indexWhere((element) => element.extendedPublicKey == myPublicKey);

  TaprootMusig2SignSession({required this.vault, required this.initialPsbt}) : _currentPsbt = initialPsbt.serialize() {
    final vaultKeyStoreList = (vault.coconutVault as TaprootVault).keyStoreList;
    if (vaultKeyStoreList.length <= 1) {
      throw ArgumentError('This vault is not MuSig2');
    }
    final input = initialPsbt.inputs[0];
    final participantPubKeyCount = input.muSig2ParticipantPubkeys?.length ?? 0;
    final nonceCount = input.muSig2PubNonces?.length ?? 0;
    final sigCount = input.muSig2PartialSigs?.length ?? 0;
    if (input.muSig2AggregatedPublicKey?.isNotEmpty == false) {
      throw ArgumentError('MuSig2 aggregated public key is empty in PSBT');
    }
    if (participantPubKeyCount != vaultKeyStoreList.length) {
      throw ArgumentError(
        'MuSig2 participant public key count mismatch. $participantPubKeyCount / ${vaultKeyStoreList.length}',
      );
    }
    if (sigCount == vaultKeyStoreList.length) {
      throw UnsupportedTaprootPsbtException(message: t.exceptions.transaction.already_signed);
    }
    if (nonceCount < sigCount) {
      throw UnsupportedTaprootPsbtException(message: 'nonceCount: $nonceCount, sigCount: $sigCount');
    }

    if (nonceCount == 0) {
      _firstSignerStep = TaprootMusig2FirstSignerStep.none;
      return;
    }

    if (nonceCount == 1 && sigCount == 0) {
      // 내가 논스 한게 아니고 서명한게 아닌지 확인
      if (_getMyNonceFromPsbtInput(input) != null) {
        throw UnsupportedTaprootPsbtException(message: t.exceptions.transaction.muSig2.already_has_nonce_with_this);
      }

      _secondSignerStep = TaprootMusig2SecondSignerStep.remoteNonceCreated;
      return;
    }

    // 처리 가능한 조합(위 분기)에 해당하지 않는 비정상 상태는 명시적으로 거부합니다.
    // 여기서 예외를 던지지 않고 넘어가면 _firstSignerStep/_secondSignerStep이 모두 null로 남아
    // isFirstSigner가 false로 판정되고, 이후 secondSignerStep! 등 non-null 단언에서 크래시가 발생합니다.
    throw UnsupportedTaprootPsbtException(
      message: 'Unexpected MuSig2 PSBT state: nonceCount=$nonceCount, sigCount=$sigCount',
    );
  }

  // MARK: - First Signer 메서드

  /// 첫 번째 폰: seed로 public nonce 생성 및 PSBT에 추가
  /// [seed]로 서명자의 secret nonce와 public nonce를 생성하고 PSBT에 public nonce를 기록
  Future<String> addNonceForFirstSigner(Seed seed) async {
    // 이전 isolate가 남아있으면 정리 후 새로 시작합니다.
    await _firstSignerIsolate?.dispose();
    _firstSignerIsolate = MuSig2FirstSignerIsolate();
    await _firstSignerIsolate!.initialize();

    final result = await _firstSignerIsolate!.addPublicNonce(_coordinatorBsms, _currentPsbt, seed);

    _currentPsbt = result;
    _localPublicNonce = _getMyNonceFromPsbtInput(Psbt.parse(_currentPsbt).inputs[0]);
    _firstSignerStep = TaprootMusig2FirstSignerStep.localNonceCreated;
    return _currentPsbt;
  }

  /// xpub과 PSBT tapBip32Derivation에서 해당 masterFingerprint의 derivation path를 찾아
  /// child compressed pubkey hex를 반환
  String _deriveChildPubKeyHex(PsbtInput psbtInput, String xpub, String masterFingerprint) {
    final derivation = psbtInput.tapBip32Derivation?.firstWhere(
      (d) => d.masterFingerprint == masterFingerprint.toUpperCase(),
      orElse: () => throw Exception('Participant not found in PSBT'),
    );
    final extPubKey = ExtendedPublicKey.parse(xpub);
    final hdWallet = HDWallet.fromPublicKey(extPubKey.publicKey, extPubKey.chainCode);
    return Codec.encodeHex(
      hdWallet.derive(derivation!.isChange ? 1 : 0).derive(derivation.accountIndex).neutered().publicKey,
    );
  }

  /// PsbtInput에서 내가 추가한 nonce 값을 반환. 없으면 null.
  String? _getMyNonceFromPsbtInput(PsbtInput psbtInput) {
    final myPubKeyHex = _deriveChildPubKeyHex(psbtInput, myOwner.extendedPublicKey, myOwner.masterFingerprint);
    return psbtInput.muSig2PubNonces?.entries.where((e) => e.key.startsWith(myPubKeyHex)).firstOrNull?.value;
  }

  bool hasOtherSigned(PsbtInput psbtInput, String otherXpub, String otherMasterFingerprint) {
    final childPubKeyHex = _deriveChildPubKeyHex(psbtInput, otherXpub, otherMasterFingerprint);
    // muSig2PartialSigs의 publicKey: participantPubKey + aggregatedPublicKey + sigHash 이므로 startsWith으로 판별
    return psbtInput.muSig2PartialSigs?.any((sig) => sig.publicKey.startsWith(childPubKeyHex)) ?? false;
  }

  /// [scannedPsbt]: 두 번째 폰이 QR로 공유한 PSBT
  /// 검증 실패 시 FormatException throw
  void _validateSecondSignerPsbt(String scannedPsbt) {
    assert(isFirstSigner);
    final current = Psbt.parse(_currentPsbt);
    Psbt? scanned;
    try {
      scanned = Psbt.parse(scannedPsbt);
    } catch (e) {
      throw FormatException(t.taproot_sign_screen.exceptions.format_exception.invalid_psbt_format);
    }

    _validateTransactionBody(current, scanned);
    _validateParticipants(current, scanned);
    _validateSignatures(scanned);
    _validateNonceIntegrity(scanned);
  }

  /// 트랜잭션 본문 동일성 검증 (txid, input/output 개수 및 내용)
  void _validateTransactionBody(Psbt current, Psbt scanned) {
    final currentTx = current.unsignedTransaction!;
    final scannedTx = scanned.unsignedTransaction!;
    if (!isSameTransactionBody(currentTx, scannedTx)) {
      throw FormatException(t.taproot_sign_screen.exceptions.format_exception.transaction_mismatch);
    }
  }

  /// 같은 MuSig2 vault의 PSBT인지 확인 (참여자 pubkey, aggregated pubkey)
  void _validateParticipants(Psbt current, Psbt scanned) {
    for (int i = 0; i < scanned.inputs.length; i++) {
      final currentInput = current.inputs[i];
      final scannedInput = scanned.inputs[i];

      if (currentInput.muSig2AggregatedPublicKey != scannedInput.muSig2AggregatedPublicKey) {
        throw FormatException(t.taproot_sign_screen.exceptions.format_exception.different_wallet);
      }

      final currentParticipants = currentInput.muSig2ParticipantPubkeys?.toSet();
      final scannedParticipants = scannedInput.muSig2ParticipantPubkeys?.toSet();
      if (currentParticipants == null ||
          scannedParticipants == null ||
          !currentParticipants.containsAll(scannedParticipants) ||
          !scannedParticipants.containsAll(currentParticipants)) {
        throw FormatException(t.taproot_sign_screen.exceptions.format_exception.participant_mismatch);
      }
    }
  }

  /// 두 번째 폰의 partial signature 존재 여부 확인
  void _validateSignatures(Psbt scanned) {
    for (int i = 0; i < scanned.inputs.length; i++) {
      final scannedInput = scanned.inputs[i];
      if (scannedInput.muSig2PartialSigs == null || scannedInput.muSig2PartialSigs!.isEmpty) {
        throw FormatException(t.taproot_sign_screen.exceptions.format_exception.no_signature);
      }

      final hasOtherSignerSig = hasOtherSigned(
        scannedInput,
        otherOwner.extendedPublicKey,
        otherOwner.masterFingerprint,
      );
      if (!hasOtherSignerSig) {
        throw FormatException(t.taproot_sign_screen.exceptions.format_exception.no_other_signer_sig);
      }
    }
  }

  /// 내가 추가한 nonce 무결성 확인
  void _validateNonceIntegrity(Psbt scanned) {
    for (int i = 0; i < scanned.inputs.length; i++) {
      final myNonceInScanned = _getMyNonceFromPsbtInput(scanned.inputs[i]);
      if (myNonceInScanned == null) {
        throw FormatException(t.taproot_sign_screen.exceptions.format_exception.nonce_missing);
      }
      if (myNonceInScanned != _localPublicNonce) {
        throw FormatException(t.taproot_sign_screen.exceptions.format_exception.nonce_tampered);
      }
    }
  }

  /// 첫 번째 폰: 두 번째 폰의 QR을 스캔하여 PSBT에서 nonce와 partial sig 추출 후 aggregation
  /// [secondSignerPsbt]: 두 번째 폰이 QR로 공유한 PSBT (이미 nonce + partial sig 포함)
  ///
  /// 첫 번째 서명자의 secret nonce는 [_firstSignerIsolate]가 유지하는 [KeyStore]에
  /// 살아있으므로 추가 seed가 필요하지 않습니다.
  Future<String> finalizeByScanningSecondSignerPsbt(String secondSignerPsbt) async {
    _validateSecondSignerPsbt(secondSignerPsbt);
    if (_firstSignerIsolate == null) {
      throw StateError('First signer nonce was not created. Call addNonceForFirstSigner first.');
    }

    final result = await _firstSignerIsolate!.addSignature(secondSignerPsbt);
    await _firstSignerIsolate!.dispose();
    _firstSignerIsolate = null;

    _currentPsbt = result;
    // 검증
    Psbt.parse(_currentPsbt).getSignedTransaction(AddressType.p2tr);
    _firstSignerStep = TaprootMusig2FirstSignerStep.completed;
    return _currentPsbt;
  }

  // MARK: - Second Signer 메서드

  static String _createNonceAndSignInIsolate(Map<String, dynamic> params) {
    final vault = TaprootVault.fromCoordinatorBsms(params['bsms']);
    vault.bindSeedToKeyStore(params['seed']);
    final psbtWithNonce = vault.addPublicNonce(params['psbt']);
    return vault.addSignatureToPsbt(psbtWithNonce);
  }

  /// 두 번째 폰: 첫 번째 폰의 PSBT로 초기화 후 seed로 nonce + partial signature 생성하여 PSBT에 추가
  /// [psbtWithRemoteNonce]: 첫 번째 폰의 QR을 스캔한 PSBT (이미 첫 번째 폰의 nonce 포함)
  /// [seed]: 두 번째 폰의 seed
  /// 반환: nonce와 partial signature가 추가된 PSBT (이 PSBT를 QR로 공유)
  Future<String> signAsSecondSigner(Seed seed) async {
    final result = await compute(_createNonceAndSignInIsolate, {
      'bsms': _coordinatorBsms,
      'psbt': _currentPsbt,
      'seed': seed,
    });

    _currentPsbt = result;
    _secondSignerStep = TaprootMusig2SecondSignerStep.signed;
    return _currentPsbt; // 이 PSBT를 QR로 공유
  }

  /// 세션에서 사용 중인 isolate 및 민감 메모리를 정리합니다.
  /// 화면이 종료되거나 서명 흐름이 취소될 때 호출해야 합니다.
  Future<void> dispose() async {
    await _firstSignerIsolate?.dispose();
    _firstSignerIsolate = null;
  }
}
