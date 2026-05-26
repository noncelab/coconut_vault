import 'package:coconut_vault/model/taproot/taproot_wallet_sync_data.dart';
import 'package:coconut_vault/widgets/animated_qr/scan_data_handler/i_qr_scan_data_handler.dart';

class TaprootWalletSyncQrDataHandler implements IQrScanDataHandler {
  TaprootWalletSyncData? _walletSyncData;

  bool get isFragmentedDataScanned => false;

  @override
  TaprootWalletSyncData? get result => _walletSyncData;

  @override
  double get progress => isCompleted() ? 1.0 : 0.0;

  @override
  bool joinData(String data) {
    if (!validateFormat(data)) {
      return false;
    }

    _walletSyncData = TaprootWalletSyncData.parse(data.trim());
    return true;
  }

  @override
  bool validateFormat(String data) {
    try {
      TaprootWalletSyncData.parse(data.trim());
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  bool isCompleted() => _walletSyncData != null;

  @override
  void reset() {
    _walletSyncData = null;
  }
}
