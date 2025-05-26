import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/view_model/mutlisig_quorum_selection_view_model.dart';
import 'package:coconut_vault/providers/wallet_creation_provider.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/animation/key_safe_animation_widget.dart';
import 'package:coconut_vault/widgets/appbar/custom_appbar.dart';
import 'package:coconut_vault/widgets/button/custom_buttons.dart';
import 'package:coconut_vault/widgets/highlighted_text.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum ChangeCountButtonType { nCountMinus, nCountPlus, mCountMinus, mCountPlus }

class GradientProgressBar extends StatelessWidget {
  final double value;
  final double height;
  final Gradient gradient;

  const GradientProgressBar({
    super.key,
    required this.value,
    required this.height,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: Container(
        width: double.infinity,
        height: height,
        color: CoconutColors.black.withOpacity(0.06),
        child: Stack(
          children: [
            FractionallySizedBox(
              widthFactor: value,
              child: Container(
                decoration: BoxDecoration(
                  gradient: gradient,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MultisigQuorumSelectionScreen extends StatefulWidget {
  const MultisigQuorumSelectionScreen({super.key});

  @override
  State<MultisigQuorumSelectionScreen> createState() => _MultisigQuorumSelectionScreenState();
}

class _MultisigQuorumSelectionScreenState extends State<MultisigQuorumSelectionScreen> {
  late MultisigQuorumSelectionViewModel _viewModel;

  bool _mounted = true; // didChangeDependencies
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MultisigQuorumSelectionViewModel>(
      create: (_) => _viewModel,
      child: Consumer<MultisigQuorumSelectionViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            backgroundColor: CoconutColors.white,
            appBar: CustomAppBar.buildWithNext(
              title: t.multisig_wallet,
              context: context,
              onNextPressed: () {
                viewModel.saveQuorumRequirement();
                viewModel.setProgressAnimationVisible(false); // TODO: UI
                _mounted = false;
                Navigator.pushNamed(context, AppRoutes.signerAssignment);
              },
              isActive: viewModel.isQuorumSettingValid,
            ),
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32),
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(
                          child: Center(
                            child: Text(
                              t.select_multisig_quorum_screen.total_key_count,
                              style: Styles.body2Bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        CountingRowButton(
                          onMinusPressed: () =>
                              viewModel.onCountButtonClicked(ChangeCountButtonType.nCountMinus),
                          onPlusPressed: () =>
                              viewModel.onCountButtonClicked(ChangeCountButtonType.nCountPlus),
                          countText: viewModel.totalCount.toString(),
                          isMinusButtonDisabled: viewModel.totalCount <= 2,
                          isPlusButtonDisabled: viewModel.totalCount >= 3,
                        ),
                        const SizedBox(
                          width: 18,
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: Center(
                            child: Text(
                              t.select_multisig_quorum_screen.required_signature_count,
                              style: Styles.body2Bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        CountingRowButton(
                          onMinusPressed: () =>
                              viewModel.onCountButtonClicked(ChangeCountButtonType.mCountMinus),
                          onPlusPressed: () =>
                              viewModel.onCountButtonClicked(ChangeCountButtonType.mCountPlus),
                          countText: viewModel.requiredCount.toString(),
                          isMinusButtonDisabled: viewModel.requiredCount <= 1,
                          isPlusButtonDisabled: viewModel.requiredCount == viewModel.totalCount,
                        ),
                        const SizedBox(
                          width: 18,
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 50,
                    ),
                    Center(
                      child: HighLightedText(
                        '${viewModel.requiredCount}/${viewModel.totalCount}',
                        color: CoconutColors.gray800,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        viewModel.buildQuorumMessage(),
                        style: Styles.unit.merge(TextStyle(
                            height: viewModel.requiredCount == viewModel.totalCount
                                ? 32.4 / 18
                                : 23.4 / 18,
                            letterSpacing: -0.01,
                            fontSize: 14)),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                    viewModel.isProgressAnimationVisible
                        ? KeySafeAnimationWidget(
                            requiredCount: viewModel.requiredCount,
                            totalCount: viewModel.totalCount,
                            buttonClickedCount: viewModel.buttonClickedCount,
                          )
                        : Container()
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    String? currentRoute = ModalRoute.of(context)?.settings.name;
    debugPrint('currentRoute: $currentRoute, mounted: $mounted');
    if (!_mounted &&
        currentRoute != null &&
        currentRoute.startsWith(AppRoutes.multisigQuorumSelection)) {
      _viewModel.setProgressAnimationVisible(false);
      Future.delayed(const Duration(milliseconds: 100), () {
        _viewModel.setProgressAnimationVisible(true);
      });
      _mounted = true;
    }
  }

  @override
  void initState() {
    super.initState();
    _viewModel = MultisigQuorumSelectionViewModel(
      Provider.of<WalletCreationProvider>(context, listen: false),
    );
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (_mounted) {
        _viewModel.setNextButtonEnabled(true);
      }
    });
  }
}
