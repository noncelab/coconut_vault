import 'package:coconut_lib/coconut_lib.dart';

bool isEquivalentExtendedPubKey(String xpub1, String xpub2) {
  ExtendedPublicKey pubkey1 = ExtendedPublicKey.parse(xpub1);
  ExtendedPublicKey pubkey2 = ExtendedPublicKey.parse(xpub2);

  return pubkey1.serialize(toXpub: true) == pubkey2.serialize(toXpub: true);
}
