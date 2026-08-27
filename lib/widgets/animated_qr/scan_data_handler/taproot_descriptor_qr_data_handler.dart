import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/utils/migration/taproot_older_to_after_migration.dart';
import 'package:coconut_vault/widgets/animated_qr/scan_data_handler/i_qr_scan_data_handler.dart';

class TaprootDescriptorQrDataHandler implements IQrScanDataHandler {
  String? _descriptor;

  bool get isFragmentedDataScanned => false;

  @override
  String? get result => _descriptor;

  @override
  double get progress => isCompleted() ? 1.0 : 0.0;

  @override
  bool joinData(String data) {
    if (!validateFormat(data)) {
      return false;
    }

    _descriptor = TaprootOlderToAfterMigration.migrateDescriptor(data.trim()).descriptor;
    return true;
  }

  @override
  bool validateFormat(String data) {
    final descriptor = data.trim();
    if (!descriptor.toLowerCase().startsWith('tr(')) {
      return false;
    }

    try {
      TaprootVault.fromDescriptor(TaprootOlderToAfterMigration.migrateDescriptor(descriptor).descriptor);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  bool isCompleted() => _descriptor != null && _descriptor!.isNotEmpty;

  @override
  void reset() {
    _descriptor = null;
  }
}
