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

    controller?.pause();

    final result = _coordinatorBsmsQrDataHandler.result;

    if (result == null) {
      onFailedScanning(wrongFormatMessage);
      setState(() => isProcessing = false);
      return;
    }

    try {
      // 이 화면이 어느 Vault에 속한 건지에 대한 id는
      // 라우팅 아규먼트나 Provider 등으로 주입해야 함.
      // 예시로 id를 arguments에서 꺼낸다고 가정:
      // final args = ModalRoute.of(context)!.settings.arguments as VaultHomeNavArgs;
      // final vault = await walletProvider.importMultisigVault(decodedData, args.vaultId);

      // assert(walletProvider.isAddVaultCompleted);

      // if (!mounted) return;
      // Navigator.pushNamedAndRemoveUntil(
      //   context,
      //   '/',
      //   (Route<dynamic> route) => false,
      //   arguments: VaultHomeNavArgs(addedWalletId: vault.id),
      // );

      final normalizedMultisigConfig = MultisigNormalizer.fromCoordinatorResult(result);
      Logger.log(
        '\t normalizedMultisigConfig: \n name: ${normalizedMultisigConfig.name}\n requiredCount: ${normalizedMultisigConfig.requiredCount}\n signerBsms: [\n${normalizedMultisigConfig.signerBsms.join(',\n')}\n]',
      );

      final bool isValidMultisig = _coordinatorBsmsQrDataHandler.validateFormat(scanData);

      if (isValidMultisig) {
        final creationProvider = Provider.of<WalletCreationProvider>(context, listen: false);

        creationProvider.resetAll();

        final int m = normalizedMultisigConfig.requiredCount;
        final int n = normalizedMultisigConfig.signerBsms.length;

        creationProvider.setQuorumRequirement(m, n);
        List<MultisigSigner> signers =
            normalizedMultisigConfig.signerBsms.asMap().entries.map((entry) {
              int index = entry.key;
              String bsmsString = entry.value;

              KeyStore generatedKeyStore = KeyStore.fromSignerBsms(bsmsString);

              return MultisigSigner(
                id: 0,
                keyStore: generatedKeyStore,
                signerBsms: bsmsString,
                name: 'Signer ${index + 1}',
                innerVaultId: null,
              );
            }).toList();

        creationProvider.setSigners(signers);

        Navigator.pushReplacementNamed(
          context,
          AppRoutes.vaultNameSetup,
          arguments: {'name': normalizedMultisigConfig.name},
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
      if (e is NotRelatedMultisigWalletException) {
        onFailedScanning(e.message);
        return;
      }
      onFailedScanning(e.toString());
      controller?.start();
    }
  }
}
