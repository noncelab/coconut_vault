import 'package:coconut_vault/providers/view_model/pin_setting_view_model.dart';
import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/widgets/button/fixed_bottom_button.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/utils/vibration_util.dart';
import 'package:coconut_vault/widgets/animated_dialog.dart';
import 'package:coconut_vault/screens/common/pin_input_screen.dart';
import 'package:provider/provider.dart';

class PinSettingScreen extends StatefulWidget {
  final bool greetingVisible;
  final Function? onComplete;
  const PinSettingScreen({super.key, this.greetingVisible = false, this.onComplete});

  @override
  State<PinSettingScreen> createState() => _PinSettingScreenState();
}

class _PinSettingScreenState extends State<PinSettingScreen> {
  late final PinSettingViewModel _viewModel;
  double? _frozenBottomInset;
  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _viewModel = PinSettingViewModel(
      authProvider: auth,
      greetingVisible: widget.greetingVisible,
      authenticateBiometrics:
          () async => mounted ? auth.authenticateWithBiometrics(context: context, isSaved: true) : false,
      noticeBiometrics: () async {
        if (mounted) await _noticeTEEUseBiometrics();
      },
      onSaved: _showSuccessAndNavigate,
      onBeforeSave: () {
        if (mounted) {
          setState(() => _frozenBottomInset = MediaQuery.of(context).viewInsets.bottom);
          FocusScope.of(context).unfocus();
        }
      },
      onProcessingEnd: () {
        if (mounted) setState(() => _frozenBottomInset = null);
      },
    );
  }

  Future<void> _noticeTEEUseBiometrics() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return CoconutPopup(
          languageCode: context.read<VisibilityProvider>().appLanguage.code,
          insetPadding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.15),
          title: t.alert.secure_module_use_biometrics.title,
          description: t.alert.secure_module_use_biometrics.description,
          backgroundColor: CoconutColors.white,
          rightButtonText: t.confirm,
          onTapRight: () {
            Navigator.pop(context);
          },
        );
      },
    );
  }

  Future<void> _showSuccessAndNavigate() async {
    if (!mounted) return;
    vibrateLight();
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (BuildContext buildContext, Animation animation, Animation secondaryAnimation) {
        return AnimatedDialog(
          context: buildContext,
          lottieAddress: 'assets/lottie/pin-locked-success.json',
          duration: 400,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          ).drive(Tween<Offset>(begin: const Offset(0, 1), end: const Offset(0, 0))),
          child: child,
        );
      },
    );

    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    widget.onComplete?.call();

    if (!mounted) {
      return;
    }

    Navigator.pop(context); // 자물쇠 lottie 닫기
    Navigator.pop(context, true); // pin_setting_screen 닫기
    if (widget.greetingVisible) {
      Navigator.pushNamed(context, AppRoutes.vaultTypeSelection);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PinSettingViewModel>.value(
      value: _viewModel,
      child: Consumer<PinSettingViewModel>(builder: (context, model, _) => _buildScreen(context)),
    );
  }

  Widget _buildScreen(BuildContext context) {
    if (_viewModel.greeting) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: CoconutAppBar.build(title: '', context: context, isBottom: true),
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 120),
                  Center(
                    child: Text(
                      t.pin_setting_screen.set_password,
                      style: CoconutTypography.heading3_21_Bold,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              FixedBottomButton(onButtonClicked: _viewModel.dismissGreeting, text: t.confirm),
            ],
          ),
        ),
      );
    }

    Widget screen = PinInputScreen(
      disabled: _viewModel.isProcessing,
      canChangePinType: true,
      title: _viewModel.step == 0 ? t.pin_setting_screen.new_password : t.pin_setting_screen.enter_again,
      descriptionTextWidget: Text.rich(
        TextSpan(
          text: t.pin_setting_screen.keep_in_mind,
          style: CoconutTypography.body3_12.setColor(CoconutColors.warningText),
        ),
        textAlign: TextAlign.center,
      ),
      pin: _viewModel.step == 0 ? _viewModel.pin : _viewModel.pinConfirm,
      errorMessage: _viewModel.errorMessage,
      onKeyTap: _viewModel.onKeyTap,
      onPinTypeChanged: _viewModel.onPinTypeChanged,
      pinType: _viewModel.currentPinType,
      pinShuffleNumbers: _viewModel.shuffledPinNumbers,
      onPinClear: _viewModel.clearPin,
      step: _viewModel.step,
    );

    if (_frozenBottomInset != null) {
      screen = MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(viewInsets: MediaQuery.of(context).viewInsets.copyWith(bottom: _frozenBottomInset)),
        child: screen,
      );
    }

    return screen;
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }
}
