import 'package:coconut_vault/screens/home/select_sync_option_bottom_sheet.dart';
import 'package:coconut_vault/screens/wallet_info/export_options_screen.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/packages/bc-ur-dart/lib/cbor_lite.dart' as local_cbor;
import 'dart:convert';
import 'dart:typed_data';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/single_sig/single_sig_vault_list_item.dart';
import 'package:coconut_vault/providers/view_model/multisig_signer_bsms_export_view_model.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/screens/wallet_info/single_sig_menu/signer_bsms_qr_screen.dart';
import 'package:coconut_vault/widgets/adaptive_qr_image.dart';
import 'package:coconut_vault/widgets/button/copy_text_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class ExportWallets extends ChangeNotifier implements WalletProvider {
  final SingleSigVaultListItem wallet;
  ExportWallets(this.wallet);
  @override
  SingleSigVaultListItem getVaultById(int id) => wallet;
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  const mnemonic = 'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
  SingleSigVaultListItem makeWallet({int account = 0, String passphrase = ''}) {
    final vault = SingleSignatureVault.fromKeyStore(
      KeyStore.fromMnemonic(
        Uint8List.fromList(utf8.encode(mnemonic)),
        AddressType.p2wpkh,
        accountIndex: account,
        passphrase: Uint8List.fromList(utf8.encode(passphrase)),
      ),
      accountIndex: account,
    );
    return SingleSigVaultListItem(
      id: 1,
      name: 'test signer',
      colorIndex: 0,
      iconIndex: 0,
      descriptor: vault.descriptor,
      signerBsmsByAddressType: {AddressType.p2wsh: vault.getSignerBsms(AddressType.p2wsh, '')},
      createdAt: DateTime(2026),
    );
  }

  tearDown(() => NetworkType.setNetworkType(NetworkType.mainnet));
  for (final network in [NetworkType.mainnet, NetworkType.testnet]) {
    test('signer export preserves BSMS BIP48 account independently of singlesig account on $network', () {
      NetworkType.setNetworkType(network);
      for (final account in [0, 2]) {
        final wallets = ExportWallets(makeWallet(account: account, passphrase: 'test-passphrase'));
        final model = MultisigSignerBsmsExportViewModel(wallets, 1);
        final bsms = Bsms.parseSigner(wallets.wallet.getSignerBsmsByAddressType(AddressType.p2wsh));
        final origin = model.signerDescriptor;
        final key = ExtendedPublicKey.parse(origin.split(']').last);
        final expected = KeyStore.fromMnemonic(
          Uint8List.fromList(utf8.encode(mnemonic)),
          AddressType.p2wsh,
          accountIndex: 0,
          passphrase: Uint8List.fromList(utf8.encode('test-passphrase')),
        );
        expect(key.serialize(), expected.extendedPublicKey.serialize(toXpub: true));
        expect(origin, startsWith('[${bsms.signer!.masterFingerPrint}/48\'/'));
        expect(origin, contains(network.isTestnet ? "/1'/" : "/0'/"));
        expect(origin, contains("/0'/2']"));
        expect(origin, isNot(contains('BSMS')));
        expect(origin, isNot(contains(mnemonic)));
        expect(model.qrData, wallets.wallet.getSignerBsmsByAddressType(AddressType.p2wsh));
        final json = jsonDecode(model.blueWalletCosigner) as Map;
        expect(json['xfp'], bsms.signer!.masterFingerPrint);
        expect(json['path'], 'm/${bsms.signer!.path}');
        expect(json['xpub'], expected.extendedPublicKey.serialize(toXpub: true));
        final decoder = local_cbor.CBORDecoder(model.sparrowAccount);
        expect(decoder.decodeTagAndValue().$2, 2); // account map
        expect(decoder.decodeInteger().$1, 1);
        expect(decoder.decodeInteger().$1, int.parse(bsms.signer!.masterFingerPrint, radix: 16));
        expect(decoder.decodeInteger().$1, 2);
        expect(decoder.decodeTagAndValue().$2, 1); // output array
        for (final tag in [308, 401, 410, 303]) {
          expect(decoder.decodeTagAndValue().$2, tag);
        }
        expect(decoder.decodeTagAndValue().$2, 6); // public HD key map
        expect(decoder.decodeInteger().$1, 2);
        expect(decoder.decodeBool().$1, false); // never a private key
        expect(decoder.decodeInteger().$1, 3);
        expect(decoder.decodeBytes().$1, expected.extendedPublicKey.publicKey);
        expect(decoder.decodeInteger().$1, 4);
        expect(decoder.decodeBytes().$1, expected.extendedPublicKey.chainCode);
        expect(decoder.decodeInteger().$1, 5);
        expect(decoder.decodeTagAndValue().$2, 305);
        expect(decoder.decodeTagAndValue().$2, 2);
        expect(decoder.decodeInteger().$1, 1);
        expect(decoder.decodeInteger().$1, 0); // Bitcoin
        expect(decoder.decodeInteger().$1, 2);
        expect(decoder.decodeInteger().$1, network.isTestnet ? 1 : 0);
        expect(decoder.decodeInteger().$1, 6);
        expect(decoder.decodeTagAndValue().$2, 304);
        expect(decoder.decodeTagAndValue().$2, 3);
        expect(decoder.decodeInteger().$1, 1);
        expect(decoder.decodeTagAndValue().$2, 8);
        for (final index in [48, network.isTestnet ? 1 : 0, 0, 2]) {
          expect(decoder.decodeInteger().$1, index);
          expect(decoder.decodeBool().$1, true);
        }
        expect(decoder.decodeInteger().$1, 2);
        expect(decoder.decodeInteger().$1, int.parse(bsms.signer!.masterFingerPrint, radix: 16));
        expect(decoder.decodeInteger().$1, 3);
        expect(decoder.decodeInteger().$1, 4); // origin depth
        expect(decoder.decodeInteger().$1, 8);
        expect(decoder.decodeInteger().$1, int.parse(expected.extendedPublicKey.parentFingerprint, radix: 16));

        model.dispose();
        wallets.dispose();
      }
    });
  }

  for (final app in WalletApp.values) {
    testWidgets('$app selection opens the correct signer QR without a format toggle', (tester) async {
      NetworkType.setNetworkType(NetworkType.mainnet);
      await tester.binding.setSurfaceSize(const Size(430, 1100));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final wallets = ExportWallets(makeWallet());
      final expected = MultisigSignerBsmsExportViewModel(wallets, 1);
      WalletApp? selectedApp;
      await tester.pumpWidget(
        ChangeNotifierProvider<WalletProvider>.value(
          value: wallets,
          child: MaterialApp(
            home: const VaultExportOptionsScreen(id: 1, walletType: WalletType.singleSignature),
            routes: {
              AppRoutes.multisigSignerBsmsExport: (context) {
                final args = ModalRoute.of(context)!.settings.arguments as Map;
                selectedApp = args['app'] as WalletApp;
                return SignerBsmsQrScreen(id: args['id'], app: selectedApp!);
              },
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.vault_menu_screen.title.use_as_multisig_signer));
      await tester.pumpAndSettle();
      expect(find.text(t.watch_only_options.title), findsOneWidget);
      final label = switch (app) {
        WalletApp.coconut => t.watch_only_options.coconut_wallet,
        WalletApp.sparrow => t.watch_only_options.sparrow,
        WalletApp.nunchuk => t.watch_only_options.nunchuk,
        WalletApp.bluewallet => t.watch_only_options.bluewallet,
      };
      await tester.tap(find.text(label));
      // Sparrow's animated QR has a repeating timer.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(selectedApp, app);
      final qr = tester.widget<AdaptiveQrImage>(find.byType(AdaptiveQrImage));
      final text = tester.widget<CopyTextContainer>(find.byType(CopyTextContainer)).text;
      switch (app) {
        case WalletApp.coconut:
          expect(qr.qrData, expected.qrData);
          expect(text, expected.qrData);
        case WalletApp.nunchuk:
          expect(qr.qrData, expected.signerDescriptor);
          expect(text, expected.signerDescriptor);
        case WalletApp.bluewallet:
          expect(jsonDecode(qr.qrData!), jsonDecode(expected.blueWalletCosigner));
          expect(text, expected.blueWalletCosigner);
        case WalletApp.sparrow:
          expect(qr.qrData, isNull);
          expect(qr.qrViewDataHandler!.nextPart().toLowerCase(), startsWith('ur:crypto-account/'));
          expect(text, expected.signerDescriptor);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      expected.dispose();
      wallets.dispose();
    });
  }
}
