import 'dart:convert';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/model/data/singlesig_vault_list_item.dart';
import 'package:coconut_vault/model/data/vault_list_item_factory.dart';

class SinglesigVaultListItemFactory implements VaultListItemFactory {
  static const String secretField = 'secret';
  static const String passphraseField = 'passphrase';

  @override
  Future<SinglesigVaultListItem> create(
      {required String name,
      required int colorIndex,
      required int iconIndex,
      required Map<String, dynamic> secrets}) async {
    if (!secrets.containsKey(secretField)) {
      throw ArgumentError("The 'secrets' map must contain a 'secret' key.");
    }

    String secret = secrets[secretField];
    String passphrase = secrets[passphraseField] ?? '';

    final nextId = VaultListItemFactory.loadNextId();
    final newVault = SinglesigVaultListItem(
        id: nextId,
        name: name,
        colorIndex: colorIndex,
        iconIndex: iconIndex,
        secret: secret,
        passphrase: passphrase);
    await VaultListItemFactory.saveNextId(nextId + 1);

    return newVault;
  }

  @override
  SinglesigVaultListItem createFromJson(Map<String, dynamic> json) {
    final result = SinglesigVaultListItem.fromJson(json);

    if (result.vaultJsonString != null) {
      String vaultJson = result.vaultJsonString!;
      String? migrationResult = migrateVaultJsonStringForUpdate(vaultJson);
      if (migrationResult != null) {
        vaultJson = migrationResult;
      }
      result.coconutVault = SingleSignatureVault.fromJson(vaultJson);
    } else {
      Seed seed =
          Seed.fromMnemonic(result.secret, passphrase: result.passphrase);
      result.coconutVault = SingleSignatureVault.fromSeed(
        seed,
        AddressType.p2wpkh,
      );
    }

    return result;
  }

  // coconut_lib 0.7 -> 0.8, KeyStore에 addressType 프로퍼티가 추가되었습니다.
  static String? migrateVaultJsonStringForUpdate(String vaultJson) {
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
