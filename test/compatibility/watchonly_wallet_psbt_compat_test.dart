import 'dart:convert';
import 'dart:io';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/model/multisig/multisig_vault_list_item.dart';
import 'package:coconut_vault/model/single_sig/single_sig_vault_list_item.dart';
import 'package:coconut_vault/providers/sign_provider.dart';
import 'package:coconut_vault/providers/view_model/airgap/psbt_scanner_view_model.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// 타사 watch-only 지갑(BlueWallet, Nunchuk, Sparrow)이 생성한 PSBT가
/// coconut_lib의 `Psbt.matchesVault` 및 Vault 앱의 현재 매칭 로직과 호환되는지 검증한다.
///
/// ## 목적
/// Taproot 지갑은 `Psbt.matchesVault`를 사용하지만, 싱글시그/멀티시그는 타사 지갑과의
/// 호환성 우려로 사용하지 않고 있다. 이 테스트는 타사 PSBT 데이터를 직접 넣어서
/// `matchesVault`가 정상 동작하는지 확인하고, 싱글시그/멀티시그에도 적용 가능한지
/// 판단하는 근거를 제공한다.
///
/// ## 데이터 준비 방법
/// 1. 타사 지갑(Sparrow/BlueWallet/Nunchuk)에서 같은 니모닉으로 watch-only 지갑 생성
/// 2. 타사 지갑에서 PSBT 생성 (unsigned)
/// 3. PSBT base64 문자열을 아래 fixture에 입력
/// 4. 니모닉은 test/test.env 파일의 TEST_MNEMONIC으로 전달 (싱글시그/멀티시그 모두 동일 니모닉 사용)
///    - 니모닉은 보안상 커밋/푸시하지 않도록 하세요.
/// 5. 네트워크(mainnet/regtest)를 맞춰서 설정
///
/// ## 니모닉 설정
/// - `test/test.env` 파일에 `TEST_MNEMONIC`으로 설정합니다. (멀티시그 두 서명자 모두 동일 니모닉 사용)
/// - 파일이 없거나 값이 비어 있으면 에러 메시지와 함께 테스트가 실패합니다.
String? _getMnemonic() {
  final envFile = File('test/test.env');
  if (envFile.existsSync()) {
    for (final line in envFile.readAsLinesSync()) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      final eqIndex = trimmed.indexOf('=');
      if (eqIndex <= 0) continue;
      final key = trimmed.substring(0, eqIndex).trim();
      if (key == 'TEST_MNEMONIC') {
        var value = trimmed.substring(eqIndex + 1).trim();
        // 따옴표 제거
        if ((value.startsWith("'") && value.endsWith("'")) || (value.startsWith('"') && value.endsWith('"'))) {
          value = value.substring(1, value.length - 1);
        }
        if (value.isNotEmpty) return value;
      }
    }
  }

  return null;
}

void main() {
  final String? mnemonic = _getMnemonic();
  final bool hasMnemonic = mnemonic != null && mnemonic.trim().isNotEmpty;

  if (!hasMnemonic) {
    print('');
    print('============================================================');
    print('  ⚠️  니모닉이 설정되지 않았습니다.');
    print('');
    print('  test/test.env 파일을 생성하고 아래 내용을 넣으세요:');
    print("    TEST_MNEMONIC='단어1 단어2 ... 단어12'");
    print('  (test/test.env는 .gitignore에 추가되어 커밋되지 않습니다.)');
    print('');
    print('  니모닉은 보안상 커밋/푸시하지 마세요.');
    print('============================================================');
    print('');
  }

  group('Sparrow PSBT 호환성', () {
    group('싱글시그 (P2WPKH)', () {
      _singleSigCompatTest(
        testName: 'Sparrow P2WPKH PSBT → matchesVault 호환성',
        mnemonic: mnemonic,
        passphrase: '',
        psbtBase64:
            'cHNidP8BAHECAAAAAUx8hQwn9WInVNq6eJudmCqNJnus09q8sV6ClhJEcK3vAQAAAAD9////AugDAAAAAAAAFgAU+gGNgKXZoNnlBGAkM6wljBaPnnDkCgAAAAAAABYAFIJ8QhG9e3jvp7eVbcNiVKzQIMIfm9MOAE8BBIiyHgN/K2t4gAAAAHSWPGKQpMbFvWYGJDK6aUvo8FKEtkRRqzz3rKvHMVNJA00pBGkTxrA4MRtvztMnqOLZUEqCUQu7kvna+h3lmORmEKOy63BUAACAAAAAgAAAAIAAAQEfWQ8AAAAAAAAWABSe+w0RYCFGU1uhL0Htbcq36fp70AEDBAEAAAAiBgNgbpfLVP6rZiIsMeGouPR+5/kV4j8+g3QWAgzqSVdZVRijsutwVAAAgAAAAIAAAACAAQAAADQAAAAAIgICp9SWy+aG0zmFIXyodW8JOesZcuQQbY0IjqtGZvzMazAYo7LrcFQAAIAAAACAAAAAgAAAAAAAAAAAACICAmhcLPqx6OTNcwk3s29QDq6svmTnT8zyApkxQg45T2y4GKOy63BUAACAAAAAgAAAAIABAAAANQAAAAA=',
        networkType: NetworkType.mainnet,
        accountIndex: 0,
      );
    });

    group('멀티시그 (P2WSH)', () {
      _multisigCompatTest(
        testName: 'Sparrow P2WSH PSBT → matchesVault 호환성',
        mnemonics: [mnemonic, mnemonic],
        passphrases: ['', 'dladmswl'],
        threshold: 2,
        psbtBase64:
            'cHNidP8BAFICAAAAARMK8g/TMXtZEKQJZuQ9u59KODkoA3FPVxYopdMe/Yb8AAAAAAD9////AX93AAAAAAAAFgAUcS7odsDc9riiMw0HRQLEJBMRApJ80w4ATwEEiLIeBFRkgUqAAAACOhprR++k62W2avghhd8axGfBZ8nIvNts53kQLIEeZSQCUxEZ1QwMjUdWEP4XnDUEpSBesAY8GOd0y781SlMoX/UUo7LrcDAAAIAAAACAAAAAgAIAAIBPAQSIsh4ESgPYFIAAAAJ2aPW8l2/ILPmYdVgSgvXiadfz1aENx6tiZ8uJsc2DuAIf5DJJXIo0gZgFYu/1h4aCS2jjat1rntuw2d4lvf6xWBQFB6TNMAAAgAAAAIAAAACAAgAAgAABASsJeAAAAAAAACIAIF7wVA4SndBaFUCT38oHba0GhuBkc4iCTonv/UFjAaOFAQMEAQAAAAEFR1IhAkFQD/2LkQoBf7J2TG1sehOFdBDdbumu2ZZAq/MAJtdDIQJcZPlkloXzndvTKWXqhI5ViR1l5KYOo1NC/SOEjSVNIlKuIgYCQVAP/YuRCgF/snZMbWx6E4V0EN1u6a7ZlkCr8wAm10Mco7LrcDAAAIAAAACAAAAAgAIAAIAAAAAAAAAAACIGAlxk+WSWhfOd29MpZeqEjlWJHWXkpg6jU0L9I4SNJU0iHAUHpM0wAACAAAAAgAAAAIACAACAAAAAAAAAAAAAAA==',
        networkType: NetworkType.mainnet,
        accountIndex: 0,
      );
    });
  });

  group('BlueWallet PSBT 호환성', () {
    group('싱글시그 (P2WPKH)', () {
      _singleSigCompatTest(
        testName: 'BlueWallet P2WPKH PSBT → matchesVault 호환성',
        mnemonic: mnemonic,
        passphrase: '',
        psbtBase64:
            'cHNidP8BAHECAAAAAUx8hQwn9WInVNq6eJudmCqNJnus09q8sV6ClhJEcK3vAQAAAAD/////AugDAAAAAAAAFgAUiyAyXM8NFVvIGibF9KB9dGMHq3TfCgAAAAAAABYAFIJ8QhG9e3jvp7eVbcNiVKzQIMIfAAAAAAABAR9ZDwAAAAAAABYAFJ77DRFgIUZTW6EvQe1tyrfp+nvQIgYDYG6Xy1T+q2YiLDHhqLj0fuf5FeI/PoN0FgIM6klXWVUYo7LrcFQAAIAAAACAAAAAgAEAAAA0AAAAAAAiAgJoXCz6sejkzXMJN7NvUA6urL5k50/M8gKZMUIOOU9suBijsutwVAAAgAAAAIAAAACAAQAAADUAAAAA',
        networkType: NetworkType.mainnet,
        accountIndex: 0,
      );
    });

    group('멀티시그 (P2WSH)', () {
      _multisigCompatTest(
        testName: 'BlueWallet P2WSH PSBT → matchesVault 호환성',
        mnemonics: [mnemonic, mnemonic],
        passphrases: ['', 'dladmswl'],
        threshold: 2,
        psbtBase64:
            'cHNidP8BAFICAAAAARMK8g/TMXtZEKQJZuQ9u59KODkoA3FPVxYopdMe/Yb8AAAAAAD/////AXx3AAAAAAAAFgAUGJFjpvD6Ga5+66ONauMWKE8WbLEAAAAAAAEA/TsBAgAAAAABAaIAtp80HfXQNf0TjZknHHtWb1aUXAH9ob8dzbdQSmQMAAAAAAD/////AQl4AAAAAAAAIgAgXvBUDhKd0FoVQJPfygdtrQaG4GRziIJOie/9QWMBo4UEAEcwRAIgM760nvV9SySfJSUUINTVw5/hle8gkCRs0XDC6kJRcXMCIGZJ+nLkbbgUoeJha5Ht5KA37VKKckbn5sfvpKeKq76gAUgwRQIhAIUJvaHdlJYxtkWwl/Kf8Tpp4ndt51CwptExQN/LY1LFAiB8KMhA89rqXprIH+myuLzHo9nvo/5VefX25/mImRVZ0gFHUiECGIhERdhsQQdjbLbCoxK9tz1HB+m3D/yPYIVXEqHbdHshA93b2X6ZtvlbZ/VzAIrAlmSzu+WnX5gb0bOhoXhrUI9lUq4AAAAAAQErCXgAAAAAAAAiACBe8FQOEp3QWhVAk9/KB22tBobgZHOIgk6J7/1BYwGjhQEFR1IhAkFQD/2LkQoBf7J2TG1sehOFdBDdbumu2ZZAq/MAJtdDIQJcZPlkloXzndvTKWXqhI5ViR1l5KYOo1NC/SOEjSVNIlKuIgYCQVAP/YuRCgF/snZMbWx6E4V0EN1u6a7ZlkCr8wAm10Mco7LrcDAAAIAAAACAAAAAgAIAAIAAAAAAAAAAACIGAlxk+WSWhfOd29MpZeqEjlWJHWXkpg6jU0L9I4SNJU0iHAUHpM0wAACAAAAAgAAAAIACAACAAAAAAAAAAAAAAA==',
        networkType: NetworkType.mainnet,
        accountIndex: 0,
      );
    });
  });

  group('Nunchuk PSBT 호환성', () {
    group('싱글시그 (P2WPKH)', () {
      _singleSigCompatTest(
        testName: 'Nunchuk P2WPKH PSBT → matchesVault 호환성',
        mnemonic: mnemonic,
        passphrase: '',
        psbtBase64:
            'cHNidP8BAHsCAAAAAkx8hQwn9WInVNq6eJudmCqNJnus09q8sV6ClhJEcK3vAQAAAAD9////JoQz7j4BvqC46QZshE2yZKpJy36gLEzXusgl8SKApr4AAAAAAP3///8BVRIAAAAAAAAWABSLIDJczw0VW8gaJsX0oH10YwerdAAAAABPAQSIsh4DfytreIAAAAB0ljxikKTGxb1mBiQyumlL6PBShLZEUas896yrxzFTSQNNKQRpE8awODEbb87TJ6ji2VBKglELu5L52vod5ZjkZhCjsutwVAAAgAAAAIAAAACAAAEAcQIAAAABgku7ufTrTSDlwg+puXqZtM/oDC061K7BwhBko/mwMW4AAAAAAP////8C6AMAAAAAAAAWABSI2p+ehjBI9M5Va84DzrEvssVAbVkPAAAAAAAAFgAUnvsNEWAhRlNboS9B7W3Kt+n6e9AAAAAAAQEfWQ8AAAAAAAAWABSe+w0RYCFGU1uhL0Htbcq36fp70CIGA2Bul8tU/qtmIiwx4ai49H7n+RXiPz6DdBYCDOpJV1lVGKOy63BUAACAAAAAgAAAAIABAAAANAAAAAABAFICAAAAAUx8hQwn9WInVNq6eJudmCqNJnus09q8sV6ClhJEcK3vAAAAAAD/////Aa4DAAAAAAAAFgAU8+2pXA6Hu9ZEFiyUcKuN6FoYcp4AAAAAAQEfrgMAAAAAAAAWABTz7alcDoe71kQWLJRwq43oWhhyniIGA71i0lipPLnezxhUa4dTN4XUZXeJoYgny9SuZMT+d4hHGKOy63BUAACAAAAAgAAAAIAAAAAAHgAAAAAA',
        networkType: NetworkType.mainnet,
        accountIndex: 0,
      );
    });

    group('멀티시그 (P2WSH)', () {
      _multisigCompatTest(
        testName: 'Nunchuk P2WSH PSBT → matchesVault 호환성',
        mnemonics: [mnemonic, mnemonic],
        passphrases: ['', 'dladmswl'],
        threshold: 2,
        psbtBase64:
            'cHNidP8BAFICAAAAARMK8g/TMXtZEKQJZuQ9u59KODkoA3FPVxYopdMe/Yb8AAAAAAD9////AX93AAAAAAAAFgAUcS7odsDc9riiMw0HRQLEJBMRApIAAAAATwEEiLIeBEoD2BSAAAACdmj1vJdvyCz5mHVYEoL14mnX89WhDcerYmfLibHNg7gCH+QySVyKNIGYBWLv9YeGgkto42rda57bsNneJb3+sVgUBQekzTAAAIAAAACAAAAAgAIAAIBPAQSIsh4EVGSBSoAAAAI6GmtH76TrZbZq+CGF3xrEZ8Fnyci822zneRAsgR5lJAJTERnVDAyNR1YQ/hecNQSlIF6wBjwY53TLvzVKUyhf9RSjsutwMAAAgAAAAIAAAACAAgAAgAABAF4CAAAAAaIAtp80HfXQNf0TjZknHHtWb1aUXAH9ob8dzbdQSmQMAAAAAAD/////AQl4AAAAAAAAIgAgXvBUDhKd0FoVQJPfygdtrQaG4GRziIJOie/9QWMBo4UAAAAAAQErCXgAAAAAAAAiACBe8FQOEp3QWhVAk9/KB22tBobgZHOIgk6J7/1BYwGjhQEFR1IhAkFQD/2LkQoBf7J2TG1sehOFdBDdbumu2ZZAq/MAJtdDIQJcZPlkloXzndvTKWXqhI5ViR1l5KYOo1NC/SOEjSVNIlKuIgYCQVAP/YuRCgF/snZMbWx6E4V0EN1u6a7ZlkCr8wAm10Mco7LrcDAAAIAAAACAAAAAgAIAAIAAAAAAAAAAACIGAlxk+WSWhfOd29MpZeqEjlWJHWXkpg6jU0L9I4SNJU0iHAUHpM0wAACAAAAAgAAAAIACAACAAAAAAAAAAAAAAA==',
        networkType: NetworkType.mainnet,
        accountIndex: 0,
      );
    });
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// 테스트 헬퍼
// ─────────────────────────────────────────────────────────────────────────────

void _singleSigCompatTest({
  required String testName,
  required String? mnemonic,
  required String passphrase,
  required String psbtBase64,
  required NetworkType networkType,
  int accountIndex = 0,
}) {
  test(testName, () async {
    if (mnemonic == null || mnemonic.trim().isEmpty) {
      markTestSkipped('test/test.env에 TEST_MNEMONIC이 설정되지 않음');
      return;
    }
    if (psbtBase64.isEmpty) {
      markTestSkipped('PSBT 데이터가 아직 입력되지 않음');
      return;
    }

    NetworkType.setNetworkType(networkType);

    // 1. 니모닉으로 vault 생성
    final vault = SingleSignatureVault.fromMnemonic(
      utf8.encode(mnemonic),
      passphrase: passphrase.isNotEmpty ? utf8.encode(passphrase) : null,
      accountIndex: accountIndex,
    );

    // 2. PSBT 파싱
    final psbt = Psbt.parse(psbtBase64);

    // 3. matchesVault 테스트 (탭루트에서 사용 중인 방식)
    bool matchesVaultResult = false;
    Object? matchesVaultError;
    try {
      matchesVaultResult = psbt.matchesVault(vault);
    } catch (e) {
      matchesVaultError = e;
    }

    // 4. 현재 매칭 로직 테스트 (MFP + hasPublicKeyInPsbt)
    final psbtMfp =
        psbt.extendedPublicKeyList.isNotEmpty
            ? psbt.extendedPublicKeyList.first.masterFingerprint
            : (psbt.inputs.first.bip32Derivation?.first.masterFingerprint ?? '');
    final vaultMfp = vault.keyStore.masterFingerprint;
    final mfpMatches = psbtMfp == vaultMfp;

    bool hasPublicKeyResult = false;
    Object? hasPublicKeyError;
    try {
      hasPublicKeyResult = vault.hasPublicKeyInPsbt(psbtBase64);
    } catch (e) {
      hasPublicKeyError = e;
    }

    // 5. 진단 정보 출력
    print('─── $testName 진단 ───');
    print('  network:           ${networkType.isTestnet ? "regtest/testnet" : "mainnet"}');
    print('  vault MFP:          $vaultMfp');
    print('  PSBT MFP:           $psbtMfp');
    print('  MFP match:          $mfpMatches');
    print('  addressType:        ${psbt.addressType}');
    print('  global xpub count:  ${psbt.extendedPublicKeyList.length}');
    if (psbt.extendedPublicKeyList.isNotEmpty) {
      print('  global xpub[0]:      ${psbt.extendedPublicKeyList.first.publicKey}');
      print('  global xpub[0] path: ${psbt.extendedPublicKeyList.first.path}');
    }
    print('  input count:        ${psbt.inputs.length}');
    for (int i = 0; i < psbt.inputs.length; i++) {
      final input = psbt.inputs[i];
      print('  input[$i]:');
      print('    witnessUtxo:      ${input.witnessUtxo != null ? "present" : "null"}');
      print('    bip32Derivation:  ${input.bip32Derivation?.length ?? 0} entries');
      if (input.bip32Derivation != null) {
        for (int j = 0; j < input.bip32Derivation!.length; j++) {
          final d = input.bip32Derivation![j];
          print(
            '      [$j] mfp=${d.masterFingerprint} path=${d.path} pub=${d.publicKey.substring(0, d.publicKey.length > 16 ? 16 : d.publicKey.length)}...',
          );
        }
      }
    }
    print('  isFromCoconut:      ${psbt.isFromCoconut}');
    print('');
    print('  matchesVault:       $matchesVaultResult');
    if (matchesVaultError != null) {
      print('  matchesVault error: $matchesVaultError');
    }
    print('  hasPublicKeyInPsbt: $hasPublicKeyResult');
    if (hasPublicKeyError != null) {
      print('  hasPublicKey error: $hasPublicKeyError');
    }
    print('─── 진단 끝 ───');

    // 6. 검증
    // matchesVault가 true면 타사 지갑과 호환됨
    // matchesVault가 false거나 예외면 호환 불가 → 원인 진단 필요
    expect(
      matchesVaultResult,
      isTrue,
      reason:
          matchesVaultError != null
              ? 'matchesVault 예외 발생: $matchesVaultError'
              : 'matchesVault가 false를 반환. 타사 PSBT 포맷이 coconut_lib 검증 기준을 충족하지 않음.',
    );

    // 현재 로직도 정상 동작해야 함
    expect(
      hasPublicKeyResult,
      isTrue,
      reason:
          hasPublicKeyError != null
              ? 'hasPublicKeyInPsbt 예외 발생: $hasPublicKeyError'
              : '현재 매칭 로직도 false. 니모닉/네트워크/계정 인덱스를 확인하세요.',
    );

    // 7. 실제 서명 검증 — 매칭은 되어도 서명이 실패하면 사용 불가
    final signedPsbt = Psbt.parse(vault.addSignatureToPsbt(psbtBase64));
    expect(
      signedPsbt.inputs.every((input) => input.signedCount >= 1),
      isTrue,
      reason: 'addSignatureToPsbt 결과에 서명이 추가되지 않음.',
    );

    // 8. 앱의 스캔 매칭 경로(setMatchingVault)로도 동일하게 식별되는지 확인
    final vaultItem = SingleSigVaultListItem(
      id: 1,
      name: 'compat single sig vault',
      colorIndex: 0,
      iconIndex: 0,
      descriptor: vault.descriptor,
      signerBsmsByAddressType: {AddressType.p2wpkh: ''},
      createdAt: DateTime(2026),
    );
    final signProvider = SignProvider();
    final viewModel = PsbtScannerViewModel(_FakeWalletProvider([vaultItem]), signProvider);
    await viewModel.setMatchingVault(psbtBase64);
    expect(signProvider.vaultListItem, same(vaultItem));
  });
}

void _multisigCompatTest({
  required String testName,
  required List<String?> mnemonics,
  required List<String> passphrases,
  required int threshold,
  required String psbtBase64,
  required NetworkType networkType,
  int accountIndex = 0,
}) {
  test(testName, () async {
    if (mnemonics.any((m) => m == null || m.trim().isEmpty)) {
      markTestSkipped('test/test.env에 TEST_MNEMONIC이 설정되지 않음');
      return;
    }
    if (psbtBase64.isEmpty) {
      markTestSkipped('PSBT 데이터가 아직 입력되지 않음');
      return;
    }

    NetworkType.setNetworkType(networkType);

    // 1. 니모닉들로 멀티시그 vault 생성
    final keyStores = <KeyStore>[];
    for (int i = 0; i < mnemonics.length; i++) {
      final seed = Seed.fromMnemonic(
        utf8.encode(mnemonics[i]!),
        passphrase: passphrases[i].isNotEmpty ? utf8.encode(passphrases[i]) : null,
      );
      keyStores.add(KeyStore.fromSeed(seed, AddressType.p2wsh, accountIndex: accountIndex));
    }
    final vault = MultisignatureVault.fromKeyStoreList(keyStores, threshold);

    // 2. PSBT 파싱
    final psbt = Psbt.parse(psbtBase64);

    // 3. matchesVault 테스트
    bool matchesVaultResult = false;
    Object? matchesVaultError;
    try {
      matchesVaultResult = psbt.matchesVault(vault);
    } catch (e) {
      matchesVaultError = e;
    }

    // 4. 현재 매칭 로직 테스트 (MFP set + hasPublicKeyInPsbt)
    final psbtMfpSet = psbt.extendedPublicKeyList.map((e) => e.masterFingerprint).toSet();
    final vaultMfpSet = vault.keyStoreList.map((e) => e.masterFingerprint).toSet();
    final mfpSetMatches = psbtMfpSet.length == vaultMfpSet.length && psbtMfpSet.every(vaultMfpSet.contains);

    bool hasPublicKeyResult = false;
    Object? hasPublicKeyError;
    try {
      hasPublicKeyResult = vault.hasPublicKeyInPsbt(psbtBase64);
    } catch (e) {
      hasPublicKeyError = e;
    }

    // 5. 진단 정보 출력
    print('─── $testName 진단 ───');
    print('  network:           ${networkType.isTestnet ? "regtest/testnet" : "mainnet"}');
    print('  vault MFP set:     $vaultMfpSet');
    print('  PSBT MFP set:      $psbtMfpSet');
    print('  MFP set match:     $mfpSetMatches');
    print('  threshold:         $threshold / ${keyStores.length}');
    print('  addressType:       ${psbt.addressType}');
    print('  global xpub count: ${psbt.extendedPublicKeyList.length}');
    for (int i = 0; i < psbt.extendedPublicKeyList.length; i++) {
      print('  global xpub[$i]:    ${psbt.extendedPublicKeyList[i].publicKey}');
      print('  global xpub[$i] path: ${psbt.extendedPublicKeyList[i].path}');
    }
    print('  input count:       ${psbt.inputs.length}');
    for (int i = 0; i < psbt.inputs.length; i++) {
      final input = psbt.inputs[i];
      print('  input[$i]:');
      print('    witnessUtxo:      ${input.witnessUtxo != null ? "present" : "null"}');
      print('    witnessScript:    ${input.witnessScript != null ? "present" : "null"}');
      print('    bip32Derivation:  ${input.bip32Derivation?.length ?? 0} entries');
      if (input.bip32Derivation != null) {
        for (int j = 0; j < input.bip32Derivation!.length; j++) {
          final d = input.bip32Derivation![j];
          print('      [$j] mfp=${d.masterFingerprint} path=${d.path}');
        }
      }
      print('    requiredSig:      ${input.requiredSignature}');
    }
    print('  isFromCoconut:     ${psbt.isFromCoconut}');
    print('');
    print('  matchesVault:       $matchesVaultResult');
    if (matchesVaultError != null) {
      print('  matchesVault error: $matchesVaultError');
    }
    print('  hasPublicKeyInPsbt: $hasPublicKeyResult');
    if (hasPublicKeyError != null) {
      print('  hasPublicKey error: $hasPublicKeyError');
    }
    print('─── 진단 끝 ───');

    // 6. 검증
    expect(
      matchesVaultResult,
      isTrue,
      reason:
          matchesVaultError != null
              ? 'matchesVault 예외 발생: $matchesVaultError'
              : 'matchesVault가 false를 반환. 타사 PSBT 포맷이 coconut_lib 검증 기준을 충족하지 않음.',
    );

    expect(
      hasPublicKeyResult,
      isTrue,
      reason:
          hasPublicKeyError != null
              ? 'hasPublicKeyInPsbt 예외 발생: $hasPublicKeyError'
              : '현재 매칭 로직도 false. 니모닉/네트워크/계정 인덱스를 확인하세요.',
    );

    // 7. 실제 서명 검증 — 모든 input이 threshold까지 서명되어야 함
    final signedPsbt = Psbt.parse(vault.addSignatureToPsbt(psbtBase64));
    expect(
      signedPsbt.inputs.every((input) => input.signedCount >= input.requiredSignature),
      isTrue,
      reason: 'addSignatureToPsbt 후에도 서명 수가 threshold에 미달.',
    );

    // 8. 앱의 스캔 매칭 경로(setMatchingVault)로도 동일하게 식별되는지 확인
    final vaultItem = MultisigVaultListItem(
      id: 1,
      name: 'compat multisig vault',
      colorIndex: 0,
      iconIndex: 0,
      signers:
          vault.keyStoreList.indexed
              .map((entry) => MultisigSigner(id: entry.$1, name: 'signer ${entry.$1}', keyStore: entry.$2))
              .toList(),
      requiredSignatureCount: threshold,
      createdAt: DateTime(2026),
    );
    final signProvider = SignProvider();
    final viewModel = PsbtScannerViewModel(_FakeWalletProvider([vaultItem]), signProvider);
    await viewModel.setMatchingVault(psbtBase64);
    expect(signProvider.vaultListItem, same(vaultItem));
  });
}

class _FakeWalletProvider implements WalletProvider {
  _FakeWalletProvider(this._vaultList) : _isLoaded = true;

  final List<VaultListItemBase> _vaultList;
  final bool _isLoaded;

  @override
  bool get isVaultsLoaded => _isLoaded;

  @override
  List<VaultListItemBase> get vaultList => _vaultList;

  @override
  VaultListItemBase getVaultById(int id) => _vaultList.firstWhere((vault) => vault.id == id);

  @override
  Future<void> loadVaultList() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
