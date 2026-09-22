import 'package:coconut_vault/enums/wallet_enums.dart';

class PrivacyInfoNotFoundException implements Exception {
  final int walletId;
  final WalletType walletType;

  const PrivacyInfoNotFoundException({required this.walletId, required this.walletType});

  @override
  String toString() => 'Privacy info not found: walletId=$walletId, type=${walletType.name}';
}

class InvalidWalletDataException implements Exception {
  final String message;
  final Object? cause;

  const InvalidWalletDataException(this.message, {this.cause});

  @override
  String toString() => 'Invalid wallet data: $message${cause == null ? '' : ' ($cause)'}';
}
