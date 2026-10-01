import 'dart:convert';

import 'package:coconut_vault/constants/build_config.dart';
import 'package:coconut_vault/extensions/uint8list_extensions.dart';
import 'package:coconut_vault/isolates/wallet_isolates/wallet_isolates.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/passphrase_wallet_selection_bottom_sheet.dart';
import 'package:coconut_vault/utils/nfkd_util.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:loader_overlay/loader_overlay.dart';

/// 가져오려는 지갑이 이미 정해져 있을 때(외부 서명자, 디스크립터 등) 패스프레이즈 후보가 그 지갑을 만드는지 판정한다.
class ImportPassphraseMatcher {
  final Future<bool> Function(Uint8List secret, Uint8List passphrase) matches;

  /// 맞는 후보가 없을 때 NFKD로 진행할지 여부. false면 [ImportPassphraseNoMatch]를 반환한다.
  /// 불일치를 다음 화면에서 따로 안내하는 흐름(탭루트 가져오기)에서 켠다.
  final bool proceedWithNfkdWhenNoMatch;

  const ImportPassphraseMatcher(this.matches, {this.proceedWithNfkdWhenNoMatch = false});
}

sealed class ImportPassphraseResult {
  const ImportPassphraseResult();
}

/// 지갑 파생에 사용할 패스프레이즈 바이트. 호출자가 사용 후 지운다.
final class ImportPassphraseSelected extends ImportPassphraseResult {
  final Uint8List passphrase;
  const ImportPassphraseSelected(this.passphrase);
}

/// [ImportPassphraseMatcher]가 주어졌지만 어떤 후보도 맞지 않는다.
final class ImportPassphraseNoMatch extends ImportPassphraseResult {
  const ImportPassphraseNoMatch();
}

/// 사용자가 지갑 선택을 닫았다.
final class ImportPassphraseCancelled extends ImportPassphraseResult {
  const ImportPassphraseCancelled();
}

/// 가져오기에서 지갑 파생에 쓸 패스프레이즈 바이트를 정한다.
///
/// NFKD 정규화로 바뀌지 않는 패스프레이즈는 두 방식의 결과가 같으므로 그대로 쓴다.
/// 바뀌는 경우 NFKD(표준)와 정규화하지 않은 UTF-8(3.2.0 이하 코코넛 볼트) 중 하나를 고른다.
/// - [matcher]가 있으면 맞는 후보를 자동으로 고른다. NFKD를 먼저 확인한다.
/// - 이전 방식 지갑이 있을 수 있는 full 빌드에서는 두 지갑의 MFP를 보여주고 사용자가 고르게 한다.
/// - 그 외(lite 등)에는 NFKD를 쓴다.
Future<ImportPassphraseResult> resolveImportPassphrase(
  BuildContext context, {
  required Uint8List secret,
  required String passphrase,
  ImportPassphraseMatcher? matcher,
}) async {
  final nfkd = NfkdUtil.encodeNfkd(passphrase);
  final legacy = Uint8List.fromList(utf8.encode(passphrase));
  final isChangedByNormalization = !listEquals(nfkd, legacy);

  if (!isChangedByNormalization) {
    legacy.wipe();
    if (matcher == null) return ImportPassphraseSelected(nfkd);
  }

  if (matcher != null) {
    final candidates = isChangedByNormalization ? [nfkd, legacy] : [nfkd];
    context.loaderOverlay.show();
    try {
      for (final candidate in candidates) {
        if (await matcher.matches(secret, candidate)) {
          for (final other in candidates) {
            if (!identical(other, candidate)) other.wipe();
          }
          return ImportPassphraseSelected(candidate);
        }
      }
    } finally {
      if (context.mounted) context.loaderOverlay.hide();
    }
    if (matcher.proceedWithNfkdWhenNoMatch) {
      if (isChangedByNormalization) legacy.wipe();
      return ImportPassphraseSelected(nfkd);
    }
    for (final candidate in candidates) {
      candidate.wipe();
    }
    return const ImportPassphraseNoMatch();
  }

  const lastUnnormalizedVersion = kLastUnnormalizedPassphraseVersion;
  if (lastUnnormalizedVersion == null) {
    legacy.wipe();
    return ImportPassphraseSelected(nfkd);
  }

  if (!context.mounted) return const ImportPassphraseCancelled();
  context.loaderOverlay.show();
  final List<String> masterFingerprints;
  try {
    masterFingerprints = await compute(WalletIsolates.deriveMasterFingerprints, {
      'mnemonic': Uint8List.fromList(secret),
      'passphrases': [Uint8List.fromList(nfkd), Uint8List.fromList(legacy)],
    });
  } finally {
    if (context.mounted) context.loaderOverlay.hide();
  }

  if (!context.mounted) return const ImportPassphraseCancelled();
  final selected = await MyBottomSheet.showBottomSheet_ratio<PassphraseEncoding>(
    context: context,
    ratio: 0.5,
    child: PassphraseWalletSelectionBottomSheet(
      nfkdMasterFingerprint: masterFingerprints[0],
      legacyMasterFingerprint: masterFingerprints[1],
      lastUnnormalizedVersion: lastUnnormalizedVersion,
    ),
  );

  switch (selected) {
    case PassphraseEncoding.nfkd:
      legacy.wipe();
      return ImportPassphraseSelected(nfkd);
    case PassphraseEncoding.legacyUtf8:
      nfkd.wipe();
      return ImportPassphraseSelected(legacy);
    case null:
      nfkd.wipe();
      legacy.wipe();
      return const ImportPassphraseCancelled();
  }
}
