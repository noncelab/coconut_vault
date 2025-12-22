import 'dart:async';
import 'dart:convert';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/enums/vault_mode_enum.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/isolates/wallet_isolates.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/model/multisig/multisig_vault_list_item.dart';
import 'package:coconut_vault/model/single_sig/single_sig_vault_list_item.dart';
import 'package:coconut_vault/repository/model/multisig_wallet_privacy_info.dart';
import 'package:coconut_vault/repository/model/single_sig_wallet_privacy_info.dart';
import 'package:coconut_vault/repository/model/wallet_privacy_info.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/utils/print_util.dart';
import 'package:flutter/foundation.dart';

Future<void> migrateV1toV2(
  List<dynamic> jsonList,
  Completer<void>? cancelToken,
  SharedPrefsRepository sharedPrefs,
  Future<void> Function(int id, WalletType walletType, WalletPrivacyInfo data) savePrivacyInfo,
) async {
  assert(sharedPrefs.getString(SharedPrefsKeys.kVaultMode) == VaultMode.secureStorage.name);
  final vaultList = await loadVaultsFromJsonListV1(jsonList);
  if (vaultList == null) return;

  for (final item in vaultList) {
    if (cancelToken?.isCompleted == true) return;

    if (item is SingleSigVaultListItem) {
      // INFO: v1에서는 signerBsms를 사용했었기 때문에 deprecated 프로퍼티를 사용
      await savePrivacyInfo(
        item.id,
        WalletType.singleSignature,
        SingleSigWalletPrivacyInfo(
          descriptor: item.descriptor,
          signerBsmsByAddressTypeName: {AddressType.p2wsh.name: _removeSignerBsmsDescriptionOfV1(item.signerBsms!)},
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
              wallet.signers.map((MultisigSigner signer) {
                if (signer.signerBsms != null) {
                  return SignerPrivacyInfo(
                    signerBsms: _removeSignerBsmsDescriptionOfV1(signer.signerBsms!),
                    keyStoreToJson: signer.keyStore.toJson(),
                  );
                } else {
                  // 다른 볼트에서 다중서명지갑 추가했고, 외부 키가 있는 경우
                  final extendedPublicKey = signer.keyStore.extendedPublicKey.toString();
                  final coinType =
                      (extendedPublicKey.startsWith('xpub') || extendedPublicKey.startsWith('zpub')) ? "0'" : "1'";
                  return SignerPrivacyInfo(
                    signerBsms:
                        "BSMS 1.0\n00\n[${signer.keyStore.masterFingerprint}/48'/$coinType/0'/2']$extendedPublicKey\n",
                    keyStoreToJson: signer.keyStore.toJson(),
                  );
                }
              }).toList(),
        ),
      );
    }
  }

  final jsonString = jsonEncode(vaultList.map((item) => item.toPublicJson()).toList());
  await sharedPrefs.setString(SharedPrefsKeys.kVaultListField, jsonString);
  printLongString('✅마이그레이션 완료: $jsonString');
}

// INFO: DATA_SCHEME_VERSION v1에서 사용하던 지갑 로드 함수
Future<List<VaultListItemBase>?> loadVaultsFromJsonListV1(
  List<dynamic> jsonList, {
  Completer<void>? cancelToken,
}) async {
  final vaultList = <VaultListItemBase>[];

  for (int i = 0; i < jsonList.length; i++) {
    if (cancelToken?.isCompleted == true) return null;

    final item = await compute<Map<String, dynamic>, VaultListItemBase>(
      WalletIsolates.initializeWallet,
      jsonList[i] as Map<String, dynamic>,
    );
    vaultList.add(item);
  }

  return vaultList;
}

String _removeSignerBsmsDescriptionOfV1(String signerBsms) {
  final parts = signerBsms.split('\n');
  // 다 length 4에 걸릴 것으로 예상됨
  if (parts.length == 4) {
    // signerBsms의 description 파트에 지갑의 최초 이름이 저장되어 있음
    parts[parts.length - 1] = '';
    return parts.join('\n');
  }

  if (parts.length == 3) {
    return "$signerBsms\n";
  }

  throw 'Invalid signre bsms of coconut vault: $signerBsms';
}
