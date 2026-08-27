import 'package:coconut_lib/coconut_lib.dart';

class TaprootOlderToAfterMigrationResult {
  final String descriptor;
  final bool hasChanges;

  const TaprootOlderToAfterMigrationResult({required this.descriptor, required this.hasChanges});
}

/// Normalizes legacy absolute-locktime inheritance miniscripts before they are
/// parsed by the current coconut_lib version.
class TaprootOlderToAfterMigration {
  static String migrateMiniscript(String miniscript) {
    final match = RegExp(r'^and_v\(v:pk\((.+)\),(?:older|after)\((\d+)\)\)$').firstMatch(miniscript);
    if (match == null) return miniscript;

    final migratedMiniscript = 'and_v(v:pk(${match.group(1)}),after(${match.group(2)}))';
    InheritancePolicy.fromMiniscript(migratedMiniscript);
    return migratedMiniscript;
  }

  static TaprootOlderToAfterMigrationResult migrateDescriptor(String descriptor) {
    final descriptorObject = Descriptor.parse(descriptor, ignoreChecksum: true);
    var hasChanges = false;

    for (var index = 0; index < descriptorObject.miniscriptList.length; index++) {
      final miniscript = descriptorObject.miniscriptList[index];
      final migratedMiniscript = migrateMiniscript(miniscript);
      if (migratedMiniscript == miniscript) continue;
      descriptorObject.miniscriptList[index] = migratedMiniscript;
      hasChanges = true;
    }

    final migratedDescriptor = descriptorObject.serialize();
    return TaprootOlderToAfterMigrationResult(
      descriptor: migratedDescriptor,
      hasChanges: hasChanges || descriptor != migratedDescriptor,
    );
  }
}
