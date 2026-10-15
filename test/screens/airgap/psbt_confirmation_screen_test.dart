import 'dart:convert';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/single_sig/single_sig_vault_list_item.dart';
import 'package:coconut_vault/providers/sign_provider.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:coconut_vault/screens/airgap/psbt_confirmation_screen.dart';
import 'package:coconut_vault/widgets/card/send_transaction_flow_card.dart';
import 'package:coconut_vault/widgets/send_output_detail_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() => LocaleSettings.instance.loadAllLocales());

  for (final locale in AppLocale.values) {
    for (final scenario in [
      (inputs: 1, outputs: 1, sweep: true, inputLabels: [0], outputLabels: [0]),
      (inputs: 5, outputs: 3, sweep: false, inputLabels: [0, 1, 2, 3, 4], outputLabels: [0, 1, 2]),
      (inputs: 6, outputs: 4, sweep: false, inputLabels: [0, 1, 2, 5], outputLabels: [0, 3]),
      (inputs: 6, outputs: 5, sweep: false, inputLabels: [0, 1, 2, 5], outputLabels: [0, 4]),
    ]) {
      testWidgets('${locale.name}: numbers ${scenario.inputs} inputs and ${scenario.outputs} outputs from zero', (
        tester,
      ) async {
        NetworkType.setNetworkType(NetworkType.regtest);
        SharedPreferences.setMockInitialValues({SharedPrefsKeys.kLanguage: locale.name});
        await SharedPrefsRepository().init();
        final visibilityProvider = VisibilityProvider(isSigningOnlyMode: false);
        LocaleSettings.setLocaleSync(locale);

        final vault = SingleSignatureVault.fromMnemonic(
          utf8.encode('abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about'),
        );
        final utxos = List.generate(
          scenario.inputs,
          (index) => Utxo(
            Codec.encodeHex(Hash.sha256('psbt-confirmation-test-$index')),
            0,
            100000,
            '${vault.derivationPath}/0/$index',
          ),
        );
        final transaction =
            scenario.sweep
                ? Transaction.forSweep(utxos, vault.getAddress(10), 3, vault)
                : Transaction.forBatchPayment(
                  utxos,
                  {for (int index = 0; index < scenario.outputs; index++) vault.getAddress(10 + index): 15000 + index},
                  '${vault.derivationPath}/1/0',
                  3,
                  vault,
                );
        final signProvider =
            SignProvider()
              ..setVaultListItem(
                SingleSigVaultListItem(
                  id: 1,
                  name: 'Test vault',
                  colorIndex: 0,
                  iconIndex: 0,
                  descriptor: vault.descriptor,
                  signerBsmsByAddressType: {AddressType.p2wpkh: ''},
                  createdAt: DateTime(2026),
                ),
              )
              ..saveUnsignedPsbt(Psbt.fromTransaction(transaction, vault).serialize());

        await tester.pumpWidget(
          MultiProvider(
            providers: [Provider.value(value: signProvider), ChangeNotifierProvider.value(value: visibilityProvider)],
            child: const MaterialApp(home: PsbtConfirmationScreen()),
          ),
        );
        await tester.pump();
        expect(LocaleSettings.currentLocale, locale);

        List<String> labelsIn(Type widgetType) {
          return tester
              .widgetList<Text>(find.descendant(of: find.byType(widgetType), matching: find.byType(Text)))
              .map((text) => text.data)
              .whereType<String>()
              .where((label) => RegExp(r'\d+$').hasMatch(label) || label == t.change)
              .toList();
        }

        expect(
          {'flow': labelsIn(SendTransactionFlowCard), 'details': labelsIn(SendOutputDetailCard)},
          {
            'flow': [
              ...scenario.inputLabels.map((index) => t.psbt_confirmation_screen.flow_input_title(index: index)),
              ...scenario.outputLabels.map((index) => t.psbt_confirmation_screen.flow_output_title(index: index)),
              if (!scenario.sweep) t.change,
            ],
            'details': [
              for (int index = 0; index < scenario.outputs; index++)
                t.psbt_confirmation_screen.flow_output_title(index: index),
              if (!scenario.sweep) t.change,
            ],
          },
        );
        await tester.pumpWidget(const SizedBox());
        visibilityProvider.dispose();
      });
    }
  }
}
