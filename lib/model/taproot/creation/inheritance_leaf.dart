import 'package:coconut_vault/model/taproot/seed_source.dart';
import 'package:json_annotation/json_annotation.dart';

part 'inheritance_leaf.g.dart';

@JsonSerializable(explicitToJson: true)
class InheritanceLeaf {
  @JsonKey(name: "secret")
  final SeedSource? secret;

  @JsonKey(name: "descriptor")
  final String? descriptor;

  @JsonKey(name: "lockTime")
  final int lockTime;

  InheritanceLeaf({this.secret, this.descriptor, required this.lockTime})
    : assert((secret != null) ^ (descriptor != null), 'Exactly one of secret or descriptor must be provided');

  factory InheritanceLeaf.fromJson(Map<String, dynamic> json) => _$InheritanceLeafFromJson(json);

  Map<String, dynamic> toJson() => _$InheritanceLeafToJson(this);

  void wipe() {
    secret?.wipe();
  }
}
