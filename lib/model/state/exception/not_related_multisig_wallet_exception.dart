class NotRelatedMultisigWalletException implements Exception {
  final String message;
  NotRelatedMultisigWalletException(
      {this.message = '이 지갑을 키로 사용한 다중 서명 지갑이 아닙니다.'});

  @override
  String toString() => 'MyFunctionException: $message';
}
