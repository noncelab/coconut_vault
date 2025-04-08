import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/view_model/vault_list_restoration_view_model.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/utils/icon_util.dart';
import 'package:coconut_vault/widgets/indicator/gradient_progress_indicator.dart';
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
  late VaultListRestorationViewModel _viewModel;
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(vsync: this);
    _viewModel = VaultListRestorationViewModel();
    _viewModel.restoreVaultList();
    _startProgress();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  void _startProgress() {
    if (_progressController.isAnimating) {
      _progressController.stop();
      return;
    }

    // 실제 복구 처리 연동
    _progressController.duration = const Duration(seconds: 3);
    _progressController.forward();
    _progressController.addListener(() {
      setState(() {});
    });
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {}
    });
  }

  Widget _buildWalletListItem() {
    return Container(
      width: double.infinity,
      height: 70,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
          Container(
              width: 22,
              height: 22,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: BackgroundColorPalette[0],
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: SvgPicture.asset(
                CustomIcons.getPathByIndex(0),
                colorFilter: ColorFilter.mode(ColorPalette[0], BlendMode.srcIn),
              )),
          const SizedBox(width: 4),
          const Text('일반 지갑', style: CoconutTypography.body2_14),
          const Spacer(),
          Text('0000000', style: CoconutTypography.body3_12_Number)
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        child: ChangeNotifierProvider<VaultListRestorationViewModel>(
            create: (_) => _viewModel,
            child: Consumer<VaultListRestorationViewModel>(
                builder: (context, viewModel, child) => Scaffold(
                      backgroundColor: CoconutColors.white,
                      body: Container(
                        width: MediaQuery.sizeOf(context).width,
                        padding: const EdgeInsets.symmetric(
                          horizontal: CoconutLayout.defaultPadding,
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Column(
                                children: [
                                  const SizedBox(height: kToolbarHeight + 100),
                                  Text(
                                    _viewModel.isVaultListRestored
                                        ? t.vault_list_restoration
                                            .completed_title
                                        : t.vault_list_restoration
                                            .in_progress_title,
                                    style: CoconutTypography.heading4_18_Bold,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 20),
                                    child: Text(
                                      _viewModel.isVaultListRestored
                                          ? t.vault_list_restoration
                                              .completed_description(
                                                  count:
                                                      _viewModel.vaultListCount)
                                          : t.vault_list_restoration
                                              .in_progress_description,
                                      style: CoconutTypography.body2_14_Bold,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  AnimatedOpacity(
                                    opacity: _viewModel.isVaultListRestored
                                        ? 1.0
                                        : 0.0,
                                    duration: const Duration(milliseconds: 500),
                                    child: SingleChildScrollView(
                                      child: Column(
                                        children: [
                                          _buildWalletListItem(),
                                          const SizedBox(height: 16),
                                          _buildWalletListItem(),
                                          const SizedBox(height: 16),
                                          _buildWalletListItem(),
                                        ],
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                            if (!_viewModel.isVaultListRestored)
                              Center(
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    GradientCircularProgressIndicator(
                                      radius: 90,
                                      gradientColors: const [
                                        Colors.white,
                                        Color.fromARGB(255, 164, 214, 250),
                                      ],
                                      strokeWidth: 36.0,
                                      progress: _progressController.value > 0
                                          ? _progressController.value
                                          : 0.01,
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          (_progressController.value * 100)
                                              .toStringAsFixed(0),
                                          style: CoconutTypography
                                              .heading1_32_Bold
                                              .setColor(const Color(0xFF1E88E5))
                                              .merge(const TextStyle(
                                                  fontWeight: FontWeight.w900)),
                                        ),
                                        CoconutLayout.spacing_100w,
                                        Text(
                                          '%',
                                          style: CoconutTypography.body1_16_Bold
                                              .setColor(
                                                  const Color(0xFF42A5F5)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            if (_viewModel.isVaultListRestored)
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 40,
                                child: CoconutButton(
                                  disabledBackgroundColor:
                                      CoconutColors.gray400,
                                  width: double.infinity,
                                  text: t.vault_list_restoration.start_vault,
                                  onPressed: () {
                                    Navigator.pushNamedAndRemoveUntil(
                                      context,
                                      '/',
                                      (Route<dynamic> route) => false,
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ))));
  }
}
