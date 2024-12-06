import 'dart:convert';

import 'package:coconut_lib/coconut_lib.dart';

class SinglesigVaultListItemFactory {
  static const String secretField = 'secret';
  static const String passphraseField = 'passphrase';

  // coconut_lib 0.7 -> 0.8, KeyStore에 addressType 프로퍼티가 추가되었습니다.
  static String? migrateVaultJsonStringForCoconutLibUpdate(String vaultJson) {
    Map<String, dynamic> vaultMap = jsonDecode(vaultJson);
    Map<String, dynamic> keyStoreMap = jsonDecode(vaultMap['keyStore']);
    if (keyStoreMap['addressType'] == null) {
      keyStoreMap['addressType'] = AddressType.p2wpkh.toString();
      vaultMap['keyStore'] = jsonEncode(keyStoreMap);
      String updatedVaultJson = jsonEncode(vaultMap);
      return updatedVaultJson;
    }

    return null;
  }
}
