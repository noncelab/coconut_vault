import 'dart:io';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/app_routes_params.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/model/multisig/multisig_vault_list_item.dart';
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
  final String name;
  final int iconIndex;
  final int colorIndex;

  const VaultNameAndIconSetupScreen({super.key, this.name = '', this.iconIndex = 0, this.colorIndex = 0});

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

  // 초기화 여부 체크 플래그 (키보드가 올라올 때 등 화면이 갱신될 때 데이터가 리셋되는 것을 방지)
  bool _isInitialized = false;
  // 자동 저장 실행 여부 플래그
  bool _isAutoSaving = false;

  @override
  void initState() {
    super.initState();
    _walletProvider = Provider.of<WalletProvider>(context, listen: false);
    _walletProvider.isVaultListLoadingNotifier.addListener(_onVaultListLoading);
    _walletCreationProvider = Provider.of<WalletCreationProvider>(context, listen: false);

    // 기본값 설정 (arguments가 있으면 didChangeDependencies에서 덮어씌워짐)
    inputText = widget.name;
    selectedIconIndex = widget.iconIndex;
    selectedColorIndex = widget.colorIndex;
    _controller.text = inputText;
  }

  // TODO: 아래 이벤트 함수 삭제 가능한지 확인
  // Arguments 처리 로직
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isInitialized) {
      final args = ModalRoute.of(context)?.settings.arguments;
      // bool shouldAutoSave = false;

      if (args != null && args is Map<String, dynamic>) {
        if (args.containsKey('name')) {
          inputText = args['name'] as String;
          _controller.text = inputText;
        }
        if (args.containsKey('iconIndex')) {
          selectedIconIndex = args['iconIndex'] as int;
        }
        if (args.containsKey('colorIndex')) {
          selectedColorIndex = args['colorIndex'] as int;
        }

        // 이름이 있으면 자동 저장 플래그 설정
        //if (inputText.trim().isNotEmpty) {
        //shouldAutoSave = true;
        //}
      }

      _isInitialized = true;

      // if (shouldAutoSave) {
      //   _isAutoSaving = true;
      //   // 화면이 다 그려진 직후 저장 로직 실행
      //   WidgetsBinding.instance.addPostFrameCallback((_) {
      //     _closeKeyboard();
      //     // 여기서 saveNewVaultName을 호출하면 내부에서 _showLoading = true가 되면서 로딩 화면이 뜸
      //     saveNewVaultName(context);
      //   });
      // }
    }
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

  void _removeTrim() {
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
          _isAutoSaving = false;
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
        _isAutoSaving = false;
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
                        _removeTrim(); // TODO: 테스트 필요
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
                  _walletProvider.isVaultListLoading || _isAutoSaving
                      ? MessageActivityIndicator(message: t.vault_name_icon_setup_screen.saving)
                      : const CircularProgressIndicator(color: CoconutColors.gray800),
            ),
          ),
        ),
      ],
    );
  }
}
