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

  Future<SingleSignatureVault> prepare(AppLocale locale) async {
    NetworkType.setNetworkType(NetworkType.regtest);
    SharedPreferences.setMockInitialValues({SharedPrefsKeys.kLanguage: locale.name});
    await SharedPrefsRepository().init();
    LocaleSettings.setLocaleSync(locale);
    return SingleSignatureVault.fromMnemonic(
      utf8.encode('abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about'),
    );
  }

  List<Utxo> utxosFor(SingleSignatureVault vault, int count) => List.generate(
    count,
    (index) => Utxo(
      Codec.encodeHex(Hash.sha256('psbt-confirmation-test-$index')),
      0,
      100000,
      '${vault.derivationPath}/0/$index',
    ),
  );

  Future<(SignProvider, VisibilityProvider)> pumpConfirmation(
    WidgetTester tester,
    SingleSignatureVault vault,
    String psbtBase64,
  ) async {
    final visibilityProvider = VisibilityProvider(isSigningOnlyMode: false);
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
          ..saveUnsignedPsbt(psbtBase64);

    await tester.pumpWidget(
      MultiProvider(
        providers: [Provider.value(value: signProvider), ChangeNotifierProvider.value(value: visibilityProvider)],
        child: const MaterialApp(home: PsbtConfirmationScreen()),
      ),
    );
    await tester.pump();
    return (signProvider, visibilityProvider);
  }

  List<String> labelsIn(WidgetTester tester, Type widgetType) {
    return tester
        .widgetList<Text>(find.descendant(of: find.byType(widgetType), matching: find.byType(Text)))
        .map((text) => text.data)
        .whereType<String>()
        .where((label) => RegExp(r'\d+$').hasMatch(label) || label == t.change)
        .toList();
  }

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
        final vault = await prepare(locale);
        final utxos = utxosFor(vault, scenario.inputs);
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
        final (_, visibilityProvider) = await pumpConfirmation(
          tester,
          vault,
          Psbt.fromTransaction(transaction, vault).serialize(),
        );
        expect(LocaleSettings.currentLocale, locale);

        expect(
          {'flow': labelsIn(tester, SendTransactionFlowCard), 'details': labelsIn(tester, SendOutputDetailCard)},
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

    // 외부 코디네이터가 만든 PSBT는 거스름돈이 어느 위치에나, 여러 개 있을 수 있다.
    // 번호는 월렛과 같은 실제 출력 인덱스(vout)이고, 거스름돈 행은 원래 위치에 번호 없이 남는다.
    for (final layout in [
      (name: 'change first', change: [true, false, false], flow: [1, 2], details: [null, 1, 2]),
      (name: 'change in the middle', change: [false, true, false], flow: [0, 2], details: [0, null, 2]),
      (name: 'change last', change: [false, false, true], flow: [0, 1], details: [0, 1, null]),
      (name: 'two change outputs', change: [true, false, true, false], flow: [1, 3], details: [null, 1, null, 3]),
      (
        name: 'collapsed outputs after change',
        change: [true, false, false, false, false],
        flow: [1, 4],
        details: [null, 1, 2, 3, 4],
      ),
      (
        name: 'collapsed outputs with interleaved change',
        change: [false, true, false, false, true, false],
        flow: [0, 5],
        details: [0, null, 2, 3, null, 5],
      ),
    ]) {
      testWidgets('${locale.name}: ${layout.name} keeps output order and change unnumbered', (tester) async {
        final vault = await prepare(locale);
        final utxos = utxosFor(vault, 2);
        // Psbt.fromTransaction은 모든 거스름돈 출력에 changeAddressDerivationPath 하나를 기록하므로 같은 거스름돈 주소를 쓴다.
        final changePath = '${vault.derivationPath}/1/0';
        final outputs = [
          for (final (index, isChange) in layout.change.indexed)
            isChange
                ? TransactionOutput.forPayment(
                  50000 + index,
                  vault.getAddressWithDerivationPath(changePath),
                  derivationPath: changePath,
                  isChangeOutput: true,
                )
                : TransactionOutput.forPayment(15000 + index, vault.getAddress(10 + index)),
        ];
        final transaction =
            Transaction.withInputsAndOutputs(
                [for (final utxo in utxos) TransactionInput.forPayment(utxo.transactionHash, utxo.index)],
                outputs,
                vault.addressType,
              )
              ..utxoList.addAll(utxos)
              ..changeAddressDerivationPath = changePath;
        final psbtBase64 = Psbt.fromTransaction(transaction, vault).serialize();

        final (signProvider, visibilityProvider) = await pumpConfirmation(tester, vault, psbtBase64);

        expect(
          {'flow': labelsIn(tester, SendTransactionFlowCard), 'details': labelsIn(tester, SendOutputDetailCard)},
          {
            'flow': [
              for (int index = 0; index < utxos.length; index++)
                t.psbt_confirmation_screen.flow_input_title(index: index),
              ...layout.flow.map((index) => t.psbt_confirmation_screen.flow_output_title(index: index)),
              t.change,
            ],
            'details': [
              for (final index in layout.details)
                index == null ? t.change : t.psbt_confirmation_screen.flow_output_title(index: index),
            ],
          },
        );

        // 표시용 번호만 바뀌고 출력 데이터·순서와 서명 대상 PSBT는 그대로다.
        final items = tester.widget<SendOutputDetailCard>(find.byType(SendOutputDetailCard)).items;
        expect(
          [for (final item in items) (item.address, item.amountSats, item.isChange)],
          [for (final (index, output) in outputs.indexed) (output.getAddress(), output.amount, layout.change[index])],
        );
        final flowCard = tester.widget<SendTransactionFlowCard>(find.byType(SendTransactionFlowCard));
        expect(flowCard.externalOutputIndexes.length, flowCard.externalOutputAmounts.length);
        expect(
          [
            for (final (index, amount) in flowCard.externalOutputAmounts.indexed)
              (flowCard.externalOutputIndexes[index], amount),
          ],
          [
            for (final (index, output) in outputs.indexed)
              if (!layout.change[index]) (index, output.amount),
          ],
        );
        expect(flowCard.changeOutputAmounts, [
          for (final (index, output) in outputs.indexed)
            if (layout.change[index]) output.amount,
        ]);
        expect(signProvider.unsignedPsbtBase64, psbtBase64);
        expect(signProvider.psbt!.serialize(), psbtBase64);

        await tester.pumpWidget(const SizedBox());
        visibilityProvider.dispose();
      });
    }
  }
}
