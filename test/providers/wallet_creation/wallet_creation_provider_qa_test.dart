// QA generated host test (logic_coverage.autofill)
// Targets: WalletCreationProvider.externalSignerContext / setExternalSignerContext (new, b49d40ee)
// Intent (b49d40ee): 기존 externalSigner + multisigVaultIdOfExternalSigner 두 필드를 ExternalSignerContext 하나로
//   묶는다. set한 컨텍스트를 그대로 돌려주고, resetAll()은 (이전 두 필드처럼) 컨텍스트도 지운다.
//   resetSecretAndPassphrase/resetSigner는 컨텍스트를 지우지 않는다(이전 코드도 resetAll에서만 지움).
// Real classes: WalletCreationProvider, ExternalSignerContext, MultisigSigner.
import 'dart:convert';
import 'dart:typed_data';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/model/multisig/external_signer_context.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/providers/wallet_creation/wallet_creation_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => NetworkType.setNetworkType(NetworkType.regtest));

  ExternalSignerContext context({int? vaultId = 7}) {
    final vault = SingleSignatureVault.fromMnemonic(
      utf8.encode('machine crack daughter fish credit glare raven fever tunnel delay fish record'),
      passphrase: utf8.encode('wcp'),
    );
    final signer = MultisigSigner(
      id: 1,
      name: 'ext',
      keyStore: KeyStore.fromSeed(vault.keyStore.seed, AddressType.p2wsh),
    );
    return ExternalSignerContext(signer: signer, multisigVaultId: vaultId);
  }

  test('초기값은 null', () {
    expect(WalletCreationProvider().externalSignerContext, isNull);
  });

  test('setExternalSignerContext로 넣은 컨텍스트를 그대로 돌려준다', () {
    final provider = WalletCreationProvider();
    final ctx = context();

    provider.setExternalSignerContext(ctx);

    expect(provider.externalSignerContext, same(ctx));
    expect(provider.externalSignerContext!.multisigVaultId, 7);
  });

  test('다시 set하면 최신 컨텍스트로 교체된다', () {
    final provider = WalletCreationProvider();
    provider.setExternalSignerContext(context(vaultId: 1));
    final second = context(vaultId: null);

    provider.setExternalSignerContext(second);

    expect(provider.externalSignerContext, same(second));
    expect(provider.externalSignerContext!.multisigVaultId, isNull);
  });

  test('resetAll은 컨텍스트를 지운다', () {
    final provider = WalletCreationProvider();
    provider.setSecretAndPassphrase(Uint8List.fromList(utf8.encode('secret')), null);
    provider.setExternalSignerContext(context());

    provider.resetAll();

    expect(provider.externalSignerContext, isNull);
  });

  test('resetSecretAndPassphrase / resetSigner는 컨텍스트를 유지한다', () {
    final provider = WalletCreationProvider();
    final ctx = context();
    provider.setSecretAndPassphrase(Uint8List.fromList(utf8.encode('secret')), null);
    provider.setExternalSignerContext(ctx);

    provider.resetSecretAndPassphrase();
    provider.resetSigner();

    expect(provider.externalSignerContext, same(ctx));
  });

  test('컨텍스트가 있어도 secret만 있으면 walletType은 singleSignature', () {
    final provider = WalletCreationProvider();
    provider.setSecretAndPassphrase(Uint8List.fromList(utf8.encode('secret')), null);
    provider.setExternalSignerContext(context());

    expect(provider.walletType, WalletType.singleSignature);
  });
}
