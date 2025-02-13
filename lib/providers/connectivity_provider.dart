import 'dart:async';
import 'dart:io';

import 'package:coconut_vault/constants/method_channel.dart';
import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

enum ConnectivityState { off, on, bluetoothUnauthorized }

class ConnectivityProvider extends ChangeNotifier {
  bool? _isNetworkOn;
  bool? get isNetworkOn => _isNetworkOn;
  bool? _isBluetoothOn;
  bool? get isBluetoothOn => _isBluetoothOn;
  bool? _isBluetoothUnauthorized; // iOS only
  bool? get isBluetoothUnauthorized => _isBluetoothUnauthorized;
  bool? _isDeveloperModeOn =
      Platform.isAndroid && kReleaseMode ? null : false; // Android only
  bool? get isDeveloperModeOn => _isDeveloperModeOn;

  late StreamSubscription<BluetoothAdapterState> _bluetoothSubscription;
  late StreamSubscription<List<ConnectivityResult>> _networkSubscription;

  static const MethodChannel _channel = MethodChannel(methodChannelOS);

  void Function(ConnectivityState) onConnectivityStateChanged;

  ConnectivityProvider({required this.onConnectivityStateChanged}) {
    setInitData();
  }

  Future setInitData() async {
    setConnectActivity(network: true, bluetooth: false, developerMode: true);
  }

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
      SharedPrefsRepository().setBool(
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
      // if (_hasSeenGuide) {
      //   onConnectivityStateChanged.call(ConnectivityState.on);
      // }
    }
    notifyListeners();
  }
}
