import 'package:flutter/foundation.dart';
import 'package:coconut_vault/constants/pin_constants.dart';
import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:coconut_vault/utils/vibration_util.dart';
import 'package:coconut_vault/widgets/pin/pin_length_toggle_button.dart';

class PinSettingViewModel extends ChangeNotifier {
  final AuthProvider _authProvider;
  final Future<bool> Function() authenticateBiometrics;
  final Future<void> Function() noticeBiometrics;
  final Future<void> Function() onSaved;
  final VoidCallback onBeforeSave;
  final VoidCallback onProcessingEnd;
  bool _disposed = false;
  bool get mounted => !_disposed;
  bool _greeting;
  int _step = 0;
  String _pin = '';
  String _pinConfirm = '';
  String _errorMessage = '';
  PinType _currentPinType;
  bool _isProcessing = false;
  List<String> _shuffledPinNumbers;
  PinSettingViewModel({
    required AuthProvider authProvider,
    required bool greetingVisible,
    required this.authenticateBiometrics,
    required this.noticeBiometrics,
    required this.onSaved,
    required this.onBeforeSave,
    required this.onProcessingEnd,
  }) : _authProvider = authProvider,
       _greeting = greetingVisible,
       _currentPinType = authProvider.isPinCharacter ? PinType.character : PinType.number,
       _shuffledPinNumbers = authProvider.getShuffledNumberList(isPinSettingContext: true);
  bool get greeting => _greeting;
  int get step => _step;
  String get pin => _pin;
  String get pinConfirm => _pinConfirm;
  String get errorMessage => _errorMessage;
  PinType get currentPinType => _currentPinType;
  bool get isProcessing => _isProcessing;
  List<String> get shuffledPinNumbers => List.unmodifiable(_shuffledPinNumbers);
  void dismissGreeting() => _update(() => _greeting = false);
  void clearPin() {
    if (_disposed || _isProcessing) return;
    _update(() {
      if (_step == 0) {
        _pin = '';
      } else {
        _pinConfirm = '';
      }
    });
  }

  void _update(VoidCallback update) {
    if (_disposed) return;
    update();
    if (!_disposed) notifyListeners();
  }

  void returnToBackSequence(String message, {bool isError = false, bool firstSequence = false}) {
    _update(() {
      _errorMessage = message;
      onProcessingEnd();
      _isProcessing = false;
      _pinConfirm = '';

      _shuffledPinNumbers = _authProvider.getShuffledNumberList(isPinSettingContext: true);
      if (firstSequence) {
        _step = 0;
        _pin = '';
      }
    });

    if (isError) {
      vibrateMedium();
    } else {
      vibrateLightDouble();
    }
  }

  Future<bool> _comparePin(String input) async {
    bool isSamePin = await _authProvider.verifyPin(input);
    return isSamePin;
  }

  // 입력 모드 변경 핸들러 추가: 입력 모드가 변경되면 입력값 초기화
  void onPinTypeChanged(PinType newPinType) {
    if (_disposed || _isProcessing) return;
    _update(() {
      _currentPinType = newPinType;
      _pin = '';
      _pinConfirm = '';
      _errorMessage = '';
      if (_step == 1) {
        _step = 0;
      }
    });
  }

  Future<void> onKeyTap(String value) async {
    if (_disposed || _isProcessing) return;
    if (_currentPinType == PinType.character) {
      // 문자 입력 모드에서 'Done' 버튼을 누르는 경우
      await _onPressDoneKey(value);
    } else {
      await _onKeyTapNumber(value);
    }
  }

  Future<void> _onPressDoneKey(String value) async {
    if (_step == 0) {
      _pin = value;

      if (_pin.isNotEmpty) {
        await _proceedToNextStep();
      }
    } else {
      _pinConfirm = value;

      if (_pinConfirm.isNotEmpty) {
        await _finalizePinSetup();
      }
    }
  }

  Future<void> _proceedToNextStep() async {
    if (_isProcessing) return;
    _update(() => _isProcessing = true);
    try {
      bool isAlreadyUsingPin = await _comparePin(_pin);
      if (!mounted) return;

      if (isAlreadyUsingPin) {
        returnToBackSequence(t.errors.duplicate_pin_error, firstSequence: true);
        return;
      }
    } catch (error) {
      if (!mounted) return;
      returnToBackSequence(t.errors.pin_processing_error, isError: true);
      return;
    }
    _update(() {
      _isProcessing = false;
      _step = 1;
      _errorMessage = '';
      if (_currentPinType == PinType.number) {
        _shuffledPinNumbers = _authProvider.getShuffledNumberList(isPinSettingContext: true);
      }
    });
  }

  /// 비밀번호 일치 여부 확인 후 저장
  /// 비밀번호 최초 설정 시 생체 인증 사용 여부 확인
  Future<void> _finalizePinSetup() async {
    if (_pin != _pinConfirm) {
      _update(() {
        _errorMessage = t.errors.pin_incorrect_error;
        _pinConfirm = '';
        if (_currentPinType == PinType.number) {
          _shuffledPinNumbers = _authProvider.getShuffledNumberList(isPinSettingContext: true);
        }
      });
      vibrateLightDouble();
      return;
    }

    _update(() {
      _errorMessage = '';
      onBeforeSave();
      _isProcessing = true;
    });

    try {
      // 생체 인증 사용 여부 확인
      bool isPinSet = SharedPrefsRepository().getBool(SharedPrefsKeys.isPinEnabled) ?? false;
      if (!isPinSet &&
          _authProvider.isBiometricSupportedByDevice &&
          _authProvider.availableBiometrics.isNotEmpty &&
          mounted) {
        final useBiometrics = await authenticateBiometrics();
        if (!mounted) return;
        if (!useBiometrics) {
          await noticeBiometrics();
        }
      }

      if (!mounted) return;

      // 비밀번호 저장 후 화면 이동
      await _savePin();
    } catch (_) {
      if (mounted) returnToBackSequence(t.errors.pin_processing_error, isError: true, firstSequence: true);
    }
  }

  // 숫자 모드 PIN 입력 처리
  Future<void> _onKeyTapNumber(String value) async {
    String currentPin = _step == 0 ? _pin : _pinConfirm;

    if (value == kDeleteBtnIdentifier) {
      if (currentPin.isNotEmpty) {
        currentPin = currentPin.substring(0, currentPin.length - 1);
      }
    } else if (currentPin.length < kExpectedPinLength) {
      currentPin += value;
      vibrateExtraLight();
    }

    _update(() {
      if (_step == 0) {
        _pin = currentPin;
      } else {
        _pinConfirm = currentPin;
      }
    });

    if (currentPin.length == kExpectedPinLength) {
      if (_step == 0) {
        await _proceedToNextStep();
      } else {
        await _finalizePinSetup();
      }
    }
  }

  Future<void> _savePin() async {
    try {
      await _authProvider.savePin(_pinConfirm, _currentPinType == PinType.character);
    } catch (_) {
      if (mounted) returnToBackSequence(t.errors.pin_processing_error, isError: true, firstSequence: true);
      return;
    }
    _pin = '';
    _pinConfirm = '';
    if (mounted) await onSaved();
  }

  @override
  void dispose() {
    _disposed = true;
    _pin = '';
    _pinConfirm = '';
    super.dispose();
  }
}
