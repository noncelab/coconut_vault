import 'dart:convert';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/isolates/musig2_first_signer_isolate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MuSig2FirstSignerIsolate', () {
    late SingleSignatureVault signer1;
    late SingleSignatureVault signer2;
    late KeyStore keyStore1;
    late KeyStore keyStore2;
    late TaprootVault vault;

    setUp(() {
      NetworkType.setNetworkType(NetworkType.regtest);
      signer1 = _createP2wpkhVault(passphrase: 'signer-1');
      signer2 = _createP2wpkhVault(passphrase: 'signer-2');
      keyStore1 = KeyStore.fromSeed(signer1.keyStore.seed, AddressType.p2tr);
      keyStore2 = KeyStore.fromSeed(signer2.keyStore.seed, AddressType.p2tr);
      vault = TaprootVault.fromKeyStoreList([keyStore1, keyStore2], []);
    });

    test(
      'first signer can add public nonce and later finalize with the same isolate',
      () async {
        final unsignedPsbt = _createUnsignedPsbt(vault);
        final coordinatorBsms = vault.getCoordinatorBsms();

        final firstSignerIsolate = MuSig2FirstSignerIsolate();
        await firstSignerIsolate.initialize();

        // 1. 첫 번째 서명자가 public nonce 추가
        final nonceAddedPsbt = await firstSignerIsolate.addPublicNonce(
          coordinatorBsms,
          unsignedPsbt.serialize(),
          signer1.keyStore.seed,
        );

        // 2. 두 번째 서명자가 nonce + partial signature 추가
        final secondSignerVault = TaprootVault.fromCoordinatorBsms(coordinatorBsms);
        secondSignerVault.bindSeedToKeyStore(signer2.keyStore.seed);
        final secondSignerPsbt = secondSignerVault.addSignatureToPsbt(secondSignerVault.addPublicNonce(nonceAddedPsbt));

        // 3. 첫 번째 서명자가 동일 isolate에서 최종 서명
        final finalizedPsbt = await firstSignerIsolate.addSignature(secondSignerPsbt);

        // 4. 최종 PSBT 검증
        final signedTx = Psbt.parse(finalizedPsbt).getSignedTransaction(AddressType.p2tr);
        expect(Codec.decodeHex(signedTx.inputs.single.witnessList.single), hasLength(64));

        await firstSignerIsolate.dispose();
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );

    test('first signer isolate fails to finalize if addNonce was not called', () async {
      final firstSignerIsolate = MuSig2FirstSignerIsolate();
      await firstSignerIsolate.initialize();

      final unsignedPsbt = _createUnsignedPsbt(vault);

      await expectLater(
        () => firstSignerIsolate.addSignature(unsignedPsbt.serialize()),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('addNonce must be called before addSignature'),
          ),
        ),
      );

      await firstSignerIsolate.dispose();
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}

SingleSignatureVault _createP2wpkhVault({required String passphrase}) {
  return SingleSignatureVault.fromMnemonic(
    utf8.encode('machine crack daughter fish credit glare raven fever tunnel delay fish record'),
    passphrase: utf8.encode(passphrase),
  );
}

Psbt _createUnsignedPsbt(TaprootVault vault) {
  final utxo = Utxo(Codec.encodeHex(Hash.sha256('musig2-first-signer-isolate-test')), 0, 100000, "m/86'/1'/0'/0/0");
  final tx = Transaction.forSinglePayment([utxo], vault.getAddress(1), "${vault.derivationPath}/1/0", 15000, 3, vault);
  return Psbt.fromTransaction(tx, vault);
}
