import 'package:realm/realm.dart';

part 'keyValue.realm.dart'; // $ dart run realm generate

@RealmModel() // define a data model class named `_Car`.
class _KeyValue {
  @PrimaryKey()
  late String key;

  late String value;
}
