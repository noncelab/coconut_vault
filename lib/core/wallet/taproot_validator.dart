import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/exception/network_mismatch_exception.dart';

class TaprootValidator {
  TaprootValidator._();

  static const int minParentCount = 1;
  static const int maxParentCount = 2;
  static const int requiredBeneficiaryCount = 1;

  static final List<AddressType> allowedSignerAddressTypes = [AddressType.p2tr];

  /// 1. 스캔한 Taproot Signer BSMS QR 데이터 정합성 확인.
  static KeyStore validateSignerBsms(String signerBsms) {
    final bsms = Bsms.parseSigner(signerBsms.trim());
    validateSignerDerivationPath(bsms.signer!.path);
    return KeyStore.fromSignerBsms(signerBsms);
  }

  static void validateSignerDerivationPath(String path) {
    try {
      final normalizedPath = _normalizeDerivationPath(path);
      final splitPath = normalizedPath.split('/');
      if (splitPath.length < 3) {
        throw FormatException('Invalid Taproot signer derivation path: $path');
      }

      final purpose = splitPath[0];
      final allowedAddressTypeIndex = allowedSignerAddressTypes.indexWhere((addressType) {
        return "${addressType.purposeIndex}'" == purpose;
      });
      if (allowedAddressTypeIndex < 0) {
        throw FormatException('Taproot signer purpose index is not allowed: $path');
      }

      if (allowedSignerAddressTypes[allowedAddressTypeIndex] != AddressType.p2tr) {
        throw FormatException('Only Taproot (P2TR) signer is supported: $path');
      }

      final coinType = splitPath[1];
      final isValidCoinType = NetworkType.currentNetworkType.isTestnet ? coinType == "1'" : coinType == "0'";
      if (!isValidCoinType) {
        throw NetworkMismatchException(
          message: NetworkType.currentNetworkType.isTestnet
              ? t.alert.bsms_network_mismatch.description_when_testnet
              : t.alert.bsms_network_mismatch.description_when_mainnet,
        );
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw FormatException('Invalid Taproot signer derivation path: $path ${e.toString()}');
    }
  }

  /// 2. Descriptor 내부 확장공개키 기준으로 같은 탭루트 지갑인지 확인.
  static bool hasMatchingExtendedPublicKeyInDescriptors(String leftDescriptor, String rightDescriptor) {
    final leftVault = parseTaprootDescriptor(leftDescriptor);
    final rightVault = parseTaprootDescriptor(rightDescriptor);
    return hasMatchingExtendedPublicKey(leftVault, rightVault);
  }

  static bool hasMatchingExtendedPublicKey(TaprootVault leftVault, TaprootVault rightVault) {
    final leftExtendedPublicKeys = _extendedPublicKeysFromVault(leftVault);
    final rightExtendedPublicKeys = _extendedPublicKeysFromVault(rightVault);
    return leftExtendedPublicKeys.any(rightExtendedPublicKeys.contains);
  }

  static bool hasMatchingExtendedPublicKeyWithSignerBsms(String descriptor, String signerBsms) {
    final vaultExtendedPublicKeys = _extendedPublicKeysFromVault(parseTaprootDescriptor(descriptor));
    final signerExtendedPublicKey = validateSignerBsms(signerBsms).extendedPublicKey.serialize();
    return vaultExtendedPublicKeys.contains(signerExtendedPublicKey);
  }

  /// 3. 상속 지갑 Descriptor QR 데이터 정합성 확인.
  static TaprootVault validateInheritanceDescriptor(String descriptor) {
    final vault = parseTaprootDescriptor(descriptor);
    final parentCount = vault.keyStoreList.length;
    final beneficiaryCount = _beneficiaryKeyStoresFromVault(vault).length;

    if (parentCount < minParentCount || parentCount > maxParentCount) {
      throw FormatException('Invalid Taproot inheritance parent count: $parentCount');
    }

    if (beneficiaryCount != requiredBeneficiaryCount) {
      throw FormatException('Invalid Taproot inheritance beneficiary count: $beneficiaryCount');
    }

    return vault;
  }

  /// 4. 상속 지갑 Descriptor의 자식 정보가 방금 생성한 자식 지갑의 P2TR Signer BSMS와 일치하는지 확인.
  static bool isInheritanceDescriptorChildMatched({
    required String inheritanceDescriptor,
    required String childSignerBsms,
  }) {
    final inheritanceVault = validateInheritanceDescriptor(inheritanceDescriptor);
    final childExtendedPublicKey = validateSignerBsms(childSignerBsms).extendedPublicKey.serialize();
    return _beneficiaryExtendedPublicKeysFromVault(inheritanceVault).contains(childExtendedPublicKey);
  }

  static bool isInheritanceDescriptorChildDescriptorMatched({
    required String inheritanceDescriptor,
    required String childDescriptor,
  }) {
    return isInheritanceDescriptorChildMatched(
      inheritanceDescriptor: inheritanceDescriptor,
      childSignerBsms: signerBsmsFromSingleKeyTaprootDescriptor(childDescriptor),
    );
  }

  static TaprootVault parseTaprootDescriptor(String descriptor) {
    final trimmedDescriptor = descriptor.trim();
    if (trimmedDescriptor.isEmpty) {
      throw const FormatException('Taproot descriptor is empty');
    }

    return TaprootVault.fromDescriptor(trimmedDescriptor);
  }

  static String signerBsmsFromSingleKeyTaprootDescriptor(String descriptor) {
    final vault = parseTaprootDescriptor(descriptor);
    if (vault.keyStoreList.length != 1) {
      throw FormatException('Single-key Taproot descriptor is required: ${vault.keyStoreList.length}');
    }

    final keyStore = vault.keyStoreList.first;
    return Bsms.fromSigner(
      keyStore.masterFingerprint,
      vault.derivationPath.replaceAll('m/', ''),
      keyStore.extendedPublicKey.serialize(),
      '',
    ).serializeSigner();
  }

  static String _normalizeDerivationPath(String path) {
    return path.trim().replaceAll('h', "'").replaceFirst(RegExp(r'^m/'), '');
  }

  static Set<String> _extendedPublicKeysFromVault(TaprootVault vault) {
    return {
      ...vault.keyStoreList.map(_extendedPublicKeyFromKeyStore),
      ..._beneficiaryExtendedPublicKeysFromVault(vault),
    };
  }

  static Set<String> _beneficiaryExtendedPublicKeysFromVault(TaprootVault vault) {
    return _beneficiaryKeyStoresFromVault(vault).map(_extendedPublicKeyFromKeyStore).toSet();
  }

  static List<KeyStore> _beneficiaryKeyStoresFromVault(TaprootVault vault) {
    return vault.policyList
        .whereType<InheritancePolicy>()
        .map((policy) => policy.beneficiaryKeyStore)
        .toList(growable: false);
  }

  static String _extendedPublicKeyFromKeyStore(KeyStore keyStore) {
    return keyStore.extendedPublicKey.serialize();
  }
}
