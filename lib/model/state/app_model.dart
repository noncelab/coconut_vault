import 'dart:async';
import 'dart:math';

import 'package:coconut_vault/services/shared_preferences_keys.dart';
import 'package:coconut_vault/services/shared_preferences_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:coconut_vault/services/secure_storage_service.dart';
import 'package:coconut_vault/utils/hash_util.dart';
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
  bool? _isDeveloperModeOn = false; // Android only
  bool? get isDeveloperModeOn => _isDeveloperModeOn;

  void Function(ConnectivityState) onConnectivityStateChanged;

  late StreamSubscription<BluetoothAdapterState> _bluetoothSubscription;
  late StreamSubscription<List<ConnectivityResult>> _networkSubscription;

  /// AuthState ----------------------------------------------------------------
  final SecureStorageService _storageService = SecureStorageService();

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

  /// true = 핀 초기화 진행 후 홈 화면 설정창 노출
  bool _isResetVault = false;
  bool get isResetVault => _isResetVault;

  ///  생성된 지갑 개수
  int _vaultListLength = 0;
  int get vaultListLength => _vaultListLength;

  /// 로딩
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// 핀 입력 키
  List<String> _pinShuffleNumbers = [];
  List<String> get pinShuffleNumbers => _pinShuffleNumbers;

  Future setInitData() async {
    final prefs = SharedPrefsService();
    _hasSeenGuide = prefs.getBool(SharedPrefsKeys.hasShownStartGuide) == true;
    _isPinEnabled = prefs.getBool(SharedPrefsKeys.isPinEnabled) == true;
    _vaultListLength = prefs.getInt(SharedPrefsKeys.vaultListLength) ?? 0;
    _hasAlreadyRequestedBioPermission =
        prefs.getBool(SharedPrefsKeys.hasAlreadyRequestedBioPermission) == true;
    shuffleNumbers();

    /// true 인 경우, 첫 실행이 아님
    if (_hasSeenGuide) {
      //setConnectActivity(network: true, bluetooth: true, developerMode: true);
    } else {
      // 앱 첫 실행인 경우 가이드 화면 끝난 후 bluetooth 모니터링 시작.
      //setConnectActivity(network: true, bluetooth: false, developerMode: true);
    }
  }

  /// 초기화 이후 홈화면 진입시 비밀번`호 설정창 노출하기 위함
  void offResetVault() {
    _isResetVault = false;
  }

  Future<void> setHasSeenGuide() async {
    _hasSeenGuide = true;
    SharedPrefsService().setBool(SharedPrefsKeys.hasShownStartGuide, true);
    notifyListeners();
  }

  /// WalletList isNotEmpty 상태 저장
  Future<void> saveVaultListLength(int length) async {
    _vaultListLength = length;
    await SharedPrefsService().setInt(SharedPrefsKeys.vaultListLength, length);
    notifyListeners();
  }

  /// 비밀번호 저장
  Future<void> savePin(String pin) async {
    final prefs = SharedPrefsService();

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
    _isPinEnabled = false;
    _vaultListLength = 0;

    await _storageService.delete(key: VAULT_PIN);
    final prefs = SharedPrefsService();
    prefs.setBool(SharedPrefsKeys.isBiometricEnabled, false);
    prefs.setBool(SharedPrefsKeys.isPinEnabled, false);
    prefs.setInt(SharedPrefsKeys.vaultListLength, 0);
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
    _pinShuffleNumbers.insert(_pinShuffleNumbers.length - 1, '');

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
