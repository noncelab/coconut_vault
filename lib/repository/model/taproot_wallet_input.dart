import 'dart:typed_data';

typedef SecretPassphrasePair = ({Uint8List secret, Uint8List? passphrase});
typedef InheritancePolicyInput = ({String descriptor, int timestamp});

class TaprootSeedInfoForSave {
  final SecretPassphrasePair secretPassphrasePair;
  final String extendedPublicKey;

  TaprootSeedInfoForSave({required this.secretPassphrasePair, required this.extendedPublicKey});
}
