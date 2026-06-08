/// Taproot seed가 secure storage에 저장된 위치를 식별하는 런타임 키 모델.
/// 직렬화 대상이 아니며 조회 시점에만 사용된다.
class TaprootSeedKeyIdentifier {
  final String extendedPublicKey;

  const TaprootSeedKeyIdentifier({required this.extendedPublicKey});
}
