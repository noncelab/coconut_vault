import 'package:coconut_vault/constants/icon_path.dart';
import 'package:coconut_vault/localization/strings.g.dart';

enum HardwareWalletType { coconutVault, keystone3Pro, seedSigner, jade, coldcard, krux }

extension HardwareWalletTypeExtension on HardwareWalletType {
  static final Map<HardwareWalletType, String> _names = {
    HardwareWalletType.coconutVault: t.hardware_wallet_type.vault,
    HardwareWalletType.keystone3Pro: t.hardware_wallet_type.keystone,
    HardwareWalletType.seedSigner: t.hardware_wallet_type.seedsigner,
    HardwareWalletType.jade: t.hardware_wallet_type.jade,
    HardwareWalletType.coldcard: t.hardware_wallet_type.coldcard,
    HardwareWalletType.krux: t.hardware_wallet_type.krux,
  };

  static const Map<HardwareWalletType, String> _icons = {
    HardwareWalletType.coconutVault: kCoconutVaultIconPath,
    HardwareWalletType.keystone3Pro: kKeystoneIconPath,
    HardwareWalletType.seedSigner: kSeedSignerIconPath,
    HardwareWalletType.jade: kJadeIconPath,
    HardwareWalletType.coldcard: kColdCardIconPath,
    HardwareWalletType.krux: kKruxIconPath,
  };

  String get displayName => _names[this]!;
  String get iconPath => _icons[this]!;
}
