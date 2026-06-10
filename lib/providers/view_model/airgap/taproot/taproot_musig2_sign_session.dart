import 'package:coconut_lib/coconut_lib.dart';

enum TaprootMusig2SignStep {
  none,
  localNonceCreated,
  remoteNonceRequired,
  remotePartialSignatureRequired,
  localPartialSignatureCreated,
  completed,
}

class TaprootMusig2SignSession {
  final TaprootVault coconutVault;
  final String initialPsbt;

  TaprootMusig2SignStep _step = TaprootMusig2SignStep.none;
  TaprootMusig2SignStep get step => _step;

  TaprootMusig2SignSession({required this.coconutVault, required this.initialPsbt});

  // nonce 생성, nonce 수신, partial sig 생성/수신 등 상태 전이 메서드들
}
