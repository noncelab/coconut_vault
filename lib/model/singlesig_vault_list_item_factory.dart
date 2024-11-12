import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/model/singlesig_vault_list_item.dart';
import 'package:coconut_vault/model/vault_list_item_base.dart';
import 'package:coconut_vault/model/vault_list_item_factory.dart';

class SinglesigVaultListItemFactory implements VaultListItemFactory {
  static const String secretField = 'secret';
  static const String passphraseField = 'passphrase';

  @override
  Future<VaultListItemBase> create(
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
}
