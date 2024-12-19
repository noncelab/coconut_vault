/// vault_model의 _vaultList에서 type 값 문자열을 비교할 때 꼭 VaultType.singleSignature.name으로 비교하셔야 합니다
enum VaultType {
  singleSignature, // Single-Signature Vault
  multiSignature, // Multi-Signature Vault
}
