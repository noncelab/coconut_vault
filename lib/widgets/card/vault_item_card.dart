import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/model/multisig/multisig_vault_list_item.dart';
import 'package:coconut_vault/model/single_sig/single_sig_vault_list_item.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/screens/wallet_info/account_number_settings_bottom_sheet.dart';
import 'package:coconut_vault/screens/wallet_info/passphrase_check_bottom_sheet.dart';
import 'package:coconut_vault/utils/colors_util.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/widgets/button/tooltip_button.dart';
import 'package:coconut_vault/widgets/icon/vault_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import 'dart:math' as math;

import 'package:provider/provider.dart';

class VaultItemCard extends StatefulWidget {
  final VaultListItemBase vaultItem;
  final VoidCallback onTooltipClicked;
  final VoidCallback onNameChangeClicked;
  final GlobalKey tooltipKey;

  const VaultItemCard({
    super.key,
    required this.vaultItem,
    required this.onTooltipClicked,
    required this.onNameChangeClicked,
    required this.tooltipKey,
  });

  @override
  State<VaultItemCard> createState() => _VaultItemCardState();
}

class _VaultItemCardState extends State<VaultItemCard> {
  bool _isItemTapped = false;
  bool _isDerivationPathTapped = false;
  bool get _isMultisig => widget.vaultItem is MultisigVaultListItem;

  @override
  Widget build(BuildContext context) {
    List<MultisigSigner>? signers;
    String rightText = '';

    switch (widget.vaultItem) {
      case MultisigVaultListItem multiVault:
        signers = multiVault.signers;
        rightText = '${multiVault.requiredSignatureCount}/${multiVault.signers.length}';
      case SingleSigVaultListItem singleVault:
        rightText = (singleVault.coconutVault as SingleSignatureVault).keyStore.masterFingerprint;
      default:
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: _isMultisig ? null : Border.all(color: CoconutColors.borderLightGray, width: 1),
        gradient:
            _isMultisig
                ? LinearGradient(
                  colors: CustomColorHelper.getGradientColors(signers!),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  transform: const GradientRotation(math.pi / 10),
                )
                : null,
      ),
      child: Container(
        margin: _isMultisig ? const EdgeInsets.all(2) : null,
        padding: const EdgeInsets.all(20),
        decoration:
            _isMultisig ? BoxDecoration(color: CoconutColors.white, borderRadius: BorderRadius.circular(12)) : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: GestureDetector(
                onTapDown: (_) => setState(() => _isItemTapped = true),
                onTapCancel: () => setState(() => _isItemTapped = false),
                onTap: () {
                  widget.onNameChangeClicked();
                  setState(() => _isItemTapped = false);
                },
                child: Row(
                  children: [
                    _buildIcon(),
                    CoconutLayout.spacing_200w,
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                            child: Text(
                              widget.vaultItem.name,
                              style: CoconutTypography.body1_16_Bold,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            CoconutLayout.spacing_200w,
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [_buildMfpContent(rightText), _buildBottomRightContent()],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMfpContent(String rightText) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 120),
          child:
              _isMultisig
                  ? FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      rightText.replaceAllMapped(RegExp(r'[a-z]+'), (match) => match.group(0)!.toUpperCase()),
                      style: CoconutTypography.heading4_18_NumberBold,
                    ),
                  )
                  : TooltipButton(
                    isSelected: false,
                    text: rightText,
                    isLeft: true,
                    iconkey: widget.tooltipKey,
                    containerMargin: EdgeInsets.zero,
                    onTapDown: (_) => widget.onTooltipClicked(),
                    textStyle: CoconutTypography.heading4_18_NumberBold,
                    iconColor: CoconutColors.black,
                    iconSize: 18,
                    isIconBold: true,
                  ),
        );
      },
    );
  }

  Widget _buildBottomRightContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 120),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child:
                _isMultisig
                    ? Text(
                      DateFormat('yy.MM.dd HH:mm').format(widget.vaultItem.createdAt),
                      style: CoconutTypography.body2_14.setColor(CoconutColors.gray700),
                    )
                    : _buildDerivationPathContent(),
          ),
        );
      },
    );
  }

  Widget _buildDerivationPathContent() {
    final isAccountEditEnabled = context.watch<VisibilityProvider>().isAccountEditEnabled;

    return Selector<WalletProvider, ({String derivationPath, int currentAccount})>(
      selector: (context, provider) {
        // 지갑 삭제 시 notifyListeners()가 호출되면 부모 위젯이 이 카드를 트리에서
        // 제거하기 전에 selector가 먼저 실행될 수 있음. getVaultById() 대신
        // getVaultByIdOrNull()을 사용해 해당 타이밍에 null을 반환하도록 처리.
        final vault = provider.getVaultByIdOrNull(widget.vaultItem.id) as SingleSigVaultListItem?;
        if (vault == null) {
          final fallback = widget.vaultItem as SingleSigVaultListItem;
          return (derivationPath: fallback.derivationPath, currentAccount: fallback.currentAccountIndex);
        }
        return (derivationPath: vault.derivationPath, currentAccount: vault.currentAccountIndex);
      },
      builder: (context, data, child) {
        final textColor = _isDerivationPathTapped ? CoconutColors.gray500 : CoconutColors.gray700;
        final iconColor = _isDerivationPathTapped ? CoconutColors.gray500 : CoconutColors.gray700;

        return GestureDetector(
          onTapDown: isAccountEditEnabled ? (_) => setState(() => _isDerivationPathTapped = true) : null,
          onTapCancel: isAccountEditEnabled ? () => setState(() => _isDerivationPathTapped = false) : null,
          onTapUp: isAccountEditEnabled ? (_) => setState(() => _isDerivationPathTapped = false) : null,
          onTap: isAccountEditEnabled ? () => _handleAccountEditTap(data.currentAccount) : null,
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(data.derivationPath, style: CoconutTypography.body2_14_Bold.setColor(textColor)),
              if (isAccountEditEnabled) ...[
                const SizedBox(width: 4),
                SvgPicture.asset(
                  'assets/svg/edit-outlined.svg',
                  width: 14,
                  colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildIcon() {
    final int colorIndex = widget.vaultItem.colorIndex;
    final int iconIndex = widget.vaultItem.iconIndex;

    final icon = Container(
      decoration: const BoxDecoration(color: CoconutColors.white, borderRadius: BorderRadius.all(Radius.circular(12))),
      child: VaultIcon(iconIndex: iconIndex, colorIndex: colorIndex),
    );

    return VaultIconEditBadge(isTapped: _isItemTapped, child: icon);
  }

  Future<void> _handleAccountEditTap(int currentAccount) async {
    final walletProvider = context.read<WalletProvider>();
    bool hasPassphrase = false;

    if (!walletProvider.isSigningOnlyMode) {
      hasPassphrase = await walletProvider.hasPassphrase(widget.vaultItem.id);
    }

    if (!mounted) return;

    if (hasPassphrase) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder:
            (context) => PassphraseVerificationBottomSheet(
              vaultId: widget.vaultItem.id,
              onVerificationSuccess: (passphrase) {
                Navigator.pop(context);
                _showAccountEditSheet(currentAccount, passphrase: passphrase);
              },
            ),
      );
    } else {
      _showAccountEditSheet(currentAccount);
    }
  }

  void _showAccountEditSheet(int currentAccount, {Uint8List? passphrase}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => AccountEditBottomSheet(
            account: currentAccount,
            onUpdate: (account) async {
              await context.read<WalletProvider>().updateSingleSigAccount(
                widget.vaultItem.id,
                account,
                passphrase: passphrase,
              );
            },
          ),
    );
  }
}
