import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/providers/sign_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';

class PsbtScannerViewModel {
  late final WalletProvider _walletProvider;
  late final SignProvider _signProvider;
  late final VaultListItemBase _vaultListItem;

  PsbtScannerViewModel(this._walletProvider, this._signProvider, int walletId) {
    _signProvider.resetAll();
    _vaultListItem = _walletProvider.getVaultById(walletId);
    _signProvider.setVaultListItem(_vaultListItem);
  }

  bool get isMultisig => _vaultListItem.vaultType == WalletType.multiSignature;
  String get walletName => _vaultListItem.name;

  Future<bool> canSign(String psbtBase64) async {
    return await _vaultListItem.canSign(psbtBase64);
  }

  void saveUnsignedPsbt(String psbtBase64) {
    _signProvider.saveUnsignedPsbt(psbtBase64);
  }

  Psbt parseBase64EncodedToPsbt(String signedPsbtBase64Encoded) {
    return Psbt.parse(signedPsbtBase64Encoded);
  }
}
