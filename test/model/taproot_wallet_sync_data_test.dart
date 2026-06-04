import 'dart:convert';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/model/taproot/taproot_wallet_sync_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() {
    NetworkType.setNetworkType(NetworkType.testnet);
  });

  final rawCase1 = jsonEncode({
    "name": "Skirt1+Prison",
    "colorIndex": 2,
    "iconIndex": 1,
    "descriptor":
        "tr([6213D91E/86'/1'/0']tpubDDa4Jsxcnams3Nijs1QqciRAVzofLZfvGzLDhoN1j9e6nDmKBuWieycjXdbyK94hmCi9EpG7u3n6jFdZyvvnE9JsPSw5r5uq7C7rCcye2p2/<0;1>/*,{and_v(v:pk([A0F6BA00/86'/1'/0']tpubDCteo5kJNojzeAm6P9w688A9jvngmZgAkRSYdULTqTU1Jm39gHNnkBHMPYWC3s4HkBUhMcJNowFuHczEi9JwWdRZwnv8eRetwKY7RbmUxdU/<0;1>/*),older(1780012800))})#s63akr4t",
    "keyPathSeedInfos": [
      "tpubDDa4Jsxcnams3Nijs1QqciRAVzofLZfvGzLDhoN1j9e6nDmKBuWieycjXdbyK94hmCi9EpG7u3n6jFdZyvvnE9JsPSw5r5uq7C7rCcye2p2"
    ],
    "scriptPathSeedInfos": [
      {
        "miniscript":
            "and_v(v:pk([A0F6BA00/86'/1'/0']tpubDCteo5kJNojzeAm6P9w688A9jvngmZgAkRSYdULTqTU1Jm39gHNnkBHMPYWC3s4HkBUhMcJNowFuHczEi9JwWdRZwnv8eRetwKY7RbmUxdU/<0;1>/*),older(1780012800))",
        "extendedPublicKeys": [
          "tpubDCteo5kJNojzeAm6P9w688A9jvngmZgAkRSYdULTqTU1Jm39gHNnkBHMPYWC3s4HkBUhMcJNowFuHczEi9JwWdRZwnv8eRetwKY7RbmUxdU"
        ],
      }
    ],
  });

  final rawCase2 = jsonEncode({
    "name": "Skirt1/Prison/bigLockTime",
    "colorIndex": 2,
    "iconIndex": 1,
    "descriptor":
        "tr([6213D91E/86'/1'/0']tpubDDa4Jsxcnams3Nijs1QqciRAVzofLZfvGzLDhoN1j9e6nDmKBuWieycjXdbyK94hmCi9EpG7u3n6jFdZyvvnE9JsPSw5r5uq7C7rCcye2p2/<0;1>/*,{and_v(v:pk([A0F6BA00/86'/1'/0']tpubDCteo5kJNojzeAm6P9w688A9jvngmZgAkRSYdULTqTU1Jm39gHNnkBHMPYWC3s4HkBUhMcJNowFuHczEi9JwWdRZwnv8eRetwKY7RbmUxdU/<0;1>/*),older(1811462400))})#mqhpy92r",
    "keyPathSeedInfos": [
      "tpubDDa4Jsxcnams3Nijs1QqciRAVzofLZfvGzLDhoN1j9e6nDmKBuWieycjXdbyK94hmCi9EpG7u3n6jFdZyvvnE9JsPSw5r5uq7C7rCcye2p2"
    ],
    "scriptPathSeedInfos": [
      {
        "miniscript":
            "and_v(v:pk([A0F6BA00/86'/1'/0']tpubDCteo5kJNojzeAm6P9w688A9jvngmZgAkRSYdULTqTU1Jm39gHNnkBHMPYWC3s4HkBUhMcJNowFuHczEi9JwWdRZwnv8eRetwKY7RbmUxdU/<0;1>/*),older(1811462400))",
        "extendedPublicKeys": [
          "tpubDCteo5kJNojzeAm6P9w688A9jvngmZgAkRSYdULTqTU1Jm39gHNnkBHMPYWC3s4HkBUhMcJNowFuHczEi9JwWdRZwnv8eRetwKY7RbmUxdU"
        ],
      }
    ],
  });

  final rawCase3 = jsonEncode({
    "name": "Skirt1+Prison",
    "colorIndex": 2,
    "iconIndex": 1,
    "descriptor":
        "tr([6213D91E/86'/1'/0']tpubDDa4Jsxcnams3Nijs1QqciRAVzofLZfvGzLDhoN1j9e6nDmKBuWieycjXdbyK94hmCi9EpG7u3n6jFdZyvvnE9JsPSw5r5uq7C7rCcye2p2/<0;1>/*,{and_v(v:pk([A0F6BA00/86'/1'/0']tpubDCteo5kJNojzeAm6P9w688A9jvngmZgAkRSYdULTqTU1Jm39gHNnkBHMPYWC3s4HkBUhMcJNowFuHczEi9JwWdRZwnv8eRetwKY7RbmUxdU/<0;1>/*),older(1780012800))})#s63akr4t",
    "scriptPathSeedInfos": [
      {
        "miniscript":
            "and_v(v:pk([A0F6BA00/86'/1'/0']tpubDCteo5kJNojzeAm6P9w688A9jvngmZgAkRSYdULTqTU1Jm39gHNnkBHMPYWC3s4HkBUhMcJNowFuHczEi9JwWdRZwnv8eRetwKY7RbmUxdU/<0;1>/*),older(1780012800))",
        "extendedPublicKeys": [
          "tpubDCteo5kJNojzeAm6P9w688A9jvngmZgAkRSYdULTqTU1Jm39gHNnkBHMPYWC3s4HkBUhMcJNowFuHczEi9JwWdRZwnv8eRetwKY7RbmUxdU"
        ],
      }
    ],
  });

  final rawCase4 = jsonEncode({
    "name": "Skirt1/Prison/bigLockTime",
    "colorIndex": 2,
    "iconIndex": 1,
    "descriptor":
        "tr([6213D91E/86'/1'/0']tpubDDa4Jsxcnams3Nijs1QqciRAVzofLZfvGzLDhoN1j9e6nDmKBuWieycjXdbyK94hmCi9EpG7u3n6jFdZyvvnE9JsPSw5r5uq7C7rCcye2p2/<0;1>/*,{and_v(v:pk([A0F6BA00/86'/1'/0']tpubDCteo5kJNojzeAm6P9w688A9jvngmZgAkRSYdULTqTU1Jm39gHNnkBHMPYWC3s4HkBUhMcJNowFuHczEi9JwWdRZwnv8eRetwKY7RbmUxdU/<0;1>/*),older(1811462400))})#mqhpy92r",
    "keyPathSeedInfos": [
      "tpubDDa4Jsxcnams3Nijs1QqciRAVzofLZfvGzLDhoN1j9e6nDmKBuWieycjXdbyK94hmCi9EpG7u3n6jFdZyvvnE9JsPSw5r5uq7C7rCcye2p2"
    ],
  });

  group('TaprootWalletSyncData.parse - 유효한 데이터', () {
    test('case1: Skirt1+Prison 데이터를 정상적으로 파싱한다', () {
      final result = TaprootWalletSyncData.parse(rawCase1);

      expect(result.name, 'Skirt1+Prison');
      expect(result.colorIndex, 2);
      expect(result.iconIndex, 1);
      expect(
        result.descriptor,
        "tr([6213D91E/86'/1'/0']tpubDDa4Jsxcnams3Nijs1QqciRAVzofLZfvGzLDhoN1j9e6nDmKBuWieycjXdbyK94hmCi9EpG7u3n6jFdZyvvnE9JsPSw5r5uq7C7rCcye2p2/<0;1>/*,{and_v(v:pk([A0F6BA00/86'/1'/0']tpubDCteo5kJNojzeAm6P9w688A9jvngmZgAkRSYdULTqTU1Jm39gHNnkBHMPYWC3s4HkBUhMcJNowFuHczEi9JwWdRZwnv8eRetwKY7RbmUxdU/<0;1>/*),older(1780012800))})#s63akr4t",
      );
      expect(result.keyPathExtendedPublicKeys, hasLength(1));
      expect(
        result.keyPathExtendedPublicKeys.first,
        "tpubDDa4Jsxcnams3Nijs1QqciRAVzofLZfvGzLDhoN1j9e6nDmKBuWieycjXdbyK94hmCi9EpG7u3n6jFdZyvvnE9JsPSw5r5uq7C7rCcye2p2",
      );
      expect(result.scriptPathSeedInfos, hasLength(1));
      expect(
        result.scriptPathSeedInfos.first.miniscript,
        "and_v(v:pk([A0F6BA00/86'/1'/0']tpubDCteo5kJNojzeAm6P9w688A9jvngmZgAkRSYdULTqTU1Jm39gHNnkBHMPYWC3s4HkBUhMcJNowFuHczEi9JwWdRZwnv8eRetwKY7RbmUxdU/<0;1>/*),older(1780012800))",
      );
      expect(result.scriptPathSeedInfos.first.extendedPublicKeys, hasLength(1));
      expect(
        result.scriptPathSeedInfos.first.extendedPublicKeys.first,
        "tpubDCteo5kJNojzeAm6P9w688A9jvngmZgAkRSYdULTqTU1Jm39gHNnkBHMPYWC3s4HkBUhMcJNowFuHczEi9JwWdRZwnv8eRetwKY7RbmUxdU",
      );
    });

    test('case2: Skirt1/Prison/bigLockTime 데이터를 정상적으로 파싱한다', () {
      final result = TaprootWalletSyncData.parse(rawCase2);

      expect(result.name, 'Skirt1/Prison/bigLockTime');
      expect(result.colorIndex, 2);
      expect(result.iconIndex, 1);
      expect(
        result.descriptor,
        "tr([6213D91E/86'/1'/0']tpubDDa4Jsxcnams3Nijs1QqciRAVzofLZfvGzLDhoN1j9e6nDmKBuWieycjXdbyK94hmCi9EpG7u3n6jFdZyvvnE9JsPSw5r5uq7C7rCcye2p2/<0;1>/*,{and_v(v:pk([A0F6BA00/86'/1'/0']tpubDCteo5kJNojzeAm6P9w688A9jvngmZgAkRSYdULTqTU1Jm39gHNnkBHMPYWC3s4HkBUhMcJNowFuHczEi9JwWdRZwnv8eRetwKY7RbmUxdU/<0;1>/*),older(1811462400))})#mqhpy92r",
      );
      expect(result.keyPathExtendedPublicKeys, hasLength(1));
      expect(
        result.keyPathExtendedPublicKeys.first,
        "tpubDDa4Jsxcnams3Nijs1QqciRAVzofLZfvGzLDhoN1j9e6nDmKBuWieycjXdbyK94hmCi9EpG7u3n6jFdZyvvnE9JsPSw5r5uq7C7rCcye2p2",
      );
      expect(result.scriptPathSeedInfos, hasLength(1));
      expect(
        result.scriptPathSeedInfos.first.miniscript,
        "and_v(v:pk([A0F6BA00/86'/1'/0']tpubDCteo5kJNojzeAm6P9w688A9jvngmZgAkRSYdULTqTU1Jm39gHNnkBHMPYWC3s4HkBUhMcJNowFuHczEi9JwWdRZwnv8eRetwKY7RbmUxdU/<0;1>/*),older(1811462400))",
      );
      expect(result.scriptPathSeedInfos.first.extendedPublicKeys, hasLength(1));
      expect(
        result.scriptPathSeedInfos.first.extendedPublicKeys.first,
        "tpubDCteo5kJNojzeAm6P9w688A9jvngmZgAkRSYdULTqTU1Jm39gHNnkBHMPYWC3s4HkBUhMcJNowFuHczEi9JwWdRZwnv8eRetwKY7RbmUxdU",
      );
    });
  });

  group('TaprootWalletSyncData.parse - 유효하지 않은 데이터', () {
    test('유효하지 않은 JSON 문자열이면 FormatException을 던진다', () {
      expect(() => TaprootWalletSyncData.parse('not-json'), throwsA(isA<FormatException>()));
    });

    test('JSON 배열이면 FormatException을 던진다', () {
      expect(
        () => TaprootWalletSyncData.parse(jsonEncode([])),
        throwsA(isA<FormatException>()),
      );
    });

    test('name이 없으면 FormatException을 던진다', () {
      final json = jsonDecode(rawCase1) as Map<String, dynamic>;
      json.remove('name');
      expect(() => TaprootWalletSyncData.parse(jsonEncode(json)), throwsA(isA<FormatException>()));
    });

    test('name이 빈 문자열이면 FormatException을 던진다', () {
      final json = jsonDecode(rawCase1) as Map<String, dynamic>;
      json['name'] = '';
      expect(() => TaprootWalletSyncData.parse(jsonEncode(json)), throwsA(isA<FormatException>()));
    });

    test('colorIndex가 없으면 FormatException을 던진다', () {
      final json = jsonDecode(rawCase1) as Map<String, dynamic>;
      json.remove('colorIndex');
      expect(() => TaprootWalletSyncData.parse(jsonEncode(json)), throwsA(isA<FormatException>()));
    });

    test('colorIndex가 String이면 FormatException을 던진다', () {
      final json = jsonDecode(rawCase1) as Map<String, dynamic>;
      json['colorIndex'] = '2';
      expect(() => TaprootWalletSyncData.parse(jsonEncode(json)), throwsA(isA<FormatException>()));
    });

    test('iconIndex가 없으면 FormatException을 던진다', () {
      final json = jsonDecode(rawCase1) as Map<String, dynamic>;
      json.remove('iconIndex');
      expect(() => TaprootWalletSyncData.parse(jsonEncode(json)), throwsA(isA<FormatException>()));
    });

    test('descriptor가 없으면 FormatException을 던진다', () {
      final json = jsonDecode(rawCase1) as Map<String, dynamic>;
      json.remove('descriptor');
      expect(() => TaprootWalletSyncData.parse(jsonEncode(json)), throwsA(isA<FormatException>()));
    });

    test('keyPathSeedInfos가 없으면 빈 배열로 파싱이 성공한다', () {
      final json = jsonDecode(rawCase1) as Map<String, dynamic>;
      json.remove('keyPathSeedInfos');
      final result = TaprootWalletSyncData.parse(jsonEncode(json));
      expect(result.keyPathExtendedPublicKeys, isEmpty);
    });

    test('keyPathSeedInfos 항목이 빈 문자열이면 FormatException을 던진다', () {
      final json = jsonDecode(rawCase1) as Map<String, dynamic>;
      json['keyPathSeedInfos'] = [''];
      expect(() => TaprootWalletSyncData.parse(jsonEncode(json)), throwsA(isA<FormatException>()));
    });

    test('scriptPathSeedInfos가 없으면 빈 배열로 파싱이 성공한다', () {
      final json = jsonDecode(rawCase1) as Map<String, dynamic>;
      json.remove('scriptPathSeedInfos');
      final result = TaprootWalletSyncData.parse(jsonEncode(json));
      expect(result.scriptPathSeedInfos, isEmpty);
    });

    test('scriptPathSeedInfos 항목이 Map이 아니면 FormatException을 던진다', () {
      final json = jsonDecode(rawCase1) as Map<String, dynamic>;
      json['scriptPathSeedInfos'] = ['not-a-map'];
      expect(() => TaprootWalletSyncData.parse(jsonEncode(json)), throwsA(isA<FormatException>()));
    });

    test('scriptPathSeedInfos 항목에 miniscript가 없으면 FormatException을 던진다', () {
      final json = jsonDecode(rawCase1) as Map<String, dynamic>;
      (json['scriptPathSeedInfos'] as List).first.remove('miniscript');
      expect(() => TaprootWalletSyncData.parse(jsonEncode(json)), throwsA(isA<FormatException>()));
    });

  });

  group('TaprootWalletSyncData.parse - keyPathSeedInfos가 없는 rawString', () {
    test('case3: keyPathSeedInfos 필드가 없어도 빈 배열로 파싱이 성공한다', () {
      final result = TaprootWalletSyncData.parse(rawCase3);

      expect(result.name, 'Skirt1+Prison');
      expect(result.colorIndex, 2);
      expect(result.iconIndex, 1);
      expect(result.keyPathExtendedPublicKeys, isEmpty);
      expect(result.scriptPathSeedInfos, hasLength(1));
    });
  });

  group('TaprootWalletSyncData.parse - scriptPathSeedInfos가 없는 rawString', () {
    test('case4: scriptPathSeedInfos 필드가 없어도 빈 배열로 파싱이 성공한다', () {
      final result = TaprootWalletSyncData.parse(rawCase4);

      expect(result.name, 'Skirt1/Prison/bigLockTime');
      expect(result.colorIndex, 2);
      expect(result.iconIndex, 1);
      expect(result.keyPathExtendedPublicKeys, hasLength(1));
      expect(result.scriptPathSeedInfos, isEmpty);
    });
  });
}
