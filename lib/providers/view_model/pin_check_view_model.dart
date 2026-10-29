import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:coconut_vault/constants/pin_constants.dart';
import 'package:coconut_vault/enums/pin_check_context_enum.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/preference_provider.dart';
import 'package:coconut_vault/usecases/reset_credentials_and_wallets_usecase.dart';
import 'package:coconut_vault/utils/vibration_util.dart';
import 'package:coconut_vault/widgets/pin/pin_length_toggle_button.dart';

class PinCheckViewModel extends ChangeNotifier {
  final AuthProvider _authProvider;
  final bool _isAppLaunched;
  final Future<void> Function() onSuccess;
  final Future<void> Function() onKeyboardFocus;
  final Future<void> Function() verifyBiometrics;
  final Future<void> Function() onReset;
  final Future<void> Function() onPermanentlyLocked;
  final Future<void> Function() onPermanentLockReset;
  final Future<bool> Function(Object) onResetFailure;
  final PreferenceProvider Function() getPreferenceProvider;
  bool _disposed = false;
  bool _initialized = false;
  bool get mounted => !_disposed;
  Timer? _countdown;
  String _pin = '';
  String _errorMessage = '';
  late PinType _pinType;
  bool _shouldDelayKeyboard = false;
  late List<String> _shuffledPinNumbers;
  bool? _isPinInputLocked;
  bool _isLastChanceToTry = false;
  bool _isVerifyingPin = false;
  bool _isResetting = false;

  PinCheckViewModel({
    required AuthProvider authProvider,
    required PinCheckContextEnum pinCheckContext,
    required this.onSuccess,
    required this.onKeyboardFocus,
    required this.verifyBiometrics,
    required this.onReset,
    required this.onPermanentlyLocked,
    required this.onPermanentLockReset,
    required this.onResetFailure,
    required this.getPreferenceProvider,
  }) : _authProvider = authProvider,
       _isAppLaunched = pinCheckContext == PinCheckContextEnum.appLaunch {
    _pinType = _authProvider.isPinCharacter ? PinType.character : PinType.number;
    _shouldDelayKeyboard = _isAppLaunched && _authProvider.isBiometricEnabled && _pinType == PinType.character;
    _shuffledPinNumbers = _authProvider.getShuffledNumberList();
    if (_isAppLaunched && _authProvider.isPermanentlyLocked) _errorMessage = t.errors.pin_max_attempts_exceeded_error;
  }
  String get pin => _pin;
  String get errorMessage => _errorMessage;
  PinType get pinType => _pinType;
  List<String> get shuffledPinNumbers => List.unmodifiable(_shuffledPinNumbers);
  bool get shouldDelayKeyboard => _shouldDelayKeyboard;
  bool get isLastChanceToTry => _isLastChanceToTry;
  bool get isVerifyingPin => _isVerifyingPin;
  bool get isResetting => _isResetting;
  bool get disabled =>
      _authProvider.isPermanentlyLocked || _isPinInputLocked != false || _isVerifyingPin || _isResetting;
  bool get isPermanentlyLocked => _authProvider.isPermanentlyLocked;

  Future<void> initialize() async {
    if (_disposed || _initialized) return;
    _initialized = true;
    _authProvider.onAuthenticationSuccess = _handleAuthenticationSuccess;
    await _initializeLockState();
  }

  Future<void> onKeyTap(String value) => _onKeyTap(value);
  void clearPin() => _update(() {
    _pin = '';
    _errorMessage = '';
  });
  Future<void> confirmReset() async {
    if (_disposed) return;
    if (_isAppLaunched && _authProvider.isPermanentlyLocked) {
      await _clearPermanentLockAndGoHome();
    } else {
      await _reset();
    }
  }

  void _update(VoidCallback update) {
    if (_disposed) return;
    update();
    if (!_disposed) notifyListeners();
  }

  Future<void> _initializeLockState() async {
    await _authProvider.ready;
    if (!mounted) return;
    if (_authProvider.authenticationUnavailable) {
      _update(() {
        _isPinInputLocked = true;
        _errorMessage = t.errors.pin_processing_error;
      });
      return;
    }
    _pinType = _authProvider.isPinCharacter ? PinType.character : PinType.number;
    if (!_isAppLaunched) {
      _update(() {
        _isPinInputLocked = false;
      });
      return;
    }

    if (_authProvider.isPermanentlyLocked) {
      _update(() {
        _isPinInputLocked = true;
      });
      // Resume deletion if the app stopped after persisting the final failure.
      if (_authProvider.isPinSet) await _handlePermanentLockout();
      return;
    }

    if (!_authProvider.isUnlockAvailable) {
      _update(() {
        _isPinInputLocked = true;
        if (_authProvider.unlockAvailableAt != null) {
          _startCountdownTimerUntil(_authProvider.unlockAvailableAt!);
        }
      });
    } else {
      _update(() {
        _isPinInputLocked = false;
        _isLastChanceToTry = _authProvider.currentTurn + 1 == kMaxTurn;

        if (_isLastChanceToTry) {
          _errorMessage = t.errors.remaining_times_away_from_reset_error(
            count: kMaxAttemptPerTurn - _authProvider.currentAttemptInTurn,
          );
        }
      });
    }

    _update(() => _isVerifyingPin = true);
    try {
      final authenticated = await _authenticateWithBiometricsIfEligible();
      if (!mounted) return;
      if (authenticated) {
        await _handleAuthenticationSuccess();
      } else if (_shouldDelayKeyboard) {
        await _handleKeyboardFocus();
      }
    } catch (_) {
      if (mounted) _update(() => _errorMessage = t.errors.pin_processing_error);
    } finally {
      if (mounted) _update(() => _isVerifyingPin = false);
    }
  }

  Future<void> _handleKeyboardFocus() async {
    _update(() => _shouldDelayKeyboard = false);
    if (mounted) await onKeyboardFocus();
  }

  Future<bool> _authenticateWithBiometricsIfEligible() async {
    if (!_isAppLaunched ||
        _authProvider.isPermanentlyLocked ||
        _isPinInputLocked == true ||
        !_authProvider.isBiometricEnabled) {
      return false;
    }

    return await _authProvider.authenticateWithBiometrics();
  }

  Future<void> _onKeyTap(String value) async {
    if (_disposed || _isPinInputLocked != false || _isVerifyingPin || _isResetting) {
      return;
    }

    if (value == kBiometricIdentifier) {
      await _verifyBiometric();
      return;
    }

    _update(() {
      // 문자 입력 모드
      if (_pinType == PinType.character) {
        _pin = value;
        return;
      }

      // 6-digit PIN 입력 모드
      if (value == kDeleteBtnIdentifier) {
        if (_pin.isNotEmpty) {
          _pin = _pin.substring(0, _pin.length - 1);
        }
      } else if (_pin.length < kExpectedPinLength) {
        _pin += value;
        vibrateExtraLight();
      }
    });
    if ((_pinType == PinType.character && _pin.isNotEmpty) || _pin.length == kExpectedPinLength) {
      await _verifyPin();
    }
  }

  Future<void> _handleAuthenticationSuccess() async {
    if (!mounted) return;
    await _authProvider.resetAuthenticationState();
    if (mounted) await onSuccess();
  }

  Future<void> _verifyBiometric() async {
    _update(() => _isVerifyingPin = true);
    try {
      await verifyBiometrics();
    } catch (_) {
      if (mounted) _update(() => _errorMessage = t.errors.pin_processing_error);
    } finally {
      if (mounted) _update(() => _isVerifyingPin = false);
    }
  }

  Future<void> _verifyPin() async {
    if (_isVerifyingPin) return;
    _update(() {
      _isVerifyingPin = true;
    });
    bool isAuthenticated;
    try {
      isAuthenticated = await _authProvider.verifyPin(_pin, isAppLaunchScreen: _isAppLaunched);
    } catch (_) {
      if (mounted) {
        _update(() {
          _isVerifyingPin = false;
          _pin = '';
          _errorMessage = t.errors.pin_processing_error;
        });
      }
      return;
    }
    _pin = '';
    if (!mounted) return;
    if (mounted) {
      _update(() {
        _isVerifyingPin = false;
      });
    }
    if (isAuthenticated) {
      try {
        await _handleAuthenticationSuccess();
      } catch (_) {
        if (mounted) _update(() => _errorMessage = t.errors.pin_processing_error);
      }
      return;
    }

    await _handleAuthenticationFailure();
  }

  Future<void> _handleAuthenticationFailure() async {
    if (_isAppLaunched) {
      if (_authProvider.isPermanentlyLocked) {
        vibrateMedium();
        await _handlePermanentLockout();
        return;
      }

      if (_authProvider.remainingAttemptCount > 0 && _authProvider.remainingAttemptCount < kMaxAttemptPerTurn) {
        vibrateLightDouble();
        _update(() {
          final remainingTimes = _authProvider.remainingAttemptCount;
          _errorMessage =
              _isLastChanceToTry
                  ? t.errors.remaining_times_away_from_reset_error(count: remainingTimes)
                  : t.errors.pin_incorrect_with_remaining_attempts_error(count: remainingTimes);
        });
      } else {
        vibrateMedium();
        _update(() {
          _errorMessage = '';
          _isPinInputLocked = true;
        });

        final nextUnlockTime = _authProvider.unlockAvailableAt;
        if (nextUnlockTime != null) _startCountdownTimerUntil(nextUnlockTime);
      }
    } else {
      vibrateLightDouble();
      _update(() {
        _errorMessage = t.errors.pin_incorrect_error;
      });
    }

    _update(() {
      _pin = '';
      _shuffledPinNumbers = _authProvider.getShuffledNumberList();
    });
  }

  void _startCountdownTimerUntil(DateTime lockoutEndTime) {
    _countdown?.cancel();
    _countdown = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final remainingDuration = lockoutEndTime.difference(DateTime.now());
      final remainingSeconds = remainingDuration.inSeconds > 0 ? remainingDuration.inSeconds : 0;

      if (remainingSeconds == 0) {
        timer.cancel();
        _update(() {
          _errorMessage = '';
          _isPinInputLocked = false;
          _isLastChanceToTry = _authProvider.currentTurn + 1 == kMaxTurn;
        });
      } else {
        final formattedTime = _formatRemainingTime(remainingSeconds);
        _update(() {
          _errorMessage = t.errors.retry_after(time: formattedTime);
        });
      }
    });
  }

  String _formatRemainingTime(int remainingSeconds) {
    final hours = remainingSeconds ~/ 3600;
    final minutes = (remainingSeconds % 3600) ~/ 60;
    final seconds = remainingSeconds % 60;

    List<String> timeComponents = [];

    if (hours > 0) timeComponents.add('$hours${t.hour}');
    if (minutes > 0) timeComponents.add('$minutes${t.minute}');
    if (seconds > 0 || timeComponents.isEmpty) {
      timeComponents.add('$seconds${t.second}');
    }

    return timeComponents.join(' ');
  }

  Future<void> _clearPermanentLockAndGoHome() async {
    if (_isResetting) return;
    _update(() => _isResetting = true);
    try {
      await _authProvider.clearPermanentLock();
    } catch (_) {
      if (mounted) _update(() => _errorMessage = t.errors.pin_processing_error);
      return;
    } finally {
      if (mounted) _update(() => _isResetting = false);
    }
    if (!mounted) return;
    await onPermanentLockReset();
  }

  Future<void> _reset() async {
    if (_isResetting) return;
    _update(() => _isResetting = true);
    // PinCheckScreen은 appLaunch 플로우에서 사용되어 WalletProvider가 아직 트리에 없으므로 walletProvider 전달하지 않음.
    final preferenceProvider = getPreferenceProvider();
    while (mounted) {
      try {
        await ResetCredentialsAndWalletsUsecase.execute(
          authProvider: _authProvider,
          preferenceProvider: preferenceProvider,
        );

        if (!mounted) return;
        _update(() => _isResetting = false);
        await onReset();
        return;
      } catch (e) {
        if (!mounted) return;
        final shouldRetry = await onResetFailure(e);
        if (shouldRetry) continue;
        if (mounted) _update(() => _isResetting = false);
        return;
      }
    }
  }

  Future<void> _handlePermanentLockout() async {
    if (_isResetting) return;
    _update(() {
      _isLastChanceToTry = false;
      _errorMessage = t.errors.pin_max_attempts_exceeded_error;
      _isPinInputLocked = true;
      _isResetting = true;
    });
    // PinCheckScreen은 appLaunch 플로우에서 사용되어 WalletProvider가 아직 트리에 없으므로 walletProvider 전달하지 않음.
    final preferenceProvider = getPreferenceProvider();
    while (mounted) {
      try {
        await ResetCredentialsAndWalletsUsecase.execute(
          authProvider: _authProvider,
          preferenceProvider: preferenceProvider,
          preservePermanentLock: true,
        );

        if (!mounted) return;
        _update(() => _isResetting = false);
        await onPermanentlyLocked();
        return;
      } catch (e) {
        if (!mounted) return;
        final shouldRetry = await onResetFailure(e);
        if (shouldRetry) continue;
        if (mounted) _update(() => _isResetting = false);
        return;
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _countdown?.cancel();
    if (_authProvider.onAuthenticationSuccess == _handleAuthenticationSuccess) {
      _authProvider.onAuthenticationSuccess = null;
    }
    _pin = '';
    super.dispose();
  }
}
