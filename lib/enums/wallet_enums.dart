import 'package:coconut_lib/coconut_lib.dart';

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

enum MultisigCategory { lossTolerant, balanced, highSecurity, highestSecurity }
