import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/model/single_sig/single_sig_vault_list_item.dart';
import 'package:coconut_vault/providers/sign_provider.dart';
import 'package:coconut_vault/providers/view_model/airgap/psbt_confirmation_view_model.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/payjoin_psbt_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SingleSignatureVault ours;
  late SingleSignatureVault counterparty;
  late VisibilityProvider visibility;

  setUp(() async {
    NetworkType.setNetworkType(NetworkType.regtest);
    ours = PayjoinPsbtFixture.ourVault();
    counterparty = PayjoinPsbtFixture.counterpartyVault();
    SharedPreferences.setMockInitialValues({SharedPrefsKeys.kIsBtcUnit: false, SharedPrefsKeys.kLanguage: 'en'});
    await SharedPrefsRepository().init();
    visibility = VisibilityProvider(isSigningOnlyMode: true);
  });

  (PsbtConfirmationViewModel, SignProvider) review(Psbt psbt) {
    final signProvider =
        SignProvider()
          ..setVaultListItem(
            SingleSigVaultListItem(
              id: 1,
              name: 'vault',
              colorIndex: 0,
              iconIndex: 0,
              descriptor: ours.descriptor,
              signerBsmsByAddressType: {AddressType.p2wpkh: ''},
              createdAt: DateTime(2026),
            ),
          )
          ..saveUnsignedPsbt(psbt.serialize());
    final viewModel = PsbtConfirmationViewModel(signProvider, visibility)..setTxInfo();
    return (viewModel, signProvider);
  }

  test("a sender's proposal shows what this vault sends, net of the other party's input", () {
    final (viewModel, signProvider) = review(PayjoinPsbtFixture.senderProposal(ours, receiver: counterparty));

    expect(viewModel.isPayjoin, isTrue);
    // 200000 in from our two inputs, 149000 back as change.
    expect(viewModel.payjoinNetAmount, -51000);
    expect(viewModel.sendingAmount, 51000);
    expect(viewModel.totalAmount, 51000);
    expect(viewModel.foreignInputs.map((input) => input.index), [1]);
    expect(viewModel.inputs, [100000, null, 100000]);
    expect(viewModel.estimatedFee, isNull);
    expect(viewModel.hasWarning, isTrue);
    expect(signProvider.payjoinNetAmount, -51000);
    expect(signProvider.sendingAmount, 51000);
    expect(signProvider.recipientAddress, counterparty.getAddress(5));
  });

  test("a receiver's PSBT shows what this vault receives", () {
    final (viewModel, signProvider) = review(PayjoinPsbtFixture.receiverProposal(ours, sender: counterparty));

    // 200000 out to us, 100000 in from our input.
    expect(viewModel.payjoinNetAmount, 100000);
    expect(viewModel.sendingAmount, 100000);
    expect(viewModel.foreignInputs.map((input) => input.index), [0, 1]);
    expect(viewModel.inputs, [null, null, 100000]);
    expect(viewModel.estimatedFee, isNull);
    expect(signProvider.payjoinNetAmount, 100000);
    expect(signProvider.recipientAddress, ours.getAddressWithDerivationPath('${ours.derivationPath}/0/7'));
  });

  test("the net amount ignores the amount the other party states for its input", () {
    final psbt = PayjoinPsbtFixture.build(
      ours,
      inputs: [
        PayjoinPsbtFixture.foreignInput(counterparty, 0, amount: 5000000),
        OwnedInput(PayjoinPsbtFixture.ownedUtxo(ours, 0)),
      ],
      outputs: [
        ForeignOutput(99000, counterparty.getAddress(1, isChange: true)),
        OwnedOutput(200000, '${ours.derivationPath}/0/7'),
      ],
    );

    final (viewModel, _) = review(psbt);

    expect(viewModel.payjoinNetAmount, 100000);
    expect(viewModel.estimatedFee, isNull);
  });

  test('an ordinary PSBT keeps its fee and no payjoin notice', () {
    final tx = Transaction.forSinglePayment(
      [PayjoinPsbtFixture.ownedUtxo(ours, 0)],
      counterparty.getAddress(0),
      '${ours.derivationPath}/1/0',
      15000,
      3,
      ours,
    );

    final (viewModel, signProvider) = review(Psbt.fromTransaction(tx, ours));

    expect(viewModel.isPayjoin, isFalse);
    expect(viewModel.hasWarning, isFalse);
    expect(viewModel.estimatedFee, isNotNull);
    expect(viewModel.sendingAmount, 15000);
    expect(signProvider.payjoinNetAmount, isNull);
  });
}
