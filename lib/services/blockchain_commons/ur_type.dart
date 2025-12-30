enum UrType {
  cryptoPsbt('crypto-psbt'),
  cryptoAccount('crypto-account'), // single sig
  cryptoOutput('crypto-output'), // multisig
  bytes('bytes');

  final String value;
  const UrType(this.value);
}
