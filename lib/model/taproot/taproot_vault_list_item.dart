import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:collection/collection.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/model/taproot/taproot_participant.dart';
import 'package:coconut_vault/model/taproot/taproot_seed_info.dart';
import 'package:json_annotation/json_annotation.dart';

part 'taproot_vault_list_item.g.dart'; // 생성될 파일 이름 $ dart run build_runner build

@JsonSerializable(ignoreUnannotated: true, createFactory: false)
class TaprootVaultListItem extends VaultListItemBase {
  static const fieldDescriptor = 'descriptor';
  static const fieldKeyPathSeedInfos = 'keyPathSeedInfos';
  static const fieldBeneficiarySeedInfos = 'beneficiarySeedInfos';

  @JsonKey(name: fieldDescriptor)
  final String descriptor;
  @JsonKey(name: fieldKeyPathSeedInfos)
  final List<TaprootSeedInfo> _keyPathSeedInfos;
  List<TaprootSeedInfo> get keyPathSeedInfos => _keyPathSeedInfos;
  @JsonKey(name: fieldBeneficiarySeedInfos)
  final List<TaprootSeedInfo> _beneficiarySeedInfos;
  List<TaprootSeedInfo> get beneficiarySeedInfos => _beneficiarySeedInfos;

  late final bool _isParent;
  late final List<TaprootParticipant> _keyPathParticipants;
  late final List<TaprootBeneficiaryParticipant> _beneficiaryParticipants;

  TaprootVaultListItem({
    required super.id,
    required super.name,
    required super.colorIndex,
    required super.iconIndex,
    required super.createdAt,
    required this.descriptor,
    required List<TaprootSeedInfo> keyPathSeedInfos,
    required List<TaprootSeedInfo> beneficiarySeedInfos,
  }) : _keyPathSeedInfos = List.unmodifiable(keyPathSeedInfos),
       _beneficiarySeedInfos = List.unmodifiable(beneficiarySeedInfos),
       super(vaultType: WalletType.taproot) {
    coconutVault = TaprootVault.fromDescriotor(descriptor);

    final taprootVault = (coconutVault as TaprootVault);
    final List<TaprootParticipant> keyPathParticipants = [];
    for (final keyStore in taprootVault.keyStoreList) {
      final extendedPubKey = keyStore.extendedPublicKey.serialize();
      final TaprootSeedInfo? seedInfo = keyPathSeedInfos.firstWhereOrNull(
        (seedInfo) => seedInfo.extendedPublicKey == extendedPubKey,
      );
      keyPathParticipants.add(
        TaprootParticipant(
          masterFingerprint: keyStore.masterFingerprint,
          type: TaprootParticipantType.keyPath,
          extendedPublicKey: extendedPubKey,
          isSeedStored: seedInfo != null,
          isPassphraseSet: seedInfo?.isPassphraseSet ?? false,
        ),
      );
    }

    final List<TaprootBeneficiaryParticipant> beneficiaryParticipants = [];
    for (final policy in taprootVault.policyList) {
      if (policy is! InheritancePolicy) continue;

      final keyStore = policy.beneficiaryKeyStore;
      final extendedPubKey = keyStore.extendedPublicKey.serialize();
      final TaprootSeedInfo? seedInfo = beneficiarySeedInfos.firstWhereOrNull(
        (seedInfo) => seedInfo.extendedPublicKey == extendedPubKey,
      );
      beneficiaryParticipants.add(
        TaprootBeneficiaryParticipant(
          masterFingerprint: keyStore.masterFingerprint,
          type: TaprootParticipantType.beneficiary,
          extendedPublicKey: extendedPubKey,
          isSeedStored: seedInfo != null,
          isPassphraseSet: seedInfo?.isPassphraseSet ?? false,
          lockTime: policy.locktime,
        ),
      );
    }

    _keyPathParticipants = keyPathParticipants;
    _beneficiaryParticipants = beneficiaryParticipants;
    _isParent = keyPathSeedInfos.isNotEmpty;
  }

  List<TaprootParticipant> get keyPathParticipants => List.unmodifiable(_keyPathParticipants);
  List<TaprootBeneficiaryParticipant> get beneficiaryParticipants => List.unmodifiable(_beneficiaryParticipants);
  bool get isParent => _isParent;
  String get derivationPath => (coconutVault as TaprootVault).derivationPath;

  @override
  Future<bool> canSign(String psbt) async => false;

  @override
  String getWalletSyncString() => '';

  @override
  Map<String, dynamic> toJson() => _$TaprootVaultListItemToJson(this);

  @override
  Map<String, dynamic> toPublicJson() {
    final json = toJson();
    json.remove(fieldDescriptor);
    json.remove(fieldKeyPathSeedInfos);
    json.remove(fieldBeneficiarySeedInfos);
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
              .map((e) => TaprootSeedInfo.fromJson(e as Map<String, dynamic>))
              .toList(),
      beneficiarySeedInfos:
          (json[fieldBeneficiarySeedInfos] as List<dynamic>)
              .map((e) => TaprootSeedInfo.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }
}
