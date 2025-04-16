import 'dart:convert';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/managers/isolate_manager.dart';
import 'package:coconut_vault/utils/isolate_handler.dart';
import 'package:json_annotation/json_annotation.dart';

part 'multisig_vault_list_item.g.dart'; // 생성될 파일 이름 $ dart run build_runner build

@JsonSerializable(ignoreUnannotated: true)
class MultisigVaultListItem extends VaultListItemBase {
  MultisigVaultListItem(
      {required super.id,
      required super.name,
      required super.colorIndex,
      required super.iconIndex,
      required this.signers,
      required this.requiredSignatureCount,
      String? coordinatorBsms,
      super.vaultJsonString})
      : super(vaultType: WalletType.multiSignature) {
    coconutVault = MultisignatureVault.fromKeyStoreList(
        signers.map((signer) => signer.keyStore).toList(), requiredSignatureCount,
        addressType: AddressType.p2wsh);

    name = name.replaceAll('\n', ' ');
    this.coordinatorBsms =
        coordinatorBsms ?? (coconutVault as MultisignatureVault).getCoordinatorBsms();
  }

  @JsonKey(name: "signers")
  final List<MultisigSigner> signers;

  @JsonKey(name: "coordinatorBsms", includeIfNull: false)
  late final String? coordinatorBsms;

  // json_serialization가 기본 생성자를 사용해서 추가함
  // 필요 서명 개수
  @JsonKey(name: "requiredSignatureCount")
  late final int requiredSignatureCount;

  @override
  Future<bool> canSign(String psbt) async {
    var isolateHandler = IsolateHandler<List<dynamic>, bool>(canSignToPsbtIsolate);
    try {
      await isolateHandler.initialize(initialType: InitializeType.canSign);
      bool canSignToPsbt = await isolateHandler.run([coconutVault, psbt]);
      return canSignToPsbt;
    } finally {
      isolateHandler.dispose();
    }
  }

  @override
  String getWalletSyncString() {
    final newSigners = signers
        .map((signer) => {
              'innerVaultId': signer.innerVaultId,
              'name': signer.name,
              'iconIndex': signer.iconIndex,
              'colorIndex': signer.colorIndex,
              'memo': signer.memo,
            })
        .toList();

    Map<String, dynamic> json = {
      'name': name,
      'colorIndex': colorIndex,
      'iconIndex': iconIndex,
      'descriptor': coconutVault.descriptor,
      'requiredSignatureCount': requiredSignatureCount,
      'signers': newSigners,
    };

    return jsonEncode(json);
  }

  @override
  Map<String, dynamic> toJson() => _$MultisigVaultListItemToJson(this);

  factory MultisigVaultListItem.fromJson(Map<String, dynamic> json) {
    json['vaultType'] = _$WalletTypeEnumMap[WalletType.multiSignature];
    return _$MultisigVaultListItemFromJson(json);
  }
}
