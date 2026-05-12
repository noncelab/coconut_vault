import 'dart:convert';

import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/repository/secure_storage_repository.dart';
import 'package:coconut_vault/repository/secure_zone_repository.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:coconut_vault/repository/wallet_persistence_strategy/wallet_persistence_strategy.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:flutter/services.dart';

/// [WalletRepository]의 인스턴스 없이도 호출 가능한 정적 삭제 유틸.
///
/// 앱 초기화 실패 등 `WalletRepository`가 준비되지 않은 상태에서도 저장된
/// 모든 wallet 관련 데이터(Secure Zone alias, Flutter Secure Storage, SharedPrefs 메타)를 정리할 수 있도록
/// 전용 클래스로 분리되었습니다.
class WalletStorageCleaner {
  WalletStorageCleaner._();

  /// 저장된 모든 wallet 데이터(SZR 키, FSS 항목, SharedPrefs 메타)를 삭제합니다.
  ///
  /// [walletKeys]가 주어지면 SZR 삭제 대상으로 그대로 사용합니다.
  /// null이면 SharedPrefs의 공개 vault 목록(`kVaultListField`)에서 wallet key를 복구합니다.
  static Future<void> clearAll({List<VaultListItemBase>? wallets}) async {
    final sharedPrefs = SharedPrefsRepository();

    final List<String> keys;
    if (wallets != null) {
      keys = extractWalletKeysFromWalletList(wallets);
      Logger.log('--> [WalletStorageCleaner] clearAll: wallets keys=$keys');
    } else {
      final jsonArrayString = sharedPrefs.getString(SharedPrefsKeys.kVaultListField);
      Logger.log('--> [WalletStorageCleaner] clearAll: jsonArrayString=$jsonArrayString');
      keys = extractWalletKeysFromPublicJson(jsonArrayString);
    }

    await _deleteSecureZoneKeys(keys);
    await _deleteSecureStorage();
    await _deleteSharedPrefsMeta(sharedPrefs);
  }

  /// 공개 vault list JSON(`SharedPrefsKeys.kVaultListField`에 저장된 문자열)에서
  /// multisig가 아닌 항목의 wallet storage key 리스트를 추출합니다.
  static List<String> extractWalletKeysFromPublicJson(String jsonArray) {
    if (jsonArray.isEmpty || jsonArray == '[]') return const [];
    try {
      final decoded = jsonDecode(jsonArray);
      if (decoded is! List) {
        Logger.error('--> ❌ vaultList JSON이 List 아님 (${decoded.runtimeType})');
        return const [];
      }
      return decoded
          .whereType<Map>()
          .map((m) {
            final id = m['id'];
            final typeName = m[VaultListItemBase.vaultTypeField];
            if (id is! int || typeName is! String) return null;
            final type = WalletType.fromName(typeName);
            if (type == null || type == WalletType.multiSignature) return null;
            return WalletStorageKeys.walletKey(id, type);
          })
          .whereType<String>()
          .toList();
    } on FormatException catch (_) {
      Logger.error('--> ❌ vaultList JSON parse 실패');
      return const [];
    }
  }

  /// 인메모리 wallet 리스트에서 multisig가 아닌 항목의 wallet storage key 리스트를 추출합니다.
  static List<String> extractWalletKeysFromWalletList(List<VaultListItemBase> walletList) {
    return walletList
        .where((wallet) => wallet.vaultType != WalletType.multiSignature)
        .map((wallet) => WalletStorageKeys.walletKey(wallet.id, wallet.vaultType))
        .toList();
  }

  static Future<void> _deleteSecureZoneKeys(List<String> walletKeys) async {
    if (walletKeys.isEmpty) {
      Logger.log('--> ℹ️ SZR deleteKeys skip: 삭제할 키 없음');
      return;
    }
    Logger.log('--> 🧹 SZR deleteKeys 시도: ${walletKeys.length}개');
    try {
      await SecureZoneRepository().deleteKeys(aliasList: walletKeys);
      Logger.log('--> ✅ SZR deleteKeys 성공: ${walletKeys.length}개 삭제 완료');
    } on PlatformException catch (e) {
      Logger.error('--> ❌ SZR deleteKeys 실패 ${e.toString()} ');
    }
  }

  static Future<void> _deleteSecureStorage() async {
    try {
      await SecureStorageRepository().deleteAll();
    } on PlatformException catch (_) {
      Logger.error('--> ❌ FSS deleteAll 실패');
    }
  }

  static Future<void> _deleteSharedPrefsMeta(SharedPrefsRepository sp) async {
    await sp.deleteSharedPrefsWithKey(SharedPrefsKeys.vaultListLength);
    await sp.deleteSharedPrefsWithKey(SharedPrefsKeys.kVaultListField);
    await sp.deleteSharedPrefsWithKey(SharedPrefsKeys.kNextIdField);
  }
}
