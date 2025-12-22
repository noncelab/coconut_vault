import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/app_routes_params.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/model/exception/network_mismatch_exception.dart';
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
  bool _isFirstScanData = true;

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
      return;
    }
    final barcode = codes.first;
    if (barcode.rawValue == null) {
      return;
    }

    final scanData = barcode.rawValue!;

    if (_isFirstScanData) {
      if (!_dataHandler.validateFormat(scanData)) {
        onFailedScanning(wrongFormatMessage);
        return;
      }
      _isFirstScanData = false;
    }

    try {
      final joinResult = _dataHandler.joinData(scanData);
      if (joinResult == false && _dataHandler.isFragmentedDataScanned == false) {
        _handleScanFailure(wrongFormatMessage);
        return;
      }

      if (_dataHandler.isFragmentedDataScanned == true) {
        updateScanProgress(_dataHandler.progress);
      }

      if (!_dataHandler.isCompleted()) {
        return;
      }

      setState(() => isProcessing = true);

      final result = _dataHandler.result;
      if (result == null) {
        _handleScanFailure(wrongFormatMessage);
        return;
      }

      final bool isAppMainnet = NetworkType.currentNetworkType == NetworkType.mainnet;

      final String resultString = result.toString().toLowerCase();

      final bool isDataTestnet =
          resultString.contains('tpub') || resultString.contains('vpub') || resultString.contains('upub');

      final bool isDataMainnet =
          resultString.contains('xpub') || resultString.contains('zpub') || resultString.contains('ypub');

      if (isDataTestnet || isDataMainnet) {
        if (isAppMainnet && isDataTestnet && !isDataMainnet) {
          throw NetworkMismatchException();
        }

        if (!isAppMainnet && isDataMainnet && !isDataTestnet) {
          throw NetworkMismatchException();
        }
      }

      NormalizedMultisigConfig normalizedMultisigConfig = MultisigNormalizer.fromCoordinatorResult(result);
      Logger.log(
        '\t normalizedMultisigConfig: \n name: ${normalizedMultisigConfig.name}\n requiredCount: ${normalizedMultisigConfig.requiredCount}\n signerBsms: [\n${normalizedMultisigConfig.signerBsms.join(',\n')}\n]',
      );

      final sameWalletName = _viewModel.findSameWalletName(normalizedMultisigConfig);
      if (sameWalletName != null) {
        if (!mounted) return;
        _reset();
        await showInfoPopup(context, t.alert.same_wallet.title, t.alert.same_wallet.description(name: sameWalletName));
        setState(() {
          isProcessing = false;
        });
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
          arguments: {'name': normalizedMultisigConfig.name, 'isImported': true},
        );
      }
    } catch (e) {
      Logger.error('🛑: $e');
      String failureMessage;

      if (e is NetworkMismatchException) {
        if (NetworkType.currentNetworkType == NetworkType.mainnet) {
          failureMessage =
              "${t.alert.bsms_network_mismatch.title}\n\n${t.alert.bsms_network_mismatch.description_when_mainnet}";
        } else {
          failureMessage =
              "${t.alert.bsms_network_mismatch.title}\n\n${t.alert.bsms_network_mismatch.description_when_testnet}";
        }
      } else {
        failureMessage =
            "${t.coordinator_bsms_config_scanner_screen.error_title}\n\n${t.coordinator_bsms_config_scanner_screen.error_message}";
      }

      _handleScanFailure(failureMessage);
    }
  }

  void _reset() {
    _isFirstScanData = true;
    _dataHandler.reset();

    resetScanProgress();
  }

  void _handleScanFailure(String message) {
    _reset();
    onFailedScanning(message);
  }
}
