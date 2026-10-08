import 'dart:convert';

import 'package:coconut_vault/extensions/uint8list_extensions.dart';
import 'package:coconut_vault/isolates/wallet_isolates/wallet_isolates.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/utils/nfkd_util.dart';
import 'package:flutter/foundation.dart';

/// 입력한 패스프레이즈를 지갑에 저장된 MFP와 대조한다.
///
/// 지금 만드는 지갑은 NFKD로 정규화한 패스프레이즈를 쓰고, 3.2.0 이하 코코넛 볼트는 정규화하지 않은 UTF-8을 썼다.
/// NFKD로 먼저 확인하고, 정규화로 바뀌는 패스프레이즈라면 정규화하지 않은 UTF-8로 한 번 더 확인한다.
///
/// [result]는 [WalletIsolates.verifyPassphrase]의 결과다. 일치한 후보가 없으면 NFKD 후보의 결과를 담는다.
/// [passphrase]는 [result]를 만든 후보 바이트이며, 호출자가 사용 후 지운다.
Future<({Map<String, dynamic> result, Uint8List passphrase})> verifyReenteredPassphrase({
  required Uint8List mnemonic,
  required String passphrase,
  required VaultListItemBase vaultListItem,
  String? targetXpub,
}) async {
  final nfkd = NfkdUtil.encodeNfkd(passphrase);
  final nfkdResult = await _verify(mnemonic, nfkd, vaultListItem, targetXpub);
  if (nfkdResult['success'] == true || NfkdUtil.isNfkdNormalized(passphrase)) {
    return (result: nfkdResult, passphrase: nfkd);
  }

  final legacy = Uint8List.fromList(utf8.encode(passphrase));
  final legacyResult = await _verify(mnemonic, legacy, vaultListItem, targetXpub);
  if (legacyResult['success'] == true) {
    nfkd.wipe();
    return (result: legacyResult, passphrase: legacy);
  }

  legacy.wipe();
  return (result: nfkdResult, passphrase: nfkd);
}

Future<Map<String, dynamic>> _verify(
  Uint8List mnemonic,
  Uint8List passphrase,
  VaultListItemBase vaultListItem,
  String? targetXpub,
) {
  // compute는 인자를 isolate로 복사하고, isolate 쪽 사본은 verifyPassphrase가 지운다.
  return compute(WalletIsolates.verifyPassphrase, {
    'mnemonic': mnemonic,
    'passphrase': passphrase,
    'vaultListItem': vaultListItem,
    'targetXpub': targetXpub,
  });
}
