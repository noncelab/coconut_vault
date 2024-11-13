import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/model/data/multisig_signer.dart';
import 'package:coconut_vault/model/data/multisig_vault_list_item.dart';
import 'package:coconut_vault/model/data/vault_list_item_factory.dart';

class MultisigVaultListItemFactory implements VaultListItemFactory {
  static const String coordinatorBsmsField = 'coordinatorBsms';
  static const String signersField = 'signers';

  @override
  Future<MultisigVaultListItem> create(
      {required String name,
      required int colorIndex,
      required int iconIndex,
      required Map<String, dynamic> secrets}) async {
    if (!secrets.containsKey(coordinatorBsmsField)) {
      throw ArgumentError(
          "The 'secrets' map must contain a 'coordinatorBsms' key.");
    }
    if (!secrets.containsKey(signersField)) {
      throw ArgumentError("The 'secrets' map must contain a 'signers' key.");
    }

    String coordinatorBsms = secrets[coordinatorBsmsField];
    List<MultisigSigner> signers = secrets[signersField];

    final nextId = VaultListItemFactory.loadNextId();
    final newVault = MultisigVaultListItem(
        id: nextId,
        name: name,
        colorIndex: colorIndex,
        iconIndex: iconIndex,
        coordinatorBsms: coordinatorBsms,
        signers: signers);
    await VaultListItemFactory.saveNextId(nextId + 1);

    return newVault;
  }

  @override
  MultisigVaultListItem createFromJson(Map<String, dynamic> json) {
    final result = MultisigVaultListItem.fromJson(json);

    if (result.vaultJsonString != null) {
      String vaultJson = result.vaultJsonString!;
      result.coconutVault = MultisignatureVault.fromJson(vaultJson);
    } else {
      String bsms = result.coordinatorBsms;
      result.coconutVault = MultisignatureVault.fromCoordinatorBsms(bsms);
    }

    return result;
  }
}
