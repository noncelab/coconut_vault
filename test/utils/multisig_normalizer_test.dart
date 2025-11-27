// test/utils/multisig_normalizer_test.dart

import 'package:coconut_vault/utils/bip/multisig_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MultisigNormalizer.fromCoordinatorResult', () {
    test('Sparrow/Blue Wallet 스타일 텍스트를 정상 파싱한다', () {
      const input = '''
# Blue Wallet Vault Multisig setup file (created by Sparrow)
#
Name: multisig2
Policy: 2 of 3
Derivation: m/48'/1'/0'/2'
Format: P2WSH

73C5DA0A: tpubDFH9dgzveyD8zTbPUFuLrGmCydNvxehyNdUXKJAQN8x4aZ4j6UZqGfnqFrD4NqyaTVGKbvEW54tsvPTK2UoSbCC1PJY8iCNiwTL3RWZEheQ
A0F6BA00: tpubDFX3DiBn9TanpuwxEbfBfPoRDtfGuwRNpkCFf4Yq22SMSGhr4zLhMBFSbTR7jFnLbNdqvtLUyuSAYk4jR8vSa4h2m8qL6zxwU4bYE1wGmDF
A3B2EB70: tpubDFXHjN6AZbhZd5H6XhMWAKjoCn9r9Uj6sMtyXKTkN3HAaYEMEGKzU836gkxcF7PUT3BgMUj8KPmU447kzo1naMetkyWNRoBapfAbqWqUuzQ
''';

      final config = MultisigNormalizer.fromCoordinatorResult(input);

      expect(config.name, 'multisig2');
      expect(config.requiredCount, 2);
      expect(config.signerBsms, hasLength(3));
      expect(config.signerBsms[0], contains('73C5DA0A'));
      expect(config.signerBsms[1], contains('A0F6BA00'));
      expect(config.signerBsms[2], contains('A3B2EB70'));

      print('--> config: ${config.signerBsms.join('\n')}');
    });

    test('JSON 형식을 정상 파싱한다', () {
      const input = '''
{
 "label": "multisig2",
  "blockheight": 140309,
  "descriptor": "wsh(sortedmulti(2,[73c5da0a/48h/1h/0h/2h]tpubDFH9dgzveyD8zTbPUFuLrGmCydNvxehyNdUXKJAQN8x4aZ4j6UZqGfnqFrD4NqyaTVGKbvEW54tsvPTK2UoSbCC1PJY8iCNiwTL3RWZEheQ,[a0f6ba00/48h/1h/0h/2h]tpubDFX3DiBn9TanpuwxEbfBfPoRDtfGuwRNpkCFf4Yq22SMSGhr4zLhMBFSbTR7jFnLbNdqvtLUyuSAYk4jR8vSa4h2m8qL6zxwU4bYE1wGmDF,[a3b2eb70/48h/1h/0h/2h]tpubDFXHjN6AZbhZd5H6XhMWAKjoCn9r9Uj6sMtyXKTkN3HAaYEMEGKzU836gkxcF7PUT3BgMUj8KPmU447kzo1naMetkyWNRoBapfAbqWqUuzQ))#pmgfjdf3"
}
''';

      final config = MultisigNormalizer.fromCoordinatorResult(input);

      expect(config.name, 'multisig2');
      expect(config.requiredCount, 2);
      expect(config.signerBsms, hasLength(3));
      expect(config.signerBsms[0], contains('73c5da0a'.toUpperCase()));
      expect(config.signerBsms[1], contains('a0f6ba00'.toUpperCase()));
      expect(config.signerBsms[2], contains('a3b2eb70'.toUpperCase()));

      print('--> config: ${config.signerBsms.join('\n')}');
    });

    test('Coconut JSON 형식을 정상 파싱한다', () {
      const input = '''
{name: 핳핳, colorIndex: 9, iconIndex: 0, namesMap: {73C5DA0A: test1, A3B2EB70: test2}, coordinatorBsms: BSMS 1.0
wsh(sortedmulti(2,[73C5DA0A/48'/1'/0'/2']Vpub5n95dMZrDHj6SeBgJ1oz4Fae2N2eJNuWK3VTKDb2dzGpMFLUHLmtyDfen7AaQxwQ5mZnMyXdVrkEaoMLVTH8FmVBRVWPGFYWhmtDUGehGmq/<0;1>/*,[A3B2EB70/48'/1'/0'/2']Vpub5nPDj2f67vDX5FsPMTG9NJZEFWoZVCvdomuuXEtNdtbvMEW6R8Y4AfuvD1v8HEMJ5KV97Y2FkBcpiU1nTmVUEvx4oAUcyrMNayimtFvjGQs/<0;1>/*))#68alx3dv
/0/*,/1/*
bcrt1qe9kjcm3ydmwu90jqaj5tx257jq9gnvm2zxr2whu0ttreqgruj5mqvx499u}
''';

      final config = MultisigNormalizer.fromCoordinatorResult(input);

      expect(config.name, '핳핳');
      expect(config.requiredCount, 2);
      expect(config.signerBsms, hasLength(2));
      expect(config.signerBsms[0], contains('73C5DA0A'));
      expect(config.signerBsms[1], contains('A3B2EB70'));
      expect(config.signerBsms[0], contains("48'/1'/0'/2'"));
      expect(config.signerBsms[1], contains("48'/1'/0'/2'"));
      expect(config.signerBsms[0], contains("test1"));
      expect(config.signerBsms[1], contains("test2"));
    });

    test('JSON String 형식을 정상 파싱한다 - no double quotes', () {
      const input = '''
{label: multisig2, blockheight: 140309, descriptor: wsh(sortedmulti(2,[73c5da0a/48h/1h/0h/2h]tpubDFH9dgzveyD8zTbPUFuLrGmCydNvxehyNdUXKJAQN8x4aZ4j6UZqGfnqFrD4NqyaTVGKbvEW54tsvPTK2UoSbCC1PJY8iCNiwTL3RWZEheQ,[a0f6ba00/48h/1h/0h/2h]tpubDFX3DiBn9TanpuwxEbfBfPoRDtfGuwRNpkCFf4Yq22SMSGhr4zLhMBFSbTR7jFnLbNdqvtLUyuSAYk4jR8vSa4h2m8qL6zxwU4bYE1wGmDF,[a3b2eb70/48h/1h/0h/2h]tpubDFXHjN6AZbhZd5H6XhMWAKjoCn9r9Uj6sMtyXKTkN3HAaYEMEGKzU836gkxcF7PUT3BgMUj8KPmU447kzo1naMetkyWNRoBapfAbqWqUuzQ))#pmgfjdf3}
''';

      final config = MultisigNormalizer.fromCoordinatorResult(input);

      expect(config.name, 'multisig2');
      expect(config.requiredCount, 2);
      expect(config.signerBsms, hasLength(3));
      expect(config.signerBsms[0], contains('73c5da0a'.toUpperCase()));
      expect(config.signerBsms[1], contains('a0f6ba00'.toUpperCase()));
      expect(config.signerBsms[2], contains('a3b2eb70'.toUpperCase()));

      print('--> config: ${config.signerBsms.join('\n')}');
    });
  });
}
