import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/managers/isolate_manager.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/utils/isolate_handler.dart';
import 'package:flutter/material.dart';

class MultisigSignerBsmsExportViewModel extends ChangeNotifier {
  final WalletProvider _walletProvider;
  late String _qrData;
  late String _errorMessage;
  late bool _isLoading;
  late bool _isSignerBsmsSetFailed;
  late VaultListItemBase _vaultListItem;
  Bsms? _bsms;
  IsolateHandler<List<VaultListItemBase>, List<String>> extractBsmsIsolateHandler =
      IsolateHandler(extractSignerBsmsIsolate);

  MultisigSignerBsmsExportViewModel(this._walletProvider, id) {
    _qrData = '';
    _errorMessage = '';
    _isLoading = true;
    _isSignerBsmsSetFailed = false;
    _vaultListItem = _walletProvider.getVaultById(id);
    debugPrint('id:: $id');
    setSignerBsms();
  }
  String get name => _vaultListItem.name;
  String get qrData => _qrData;
  String get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isSignerBsmsSetFailed => _isSignerBsmsSetFailed;
  Bsms? get bsms => _bsms;

  VaultListItemBase get vaultListItem => _vaultListItem;

  @override
  void dispose() {
    extractBsmsIsolateHandler.dispose();
    super.dispose();
  }

  void _setLoading() {
    _isLoading = _bsms == null;
    notifyListeners();
  }

  // _isSignerBsmsSetFailed의 상태를 설정합니다.
  void setSignerBsmsStatus(bool value) {
    _isSignerBsmsSetFailed = value;
    notifyListeners();
  }

  Future<void> setSignerBsms() async {
    await extractBsmsIsolateHandler.initialize(initialType: InitializeType.extractSignerBsms);

    try {
      List<String> bsmses = await extractBsmsIsolateHandler.run([_vaultListItem]);

      _qrData = bsmses[0];
      _bsms = Bsms.parseSigner(_qrData);
    } catch (error) {
      _errorMessage = error.toString();
      _isSignerBsmsSetFailed = true;
    } finally {
      extractBsmsIsolateHandler.dispose();
      _setLoading();
    }
  }
}
