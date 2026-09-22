import 'package:coconut_vault/enums/vault_mode_enum.dart';
import 'package:coconut_vault/main_lite.dart' as app;
import 'package:integration_test/integration_test.dart';

import 'single_sig_creation_suite.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  runSingleSigCreationSuite(appMain: app.main, mode: VaultMode.signingOnly, isLite: true);
}
