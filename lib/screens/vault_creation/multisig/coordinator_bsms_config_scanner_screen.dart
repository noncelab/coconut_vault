import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/app_routes_params.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/providers/view_model/vault_creation/multisig/import_coordinator_bsms_view_model.dart';
import 'package:coconut_vault/providers/wallet_creation_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/screens/vault_creation/multisig/bsms_scanner_base.dart';
import 'package:coconut_vault/utils/bip/multisig_normalizer.dart';
import 'package:coconut_vault/utils/bip/normalized_multisig_config.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/utils/popup_util.dart';
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
  final CoordinatorBsmsQrDataHandler _dataHandler;
  late final ImportCoordinatorBsmsViewModel _viewModel;

  _CoordinatorBsmsConfigScannerScreenState() : _dataHandler = CoordinatorBsmsQrDataHandler();

  @override
  void initState() {
    super.initState();
    _viewModel = ImportCoordinatorBsmsViewModel(Provider.of<WalletProvider>(context, listen: false));
  }

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
    try {
      _dataHandler.joinData(scanData);
    } catch (e) {
      _dataHandler.reset();
      onFailedScanning('$wrongFormatMessage\n${e.toString()}');
      return;
    }

    if (!_dataHandler.isCompleted()) {
      setState(() => isProcessing = false);
      return;
    }

    await controller?.stop();
    if (!mounted) return;

    final result = _dataHandler.result;

    if (result == null) {
      _dataHandler.reset();
      onFailedScanning(wrongFormatMessage);
      setState(() => isProcessing = false);
      return;
    }

    NormalizedMultisigConfig? normalizedMultisigConfig;
    try {
      normalizedMultisigConfig = MultisigNormalizer.fromCoordinatorResult(result);
      Logger.log(
        '\t normalizedMultisigConfig: \n name: ${normalizedMultisigConfig.name}\n requiredCount: ${normalizedMultisigConfig.requiredCount}\n signerBsms: [\n${normalizedMultisigConfig.signerBsms.join(',\n')}\n]',
      );
    } catch (e) {
      _dataHandler.reset();
      onFailedScanning('$wrongFormatMessage\n${e.toString()}');
      Logger.error('🛑 MultisigNormalizer.fromCoordinatorResult 에러 발생: $e');
      await controller?.start();
      return;
    }

    try {
      final sameWalletName = _viewModel.findSameWalletName(normalizedMultisigConfig);
      if (sameWalletName != null) {
        if (!mounted) return;
        _dataHandler.reset();
        await showInfoPopup(context, t.alert.same_wallet.title, t.alert.same_wallet.description(name: sameWalletName));
        await controller?.start();
        return;
      }

      bool isCoconutMultisigConfig = _viewModel.isCoconutMultisigConfig(result);
      List<MultisigSigner> signers = _viewModel.getMultisigSignersFromMultisigConfig(normalizedMultisigConfig);
      if (isCoconutMultisigConfig) {
        final colorIndex = result[VaultListItemBase.fieldColorIndex] as int;
        final iconIndex = result[VaultListItemBase.fieldIconIndex] as int;
        final vault = await _viewModel.addMultisigVault(normalizedMultisigConfig, colorIndex, iconIndex, signers);
        if (!mounted) return;
        //Logger.log('---> Homeroute = ${HomeScreenStatus().screenStatus}');
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/',
          (Route<dynamic> route) => false,
          arguments: VaultHomeNavArgs(addedWalletId: vault.id),
        );
      } else {
        final creationProvider = Provider.of<WalletCreationProvider>(context, listen: false)..resetAll();
        creationProvider.setQuorumRequirement(
          normalizedMultisigConfig.requiredCount,
          normalizedMultisigConfig.signerBsms.length,
        );
        creationProvider.setSigners(signers);
        if (!context.mounted) return;
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.vaultNameSetup,
          arguments: {'name': normalizedMultisigConfig.name},
        );
      }
    } catch (e) {
      Logger.error('🛑: $e');
      _dataHandler.reset();
      onFailedScanning("${t.alert.wallet_creation_failed.title}\n${e.toString()}");
      await controller?.start();
    }
  }
}
