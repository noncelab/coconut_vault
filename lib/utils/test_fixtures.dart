import 'dart:convert';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:flutter/foundation.dart';

import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/model/single_sig/single_sig_wallet_create_dto.dart';
import 'package:coconut_vault/model/taproot/creation/inheritance_leaf.dart';
import 'package:coconut_vault/model/taproot/creation/taproot_wallet_create_dto.dart';
import 'package:coconut_vault/model/taproot/seed_source.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';

/// 개발/테스트 빌드 전용 테스트 지갑 픽스처 로더.
/// 릴리즈 빌드에서는 kDebugMode 조건 때문에 호출되지 않아야 합니다.
Future<void> loadTestWallets(WalletProvider walletProvider) async {
  assert(kDebugMode, 'loadTestWallets is only available in debug builds');

  const lockTime = 1786892400; // 2026-08-16 00:00:00 KST

  Uint8List mnemonic(String words) => Uint8List.fromList(utf8.encode(words));
  Uint8List passphrase(String? value) =>
      value == null || value.isEmpty ? Uint8List(0) : Uint8List.fromList(utf8.encode(value));

  // --- SingleSig ---
  final singleNoPass = await walletProvider.addSingleSigVault(
    SingleSigWalletCreateDto(
      null,
      'single_no_pass',
      1,
      1,
      mnemonic('chair mechanic law black leopard arctic punch flock census shrug able oval'),
      passphrase(null),
    ),
  );

  final singleWithPass = await walletProvider.addSingleSigVault(
    SingleSigWalletCreateDto(
      null,
      'single_with_pass',
      1,
      2,
      mnemonic('chair mechanic law black leopard arctic punch flock census shrug able oval'),
      passphrase('1'),
    ),
  );

  // --- Multisig 2-of-2 (singleNoPass + singleWithPass) ---
  final singleNoPassBsms = singleNoPass.getSignerBsmsByAddressType(AddressType.p2wsh, withLabel: false);
  final singleWithPassBsms = singleWithPass.getSignerBsmsByAddressType(AddressType.p2wsh, withLabel: false);

  await walletProvider.addMultisigVault(
    'multisig_2of2',
    1,
    3,
    [
      MultisigSigner(id: 0, keyStore: KeyStore.fromSignerBsms(singleNoPassBsms), signerBsms: singleNoPassBsms),
      MultisigSigner(id: 1, keyStore: KeyStore.fromSignerBsms(singleWithPassBsms), signerBsms: singleWithPassBsms),
    ],
    2,
    isImported: true,
  );

  // --- Taproot MuSig2 inheritance ---
  await walletProvider.addTaprootVault(
    TaprootWalletCreateDto(
      null,
      'taproot_musig2_inheritance',
      1,
      4,
      [
        SeedSource(
          mnemonic: mnemonic('chair mechanic law black leopard arctic punch flock census shrug able oval'),
          passphrase: passphrase(null),
        ),
      ],
      [
        _taprootKeyPathSignerBsms(
          mnemonic('chair mechanic law black leopard arctic punch flock census shrug able oval'),
          passphrase('1'),
        ),
      ],
      [
        InheritanceLeaf(
          secret: SeedSource(
            mnemonic: mnemonic('chair mechanic law black leopard arctic punch flock census shrug able oval'),
            passphrase: passphrase('2'),
          ),
          lockTime: lockTime,
        ),
      ],
    ),
  );

  // --- Taproot single parent inheritance ---
  await walletProvider.addTaprootVault(
    TaprootWalletCreateDto(
      null,
      'taproot_single_inheritance',
      1,
      5,
      [],
      [
        _taprootKeyPathSignerBsms(
          mnemonic('chair mechanic law black leopard arctic punch flock census shrug able oval'),
          passphrase('1'),
        ),
      ],
      [
        InheritanceLeaf(
          secret: SeedSource(
            mnemonic: mnemonic('chair mechanic law black leopard arctic punch flock census shrug able oval'),
            passphrase: passphrase('2'),
          ),
          lockTime: lockTime,
        ),
      ],
    ),
  );
}

String _taprootKeyPathSignerBsms(Uint8List mnemonicBytes, Uint8List passphraseBytes) {
  final seed = Seed.fromMnemonic(mnemonicBytes, passphrase: passphraseBytes);
  final keyStore = KeyStore.fromSeed(seed, AddressType.p2tr);
  final vault = TaprootVault.fromKeyStoreList([keyStore], []);
  return vault.getSignerBsms('');
}
