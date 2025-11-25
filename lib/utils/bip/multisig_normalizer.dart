import 'dart:convert';
import 'package:coconut_vault/utils/bip/normalized_multisig_config.dart';

/// CoordinatorBsmsQrDataHandler.result -> NormalizedMultisigConfig
class MultisigNormalizer {
  static NormalizedMultisigConfig fromCoordinatorResult(dynamic result) {
    if (result == null) {
      throw const FormatException('Empty coordinator result');
    }

    if (result is String) {
      final trimmed = result.trim();

      // 1) Coconut export 텍스트
      //    {name: ..., coordinatorBsms: ...} 같은 형태
      if (trimmed.contains('coordinatorBsms:')) {
        return _normalizeCoconutText(trimmed);
      }

      // 2) Sparrow / BlueWallet 텍스트
      if (trimmed.contains('Policy:') && trimmed.contains('Derivation:')) {
        return _normalizeText(trimmed);
      }

      // 3) BSMS 1.0 텍스트
      if (trimmed.startsWith('BSMS 1.0') && trimmed.contains('sortedmulti(')) {
        return _normalizeRawBsmsText(trimmed);
      }

      // 4) JSON Sparrow descriptor export 등
      if (trimmed.startsWith('{')) {
        final map = jsonDecode(trimmed) as Map<String, dynamic>;
        return _normalizeJson(map);
      }
    }
    return _normalizeJson(result as Map<String, dynamic>);
  }

  static NormalizedMultisigConfig _normalizeCoconutText(String text) {
    final nameMatch = RegExp(r'name:\s*([^,}]+)').firstMatch(text);
    if (nameMatch == null) {
      throw const FormatException('name not found in coconut export');
    }
    final name = nameMatch.group(1)!.trim();

    final namesMapMatch = RegExp(r'namesMap:\s*\{([^}]+)\}').firstMatch(text);
    Map<String, String> namesMap = {};
    if (namesMapMatch != null) {
      final entries = namesMapMatch.group(1)!;
      for (final entry in entries.split(',')) {
        final parts = entry.split(':');
        if (parts.length == 2) {
          final fingerprint = parts[0].trim().toUpperCase();
          final label = parts[1].trim();
          namesMap[fingerprint] = label;
        }
      }
    }

    final coordIdx = text.indexOf('coordinatorBsms:');
    if (coordIdx < 0) {
      throw const FormatException('coordinatorBsms not found in coconut export');
    }

    String coordBlock = text.substring(coordIdx + 'coordinatorBsms:'.length).trim();

    if (coordBlock.endsWith('}')) {
      coordBlock = coordBlock.substring(0, coordBlock.length - 1).trim();
    }

    final coordLines = coordBlock.split('\n');
    if (coordLines.length < 2) {
      throw const FormatException('Invalid coordinatorBsms block');
    }

    final descriptorLine = coordLines[1].trim();

    final sortedmultiMatch = RegExp(r'sortedmulti\((\d+),').firstMatch(descriptorLine);
    if (sortedmultiMatch == null) {
      throw const FormatException('Not a sortedmulti descriptor in coordinatorBsms');
    }
    final requiredCount = int.parse(sortedmultiMatch.group(1)!);

    final signerMatches = RegExp(r'\[([^\]]+)\]([A-Za-z0-9]+)').allMatches(descriptorLine);

    final signerBsms = <String>[];

    for (final match in signerMatches) {
      final bracketContent = match.group(1)!; // 73C5DA0A/48'/1'/0'/2'
      final xpub = match.group(2)!; // tpub...

      final slashIdx = bracketContent.indexOf('/');
      if (slashIdx <= 0) continue;

      final fpRaw = bracketContent.substring(0, slashIdx);
      final pathRaw = bracketContent.substring(slashIdx + 1); // 48'/1'/0'/2'

      final fingerprint = _normalizeFingerprint(fpRaw);
      final normalizedPath = _normalizeHardenedPath(pathRaw);

      final label = namesMap[fingerprint];

      final bsms = _buildSignerBsms(
        fingerprint: fingerprint,
        derivationPath: normalizedPath,
        extendedKey: xpub,
        label: label,
      );
      signerBsms.add(bsms);
    }

    return NormalizedMultisigConfig(name: name, requiredCount: requiredCount, signerBsms: signerBsms);
  }

  static NormalizedMultisigConfig _normalizeText(String text) {
    final lines = text.split('\n');

    final nameLine = lines.firstWhere(
      (l) => l.startsWith('Name:'),
      orElse: () => throw const FormatException('Name not found'),
    );
    final name = nameLine.split(':')[1].trim();

    final policyLine = lines.firstWhere(
      (l) => l.startsWith('Policy:'),
      orElse: () => throw const FormatException('Policy not found'),
    );
    final requiredCount = int.parse(policyLine.split(':')[1].trim().split(' ')[0]);

    final derivationLine = lines.firstWhere(
      (l) => l.startsWith('Derivation:'),
      orElse: () => throw const FormatException('Derivation not found'),
    );
    final derivationPath = derivationLine.split(':')[1].trim().replaceAll('m/', ''); // 예: 48'/1'/0'/2'

    // signer lines: FINGERPRINT: XPUB
    final signerLines = lines.where((l) => l.contains(':') && l.contains('pub')).toList();

    final signerBsms = <String>[];

    for (int i = 0; i < signerLines.length; i++) {
      final line = signerLines[i].trim();
      final parts = line.split(':');
      final xpub = parts[1].trim();

      final bsms = _buildSignerBsms(
        fingerprint: _normalizeFingerprint(parts[0]),
        derivationPath: _normalizeHardenedPath(derivationPath),
        extendedKey: xpub,
      );

      signerBsms.add(bsms);
    }

    return NormalizedMultisigConfig(name: name, requiredCount: requiredCount, signerBsms: signerBsms);
  }

  static NormalizedMultisigConfig _normalizeRawBsmsText(String text) {
    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    if (lines.isEmpty || lines[0] != 'BSMS 1.0') {
      throw const FormatException('Invalid BSMS header');
    }

    final descriptorLine = lines.firstWhere(
      (l) => l.contains('sortedmulti('),
      orElse: () => throw const FormatException('Descriptor line not found in BSMS text'),
    );

    final sortedmultiMatch = RegExp(r'sortedmulti\((\d+),').firstMatch(descriptorLine);
    if (sortedmultiMatch == null) {
      throw const FormatException('Not a sortedmulti descriptor in BSMS text');
    }
    final requiredCount = int.parse(sortedmultiMatch.group(1)!);

    final signerMatches = RegExp(r'\[([^\]]+)\]([A-Za-z0-9]+)').allMatches(descriptorLine);

    final signerBsms = <String>[];

    for (final match in signerMatches) {
      final bracketContent = match.group(1)!;
      final extendedKey = match.group(2)!;

      final slashIdx = bracketContent.indexOf('/');
      if (slashIdx <= 0) continue;

      final fpRaw = bracketContent.substring(0, slashIdx);
      final pathRaw = bracketContent.substring(slashIdx + 1);

      final fingerprint = _normalizeFingerprint(fpRaw);
      final normalizedPath = _normalizeHardenedPath(pathRaw);

      final bsms = _buildSignerBsms(fingerprint: fingerprint, derivationPath: normalizedPath, extendedKey: extendedKey);

      signerBsms.add(bsms);
    }

    return NormalizedMultisigConfig(name: '', requiredCount: requiredCount, signerBsms: signerBsms);
  }

  static NormalizedMultisigConfig _normalizeJson(Map<String, dynamic> json) {
    final name = (json['label'] ?? '') as String;
    final descriptor = json['descriptor'] as String?;

    if (descriptor == null) {
      throw const FormatException('descriptor not found in JSON');
    }

    final sortedmultiMatch = RegExp(r'sortedmulti\((\d+),').firstMatch(descriptor);
    if (sortedmultiMatch == null) {
      throw const FormatException('Not a sortedmulti descriptor');
    }
    final requiredCount = int.parse(sortedmultiMatch.group(1)!);

    final signerMatches = RegExp(r'\[([^\]]+)\]([A-Za-z0-9]+)').allMatches(descriptor);

    final signerBsms = <String>[];

    for (final match in signerMatches) {
      final bracketContent = match.group(1)!; // 73c5da0a/48h/1h/0h/2h
      final xpub = match.group(2)!; // tpub...

      final slashIdx = bracketContent.indexOf('/');
      if (slashIdx <= 0) continue;

      final fpRaw = bracketContent.substring(0, slashIdx);
      final pathRaw = bracketContent.substring(slashIdx + 1); // 48h/1h/0h/2

      final fingerprint = _normalizeFingerprint(fpRaw);
      final normalizedPath = _normalizeHardenedPath(pathRaw);

      final bsms = _buildSignerBsms(fingerprint: fingerprint, derivationPath: normalizedPath, extendedKey: xpub);
      signerBsms.add(bsms);
    }

    return NormalizedMultisigConfig(name: name, requiredCount: requiredCount, signerBsms: signerBsms);
  }

  static String _normalizeFingerprint(String fp) {
    return fp.trim().toUpperCase();
  }

  static String _normalizeHardenedPath(String rawPathNoM) {
    final segments = rawPathNoM.split('/');

    final normalized =
        segments.map((seg) {
          seg = seg.trim();
          if (seg.isEmpty) return seg;

          if (seg.endsWith('h') || seg.endsWith('H')) {
            final trimmed = seg.substring(0, seg.length - 1);
            return '$trimmed\'';
          }
          return seg;
        }).toList();

    return normalized.join('/');
  }

  static String _buildSignerBsms({
    required String fingerprint,
    required String derivationPath,
    required String extendedKey,
    String? label,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('BSMS 1.0');
    buffer.writeln('00');
    buffer.write('[$fingerprint/$derivationPath]$extendedKey');

    if (label != null && label.trim().isNotEmpty) {
      buffer.write('\n${label.trim()}');
    }

    return buffer.toString();
  }
}
