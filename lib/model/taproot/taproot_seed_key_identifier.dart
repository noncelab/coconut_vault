/// Taproot seed가 secure storage에 저장된 위치를 식별하는 런타임 키 모델.
///
/// KeyPath/ScriptPath seed는 저장 키 형태가 서로 달라(ScriptPath는 scriptKey가 추가로 필요)
/// 두 변형으로 표현한다. 직렬화 대상이 아니며 조회 시점에만 사용된다.
sealed class TaprootSeedKeyIdentifier {
  const TaprootSeedKeyIdentifier();
}

class KeyPathSeedKeyIdentifier extends TaprootSeedKeyIdentifier {
  final String extendedPublicKey;

  const KeyPathSeedKeyIdentifier({required this.extendedPublicKey});
}

class ScriptPathSeedKeyIdentifier extends TaprootSeedKeyIdentifier {
  final String scriptKey;
  final String extendedPublicKey;

  const ScriptPathSeedKeyIdentifier({required this.scriptKey, required this.extendedPublicKey});
}
