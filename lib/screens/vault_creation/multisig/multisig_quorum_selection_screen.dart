import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/view_model/mutlisig_quorum_selection_view_model.dart';
import 'package:coconut_vault/providers/wallet_creation_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/widgets/animation/key_safe_animation_widget.dart';
import 'package:coconut_vault/widgets/button/fixed_bottom_button.dart';
import 'package:coconut_vault/widgets/highlighted_text.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GradientProgressBar extends StatelessWidget {
  final double value;
  final double height;
  final Gradient gradient;

  const GradientProgressBar({super.key, required this.value, required this.height, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: Container(
        width: double.infinity,
        height: height,
        color: CoconutColors.black.withValues(alpha: 0.06),
        child: Stack(
          children: [
            FractionallySizedBox(widthFactor: value, child: Container(decoration: BoxDecoration(gradient: gradient))),
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

  bool _mounted = true;
  int _totalKeyCount = 3;
  int _requiredSignatureCount = 2;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<MultisigQuorumSelectionViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            backgroundColor: CoconutColors.white,
            appBar: CoconutAppBar.build(title: t.multisig_wallet, context: context),
            body: SafeArea(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32),
                      child: Column(
                        children: [
                          _buildQuorumInfo(viewModel),
                          CoconutLayout.spacing_600h,
                          _buildTotalKeyCount(viewModel),
                          CoconutLayout.spacing_400h,
                          _buildRequiredSignatureCount(viewModel),
                          CoconutLayout.spacing_1400h,
                        ],
                      ),
                    ),
                  ),
                  FixedBottomButton(
                    text: t.next,
                    backgroundColor: CoconutColors.black,
                    isActive: viewModel.isQuorumSettingValid,
                    onButtonClicked: () {
                      viewModel.saveQuorumRequirement();

                      _mounted = false;
                      Navigator.pushNamed(context, AppRoutes.signerAssignment);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _viewModel = MultisigQuorumSelectionViewModel(
      Provider.of<WalletProvider>(context, listen: false),
      Provider.of<WalletCreationProvider>(context, listen: false),
    );

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (_mounted) {
        _viewModel.setNextButtonEnabled(true);
      }
    });
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  Widget _buildQuorumInfo(MultisigQuorumSelectionViewModel viewModel) {
    final requiredCount = viewModel.requiredCount;
    final totalCount = viewModel.totalCount;
    final quorumMessage = viewModel.buildQuorumMessage();

    final buttonClickedCount = viewModel.buttonClickedCount;

    return Container(
      height: 274,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(borderRadius: CoconutBorder.defaultRadius, color: CoconutColors.gray150),
      alignment: Alignment.center,
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
        child: Column(
          children: [
            Center(child: HighLightedText('$requiredCount/$totalCount', color: CoconutColors.gray800, fontSize: 24)),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                quorumMessage,
                style: CoconutTypography.body2_14_Number.merge(const TextStyle(letterSpacing: -0.01)),
                textAlign: TextAlign.center,
              ),
            ),
            const Spacer(),
            KeySafeAnimationWidget(
              requiredCount: requiredCount,
              totalCount: totalCount,
              buttonClickedCount: buttonClickedCount,
            ),
            CoconutLayout.spacing_400h,
          ],
        ),
      ),
    );
  }

  Widget _buildTotalKeyCount(MultisigQuorumSelectionViewModel viewModel) {
    return _buildKeyStepperWidget(
      key: const Key('total_key_count'),
      text: t.select_multisig_quorum_screen.total_key_count,
      maxCount: 3,
      minCount: 2,
      initialCount: _totalKeyCount,
      onCount: (count) {
        viewModel.onClick(QuorumType.totalCount, count);
        setState(() {
          _totalKeyCount = count;
        });
        if (_totalKeyCount < _requiredSignatureCount) {
          setState(() {
            _requiredSignatureCount = _totalKeyCount;
          });
        }
      },
    );
  }

  Widget _buildRequiredSignatureCount(MultisigQuorumSelectionViewModel viewModel) {
    return _buildKeyStepperWidget(
      key: ValueKey('required_signature_count_$_requiredSignatureCount'),
      text: t.select_multisig_quorum_screen.required_signature_count,
      maxCount: _totalKeyCount,
      minCount: 1,
      initialCount: _requiredSignatureCount,
      onCount: (count) {
        viewModel.onClick(QuorumType.requiredCount, count);
        setState(() {
          _requiredSignatureCount = count;
        });
      },
    );
  }

  Widget _buildKeyStepperWidget({
    required Key key,
    required String text,
    required int maxCount,
    required int minCount,
    required int initialCount,
    required Function(int count) onCount,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      key: key,
      children: [
        Expanded(child: Center(child: Text(text, style: CoconutTypography.body2_14_Bold))),
        Expanded(
          child: CoconutStepper(
            key: ValueKey('${key.toString()}_$_totalKeyCount'),
            maxCount: maxCount,
            onCount: onCount,
            initialCount: initialCount,
            minCount: minCount,
          ),
        ),
        CoconutLayout.spacing_500w,
      ],
    );
  }
}
