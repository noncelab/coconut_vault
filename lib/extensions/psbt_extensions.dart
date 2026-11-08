import 'package:coconut_lib/coconut_lib.dart';

extension PayjoinPsbtExtension on Psbt {
  /// Whether another signer has already finalized any input.
  ///
  /// A payjoin (BIP 77/78) PSBT carries the other party's inputs this way, and
  /// coconut_lib accepts such inputs only when asked to. Asking only for these
  /// PSBTs keeps every other PSBT under the global xpub and wallet identifier
  /// checks, which coconut_lib skips when finalized foreign inputs are allowed.
  bool get hasFinalizedInputs => inputs.any((input) => input.isFinalized);
}
