import 'dart:convert';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'vault_list_item.g.dart'; // 생성될 파일 이름 $ dart run build_runner build

@JsonSerializable(ignoreUnannotated: true)
class VaultListItem {
  VaultListItem(
      {required this.id,
      required this.name,
      required this.colorIndex,
      required this.iconIndex,
      required this.secret,
      required this.passphrase,
      this.vaultJsonString}) {
    Seed seed = Seed.fromMnemonic(secret, passphrase: passphrase);
    coconutVault = SingleSignatureVault.fromSeed(seed, AddressType.p2wpkh);

    vaultJsonString = coconutVault.toJson();
  }

  @JsonKey(name: "id")
  final int id;
  @JsonKey(name: "name")
  final String name;
  @JsonKey(name: "colorIndex")
  final int colorIndex;
  @JsonKey(name: "iconIndex")
  final int iconIndex;
  @JsonKey(name: "secret")
  final String secret;
  @JsonKey(name: "passphrase")
  final String passphrase;
  @JsonKey(name: "vaultJsonString")
  String? vaultJsonString;

  late SingleSignatureVault coconutVault;

  // 다음 일련번호를 저장하고 불러오는 메서드
  static Future<int> _loadNextId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('nextId') ?? 1;
  }

  static Future<void> _saveNextId(int nextId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('nextId', nextId);
  }

  static Future<VaultListItem> create(
      {required String name,
      required int colorIndex,
      required int iconIndex,
      required String secret,
      String passphrase = '',
      List<AddressType>? addressTypes}) async {
    final nextId = await _loadNextId();

    final newItem = VaultListItem(
        id: nextId,
        name: name,
        colorIndex: colorIndex,
        iconIndex: iconIndex,
        secret: secret,
        passphrase: passphrase);
    await _saveNextId(nextId + 1); // 다음 일련번호 저장
    return newItem;
  }

  @override
  String toString() =>
      'Vault($id) / name=$name / colorIndex=$colorIndex / iconIndex=$iconIndex';

  factory VaultListItem.fromJson(Map<String, dynamic> json) {
    final result = _$VaultListItemFromJson(json);

    if (result.vaultJsonString != null) {
      String vaultJson = result.vaultJsonString!;
      result.coconutVault = SingleSignatureVault.fromJson(vaultJson);
    } else {
      Seed seed =
          Seed.fromMnemonic(result.secret, passphrase: result.passphrase);
      result.coconutVault = SingleSignatureVault.fromSeed(
        seed,
        AddressType.p2wpkh,
      );
    }

    return result;
  }

  Map<String, dynamic> toJson() => _$VaultListItemToJson(this);

  String getWalletSyncString() {
    Map<String, dynamic> json = {
      'name': name,
      'colorIndex': colorIndex,
      'iconIndex': iconIndex,
      'descriptor': coconutVault.descriptor
    };

    return jsonEncode(json);
  }
}
