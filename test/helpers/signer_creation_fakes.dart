import 'dart:convert';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/model/single_sig/single_sig_vault_list_item.dart';
import 'package:coconut_vault/model/single_sig/single_sig_wallet_create_dto.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

const mnemonicA = 'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
const mnemonicB = 'hope disorder index rather outdoor response rain range genuine oil banana feed';

class FakeWalletProvider extends ChangeNotifier implements WalletProvider {
  final List<VaultListItemBase> _vaults = [];

  @override
  List<VaultListItemBase> getVaults() => List.unmodifiable(_vaults);

  @override
  final ValueNotifier<bool> isVaultListLoadingNotifier = ValueNotifier<bool>(false);

  @override
  bool get isVaultListLoading => false;

  @override
  bool get isSigningOnlyMode => false;

  @override
  bool isNameDuplicated(String name) => false;

  /// 실제 구현처럼 저장 직후 동기적으로 notifyListeners 한다.
  @override
  Future<SingleSigVaultListItem> addSingleSigVault(SingleSigWalletCreateDto wallet) async {
    final vault = makeSingleSig(id: 100 + _vaults.length, mnemonic: utf8.decode(wallet.mnemonic!));
    addVault(vault);
    return vault;
  }

  void addVault(VaultListItemBase vault) {
    _vaults.add(vault);
    notifyListeners();
  }

  bool get isListened => hasListeners;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthProvider extends Fake implements AuthProvider {}

SingleSigVaultListItem makeSingleSig({required int id, required String mnemonic}) {
  final keyStore = KeyStore.fromMnemonic(Uint8List.fromList(utf8.encode(mnemonic)), AddressType.p2wpkh);
  final descriptor = Descriptor.forSingleSignature(AddressType.p2wpkh, keyStore, "84'/0'/0'");
  final vault = SingleSignatureVault.fromKeyStore(keyStore, accountIndex: 0);

  return SingleSigVaultListItem(
    id: id,
    name: 'single-$id',
    colorIndex: 0,
    iconIndex: 0,
    descriptor: descriptor.serialize(),
    signerBsmsByAddressType: {AddressType.p2wsh: vault.getSignerBsms(AddressType.p2wsh, '')},
    createdAt: DateTime(2026),
  );
}
