import 'package:coconut_vault/model/taproot/taproot_wallet_sync_data.dart';
import 'package:flutter/foundation.dart';

class TaprootImportViewModel extends ChangeNotifier {
  TaprootWalletSyncData? _walletSyncData;

  TaprootWalletSyncData? get walletSyncData => _walletSyncData;

  void setWalletSyncData(TaprootWalletSyncData walletSyncData) {
    _walletSyncData = walletSyncData;
    debugPrint('TaprootImportViewModel walletSyncData: ${walletSyncData.toJson()}');
    notifyListeners();
  }

  void reset() {
    _walletSyncData = null;
    notifyListeners();
  }
}
