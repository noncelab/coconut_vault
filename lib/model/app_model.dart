import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:coconut_vault/services/shared_preferences_keys.dart';
import 'package:coconut_vault/services/shared_preferences_service.dart';
import 'package:coconut_vault/styles.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:local_auth/local_auth.dart';
import 'package:coconut_vault/constants/method_channel.dart';
import 'package:coconut_vault/services/secure_storage_service.dart';
import 'package:coconut_vault/utils/hash_util.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:url_launcher/url_launcher.dart';

// ignore: constant_identifier_names
const String VAULT_PIN = "VAULT_PIN";

enum ConnectivityState { off, on, bluetoothUnauthorized }

class AppModel with ChangeNotifier {
  AppModel({required this.onConnectivityStateChanged}) {
    setInitData();
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

  /// 보안상의 이유로 기기가 네트워크, 블루투스, 개발자 모드가 켜져있을 때 볼트 사용을 막아야 합니다.
  /// 따라서 위 요소들의 상태를 모니터링합니다.
  /// 앱 실행 후 최초 1번만 구독 되도록 호출해야 합니다. (! 별도 체크 로직은 없음)
  ///
  /// 매개변수로 모니터링 할 요소를 선택할 수 있습니다.
  ///
  /// * 단, iOS에서는 개발자모드 여부를 제공하지 않기 때문에 제외합니다.
  void setConnectActivity(
      {required bool network,
      required bool bluetooth,
      required bool developerMode}) {
    if (bluetooth) {
      SharedPrefsService().setBool(
          SharedPrefsKeys.hasAlreadyRequestedBluetoothPermission, true);
      // 블루투스 상태
      if (Platform.isIOS) {
        // showPowerAlert: false 설정 해줘야, 앱 재접속 시 블루투스 권한 없을 때 CBCentralManagerOptionShowPowerAlertKey 관련 prompt가 뜨지 않음
        FlutterBluePlus.setOptions(showPowerAlert: false).then((_) {
          _bluetoothSubscription = FlutterBluePlus.adapterState
              .listen((BluetoothAdapterState state) {
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
    }

    // 네트워크 상태
    if (network) {
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
    }

    // 개발자모드 상태 확인, 릴리즈버전일 경우에만 상태체크
    if (developerMode && Platform.isAndroid && kReleaseMode) {
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
    if (Platform.isIOS && _isBluetoothUnauthorized == true) {
      onConnectivityStateChanged.call(ConnectivityState.bluetoothUnauthorized);
    } else if (_isBluetoothOn == true ||
        _isNetworkOn == true ||
        (Platform.isAndroid && _isDeveloperModeOn == true)) {
      if (_hasSeenGuide) {
        onConnectivityStateChanged.call(ConnectivityState.on);
      }
    }
    notifyListeners();
  }

  /// AuthState ----------------------------------------------------------------
  final SecureStorageService _storageService = SecureStorageService();
  final LocalAuthentication _auth = LocalAuthentication();

  /// 비밀번호 설정 여부
  bool _isPinEnabled = false;
  bool get isPinEnabled => _isPinEnabled;

  /// 리셋 여부
  bool _hasAlreadyRequestedBioPermission = false;
  bool get hasAlreadyRequestedBioPermission =>
      _hasAlreadyRequestedBioPermission;

  /// 첫 실행 가이드 확인 여부
  bool _hasSeenGuide = false;
  bool get hasSeenGuide => _hasSeenGuide;

  /// 디바이스 생체인증 활성화 여부
  bool _canCheckBiometrics = false;
  bool get canCheckBiometrics => _canCheckBiometrics;

  /// 사용자 생체 인증 on/off 여부
  bool _isBiometricEnabled = false;
  bool get isBiometricEnabled => _isBiometricEnabled;

  /// 사용자 생체인증 권한 허용 여부
  bool _hasBiometricsPermission = false;
  bool get hasBiometricsPermission => _hasBiometricsPermission;

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

  Future setInitData() async {
    await checkDeviceBiometrics();
    final prefs = SharedPrefsService();
    _hasSeenGuide = prefs.getBool(SharedPrefsKeys.hasShownStartGuide) == true;
    _isPinEnabled = prefs.getBool(SharedPrefsKeys.isPinEnabled) == true;
    _isBiometricEnabled =
        prefs.getBool(SharedPrefsKeys.isBiometricEnabled) == true;
    _hasBiometricsPermission =
        prefs.getBool(SharedPrefsKeys.hasBiometricsPermission) == true;
    _isNotEmptyVaultList =
        prefs.getBool(SharedPrefsKeys.isNotEmptyVaultList) == true;
    _hasAlreadyRequestedBioPermission =
        prefs.getBool(SharedPrefsKeys.hasAlreadyRequestedBioPermission) == true;
    shuffleNumbers();

    /// true 인 경우, 첫 실행이 아님
    if (_hasSeenGuide) {
      setConnectActivity(network: true, bluetooth: true, developerMode: true);
    } else {
      // 앱 첫 실행인 경우 가이드 화면 끝난 후 bluetooth 모니터링 시작.
      setConnectActivity(network: true, bluetooth: false, developerMode: true);
    }
  }

  /// 초기화 이후 홈화면 진입시 비밀번`호 설정창 노출하기 위함
  void offResetVault() {
    _isResetVault = false;
  }

  /// 핀 or 생체인증 성공여부 변경
  void changeIsAuthChecked(bool check) {
    _isAuthChecked = check;
  }

  Future<void> setHasSeenGuide() async {
    _hasSeenGuide = true;
    SharedPrefsService().setBool(SharedPrefsKeys.hasShownStartGuide, true);
    notifyListeners();
  }

  /// 기기의 생체인증 가능 여부 업데이트
  Future<void> checkDeviceBiometrics() async {
    final prefs = SharedPrefsService();
    List<BiometricType> availableBiometrics = [];

    try {
      final isEnabledBiometrics = await _auth.canCheckBiometrics;
      availableBiometrics = await _auth.getAvailableBiometrics();

      _canCheckBiometrics =
          isEnabledBiometrics && availableBiometrics.isNotEmpty;

      prefs.setBool(SharedPrefsKeys.canCheckBiometrics, _canCheckBiometrics);

      if (!_canCheckBiometrics) {
        _isBiometricEnabled = false;
        prefs.setBool(SharedPrefsKeys.isBiometricEnabled, false);
      }

      notifyListeners();
    } on PlatformException catch (e) {
      // 생체 인식 기능 비활성화, 사용자가 권한 거부, 기기 하드웨어에 문제가 있는 경우, 기기 호환성 문제, 플랫폼 제한
      Logger.log(e);
      _canCheckBiometrics = false;
      prefs.setBool(SharedPrefsKeys.canCheckBiometrics, false);
      _isBiometricEnabled = false;
      prefs.setBool(SharedPrefsKeys.isBiometricEnabled, false);
      notifyListeners();
    }
  }

  /// 생체인증 진행 후 성공 여부 반환
  Future<bool> authenticateWithBiometrics(BuildContext context,
      {bool showAuthenticationFailedDialog = true, bool isSave = false}) async {
    bool authenticated = false;
    try {
      authenticated = await _auth.authenticate(
        localizedReason:
            '잠금 해제 시 생체 인증을 사용하시겠습니까?', // 이 문구는 aos, iOS(touch ID)에서 사용됩니다. ios face ID는 info.plist string을 사용합니다.
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (Platform.isIOS && !authenticated) {
        if (context.mounted) {
          await _showAuthenticationFailedDialog(context);
        }
      }

      if (isSave) {
        saveIsBiometricEnabled(authenticated);
        _setBioRequestedInSharedPrefs();
      }

      return authenticated;
    } on PlatformException catch (e) {
      Logger.log(e);

      if (isSave) {
        saveIsBiometricEnabled(false);
        if (Platform.isIOS &&
            !authenticated &&
            e.message == 'Biometry is not available.' &&
            showAuthenticationFailedDialog) {
          if (context.mounted) {
            await _showAuthenticationFailedDialog(context);
          }
        }
        _setBioRequestedInSharedPrefs();
      }
    }
    return false;
  }

  /// WalletList isNotEmpty 상태 저장
  Future<void> saveNotEmptyVaultList(bool isNotEmpty) async {
    _isNotEmptyVaultList = isNotEmpty;
    await SharedPrefsService()
        .setBool(SharedPrefsKeys.isNotEmptyVaultList, isNotEmpty);
    notifyListeners();
  }

  /// 사용자 생체인증 활성화 여부 저장
  Future<void> saveIsBiometricEnabled(bool value) async {
    _isBiometricEnabled = value;
    _hasBiometricsPermission = value;
    final prefs = SharedPrefsService();
    await prefs.setBool(SharedPrefsKeys.isBiometricEnabled, value);
    await prefs.setBool(SharedPrefsKeys.hasBiometricsPermission, value);
    shuffleNumbers();
  }

  Future<void> _setBioRequestedInSharedPrefs() async {
    _hasAlreadyRequestedBioPermission = true;
    await SharedPrefsService()
        .setBool(SharedPrefsKeys.hasAlreadyRequestedBioPermission, true);
  }

  /// 비밀번호 저장
  Future<void> savePin(String pin) async {
    final prefs = SharedPrefsService();

    if (_canCheckBiometrics && !_isPinEnabled) {
      _isBiometricEnabled = true;
      prefs.setBool(SharedPrefsKeys.isBiometricEnabled, true);
    }

    String hashed = hashString(pin);
    await _storageService.write(key: VAULT_PIN, value: hashed);
    _isPinEnabled = true;
    prefs.setBool(SharedPrefsKeys.isPinEnabled, true);
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
    final prefs = SharedPrefsService();
    prefs.setBool(SharedPrefsKeys.isBiometricEnabled, false);
    prefs.setBool(SharedPrefsKeys.isPinEnabled, false);
    prefs.setBool(SharedPrefsKeys.isNotEmptyVaultList, false);
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

  Future<void> _openAppSettings() async {
    const url = 'app-settings:';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  Future<void> _showAuthenticationFailedDialog(BuildContext context) async {
    await showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text(
            _hasAlreadyRequestedBioPermission == true
                ? '생체 인증 권한이 필요합니다'
                : '생체 인증 권한이 거부되었습니다',
            style: const TextStyle(
              color: MyColors.black,
            ),
          ),
          content: const Text(
            '생체 인증을 통한 잠금 해제를 하시려면\n설정 > 코코넛 볼트에서 생체 인증 권한을 허용해 주세요.',
            style: TextStyle(
              color: MyColors.black,
            ),
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: Text(
                '닫기',
                style: Styles.label.merge(
                  const TextStyle(
                    color: MyColors.black,
                  ),
                ),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
              },
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: Text(
                '설정화면으로 이동',
                style: Styles.label.merge(
                  const TextStyle(
                      color: Colors.blueAccent, fontWeight: FontWeight.bold),
                ),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                await _openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }

  // Be sure to cancel subscription after you are done
  @override
  void dispose() {
    _bluetoothSubscription.cancel();
    _networkSubscription.cancel();
    super.dispose();
  }
}
