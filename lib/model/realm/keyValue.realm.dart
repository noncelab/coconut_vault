// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'keyValue.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

// ignore_for_file: type=lint
class KeyValue extends _KeyValue
    with RealmEntity, RealmObjectBase, RealmObject {
  KeyValue(
    String key,
    String value,
  ) {
    RealmObjectBase.set(this, 'key', key);
    RealmObjectBase.set(this, 'value', value);
  }

  KeyValue._();

  @override
  String get key => RealmObjectBase.get<String>(this, 'key') as String;
  @override
  set key(String value) => RealmObjectBase.set(this, 'key', value);

  @override
  String get value => RealmObjectBase.get<String>(this, 'value') as String;
  @override
  set value(String value) => RealmObjectBase.set(this, 'value', value);

  @override
  Stream<RealmObjectChanges<KeyValue>> get changes =>
      RealmObjectBase.getChanges<KeyValue>(this);

  @override
  Stream<RealmObjectChanges<KeyValue>> changesFor([List<String>? keyPaths]) =>
      RealmObjectBase.getChangesFor<KeyValue>(this, keyPaths);

  @override
  KeyValue freeze() => RealmObjectBase.freezeObject<KeyValue>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'key': key.toEJson(),
      'value': value.toEJson(),
    };
  }

  static EJsonValue _toEJson(KeyValue value) => value.toEJson();
  static KeyValue _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'key': EJsonValue key,
        'value': EJsonValue value,
      } =>
        KeyValue(
          fromEJson(key),
          fromEJson(value),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(KeyValue._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(ObjectType.realmObject, KeyValue, 'KeyValue', [
      SchemaProperty('key', RealmPropertyType.string, primaryKey: true),
      SchemaProperty('value', RealmPropertyType.string),
    ]);
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}
