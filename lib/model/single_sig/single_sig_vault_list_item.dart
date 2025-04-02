import 'dart:convert';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/managers/isolate_manager.dart';
import 'package:coconut_vault/utils/isolate_handler.dart';
import 'package:json_annotation/json_annotation.dart';

part 'single_sig_vault_list_item.g.dart'; // 생성될 파일 이름 $ dart run build_runner build

@JsonSerializable(ignoreUnannotated: true)
class SingleSigVaultListItem extends VaultListItemBase {
  static const String secretField = 'secret';
  static const String passphraseField = 'passphrase';
  static const String signerBsmsField = 'signerBsms';

  SingleSigVaultListItem({
    required super.id,
    required super.name,
    required super.colorIndex,
    required super.iconIndex,
    required String secret,
    required String passphrase,
    this.signerBsms,
    this.linkedMultisigInfo,
    super.vaultJsonString,
  }) : super(vaultType: WalletType.singleSignature) {
    Seed seed = Seed.fromMnemonic(secret, passphrase: passphrase);
    coconutVault =
        SingleSignatureVault.fromSeed(seed, addressType: AddressType.p2wpkh);
    final singlesigVault = coconutVault as SingleSignatureVault;

    /// 추후 속도 개선을 위한 로직 고려
    signerBsms = singlesigVault.getSignerBsms(AddressType.p2wsh, name);
    singlesigVault.keyStore.seed = null;

    name = name.replaceAll('\n', ' ');
  }

  /// @Deprecated
  @JsonKey(name: secretField)
  String? secret;

  /// @Deprecated
  @JsonKey(name: passphraseField)
  String? passphrase;

  @JsonKey(name: "linkedMultisigInfo")
  Map<int, int>? linkedMultisigInfo;

  @JsonKey(name: signerBsmsField)
  String? signerBsms;

  @override
  Future<bool> canSign(String psbt) async {
    var isolateHandler =
        IsolateHandler<List<dynamic>, bool>(canSignToPsbtIsolate);
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
    Map<String, dynamic> json = {
      'name': name,
      'colorIndex': colorIndex,
      'iconIndex': iconIndex,
      'descriptor': coconutVault.descriptor
    };

    return jsonEncode(json);
  }

  @override
  Map<String, dynamic> toJson() => _$SinglesigVaultListItemToJson(this);

  factory SingleSigVaultListItem.fromJson(Map<String, dynamic> json) {
    json['vaultType'] = _$VaultTypeEnumMap[WalletType.singleSignature];
    return _$SinglesigVaultListItemFromJson(json);
  }

  @override
  String toString() =>
      'Vault($id) / type=$vaultType / linkedMultisigInfo=$linkedMultisigInfo / name=$name / colorIndex=$colorIndex / iconIndex=$iconIndex';
}
