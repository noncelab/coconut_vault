// test/utils/multisig_normalizer_test.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:cbor/cbor.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/model/exception/network_mismatch_exception.dart';
import 'package:coconut_vault/utils/bip/multisig_normalizer.dart';
import 'package:coconut_vault/utils/bip/normalized_multisig_config.dart';
import 'package:coconut_vault/utils/ur_bytes_converter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ur/ur.dart';
import 'package:ur/ur_decoder.dart';

Map<String, dynamic> _convertKeysToString(Map<dynamic, dynamic> map) {
  return map.map((key, value) {
    String newKey = key.toString();
    dynamic newValue;
    if (value is Map) {
      newValue = _convertKeysToString(value);
    } else if (value is List) {
      newValue =
          value.map((item) {
            if (item is Map) {
              return _convertKeysToString(item);
            } else {
              return item;
            }
          }).toList();
    } else {
      newValue = value;
    }
    return MapEntry(newKey, newValue);
  });
}

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

  group('NormalizedMultisigConfig.getMultisigConfigString', () {
    test('regtest: 생성된 문자열이 Keystone 포맷과 일치해야 한다', () {
      // given
      const bsms1 = '''
BSMS 1.0
00
[73c5da0a/48'/0'/0'/2']xpub6E9t6eQGiTVTG99xWo6KEdYAVyGtrmkCNgbTPVPSEvA6wgAS2irZxLdvbLBTz5XURtLSB2LPMZHf85CJxapgr8NpYcdDX56UKpVvZ5qxu9k
mother
''';

      const bsms2 = '''
BSMS 1.0
00
[a0f6ba00/48'/0'/0'/2']xpub6Dtc8ee6APa87VBy7LoZo6RfdGY3k8gnPzT1TYvHygVPJhur24RgEk9FftpzcvPhQgk9j5WKr5jkxs1Lhew25ffN5tLQfkcdE6Lz5DosnsT
father
''';

      // 네트워크 타입을 regtest로 설정
      NetworkType.setNetworkType(NetworkType.regtest);

      final config = NormalizedMultisigConfig(name: 'family-multisig', requiredCount: 2, signerBsms: [bsms1, bsms2]);

      // when
      final result = config.getMultisigConfigString();

      // then
      final expected =
          StringBuffer()
            ..writeln('# Keystone Multisig setup file (created by Coconut Vault)')
            ..writeln('#')
            ..writeln()
            ..writeln('Name: family-multisig')
            ..writeln('Policy: 2 of 2')
            ..writeln("Derivation: m/48'/1'/0'/2'")
            ..writeln('Format: P2WSH')
            ..writeln()
            ..writeln(
              '73C5DA0A: xpub6E9t6eQGiTVTG99xWo6KEdYAVyGtrmkCNgbTPVPSEvA6wgAS2irZxLdvbLBTz5XURtLSB2LPMZHf85CJxapgr8NpYcdDX56UKpVvZ5qxu9k',
            )
            ..writeln(
              'A0F6BA00: xpub6Dtc8ee6APa87VBy7LoZo6RfdGY3k8gnPzT1TYvHygVPJhur24RgEk9FftpzcvPhQgk9j5WKr5jkxs1Lhew25ffN5tLQfkcdE6Lz5DosnsT',
            );

      expect(result, expected.toString());
      print('--> result: \n$result');
    });

    test('mainnet: 생성된 문자열이 Keystone 포맷과 일치해야 한다', () {
      // given
      const bsms1 = '''
BSMS 1.0
00
[73c5da0a/48'/0'/0'/2']xpub6E9t6eQGiTVTG99xWo6KEdYAVyGtrmkCNgbTPVPSEvA6wgAS2irZxLdvbLBTz5XURtLSB2LPMZHf85CJxapgr8NpYcdDX56UKpVvZ5qxu9k
mother
''';

      const bsms2 = '''
BSMS 1.0
00
[a0f6ba00/48'/0'/0'/2']xpub6Dtc8ee6APa87VBy7LoZo6RfdGY3k8gnPzT1TYvHygVPJhur24RgEk9FftpzcvPhQgk9j5WKr5jkxs1Lhew25ffN5tLQfkcdE6Lz5DosnsT
father
''';

      // 네트워크 타입을 mainnet으로 설정
      NetworkType.setNetworkType(NetworkType.mainnet);

      final config = NormalizedMultisigConfig(name: 'family-multisig', requiredCount: 2, signerBsms: [bsms1, bsms2]);

      // when
      final result = config.getMultisigConfigString();

      // then
      final expected =
          StringBuffer()
            ..writeln('# Keystone Multisig setup file (created by Coconut Vault)')
            ..writeln('#')
            ..writeln()
            ..writeln('Name: family-multisig')
            ..writeln('Policy: 2 of 2')
            ..writeln("Derivation: m/48'/0'/0'/2'")
            ..writeln('Format: P2WSH')
            ..writeln()
            ..writeln(
              '73C5DA0A: xpub6E9t6eQGiTVTG99xWo6KEdYAVyGtrmkCNgbTPVPSEvA6wgAS2irZxLdvbLBTz5XURtLSB2LPMZHf85CJxapgr8NpYcdDX56UKpVvZ5qxu9k',
            )
            ..writeln(
              'A0F6BA00: xpub6Dtc8ee6APa87VBy7LoZo6RfdGY3k8gnPzT1TYvHygVPJhur24RgEk9FftpzcvPhQgk9j5WKr5jkxs1Lhew25ffN5tLQfkcdE6Lz5DosnsT',
            );

      expect(result, expected.toString());
      print('--> result: \n$result');
    });
  });

  group('MultisigNormalizer.signerBsmsFromUrResult', () {
    test('ur-decoder test', () {
      NetworkType.setNetworkType(NetworkType.mainnet);
      final urParts = [
        // 'UR:CRYPTO-ACCOUNT/OEADCYOTPRWMJOAOLYTAADMETAADDLOLAOWKAXHDCLAOGUBYCFTLBNBNLGFLHFBEZECHNSECAAONCXHYPFAMFNCSVDJYSBRSECGEGUDEHEYKAAHDCXFTCYJEFLWSOXWMIHRPIMYACLLPURCYSSIOSEIOSOSPRFUYJZVDKKBEDWLYCKIHDKAHTAADEHOEADAEAOAEAMTAADDYOTADLOCSDYYKAEYKAEYKAOYKAOCYOTPRWMJOAXAAAYCYGHIELYGEVEATAHFR',
        'UR:CRYPTO-ACCOUNT/OEADCYJKSKTNBKAOLYTAADMETAADDLOLAOWKAXHDCLAOCYFRYKZOYLEMTIWFINMUZCFGUOGABWASFRWMGUDPIHGWVTURTALUTDKPLPUONEDTAAHDCXRKNBSTSGCMBKLTBAZERHFZPYMHTIWKDEGWWDCWHYBTCLCHIOKBLFFHSRKBDPHGIAAHTAADEHOEADAEAOAEAMTAADDYOTADLOCSDYYKAEYKAEYKAOYKAOCYJKSKTNBKAXAAAYCYCEWZMSCMCHOLYNKG',
      ];

      final decoder = URDecoder();
      for (final part in urParts) {
        decoder.receivePart(part);
      }
      final mapResult = UrBytesConverter.convertToMap(decoder.result);
      print('--> decoder.result: ${decoder.result}');
      // print(jsonEncode(decoder.result));

      final convertedMap = _convertKeysToString(mapResult as Map<dynamic, dynamic>);
      print(jsonEncode(_convertKeysToString(mapResult)));

      // final bsms = MultisigNormalizer.signerBsmsFromUrResult(mapResult);
      // print('--> bsms: $bsms');
    });
    test('regtest: 키스톤 UR 결과를 정상적으로 BSMS 형식으로 변환한다', () {
      // given
      NetworkType.setNetworkType(NetworkType.regtest);

      // 실제 키스톤 UR 예시 (regtest용)
      final urParts = [
        'UR:CRYPTO-ACCOUNT/OEADCYOTPRWMJOAOLYTAADMETAADDLOLAOWKAXHDCLAOGUBYCFTLBNBNLGFLHFBEZECHNSECAAONCXHYPFAMFNCSVDJYSBRSECGEGUDEHEYKAAHDCXFTCYJEFLWSOXWMIHRPIMYACLLPURCYSSIOSEIOSOSPRFUYJZVDKKBEDWLYCKIHDKAHTAADEHOEADAEAOAEAMTAADDYOTADLOCSDYYKAEYKAEYKAOYKAOCYOTPRWMJOAXAAAYCYGHIELYGEVEATAHFR',
      ];

      final decoder = URDecoder();
      for (final part in urParts) {
        decoder.receivePart(part);
      }

      expect(decoder.isComplete(), true, reason: 'UR 디코딩이 완료되어야 함');
      expect(decoder.isSuccess(), true, reason: 'UR 디코딩이 성공해야 함');

      final mapResult = UrBytesConverter.convertToMap(decoder.result);
      expect(mapResult, isNotNull, reason: 'UR 결과가 Map으로 변환되어야 함');

      // when
      final bsms = MultisigNormalizer.signerBsmsFromUrResult(mapResult!);

      // then
      expect(bsms, isNotEmpty, reason: 'BSMS 문자열이 생성되어야 함');
      expect(bsms, startsWith('BSMS 1.0'), reason: 'BSMS 형식으로 시작해야 함');
      expect(bsms, contains('00'), reason: 'BSMS 버전 정보가 포함되어야 함');

      // fingerprint와 derivation path가 포함되어야 함
      expect(bsms, contains('48'), reason: 'derivation path에 48이 포함되어야 함');
      expect(bsms, contains('1'), reason: 'regtest이므로 coin type 1이 포함되어야 함');
      expect(bsms, contains('2'), reason: 'script type 2가 포함되어야 함');

      print('--> signerBsms: \n$bsms');
    });

    test('mainnet: 키스톤 UR 결과를 정상적으로 BSMS 형식으로 변환한다', () {
      // given
      NetworkType.setNetworkType(NetworkType.mainnet);

      // 실제 키스톤 UR 예시 (mainnet용 - coin type 0)
      // 실제 UR 데이터가 필요하지만, 일단 구조만 테스트
      // 실제로는 mainnet용 UR을 사용해야 함

      // Mock UR 결과 구조 생성
      final mockUrResult = <dynamic, dynamic>{
        2: [
          // accounts list
          <dynamic, dynamic>{
            3: CborBytes(Uint8List.fromList([0x02] + List.filled(32, 0))), // pubkey (33 bytes)
            4: CborBytes(Uint8List.fromList(List.filled(32, 0))), // chaincode (32 bytes)
            6: <dynamic, dynamic>{
              // origin
              1: [48, true, 0, true, 0, true, 2, true], // path: m/48'/0'/0'/2'
              2: 0x73C5DA0A, // master fingerprint (decimal)
            },
          },
        ],
      };

      // when
      final bsms = MultisigNormalizer.signerBsmsFromUrResult(mockUrResult);

      // then
      expect(bsms, isNotEmpty, reason: 'BSMS 문자열이 생성되어야 함');
      expect(bsms, startsWith('BSMS 1.0'), reason: 'BSMS 형식으로 시작해야 함');
      expect(bsms, contains('73C5DA0A'), reason: 'master fingerprint가 포함되어야 함');
      expect(bsms, contains("48'/0'/0'/2'"), reason: 'derivation path가 포함되어야 함');

      print('--> signerBsms: \n$bsms');
    });

    test('필요한 필드가 없을 때 FormatException을 던진다', () {
      // given
      final invalidMap = <dynamic, dynamic>{
        // '2' 키가 없음
      };

      // when & then
      expect(() => MultisigNormalizer.signerBsmsFromUrResult(invalidMap), throwsA(isA<FormatException>()));
    });

    test('accounts 리스트가 비어있을 때 FormatException을 던진다', () {
      // given
      final invalidMap = <dynamic, dynamic>{
        2: <dynamic>[], // 빈 리스트
      };

      // when & then
      expect(() => MultisigNormalizer.signerBsmsFromUrResult(invalidMap), throwsA(isA<FormatException>()));
    });

    test('P2WSH derivation path가 없을 때 FormatException을 던진다', () {
      // given
      NetworkType.setNetworkType(NetworkType.mainnet);

      final invalidMap = <dynamic, dynamic>{
        2: [
          // accounts list
          <dynamic, dynamic>{
            3: CborBytes(Uint8List.fromList([0x02] + List.filled(32, 0))),
            4: CborBytes(Uint8List.fromList(List.filled(32, 0))),
            6: <dynamic, dynamic>{
              1: [44, true, 0, true, 0, true], // 다른 derivation path (P2PKH)
              2: 0x73C5DA0A,
            },
          },
        ],
      };

      // when & then
      expect(() => MultisigNormalizer.signerBsmsFromUrResult(invalidMap), throwsA(isA<FormatException>()));
    });

    test('네트워크 불일치 시 NetworkMismatchException을 던진다', () {
      // given
      NetworkType.setNetworkType(NetworkType.mainnet);

      final invalidMap = <dynamic, dynamic>{
        2: [
          // accounts list
          <dynamic, dynamic>{
            3: CborBytes(Uint8List.fromList([0x02] + List.filled(32, 0))),
            4: CborBytes(Uint8List.fromList(List.filled(32, 0))),
            6: <dynamic, dynamic>{
              1: [48, true, 1, true, 0, true, 2, true], // testnet coin type (1)
              2: 0x73C5DA0A,
            },
          },
        ],
      };

      // when & then
      expect(() => MultisigNormalizer.signerBsmsFromUrResult(invalidMap), throwsA(isA<NetworkMismatchException>()));
    });

    test('master fingerprint가 없을 때 FormatException을 던진다', () {
      // given
      NetworkType.setNetworkType(NetworkType.mainnet);

      final invalidMap = <dynamic, dynamic>{
        2: [
          // accounts list
          <dynamic, dynamic>{
            3: CborBytes(Uint8List.fromList([0x02] + List.filled(32, 0))),
            4: CborBytes(Uint8List.fromList(List.filled(32, 0))),
            6: <dynamic, dynamic>{
              1: [48, true, 0, true, 0, true, 2, true],
              // '2' 키 (master fingerprint)가 없음
            },
          },
        ],
      };

      // when & then
      expect(() => MultisigNormalizer.signerBsmsFromUrResult(invalidMap), throwsA(isA<FormatException>()));
    });
  });
}
