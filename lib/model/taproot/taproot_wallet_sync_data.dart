import 'dart:convert';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/model/taproot/taproot_vault_list_item.dart';
import 'package:coconut_vault/utils/migration/taproot_older_to_after_migration.dart';

class TaprootWalletSyncData {
  final String name;
  final int colorIndex;
  final int iconIndex;
  final String descriptor;
  final List<String> keyPathExtendedPublicKeys;
  final List<TaprootWalletSyncScriptPathData> scriptPathSeedInfos;
  final bool wasMigratedFromOlderToAfter;

  TaprootWalletSyncData({
    required this.name,
    required this.colorIndex,
    required this.iconIndex,
    required this.descriptor,
    required this.keyPathExtendedPublicKeys,
    required this.scriptPathSeedInfos,
    this.wasMigratedFromOlderToAfter = false,
  });

  factory TaprootWalletSyncData.parse(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid taproot wallet sync data.');
    }

    final descriptor = _readString(decoded, TaprootVaultListItem.fieldDescriptor);
    final descriptorMigration = TaprootOlderToAfterMigration.migrateDescriptor(descriptor);
    final scriptPathSeedInfos =
        decoded.containsKey(TaprootVaultListItem.fieldScriptPathSeedInfos)
            ? _readMapList(decoded, TaprootVaultListItem.fieldScriptPathSeedInfos)
                .map(TaprootWalletSyncScriptPathData.fromJson)
                .map(
                  (seedInfo) => seedInfo.copyWith(
                    miniscript: TaprootOlderToAfterMigration.migrateMiniscript(seedInfo.miniscript),
                  ),
                )
                .toList()
            : <TaprootWalletSyncScriptPathData>[];

    TaprootVault.fromDescriptor(descriptorMigration.descriptor);

    return TaprootWalletSyncData(
      name: _readString(decoded, VaultListItemBase.fieldName),
      colorIndex: _readInt(decoded, VaultListItemBase.fieldColorIndex),
      iconIndex: _readInt(decoded, VaultListItemBase.fieldIconIndex),
      descriptor: descriptorMigration.descriptor,
      keyPathExtendedPublicKeys:
          decoded.containsKey(TaprootVaultListItem.fieldKeyPathSeedInfos)
              ? _readStringList(decoded, TaprootVaultListItem.fieldKeyPathSeedInfos)
              : [],
      scriptPathSeedInfos: scriptPathSeedInfos,
      wasMigratedFromOlderToAfter:
          descriptorMigration.hasChanges || scriptPathSeedInfos.any((seedInfo) => seedInfo.wasMigratedFromOlderToAfter),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      VaultListItemBase.fieldName: name,
      VaultListItemBase.fieldColorIndex: colorIndex,
      VaultListItemBase.fieldIconIndex: iconIndex,
      TaprootVaultListItem.fieldDescriptor: descriptor,
      TaprootVaultListItem.fieldKeyPathSeedInfos: keyPathExtendedPublicKeys,
      TaprootVaultListItem.fieldScriptPathSeedInfos: scriptPathSeedInfos.map((seedInfo) => seedInfo.toJson()).toList(),
    };
  }

  static String _readString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Invalid $key.');
    }
    return value;
  }

  static int _readInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! int) {
      throw FormatException('Invalid $key.');
    }
    return value;
  }

  static List<String> _readStringList(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! List) {
      throw FormatException('Invalid $key.');
    }
    return value.map((item) {
      if (item is! String || item.trim().isEmpty) {
        throw FormatException('Invalid $key item.');
      }
      return item;
    }).toList();
  }

  static List<Map<String, dynamic>> _readMapList(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! List) {
      throw FormatException('Invalid $key.');
    }
    return value.map((item) {
      if (item is! Map<String, dynamic>) {
        throw FormatException('Invalid $key item.');
      }
      return item;
    }).toList();
  }
}

class TaprootWalletSyncScriptPathData {
  final String miniscript;
  final List<String> extendedPublicKeys;
  final bool wasMigratedFromOlderToAfter;

  TaprootWalletSyncScriptPathData({
    required this.miniscript,
    required this.extendedPublicKeys,
    this.wasMigratedFromOlderToAfter = false,
  });

  TaprootWalletSyncScriptPathData copyWith({String? miniscript}) {
    return TaprootWalletSyncScriptPathData(
      miniscript: miniscript ?? this.miniscript,
      extendedPublicKeys: extendedPublicKeys,
      wasMigratedFromOlderToAfter: wasMigratedFromOlderToAfter || miniscript != null && miniscript != this.miniscript,
    );
  }

  factory TaprootWalletSyncScriptPathData.fromJson(Map<String, dynamic> json) {
    final miniscript = json['miniscript'];
    if (miniscript is! String || miniscript.trim().isEmpty) {
      throw const FormatException('Invalid miniscript.');
    }

    return TaprootWalletSyncScriptPathData(
      miniscript: miniscript,
      extendedPublicKeys: TaprootWalletSyncData._readStringList(json, 'extendedPublicKeys'),
    );
  }

  Map<String, dynamic> toJson() {
    return {'miniscript': miniscript, 'extendedPublicKeys': extendedPublicKeys};
  }
}
