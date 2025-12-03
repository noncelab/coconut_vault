import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/utils/bip/signer_bsms.dart';

class NormalizedMultisigConfig {
  final String name;
  final int requiredCount; // m
  final List<String> signerBsms; // 각 signer BSMS (BIP-129 형식)

  const NormalizedMultisigConfig({required this.name, required this.requiredCount, required this.signerBsms});

  int get totalSigners => signerBsms.length;

  // # Keystone Multisig setup file (created by Coconut Vaults)
  // #
  //
  // Name: keyston-multisig
  // Policy: 2 of 2
  // Derivation: m/48'/0'/0'/2'
  // Format: P2WSH
  //
  // A3B2EB70: xpub6E9t6eQGiTVTG99xWo6KEdYAVyGtrmkCNgbTPVPSEvA6wgAS2irZxLdvbLBTz5XURtLSB2LPMZHf85CJxapgr8NpYcdDX56UKpVvZ5qxu9k
  // A0F6BA00: xpub6Dtc8ee6APa87VBy7LoZo6RfdGY3k8gnPzT1TYvHygVPJhur24RgEk9FftpzcvPhQgk9j5WKr5jkxs1Lhew25ffN5tLQfkcdE6Lz5DosnsT

  String getMultisigConfigString() {
    final signerBsmsList = signerBsms.map((sb) => SignerBsms.parse(sb)).toList();
    final coin = NetworkType.currentNetworkType == NetworkType.mainnet ? 0 : 1;
    final policy = '$requiredCount of ${signerBsmsList.length}';
    // 현재 정책에 따라 P2WSH만 지원하므로 고정
    final derivationPath = "m/48'/$coin'/0'/2'";
    const scriptType = 'P2WSH';

    final configString =
        StringBuffer()
          ..writeln('# Keystone Multisig setup file (created by Coconut Vault)')
          ..writeln('#')
          ..writeln()
          ..writeln('Name: $name')
          ..writeln('Policy: $policy')
          ..writeln('Derivation: $derivationPath')
          ..writeln('Format: $scriptType')
          ..writeln();

    for (final s in signerBsmsList) {
      configString.writeln('${s.fingerprint.toUpperCase()}: ${s.extendedKey}');
    }

    return configString.toString();
  }
}
