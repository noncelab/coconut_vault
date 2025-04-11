import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/multisig/multisig_vault_list_item.dart';
import 'package:coconut_vault/model/single_sig/single_sig_vault_list_item.dart';
import 'package:coconut_vault/providers/view_model/vault_list_restoration_view_model.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/utils/icon_util.dart';
import 'package:coconut_vault/widgets/button/fixed_bottom_button.dart';
import 'package:coconut_vault/widgets/indicator/percent_progress_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

class VaultListRestorationScreen extends StatefulWidget {
  const VaultListRestorationScreen({super.key});

  @override
  State<VaultListRestorationScreen> createState() =>
      _VaultListRestorationScreenState();
}

class _VaultListRestorationScreenState extends State<VaultListRestorationScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  void _startProgress(VaultListRestorationViewModel viewModel) {
    if (_progressController.isAnimating) {
      _progressController.stop();
      return;
    }

    // 복원 프로세스 시작
    viewModel.restoreVaultList();

    _progressController.addListener(() {
      setState(() {});
      if (_progressController.value == 1) {
        // 내부적으로 복원 프로세스가 완료되고, _progressController도 100% 진행 되고 나면 다음 화면으로 전환
        Future.delayed(const Duration(milliseconds: 3000), () {
          viewModel.setIsVaultListRestored(true);
        });
      }
    });

    viewModel.addListener(() {
      final progress = viewModel.restoreProgress;
      debugPrint('viewModel.restoreProgress: $progress');

      if (progress == 5 ||
          progress == 50 ||
          progress == 90 ||
          progress == 100) {
        const duration = Duration(
          milliseconds: 2000,
        );

        _progressController.animateTo(
          progress / 100,
          duration: duration,
        );
      }
    });
  }

  Widget _buildWalletListItem(
      String walletName, int iconIndex, int colorIndex, String rightText) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CoconutColors.white,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.18),
            spreadRadius: 4,
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          CoconutIcon(
            size: 44,
            backgroundColor: BackgroundColorPalette[colorIndex],
            child: SvgPicture.asset(
              CustomIcons.getPathByIndex(0),
              colorFilter:
                  ColorFilter.mode(ColorPalette[iconIndex], BlendMode.srcIn),
            ),
          ),
          CoconutLayout.spacing_100w,
          Text(walletName, style: CoconutTypography.body1_16),
          const Spacer(),
          Text(rightText, style: CoconutTypography.body2_14_Number)
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: ChangeNotifierProvider<VaultListRestorationViewModel>(
        create: (_) => VaultListRestorationViewModel(
          Provider.of<WalletProvider>(context, listen: false),
        ),
        child: Consumer<VaultListRestorationViewModel>(
            builder: (context, viewModel, child) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!viewModel.isVaultListRestored &&
                !viewModel.isRestoreProcessing) {
              // 중복 실행 방지
              _startProgress(viewModel);
            }
          });

          return Scaffold(
            backgroundColor: CoconutColors.white,
            body: SafeArea(
              child: Stack(
                children: [
                  Column(
                    children: [
                      CoconutLayout.spacing_2500h,
                      Text(
                        viewModel.isVaultListRestored
                            ? t.vault_list_restoration.completed_title
                            : t.vault_list_restoration.in_progress_title,
                        style: CoconutTypography.heading4_18_Bold,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          viewModel.isVaultListRestored
                              ? t.vault_list_restoration.completed_description(
                                  count: viewModel.vaultList.length)
                              : t.vault_list_restoration
                                  .in_progress_description,
                          style: CoconutTypography.body2_14_Bold,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        child: AnimatedOpacity(
                          opacity: viewModel.isVaultListRestored ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 500),
                          child: ListView.builder(
                            itemCount: viewModel.vaultList.length,
                            itemBuilder: (context, index) {
                              var vaultItem = viewModel.vaultList[index];
                              late int colorIndex;
                              late int iconIndex;
                              late String rightText;

                              if (vaultItem is SingleSigVaultListItem) {
                                SingleSigVaultListItem singleVault = vaultItem;
                                final singlesigVault = singleVault.coconutVault
                                    as SingleSignatureVault;
                                colorIndex = singleVault.colorIndex;
                                iconIndex = singleVault.iconIndex;
                                rightText = singlesigVault
                                    .keyStore.masterFingerprint; // mfp
                              } else {
                                MultisigVaultListItem multiVault =
                                    vaultItem as MultisigVaultListItem;
                                colorIndex = multiVault.colorIndex;
                                iconIndex = multiVault.iconIndex;

                                rightText =
                                    '${multiVault.requiredSignatureCount} / ${multiVault.signers.length}'; // m-of-n
                              }

                              return Padding(
                                padding: EdgeInsets.only(
                                    top: index == 0 ? Sizes.size8 : 0,
                                    bottom:
                                        index == viewModel.vaultList.length - 1
                                            ? 190
                                            : Sizes.size8,
                                    left: CoconutLayout.defaultPadding,
                                    right: CoconutLayout.defaultPadding),
                                child: _buildWalletListItem(vaultItem.name,
                                    iconIndex, colorIndex, rightText),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!viewModel.isVaultListRestored)
                    Center(
                      child: PercentProgressIndicator(
                        progressController: _progressController,
                        textColor: const Color(0xFF1E88E5),
                      ),
                    ),
                  if (viewModel.isVaultListRestored) ...{
                    FixedBottomButton(
                      onButtonClicked: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/',
                          (Route<dynamic> route) => false,
                        );
                      },
                      text: t.vault_list_restoration.start_vault,
                      textColor: CoconutColors.white,
                      showGradient: true,
                      gradientPadding: const EdgeInsets.only(
                          left: 16, right: 16, bottom: 40, top: 110),
                      isActive: true,
                      backgroundColor: CoconutColors.black,
                    )
                  },
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
