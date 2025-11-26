import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/repository/model/wallet_privacy_info.dart';
import 'package:json_annotation/json_annotation.dart';

part 'single_sig_wallet_privacy_data.g.dart';

@JsonSerializable()
class SingleSigWalletPrivacyInfo extends WalletPrivacyInfo {
  static final validAddressTypes = [AddressType.p2wsh];

  final String descriptor;
  late final Map<String, String> signerBsmsByAddressTypeName;

  SingleSigWalletPrivacyInfo({required this.descriptor, required Map<String, String> signerBsmsByAddressTypeName})
    : signerBsmsByAddressTypeName = validateSignerBsms(signerBsmsByAddressTypeName);

  factory SingleSigWalletPrivacyInfo.fromJson(Map<String, dynamic> json) => _$SingleSigWalletPrivacyDataFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$SingleSigWalletPrivacyDataToJson(this);

  static Map<String, String> validateSignerBsms(Map<String, String> signerBsmsByAddressTypeName) {
    if (signerBsmsByAddressTypeName.length != validAddressTypes.length) {
      throw ArgumentError('Wrong signerBsms');
    }
    // validAddressType 모두 Map에 Key로 반드시 있어야 함
    for (final type in validAddressTypes) {
      if (!signerBsmsByAddressTypeName.containsKey(type.name)) {
        throw ArgumentError.value(null, type.name, 'Signer BSMS missed');
      }
    }

    return signerBsmsByAddressTypeName;
  }

  Map<AddressType, String> getSignerBsmsByAddressType() {
    return signerBsmsByAddressTypeName.map(
      (key, value) => MapEntry(AddressType.values.firstWhere((e) => e.name == key), value),
    );
  }

  factory SingleSigWalletPrivacyInfo.fromAddressTypeMap({
    required String descriptor,
    required Map<AddressType, String> signerBsmsByAddressType,
  }) {
    final byName = validateSignerBsms(signerBsmsByAddressType.map((key, value) => MapEntry(key.name, value)));
    return SingleSigWalletPrivacyInfo(descriptor: descriptor, signerBsmsByAddressTypeName: byName);
  }
}
