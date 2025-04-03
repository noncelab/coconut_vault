import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/view_model/create_backup_view_model.dart';
import 'package:coconut_vault/widgets/indicator/circle_countdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:provider/provider.dart';

enum PrepareUpdateLevel {
  start,
  mnemonicValidate,
  beforeUpdate,
  creatingSafetyKey,
  savingWalletData,
  checkingBackupFile,
  prepareUpdateComplete,
}

class PrepareUpdateScreen extends StatefulWidget {
  const PrepareUpdateScreen({super.key});

  @override
  State<PrepareUpdateScreen> createState() => _PrepareUpdateScreenState();
}

class _PrepareUpdateScreenState extends State<PrepareUpdateScreen> {
  final TextEditingController _textEditingController = TextEditingController();
  final _textFieldFocusNode = FocusNode();

  bool _mnemonicErrorVisible = false;
  bool _nextButtonEnabled = true;

  PrepareUpdateLevel _prepareUpdateLevel = PrepareUpdateLevel.start;

  @override
  void initState() {
    super.initState();
    _textEditingController.addListener(() {
      if (_textEditingController.text.length >= 3) {
        _validateMnemonic();
      } else {
        setState(() {
          _mnemonicErrorVisible = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PrepareUpdateViewModel(),
      child: Consumer<PrepareUpdateViewModel>(
        builder: (context, viewModel, child) {
          return GestureDetector(
            onTap: () => _closeKeyboard(),
            child: Scaffold(
              appBar: CoconutAppBar.build(
                title: t.settings_screen.prepare_update,
                context: context,
              ),
              body: Container(
                width: MediaQuery.sizeOf(context).width,
                padding: const EdgeInsets.symmetric(
                  horizontal: CoconutLayout.defaultPadding,
                ),
                height: MediaQuery.sizeOf(context).height -
                    kToolbarHeight -
                    MediaQuery.of(context).padding.top,
                child: Stack(
                  children: [
                    _getBodyWidget(),
                    if (_prepareUpdateLevel == PrepareUpdateLevel.start ||
                        _prepareUpdateLevel == PrepareUpdateLevel.beforeUpdate)
                      Positioned(
                          left: 0,
                          right: 0,
                          bottom: 40,
                          child: _buildNextButton()),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _getBodyWidget() {
    switch (_prepareUpdateLevel) {
      case PrepareUpdateLevel.start:
        return _buildStartWidget();
      case PrepareUpdateLevel.mnemonicValidate:
        return _buildMnemonicValidateWidget();
      case PrepareUpdateLevel.beforeUpdate:
        return _buildBeforeUpdateWidget();
      case PrepareUpdateLevel.prepareUpdateComplete:
        return _buildPrepareUpdateCompleteWidget();
      case PrepareUpdateLevel.creatingSafetyKey:
      case PrepareUpdateLevel.savingWalletData:
      case PrepareUpdateLevel.checkingBackupFile:
        return _buildUpdateProcessWidget();
    }
  }

  Widget _buildNextButton() {
    return Stack(
      children: [
        CoconutButton(
          onPressed: () => _onNextButtonPressed(),
          isActive: _nextButtonEnabled,
          width: double.infinity,
          text: _prepareUpdateLevel == PrepareUpdateLevel.start
              ? t.confirm
              : t.start,
        ),
        if (_prepareUpdateLevel == PrepareUpdateLevel.beforeUpdate)
          Positioned(
            right: 20,
            top: 0,
            bottom: 0,
            child: CircleCountdown(
              startSeconds: 5,
              onCompleted: () {
                if (!mounted) return;
                setState(() {
                  _nextButtonEnabled = true;
                });
              },
            ),
          ),
      ],
    );
  }

  void _onNextButtonPressed() async {
    // PrepareUpdateLevel.start 상태에서는 mnemonicValidate으로 전환,
    // PrepareUpdateLevel.beforeUpdate 상태에서는 creatingSafetyKey으로 전환
    // PrepareUpdateLevel.beforeUpdate 전환직후 _nextButtonEnabled이 false로 설정되고 countdown 5초 후 _nextButtonEnabled이 true로 변경됨
    if (_prepareUpdateLevel == PrepareUpdateLevel.start) {
      setState(() {
        _prepareUpdateLevel = PrepareUpdateLevel.mnemonicValidate;
      });
    } else if (_prepareUpdateLevel == PrepareUpdateLevel.beforeUpdate) {
      setState(() {
        _nextButtonEnabled = false;
        _prepareUpdateLevel = PrepareUpdateLevel.creatingSafetyKey;
      });
    }
  }

  Widget _buildStartWidget() {
    return Center(
      child: Column(
        children: [
          CoconutLayout.spacing_1600h,
          Text(
            t.prepare_update.title,
            style: CoconutTypography.heading4_18_Bold,
          ),
          CoconutLayout.spacing_500h,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              t.prepare_update.description,
              style: CoconutTypography.body2_14,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMnemonicValidateWidget() {
    return Center(
      child: Column(
        children: [
          CoconutLayout.spacing_1600h,
          Text(
            // TODO 지갑이름, value 삽입
            t.prepare_update
                .enter_nth_word_of_wallet(wallet_name: 'test', n: 10),
            style: CoconutTypography.heading4_18_Bold,
          ),
          CoconutLayout.spacing_1500h,
          _buildMnemonicTextField(),
        ],
      ),
    );
  }

  Widget _buildBeforeUpdateWidget() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CoconutLayout.spacing_1300h,
      ],
    );
  }

  Widget _buildUpdateProcessWidget() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CoconutLayout.spacing_1300h,
      ],
    );
  }

  Widget _buildPrepareUpdateCompleteWidget() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CoconutLayout.spacing_1300h,
      ],
    );
  }

  void _validateMnemonic() async {
    if (_textEditingController.text != 'mnemonic') {
      // Replace with actual validation
      setState(() {
        _mnemonicErrorVisible = true;
      });
      return;
    }

    setState(() {
      _mnemonicErrorVisible = false;
    });
    _closeKeyboard();
    context.loaderOverlay.show();
    await Future.delayed(const Duration(milliseconds: 2000));
    if (mounted) {
      context.loaderOverlay.hide();
      setState(() {
        _prepareUpdateLevel = PrepareUpdateLevel.beforeUpdate;
      });
    }
  }

  void _closeKeyboard() {
    FocusScope.of(context).unfocus();
  }

  CoconutTextField _buildMnemonicTextField() {
    return CoconutTextField(
      controller: _textEditingController,
      focusNode: _textFieldFocusNode,
      maxLines: 1,
      textInputAction: TextInputAction.done,
      onChanged: (text) {},
      isError: _mnemonicErrorVisible,
      isLengthVisible: false,
      errorText: t.prepare_update.incorrect_input_try_again,
      placeholderText: t.prepare_update.enter_word,
      suffix: Row(children: [
        IconButton(
          iconSize: 14,
          padding: EdgeInsets.zero,
          onPressed: () {
            setState(() {
              _textEditingController.text = '';
            });
          },
          icon: SvgPicture.asset(
            'assets/svg/text-field-clear.svg',
            colorFilter:
                const ColorFilter.mode(CoconutColors.gray300, BlendMode.srcIn),
          ),
        ),
      ]),
    );
  }
}
