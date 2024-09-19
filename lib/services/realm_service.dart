import 'package:coconut_vault/model/realm/keyValue.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:realm/realm.dart';

class RealmService {
  static final config = Configuration.local([
    KeyValue.schema
  ], encryptionKey: [
    0x01,
    0x23,
    0x45,
    0x67,
    0x89,
    0xAB,
    0xCD,
    0xEF,
    0xFE,
    0xDC,
    0xBA,
    0x98,
    0x76,
    0x54,
    0x32,
    0x10,
    0x01,
    0x23,
    0x45,
    0x67,
    0x89,
    0xAB,
    0xCD,
    0xEF,
    0xFE,
    0xDC,
    0xBA,
    0x98,
    0x76,
    0x54,
    0x32,
    0x10,
    0x01,
    0x23,
    0x45,
    0x67,
    0x89,
    0xAB,
    0xCD,
    0xEF,
    0xFE,
    0xDC,
    0xBA,
    0x98,
    0x76,
    0x54,
    0x32,
    0x10,
    0x01,
    0x23,
    0x45,
    0x67,
    0x89,
    0xAB,
    0xCD,
    0xEF,
    0xFE,
    0xDC,
    0xBA,
    0x98,
    0x76,
    0x54,
    0x32,
    0x10
  ]);

  bool updateKeyValue({required String key, required String value}) {
    Realm realm = Realm(config);
    try {
      var objects = realm.query<KeyValue>(r'key == $0', [key]);
      if (objects.isEmpty) {
        realm.write(() {
          realm.add(KeyValue(key, value));
        });
      } else {
        if (objects.length > 1) {
          throw Exception("[Realm] KeyValue($key) is one more.");
        }
        realm.write(() {
          objects[0].value = value;
        });
      }

      return true;
    } catch (_) {
      Logger.log("[RealmService] updateKeyValue failed. Reason: $_");
      return false;
    } finally {
      realm.close();
    }
  }

  String? getValue({required String key}) {
    Realm realm = Realm(config);

    try {
      var objects = realm.query<KeyValue>(r'key == $0', [key]);
      //Logger.log('objects: ${objects.length} ${objects[0].key}');
      if (objects.isEmpty) {
        return null;
      }

      if (objects.length > 1) {
        throw Exception("[Realm] KeyValue($key) is one more.");
      }

      return objects[0].value;
    } catch (_) {
      Logger.log("[RealmService] getValue failed. Reason: $_");
      return null;
    } finally {
      realm.close();
    }
  }

  void deleteAll() {
    Realm realm = Realm(config);
    try {
      realm.write(() {
        realm.deleteAll();
      });
    } catch (_) {
      Logger.log("[RealmService] getValue failed. Reason: $_");
    } finally {
      realm.close();
    }
  }
}
