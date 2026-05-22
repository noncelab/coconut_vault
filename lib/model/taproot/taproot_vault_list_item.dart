import 'dart:convert';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/model/taproot/script_path_seed_info.dart';
import 'package:collection/collection.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/model/taproot/taproot_participant.dart';
import 'package:coconut_vault/model/taproot/stored_taproot_seed_info.dart';
import 'package:json_annotation/json_annotation.dart';

part 'taproot_vault_list_item.g.dart'; // 생성될 파일 이름 $ dart run build_runner build

@JsonSerializable(ignoreUnannotated: true, createFactory: false)
class TaprootVaultListItem extends VaultListItemBase {
  static const fieldDescriptor = 'descriptor';
  static const fieldKeyPathSeedInfos = 'keyPathSeedInfos';
  static const fieldScriptPathSeedInfos = 'scriptPathSeedInfos';

  @JsonKey(name: fieldDescriptor)
  final String descriptor;
  @JsonKey(name: fieldKeyPathSeedInfos)
  final List<StoredTaprootSeedInfo> _keyPathSeedInfos;
  List<StoredTaprootSeedInfo> get keyPathSeedInfos => _keyPathSeedInfos;
  @JsonKey(name: fieldScriptPathSeedInfos)
  final List<ScriptPathSeedInfo> _scriptPathSeedInfos;
  List<ScriptPathSeedInfo> get scriptPathSeedInfos => _scriptPathSeedInfos;

  /// Key Path spending에 참여하는 서명자 목록.
  /// 이 키들은 MuSig2로 aggregate되어 단일 internal key를 구성함.
  late final List<TaprootParticipant> _owners;
  late final List<TaprootBeneficiaryParticipant> _beneficiaries;

  TaprootVaultListItem({
    required super.id,
    required super.name,
    required super.colorIndex,
    required super.iconIndex,
    required super.createdAt,
    required this.descriptor,
    required List<StoredTaprootSeedInfo> keyPathSeedInfos,
    required List<ScriptPathSeedInfo> scriptPathSeedInfos,
  }) : _keyPathSeedInfos = List.unmodifiable(keyPathSeedInfos),
       _scriptPathSeedInfos = List.unmodifiable(scriptPathSeedInfos),
       super(vaultType: WalletType.taproot) {
    coconutVault = TaprootVault.fromDescriptor(descriptor);

    final taprootVault = (coconutVault as TaprootVault);
    _owners = _buildOwners(taprootVault, keyPathSeedInfos);
    _beneficiaries = _buildBeneficiaries(taprootVault, scriptPathSeedInfos);
  }

  static List<TaprootParticipant> _buildOwners(
    TaprootVault taprootVault,
    List<StoredTaprootSeedInfo> keyPathSeedInfos,
  ) {
    final List<TaprootParticipant> owners = [];
    for (final keyStore in taprootVault.keyStoreList) {
      final extendedPubKey = keyStore.extendedPublicKey.serialize();
      final StoredTaprootSeedInfo? seedInfo = keyPathSeedInfos.firstWhereOrNull(
        (seedInfo) => seedInfo.extendedPublicKey == extendedPubKey,
      );
      owners.add(
        TaprootParticipant(
          masterFingerprint: keyStore.masterFingerprint,
          type: TaprootParticipantType.keyPath,
          extendedPublicKey: extendedPubKey,
          isSeedStored: seedInfo != null,
          isPassphraseSet: seedInfo?.isPassphraseSet ?? false,
        ),
      );
    }

    return owners;
  }

  static List<TaprootBeneficiaryParticipant> _buildBeneficiaries(
    TaprootVault taprootVault,
    List<ScriptPathSeedInfo> scriptPathSeedInfos,
  ) {
    final List<TaprootBeneficiaryParticipant> beneficiaries = [];
    for (final policy in taprootVault.policyList) {
      if (policy is! InheritancePolicy) continue;

      final keyStore = policy.beneficiaryKeyStore;
      final extendedPubKey = keyStore.extendedPublicKey.serialize();
      final scriptKey = ScriptPathSeedInfo.generateKey(policy);
      final ScriptPathSeedInfo? seedInfo = scriptPathSeedInfos.firstWhereOrNull(
        (seedInfo) => seedInfo.role == ScriptPathRole.beneficiary && seedInfo.key == scriptKey,
      );
      assert(seedInfo == null || seedInfo.seedInfos.isNotEmpty);
      final bool isPassphraseSet = seedInfo?.seedInfos[0].isPassphraseSet ?? false;

      beneficiaries.add(
        TaprootBeneficiaryParticipant(
          masterFingerprint: keyStore.masterFingerprint,
          type: TaprootParticipantType.beneficiary,
          extendedPublicKey: extendedPubKey,
          isSeedStored: seedInfo != null,
          isPassphraseSet: isPassphraseSet,
          lockTime: policy.locktime,
          scriptKey: scriptKey,
        ),
      );
    }

    return beneficiaries;
  }

  List<TaprootParticipant> get owners => List.unmodifiable(_owners);
  List<TaprootBeneficiaryParticipant> get beneficiaries => List.unmodifiable(_beneficiaries);
  bool get isParent => _keyPathSeedInfos.isNotEmpty;
  String get derivationPath => (coconutVault as TaprootVault).derivationPath;

  @override
  Future<bool> canSign(String psbt) async => false;

  @override
  String getWalletSyncString() {
    return jsonEncode({
      VaultListItemBase.fieldName: name,
      VaultListItemBase.fieldColorIndex: colorIndex,
      VaultListItemBase.fieldIconIndex: iconIndex,
      fieldDescriptor: descriptor,
      fieldKeyPathSeedInfos: _keyPathSeedInfos.map((seedInfo) => seedInfo.extendedPublicKey).toList(),
      fieldScriptPathSeedInfos:
          _scriptPathSeedInfos
              .map((seedInfo) {
                final miniscript = (coconutVault as TaprootVault)
                    .policyList
                    .firstWhereOrNull((p) => ScriptPathSeedInfo.generateKey(p) == seedInfo.key)
                    ?.toMiniscript();
                if (miniscript == null) return null;
                return <String, dynamic>{
                  'miniscript': miniscript,
                  'extendedPublicKeys': seedInfo.seedInfos.map((s) => s.extendedPublicKey).toList(),
                };
              })
              .whereType<Map<String, dynamic>>()
              .toList(),
      VaultListItemBase.fieldCreatedAt: createdAt.toIso8601String(),
    });
  }

  @override
  Map<String, dynamic> toJson() => _$TaprootVaultListItemToJson(this);

  @override
  Map<String, dynamic> toPublicJson() {
    final json = toJson();
    json.remove(fieldDescriptor);
    json.remove(fieldKeyPathSeedInfos);
    json.remove(fieldScriptPathSeedInfos);
    return json;
  }

  factory TaprootVaultListItem.fromJson(Map<String, dynamic> json) {
    return TaprootVaultListItem(
      id: json['id'] as int,
      name: json['name'] as String,
      colorIndex: json['colorIndex'] as int,
      iconIndex: json['iconIndex'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      descriptor: json[fieldDescriptor] as String,
      keyPathSeedInfos:
          (json[fieldKeyPathSeedInfos] as List<dynamic>)
              .map((e) => StoredTaprootSeedInfo.fromJson(e as Map<String, dynamic>))
              .toList(),
      scriptPathSeedInfos:
          (json[fieldScriptPathSeedInfos] as List<dynamic>)
              .map((e) => ScriptPathSeedInfo.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }
}
