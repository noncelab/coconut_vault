import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/taproot/taproot_vault_list_item.dart';
import 'package:coconut_vault/providers/view_model/wallet_info/wallet_info_view_model.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/widgets/button/button_group.dart';
import 'package:coconut_vault/widgets/button/single_button.dart';
import 'package:coconut_vault/widgets/card/taproot/taproot_participant_card.dart';
import 'package:coconut_vault/widgets/card/taproot/taproot_setup_summary_card.dart';
import 'package:coconut_vault/widgets/card/taproot/taproot_vault_item_card.dart';
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
  @override
  Widget build(BuildContext context) {
    final walletProvider = context.watch<WalletProvider>();
    final vault = walletProvider.getVaultById(widget.id) as TaprootVaultListItem;

    final List<TaprootParticipantCard> participantCards = [
      // 상위 지갑 참여자 (Key Path)
      ...vault.owners.map(
        (owner) => TaprootParticipantCard(
          role: TaprootParticipantRole.parent,
          mfp: owner.masterFingerprint,
          derivationPath: vault.derivationPath,
          walletName: owner.isSeedStored ? vault.name : null,
          isMine: owner.isSeedStored,
        ),
      ),
      // 하위 지갑 참여자 (Script Path / 상속 조건)
      ...vault.beneficiaries.map(
        (beneficiary) => TaprootParticipantCard(
          role: TaprootParticipantRole.child,
          mfp: beneficiary.masterFingerprint,
          derivationPath: vault.derivationPath,
          walletName: beneficiary.isSeedStored ? vault.name : null,
          locktime: beneficiary.lockTime,
          isMine: beneficiary.isSeedStored,
        ),
      ),
    ];

    final bool hasPassphrase =
        vault.owners.any((o) => o.isSeedStored && o.isPassphraseSet) ||
        vault.beneficiaries.any((b) => b.isSeedStored && b.isPassphraseSet);

    return ChangeNotifierProvider(
      create:
          (context) =>
              WalletInfoViewModel(Provider.of<WalletProvider>(context, listen: false), widget.id, isMultisig: false),
      child: Consumer<WalletInfoViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            backgroundColor: CoconutColors.white,
            appBar: CoconutAppBar.build(
              context: context,
              title: vault.name,
              actionButtonList: [
                IconButton(
                  onPressed: () {
                    // TODO: 삭제 팝업 로직 구현 (필요 시 WalletInfoLayout의 _showDeleteDialog 로직 이식)
                  },
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
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TaprootVaultItemCard(vaultItem: vault, showTaprootWalletInfo: true),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
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
                            title: t.vault_menu_screen.view_xpub,
                            onPressed:
                                () => Navigator.pushNamed(context, AppRoutes.viewXpub, arguments: {'id': widget.id}),
                          ),
                          SingleButton(
                            title: t.view_mnemonic,
                            onPressed:
                                () =>
                                    Navigator.pushNamed(context, AppRoutes.mnemonicView, arguments: {'id': widget.id}),
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
