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
}

class TaprootBeneficiaryParticipant extends TaprootParticipant {
  final int lockTime;

  TaprootBeneficiaryParticipant({
    required super.masterFingerprint,
    required super.type,
    required super.extendedPublicKey,
    required super.isSeedStored,
    required super.isPassphraseSet,
    required this.lockTime,
  });
}
