import 'dart:convert';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/enums/vault_mode_enum.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/model/multisig/multisig_vault_list_item.dart';
import 'package:coconut_vault/model/single_sig/single_sig_vault_list_item.dart';
import 'package:coconut_vault/repository/model/multisig_wallet_privacy_info.dart';
import 'package:coconut_vault/repository/model/single_sig_wallet_privacy_info.dart';
import 'package:coconut_vault/repository/model/wallet_privacy_info.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:coconut_vault/utils/logger.dart';

Future<void> migrateV1toV2(
  List<VaultListItemBase> vaultList,
  SharedPrefsRepository sharedPrefs,
  Future<void> Function(int id, WalletType walletType, WalletPrivacyInfo data) savePrivacyInfo,
) async {
  assert(sharedPrefs.getString(SharedPrefsKeys.kVaultMode) == VaultMode.secureStorage.name);

  for (final item in vaultList) {
    if (item is SingleSigVaultListItem) {
      // INFO: v1에서는 signerBsms를 사용했었기 때문에 deprecated 프로퍼티를 사용
      await savePrivacyInfo(
        item.id,
        WalletType.singleSignature,
        SingleSigWalletPrivacyInfo(
          descriptor: item.descriptor,
          signerBsmsByAddressTypeName: {AddressType.p2wsh.name: item.signerBsms!},
        ),
      );
    } else {
      final wallet = item as MultisigVaultListItem;
      await savePrivacyInfo(
        wallet.id,
        WalletType.multiSignature,
        MultisigWalletPrivacyInfo(
          coordinatorBsms: wallet.coordinatorBsms,
          signersPrivacyInfo:
              wallet.signers
                  .map(
                    (signer) =>
                        SignerPrivacyInfo(signerBsms: signer.signerBsms!, keyStoreToJson: signer.keyStore.toJson()),
                  )
                  .toList(),
        ),
      );
    }
  }

  final jsonString = jsonEncode(vaultList.map((item) => item.toPublicJson()).toList());
  await sharedPrefs.setString(SharedPrefsKeys.kVaultListField, jsonString);
  Logger.log('✅마이그레이션 완료: $jsonString');
}
