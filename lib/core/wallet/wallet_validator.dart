import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/exception/network_mismatch_exception.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/utils/bip/signer_bsms.dart';

/// Pure-function validation rules for multisig signers and derivation paths.
///
/// Has no Flutter / state dependency, so call sites can use it from anywhere
/// (provider, service, screen, isolate, unit test) without wiring DI.
class WalletValidator {
  WalletValidator._();

  static final List<AddressType> allowedMultisigAddressTypes = [AddressType.p2wsh];

  /// Validates a list of [MultisigSigner]:
  ///  - each signer's BSMS parses
  ///  - each derivation path is allowed (see [validateSignerDerivationPath])
  ///  - all signers share the same derivation path
  static void validateSigners(List<MultisigSigner> signers) {
    String? firstPath;
    for (var signer in signers) {
      if (signer.signerBsms == null) ArgumentError('signerBsms is null');

      final signerBsms = SignerBsms.parse(signer.signerBsms!);
      validateSignerDerivationPath(signerBsms.derivationPath);
      // path consistency check
      if (firstPath == null) {
        firstPath = signerBsms.derivationPath;
      } else {
        if (firstPath != signerBsms.derivationPath) {
          throw FormatException('Signer derivation path is not consistent : ${signerBsms.derivationPath}');
        }
      }
    }
  }

  /// Validates a single signer derivation path.
  /// Allows both `'` and `h` for hardened indices.
  static void validateSignerDerivationPath(String path) {
    try {
      final normalizedPath = path.replaceAll("h", "'");
      final splitedPath = normalizedPath.split('/');
      // purpose index check
      final String purpose = splitedPath[0];
      final allowedAddressTypeIndex = allowedMultisigAddressTypes.indexWhere((addressType) {
        return ("${addressType.purposeIndex}'" == purpose);
      });
      if (allowedAddressTypeIndex < 0) {
        throw FormatException('Signer purpose index is not allowed : $path');
      }

      // Only P2WSH(Native SegWit) support
      if (allowedMultisigAddressTypes[allowedAddressTypeIndex] != AddressType.p2wsh) {
        throw FormatException('Only Native SegWit (P2WSH) wallet is supported : $path');
      }

      // coinType check
      final String coinType = splitedPath[1];
      final isValidCoinType = NetworkType.currentNetworkType.isTestnet ? coinType == "1'" : coinType == "0'";
      if (!isValidCoinType) {
        throw NetworkMismatchException(
          message:
              NetworkType.currentNetworkType.isTestnet
                  ? t.alert.bsms_network_mismatch.description_when_testnet
                  : t.alert.bsms_network_mismatch.description_when_mainnet,
        );
      }

      if (allowedMultisigAddressTypes[allowedAddressTypeIndex] == AddressType.p2wsh) {
        if (splitedPath[2] != "0'" || splitedPath[3] != "2'") {
          throw FormatException('Signer derivation path is not allowed : $path');
        }
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw FormatException('Invalid derivation path: $path ${e.toString()}');
    }
  }
}
