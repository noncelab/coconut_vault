enum UrType {
  cryptoPsbt('crypto-psbt'),
  cryptoAccount('crypto-account'), // single sig
  cryptoOutput('crypto-output'); // multisig

  final String value;
  const UrType(this.value);
}
