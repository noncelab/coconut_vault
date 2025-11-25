class NormalizedMultisigConfig {
  final String name;
  final int requiredCount; // m
  final List<String> signerBsms; // 각 signer BSMS (BIP-129 형식)

  const NormalizedMultisigConfig({required this.name, required this.requiredCount, required this.signerBsms});

  int get totalSigners => signerBsms.length;
}
