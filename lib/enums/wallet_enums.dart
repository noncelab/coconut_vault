import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/localization/strings.g.dart';

/// vault_model의 _vaultList에서 type 값 문자열을 비교할 때 꼭 VaultType.singleSignature.name으로 비교하셔야 합니다
enum WalletType {
  singleSignature, // Single-Signature Vault
  multiSignature; // Multi-Signature Vault

  AddressType get addressType {
    switch (this) {
      case WalletType.singleSignature:
        return AddressType.p2wpkh;
      case WalletType.multiSignature:
        return AddressType.p2wsh;
    }
  }
}

enum HardwareWalletType { vault, keystone, seesigner, jade, coldcard, krux }

extension HarewareWalletTypeExtension on HardwareWalletType {
  String get displayName {
    switch (this) {
      case HardwareWalletType.vault:
        return t.hardware_wallet_type.vault;
      case HardwareWalletType.keystone:
        return t.hardware_wallet_type.keystone;
      case HardwareWalletType.seesigner:
        return t.hardware_wallet_type.seesigner;
      case HardwareWalletType.jade:
        return t.hardware_wallet_type.jade;
      case HardwareWalletType.coldcard:
        return t.hardware_wallet_type.coldcard;
      case HardwareWalletType.krux:
        return t.hardware_wallet_type.krux;
    }
  }
}
