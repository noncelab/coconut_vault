import 'package:coconut_lib/coconut_lib.dart';

class TaprootLegacyInheritanceMigrationResult {
  final String descriptor;
  final bool hasChanges;
  final bool hasOlder;

  const TaprootLegacyInheritanceMigrationResult({
    required this.descriptor,
    required this.hasChanges,
    required this.hasOlder,
  });
}

/// 볼트 3.3.0 이하 상속 leaf 표기의 after_drop 변환
class TaprootLegacyInheritanceMigration {
  static final RegExp _legacyLeaf = RegExp(r'and_v\(v:pk\(([^()]+)\),(older|after)\((\d+)\)\)');

  static String migrateMiniscript(String miniscript) {
    final match = _legacyLeaf.firstMatch(miniscript);
    if (match == null || match.start != 0 || match.end != miniscript.length) return miniscript;
    return _toAfterDrop(match);
  }

  static TaprootLegacyInheritanceMigrationResult migrateDescriptor(String descriptor) {
    final body = descriptor.split('#').first;
    final migratedBody = body.replaceAllMapped(_legacyLeaf, _toAfterDrop);
    final migratedDescriptor = Descriptor.parse('$migratedBody#${Checksum.getChecksum(migratedBody)}').serialize();

    return TaprootLegacyInheritanceMigrationResult(
      descriptor: migratedDescriptor,
      hasChanges: migratedDescriptor != descriptor,
      hasOlder: _legacyLeaf.allMatches(body).any((match) => match.group(2) == 'older'),
    );
  }

  static String _toAfterDrop(Match match) => 'and_v(after_drop(${match.group(3)}),pk(${match.group(1)}))';
}
