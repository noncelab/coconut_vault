import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/exception/not_related_multisig_wallet_exception.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/providers/wallet_creation_provider.dart';
import 'package:coconut_vault/screens/vault_creation/multisig/bsms_scanner_base.dart';
import 'package:coconut_vault/utils/bip/multisig_normalizer.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/widgets/animated_qr/scan_data_handler/coordinator_bsms_qr_data_handler.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

// 다중 서명 지갑 생성 시 외부에서 Coordinator BSMS를 스캔하는 화면
class CoordinatorBsmsConfigScannerScreen extends StatefulWidget {
  const CoordinatorBsmsConfigScannerScreen({super.key});

  @override
  State<CoordinatorBsmsConfigScannerScreen> createState() => _CoordinatorBsmsConfigScannerScreenState();
}

class _CoordinatorBsmsConfigScannerScreenState extends BsmsScannerBase<CoordinatorBsmsConfigScannerScreen> {
  static String wrongFormatMessage = t.errors.invalid_multisig_qr_error;
  final CoordinatorBsmsQrDataHandler _coordinatorBsmsQrDataHandler;

  _CoordinatorBsmsConfigScannerScreenState() : _coordinatorBsmsQrDataHandler = CoordinatorBsmsQrDataHandler();

  @override
  bool get showBackButton => true;

  @override
  bool get showBottomButton => true;

  @override
  double get topMaskHeight => 0.0;

  @override
  String get appBarTitle => t.bsms_scanner_screen.import_multisig_wallet;

  @override
  List<TextSpan> buildTooltipRichText(BuildContext context, visibilityProvider) {
    return [
      TextSpan(
        text: t.coordinator_bsms_config_scanner_screen.guide1,
        style: CoconutTypography.body2_14.copyWith(height: 1.3, color: CoconutColors.black),
      ),
      const TextSpan(text: ' '),
      TextSpan(
        text: t.coordinator_bsms_config_scanner_screen.guide2,
        style: CoconutTypography.body2_14.copyWith(height: 1.3, color: CoconutColors.black),
      ),
    ];
  }

  @override
  void onBarcodeDetected(BarcodeCapture capture) async {
    final codes = capture.barcodes;
    if (codes.isEmpty) {
      setState(() => isProcessing = false);
      return;
    }

    final barcode = codes.first;
    if (barcode.rawValue == null) {
      setState(() => isProcessing = false);
      return;
    }

    final scanData = barcode.rawValue!;
    _coordinatorBsmsQrDataHandler.joinData(scanData);
    if (!_coordinatorBsmsQrDataHandler.isCompleted()) {
      setState(() => isProcessing = false);
      return;
    }

    if (!_coordinatorBsmsQrDataHandler.isCompleted()) {
      setState(() => isProcessing = false);
      return;
    }

    await controller?.stop();
    if (!mounted) return;

    final result = _coordinatorBsmsQrDataHandler.result;

    if (result == null) {
      onFailedScanning(wrongFormatMessage);
      setState(() => isProcessing = false);
      return;
    }

    try {
      final normalizedMultisigConfig = MultisigNormalizer.fromCoordinatorResult(result);
      Logger.log(
        '\t 🛑normalizedMultisigConfig: \n name: ${normalizedMultisigConfig.name}\n requiredCount: ${normalizedMultisigConfig.requiredCount}\n signerBsms: [\n${normalizedMultisigConfig.signerBsms.join(',\n')}\n]',
      );

      final int m = normalizedMultisigConfig.requiredCount;
      final int n = normalizedMultisigConfig.signerBsms.length;

      final bool isValidMultisig = n >= 2 && m > 0 && m <= n;

      if (isValidMultisig) {
        final creationProvider = Provider.of<WalletCreationProvider>(context, listen: false);

        creationProvider.resetAll();

        creationProvider.setQuorumRequirement(m, n);
        List<MultisigSigner> signers =
            normalizedMultisigConfig.signerBsms.asMap().entries.map((entry) {
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

              return MultisigSigner(
                id: 0,
                keyStore: generatedKeyStore,
                signerBsms: bsmsString,
                name: 'Signer ${index + 1}',
                innerVaultId: null,
              );
            }).toList();

        creationProvider.setSigners(signers);

        int colorIndex = 0;
        int iconIndex = 0;

        if (result is Map<String, dynamic>) {
          if (result.containsKey('colorIndex')) {
            colorIndex =
                result['colorIndex'] is int ? result['colorIndex'] : int.tryParse(result['colorIndex'].toString()) ?? 0;
          }
          if (result.containsKey('iconIndex')) {
            iconIndex =
                result['iconIndex'] is int ? result['iconIndex'] : int.tryParse(result['iconIndex'].toString()) ?? 0;
          }
        }

        Navigator.pushReplacementNamed(
          context,
          AppRoutes.vaultNameSetup,
          arguments: {'name': normalizedMultisigConfig.name, 'colorIndex': colorIndex, 'iconIndex': iconIndex},
        );
      } else {
        await showDialog(
          context: context,
          builder:
              (context) => CoconutPopup(
                title: t.coordinator_bsms_config_scanner_screen.error_title,
                description: t.coordinator_bsms_config_scanner_screen.error_message,
                onTapRight: () {
                  Navigator.of(context).pop();
                },
              ),
        );
      }
    } catch (e) {
      Logger.log('🛑 에러 발생: $e');

      if (e is NotRelatedMultisigWalletException) {
        onFailedScanning(e.message);
        return;
      }
      onFailedScanning(e.toString());
      await controller?.start();
    }
  }
}
