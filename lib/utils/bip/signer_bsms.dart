class SignerBsms {
  final String fingerprint;
  final String derivationPath;
  final String extendedKey;
  final String? label;

  SignerBsms({required this.fingerprint, required this.derivationPath, required this.extendedKey, this.label});

  String get derivationPathForDescriptor => derivationPath.replaceAll("'", "h");

  factory SignerBsms.parse(String raw) {
    final lines = raw.split(RegExp(r'\r?\n')).map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    if (lines.length < 3) {
      throw FormatException('BSMS block tooㄴshort: ${lines.length}');
    }

    final descLine = lines[2];
    final label = (lines.length >= 4) ? lines[3] : null;

    final reg = RegExp(r'^\[([0-9a-fA-F]{8})/([^\]]+)\](.+)$');
    final m = reg.firstMatch(descLine);
    if (m == null) {
      throw FormatException('Invalid BSMS descriptor line: $descLine');
    }

    final fp = m.group(1)!;
    final path = m.group(2)!;
    final xpub = m.group(3)!.trim();

    return SignerBsms(fingerprint: fp, derivationPath: path, extendedKey: xpub, label: label);
  }
}
