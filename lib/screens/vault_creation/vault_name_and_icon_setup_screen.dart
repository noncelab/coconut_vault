import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/app_routes_params.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/exception/user_canceled_auth_exception.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/view_model/vault_creation/vault_name_and_icon_setup_view_model.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/providers/wallet_creation/wallet_creation_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/utils/popup_util.dart';
import 'package:coconut_vault/widgets/button/fixed_bottom_button.dart';
import 'package:coconut_vault/widgets/indicator/message_activity_indicator.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/widgets/vault_name_icon_edit_palette.dart';
import 'package:provider/provider.dart';

class VaultNameAndIconSetupScreen extends StatefulWidget {
  final String? name;
  final int? iconIndex;
  final int? colorIndex;
  final bool? isImported;
  final bool isEmbedded;
  final bool isTaproot;
  final ValueChanged<VaultNameAndIconSetupSaveResult>? onEmbeddedVaultSaved;
  final TaprootVaultSaveHandler? taprootVaultSaveHandler;

  const VaultNameAndIconSetupScreen({
    super.key,
    this.name,
    this.iconIndex,
    this.colorIndex,
    this.isImported,
    this.isEmbedded = false,
    this.isTaproot = false,
    this.onEmbeddedVaultSaved,
    this.taprootVaultSaveHandler,
  });

  @override
  State<VaultNameAndIconSetupScreen> createState() => _VaultNameAndIconSetupScreenState();
}

class _VaultNameAndIconSetupScreenState extends State<VaultNameAndIconSetupScreen> {
  late VaultNameAndIconSetupViewModel _viewModel;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = VaultNameAndIconSetupViewModel(
      Provider.of<WalletProvider>(context, listen: false),
      Provider.of<WalletCreationProvider>(context, listen: false),
      Provider.of<AuthProvider>(context, listen: false),
      taprootVaultSaveHandler: widget.isTaproot ? widget.taprootVaultSaveHandler : null,
      initialName: widget.name ?? '',
      initialIconIndex: widget.iconIndex ?? 0,
      initialColorIndex: widget.colorIndex ?? 0,
      isImported: widget.isImported == true,
    );
    _controller.text = _viewModel.inputText;
  }

  @override
  void dispose() {
    _viewModel.handleDisposeReset();
    _viewModel.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _closeKeyboard() {
    FocusScope.of(context).unfocus();
  }

  Future<void> _saveNewVaultName(BuildContext context) async {
    try {
      final result = await _viewModel.saveNewVault();
      if (!context.mounted) return;

      if (result.status == VaultNameAndIconSetupSaveStatus.duplicateName) {
        CoconutToast.showToast(text: t.toast.name_already_used2, context: context, isVisibleIcon: true);
        return;
      }

      if (result.status == VaultNameAndIconSetupSaveStatus.navigateMultisigSetupInfo) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.multisigSetupInfo,
          (Route<dynamic> route) => route.settings.name == '/',
          arguments: {'id': result.multisigVaultId},
        );
        return;
      }

      if (widget.isEmbedded && widget.onEmbeddedVaultSaved != null) {
        widget.onEmbeddedVaultSaved!(result);
        return;
      }

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/',
        (Route<dynamic> route) => false,
        arguments: VaultHomeNavArgs(addedWalletId: result.addedWalletId!),
      );
    } on UserCanceledAuthException catch (e) {
      Logger.error(e);
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (context) {
          return CoconutPopup(
            languageCode: context.read<VisibilityProvider>().appLanguage.code,
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
      showInfoPopup(context, t.errors.creation_error, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<VaultNameAndIconSetupViewModel>.value(
      value: _viewModel,
      child: Consumer<VaultNameAndIconSetupViewModel>(
        builder: (context, viewModel, child) {
          if (_controller.text != viewModel.inputText) {
            _controller.value = _controller.value.copyWith(
              text: viewModel.inputText,
              selection: TextSelection.collapsed(offset: viewModel.inputText.length),
              composing: TextRange.empty,
            );
          }

          final body = Stack(
            children: [
              VaultNameIconEditPalette(
                name: viewModel.inputText,
                iconIndex: viewModel.selectedIconIndex,
                colorIndex: viewModel.selectedColorIndex,
                onNameChanged: viewModel.updateName,
                onIconSelected: viewModel.updateIcon,
                onColorSelected: viewModel.updateColor,
              ),
              FixedBottomButton(
                showGradient: true,
                text: t.complete,
                onButtonClicked: () {
                  if (viewModel.inputText.trim().isEmpty) return;
                  _closeKeyboard();
                  if (viewModel.isVaultListLoading) {
                    viewModel.setShowLoading(true);
                  } else {
                    _saveNewVaultName(context);
                  }
                },
                backgroundColor: CoconutColors.black,
                isActive: viewModel.isSaveEnabled,
              ),
            ],
          );

          final screen = PopScope(
            canPop: !viewModel.showLoading,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) {
                viewModel.setPoppedByBack(true);
              }
            },
            child:
                widget.isEmbedded
                    ? body
                    : Scaffold(
                      backgroundColor: CoconutColors.white,
                      appBar: CoconutAppBar.build(
                        title: t.vault_name_icon_setup_screen.title,
                        context: context,
                        onBackPressed: () {
                          Navigator.pop(context);
                        },
                        backgroundColor: CoconutColors.white,
                      ),
                      body: SafeArea(child: body),
                    ),
          );

          return Stack(
            children: [
              screen,
              Visibility(
                visible: viewModel.showLoading,
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  decoration: BoxDecoration(color: CoconutColors.black.withValues(alpha: 0.3)),
                  child: Center(
                    child:
                        viewModel.isVaultListLoading
                            ? MessageActivityIndicator(message: t.vault_name_icon_setup_screen.saving)
                            : const CircularProgressIndicator(color: CoconutColors.gray800),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
