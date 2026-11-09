import 'package:coconut_lib/coconut_lib.dart';

extension PayjoinPsbtExtension on Psbt {
  /// Whether another signer has already finalized any input.
  ///
  /// A payjoin (BIP 77/78) PSBT carries the other party's inputs this way, and
  /// coconut_lib accepts such inputs only when asked to. Asking only for these
  /// PSBTs keeps every other PSBT under the global xpub and wallet identifier
  /// checks, which coconut_lib skips when finalized foreign inputs are allowed.
  bool get hasFinalizedInputs => inputs.any((input) => input.isFinalized);

  /// Indexes of the inputs another party contributed: finalized, and with no
  /// derivation under [masterFingerprint]. coconut_lib draws the same line
  /// between a vault's inputs and foreign ones.
  List<int> foreignInputIndexes(String masterFingerprint) {
    final fingerprint = masterFingerprint.toUpperCase();
    return [
      for (final (index, input) in inputs.indexed)
        if (input.isFinalized &&
            ![
              ...?input.bip32Derivation,
              ...?input.tapBip32Derivation,
            ].any((derivation) => derivation.masterFingerprint.toUpperCase() == fingerprint))
          index,
    ];
  }
}
