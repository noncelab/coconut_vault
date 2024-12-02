import 'dart:core';
import 'package:json_annotation/json_annotation.dart';

part 'multisig_import_detail.g.dart'; // 생성될 파일 이름 $ dart run build_runner build

@JsonSerializable(ignoreUnannotated: true)
class MultisigImportDetail {
  @JsonKey()
  int? id;
  @JsonKey()
  String name;
  @JsonKey()
  int colorIndex;
  @JsonKey()
  int iconIndex;
  @JsonKey()
  Map<String, String> namesMap; // 각 Signer의 이름 {mfp: name}
  @JsonKey()
  String coordinatorBsms;

  MultisigImportDetail({
    this.id,
    required this.name,
    required this.colorIndex,
    required this.iconIndex,
    required this.namesMap,
    required this.coordinatorBsms,
  });

  Map<String, dynamic> toJson() => _$MultisigImportDetailToJson(this);

  factory MultisigImportDetail.fromJson(Map<String, dynamic> json) =>
      _$MultisigImportDetailFromJson(json);
}
