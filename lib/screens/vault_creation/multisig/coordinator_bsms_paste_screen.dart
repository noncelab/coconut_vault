import 'dart:convert';
import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/app_routes_params.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/model/exception/network_mismatch_exception.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/providers/app_lifecycle_state_provider.dart';
import 'package:coconut_vault/providers/view_model/vault_creation/multisig/import_coordinator_bsms_view_model.dart';
import 'package:coconut_vault/providers/wallet_creation_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/utils/bip/multisig_normalizer.dart';
import 'package:coconut_vault/utils/bip/normalized_multisig_config.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/utils/popup_util.dart';
import 'package:coconut_vault/widgets/button/fixed_bottom_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CoordinatorBsmsPasteScreen extends StatefulWidget {
  const CoordinatorBsmsPasteScreen({super.key});

  @override
  State<CoordinatorBsmsPasteScreen> createState() => _CoordinatorBsmsPasteScreenState();
}

class _CoordinatorBsmsPasteScreenState extends State<CoordinatorBsmsPasteScreen> {
  final AppLifecycleStateProvider _lifecycleProvider = AppLifecycleStateProvider();
  final FocusNode _bsmsFocusNode = FocusNode();
  final TextEditingController _bsmsController = TextEditingController();

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
    _bsmsFocusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _lifecycleProvider.endOperation(AppLifecycleOperations.pastAuthRequest);
    _bsmsFocusNode.dispose();
    _bsmsController.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_bsmsFocusNode.hasFocus) {
      _lifecycleProvider.startOperation(AppLifecycleOperations.pastAuthRequest);
    } else {
      _lifecycleProvider.endOperation(AppLifecycleOperations.pastAuthRequest);
    }
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
          _errorMessage = null;
        });
      }
    } catch (e) {
      _onFailedNormalization(e);
    }
  }

  void _onFailedNormalization(Object? e) {
    Logger.error('🛑 Parsing Error Type: ${e.runtimeType}');
    Logger.error('🛑 Parsing Error Message: $e');

    String message;

    if (e is NetworkMismatchException) {
      message = (e as dynamic).message;
    } else {
      message = t.bsms_paste_screen.error_message;
    }

    setState(() {
      _normalizedMultisigConfig = null;
      _errorMessage = message;
    });
  }

  NormalizedMultisigConfig _normalizeCoordinatorBsms(String bsms) {
    final text = bsms.trim();

    try {
      //NetworkMismatch
      _viewModel.validateBsmsNetwork(text);

      //Format
      final config = MultisigNormalizer.fromCoordinatorResult(text);

      Logger.log(
        '\t normalizedMultisigConfig: \n name: ${config.name}\n requiredCount: ${config.requiredCount}\n signerBsms: [\n${config.signerBsms.join(',\n')}\n]',
      );

      return config;
    } catch (e) {
      Logger.error('Text parsing failed: $e');
      rethrow;
    }
  }

  Future<void> _onCompletePressed() async {
    try {
      setState(() {
        _isProcessing = true;
      });

      if (_normalizedMultisigConfig == null) return;

      final sameWalletName = _viewModel.findSameWalletName(_normalizedMultisigConfig!);
      if (sameWalletName != null) {
        if (!mounted) return;
        await showInfoPopup(context, t.alert.same_wallet.title, t.alert.same_wallet.description(name: sameWalletName));
        return;
      }

      final rawText = _bsmsController.text.trim();
      bool isCoconutMultisigConfig = _viewModel.isCoconutMultisigConfig(rawText);

      List<MultisigSigner> signers = _viewModel.getMultisigSignersFromMultisigConfig(_normalizedMultisigConfig!);

      if (isCoconutMultisigConfig) {
        final Map<String, dynamic> jsonResult = jsonDecode(rawText);
        final colorIndex = jsonResult[VaultListItemBase.fieldColorIndex] as int;
        final iconIndex = jsonResult[VaultListItemBase.fieldIconIndex] as int;

        final vault = await _viewModel.addMultisigVault(_normalizedMultisigConfig!, colorIndex, iconIndex, signers);

        if (!mounted) return;
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
      await showInfoPopup(context, t.alert.wallet_creation_failed.title, e.toString());
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _bsmsFocusNode.unfocus();
      },
      child: Scaffold(
        backgroundColor: CoconutColors.white,
        appBar: CoconutAppBar.build(title: t.bsms_scanner_screen.import_multisig_wallet, context: context),
        body: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          t.bsms_paste_screen.import_bsms,
                          textAlign: TextAlign.center,
                          style: CoconutTypography.body1_16_Bold,
                        ),
                        const SizedBox(height: 8.0),
                        _buildBSMSTextField(),
                      ],
                    ),
                  ),
                ),
              ),
              FixedBottomButton(
                onButtonClicked: _onCompletePressed,
                text: t.complete,
                showGradient: false,
                isActive: _normalizedMultisigConfig != null && !_isProcessing,
                subWidget: CoconutUnderlinedButton(
                  text: t.bsms_paste_screen.back_scan,
                  onTap: () {
                    Navigator.pushReplacementNamed(context, AppRoutes.coordinatorBsmsConfigScanner);
                  },
                ),
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
