import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/multisig/multisig_creation_model.dart';
import 'package:coconut_vault/providers/view_model/mutlisig_quorum_selection_view_model.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/appbar/custom_appbar.dart';
import 'package:coconut_vault/widgets/button/custom_buttons.dart';
import 'package:coconut_vault/widgets/highlighted_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
        color: MyColors.transparentBlack_06,
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
  State<MultisigQuorumSelectionScreen> createState() =>
      _MultisigQuorumSelectionScreenState();
}

class _MultisigQuorumSelectionScreenState
    extends State<MultisigQuorumSelectionScreen> {
  late MultisigQuorumSelectionViewModel _viewModel;
  bool _mounted = true; // didChangeDependencies
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MultisigQuorumSelectionViewModel>(
      create: (_) => _viewModel,
      child: Consumer<MultisigQuorumSelectionViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            backgroundColor: MyColors.white,
            appBar: CustomAppBar.buildWithNext(
              title: t.multisig_wallet,
              context: context,
              onNextPressed: () {
                viewModel.setQuorumRequirementToModel();
                viewModel.stopAnimationProgress();
                _mounted = false;
                Navigator.pushNamed(context, AppRoutes.signerAssignment);
              },
              isActive: viewModel.isQuorumSettingValid,
            ),
            body: SingleChildScrollView(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32),
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
                          onMinusPressed: () => viewModel.onCountButtonClicked(
                              ChangeCountButtonType.nCountMinus),
                          onPlusPressed: () => viewModel.onCountButtonClicked(
                              ChangeCountButtonType.nCountPlus),
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
                              t.select_multisig_quorum_screen
                                  .required_signature_count,
                              style: Styles.body2Bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        CountingRowButton(
                          onMinusPressed: () => viewModel.onCountButtonClicked(
                              ChangeCountButtonType.mCountMinus),
                          onPlusPressed: () => viewModel.onCountButtonClicked(
                              ChangeCountButtonType.mCountPlus),
                          countText: viewModel.requiredCount.toString(),
                          isMinusButtonDisabled: viewModel.requiredCount <= 1,
                          isPlusButtonDisabled:
                              viewModel.requiredCount == viewModel.totalCount,
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
                        color: MyColors.darkgrey,
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
                            height:
                                viewModel.requiredCount == viewModel.totalCount
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 64),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Row(
                                    children: [
                                      viewModel.keyActive_1
                                          ? SvgPicture.asset(
                                              'assets/svg/key-icon.svg',
                                              width: 20,
                                            )
                                          : SvgPicture.asset(
                                              'assets/svg/key-icon.svg',
                                              width: 20,
                                              colorFilter: const ColorFilter
                                                  .mode(
                                                  MyColors
                                                      .progressbarColorDisabled,
                                                  BlendMode.srcIn),
                                            ),
                                      const SizedBox(
                                        width: 30,
                                      ),
                                      Expanded(child: _buildProgressBar(0)),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 24,
                                  ),
                                  Visibility(
                                    visible: viewModel.totalCount == 3,
                                    child: Row(
                                      children: [
                                        viewModel.keyActive_2
                                            ? SvgPicture.asset(
                                                'assets/svg/key-icon.svg',
                                                width: 20,
                                              )
                                            : SvgPicture.asset(
                                                'assets/svg/key-icon.svg',
                                                width: 20,
                                                colorFilter: const ColorFilter
                                                    .mode(
                                                    MyColors
                                                        .progressbarColorDisabled,
                                                    BlendMode.srcIn),
                                              ),
                                        const SizedBox(
                                          width: 30,
                                        ),
                                        Expanded(child: _buildProgressBar(1)),
                                      ],
                                    ),
                                  ),
                                  viewModel.totalCount == 3
                                      ? const SizedBox(
                                          height: 24,
                                        )
                                      : Container(),
                                  Row(
                                    children: [
                                      viewModel.keyActive_3
                                          ? SvgPicture.asset(
                                              'assets/svg/key-icon.svg',
                                              width: 20,
                                            )
                                          : SvgPicture.asset(
                                              'assets/svg/key-icon.svg',
                                              width: 20,
                                              colorFilter: const ColorFilter
                                                  .mode(
                                                  MyColors
                                                      .progressbarColorDisabled,
                                                  BlendMode.srcIn),
                                            ),
                                      const SizedBox(
                                        width: 30,
                                      ),
                                      Expanded(child: _buildProgressBar(2)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(
                              width: 20,
                            ),
                            viewModel.animatedOpacityValue == 1
                                ? SvgPicture.asset(
                                    'assets/svg/safe-bit.svg',
                                    width: 50,
                                  )
                                : SvgPicture.asset('assets/svg/safe.svg',
                                    width: 50)
                          ],
                        ),
                      ),
                    )
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
      _viewModel.startAnimationProgress(_viewModel.totalCount,
          _viewModel.requiredCount, _viewModel.buttonClickedCount);
      _mounted = true;
    }
  }

  @override
  void initState() {
    super.initState();
    _viewModel = MultisigQuorumSelectionViewModel(
      Provider.of<MultisigCreationModel>(context, listen: false),
    );
  }

  Widget _buildProgressBar(int key) {
    return SizedBox(
      height: 4,
      child: LinearProgressIndicator(
        borderRadius: BorderRadius.circular(12),
        value: key == 0
            ? _viewModel.progressValue_1
            : key == 1
                ? _viewModel.progressValue_2
                : _viewModel.progressValue_3,
        color: MyColors.progressbarColorEnabled,
        backgroundColor: MyColors.progressbarColorDisabled,
      ),
    );
  }
}
