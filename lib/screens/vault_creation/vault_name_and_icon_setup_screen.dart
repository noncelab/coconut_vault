import 'dart:io';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/app_routes_params.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/model/exception/user_canceled_auth_exception.dart';
import 'package:coconut_vault/model/single_sig/single_sig_wallet_create_dto.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/wallet_creation_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/widgets/button/fixed_bottom_button.dart';
import 'package:coconut_vault/widgets/indicator/message_activity_indicator.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/widgets/vault_name_icon_edit_palette.dart';
import 'package:provider/provider.dart';

class VaultNameAndIconSetupScreen extends StatefulWidget {
  final String? name;
  final int? iconIndex;
  final int? colorIndex;

  const VaultNameAndIconSetupScreen({super.key, this.name, this.iconIndex, this.colorIndex});

  @override
  State<VaultNameAndIconSetupScreen> createState() => _VaultNameAndIconSetupScreenState();
}

class _VaultNameAndIconSetupScreenState extends State<VaultNameAndIconSetupScreen> {
  late WalletProvider _walletProvider;
  late WalletCreationProvider _walletCreationProvider;
  String inputText = '';
  late int selectedIconIndex;
  late int selectedColorIndex;
  final TextEditingController _controller = TextEditingController();
  bool _showLoading = false;

  @override
  void initState() {
    super.initState();
    _walletProvider = Provider.of<WalletProvider>(context, listen: false);
    _walletProvider.isVaultListLoadingNotifier.addListener(_onVaultListLoading);
    _walletCreationProvider = Provider.of<WalletCreationProvider>(context, listen: false);

    // 기본값 설정 (arguments가 있으면 didChangeDependencies에서 덮어씌워짐)
    inputText = widget.name ?? '';
    selectedIconIndex = widget.iconIndex ?? 0;
    selectedColorIndex = widget.colorIndex ?? 0;
    _controller.text = inputText;
  }

  @override
  void dispose() {
    _walletProvider.isVaultListLoadingNotifier.removeListener(_onVaultListLoading);
    _walletCreationProvider.resetAll();
    _controller.dispose();
    super.dispose();
  }

  void _onVaultListLoading() {
    if (!mounted) return;

    if (!_walletProvider.isVaultListLoadingNotifier.value) {
      if (_showLoading) {
        // saveNewVaultName(context);
      }
    }
  }

  void _closeKeyboard() {
    FocusScope.of(context).unfocus();
  }

  void _trimInput() {
    inputText = inputText.trim();
    _controller.text = inputText;
  }

  Future<void> saveNewVaultName(BuildContext context) async {
    try {
      setState(() {
        _showLoading = true;
      });

      if (_walletProvider.isNameDuplicated(inputText)) {
        CoconutToast.showToast(text: t.toast.name_already_used2, context: context, isVisibleIcon: true);
        setState(() {
          _showLoading = false;
        });
        return;
      }

      VaultListItemBase? vault;
      MultisigSigner? externalSigner = _walletCreationProvider.externalSigner;

      if (_walletCreationProvider.walletType == WalletType.singleSignature) {
        if (Platform.isIOS && _walletProvider.isSigningOnlyMode) {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          if (!authProvider.hasAlreadyRequestedBioPermission && authProvider.availableBiometrics.isNotEmpty) {
            await authProvider.authenticateWithBiometrics(context: context, isSaved: true);
          }
        }

        vault = await _walletProvider.addSingleSigVault(
          SingleSigWalletCreateDto(
            null,
            inputText,
            selectedIconIndex,
            selectedColorIndex,
            _walletCreationProvider.secret,
            _walletCreationProvider.passphrase,
          ),
        );

        // externalSigner가 있는 경우, 해당 signer를 찾아서 업데이트하고 MultisigSetupInfoScreen으로 돌아가기
        if (externalSigner != null) {
          final multisigVaultId = _walletCreationProvider.multisigVaultIdOfExternalSigner;
          // _linkNewSinglesigVaultToMultisigVaults가 이미 자동으로 실행되었지만,
          // 명시적으로 MultisigSetupInfoScreen으로 돌아가기 위해 vaultList를 다시 로드
          // await _walletProvider.loadVaultList();
          _walletCreationProvider.resetAll();

          if (!context.mounted) return;
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.multisigSetupInfo,
            (Route<dynamic> route) => route.settings.name == '/',
            arguments: {'id': multisigVaultId},
          );
          return;
        }
      } else if (_walletCreationProvider.walletType == WalletType.multiSignature) {
        vault = await _walletProvider.addMultisigVault(
          inputText,
          selectedColorIndex,
          selectedIconIndex,
          _walletCreationProvider.signers!,
          _walletCreationProvider.requiredSignatureCount!,
        );
      }

      assert(_walletProvider.isAddVaultCompleted);
      assert(vault != null);
      _walletCreationProvider.resetAll();

      if (!context.mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/',
        (Route<dynamic> route) => false,
        arguments: VaultHomeNavArgs(addedWalletId: vault!.id),
      );
    } on UserCanceledAuthException catch (e) {
      Logger.error(e);
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (context) {
          return CoconutPopup(
            title: t.errors.creation_error,
            description: t.alert.auth_canceled_when_encrypt.description,
            rightButtonText: t.confirm,
            onTapRight: () => Navigator.of(context).pop(),
          );
        },
      );
    } catch (e) {
      Logger.error(e);
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (context) {
          return CoconutPopup(
            title: t.errors.creation_error,
            description: e.toString(),
            leftButtonText: t.cancel,
            rightButtonText: t.confirm,
            onTapRight: () => Navigator.of(context).pop(),
          );
        },
      );
    } finally {
      setState(() {
        _showLoading = false;
      });
    }
  }

  void updateName(String name) {
    setState(() {
      inputText = name;
    });
  }

  void updateIcon(int index) {
    setState(() {
      selectedIconIndex = index;
    });
  }

  void updateColor(int index) {
    setState(() {
      selectedColorIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PopScope(
          canPop: !_showLoading,
          onPopInvokedWithResult: (didPop, result) {
            if (_walletCreationProvider.walletType == WalletType.singleSignature) {
              _walletCreationProvider.resetSecretAndPassphrase();
            } else {
              _walletCreationProvider.resetSigner();
            }
          },
          child: Scaffold(
            backgroundColor: CoconutColors.white,
            appBar: CoconutAppBar.build(
              title: t.vault_name_icon_setup_screen.title,
              context: context,
              onBackPressed: () {
                Navigator.pop(context);
              },
              backgroundColor: CoconutColors.white,
            ),
            body: SafeArea(
              child: Stack(
                children: [
                  VaultNameIconEditPalette(
                    name: inputText,
                    iconIndex: selectedIconIndex,
                    colorIndex: selectedColorIndex,
                    onNameChanged: updateName,
                    onIconSelected: updateIcon,
                    onColorSelected: updateColor,
                  ),
                  FixedBottomButton(
                    showGradient: true,
                    text: t.complete,
                    onButtonClicked: () {
                      if (inputText.trim().isEmpty) return;
                      _closeKeyboard();
                      if (_walletProvider.isVaultListLoading) {
                        setState(() {
                          _showLoading = true;
                        });
                      } else {
                        _trimInput();
                        saveNewVaultName(context);
                      }
                    },
                    backgroundColor: CoconutColors.black,
                    isActive: inputText.trim().isNotEmpty && !_showLoading,
                  ),
                ],
              ),
            ),
          ),
        ),
        Visibility(
          visible: _showLoading,
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            decoration: BoxDecoration(color: CoconutColors.black.withValues(alpha: 0.3)),
            child: Center(
              child:
                  _walletProvider.isVaultListLoading
                      ? MessageActivityIndicator(message: t.vault_name_icon_setup_screen.saving)
                      : const CircularProgressIndicator(color: CoconutColors.gray800),
            ),
          ),
        ),
      ],
    );
  }
}
