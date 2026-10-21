// QA generated host test (logic_coverage.autofill)
// Target: ExternalSignerContext constructor (new, b49d40ee)
// Intent (b49d40ee + class doc): 멀티시그 상세화면 '키 추가' 플로우의 매개변수(추가할 키의 서명자 정보 [signer]와
//   키 추가를 호출한 멀티시그 지갑 id [multisigVaultId])를 한 묶음으로 전달한다. multisigVaultId는 선택값.
// Real classes: ExternalSignerContext, MultisigSigner, coconut_lib KeyStore.
import 'dart:convert';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/model/multisig/external_signer_context.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => NetworkType.setNetworkType(NetworkType.regtest));

  MultisigSigner signer() {
    final vault = SingleSignatureVault.fromMnemonic(
      utf8.encode('machine crack daughter fish credit glare raven fever tunnel delay fish record'),
      passphrase: utf8.encode('ctx'),
    );
    return MultisigSigner(
      id: 2,
      name: 'external key',
      keyStore: KeyStore.fromSeed(vault.keyStore.seed, AddressType.p2wsh),
    );
  }

  test('signer와 multisigVaultId를 그대로 묶는다', () {
    final s = signer();
    final context = ExternalSignerContext(signer: s, multisigVaultId: 42);

    expect(context.signer, same(s));
    expect(context.multisigVaultId, 42);
  });

  test('multisigVaultId는 선택값이며 생략하면 null', () {
    final s = signer();
    final context = ExternalSignerContext(signer: s);

    expect(context.signer, same(s));
    expect(context.multisigVaultId, isNull);
  });
}
