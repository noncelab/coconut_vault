import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/enums/pin_check_context_enum.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/taproot/taproot_vault_list_item.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/view_model/wallet_info/wallet_info_view_model.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/screens/common/pin_check_screen.dart';
import 'package:coconut_vault/widgets/button/shrink_animation_button.dart';
import 'package:coconut_vault/screens/home/select_vault_bottom_sheet.dart';
import 'package:coconut_vault/utils/vibration_util.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/button/button_group.dart';
import 'package:coconut_vault/widgets/button/single_button.dart';
import 'package:coconut_vault/widgets/card/taproot/taproot_participant_card.dart';
import 'package:coconut_vault/widgets/card/taproot/taproot_setup_summary_card.dart';
import 'package:coconut_vault/widgets/card/taproot/taproot_vault_item_card.dart';
import 'package:coconut_vault/widgets/custom_loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class TaprootWalletInfoScreen extends StatefulWidget {
  final int id;
  final String? entryPoint;
  const TaprootWalletInfoScreen({super.key, required this.id, this.entryPoint});

  @override
  State<TaprootWalletInfoScreen> createState() => _TaprootWalletInfoScreenState();
}

class _TaprootWalletInfoScreenState extends State<TaprootWalletInfoScreen> {
  Future<void> _authenticateWithBiometricOrPin(
    BuildContext context,
    PinCheckContextEnum pinCheckContext,
    VoidCallback onSuccess,
  ) async {
    final authProvider = context.read<AuthProvider>();

    final isBiometricValid =
        pinCheckContext == PinCheckContextEnum.sensitiveAction
            ? await authProvider.isBiometricsAuthValidToAvoidDoubleAuth()
            : await authProvider.isBiometricsAuthValid();

    if (isBiometricValid && context.mounted) {
      onSuccess();
      return;
    }

    if (!context.mounted) return;
    await MyBottomSheet.showBottomSheet_90(
      context: context,
      child: CustomLoadingOverlay(
        child: PinCheckScreen(
          pinCheckContext: pinCheckContext,
          onSuccess: () async {
            Navigator.pop(context);
            onSuccess();
          },
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WalletInfoViewModel viewModel) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return CoconutPopup(
          languageCode: context.read<VisibilityProvider>().appLanguage.code,
          insetPadding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.15),
          title: t.alert.delete_vault.title,
          description: t.alert.delete_vault.description,
          backgroundColor: CoconutColors.white,
          leftButtonText: t.no,
          leftButtonColor: CoconutColors.black.withValues(alpha: 0.7),
          rightButtonText: t.yes,
          rightButtonColor: CoconutColors.warningText,
          onTapLeft: () => Navigator.pop(context),
          onTapRight: () async {
            Navigator.pop(context);

            if (!viewModel.isSigningOnlyMode) {
              await _authenticateWithBiometricOrPin(
                context,
                PinCheckContextEnum.seedDeletion,
                () => _deleteVault(context, viewModel),
              );
            } else {
              _deleteVault(context, viewModel);
            }
          },
        );
      },
    );
  }

  Future<void> _deleteVault(BuildContext context, WalletInfoViewModel viewModel) async {
    await viewModel.deleteVault();
    if (!mounted) return;

    vibrateLight();

    if (widget.entryPoint != null && widget.entryPoint == AppRoutes.vaultList) {
      Navigator.popUntil(context, (route) {
        return route.settings.name == AppRoutes.vaultList;
      });
    } else {
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  void _onVerifyPassphrasePressed(TaprootVaultListItem vault) {
    final localParticipants = _getLocalParticipants(vault);

    if (localParticipants.length > 1) {
      _showParticipantSelectionSheet(
        vault: vault,
        title: t.verify_passphrase,
        onSelected: (xpub) => _navigateToVerification(xpub),
        checkPassphrase: true,
      );
    } else if (localParticipants.isNotEmpty) {
      _navigateToVerification(localParticipants.first.xpub);
    }
  }

  List<({String name, String xpub, bool hasPassphrase})> _getLocalParticipants(TaprootVaultListItem vault) {
    final List<({String name, String xpub, bool hasPassphrase})> participants = [];

    for (int i = 0; i < vault.owners.length; i++) {
      if (vault.owners[i].isSeedStored) {
        final name =
            vault.owners.length == 1
                ? t.taproot.parent_wallet
                : '${t.taproot.parent_wallet} ${String.fromCharCode(65 + i)}';
        participants.add((
          name: name,
          xpub: vault.owners[i].extendedPublicKey,
          hasPassphrase: vault.owners[i].isPassphraseSet,
        ));
      }
    }

    for (int i = 0; i < vault.beneficiaries.length; i++) {
      if (vault.beneficiaries[i].isSeedStored) {
        final name = vault.beneficiaries.length == 1 ? t.taproot.child_wallet : '${t.taproot.child_wallet} ${i + 1}';
        participants.add((
          name: name,
          xpub: vault.beneficiaries[i].extendedPublicKey,
          hasPassphrase: vault.beneficiaries[i].isPassphraseSet,
        ));
      }
    }
    return participants;
  }

  void _onViewMnemonicPressed(TaprootVaultListItem vault, WalletInfoViewModel viewModel) {
    final localParticipants = _getLocalParticipants(vault);

    if (localParticipants.length > 1) {
      _showParticipantSelectionSheet(
        vault: vault,
        title: t.view_mnemonic,
        onSelected: (xpub) => _handleMnemonicViewAuth(xpub, viewModel),
      );
    } else if (localParticipants.isNotEmpty) {
      _handleMnemonicViewAuth(localParticipants.first.xpub, viewModel);
    }
  }

  void _handleMnemonicViewAuth(String xpub, WalletInfoViewModel viewModel) {
    if (viewModel.isSigningOnlyMode) {
      _navigateToMnemonicView(xpub);
      return;
    }

    _authenticateWithBiometricOrPin(context, PinCheckContextEnum.sensitiveAction, () => _navigateToMnemonicView(xpub));
  }

  void _showParticipantSelectionSheet({
    required TaprootVaultListItem vault,
    required String title,
    required Function(String xpub) onSelected,
    bool checkPassphrase = false,
  }) {
    final owners = <({String name, String xpub, bool hasPassphrase, bool isParent})>[];
    for (int i = 0; i < vault.owners.length; i++) {
      if (vault.owners[i].isSeedStored) {
        final name =
            vault.owners.length == 1
                ? t.taproot.parent_wallet
                : '${t.taproot.parent_wallet} ${String.fromCharCode(65 + i)}';
        owners.add((
          name: name,
          xpub: vault.owners[i].extendedPublicKey,
          hasPassphrase: vault.owners[i].isPassphraseSet,
          isParent: true,
        ));
      }
    }

    final beneficiaries = <({String name, String xpub, bool hasPassphrase, bool isParent})>[];
    for (int i = 0; i < vault.beneficiaries.length; i++) {
      if (vault.beneficiaries[i].isSeedStored) {
        final name = vault.beneficiaries.length == 1 ? t.taproot.child_wallet : '${t.taproot.child_wallet} ${i + 1}';
        beneficiaries.add((
          name: name,
          xpub: vault.beneficiaries[i].extendedPublicKey,
          hasPassphrase: vault.beneficiaries[i].isPassphraseSet,
          isParent: false,
        ));
      }
    }

    MyBottomSheet.showDraggableBottomSheet(
      context: context,
      title: title,
      childBuilder:
          (scrollController) => SelectVaultBottomSheet(
            scrollController: scrollController,
            children: [
              if (owners.isNotEmpty) ...owners.map((p) => _buildSelectionItem(p, vault, onSelected, checkPassphrase)),
              if (beneficiaries.isNotEmpty)
                ...beneficiaries.map((p) => _buildSelectionItem(p, vault, onSelected, checkPassphrase)),
              CoconutLayout.spacing_400h,
            ],
          ),
    );
  }

  Widget _buildSelectionItem(
    ({String name, String xpub, bool hasPassphrase, bool isParent}) p,
    TaprootVaultListItem vault,
    Function(String xpub) onSelected,
    bool checkPassphrase,
  ) {
    final baseColors = [CoconutColors.lightSky.withValues(alpha: 0.2), CoconutColors.periwinkle.withValues(alpha: 0.2)];
    final taprootGradientColors = p.isParent ? baseColors.reversed.toList() : baseColors;
    final isActive = !checkPassphrase || p.hasPassphrase;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ShrinkAnimationButton(
        pressedColor: CoconutColors.gray150,
        borderRadius: 8,
        isActive: isActive,
        onPressed: () {
          Navigator.pop(context);
          onSelected(p.xpub);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: CoconutColors.gray200, width: 1),
            gradient: LinearGradient(
              colors: taprootGradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              SvgPicture.asset(p.isParent ? 'assets/svg/parent.svg' : 'assets/svg/child.svg', width: 30, height: 30),
              CoconutLayout.spacing_200w,
              Expanded(
                child: Text(
                  p.name,
                  style: CoconutTypography.body2_14_Bold.setColor(
                    isActive ? CoconutColors.black : CoconutColors.gray400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              CoconutLayout.spacing_200w,
              SvgPicture.asset(
                'assets/svg/chevron-right.svg',
                width: 6,
                height: 10,
                colorFilter: ColorFilter.mode(
                  isActive ? CoconutColors.gray800 : CoconutColors.gray300,
                  BlendMode.srcIn,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToVerification(String xpub) {
    Navigator.pushNamed(context, AppRoutes.passphraseVerification, arguments: {'id': widget.id, 'targetXpub': xpub});
  }

  void _navigateToMnemonicView(String xpub) {
    Navigator.pushNamed(context, AppRoutes.mnemonicView, arguments: {'id': widget.id, 'targetXpub': xpub});
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create:
          (context) =>
              WalletInfoViewModel(Provider.of<WalletProvider>(context, listen: false), widget.id, isMultisig: false),
      child: Consumer<WalletInfoViewModel>(
        builder: (context, viewModel, child) {
          if (!viewModel.isInitialized) {
            return const Scaffold(
              backgroundColor: CoconutColors.white,
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final vault = viewModel.vaultItem as TaprootVaultListItem;
          final bool hasStoredOwnerSeed = vault.owners.any((owner) => owner.isSeedStored);

          final List<TaprootParticipantCard> participantCards = [
            // 상위 지갑 참여자 (Key Path)
            ...vault.owners.asMap().entries.map((entry) {
              final index = entry.key;
              final owner = entry.value;
              final walletName =
                  vault.owners.length == 1
                      ? t.taproot.parent_wallet
                      : '${t.taproot.parent_wallet} ${String.fromCharCode(65 + index)}';

              return TaprootParticipantCard(
                role: TaprootParticipantRole.parent,
                mfp: owner.masterFingerprint,
                derivationPath: vault.derivationPath,
                walletName: walletName,
                isMine: owner.isSeedStored,
                hasBackgroundColor: owner.isSeedStored,
                hasSingleParent: vault.owners.length == 1,
              );
            }),
            // 하위 지갑 참여자 (Script Path / 상속 조건)
            ...vault.beneficiaries.map((beneficiary) {
              final bool isMine = beneficiary.isSeedStored;
              final locktime = beneficiary.lockTime;
              final bool isLocktimeNotPassed = DateTime.now().isBefore(
                DateTime.fromMillisecondsSinceEpoch(locktime * 1000),
              );

              return TaprootParticipantCard(
                role: TaprootParticipantRole.child,
                mfp: beneficiary.masterFingerprint,
                derivationPath: vault.derivationPath,
                walletName: beneficiary.isSeedStored ? vault.name : null,
                locktime: beneficiary.lockTime,
                isMine: isMine && !hasStoredOwnerSeed,
                hasBackgroundColor: isMine,
                showLockStatusIcon: isLocktimeNotPassed,
              );
            }),
          ];

          final bool hasPassphrase =
              vault.owners.any((o) => o.isSeedStored && o.isPassphraseSet) ||
              vault.beneficiaries.any((b) => b.isSeedStored && b.isPassphraseSet);

          final bool hasLocalSeed =
              vault.owners.any((o) => o.isSeedStored) || vault.beneficiaries.any((b) => b.isSeedStored);

          return Scaffold(
            backgroundColor: CoconutColors.white,
            appBar: CoconutAppBar.build(
              context: context,
              title: vault.name,
              actionButtonList: [
                IconButton(
                  onPressed: () => _showDeleteDialog(context, viewModel),
                  icon: SvgPicture.asset(
                    'assets/svg/trash.svg',
                    width: 20,
                    colorFilter: const ColorFilter.mode(CoconutColors.red, BlendMode.srcIn),
                  ),
                ),
              ],
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    CoconutLayout.spacing_500h,
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TaprootVaultItemCard(vaultItem: vault, showTaprootWalletInfo: true),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TaprootSetupSummaryCard(
                        itemList: participantCards,
                        taprootSetupSummaryCardType: TaprootSetupSummaryCardType.tree,
                      ),
                    ),
                    CoconutLayout.spacing_500h,
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ButtonGroup(
                        buttons: [
                          SingleButton(
                            title: t.vault_home_screen.action_items.sign,
                            onPressed:
                                () => Navigator.pushNamed(context, AppRoutes.psbtScanner, arguments: {'id': widget.id}),
                          ),
                          SingleButton(
                            title: t.view_address,
                            onPressed:
                                () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.addressList,
                                  arguments: {'id': widget.id, 'isSpecificVault': true},
                                ),
                          ),
                          SingleButton(
                            title: t.view_mnemonic,
                            onPressed: !hasLocalSeed ? null : () => _onViewMnemonicPressed(vault, viewModel),
                          ),
                          if (hasPassphrase)
                            SingleButton(
                              title: t.verify_passphrase,
                              onPressed: () => _onVerifyPassphrasePressed(vault),
                            ),
                          SingleButton(
                            title: t.vault_menu_screen.export_wallet,
                            onPressed:
                                () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.vaultExportOptions,
                                  arguments: {'id': widget.id, 'walletType': WalletType.taproot},
                                ),
                          ),
                        ],
                      ),
                    ),
                    CoconutLayout.spacing_500h,
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
