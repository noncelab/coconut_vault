import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/screens/common/menu_grid.dart';
import 'package:coconut_vault/screens/vault_creation/taproot/taproot_creation_body.dart';
import 'package:coconut_vault/widgets/box/info_box.dart';
import 'package:coconut_vault/widgets/card/selectable_option_card.dart';
import 'package:coconut_vault/widgets/indicator/timeline_step_indicator.dart';
import 'package:coconut_vault/widgets/indicator/top_progress_bar.dart';
import 'package:coconut_vault/widgets/adaptive_qr_image.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/providers/wallet_creation/taproot_wallet_creation_provider.dart';
import 'package:coconut_vault/providers/view_model/vault_creation/taproot/child_creation_view_model.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

class ChildCreationScreen extends StatelessWidget {
  const ChildCreationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(create: (_) => ChildCreationViewModel(), child: const _ChildCreationScreenContent());
  }
}

class _ChildCreationScreenContent extends StatefulWidget {
  const _ChildCreationScreenContent();

  @override
  State<_ChildCreationScreenContent> createState() => _ChildCreationScreenContentState();
}

class _ChildCreationScreenContentState extends State<_ChildCreationScreenContent> {
  static const int _totalStep = 5;
  int _currentStep = 1;

  List<TextSpan> _titleLines(ChildCreationViewModel viewModel) {
    final textList = _titleList(viewModel)[_currentStep - 1];
    if (textList.length == 1) {
      return [const TextSpan(text: ''), textList[0], const TextSpan(text: '')];
    }
    if (textList.length == 2) {
      return [textList[0], textList[1], const TextSpan(text: '')];
    }
    return textList;
  }

  List<List<TextSpan>> _titleList(ChildCreationViewModel viewModel) => [
    [
      TextSpan(text: t.taproot.child_creation_screen.step1.title1),
      TextSpan(text: t.taproot.child_creation_screen.step1.title2),
    ],
    [
      TextSpan(text: t.taproot.child_creation_screen.step2.title1),
      TextSpan(text: t.taproot.child_creation_screen.step2.title2),
    ],
    viewModel.isCreateKeySelected
        ? [TextSpan(text: t.taproot.child_creation_screen.step3.title_new)]
        : [TextSpan(text: t.taproot.child_creation_screen.step3.title_existing)],
    [
      TextSpan(text: t.taproot.child_creation_screen.step4.title1),
      TextSpan(text: t.taproot.child_creation_screen.step4.title2, style: CoconutTypography.body1_16),
      TextSpan(text: t.taproot.child_creation_screen.step4.title3, style: CoconutTypography.body1_16),
    ],
    [
      TextSpan(text: t.taproot.child_creation_screen.step5.title1),
      TextSpan(text: t.taproot.child_creation_screen.step5.title2),
    ],
    [TextSpan(text: t.taproot.child_creation_screen.step6.title1)],
  ];

  List<Widget> _childList(ChildCreationViewModel viewModel) => [
    Center(child: Image.asset('assets/png/load-wallet.png', scale: 4.0, width: 210)),
    MenuGrid(
      children: [
        SelectableOptionCard(
          title: t.taproot.child_creation_screen.step2.option1_title,
          description: t.taproot.child_creation_screen.step2.option1_desc,
          bottomAssetPath: 'assets/png/wallet.png',
          imageScale: 4.0,
          imageWidth: 100,
          isSelected: viewModel.isCreateKeySelected,
          height: 217,
          onTap: () {
            viewModel.setKeyPreparationType(ChildKeyPreparationType.create);
          },
        ),
        SelectableOptionCard(
          title: t.taproot.child_creation_screen.step2.option2_title,
          description: t.taproot.child_creation_screen.step2.option2_desc,
          bottomAssetPath: 'assets/png/key-holder.png',
          imageScale: 4.0,
          imageWidth: 100,
          isSelected: viewModel.isImportKeySelected,
          height: 217,
          onTap: () {
            viewModel.setKeyPreparationType(ChildKeyPreparationType.import);
          },
        ),
      ],
    ),
    viewModel.isCreateKeySelected
        ? MenuGrid(
          children: [
            SelectableOptionCard(
              title: t.taproot.child_creation_screen.step3.new_option1,
              bottomAssetPath: 'assets/png/coin.png',
              imageScale: 4.0,
              imageWidth: 67,
              isSelected: viewModel.isCoinFlipSelected,
              height: 118,
              onTap: () {
                viewModel.setNewKeyCreationType(ChildNewKeyCreationType.coinFlip);
              },
            ),
            SelectableOptionCard(
              title: t.taproot.child_creation_screen.step3.new_option2,
              bottomAssetPath: 'assets/png/dice.png',
              imageScale: 4.0,
              imageWidth: 67,
              isSelected: viewModel.isDiceRollSelected,
              height: 118,
              onTap: () {
                viewModel.setNewKeyCreationType(ChildNewKeyCreationType.diceRoll);
              },
            ),
            SelectableOptionCard(
              title: t.taproot.child_creation_screen.step3.new_option3,
              bottomAssetPath: 'assets/png/gear.png',
              imageScale: 4.0,
              imageWidth: 67,
              isSelected: viewModel.isAutoGenerateSelected,
              height: 118,
              onTap: () {
                viewModel.setNewKeyCreationType(ChildNewKeyCreationType.autoGenerate);
              },
            ),
          ],
        )
        : MenuGrid(
          children: [
            SelectableOptionCard(
              title: t.taproot.child_creation_screen.step3.existing_option1,
              bottomAssetPath: 'assets/png/finger-picking.png',
              imageScale: 4.0,
              imageWidth: 67,
              isSelected: viewModel.isCurrentVaultSelected,
              height: 118,
              onTap: () {
                viewModel.setExistingKeyImportType(ChildExistingKeyImportType.currentVault);
              },
            ),
            SelectableOptionCard(
              title: t.taproot.child_creation_screen.step3.existing_option2,
              bottomAssetPath: 'assets/png/word.png',
              imageScale: 4.0,
              imageWidth: 67,
              isSelected: viewModel.isMnemonicInputSelected,
              height: 118,
              onTap: () {
                viewModel.setExistingKeyImportType(ChildExistingKeyImportType.mnemonicInput);
              },
            ),
            SelectableOptionCard(
              title: t.taproot.child_creation_screen.step3.existing_option3,
              bottomAssetPath: 'assets/png/scan-qr.png',
              imageScale: 4.0,
              imageWidth: 67,
              isSelected: viewModel.isSeedQrScanSelected,
              height: 118,
              onTap: () {
                viewModel.setExistingKeyImportType(ChildExistingKeyImportType.seedQrScan);
              },
            ),
          ],
        ),
    _buildQrSection(viewModel),
    const TimelineStepIndicator(
      timelineStepItemList: [
        TimelineStepItem(
          title: '부모 지갑 연결',
          description: '단일 서명 지갑과 연결됨 (MFP: 000000)',
          status: TimelineStepStatus.current,
        ),
        TimelineStepItem(
          title: '자식 지갑 설정',
          description: '탭루트 자식 지갑 (MFP: 000000)',
          status: TimelineStepStatus.upcoming,
        ),
        TimelineStepItem(title: '기간 설정', description: '2030년 2월 16일 오전 09:21', status: TimelineStepStatus.upcoming),
        TimelineStepItem(
          title: '자식 지갑 활성화',
          description: '2030년 2월 16일 오전 09:21 이후',
          status: TimelineStepStatus.future,
        ),
      ],
    ),
  ];

  Widget _buildQrSection(ChildCreationViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.only(top: 21),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (viewModel.qrData != null && viewModel.qrData!.isNotEmpty)
            AdaptiveQrImage(qrData: viewModel.qrData!)
          else
            const SizedBox(height: 200), // QR 데이터가 없을 때 영역 확보용 위젯
          CoconutLayout.spacing_500h,
          InfoBox(
            infoList: [
              MapEntry(t.wallet_type, t.taproot.taproot_single_sig_wallet),
              MapEntry(t.mfp, viewModel.masterFingerprint ?? '00000000'),
            ],
          ),
        ],
      ),
    );
  }

  bool _isNextButtonVisible(ChildCreationViewModel viewModel) {
    if (_currentStep == 2) {
      return viewModel.selectedKeyPreparationType != ChildKeyPreparationType.none;
    }
    if (_currentStep == 3) {
      if (viewModel.isCreateKeySelected) {
        return viewModel.selectedNewKeyCreationType != ChildNewKeyCreationType.none;
      } else {
        return viewModel.selectedExistingKeyImportType != ChildExistingKeyImportType.none;
      }
    }
    return true;
  }

  void _onNextPressed(ChildCreationViewModel viewModel) async {
    if (_currentStep == 3) {
      if (viewModel.isCreateKeySelected) {
        String? route;
        switch (viewModel.selectedNewKeyCreationType) {
          case ChildNewKeyCreationType.coinFlip:
            route = AppRoutes.mnemonicCoinflip;
            break;
          case ChildNewKeyCreationType.diceRoll:
            route = AppRoutes.mnemonicDiceRoll;
            break;
          case ChildNewKeyCreationType.autoGenerate:
            route = AppRoutes.mnemonicAutoGen;
            break;
          case ChildNewKeyCreationType.none:
            break;
        }

        if (route != null) {
          final passedCheck = await Navigator.pushNamed(
            context,
            AppRoutes.securitySelfCheck,
            arguments: () {
              Navigator.pop(context, true);
            },
          );
          if (passedCheck == true) {
            if (!mounted) return;
            final result = await Navigator.pushNamed(context, route, arguments: {'isTaprootChild': true});
            if (result == true) {
              if (!mounted) return;
              try {
                final taprootProvider = context.read<TaprootWalletCreationProvider>();
                viewModel.generateKeyData(taprootProvider.secret, taprootProvider.passphrase);
                setState(() {
                  _currentStep += 1;
                });
              } catch (e) {
                Logger.error('Failed to generate child wallet: $e');
              }
            }
          }
          return;
        }
      } else if (viewModel.isImportKeySelected) {
        if (viewModel.isMnemonicInputSelected) {
          Navigator.pushNamed(context, AppRoutes.mnemonicImport);
          return;
        } else if (viewModel.isSeedQrScanSelected) {
          Navigator.pushNamed(context, AppRoutes.seedQrImport);
          return;
        }
      }
    }

    if (_currentStep >= _totalStep) {
      return;
    }

    setState(() {
      _currentStep += 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ChildCreationViewModel>();

    return Scaffold(
      backgroundColor: CoconutColors.white,
      appBar: CoconutAppBar.build(
        title: t.taproot.child_creation_screen.title,
        context: context,
        backgroundColor: CoconutColors.white,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            TaprootCreationBody(
              titleLines: _titleLines(viewModel),
              showBottomButton: _isNextButtonVisible(viewModel),
              onBottomButtonPressed: () => _onNextPressed(viewModel),
              child: Container(child: _childList(viewModel)[_currentStep - 1]),
            ),
            TopProgressBar(visible: true, total: _totalStep - 1, current: _currentStep - 1),
          ],
        ),
      ),
    );
  }
}
