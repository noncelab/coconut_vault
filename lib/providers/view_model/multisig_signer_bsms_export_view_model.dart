import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/managers/isolate_manager.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/utils/isolate_handler.dart';
import 'package:flutter/material.dart';

class MultisigSignerBsmsExportViewModel extends ChangeNotifier {
  final WalletProvider _walletProvider;
  late final int _id;
  late String _qrData;
  late String _name;
  String _errorMessage = '';
  BSMS? _bsms;
  late VaultListItemBase _vaultListItem;
  late bool _isLoading;
  bool _isSignerBsmsSetCompleted = true;
  IsolateHandler<List<VaultListItemBase>, List<String>>
      extractBsmsIsolateHandler = IsolateHandler(extractSignerBsmsIsolate);

  MultisigSignerBsmsExportViewModel(this._walletProvider, this._id) {
    _qrData = '';
    _vaultListItem = _walletProvider.getVaultById(_id);
    _name = _vaultListItem.name;
    _isLoading = true;
    setSignerBsms();
  }
  BSMS? get bsms => _bsms;
  String get errorMessage => _errorMessage;
  int get id => _id;
  bool get isLoading => _isLoading;
  bool get isSignerBsmsSetCompleted => _isSignerBsmsSetCompleted;
  String get name => _name;
  String get qrData => _qrData;

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

  void setSignerBsmsCompleted(bool value) {
    _isSignerBsmsSetCompleted = value;
    notifyListeners();
  }

  Future<void> setSignerBsms() async {
    await extractBsmsIsolateHandler.initialize(
        initialType: InitializeType.extractSignerBsms);

    try {
      List<String> bsmses =
          await extractBsmsIsolateHandler.run([_vaultListItem]);

      _qrData = bsmses[0];
      _bsms = BSMS.parseSigner(_qrData);
    } catch (error) {
      _errorMessage = error.toString();
      _isSignerBsmsSetCompleted = false;
    } finally {
      extractBsmsIsolateHandler.dispose();
      _setLoading();
    }
  }
}
