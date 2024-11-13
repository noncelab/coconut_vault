import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/model/data/multisig_signer.dart';
import 'package:coconut_vault/model/data/multisig_vault_list_item.dart';
import 'package:coconut_vault/model/data/vault_list_item_factory.dart';

class MultisigVaultListItemFactory implements VaultListItemFactory {
  static const String coordinatorBsmsField = 'coordinatorBsms';
  static const String signersField = 'signers';
  static const String requiredSignatureCountField = 'requiredSignatureCount';
  static const String bsmsField = 'bsms';

  // 새로 생성 시
  @override
  Future<MultisigVaultListItem> create({
    required String name,
    required int colorIndex,
    required int iconIndex,
    required Map<String, dynamic> secrets,
  }) async {
    if (!secrets.containsKey(signersField)) {
      throw ArgumentError("The 'secrets' map must contain a 'signers' key.");
    }
    if (!secrets.containsKey(requiredSignatureCountField)) {
      throw ArgumentError(
          "The 'secrets' map must contain a 'requiredSignatureCountField' key.");
    }

    List<MultisigSigner> signers = secrets[signersField];
    int requiredSignatureCount = secrets[requiredSignatureCountField];

    final nextId = VaultListItemFactory.loadNextId();
    final newVault = MultisigVaultListItem(
        id: nextId,
        name: name,
        colorIndex: colorIndex,
        iconIndex: iconIndex,
        signers: signers,
        requiredSignatureCount: requiredSignatureCount);
    await VaultListItemFactory.saveNextId(nextId + 1);

    return newVault;
  }

  // 다른 볼트에서 복사 시
  Future<MultisigVaultListItem> createFromBsms({
    required String name,
    required int colorIndex,
    required int iconIndex,
    required Map<String, dynamic> secrets,
  }) async {
    if (!secrets.containsKey(bsmsField)) {
      throw ArgumentError("The 'secrets' map must contain a 'bsms' key.");
    }
    // TODO: field로 vault_model의 vaultList 전달해야 할지도 모름

    String bsms = secrets[bsmsField];
    List<MultisigSigner> signers = secrets[signersField];

    // TODO: 기존 지갑 정보와 bsms 값 비교해서, 일치하는 게 한개라도 있는지 확인해야 합니다.
    // TODO: 하나라도 있으면 VaultListItem 목록의 정보를 참조하여 signer 리스트를 만듭니다.

    final nextId = VaultListItemFactory.loadNextId();
    final newVault = MultisigVaultListItem.fromCoordinatorBsms(
      id: nextId,
      name: name,
      colorIndex: colorIndex,
      iconIndex: iconIndex,
      coordinatorBsms: bsms,
      signers: signers,
      // coconutVault 추가
    );
    await VaultListItemFactory.saveNextId(nextId + 1);

    return newVault;
  }

  // SecureStorage에서 복원 시
  @override
  MultisigVaultListItem createFromJson(Map<String, dynamic> json) {
    final result = MultisigVaultListItem.fromJson(json);
    // TODO: vaultJsonString이 nullable 할 수 있는 상황이 있을 수 있는지 확인하기
    if (result.vaultJsonString != null) {
      String vaultJson = result.vaultJsonString!;
      result.coconutVault = MultisignatureVault.fromJson(vaultJson);
    } else {
      // TODO:
      //String bsms = result.coordinatorBsms;
      //result.coconutVault = MultisignatureVault.fromCoordinatorBsms(bsms);
    }

    return result;
  }
}
