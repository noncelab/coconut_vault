import 'package:coconut_vault/repository/model/wallet_privacy_info.dart';
import 'package:json_annotation/json_annotation.dart';

part 'multisig_wallet_privacy_info.g.dart';

@JsonSerializable()
class SignerPrivacyInfo {
  final String signerBsms;
  final String keyStoreToJson;

  SignerPrivacyInfo({required this.signerBsms, required this.keyStoreToJson});

  factory SignerPrivacyInfo.fromJson(Map<String, dynamic> json) => _$SignerPrivacyInfoFromJson(json);

  Map<String, dynamic> toJson() => _$SignerPrivacyInfoToJson(this);
}

/// secure storage에 저장
@JsonSerializable()
class MultisigWalletPrivacyInfo extends WalletPrivacyInfo {
  final String coordinatorBsms;
  final List<SignerPrivacyInfo> signersPrivacyInfo;

  MultisigWalletPrivacyInfo({required this.coordinatorBsms, required this.signersPrivacyInfo});

  factory MultisigWalletPrivacyInfo.fromJson(Map<String, dynamic> json) => _$MultisigWalletPrivacyInfoFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$MultisigWalletPrivacyInfoToJson(this);
}
