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
          languageCode: context.read<VisibilityProvider>().language,
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
                DateTime.fromMillisecondsSinceEpoch(locktime >= 1000000000000 ? locktime : locktime * 1000),
              );

              return TaprootParticipantCard(
                role: TaprootParticipantRole.child,
                mfp: beneficiary.masterFingerprint,
                derivationPath: vault.derivationPath,
                walletName: beneficiary.isSeedStored ? vault.name : null,
                locktime: beneficiary.lockTime,
                isMine: isMine,
                hasBackgroundColor: isMine || isLocktimeNotPassed,
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
                            onPressed:
                                !hasLocalSeed
                                    ? null
                                    : () {
                                      if (viewModel.isSigningOnlyMode) {
                                        Navigator.pushNamed(
                                          context,
                                          AppRoutes.mnemonicView,
                                          arguments: {'id': widget.id},
                                        );
                                        return;
                                      }

                                      _authenticateWithBiometricOrPin(
                                        context,
                                        PinCheckContextEnum.sensitiveAction,
                                        () => Navigator.pushNamed(
                                          context,
                                          AppRoutes.mnemonicView,
                                          arguments: {'id': widget.id},
                                        ),
                                      );
                                    },
                          ),
                          if (hasPassphrase)
                            SingleButton(
                              title: t.verify_passphrase,
                              onPressed:
                                  () => Navigator.pushNamed(
                                    context,
                                    AppRoutes.passphraseVerification,
                                    arguments: {'id': widget.id},
                                  ),
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
