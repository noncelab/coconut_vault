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
  /// [wallets]가 주어지면 SZR 삭제 대상으로 그대로 사용합니다.
  /// null이면 SharedPrefs의 공개 vault 목록(`kVaultListField`)에서 wallet key를 복구합니다.
  ///
  /// 서명전용모드에서 `kVaultListField`가 비어 있어도 남은 SZR 키를 정리할 수 있습니다.
  ///
  /// [storageService]와 [secureZoneRepository]는 테스트 또는 이미 초기화된 인스턴스를
  /// 재사용할 때 전달합니다. 생략하면 각각의 기본 구현체를 사용합니다.
  static Future<void> clearAll({
    List<VaultListItemBase>? wallets,
    SecureStorageRepositoryContract? storageService,
    SecureZoneRepositoryContract? secureZoneRepository,
  }) async {
    final sharedPrefs = SharedPrefsRepository();
    final storage = storageService ?? SecureStorageRepository();

    var keys = <String>[];
    if (wallets != null) {
      keys = await extractSecureZoneKeysFromWalletList(wallets, storageService: storageService);
      Logger.log('--> [WalletStorageCleaner] clearAll: wallets keys=$keys');
    } else {
      final jsonArrayString = sharedPrefs.getString(SharedPrefsKeys.kVaultListField);
      Logger.log('--> [WalletStorageCleaner] clearAll: jsonArrayString=$jsonArrayString');
      keys = await extractSecureZoneKeysFromPublicJson(jsonArrayString, storageService: storageService);
    }

    // wallet list를 복구할 수 없는 경우(서명전용모드 재시작 등), FSS에 남아있는
    // 모든 키를 SZR alias로 추가 삭제 시도합니다.
    if (wallets == null && keys.isEmpty) {
      keys = await storage.getAllKeys();
      Logger.log('--> [WalletStorageCleaner] clearAll: fallback to FSS keys=$keys');
    }

    await _deleteSecureZoneKeys(keys, secureZoneRepository);
    await _deleteSecureStorage(storageService);
    await _deleteSharedPrefsMeta(sharedPrefs);
  }

  /// 공개 vault list JSON(`SharedPrefsKeys.kVaultListField`에 저장된 문자열)에서
  /// SZR(SecureZoneRepository)에 저장된 키 목록을 추출합니다.
  /// - 싱글시그: walletKey
  /// - 탭루트: taprootSeedIndexKey에 저장된 seed 키 목록
  /// - 멀티시그: SZR 키 없음, 제외
  static Future<List<String>> extractSecureZoneKeysFromPublicJson(
    String jsonArray, {
    SecureStorageRepositoryContract? storageService,
  }) async {
    if (jsonArray.isEmpty || jsonArray == '[]') return const [];
    try {
      final decoded = jsonDecode(jsonArray);
      if (decoded is! List) {
        Logger.error('--> ❌ vaultList JSON이 List 아님 (${decoded.runtimeType})');
        return const [];
      }
      final storage = storageService ?? SecureStorageRepository();
      final keys = <String>[];
      for (final m in decoded.whereType<Map>()) {
        final id = m['id'];
        final typeName = m[VaultListItemBase.vaultTypeField];
        if (id is! int || typeName is! String) continue;
        final type = WalletType.fromName(typeName);
        if (type == null || type == WalletType.multiSignature) continue;
        if (type == WalletType.taproot) {
          keys.addAll(await _readTaprootSeedIndex(storage, id));
        } else {
          keys.add(WalletStorageKeys.walletKey(id, type));
        }
      }
      return keys;
    } on FormatException catch (_) {
      Logger.error('--> ❌ vaultList JSON parse 실패');
      return const [];
    }
  }

  /// 인메모리 wallet 리스트에서 SZR(SecureZoneRepository)에 저장된 키 목록을 추출합니다.
  /// - 싱글시그: walletKey
  /// - 탭루트: taprootSeedIndexKey에 저장된 seed 키 목록
  /// - 멀티시그: SZR 키 없음, 제외
  static Future<List<String>> extractSecureZoneKeysFromWalletList(
    List<VaultListItemBase> walletList, {
    SecureStorageRepositoryContract? storageService,
  }) async {
    final storage = storageService ?? SecureStorageRepository();
    final keys = <String>[];
    for (final wallet in walletList) {
      if (wallet.vaultType == WalletType.multiSignature) continue;
      if (wallet.vaultType == WalletType.taproot) {
        keys.addAll(await _readTaprootSeedIndex(storage, wallet.id));
      } else {
        keys.add(WalletStorageKeys.walletKey(wallet.id, wallet.vaultType));
      }
    }
    return keys;
  }

  static Future<List<String>> _readTaprootSeedIndex(
    SecureStorageRepositoryContract storageService,
    int walletId,
  ) async {
    final indexJson = await storageService.read(key: WalletStorageKeys.taprootSeedIndexKey(walletId));
    if (indexJson == null) return const [];
    try {
      return List<String>.from(jsonDecode(indexJson));
    } on FormatException catch (_) {
      return const [];
    }
  }

  static Future<void> _deleteSecureZoneKeys(
    List<String> walletKeys, [
    SecureZoneRepositoryContract? secureZoneRepository,
  ]) async {
    if (walletKeys.isEmpty) {
      Logger.log('--> ℹ️ SZR deleteKeys skip: 삭제할 키 없음');
      return;
    }
    Logger.log('--> 🧹 SZR deleteKeys 시도: ${walletKeys.length}개');
    try {
      await (secureZoneRepository ?? SecureZoneRepository()).deleteKeys(aliasList: walletKeys);
      Logger.log('--> ✅ SZR deleteKeys 성공: ${walletKeys.length}개 삭제 완료');
    } on PlatformException catch (e) {
      Logger.error('--> ❌ SZR deleteKeys 실패 ${e.toString()} ');
    }
  }

  static Future<void> _deleteSecureStorage([SecureStorageRepositoryContract? storageService]) async {
    try {
      await (storageService ?? SecureStorageRepository()).deleteAll();
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
