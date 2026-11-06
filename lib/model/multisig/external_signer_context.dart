import 'package:coconut_vault/model/multisig/multisig_signer.dart';

/// 멀티시그 지갑에서 외부 지갑 키를 추가할 때 필요한 컨텍스트.
/// [signer]는 추가할 키의 서명자 정보이고,
/// [multisigVaultId]는 키 추가를 호출한 멀티시그 지갑의 vault id이다.
class ExternalSignerContext {
  final MultisigSigner signer;
  final int? multisigVaultId;

  const ExternalSignerContext({required this.signer, this.multisigVaultId});
}
