// QA generated host test (logic_coverage.autofill)
// Target: VaultNameAndIconSetupViewModel._saveSingleSigVault (via public saveNewVault)
//   added condition: externalSignerContext != null   (removed: externalSigner != null)
// Intent (b49d40ee): 멀티시그 상세화면 '키 추가'로 들어온 싱글시그 저장은 저장 후 그 멀티시그 지갑의
//   설정 정보 화면으로 돌아간다(navigateToMultisigSetupInfo(multisigVaultId: 컨텍스트의 vault id)).
//   컨텍스트가 없으면 홈으로(addedWalletId). 두 경우 모두 WalletCreationProvider는 resetAll.
// Real classes: VaultNameAndIconSetupViewModel, WalletCreationProvider, ExternalSignerContext.
// Boundary fakes: WalletProvider (secure storage/isolate wallet creation) and AuthProvider (biometrics),
//   only the members the view model touches.
import 'dart:convert';
import 'dart:typed_data';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/model/multisig/external_signer_context.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/model/single_sig/single_sig_vault_list_item.dart';
import 'package:coconut_vault/model/single_sig/single_sig_wallet_create_dto.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/view_model/vault_creation/vault_name_and_icon_setup_view_model.dart';
import 'package:coconut_vault/providers/wallet_creation/wallet_creation_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

const _mnemonic = 'machine crack daughter fish credit glare raven fever tunnel delay fish record';

void main() {
  setUp(() => NetworkType.setNetworkType(NetworkType.regtest));

  ExternalSignerContext ctx(int? multisigVaultId) {
    final vault = SingleSignatureVault.fromMnemonic(utf8.encode(_mnemonic), passphrase: utf8.encode('ext'));
    return ExternalSignerContext(
      signer: MultisigSigner(id: 0, name: 'ext', keyStore: KeyStore.fromSeed(vault.keyStore.seed, AddressType.p2wsh)),
      multisigVaultId: multisigVaultId,
    );
  }

  ({VaultNameAndIconSetupViewModel vm, _FakeWalletProvider wallet, WalletCreationProvider creation}) build({
    ExternalSignerContext? context,
    String name = '  my key  ',
  }) {
    final wallet = _FakeWalletProvider();
    final creation = WalletCreationProvider()..setSecretAndPassphrase(Uint8List.fromList(utf8.encode(_mnemonic)), null);
    if (context != null) creation.setExternalSignerContext(context);
    final vm = VaultNameAndIconSetupViewModel(
      wallet,
      creation,
      _FakeAuthProvider(),
      initialName: name,
      initialIconIndex: 3,
      initialColorIndex: 4,
      isImported: true,
    );
    return (vm: vm, wallet: wallet, creation: creation);
  }

  test('externalSignerContext가 있으면 그 멀티시그 vault id로 navigateMultisigSetupInfo, provider는 초기화', () async {
    final s = build(context: ctx(77));

    final result = await s.vm.saveNewVault();

    expect(result.status, VaultNameAndIconSetupSaveStatus.navigateMultisigSetupInfo);
    expect(result.multisigVaultId, 77);
    expect(result.addedWalletId, isNull);
    expect(s.wallet.addedDtos, hasLength(1));
    expect(s.creation.externalSignerContext, isNull);
    expect(s.creation.secret, isEmpty);
  });

  test('externalSignerContext의 multisigVaultId가 null이어도 navigateMultisigSetupInfo(null)', () async {
    final s = build(context: ctx(null));

    final result = await s.vm.saveNewVault();

    expect(result.status, VaultNameAndIconSetupSaveStatus.navigateMultisigSetupInfo);
    expect(result.multisigVaultId, isNull);
    expect(s.creation.externalSignerContext, isNull);
  });

  test('externalSignerContext가 없으면 추가된 지갑 id로 navigateHome, provider는 초기화', () async {
    final s = build();

    final result = await s.vm.saveNewVault();

    expect(result.status, VaultNameAndIconSetupSaveStatus.navigateHome);
    expect(result.addedWalletId, _FakeWalletProvider.addedId);
    expect(result.multisigVaultId, isNull);
    expect(s.creation.secret, isEmpty);
  });

  test('저장 DTO에 trim된 이름, 아이콘/색상, provider의 secret이 들어간다', () async {
    final s = build(context: ctx(1));

    await s.vm.saveNewVault();

    final dto = s.wallet.addedDtos.single;
    expect(dto.name, 'my key');
    expect(dto.icon, 3);
    expect(dto.color, 4);
    expect(dto.mnemonicSnapshot, utf8.encode(_mnemonic));
    expect(dto.passphrase, isNull);
    expect(s.vm.showLoading, isFalse);
  });

  test('이름이 중복이면 저장하지 않고 duplicateName, 컨텍스트 유지', () async {
    final context = ctx(9);
    final s = build(context: context, name: 'dup');
    s.wallet.duplicatedNames.add('dup');

    final result = await s.vm.saveNewVault();

    expect(result.status, VaultNameAndIconSetupSaveStatus.duplicateName);
    expect(s.wallet.addedDtos, isEmpty);
    expect(s.creation.externalSignerContext, same(context));
  });
}

class _AddedDto {
  _AddedDto(SingleSigWalletCreateDto dto)
    : name = dto.name,
      icon = dto.icon,
      color = dto.color,
      mnemonicSnapshot = dto.mnemonic == null ? null : List<int>.from(dto.mnemonic!),
      passphrase = dto.passphrase;
  final String? name;
  final int? icon;
  final int? color;
  final List<int>? mnemonicSnapshot;
  final Uint8List? passphrase;
}

class _FakeWalletProvider implements WalletProvider {
  static const addedId = 11;
  final List<_AddedDto> addedDtos = [];
  final Set<String> duplicatedNames = {};

  @override
  final ValueNotifier<bool> isVaultListLoadingNotifier = ValueNotifier<bool>(false);

  @override
  bool get isVaultListLoading => false;

  @override
  bool get isSigningOnlyMode => false;

  @override
  bool isNameDuplicated(String name) => duplicatedNames.contains(name);

  @override
  Future<SingleSigVaultListItem> addSingleSigVault(SingleSigWalletCreateDto wallet) async {
    addedDtos.add(_AddedDto(wallet));
    final vault = SingleSignatureVault.fromMnemonic(utf8.encode(_mnemonic));
    return SingleSigVaultListItem(
      id: addedId,
      name: wallet.name!,
      colorIndex: wallet.color!,
      iconIndex: wallet.icon!,
      descriptor: vault.descriptor,
      signerBsmsByAddressType: {AddressType.p2wpkh: ''},
      createdAt: DateTime(2026),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthProvider implements AuthProvider {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
