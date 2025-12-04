import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/utils/bip/signer_bsms.dart';
import 'package:coconut_vault/utils/logger.dart';

class NormalizedMultisigConfig {
  final String name;
  final int requiredCount; // m
  final List<String> signerBsms; // 각 signer BSMS (BIP-129 형식)

  const NormalizedMultisigConfig._({required this.name, required this.requiredCount, required this.signerBsms});

  factory NormalizedMultisigConfig({
    required String name,
    required int requiredCount,
    required List<String> signerBsms,
  }) {
    if (requiredCount <= 0) {
      throw ArgumentError('requiredCount must be > 0');
    }
    if (signerBsms.length <= 1) {
      throw ArgumentError('signerBsms must have at least 2 elements');
    }
    if (requiredCount > signerBsms.length) {
      throw ArgumentError('requiredCount ($requiredCount) cannot be greater than total signers (${signerBsms.length})');
    }

    return NormalizedMultisigConfig._(
      name: name.trim(),
      requiredCount: requiredCount,
      signerBsms: List.unmodifiable(signerBsms),
    );
  }

  int get totalSigners => signerBsms.length;

  // # Keystone Multisig setup file (created by Coconut Vaults)
  // #
  //
  // Name: keyston-multisig
  // Policy: 2 of 2
  // Derivation: m/48'/0'/0'/2'
  // Format: P2WSH
  //
  // A3B2EB70: xpub6E9t6eQGiTVTG99xWo6KEdYAVyGtrmkCNgbTPVPSEvA6wgAS2irZxLdvbLBTz5XURtLSB2LPMZHf85CJxapgr8NpYcdDX56UKpVvZ5qxu9k
  // A0F6BA00: xpub6Dtc8ee6APa87VBy7LoZo6RfdGY3k8gnPzT1TYvHygVPJhur24RgEk9FftpzcvPhQgk9j5WKr5jkxs1Lhew25ffN5tLQfkcdE6Lz5DosnsT

  String getMultisigConfigString() {
    final signerBsmsList = signerBsms.map((sb) => SignerBsms.parse(sb)).toList();
    final coin = NetworkType.currentNetworkType == NetworkType.mainnet ? 0 : 1;
    final policy = '$requiredCount of ${signerBsmsList.length}';
    // 현재 정책에 따라 P2WSH만 지원하므로 고정
    final derivationPath = "m/48'/$coin'/0'/2'";
    const scriptType = 'P2WSH';

    final configString =
        StringBuffer()
          ..writeln('# Keystone Multisig setup file (created by Coconut Vault)')
          ..writeln('#')
          ..writeln()
          ..writeln('Name: $name')
          ..writeln('Policy: $policy')
          ..writeln('Derivation: $derivationPath')
          ..writeln('Format: $scriptType')
          ..writeln();

    for (final s in signerBsmsList) {
      configString.writeln('${s.fingerprint.toUpperCase()}: ${s.extendedKey}');
    }

    return configString.toString();
  }

  // TODO: 위치
  // TODO: signerBsms 리스트의 타입이 변경되면 필요 없어질 수도 있음. 생성자에서 이 과정이 모두 끝날 수 있음ㄴ
  List<MultisigSigner> getMultisigSigners() {
    return signerBsms.asMap().entries.map((entry) {
      int index = entry.key;
      String bsmsString = entry.value;

      KeyStore generatedKeyStore;

      try {
        // 1차 시도: 원본으로 시도
        generatedKeyStore = KeyStore.fromSignerBsms(bsmsString);
      } catch (e) {
        Logger.log('⚠️ 1차 파싱 실패. 데이터 복구 시도 중...');

        // 줄 단위로 분리 (공백 제거)
        List<String> lines = bsmsString.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

        // Case A: 3줄만 있는 경우 (Label 누락) -> 임시 라벨 추가
        if (lines.length == 3 && lines[0].startsWith('BSMS')) {
          // 4번째 줄에 'Imported'라는 라벨을 강제로 추가
          String repairedBsms = '${lines.join('\n')}\nImported';

          Logger.log('🔧 데이터 복구 (Label 추가): \n$repairedBsms');

          try {
            generatedKeyStore = KeyStore.fromSignerBsms(repairedBsms);
          } catch (e2) {
            // Case B: 복구 실패 시, 최후의 수단으로 Descriptor(3번째 줄)만 추출해서 시도
            Logger.log('⚠️ 2차 복구 실패. Descriptor만 추출 시도.');
            String descriptorLine = lines.firstWhere(
              (line) => line.startsWith('[') && line.contains('pub'),
              orElse: () => bsmsString,
            );
            generatedKeyStore = KeyStore.fromSignerBsms(descriptorLine);
          }
        } else {
          // Case C: 그 외 포맷 에러 시 Descriptor만 추출
          String descriptorLine = bsmsString;
          if (lines.isNotEmpty) {
            descriptorLine = lines.firstWhere(
              (line) => line.startsWith('[') && line.contains('pub'),
              orElse: () => bsmsString,
            );
          }
          generatedKeyStore = KeyStore.fromSignerBsms(descriptorLine);
        }
      }

      // TODO: label이 있는 경우 memo로 설정 (테스트필요)
      final parsed = SignerBsms.parse(bsmsString);
      return MultisigSigner(
        id: index,
        keyStore: generatedKeyStore,
        signerBsms: bsmsString,
        innerVaultId: null,
        memo: parsed.label,
      );
    }).toList();
  }
}
