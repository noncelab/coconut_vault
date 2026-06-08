import 'package:coconut_vault/model/taproot/taproot_seed_key_identifier.dart';

// TODO: taproot_participant_card의 TaprootParticipantRole을 제거하고 이걸 사용.
enum TaprootParticipantType { keyPath, beneficiary }

class TaprootParticipant {
  final TaprootParticipantType type;
  final String masterFingerprint;
  final String extendedPublicKey;
  final bool isSeedStored;
  final bool isPassphraseSet;

  TaprootParticipant({
    required this.masterFingerprint,
    required this.type,
    required this.extendedPublicKey,
    required this.isSeedStored,
    required this.isPassphraseSet,
  });

  /// 상세화면이 이 participant의 seed를 secure storage에서 불러올 때 사용하는 키 식별자.
  TaprootSeedKeyIdentifier get seedKeyIdentifier => TaprootSeedKeyIdentifier(extendedPublicKey: extendedPublicKey);
}

class TaprootBeneficiaryParticipant extends TaprootParticipant {
  final int lockTime;
  final String scriptKey;

  TaprootBeneficiaryParticipant({
    required super.masterFingerprint,
    required super.type,
    required super.extendedPublicKey,
    required super.isSeedStored,
    required super.isPassphraseSet,
    required this.lockTime,
    required this.scriptKey,
  });
}
