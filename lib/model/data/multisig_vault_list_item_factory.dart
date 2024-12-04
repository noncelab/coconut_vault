import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/model/data/multisig_signer.dart';
import 'package:coconut_vault/model/data/multisig_signer_factory.dart';
import 'package:coconut_vault/model/data/multisig_vault_list_item.dart';
import 'package:coconut_vault/model/data/vault_list_item_base.dart';
import 'package:coconut_vault/model/data/vault_list_item_factory.dart';

class MultisigVaultListItemFactory implements VaultListItemFactory {
  static const String coordinatorBsmsField = 'coordinatorBsms';
  static const String signersField = 'signers';
  static const String requiredSignatureCountField = 'requiredSignatureCount';
  static const String bsmsField = 'bsms';
  static const String vaultListField = 'vaultList';

  // 다른 볼트에서 복사 시
  Future<MultisigVaultListItem> createFromBsms({
    required int nextId,
    required String name,
    required int colorIndex,
    required int iconIndex,
    required Map<String, String> namesMap,
    required Map<String, dynamic> secrets,
  }) async {
    if (!secrets.containsKey(bsmsField)) {
      throw ArgumentError("The 'secrets' map must contain a 'bsms' key.");
    }
    if (!secrets.containsKey(vaultListField)) {
      throw ArgumentError("The 'secrets' map must contain a 'vaultList' key.");
    }

    String bsms = secrets[bsmsField];
    List<VaultListItemBase> vaultList = secrets[vaultListField];

    // signer 리스트 생성
    List<MultisigSigner> signers =
        MultisigSignerFactory.createSignersForMultisignatureVaultWhenImport(
            multisigVault: MultisignatureVault.fromCoordinatorBsms(bsms),
            namesMap: namesMap,
            vaultList: vaultList);

    final newVault = MultisigVaultListItem.fromCoordinatorBsms(
      id: nextId,
      name: name,
      colorIndex: colorIndex,
      iconIndex: iconIndex,
      coordinatorBsms: bsms,
      signers: signers,
    );

    return newVault;
  }

  // SecureStorage에서 복원 시
  @override
  MultisigVaultListItem createFromJson(Map<String, dynamic> json) {
    final result = MultisigVaultListItem.fromJson(json);

    // assert(result.vaultJsonString != null);

    // result.coconutVault = MultisignatureVault.fromJson(result.vaultJsonString!);

    return result;
  }
}
