import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:local_auth/local_auth.dart';
import 'package:coconut_vault/constants/method_channel.dart';
import 'package:coconut_vault/constants/shared_preferences_constants.dart';
import 'package:coconut_vault/services/secure_storage_service.dart';
import 'package:coconut_vault/utils/hash_util.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ignore: constant_identifier_names
const String VAULT_PIN = "VAULT_PIN";

enum ConnectivityState { off, on, bluetoothUnauthorized }

class AppModel with ChangeNotifier {
  AppModel({required this.onConnectivityStateChanged}) {
    setInitData(isSetListener: true);
  }

  /// ConnectActivity ----------------------------------------------------------
  bool? _isNetworkOn;
  bool? get isNetworkOn => _isNetworkOn;
  bool? _isBluetoothOn;
  bool? get isBluetoothOn => _isBluetoothOn;
  bool? _isBluetoothUnauthorized; // iOS only
  bool? get isBluetoothUnauthorized => _isBluetoothUnauthorized;
  bool? _isDeveloperModeOn =
      Platform.isAndroid && kReleaseMode ? null : false; // Android only
  bool? get isDeveloperModeOn => _isDeveloperModeOn;

  void Function(ConnectivityState) onConnectivityStateChanged;

  late StreamSubscription<BluetoothAdapterState> _bluetoothSubscription;
  late StreamSubscription<List<ConnectivityResult>> _networkSubscription;

  static const MethodChannel _channel = MethodChannel(methodChannelOS);

  _setConnectActivity() {
    // 블루투스 상태
    if (Platform.isIOS) {
      // showPowerAlert: false 설정 해줘야, 앱 재접속 시 블루투스 권한 없을 때 CBCentralManagerOptionShowPowerAlertKey 관련 prompt가 뜨지 않음
      FlutterBluePlus.setOptions(showPowerAlert: false).then((_) {
        _bluetoothSubscription =
            FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
          if (state == BluetoothAdapterState.on) {
            _isBluetoothOn = true;
          } else if (state == BluetoothAdapterState.off) {
            _isBluetoothOn = false;
          } else if (state == BluetoothAdapterState.unauthorized) {
            // iOS only
            _isBluetoothUnauthorized = true;
          }
          _onConnectivityChanged();
        });
      });
    } else if (Platform.isAndroid) {
      _bluetoothSubscription =
          FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
        if (state == BluetoothAdapterState.on) {
          _isBluetoothOn = true;
        } else if (state == BluetoothAdapterState.off) {
          _isBluetoothOn = false;
        }
        _onConnectivityChanged();
      });
    }

    // 네트워크 상태
    _networkSubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> result) {
      if (result.contains(ConnectivityResult.none)) {
        _isNetworkOn = false;
      } else {
        _isNetworkOn = true;
      }
      _onConnectivityChanged();
    });

    // 개발자모드 상태 확인, 릴리즈버전일 경우에만 상태체크
    if (Platform.isAndroid && kReleaseMode) {
      _checkDeveloperMode();

      // 개발자모드 상태 변화 감지
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'onDeveloperModeChanged') {
          _isDeveloperModeOn = call.arguments as bool? ?? false;
          _onConnectivityChanged();
        }
      });
    }
  }

  Future<void> _checkDeveloperMode() async {
    bool? developerModeStatus;
    try {
      final bool result = await _channel.invokeMethod('isDeveloperModeEnabled');
      developerModeStatus = result;
    } catch (e) {
      // 에러 발생 시 개발자 모드 OFF로 간주
      developerModeStatus = false;
    }
    _isDeveloperModeOn = developerModeStatus;
    _onConnectivityChanged();
  }

  void _onConnectivityChanged() {
    notifyListeners();
    if (_isBluetoothOn == true ||
        _isNetworkOn == true ||
        (Platform.isAndroid && _isDeveloperModeOn == true)) {
      if (_hasSeenGuide) {
        onConnectivityStateChanged.call(ConnectivityState.on);
      }
    } else if (_isBluetoothUnauthorized == true) {
      onConnectivityStateChanged.call(ConnectivityState.bluetoothUnauthorized);
    }
  }

  /// AuthState ----------------------------------------------------------------
  final SecureStorageService _storageService = SecureStorageService();
  final LocalAuthentication _auth = LocalAuthentication();

  /// 앱 첫 진입 여부
  bool _isPinEnabled = false;
  bool get isPinEnabled => _isPinEnabled;

  /// 비밀번호 설정 여부
  bool _hasSeenGuide = false;
  bool get hasSeenGuide => _hasSeenGuide;

  /// 디바이스 생체인증 활성화 여부
  bool _canCheckBiometrics = false;
  bool get canCheckBiometrics => _canCheckBiometrics;

  /// 사용자 생체 인증 on/off 여부
  bool _isBiometricEnabled = false;
  bool get isBiometricEnabled => _isBiometricEnabled;

  /// true = 핀 초기화 진행 후 홈 화면 설정창 노출
  bool _isResetVault = false;
  bool get isResetVault => _isResetVault;

  ///  지갑 생성 여부
  bool _isNotEmptyVaultList = false;
  bool get isNotEmptyVaultList => _isNotEmptyVaultList;

  /// 팬 or 생체인증 성공 여부
  bool _isAuthChecked = false;
  bool get isAuthChecked => _isAuthChecked;

  /// 로딩
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// 핀 입력 키
  List<String> _pinShuffleNumbers = [];
  List<String> get pinShuffleNumbers => _pinShuffleNumbers;

  Future setInitData({bool isSetListener = false}) async {
    await checkDeviceBiometrics();
    final prefs = await SharedPreferences.getInstance();
    _hasSeenGuide =
        prefs.getBool(SharedPreferencesConstants.hasShownStartGuide) == true;
    _isPinEnabled =
        prefs.getBool(SharedPreferencesConstants.isPinEnabled) == true;
    _isBiometricEnabled =
        prefs.getBool(SharedPreferencesConstants.isBiometricEnabled) == true;
    _isNotEmptyVaultList =
        prefs.getBool(SharedPreferencesConstants.isNotEmptyVaultList) == true;
    shuffleNumbers();

    if (isSetListener) _setConnectActivity();
  }

  /// 초기화 이후 홈화면 진입시 비밀번호 설정창 노출하기 위함
  void offResetVault() {
    _isResetVault = false;
  }

  /// 핀 or 생체인증 성공여부 변경
  void changeIsAuthChecked(bool check) {
    _isAuthChecked = check;
  }

  Future<void> setHasSeenGuide() async {
    final prefs = await SharedPreferences.getInstance();
    _hasSeenGuide = true;
    prefs.setBool(SharedPreferencesConstants.hasShownStartGuide, true);
    notifyListeners();
  }

  /// 기기의 생체인증 가능 여부 업데이트
  Future<void> checkDeviceBiometrics() async {
    final prefs = await SharedPreferences.getInstance();
    List<BiometricType> availableBiometrics = [];

    try {
      final isEnabledBiometrics = await _auth.canCheckBiometrics;
      availableBiometrics = await _auth.getAvailableBiometrics();

      _canCheckBiometrics =
          isEnabledBiometrics && availableBiometrics.isNotEmpty;

      prefs.setBool(
          SharedPreferencesConstants.canCheckBiometrics, _canCheckBiometrics);

      if (!_canCheckBiometrics) {
        _isBiometricEnabled = false;
        prefs.setBool(SharedPreferencesConstants.isBiometricEnabled, false);
      }

      notifyListeners();
    } on PlatformException catch (e) {
      // 생체 인식 기능 비활성화, 사용자가 권한 거부, 기기 하드웨어에 문제가 있는 경우, 기기 호환성 문제, 플랫폼 제한
      Logger.log(e);
      _canCheckBiometrics = false;
      prefs.setBool(SharedPreferencesConstants.canCheckBiometrics, false);
      _isBiometricEnabled = false;
      prefs.setBool(SharedPreferencesConstants.isBiometricEnabled, false);
      notifyListeners();
    }
  }

  /// 생체인증 진행 후 성공 여부 반환
  Future<bool> authenticateWithBiometrics({bool isSave = false}) async {
    bool authenticated = false;
    try {
      authenticated = await _auth.authenticate(
        localizedReason: '생체 인증을 진행해주세요',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (isSave) {
        saveIsBiometricEnabled(authenticated);
      }

      return authenticated;
    } on PlatformException catch (e) {
      Logger.log(e);
    }
    return false;
  }

  /// WalletList isNotEmpty 상태 저장
  Future<void> saveNotEmptyVaultList(bool isNotEmpty) async {
    _isNotEmptyVaultList = isNotEmpty;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
        SharedPreferencesConstants.isNotEmptyVaultList, isNotEmpty);
    notifyListeners();
  }

  /// 사용자 생체인증 활성화 여부 저장
  Future<void> saveIsBiometricEnabled(bool value) async {
    _isBiometricEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SharedPreferencesConstants.isBiometricEnabled, value);
    shuffleNumbers();
  }

  /// 비밀번호 저장
  Future<void> savePin(String pin) async {
    final prefs = await SharedPreferences.getInstance();

    if (_canCheckBiometrics && !_isPinEnabled) {
      _isBiometricEnabled = true;
      prefs.setBool(SharedPreferencesConstants.isBiometricEnabled, true);
    }

    String hashed = hashString(pin);
    await _storageService.write(key: VAULT_PIN, value: hashed);
    _isPinEnabled = true;
    prefs.setBool(SharedPreferencesConstants.isPinEnabled, true);
    shuffleNumbers();
  }

  /// 비밀번호 검증
  Future<bool> verifyPin(String inputPin) async {
    String hashedInput = hashString(inputPin);
    final savedPin = await _storageService.read(key: VAULT_PIN);
    return savedPin == hashedInput;
  }

  /// 비밀번호 초기화
  Future<void> resetPassword() async {
    _isResetVault = true;
    _isBiometricEnabled = false;
    _isNotEmptyVaultList = false;
    _isPinEnabled = false;

    await _storageService.delete(key: VAULT_PIN);
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(SharedPreferencesConstants.isBiometricEnabled, false);
    prefs.setBool(SharedPreferencesConstants.isPinEnabled, false);
    prefs.setBool(SharedPreferencesConstants.isNotEmptyVaultList, false);
  }

  void showIndicator() {
    _isLoading = true;
    notifyListeners();
  }

  void hideIndicator() {
    _isLoading = false;
    notifyListeners();
  }

  void shuffleNumbers({isSettings = false}) {
    final random = Random();
    _pinShuffleNumbers = List<String>.generate(10, (index) => index.toString());
    _pinShuffleNumbers.shuffle(random);
    _pinShuffleNumbers.insert(_pinShuffleNumbers.length - 1,
        !isSettings && _isBiometricEnabled ? 'bio' : '');
    _pinShuffleNumbers.add('<');
    notifyListeners();
  }

  // Be sure to cancel subscription after you are done
  @override
  void dispose() {
    _bluetoothSubscription.cancel();
    _networkSubscription.cancel();
    super.dispose();
  }
}
