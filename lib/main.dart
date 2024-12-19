import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/model/manager/wallet_list_manager.dart';
import 'package:coconut_vault/services/shared_preferences_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:coconut_vault/app.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

void main() async {
  // This app is designed only to work vertically, so we limit
  // orientations to portrait up and down.
  WidgetsFlutterBinding.ensureInitialized();

  await SharedPrefsService().init();
  await WalletListManager().init();

  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  Provider.debugCheckInvalidValueType = null;

  BitcoinNetwork.setNetwork(BitcoinNetwork.regtest);

  return runApp(const PowVaultApp());
}
