import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/view_model/vault_creation/taproot/child_creation_view_model.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/screens/common/menu_grid.dart';
import 'package:coconut_vault/widgets/adaptive_qr_image.dart';
import 'package:coconut_vault/widgets/box/info_box.dart';
import 'package:coconut_vault/widgets/card/selectable_option_card.dart';
import 'package:coconut_vault/widgets/card/taproot/taproot_participant_card.dart';
import 'package:coconut_vault/widgets/card/taproot/taproot_setup_summary_card.dart';
import 'package:coconut_vault/widgets/card/taproot/taproot_vault_item_card.dart';
import 'package:coconut_vault/widgets/indicator/timeline_step_indicator.dart';
import 'package:coconut_vault/widgets/vault_row_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class ChildPreparationOptionStep extends StatelessWidget {
  const ChildPreparationOptionStep({super.key, required this.viewModel});

  final ChildCreationViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return MenuGrid(
      children: [
        SelectableOptionCard(
          title: t.taproot.common.prepare_key_option1_title,
          description: t.taproot.common.prepare_key_option1_desc,
          bottomAssetPath: 'assets/png/wallet.png',
          imageScale: 4.0,
          imageWidth: 100,
          isSelected: viewModel.keyPreparationType == ChildKeyPreparationType.create,
          height: 217,
          onTap: () => viewModel.setKeyPreparationType(ChildKeyPreparationType.create),
        ),
        SelectableOptionCard(
          title: t.taproot.common.prepare_key_option2_title,
          description: t.taproot.common.prepare_key_option2_desc,
          bottomAssetPath: 'assets/png/key-holder.png',
          imageScale: 4.0,
          imageWidth: 100,
          isSelected: viewModel.keyPreparationType == ChildKeyPreparationType.import,
          height: 217,
          onTap: () => viewModel.setKeyPreparationType(ChildKeyPreparationType.import),
        ),
      ],
    );
  }
}

class ChildCreationOptionStep extends StatelessWidget {
  const ChildCreationOptionStep({super.key, required this.viewModel});

  final ChildCreationViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    if (viewModel.keyPreparationType == ChildKeyPreparationType.create) {
      return MenuGrid(
        children: [
          SelectableOptionCard(
            title: t.taproot.common.new_option1,
            bottomAssetPath: 'assets/png/coin.png',
            imageScale: 4.0,
            imageWidth: 67,
            isSelected: viewModel.newKeyCreationType == ChildNewKeyCreationType.coinFlip,
            height: 118,
            onTap: () => viewModel.setNewKeyCreationType(ChildNewKeyCreationType.coinFlip),
          ),
          SelectableOptionCard(
            title: t.taproot.common.new_option2,
            bottomAssetPath: 'assets/png/dice.png',
            imageScale: 4.0,
            imageWidth: 67,
            isSelected: viewModel.newKeyCreationType == ChildNewKeyCreationType.diceRoll,
            height: 118,
            onTap: () => viewModel.setNewKeyCreationType(ChildNewKeyCreationType.diceRoll),
          ),
          SelectableOptionCard(
            title: t.taproot.common.new_option3,
            bottomAssetPath: 'assets/png/gear.png',
            imageScale: 4.0,
            imageWidth: 67,
            isSelected: viewModel.newKeyCreationType == ChildNewKeyCreationType.autoGenerate,
            height: 118,
            onTap: () => viewModel.setNewKeyCreationType(ChildNewKeyCreationType.autoGenerate),
          ),
        ],
      );
    }

    return Consumer<WalletProvider>(
      builder: (context, walletProvider, child) {
        final hasNoSingleSigVault = walletProvider.getVaultsByWalletType(WalletType.singleSignature).isEmpty;
        return MenuGrid(
          children: [
            SelectableOptionCard(
              title: t.taproot.common.existing_option1,
              isDisabled: hasNoSingleSigVault,
              bottomAssetPath: 'assets/png/finger-picking.png',
              imageScale: 4.0,
              imageWidth: 67,
              isSelected: viewModel.existingKeyImportType == ChildExistingKeyImportType.currentVault,
              height: 118,
              onDisabledTap: () {
                CoconutToast.showToast(
                  context: context,
                  level: CoconutToastLevel.info,
                  isVisibleIcon: true,
                  text: t.taproot.common.existing_option1_toast,
                );
              },
              onTap: () => viewModel.setExistingKeyImportType(ChildExistingKeyImportType.currentVault),
            ),
            SelectableOptionCard(
              title: t.taproot.common.existing_option2,
              bottomAssetPath: 'assets/png/word.png',
              imageScale: 4.0,
              imageWidth: 67,
              isSelected: viewModel.existingKeyImportType == ChildExistingKeyImportType.mnemonicInput,
              height: 118,
              onTap: () => viewModel.setExistingKeyImportType(ChildExistingKeyImportType.mnemonicInput),
            ),
            SelectableOptionCard(
              title: t.taproot.common.existing_option3,
              bottomAssetPath: 'assets/png/scan-qr.png',
              imageScale: 4.0,
              imageWidth: 67,
              isSelected: viewModel.existingKeyImportType == ChildExistingKeyImportType.seedQrScan,
              height: 118,
              onTap: () => viewModel.setExistingKeyImportType(ChildExistingKeyImportType.seedQrScan),
            ),
          ],
        );
      },
    );
  }
}

class ChildImportSummaryStep extends StatelessWidget {
  const ChildImportSummaryStep({super.key, required this.viewModel});

  final ChildCreationViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final scannedVaultItem = viewModel.scannedVaultItem;
    if (scannedVaultItem == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!viewModel.isBeneficiaryMatch) ...[
          CoconutLayout.spacing_1500h,
          SvgPicture.asset('assets/svg/triangle-warning.svg', width: 25, height: 25),
          CoconutLayout.spacing_200h,
          Text(
            t.taproot.child_creation_screen.step6.title2,
            style: CoconutTypography.heading3_21_Bold.setColor(CoconutColors.hotPink),
            textAlign: TextAlign.center,
          ),
          CoconutLayout.spacing_800h,
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TaprootVaultItemCard(vaultItem: scannedVaultItem, showTaprootWalletInfo: false),
        ),
        CoconutLayout.spacing_200h,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: TaprootSetupSummaryCard(
            itemList: [
              ...scannedVaultItem.owners.asMap().entries.map((entry) {
                final index = entry.key;
                final owner = entry.value;
                final isSingleParent = scannedVaultItem.owners.length == 1;
                final parentName =
                    isSingleParent
                        ? t.taproot.parent_wallet
                        : '${t.taproot.parent_wallet} ${String.fromCharCode(65 + index)}';

                return TaprootParticipantCard(
                  role: TaprootParticipantRole.parent,
                  walletName: parentName,
                  mfp: owner.masterFingerprint,
                  derivationPath: scannedVaultItem.derivationPath,
                  hasSingleParent: isSingleParent,
                  hasBackgroundColor: true,
                  isMine: owner.isSeedStored,
                );
              }),
              ...scannedVaultItem.beneficiaries.map(
                (beneficiary) => TaprootParticipantCard(
                  role: TaprootParticipantRole.child,
                  mfp: beneficiary.masterFingerprint,
                  derivationPath: scannedVaultItem.derivationPath,
                  locktime: beneficiary.lockTime,
                  hasBackgroundColor: true,
                  isMine: beneficiary.isSeedStored || beneficiary.masterFingerprint == viewModel.masterFingerprint,
                  isValid: beneficiary.masterFingerprint == viewModel.masterFingerprint,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ChildCreationTimelineStep extends StatelessWidget {
  const ChildCreationTimelineStep({super.key, required this.viewModel});

  final ChildCreationViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final lang = context.read<VisibilityProvider>().language;
    final dateString = viewModel.getFormattedLockTime(lang);

    return TimelineStepIndicator(
      enableTapToSkip: true,
      timelineStepItemList: [
        TimelineStepItem(
          title: t.taproot.child_creation_screen.step7.timeline.created_wallet,
          description: t.taproot.child_creation_screen.step7.timeline.singlesig_description(
            mfp: viewModel.masterFingerprint ?? '000000',
          ),
          status: TimelineStepStatus.current,
        ),
        TimelineStepItem(
          title: t.taproot.child_creation_screen.step7.timeline.exported_to_parent,
          description: t.taproot.child_creation_screen.step7.timeline.taproot_description(
            mfp: viewModel.scannedParentMfps,
          ),
          status: TimelineStepStatus.upcoming,
        ),
        TimelineStepItem(
          title: t.taproot.child_creation_screen.step7.timeline.imported_inheritance_info,
          description:
              '${viewModel.scannedVaultItem?.name ?? 'Name'} | ${viewModel.scannedVaultItem?.owners.length == 1 ? t.taproot.child_creation_screen.step7.timeline.single_sig_wallet : t.taproot.child_creation_screen.step7.timeline.multisig_wallet}',
          status: TimelineStepStatus.upcoming,
        ),
        TimelineStepItem(
          title: t.taproot.child_creation_screen.step7.timeline.active_inheritance_wallet,
          description: t.taproot.child_creation_screen.step7.timeline.time_after(date: dateString),
          status: TimelineStepStatus.future,
        ),
      ],
    );
  }
}

class ChildWalletQrSection extends StatelessWidget {
  const ChildWalletQrSection({super.key, required this.viewModel});

  final ChildCreationViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 21),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (viewModel.qrData != null && viewModel.qrData!.isNotEmpty)
            AdaptiveQrImage(qrData: viewModel.qrData!)
          else
            const SizedBox(height: 200),
          CoconutLayout.spacing_500h,
          InfoBox(
            infoList: [
              MapEntry(t.wallet_type, t.taproot.child_creation_screen.step4.taproot_single_sig_wallet),
              MapEntry(t.mfp, viewModel.masterFingerprint ?? '00000000'),
            ],
          ),
        ],
      ),
    );
  }
}

class ChildExistingVaultSelectionBody extends StatelessWidget {
  const ChildExistingVaultSelectionBody({super.key, required this.viewModel, required this.isProcessing});

  static const double _gradientHeight = 36.0;

  final ChildCreationViewModel viewModel;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletProvider>(
      builder: (context, walletProvider, child) {
        final vaultList = walletProvider.getVaultsByWalletType(WalletType.singleSignature);

        return Stack(
          children: [
            ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(top: _gradientHeight, bottom: _gradientHeight),
              itemCount: vaultList.length,
              separatorBuilder: (context, index) => CoconutLayout.spacing_300h,
              itemBuilder: (context, index) {
                final vault = vaultList[index];

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      VaultRowItem(
                        vault: vault,
                        onSelected: () {
                          if (isProcessing) return;
                          viewModel.setExistingVaultId(vault.id);
                        },
                        isNextIconVisible: false,
                        isKeyBorderVisible: true,
                        isSelectable: !isProcessing,
                        isSelected: viewModel.existingVaultId == vault.id,
                      ),
                      if (index == vaultList.length - 1) CoconutLayout.spacing_2000h,
                    ],
                  ),
                );
              },
            ),
            const _VaultListGradientOverlay(alignment: Alignment.topCenter),
            const _VaultListGradientOverlay(alignment: Alignment.bottomCenter),
          ],
        );
      },
    );
  }
}

class _VaultListGradientOverlay extends StatelessWidget {
  const _VaultListGradientOverlay({required this.alignment});

  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final isTop = alignment == Alignment.topCenter;
    return Positioned(
      left: 0,
      top: isTop ? 0 : null,
      right: 0,
      bottom: isTop ? null : 0,
      height: ChildExistingVaultSelectionBody._gradientHeight,
      child: IgnorePointer(
        ignoring: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: alignment,
              end: isTop ? Alignment.bottomCenter : Alignment.topCenter,
              colors: const [
                CoconutColors.white,
                CoconutColors.white,
                Color(0xE6FFFFFF),
                Color(0x99FFFFFF),
                Color(0x33FFFFFF),
              ],
              stops: const [0.0, 0.16, 0.36, 0.62, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}
