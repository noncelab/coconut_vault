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
import 'package:coconut_vault/utils/bip/multisig_normalizer.dart';
import 'package:coconut_vault/utils/bip/normalized_multisig_config.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/utils/popup_util.dart';
import 'package:coconut_vault/widgets/animated_qr/scan_data_handler/coordinator_bsms_qr_data_handler.dart';
import 'package:coconut_vault/widgets/button/fixed_bottom_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CoordinatorBsmsPasteScreen extends StatefulWidget {
  const CoordinatorBsmsPasteScreen({super.key});

  @override
  State<CoordinatorBsmsPasteScreen> createState() => _CoordinatorBsmsPasteScreenState();
}

class _CoordinatorBsmsPasteScreenState extends State<CoordinatorBsmsPasteScreen> {
  final FocusNode _bsmsFocusNode = FocusNode();
  final TextEditingController _bsmsController = TextEditingController();

  final CoordinatorBsmsQrDataHandler _dataHandler = CoordinatorBsmsQrDataHandler();
  late final ImportCoordinatorBsmsViewModel _viewModel;

  bool _bsmsObscured = false;
  bool _isProcessing = false;
  NormalizedMultisigConfig? _normalizedMultisigConfig;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _bsmsController.addListener(_onInputChanged);

    _viewModel = ImportCoordinatorBsmsViewModel(Provider.of<WalletProvider>(context, listen: false));
  }

  @override
  void dispose() {
    _bsmsFocusNode.dispose();
    _bsmsController.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    try {
      if (_bsmsController.text.isEmpty) {
        setState(() {
          _normalizedMultisigConfig = null;
          _errorMessage = null;
        });
        return;
      }
      setState(() {
        _normalizedMultisigConfig = _normalizeCoordinatorBsms(_bsmsController.text);
      });
      if (_errorMessage != null) {
        setState(() {
          // 변경되면 검증 로직을 타야 함
          _errorMessage = null;
        });
      }
    } catch (e) {
      _onFailedNormalization(e);
    }
  }

  // INFO: e.toString를 화면에 보여줘야 하는 경우를 대비
  void _onFailedNormalization(Object? e) {
    String message;

    if (e is NetworkMismatchException) {
      message = e.message;
    } else {
      message = t.bsms_paste_screen.error_message;
    }

    setState(() {
      _normalizedMultisigConfig = null;
      _errorMessage = message;
    });
  }

  NormalizedMultisigConfig _normalizeCoordinatorBsms(String bsms) {
    _dataHandler.reset();
    _dataHandler.joinData(bsms.trim());
    if (!_dataHandler.isCompleted()) {
      throw Exception("Incomplete data");
    }

    final bool isAppMainnet = NetworkType.currentNetworkType == NetworkType.mainnet;

    final String rawData = bsms.toLowerCase();

    final bool isDataTestnet = rawData.contains('tpub') || rawData.contains('vpub') || rawData.contains('upub');
    final bool isDataMainnet = rawData.contains('xpub') || rawData.contains('zpub') || rawData.contains('ypub');

    if (isDataTestnet || isDataMainnet) {
      if (isAppMainnet && isDataTestnet && !isDataMainnet) {
        throw NetworkMismatchException(message: t.alert.bsms_network_mismatch.description_when_mainnet);
      }

      if (!isAppMainnet && isDataMainnet && !isDataTestnet) {
        throw NetworkMismatchException(message: t.alert.bsms_network_mismatch.description_when_testnet);
      }
    }

    NormalizedMultisigConfig normalizedMultisigConfig = MultisigNormalizer.fromCoordinatorResult(_dataHandler.result);
    Logger.log(
      '\t normalizedMultisigConfig: \n name: ${normalizedMultisigConfig.name}\n requiredCount: ${normalizedMultisigConfig.requiredCount}\n signerBsms: [\n${normalizedMultisigConfig.signerBsms.join(',\n')}\n]',
    );
    return normalizedMultisigConfig;
  }

  Future<void> _onCompletePressed() async {
    try {
      setState(() {
        _isProcessing = true;
      });
      final sameWalletName = _viewModel.findSameWalletName(_normalizedMultisigConfig!);
      if (sameWalletName != null) {
        if (!mounted) return;
        await showInfoPopup(context, t.alert.same_wallet.title, t.alert.same_wallet.description(name: sameWalletName));
        return;
      }

      final result = _dataHandler.result;
      bool isCoconutMultisigConfig = _viewModel.isCoconutMultisigConfig(result);
      List<MultisigSigner> signers = _viewModel.getMultisigSignersFromMultisigConfig(_normalizedMultisigConfig!);
      if (isCoconutMultisigConfig) {
        final colorIndex = result[VaultListItemBase.fieldColorIndex] as int;
        final iconIndex = result[VaultListItemBase.fieldIconIndex] as int;
        final vault = await _viewModel.addMultisigVault(_normalizedMultisigConfig!, colorIndex, iconIndex, signers);
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
          _normalizedMultisigConfig!.requiredCount,
          _normalizedMultisigConfig!.signerBsms.length,
        );
        creationProvider.setSigners(signers);
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.vaultNameSetup,
          arguments: {'name': _normalizedMultisigConfig!.name, 'isImported': true},
        );
      }
    } catch (e) {
      Logger.error('🛑: $e');
      _dataHandler.reset();
      await showInfoPopup(context, t.alert.wallet_creation_failed.title, e.toString());
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoconutColors.white,
      appBar: CoconutAppBar.build(title: t.bsms_scanner_screen.import_multisig_wallet, context: context),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topCenter, // Stack 영역 내에서 상단 중앙 정렬
                child: Column(
                  mainAxisSize: MainAxisSize.min, // 필요한 만큼만 높이를 차지
                  crossAxisAlignment: CrossAxisAlignment.center, // 내부 텍스트를 중앙 정렬
                  children: [
                    Text(
                      t.bsms_paste_screen.import_bsms,
                      textAlign: TextAlign.center,
                      style: CoconutTypography.body2_14_Bold,
                    ),
                    const SizedBox(height: 8.0), // 두 텍스트 사이에 간격을 추가
                    _buildBSMSTextField(),
                  ],
                ),
              ),
              Positioned(
                bottom:
                    FixedBottomButton.fixedBottomButtonDefaultBottomPadding +
                    FixedBottomButton.fixedBottomButtonDefaultHeight +
                    12,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushReplacementNamed(context, AppRoutes.coordinatorBsmsConfigScanner);
                    },
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        t.bsms_paste_screen.back_scan,
                        style: const TextStyle(decoration: TextDecoration.underline),
                      ),
                    ),
                  ),
                ),
              ),
              FixedBottomButton(
                onButtonClicked: _onCompletePressed,
                text: t.complete,
                showGradient: false,
                isActive: _normalizedMultisigConfig != null && !_isProcessing,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBSMSTextField() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: SizedBox(
            child: CoconutTextField(
              focusNode: _bsmsFocusNode,
              controller: _bsmsController,
              onChanged: (_) {},
              maxLines: 5,
              isLengthVisible: false,
              obscureText: _bsmsObscured,
              isError: _errorMessage != null,
              errorText: _errorMessage,
            ),
          ),
        ),
      ],
    );
  }
}
