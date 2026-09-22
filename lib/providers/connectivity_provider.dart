import 'dart:async';
import 'dart:io';

import 'package:coconut_vault/constants/method_channel.dart';
import 'package:coconut_vault/screens/common/app_unavailable_notification_screen.dart';
import 'package:coconut_vault/screens/common/ios_bluetooth_auth_notification_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

enum ConnectivityState { off, on, bluetoothUnauthorized }

class ConnectivityProvider extends ChangeNotifier {
  /// 첫 실행 가이드 확인 여부
  late bool _hasSeenGuide;
  bool _isDisposed = false;

  bool? _isNetworkOn;
  bool? get isNetworkOn => _isNetworkOn;
  bool? _isBluetoothOn;
  bool? get isBluetoothOn => _isBluetoothOn;
  bool? _isBluetoothUnauthorized; // iOS only
  bool? get isBluetoothUnauthorized => _isBluetoothUnauthorized;
  bool? _isDeveloperModeOn = Platform.isAndroid && kReleaseMode ? null : false; // Android only
  bool? get isDeveloperModeOn => _isDeveloperModeOn;

  /// 블루투스 권한이 거부되어 자동으로 상태를 확인할 수 없을 때,
  /// 사용자가 직접 블루투스가 꺼져 있음을 확인했는지 여부를 기록 (세션 동안만 유지)
  bool _isBluetoothManuallyConfirmedOff = false;
  bool get isBluetoothManuallyConfirmedOff => _isBluetoothManuallyConfirmedOff;

  void setBluetoothManuallyConfirmedOff(bool isConfirmed) {
    _isBluetoothManuallyConfirmedOff = isConfirmed;
    notifyListeners();
  }

  /// 권한이 거부됐거나(unauthorized),
  /// 사용자가 권한 요청을 취소해 한 번도 확인되지 않은 경우 (isBluetoothOn == null)
  /// 사용자의 수동 확인 여부로 안전을 판단함.
  /// 권한이 있어 실제로 확인된 경우에만 감지 결과를 그대로 사용함.
  bool get isBluetoothSafe =>
      (_isBluetoothUnauthorized == true || _isBluetoothOn == null)
          ? _isBluetoothManuallyConfirmedOff
          : _isBluetoothOn == false;

  void Function(ConnectivityState)? onConnectivityStateChanged;

  StreamSubscription<BluetoothAdapterState>? _bluetoothSubscription;
  StreamSubscription<List<ConnectivityResult>>? _networkSubscription;

  static const MethodChannel _channel = MethodChannel(methodChannelOS);

  ConnectivityProvider({required bool hasSeenGuide, this.onConnectivityStateChanged}) : _hasSeenGuide = hasSeenGuide {
    if (_hasSeenGuide) {
      setConnectActivity(network: true, bluetooth: true, developerMode: true);
    } else {
      // 앱 첫 실행인 경우 가이드 화면 끝난 후 welcome_screen에서 bluetooth 권한 요청 후 모니터링 시작.
      setConnectActivity(network: true, bluetooth: false, developerMode: true);
    }
  }

  /// 보안상의 이유로 기기가 네트워크, 블루투스, 개발자 모드가 켜져있을 때 볼트 사용을 막아야 합니다.
  /// 따라서 위 요소들의 상태를 모니터링합니다.
  /// 앱 실행 후 최초 1번만 구독 되도록 호출해야 합니다. (! 별도 체크 로직은 없음)
  ///
  /// 매개변수로 모니터링 할 요소를 선택할 수 있습니다.
  ///
  /// * 단, iOS에서는 개발자모드 여부를 제공하지 않기 때문에 제외합니다.
  /// TODO: 리팩토링 필요함
  Future<void> setConnectActivity({required bool network, required bool bluetooth, required bool developerMode}) async {
    if (bluetooth) {
      // 현재 블루투스 상태 즉시 확인
      await _checkCurrentBluetoothState();

      // 블루투스 상태
      if (Platform.isIOS) {
        // showPowerAlert: false 설정 해줘야, 앱 재접속 시 블루투스 권한 없을 때 CBCentralManagerOptionShowPowerAlertKey 관련 prompt가 뜨지 않음
        FlutterBluePlus.setOptions(showPowerAlert: false).then((_) {
          _bluetoothSubscription = FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
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
        _bluetoothSubscription = FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
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
      _networkSubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) {
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
    if (_isDisposed) return;

    bool? developerModeStatus;
    try {
      final bool result = await _channel.invokeMethod('isDeveloperModeEnabled');
      developerModeStatus = result;
    } catch (e) {
      // 에러 발생 시 개발자 모드 OFF로 간주
      developerModeStatus = false;
    }

    if (_isDisposed) return; // 비동기 작업 후 다시 체크

    _isDeveloperModeOn = developerModeStatus;
    _onConnectivityChanged();
  }

  /// 현재 블루투스 상태를 즉시 확인하는 메서드
  Future<void> _checkCurrentBluetoothState() async {
    if (_isDisposed) return;

    try {
      final BluetoothAdapterState state = await FlutterBluePlus.adapterState.first;
      if (state == BluetoothAdapterState.on) {
        _isBluetoothOn = true;
      } else if (state == BluetoothAdapterState.off) {
        _isBluetoothOn = false;
      } else if (state == BluetoothAdapterState.unauthorized) {
        _isBluetoothUnauthorized = true;
        _isBluetoothOn = false;
      } else {
        _isBluetoothOn = false;
      }

      if (_isDisposed) return; // 비동기 작업 후 다시 체크

      // 상태 설정 후 즉시 UI 업데이트
      notifyListeners();
    } catch (e) {
      if (_isDisposed) return; // 에러 처리 후에도 체크

      // 에러 발생 시 블루투스 OFF로 간주
      _isBluetoothOn = false;
      notifyListeners();
    }
  }

  void _onConnectivityChanged() {
    if (_isDisposed) return;

    // 최초 온보딩(welcome_screen)에서는 설명 다이얼로그 → 사용자가 직접 요청/취소를 선택하는 플로우로 권한을 요청한다.
    // 이 전체화면 차단 화면은 온보딩을 이미 마친 재진입 시에만 동작한다.
    if (_hasSeenGuide) {
      if (Platform.isIOS && _isBluetoothUnauthorized == true) {
        runApp(const CupertinoApp(debugShowCheckedModeBanner: false, home: IosBluetoothAuthNotificationScreen()));
      } else if (_isBluetoothOn == true || _isNetworkOn == true || (Platform.isAndroid && _isDeveloperModeOn == true)) {
        runApp(
          CupertinoApp(
            debugShowCheckedModeBanner: false,
            home: AppUnavailableNotificationScreen(
              isNetworkOn: _isNetworkOn,
              isBluetoothOn: _isBluetoothOn,
              isDeveloperModeOn: _isDeveloperModeOn,
            ),
          ),
        );
      }
    }
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  void setOnConnectivityStateChanged(void Function(ConnectivityState) onChanged) {
    onConnectivityStateChanged = onChanged;
  }

  void setHasSeenGuideTrue() {
    _hasSeenGuide = true;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _bluetoothSubscription?.cancel();
    _networkSubscription?.cancel();
    super.dispose();
  }
}
