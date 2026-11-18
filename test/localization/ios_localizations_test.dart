import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'iOS bundles Thai permission strings and preserves each flavor name',
    () async {
      final projectResult = await Process.run('plutil', [
        '-convert',
        'json',
        '-o',
        '-',
        'ios/Runner.xcodeproj/project.pbxproj',
      ]);
      expect(projectResult.exitCode, 0, reason: '${projectResult.stderr}');
      final project = jsonDecode(projectResult.stdout as String) as Map<String, dynamic>;
      final objects = project['objects'] as Map<String, dynamic>;
      expect(objects[project['rootObject']]['knownRegions'], contains('th'));
      final thaiGroup = objects.entries.singleWhere((entry) => entry.value['path'] == 'th.lproj');
      final runner = objects.values.singleWhere(
        (object) => object['isa'] == 'PBXNativeTarget' && object['name'] == 'Runner',
      );
      expect(runner['fileSystemSynchronizedGroups'], contains(thaiGroup.key));
      expect(
        objects.values.any(
          (object) => object['isa'] == 'PBXGroup' && (object['children'] as List).contains(thaiGroup.key),
        ),
        isTrue,
      );

      final script = objects.values
          .map((object) => object['shellScript'])
          .whereType<String>()
          .singleWhere((script) => script.contains('EN_NSCameraUsageDescription'));
      final sourceResult = await Process.run('plutil', [
        '-convert',
        'json',
        '-o',
        '-',
        'ios/Runner/th.lproj/InfoPlist.strings',
      ]);
      expect(sourceResult.exitCode, 0, reason: '${sourceResult.stderr}');
      final sourceStrings = jsonDecode(sourceResult.stdout as String) as Map<String, dynamic>;
      expect(
        sourceStrings['NSFaceIDUsageDescription'],
        'ใช้ Face ID เพื่อปลดล็อกและเข้าถึงฟีเจอร์ด้านความปลอดภัย',
        reason: 'Preserve the Korean purpose statement: uses Face ID to unlock and access security features.',
      );
      final temp = Directory.systemTemp.createTempSync('vault-thai-ios-');
      addTearDown(() => temp.deleteSync(recursive: true));

      for (final configuration in [
        'Debug-Mainnet',
        'Release-Mainnet',
        'Release-liteMainnet',
        'Release-Regtest',
        'Release-liteRegtest',
      ]) {
        final run = await Process.run(
          'bash',
          ['-c', script],
          environment: {'CONFIGURATION': configuration, 'BUILT_PRODUCTS_DIR': temp.path, 'PRODUCT_NAME': 'Runner'},
        );
        expect(run.exitCode, 0, reason: '$configuration: ${run.stderr}');
        final thaiResult = await Process.run('plutil', [
          '-convert',
          'json',
          '-o',
          '-',
          '${temp.path}/Runner.app/th.lproj/InfoPlist.strings',
        ]);
        expect(thaiResult.exitCode, 0, reason: '$configuration: ${thaiResult.stderr}');
        final thai = jsonDecode(thaiResult.stdout as String) as Map<String, dynamic>;
        final englishResult = await Process.run('plutil', [
          '-convert',
          'json',
          '-o',
          '-',
          '${temp.path}/Runner.app/en.lproj/InfoPlist.strings',
        ]);
        final english = jsonDecode(englishResult.stdout as String) as Map<String, dynamic>;
        expect(thai['CFBundleDisplayName'], english['CFBundleDisplayName'], reason: configuration);
        for (final key in [
          'NSCameraUsageDescription',
          'NSFaceIDUsageDescription',
          'NSBluetoothAlwaysUsageDescription',
          'NSBluetoothPeripheralUsageDescription',
          'NSLocalNetworkUsageDescription',
        ]) {
          expect(thai[key], matches(RegExp(r'[\u0E00-\u0E7F]')), reason: '$configuration: $key');
          expect(thai[key], sourceStrings[key], reason: '$configuration: $key');
        }
      }
    },
    skip: !Platform.isMacOS ? 'Requires macOS plutil to validate the Xcode build script.' : false,
  );
}
