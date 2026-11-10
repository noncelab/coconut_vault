import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/model/taproot/creation/inheritance_leaf.dart';
import 'package:coconut_vault/providers/view_model/vault_creation/taproot/parent_creation_view_model.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/legacy_inheritance_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final fixture = legacyInheritanceFixtures.firstWhere(
    (fixture) => fixture.parentMnemonics.length == 1 && fixture.locktime == 1780012800,
  );
  final timelockDateTime = DateTime.fromMillisecondsSinceEpoch(fixture.locktime * Duration.millisecondsPerSecond);

  setUp(() {
    NetworkType.setNetworkType(NetworkType.testnet);
  });

  ParentCreationViewModel createViewModel() {
    return ParentCreationViewModel(_FakeWalletProvider())
      ..setParentWalletSecret(Uint8List.fromList(utf8.encode(fixture.parentMnemonics.single)))
      ..setChildWallet(
        descriptor: legacyChildDescriptor,
        masterFingerprint: 'B8688DF1',
        source: ParentChildWalletSource.scanned,
      );
  }

  Future<void> waitForLegacyFirstAddress(ParentCreationViewModel viewModel) {
    final completer = Completer<void>();
    void listener() {
      if (viewModel.legacyFirstAddress != null && !completer.isCompleted) completer.complete();
    }

    viewModel.addListener(listener);
    listener();
    return completer.future.timeout(const Duration(seconds: 30)).whenComplete(() => viewModel.removeListener(listener));
  }

  test('creates the current form by default', () {
    final viewModel = createViewModel()..setTimelockDateTime(timelockDateTime);

    final dto = viewModel.createWalletCreateDto(name: '', iconIndex: 0, colorIndex: 0);

    expect(viewModel.isLegacyInheritanceSelected, isFalse);
    expect(dto.inheritanceLeaves!.single.form, InheritanceLeafForm.current);
    expect(viewModel.legacyFirstAddress, isNull);
  });

  test('recreates a vault 3.3.0 wallet and shows its first address', () async {
    final viewModel =
        createViewModel()
          ..setLegacyInheritanceSelected(true)
          ..setTimelockDateTime(timelockDateTime);

    await waitForLegacyFirstAddress(viewModel);
    final dto = viewModel.createWalletCreateDto(name: '', iconIndex: 0, colorIndex: 0);

    expect(dto.inheritanceLeaves!.single.form, InheritanceLeafForm.legacy);
    expect(dto.inheritanceLeaves!.single.lockTime, fixture.locktime);
    expect(viewModel.legacyFirstAddress!.address, fixture.receive0);
    expect(viewModel.legacyFirstAddress!.derivationPath, "m/86'/1'/0'/0/0");
  });

  test('allows dates from 2026-01-01 in both forms', () {
    expect(ParentCreationViewModel.timelockFirstDate, DateTime(2026, 1, 1));
  });

  test('keeps a past date when the form changes', () {
    final pastDateTime = DateTime(2026, 3, 1, 9);
    final viewModel =
        createViewModel()
          ..setTimelockDateTime(pastDateTime)
          ..setLegacyInheritanceSelected(true)
          ..setLegacyInheritanceSelected(false);

    final dto = viewModel.createWalletCreateDto(name: '', iconIndex: 0, colorIndex: 0);

    expect(viewModel.selectedTimelockDateTime, pastDateTime);
    expect(dto.inheritanceLeaves!.single.form, InheritanceLeafForm.current);
    expect(dto.inheritanceLeaves!.single.lockTime, pastDateTime.millisecondsSinceEpoch ~/ 1000);
    expect(viewModel.legacyFirstAddress, isNull);
  });

  test('drops a first address that arrives after the legacy form is turned off', () async {
    final viewModel =
        createViewModel()
          ..setLegacyInheritanceSelected(true)
          ..setTimelockDateTime(timelockDateTime)
          ..setLegacyInheritanceSelected(false);

    await Future<void>.delayed(const Duration(seconds: 3));

    expect(viewModel.legacyFirstAddress, isNull);
  });
}

class _FakeWalletProvider extends Fake implements WalletProvider {}
