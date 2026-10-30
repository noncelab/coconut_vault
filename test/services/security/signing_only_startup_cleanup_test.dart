import 'dart:async';

import 'package:coconut_vault/constants/method_channel.dart';
import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/providers/app_lifecycle_state_provider.dart';
import 'package:coconut_vault/providers/preference_provider.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const zoneChannel = MethodChannel(methodChannelSecureModule);
  const keysChannel = MethodChannel('onl.coconut.vault/secure_storage_keys');
  const valuesChannel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  for (final failure in ['secure zone', 'key enumeration', 'secure storage deletion']) {
    test('signing-only startup awaits cleanup and retries $failure failure', () async {
      const publicList = '[{"id":1,"vaultType":"singleSignature"}]';
      SharedPreferences.setMockInitialValues({
        SharedPrefsKeys.kVaultMode: 'signingOnly',
        SharedPrefsKeys.kVaultListField: publicList,
      });
      final prefs = SharedPrefsRepository();
      await prefs.init();
      final values = <String, String>{'test-wallet': 'encrypted'};
      var failing = true;
      var zoneCalls = 0;
      final gate = Completer<void>();
      messenger.setMockMethodCallHandler(zoneChannel, (call) async {
        expect(call.method, 'deleteKeys');
        zoneCalls++;
        await gate.future;
        return failing && failure == 'secure zone' ? call.arguments['aliasList'] : <String>[];
      });
      messenger.setMockMethodCallHandler(keysChannel, (_) async {
        if (failing && failure == 'key enumeration') throw PlatformException(code: 'KEYS_UNAVAILABLE');
        return values.keys.toList();
      });
      messenger.setMockMethodCallHandler(valuesChannel, (call) async {
        expect(call.method, 'delete');
        if (failing && failure == 'secure storage deletion') throw PlatformException(code: 'DELETE_FAILED');
        values.remove(call.arguments['key']);
        return null;
      });
      addTearDown(() {
        for (final channel in [zoneChannel, keysChannel, valuesChannel]) {
          messenger.setMockMethodCallHandler(channel, null);
        }
      });
      final preference = PreferenceProvider();
      final visibility = VisibilityProvider(isSigningOnlyMode: true);
      final lifecycle = AppLifecycleStateProvider();
      final provider = WalletProvider(visibility, preference, lifecycle);
      addTearDown(() {
        provider.dispose();
        preference.dispose();
        visibility.dispose();
      });
      await Future<void>.delayed(Duration.zero);
      expect(zoneCalls, 0, reason: 'Constructor must not launch unobserved cleanup');
      final load = provider.loadVaultList();
      expect(identical(provider.loadVaultList(), load), true);
      expect(provider.isVaultsLoaded, false);
      final failedLoad = expectLater(load, throwsA(anything));
      gate.complete();
      await failedLoad;
      expect(provider.isVaultsLoaded, false);
      expect(provider.isVaultListLoading, false);
      expect(prefs.getString(SharedPrefsKeys.kVaultListField), publicList);
      expect(values, isNotEmpty);

      failing = false;
      await provider.loadVaultList();
      expect(zoneCalls, 2);
      expect(provider.isVaultsLoaded, true);
      expect(provider.vaultList, isEmpty);
      expect(values, isEmpty);
      expect(prefs.getString(SharedPrefsKeys.kVaultListField), isEmpty);
      await provider.loadVaultList();
      expect(zoneCalls, 2, reason: 'Successful startup cleanup must run only once');
    });
  }
}
