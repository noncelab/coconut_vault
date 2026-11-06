// QA generated host test (logic_coverage.autofill)
// Target: PsbtConfirmationViewModel.setTxInfo
// Intent (3b84e9ee "feat(숫자 표기): 국가-지역 별 숫자 표기 설정 추가 (프리셋)"):
//   배치 전송의 수신자 라벨 금액은 사용자가 고른 숫자 표기 preset(소수점/천 단위 구분자)을 따른다.
//   BTC 단위는 BalanceFormatUtil.formatSatoshiToReadableBitcoin(소수 4자리 묶음 + preset 소수점),
//   sats 단위는 preset 천 단위 구분자. (이전: BTC는 double.toString() 그대로)
//
// Real classes: PsbtConfirmationViewModel, SignProvider, VisibilityProvider(+SharedPrefsRepository),
// NumberFormatConfig, coconut_lib PSBT. Boundary: SharedPreferences.setMockInitialValues.
// Fixture helpers adapted from test/providers/view_model/airgap/psbt_scanner_view_model_test.dart:247-257,293-306.
import 'dart:convert';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/config/number_format_config.dart';
import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/enums/number_format_preset.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/single_sig/single_sig_vault_list_item.dart';
import 'package:coconut_vault/providers/sign_provider.dart';
import 'package:coconut_vault/providers/view_model/airgap/psbt_confirmation_view_model.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SingleSignatureVault ownerVault;
  late SingleSignatureVault otherVault;
  late String recipientA;
  late String recipientB;

  setUp(() {
    NetworkType.setNetworkType(NetworkType.regtest);
    ownerVault = _vault('confirm-owner');
    otherVault = _vault('confirm-other');
    recipientA = otherVault.getAddress(0);
    recipientB = otherVault.getAddress(1);
  });

  tearDown(() {
    NumberFormatConfig.instance.applyPreset(NumberFormatPreset.dotDecimal);
  });

  Future<VisibilityProvider> visibility({required bool isBtcUnit, required NumberFormatPreset preset}) async {
    SharedPreferences.setMockInitialValues({
      SharedPrefsKeys.kIsBtcUnit: isBtcUnit,
      SharedPrefsKeys.kNumberFormatPreset: preset.name,
      SharedPrefsKeys.kLanguage: 'en',
    });
    await SharedPrefsRepository().init();
    return VisibilityProvider(isSigningOnlyMode: true);
  }

  PsbtConfirmationViewModel viewModelFor(String psbtBase64, VisibilityProvider vp, SignProvider sp) {
    sp.setVaultListItem(_item(ownerVault));
    sp.saveUnsignedPsbt(psbtBase64);
    return PsbtConfirmationViewModel(sp, vp);
  }

  String batchPsbt() {
    final utxo = Utxo(Codec.encodeHex(Hash.sha256('qa-confirmation-batch')), 0, 300000000, "m/84'/1'/0'/0/0");
    final tx = Transaction.forBatchPayment(
      [utxo],
      {recipientA: 123456789, recipientB: 50000000},
      '${ownerVault.derivationPath}/1/0',
      3,
      ownerVault,
    );
    return Psbt.fromTransaction(tx, ownerVault).serialize();
  }

  group('PsbtConfirmationViewModel.setTxInfo batch recipient labels', () {
    test('BTC 단위 + dotDecimal preset: 소수점 "." + 4자리 묶음', () async {
      final vp = await visibility(isBtcUnit: true, preset: NumberFormatPreset.dotDecimal);
      final sp = SignProvider();
      final vm = viewModelFor(batchPsbt(), vp, sp);

      vm.setTxInfo();

      expect(vm.recipientAddress, containsAll(['$recipientA (1.2345 6789 ${t.btc})', '$recipientB (0.5 ${t.btc})']));
      expect(vm.recipientAddress.length, 2);
      expect(sp.recipientAmounts, {recipientA: 1.23456789, recipientB: 0.5});
      expect(vm.sendingAmount, 173456789);
    });

    test('BTC 단위 + commaDecimal preset: 소수점 ","', () async {
      final vp = await visibility(isBtcUnit: true, preset: NumberFormatPreset.commaDecimal);
      final vm = viewModelFor(batchPsbt(), vp, SignProvider());

      vm.setTxInfo();

      expect(vm.recipientAddress, containsAll(['$recipientA (1,2345 6789 ${t.btc})', '$recipientB (0,5 ${t.btc})']));
    });

    test('sats 단위 + commaDecimal preset: 천 단위 구분자 "."', () async {
      final vp = await visibility(isBtcUnit: false, preset: NumberFormatPreset.commaDecimal);
      final vm = viewModelFor(batchPsbt(), vp, SignProvider());

      vm.setTxInfo();

      expect(
        vm.recipientAddress,
        containsAll(['$recipientA (123.456.789 ${t.sats})', '$recipientB (50.000.000 ${t.sats})']),
      );
    });

    test('sats 단위 + swiss preset: 천 단위 구분자 U+2019', () async {
      final vp = await visibility(isBtcUnit: false, preset: NumberFormatPreset.swiss);
      final vm = viewModelFor(batchPsbt(), vp, SignProvider());

      vm.setTxInfo();

      expect(vm.recipientAddress, contains('$recipientA (123’456’789 ${t.sats})'));
    });
  });

  group('PsbtConfirmationViewModel.setTxInfo single recipient', () {
    test('단일 수신자는 주소만 라벨로, SignProvider에 수신 주소·금액 저장', () async {
      final vp = await visibility(isBtcUnit: true, preset: NumberFormatPreset.commaDecimal);
      final sp = SignProvider();
      final utxo = Utxo(Codec.encodeHex(Hash.sha256('qa-confirmation-single')), 0, 100000, "m/84'/1'/0'/0/0");
      final tx = Transaction.forSinglePayment(
        [utxo],
        recipientA,
        '${ownerVault.derivationPath}/1/0',
        15000,
        3,
        ownerVault,
      );
      final vm = viewModelFor(Psbt.fromTransaction(tx, ownerVault).serialize(), vp, sp);

      vm.setTxInfo();

      expect(vm.recipientAddress, [recipientA]);
      expect(vm.isSendingToMyAddress, isFalse);
      expect(sp.recipientAddress, recipientA);
      expect(sp.sendingAmount, 15000);
    });
  });
}

SingleSignatureVault _vault(String passphrase) {
  return SingleSignatureVault.fromMnemonic(
    utf8.encode('machine crack daughter fish credit glare raven fever tunnel delay fish record'),
    passphrase: utf8.encode(passphrase),
  );
}

SingleSigVaultListItem _item(SingleSignatureVault vault) {
  return SingleSigVaultListItem(
    id: 1,
    name: 'owner',
    colorIndex: 0,
    iconIndex: 0,
    descriptor: vault.descriptor,
    signerBsmsByAddressType: {AddressType.p2wpkh: ''},
    createdAt: DateTime(2026),
  );
}
