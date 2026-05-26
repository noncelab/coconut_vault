import 'package:coconut_vault/model/taproot/taproot_wallet_sync_data.dart';
import 'package:flutter/foundation.dart';

enum TaprootImportRole { none, parent, child }

class TaprootImportViewModel extends ChangeNotifier {
  TaprootWalletSyncData? _walletSyncData;
  TaprootImportRole _selectedRole = TaprootImportRole.none;

  TaprootWalletSyncData? get walletSyncData => _walletSyncData;
  TaprootImportRole get selectedRole => _selectedRole;

  void setWalletSyncData(TaprootWalletSyncData walletSyncData) {
    _walletSyncData = walletSyncData;
    debugPrint('TaprootImportViewModel walletSyncData: ${walletSyncData.toJson()}');
    notifyListeners();
  }

  void setRole(TaprootImportRole role) {
    _selectedRole = _selectedRole == role ? TaprootImportRole.none : role;
    notifyListeners();
  }

  void reset() {
    _walletSyncData = null;
    _selectedRole = TaprootImportRole.none;
    notifyListeners();
  }
}
