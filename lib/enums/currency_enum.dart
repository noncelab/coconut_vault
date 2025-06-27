import 'package:coconut_vault/localization/strings.g.dart';

enum BitcoinUnit {
  btc,
  sats;

  String symbol() {
    return this == BitcoinUnit.btc ? t.btc : t.sats;
  }
}
