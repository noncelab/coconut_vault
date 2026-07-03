import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/constants/app_language.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/view_model/vault_creation/taproot/parent_creation_view_model.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/screens/common/menu_grid.dart';
import 'package:coconut_vault/utils/date_format_util.dart';
import 'package:coconut_vault/widgets/adaptive_qr_image.dart';
import 'package:coconut_vault/widgets/button/assignable_pill_button.dart';
import 'package:coconut_vault/widgets/button/shrink_animation_button.dart';
import 'package:coconut_vault/widgets/card/selectable_option_card.dart';
import 'package:coconut_vault/widgets/text/character_fade_in_text.dart';
import 'package:coconut_vault/widgets/vault_row_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

class ParentNewKeyCreationOptionMenu extends StatelessWidget {
  const ParentNewKeyCreationOptionMenu({super.key, required this.selectedType, required this.onSelected});

  final ParentNewKeyCreationType Function(ParentCreationViewModel viewModel) selectedType;
  final void Function(ParentCreationViewModel viewModel, ParentNewKeyCreationType type) onSelected;

  @override
  Widget build(BuildContext context) {
    return Consumer<ParentCreationViewModel>(
      builder: (context, viewModel, child) {
        final selectedNewKeyCreationType = selectedType(viewModel);
        return MenuGrid(
          children: [
            SelectableOptionCard(
              title: t.taproot.common.new_option1,
              bottomAssetPath: 'assets/png/coin.png',
              imageScale: 4.0,
              imageWidth: 67,
              isSelected: selectedNewKeyCreationType == ParentNewKeyCreationType.coinFlip,
              height: 118,
              onTap: () => onSelected(viewModel, ParentNewKeyCreationType.coinFlip),
            ),
            SelectableOptionCard(
              title: t.taproot.common.new_option2,
              bottomAssetPath: 'assets/png/dice.png',
              imageScale: 4.0,
              imageWidth: 67,
              isSelected: selectedNewKeyCreationType == ParentNewKeyCreationType.diceRoll,
              height: 118,
              onTap: () => onSelected(viewModel, ParentNewKeyCreationType.diceRoll),
            ),
            SelectableOptionCard(
              title: t.taproot.common.new_option3,
              bottomAssetPath: 'assets/png/gear.png',
              imageScale: 4.0,
              imageWidth: 67,
              isSelected: selectedNewKeyCreationType == ParentNewKeyCreationType.autoGenerate,
              height: 118,
              onTap: () => onSelected(viewModel, ParentNewKeyCreationType.autoGenerate),
            ),
          ],
        );
      },
    );
  }
}

class ParentExistingVaultSelectionBody extends StatelessWidget {
  const ParentExistingVaultSelectionBody({super.key, required this.selectedVaultId, required this.onSelected});

  static const double _gradientHeight = 36.0;
  final int? Function(ParentCreationViewModel viewModel) selectedVaultId;
  final void Function(ParentCreationViewModel viewModel, int vaultId) onSelected;

  @override
  Widget build(BuildContext context) {
    return Consumer2<WalletProvider, ParentCreationViewModel>(
      builder: (context, walletProvider, viewModel, child) {
        final vaultList = walletProvider.getVaultsByWalletType(WalletType.singleSignature);
        final selectedId = selectedVaultId(viewModel);

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
                        onSelected: () => onSelected(viewModel, vault.id),
                        isNextIconVisible: false,
                        isKeyBorderVisible: true,
                        isSelectable: true,
                        isSelected: selectedId == vault.id,
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
      height: ParentExistingVaultSelectionBody._gradientHeight,
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

class ParentMultisigParentList extends StatelessWidget {
  const ParentMultisigParentList({
    super.key,
    required this.activeColor,
    required this.onCurrentWalletPressed,
    required this.onExternalWalletPressed,
  });

  final Color activeColor;
  final VoidCallback onCurrentWalletPressed;
  final VoidCallback onExternalWalletPressed;

  @override
  Widget build(BuildContext context) {
    return Consumer<ParentCreationViewModel>(
      builder: (context, viewModel, child) {
        final masterFingerprint = viewModel.parentMasterFingerprint;
        final externalParentMasterFingerprint = viewModel.externalParentMasterFingerprint;
        return Column(
          children: [
            AssignablePillButton(
              text: _parentWalletText(index: 1, masterFingerprint: masterFingerprint),
              isAssigned: true,
              activeColor: activeColor,
              width: double.infinity,
              height: 64,
              iconWidget: _CurrentWalletBadge(activeColor: activeColor),
              onPressed: onCurrentWalletPressed,
            ),
            CoconutLayout.spacing_500h,
            AssignablePillButton(
              text: _parentWalletText(index: 2, masterFingerprint: externalParentMasterFingerprint),
              isAssigned: externalParentMasterFingerprint != null,
              activeColor: activeColor,
              width: double.infinity,
              height: 64,
              onPressed: onExternalWalletPressed,
            ),
          ],
        );
      },
    );
  }

  String _parentWalletText({required int index, String? masterFingerprint}) {
    final masterFingerprintSuffix =
        masterFingerprint == null || masterFingerprint.isEmpty ? '' : ' - $masterFingerprint';
    return t.taproot.parent_creation_screen.step_1.parent_wallet(
      index: index,
      masterFingerprintSuffix: masterFingerprintSuffix,
    );
  }
}

class _CurrentWalletBadge extends StatelessWidget {
  const _CurrentWalletBadge({required this.activeColor});

  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(color: activeColor, borderRadius: BorderRadius.circular(8)),
      alignment: Alignment.center,
      child: Text(t.taproot.participant_card.me, style: CoconutTypography.body3_12.setColor(CoconutColors.white)),
    );
  }
}

class ParentMultisigParentExportQr extends StatelessWidget {
  const ParentMultisigParentExportQr({super.key, this.qrData});

  final String? qrData;

  @override
  Widget build(BuildContext context) {
    final providedQrData = qrData;
    if (providedQrData != null) {
      return _buildQrImage(providedQrData);
    }

    return Consumer<ParentCreationViewModel>(
      builder: (context, viewModel, child) {
        return _buildQrImage(viewModel.parentWalletQrData);
      },
    );
  }

  Widget _buildQrImage(String? qrData) {
    if (qrData == null || qrData.isEmpty) {
      return const SizedBox.shrink();
    }
    return AdaptiveQrImage(qrData: qrData);
  }
}

class ParentWalletSyncQr extends StatelessWidget {
  const ParentWalletSyncQr({super.key, required this.qrData});

  final String qrData;

  @override
  Widget build(BuildContext context) {
    final complete = t.taproot.parent_creation_screen.step_4.complete;
    final descriptionLines = complete.description.split('\n');
    return Column(
      children: [
        for (int index = 0; index < descriptionLines.length; index++)
          MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
            child: CharacterFadeInText(
              text: descriptionLines[index],
              animationKey: 'taproot-parent-creation-body-export-qr-description-$index',
              duration: index == 0 ? const Duration(milliseconds: 400) : const Duration(milliseconds: 700),
              delay: index == 0 ? const Duration(milliseconds: 800) : const Duration(milliseconds: 1500),
            ),
          ),
        CoconutLayout.spacing_600h,
        AdaptiveQrImage(qrData: qrData),
      ],
    );
  }
}

class ParentTimelockSetupBody extends StatelessWidget {
  const ParentTimelockSetupBody({
    super.key,
    required this.selectedDateTime,
    required this.onDatePressed,
    required this.language,
  });

  final DateTime? selectedDateTime;
  final VoidCallback onDatePressed;

  final AppLanguage language;

  static List<TextSpan> titleList() {
    return [
      TextSpan(text: t.taproot.parent_creation_screen.step_3.set_timelock_title_1),
      TextSpan(text: t.taproot.parent_creation_screen.step_3.set_timelock_title_2),
    ];
  }

  String dateTimeText(DateTime? selectedDateTime) {
    if (selectedDateTime == null) {
      return t.bottom_sheet.date_picker.placeholder;
    }

    return DateFormatUtil.formatLocalizedDateTime(selectedDateTime, language);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
          child: CharacterFadeInText(
            text: t.taproot.parent_creation_screen.step_3.set_timelock_description_1,
            animationKey: 'taproot-parent-creation-body-timelock-description-1',
            duration: const Duration(milliseconds: 400),
            delay: const Duration(milliseconds: 1700),
          ),
        ),
        MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
          child: CharacterFadeInText(
            text: t.taproot.parent_creation_screen.step_3.set_timelock_description_2,
            animationKey: 'taproot-parent-creation-body-timelock-description-2',
            duration: const Duration(milliseconds: 700),
            delay: const Duration(milliseconds: 2400),
          ),
        ),
        CoconutLayout.spacing_600h,
        ParentTimelockDateButton(
          selectedDateTime: selectedDateTime,
          text: dateTimeText(selectedDateTime),
          onPressed: onDatePressed,
        ),
      ],
    );
  }
}

class ParentTimelockDateButton extends StatelessWidget {
  const ParentTimelockDateButton({
    super.key,
    required this.selectedDateTime,
    required this.text,
    required this.onPressed,
  });

  final DateTime? selectedDateTime;
  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final hasSelectedDateTime = selectedDateTime != null;
    return ShrinkAnimationButton(
      onPressed: onPressed,
      border: Border.all(width: 1, color: CoconutColors.black.withValues(alpha: 0.15)),
      borderRadius: 12,
      defaultColor: hasSelectedDateTime ? CoconutColors.black.withValues(alpha: 0.15) : CoconutColors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            SvgPicture.asset('assets/svg/calendar-days.svg'),
            CoconutLayout.spacing_300w,
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Center(
                  child: Text(
                    text,
                    style:
                        hasSelectedDateTime
                            ? CoconutTypography.body2_14_Number.setColor(CoconutColors.black)
                            : CoconutTypography.body2_14.setColor(CoconutColors.gray400),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
