import 'dart:typed_data';

typedef SecretPassphrasePair = ({Uint8List secret, Uint8List? passphrase});
typedef InheritancePolicyInput = ({String descriptor, int timestamp});

enum TaprootSeedRole { keyPath, beneficiary }

abstract class TaprootSeedKeyIdentifier {
  String get extendedPublicKey;
  TaprootSeedRole get role;
}

class TaprootSeedKeyIdentifierImpl implements TaprootSeedKeyIdentifier {
  @override
  final String extendedPublicKey;
  @override
  final TaprootSeedRole role;

  TaprootSeedKeyIdentifierImpl({required this.extendedPublicKey, required this.role});
}

class TaprootSeedInfoForAdd implements TaprootSeedKeyIdentifier {
  final SecretPassphrasePair secretPassphrasePair;
  @override
  final String extendedPublicKey;
  @override
  final TaprootSeedRole role;

  TaprootSeedInfoForAdd({required this.secretPassphrasePair, required this.extendedPublicKey, required this.role});
}
