import 'dart:convert';
import 'dart:typed_data';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/model/single_sig/single_sig_vault_list_item.dart';
import 'package:coconut_vault/utils/nfkd_util.dart';
import 'package:coconut_vault/utils/reentered_passphrase_verifier.dart';
import 'package:flutter_test/flutter_test.dart';

const _mnemonic =
    'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

Uint8List _mnemonicBytes() => Uint8List.fromList(utf8.encode(_mnemonic));

/// [passphraseBytes]로 만든 싱글시그 지갑. 저장된 MFP가 이 바이트로 결정된다.
SingleSigVaultListItem _walletCreatedWith(Uint8List passphraseBytes) {
  final vault = SingleSignatureVault.fromMnemonic(
    _mnemonicBytes(),
    addressType: AddressType.p2wpkh,
    passphrase: Uint8List.fromList(passphraseBytes),
  );
  return SingleSigVaultListItem(
    id: 1,
    name: 'wallet',
    colorIndex: 0,
    iconIndex: 0,
    descriptor: vault.descriptor,
    signerBsmsByAddressType: {AddressType.p2wsh: vault.getSignerBsms(AddressType.p2wsh, '')},
    createdAt: DateTime.now(),
  );
}

Future<({Map<String, dynamic> result, Uint8List passphrase})> _verify(
  SingleSigVaultListItem wallet,
  String passphrase,
) {
  return verifyReenteredPassphrase(mnemonic: _mnemonicBytes(), passphrase: passphrase, vaultListItem: wallet);
}

void main() {
  const korean = '코코넛2026';
  final nfkdBytes = NfkdUtil.encodeNfkd(korean);
  final legacyBytes = Uint8List.fromList(utf8.encode(korean));

  group('verifyReenteredPassphrase', () {
    test('NFKD로 만든 지갑은 NFKD 바이트로 일치한다', () async {
      final verification = await _verify(_walletCreatedWith(nfkdBytes), korean);

      expect(verification.result['success'], isTrue);
      expect(verification.passphrase, nfkdBytes);
    });

    test('3.2.0 이하 방식(정규화하지 않은 UTF-8)으로 만든 지갑은 원문 바이트로 일치한다', () async {
      final verification = await _verify(_walletCreatedWith(legacyBytes), korean);

      expect(verification.result['success'], isTrue);
      expect(verification.passphrase, legacyBytes);
    });

    test('틀린 패스프레이즈는 실패하고 NFKD 후보의 결과를 돌려준다', () async {
      final verification = await _verify(_walletCreatedWith(nfkdBytes), '코코넛2025');

      expect(verification.result['success'], isFalse);
      expect(verification.passphrase, NfkdUtil.encodeNfkd('코코넛2025'));
    });

    test('정규화로 바뀌지 않는 패스프레이즈는 기존과 같이 동작한다', () async {
      final wallet = _walletCreatedWith(Uint8List.fromList(utf8.encode('coconut')));

      expect((await _verify(wallet, 'coconut')).result['success'], isTrue);
      expect((await _verify(wallet, 'coconut2')).result['success'], isFalse);
    });

    test('패스프레이즈 없는 지갑은 빈 입력으로 일치한다', () async {
      final verification = await _verify(_walletCreatedWith(Uint8List(0)), '');

      expect(verification.result['success'], isTrue);
      expect(verification.passphrase, isEmpty);
    });
  });
}
