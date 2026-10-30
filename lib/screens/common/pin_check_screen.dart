import 'package:coconut_vault/providers/view_model/pin_check_view_model.dart';
import 'dart:async';
import 'dart:io';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/enums/pin_check_context_enum.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/preference_provider.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/utils/popup_util.dart';
import 'package:coconut_vault/widgets/pin/pin_length_toggle_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:coconut_vault/screens/settings/pin_setting_screen.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:provider/provider.dart';

import 'pin_input_screen.dart';

class PinCheckScreen extends StatefulWidget {
  final FutureOr<void> Function()? onReset;
  final FutureOr<void> Function()? onSuccess;
  final FutureOr<void> Function()? onPermanentlyLocked;
  final FutureOr<void> Function()? onPermanentLockReset;
  final PinCheckContextEnum pinCheckContext;
  const PinCheckScreen({
    super.key,
    required this.pinCheckContext,
    this.onReset,
    this.onSuccess,
    this.onPermanentlyLocked,
    this.onPermanentLockReset,
  });

  @override
  State<PinCheckScreen> createState() => _PinCheckScreenState();
}

class _PinCheckScreenState extends State<PinCheckScreen> {
  late final PinCheckViewModel _viewModel;
  final FocusNode _characterFocusNode = FocusNode();
  DateTime? _lastPressedAt;
  bool get _isAppLaunched => widget.pinCheckContext == PinCheckContextEnum.appLaunch;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _viewModel = PinCheckViewModel(
      authProvider: auth,
      pinCheckContext: widget.pinCheckContext,
      onSuccess: _navigateAfterAuthentication,
      onKeyboardFocus: _focusKeyboard,
      verifyBiometrics: () async {
        if (mounted) await auth.verifyBiometric(context);
      },
      onReset: () async {
        if (mounted) await widget.onReset?.call();
      },
      onPermanentlyLocked: () async {
        if (mounted) await widget.onPermanentlyLocked?.call();
      },
      onPermanentLockReset: () async {
        if (mounted) await widget.onPermanentLockReset?.call();
      },
      onResetFailure: (error) async => mounted ? showResetFailureRetryPopup(context, error) : false,
      getPreferenceProvider: () => context.read<PreferenceProvider>(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _viewModel.initialize();
    });
  }

  Future<void> _navigateAfterAuthentication() async {
    if (!mounted) return;
    switch (widget.pinCheckContext) {
      case PinCheckContextEnum.pinChange:
        Navigator.pop(context);
        MyBottomSheet.showBottomSheet_90(context: context, child: const PinSettingScreen());
        break;
      default:
        await widget.onSuccess?.call();
    }
  }

  Future<void> _focusKeyboard() async {
    if (!mounted || _viewModel.pinType != PinType.character) return;
    FocusScope.of(context).unfocus();
    if (_characterFocusNode.canRequestFocus) {
      _characterFocusNode.requestFocus();
      if (Platform.isAndroid) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        if (mounted) SystemChannels.textInput.invokeMethod('TextInput.show');
      }
    }
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return CoconutPopup(
          languageCode: context.read<VisibilityProvider>().appLanguage.code,
          insetPadding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.15),
          title:
              _viewModel.authenticationRecoveryRequired
                  ? t.errors.pin_storage_reset_button
                  : !_viewModel.isPermanentlyLocked
                  ? t.alert.forgot_password.title
                  : t.pin_check_screen.dialog.restart.title,
          description:
              _viewModel.authenticationRecoveryRequired
                  ? t.errors.pin_storage_reset_warning
                  : !_viewModel.isPermanentlyLocked
                  ? t.alert.forgot_password.description1
                  : t.pin_check_screen.dialog.restart.description,
          leftButtonText: t.no,
          leftButtonColor: CoconutColors.black.withValues(alpha: 0.7),
          rightButtonText: t.yes,
          rightButtonColor: CoconutColors.warningText,
          onTapRight: () {
            Navigator.pop(context);
            _viewModel.confirmReset();
          },
          onTapLeft: () => Navigator.pop(context),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PinCheckViewModel>.value(
      value: _viewModel,
      child: Consumer<PinCheckViewModel>(builder: (context, model, _) => _buildScreen(context)),
    );
  }

  Widget _buildScreen(BuildContext context) {
    return _isAppLaunched
        ? Material(
          color: CoconutColors.white,
          child: PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) async {
              if (Platform.isAndroid && widget.pinCheckContext == PinCheckContextEnum.appLaunch) {
                final now = DateTime.now();
                if (_lastPressedAt == null || now.difference(_lastPressedAt!) > const Duration(seconds: 3)) {
                  _lastPressedAt = now;
                  Fluttertoast.showToast(
                    backgroundColor: CoconutColors.gray800,
                    msg: t.toast.back_exit,
                    toastLength: Toast.LENGTH_SHORT,
                  );
                } else {
                  SystemNavigator.pop();
                }
              }
            },
            child: Scaffold(
              backgroundColor: CoconutColors.white,
              body: Stack(
                children: [
                  Center(child: _pinInputScreen(isOnReset: true)),
                  if (_viewModel.isResetting)
                    const Positioned.fill(child: AbsorbPointer(child: Center(child: CoconutCircularIndicator()))),
                ],
              ),
            ),
          ),
        )
        : PopScope(canPop: !_viewModel.isResetting, child: _pinInputScreen());
  }

  Widget _pinInputScreen({isOnReset = false}) {
    return Selector<AuthProvider, bool>(
      selector: (_, authProvider) => authProvider.isPermanentlyLocked,
      builder: (context, isPermanentlyLocked, child) {
        return PinInputScreen(
          canChangePinType: false,
          appBarVisible: _isAppLaunched ? false : true,
          title: _isAppLaunched ? '' : t.pin_check_screen.enter_password,
          pin: _viewModel.pin,
          errorMessage: _viewModel.errorMessage,
          onKeyTap: _viewModel.onKeyTap,
          pinType: _viewModel.pinType,
          pinShuffleNumbers: _viewModel.shuffledPinNumbers,
          onPinClear: _viewModel.clearPin,
          bottomTextButtonLabel:
              _isAppLaunched
                  ? _viewModel.authenticationRecoveryRequired
                      ? t.errors.pin_storage_reset_button
                      : isPermanentlyLocked
                      ? t.errors.restart_vault
                      : t.forgot_password
                  : null,
          onPressedBottomTextButton: _showResetDialog,
          step: 0,
          lastChance: _viewModel.isLastChanceToTry,
          lastChanceMessage: t.pin_check_screen.warning,
          disabled: _viewModel.disabled,
          characterFocusNode: _characterFocusNode,
          isLoading: _viewModel.isVerifyingPin,
          shouldDelayKeyboard: _viewModel.shouldDelayKeyboard,
        );
      },
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _characterFocusNode.dispose();
    super.dispose();
  }
}
