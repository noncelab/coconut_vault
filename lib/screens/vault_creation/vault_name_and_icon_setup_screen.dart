import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/app_routes_params.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/single_sig/single_sig_wallet_create_dto.dart';
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

  const VaultNameAndIconSetupScreen({
    super.key,
    this.name = '',
    this.iconIndex = 0,
    this.colorIndex = 0,
  });

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
  bool _isTextFieldFocused = false;

  @override
  void initState() {
    super.initState();
    _walletProvider = Provider.of<WalletProvider>(context, listen: false);
    _walletProvider.isVaultListLoadingNotifier.addListener(_onVaultListLoading);
    _walletCreationProvider = Provider.of<WalletCreationProvider>(context, listen: false);
    inputText = widget.name;
    selectedIconIndex = widget.iconIndex;
    selectedColorIndex = widget.colorIndex;
    _controller.text = inputText;
  }

  @override
  void dispose() {
    _walletProvider.isVaultListLoadingNotifier.removeListener(_onVaultListLoading);
    _walletCreationProvider.resetAll();
    super.dispose();
  }

  void _onVaultListLoading() {
    if (!mounted) return;

    if (!_walletProvider.isVaultListLoadingNotifier.value) {
      if (_showLoading) {
        saveNewVaultName(context);
      }
    }
  }

  void _closeKeyboard() {
    FocusScope.of(context).unfocus();
  }

  Future<void> saveNewVaultName(BuildContext context) async {
    try {
      setState(() {
        _showLoading = true;
      });

      if (_walletProvider.isNameDuplicated(inputText)) {
        CoconutToast.showToast(
            text: t.toast.name_already_used2, context: context, isVisibleIcon: true);
        setState(() {
          _showLoading = false;
        });
        return;
      }

      if (_walletCreationProvider.secret != null) {
        await _walletProvider.addSingleSigVault(SingleSigWalletCreateDto(
            null,
            inputText,
            selectedIconIndex,
            selectedColorIndex,
            _walletCreationProvider.secret!,
            _walletCreationProvider.passphrase));
      } else if (_walletCreationProvider.signers != null) {
        // 새로운 멀티시그 지갑 리스트 아이템을 생성.
        await _walletProvider.addMultisigVault(inputText, selectedColorIndex, selectedIconIndex,
            _walletCreationProvider.signers!, _walletCreationProvider.requiredSignatureCount!);
      } else {
        throw '생성 가능 정보가 없음';
      }

      assert(_walletProvider.isAddVaultCompleted);
      _walletCreationProvider.resetAll();

      Navigator.pushNamedAndRemoveUntil(context, '/', (Route<dynamic> route) => false,
          arguments: VaultListNavArgs(isWalletAdded: true));
    } catch (e) {
      Logger.error(e);
      if (!mounted) return;
      showDialog(
          context: context,
          builder: (context) {
            return CoconutPopup(
              title: t.errors.creation_error,
              description: e.toString(),
              onTapRight: () => Navigator.of(context).pop(),
            );
          });
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

  void updateFocusState(bool isFocused) {
    setState(() {
      _isTextFieldFocused = isFocused;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PopScope(
          canPop: true,
          onPopInvokedWithResult: (didPop, result) {
            if (_walletCreationProvider.secret != null) {
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
              child: Stack(children: [
                VaultNameIconEditPalette(
                  name: inputText,
                  iconIndex: selectedIconIndex,
                  colorIndex: selectedColorIndex,
                  onNameChanged: updateName,
                  onIconSelected: updateIcon,
                  onColorSelected: updateColor,
                  onFocusChanged: updateFocusState,
                ),
                FixedBottomButton(
                  showGradient: true,
                  text: t.next,
                  onButtonClicked: () {
                    if (inputText.trim().isEmpty) return;
                    _closeKeyboard();
                    if (_walletProvider.isVaultListLoading) {
                      setState(() {
                        _showLoading = true;
                      });
                    } else {
                      saveNewVaultName(context);
                    }
                  },
                  backgroundColor: CoconutColors.black,
                  isActive: inputText.trim().isNotEmpty && !_showLoading,
                ),
              ]),
            ),
          ),
        ),
        Visibility(
          visible: _showLoading,
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            decoration: BoxDecoration(color: CoconutColors.black.withOpacity(0.3)),
            child: Center(
              child: _walletProvider.isVaultListLoading
                  ? MessageActivityIndicator(
                      message: t.vault_name_icon_setup_screen.saving) // 기존 볼트들 불러오는 중
                  : const CircularProgressIndicator(color: CoconutColors.gray800),
            ),
          ),
        ),
      ],
    );
  }
}
