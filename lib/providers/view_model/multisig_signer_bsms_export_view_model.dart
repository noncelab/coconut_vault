import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/isolates/wallet_isolates.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/model/single_sig/single_sig_vault_list_item.dart';
import 'package:coconut_vault/providers/wallet_provider/wallet_provider.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:flutter/foundation.dart';

class MultisigSignerBsmsExportViewModel extends ChangeNotifier {
  final WalletProvider _walletProvider;
  late String _qrData;
  late String _errorMessage;
  late bool _isLoading;
  late SingleSigVaultListItem _singleSigVaultListItem;
  Bsms? _bsms;

  MultisigSignerBsmsExportViewModel(this._walletProvider, id) {
    _qrData = '';
    _errorMessage = '';
    _isLoading = true;
    _singleSigVaultListItem = _walletProvider.getVaultById(id) as SingleSigVaultListItem;
    _setSignerBsms();
  }
  String get name => _singleSigVaultListItem.name;
  String get qrData => _qrData;
  String get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  Bsms? get bsms => _bsms;

  VaultListItemBase get vaultListItem => _singleSigVaultListItem;

  Future<void> _setSignerBsms() async {
    try {
      List<String> bsmses = await compute(WalletIsolates.extractSignerBsms, [_singleSigVaultListItem]);
      _qrData = bsmses[0];
      _bsms = Bsms.parseSigner(_qrData);
    } catch (e) {
      Logger.error('setSignerBsms error: $e');
      _errorMessage = e.toString();
      _bsms = null;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool isLoading) {
    _isLoading = isLoading;
    notifyListeners();
  }
}
