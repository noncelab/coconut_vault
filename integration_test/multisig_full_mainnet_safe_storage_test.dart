import 'package:coconut_vault/enums/vault_mode_enum.dart';
import 'package:coconut_vault/main.dart' as app;
import 'package:integration_test/integration_test.dart';

import 'multisig_creation_suite.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  runMultisigCreationSuite(appMain: app.main, mode: VaultMode.secureStorage, isLite: false);
}
