import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/widgets/button/shrink_animation_button.dart';
import 'package:coconut_vault/widgets/card/taproot/taproot_participant_card.dart';
import 'package:coconut_vault/widgets/card/taproot/taproot_setup_summary_card.dart';
import 'package:coconut_vault/widgets/indicator/message_activity_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

class VaultTypeSelectionScreen extends StatefulWidget {
  const VaultTypeSelectionScreen({super.key});

  @override
  State<VaultTypeSelectionScreen> createState() => _VaultTypeSelectionScreenState();
}

class _VaultTypeSelectionScreenState extends State<VaultTypeSelectionScreen> {
  String? nextPath;
  bool _showLoading = false;
  List<String> routesOptions = [
    AppRoutes.vaultCreationOptions,
    AppRoutes.multisigCreationOptions,
    AppRoutes.taprootCreationOptions,
  ];
  late final WalletProvider _walletProvider;

  @override
  void initState() {
    super.initState();
    _walletProvider = Provider.of<WalletProvider>(context, listen: false);
    _walletProvider.isVaultListLoadingNotifier.addListener(_loadingListener);
  }

  @override
  void dispose() {
    _walletProvider.isVaultListLoadingNotifier.removeListener(_loadingListener);
    super.dispose();
  }

  void _loadingListener() {
    if (!mounted) return;

    if (!_walletProvider.isVaultListLoadingNotifier.value) {
      if (_showLoading && nextPath != null) {
        setState(() {
          _showLoading = false;
        });

        Navigator.pushNamed(context, nextPath!);
      }
    }
  }

  void onTapSinglesigWallet() {
    Navigator.pushNamed(context, routesOptions[0]);
  }

  void onTapMultisigWallet() {
    Navigator.pushNamed(context, routesOptions[1]);
  }

  void onTapTaprootWallet() {
    Navigator.pushNamed(context, routesOptions[2]);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletProvider>(
      builder: (context, model, child) {
        return Scaffold(
          backgroundColor: CoconutColors.white,
          appBar: CoconutAppBar.build(title: t.select_vault_type_screen.title, context: context),
          body: SafeArea(
            minimum: const EdgeInsets.only(top: 10, right: 16, left: 16),
            child: Stack(
              children: [
                Column(
                  children: [
                    _buildOption(
                      t.single_sig_wallet,
                      t.select_vault_type_screen.single_sig,
                      onTapSinglesigWallet,
                      true,
                    ),
                    CoconutLayout.spacing_300h,
                    _buildOption(t.multisig_wallet, t.select_vault_type_screen.multisig, onTapMultisigWallet, true),
                    CoconutLayout.spacing_300h,
                    _buildOption(
                      t.taproot.parent_creation_screen.taproot_inheritance_wallet,
                      t.select_vault_type_screen.taproot,
                      onTapTaprootWallet,
                      true,
                    ),
                    CoconutLayout.spacing_300h,
                    _buildOption(
                      '테스트 화면',
                      'participant card Taproot 관련 위젯 테스트용 화면입니다.',
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => const TaprootSetupSummaryCard(
                                taprootSetupSummaryCardType: TaprootSetupSummaryCardType.column,
                                itemList: [
                                  TaprootParticipantCard(
                                    role: TaprootParticipantRole.parent,
                                    isMine: true,
                                    walletName: 'Test Wallet1',
                                    mfp: '12345678',
                                    derivationPath: "m/86'/0'/0'",
                                    locktime: 12345678,
                                    onTap: null,
                                  ),
                                  TaprootParticipantCard(
                                    role: TaprootParticipantRole.parent,
                                    isMine: false,
                                    walletName: 'Test Wallet2',
                                    mfp: '87654321',
                                    derivationPath: "m/86'/0'/1'",
                                    locktime: 87654321,
                                    onTap: null,
                                  ),
                                  TaprootParticipantCard(
                                    role: TaprootParticipantRole.child,
                                    isMine: true,
                                    walletName: 'Test Wallet3',
                                    mfp: '11111111',
                                    derivationPath: "m/86'/0'/2'",
                                    onTap: null,
                                  ),
                                  TaprootParticipantCard(
                                    role: TaprootParticipantRole.child,
                                    isMine: false,
                                    walletName: 'Test Wallet4',
                                    mfp: '22222222',
                                    derivationPath: "m/86'/0'/3'",
                                    locktime: 22222222,
                                    onTap: null,
                                  ),
                                  TaprootParticipantCard(
                                    role: TaprootParticipantRole.parent,
                                    isMine: false,
                                    hasSingleParent: true,
                                    walletName: 'Test Wallet5',
                                    mfp: '33333333',
                                    derivationPath: "m/86'/0'/4'",
                                  ),
                                  TaprootParticipantCard(
                                    role: TaprootParticipantRole.child,
                                    isMine: false,
                                    hasSingleParent: true,
                                    walletName: 'Test Wallet6',
                                    mfp: '44444444',
                                    derivationPath: "m/86'/0'/5'",
                                  ),
                                  TaprootParticipantCard(
                                    role: TaprootParticipantRole.parent,
                                    isMine: true,
                                    isValid: false,
                                    walletName: 'Test Wallet7',
                                    mfp: '55555555',
                                    derivationPath: "m/86'/0'/6'",
                                  ),
                                  TaprootParticipantCard(
                                    role: TaprootParticipantRole.child,
                                    isMine: false,
                                    isValid: false,
                                    walletName: 'Test Wallet8',
                                    mfp: '66666666',
                                    derivationPath: "m/86'/0'/7'",
                                  ),
                                  TaprootParticipantCard(
                                    role: TaprootParticipantRole.parent,
                                    isMine: true,
                                    hasSingleParent: true,
                                    isValid: false,
                                    walletName: 'Test Wallet9',
                                    mfp: '77777777',
                                    derivationPath: "m/86'/0'/8'",
                                  ),
                                  TaprootParticipantCard(
                                    role: TaprootParticipantRole.child,
                                    isMine: false,
                                    hasSingleParent: true,
                                    isValid: false,
                                    walletName: 'Test Wallet10',
                                    mfp: '88888888',
                                    derivationPath: "m/86'/0'/9'",
                                  ),
                                ],
                              ),
                        ),
                      ),
                      true,
                    ),
                    CoconutLayout.spacing_300h,
                  ],
                ),
                Visibility(
                  visible: _showLoading,
                  child: Container(
                    decoration: BoxDecoration(color: CoconutColors.black.withValues(alpha: 0.3)),
                    child: Center(child: MessageActivityIndicator(message: t.select_vault_type_screen.loading_keys)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOption(String title, String description, VoidCallback onPressed, bool isSelectable) {
    print('isSelectable: $isSelectable');
    return ShrinkAnimationButton(
      defaultColor: CoconutColors.gray150,
      pressedColor: CoconutColors.gray500.withValues(alpha: 0.1),
      onPressed: isSelectable ? onPressed : () {},
      isActive: isSelectable,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
        child: Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: CoconutTypography.body1_16_Bold.copyWith(
                        color: isSelectable ? CoconutColors.black : CoconutColors.gray400,
                        letterSpacing: 0.2,
                      ),
                    ),
                    CoconutLayout.spacing_100h,
                    Flexible(
                      child: Text(
                        overflow: TextOverflow.visible,
                        maxLines: 2,
                        description,
                        style: CoconutTypography.body2_14.copyWith(
                          color: isSelectable ? CoconutColors.gray700 : CoconutColors.gray400,
                          letterSpacing: 0.2,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(width: 10),
            SvgPicture.asset(
              'assets/svg/chevron-right.svg',
              colorFilter: ColorFilter.mode(
                isSelectable ? CoconutColors.black : CoconutColors.gray400,
                BlendMode.srcIn,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
