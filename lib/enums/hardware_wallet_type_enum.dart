import 'package:coconut_vault/constants/icon_path.dart';
import 'package:coconut_vault/localization/strings.g.dart';

// INFO: 코코넛 월렛의 walletImportSource와 이름이 반드시 일치해야 export 시 signerSource 정보가 코코넛 월렛과 호환됨
enum HardwareWalletType { coconutVault, keystone, seedSigner, jade, coldCard, krux }

extension HardwareWalletTypeExtension on HardwareWalletType {
  static final Map<HardwareWalletType, String> _names = {
    HardwareWalletType.coconutVault: t.hardware_wallet_type.vault,
    HardwareWalletType.keystone: t.hardware_wallet_type.keystone,
    HardwareWalletType.seedSigner: t.hardware_wallet_type.seedsigner,
    HardwareWalletType.jade: t.hardware_wallet_type.jade,
    HardwareWalletType.coldCard: t.hardware_wallet_type.coldcard,
    HardwareWalletType.krux: t.hardware_wallet_type.krux,
  };

  static const Map<HardwareWalletType, String> _icons = {
    HardwareWalletType.coconutVault: kCoconutVaultIconPath,
    HardwareWalletType.keystone: kKeystoneIconPath,
    HardwareWalletType.seedSigner: kSeedSignerIconPath,
    HardwareWalletType.jade: kJadeIconPath,
    HardwareWalletType.coldCard: kColdCardIconPath,
    HardwareWalletType.krux: kKruxIconPath,
  };

  String get displayName => _names[this]!;
  String get iconPath => _icons[this]!;

  static HardwareWalletType? getHardwareWalletTypeByIconPath(String iconPath) {
    return _icons.entries.firstWhere((element) => element.value == iconPath).key as HardwareWalletType?;
  }

  static HardwareWalletType? fromDisplayName(String name) {
    for (final entry in _names.entries) {
      if (entry.value == name) {
        return entry.key;
      }
    }

    return null;
  }
}
