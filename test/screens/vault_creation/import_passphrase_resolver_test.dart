import 'dart:convert';
import 'dart:typed_data';

import 'package:coconut_vault/isolates/wallet_isolates/wallet_isolates.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/import_passphrase_resolver.dart';
import 'package:coconut_vault/utils/nfkd_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loader_overlay/loader_overlay.dart';

const _mnemonic = 'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

Uint8List _secret() => Uint8List.fromList(utf8.encode(_mnemonic));

Future<ImportPassphraseResult> _resolve(
  WidgetTester tester, {
  required String passphrase,
  ImportPassphraseMatcher? matcher,
}) async {
  late BuildContext context;
  await tester.pumpWidget(
    MaterialApp(
      home: LoaderOverlay(
        child: Builder(
          builder: (ctx) {
            context = ctx;
            return const SizedBox();
          },
        ),
      ),
    ),
  );
  final result = await resolveImportPassphrase(context, secret: _secret(), passphrase: passphrase, matcher: matcher);
  await tester.pumpAndSettle();
  return result;
}

Uint8List _selectedBytes(ImportPassphraseResult result) {
  expect(result, isA<ImportPassphraseSelected>());
  return (result as ImportPassphraseSelected).passphrase;
}

void main() {
  const koreanPassphrase = '코코넛2026';
  final nfkdBytes = NfkdUtil.encodeNfkd(koreanPassphrase);
  final legacyBytes = Uint8List.fromList(utf8.encode(koreanPassphrase));

  group('resolveImportPassphrase', () {
    testWidgets('정규화로 바뀌지 않는 패스프레이즈는 선택 없이 그대로 쓴다', (tester) async {
      final result = await _resolve(tester, passphrase: 'coconut-123!');

      expect(_selectedBytes(result), utf8.encode('coconut-123!'));
    });

    testWidgets('matcher가 정규화하지 않은 후보만 맞다고 하면 그 후보를 고른다', (tester) async {
      final result = await _resolve(
        tester,
        passphrase: koreanPassphrase,
        matcher: ImportPassphraseMatcher((_, passphrase) async => listEqualsBytes(passphrase, legacyBytes)),
      );

      expect(_selectedBytes(result), legacyBytes);
    });

    testWidgets('두 후보가 모두 맞으면 NFKD를 먼저 고른다', (tester) async {
      final result = await _resolve(
        tester,
        passphrase: koreanPassphrase,
        matcher: ImportPassphraseMatcher((_, __) async => true),
      );

      expect(_selectedBytes(result), nfkdBytes);
    });

    testWidgets('맞는 후보가 없으면 NoMatch를 반환한다', (tester) async {
      final result = await _resolve(
        tester,
        passphrase: koreanPassphrase,
        matcher: ImportPassphraseMatcher((_, __) async => false),
      );

      expect(result, isA<ImportPassphraseNoMatch>());
    });

    testWidgets('정규화로 바뀌지 않아도 matcher가 맞지 않으면 NoMatch를 반환한다', (tester) async {
      final result = await _resolve(
        tester,
        passphrase: 'coconut',
        matcher: ImportPassphraseMatcher((_, __) async => false),
      );

      expect(result, isA<ImportPassphraseNoMatch>());
    });

    testWidgets('proceedWithNfkdWhenNoMatch면 맞는 후보가 없어도 NFKD로 진행한다', (tester) async {
      final result = await _resolve(
        tester,
        passphrase: koreanPassphrase,
        matcher: ImportPassphraseMatcher((_, __) async => false, proceedWithNfkdWhenNoMatch: true),
      );

      expect(_selectedBytes(result), nfkdBytes);
    });

    testWidgets('이전 방식 버전 정보가 없는 실행(flavor 없음)에서는 선택 없이 NFKD를 쓴다', (tester) async {
      // 테스트 실행은 flavor가 없으므로 kLastUnnormalizedPassphraseVersion이 null이다.
      final result = await _resolve(tester, passphrase: koreanPassphrase);

      expect(_selectedBytes(result), nfkdBytes);
    });
  });

  group('WalletIsolates.deriveMasterFingerprints', () {
    test('패스프레이즈 후보마다 MFP를 계산한다', () async {
      final result = await WalletIsolates.deriveMasterFingerprints({
        'mnemonic': _secret(),
        'passphrases': [Uint8List(0), Uint8List.fromList(nfkdBytes), Uint8List.fromList(legacyBytes)],
      });

      // 기대값은 앱과 별개로 BIP39/BIP32 참조 구현(Python hashlib + secp256k1)으로 계산했다.
      expect(result[0], '73C5DA0A'); // 패스프레이즈 없음 (BIP39 테스트 벡터)
      expect(result[1], '86F41C46'); // NFKD('코코넛2026') — Sparrow 등 표준 지갑과 같은 지갑
      expect(result[2], '17F7E6FD'); // 정규화하지 않은 UTF-8('코코넛2026') — 3.2.0 이하 코코넛 볼트
    });
  });
}

bool listEqualsBytes(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
