/// 서명 과정에서 사용하는 Provider
class SignProvider {
  int? _walletId;
  String? _unsignedPsbtBase64;

  void saveUnsignedPsbt(String psbtBase64) {
    _unsignedPsbtBase64 = psbtBase64;
  }
}
