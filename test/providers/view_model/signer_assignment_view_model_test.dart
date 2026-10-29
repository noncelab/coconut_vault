import 'dart:convert';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/model/single_sig/single_sig_vault_list_item.dart';
import 'package:coconut_vault/model/single_sig/single_sig_wallet_create_dto.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/view_model/signer_assignment_view_model.dart';
import 'package:coconut_vault/providers/view_model/vault_creation/vault_name_and_icon_setup_view_model.dart';
import 'package:coconut_vault/providers/wallet_creation/wallet_creation_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/screens/vault_creation/multisig/signer_assignment_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

const _mnemonicA = 'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
const _mnemonicB = 'hope disorder index rather outdoor response rain range genuine oil banana feed';

class _FakeWalletProvider extends ChangeNotifier implements WalletProvider {
  final List<VaultListItemBase> _vaults = [];

  @override
  List<VaultListItemBase> getVaults() => List.unmodifiable(_vaults);

  @override
  final ValueNotifier<bool> isVaultListLoadingNotifier = ValueNotifier<bool>(false);

  @override
  bool get isSigningOnlyMode => false;

  @override
  bool isNameDuplicated(String name) => false;

  /// 실제 구현처럼 저장 직후 동기적으로 notifyListeners 한다.
  @override
  Future<SingleSigVaultListItem> addSingleSigVault(SingleSigWalletCreateDto wallet) async {
    final vault = _makeSingleSig(id: 100 + _vaults.length, mnemonic: utf8.decode(wallet.mnemonic!));
    addVault(vault);
    return vault;
  }

  void addVault(VaultListItemBase vault) {
    _vaults.add(vault);
    notifyListeners();
  }

  bool get isListened => hasListeners;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthProvider extends Fake implements AuthProvider {}

SingleSigVaultListItem _makeSingleSig({required int id, required String mnemonic}) {
  final keyStore = KeyStore.fromMnemonic(Uint8List.fromList(utf8.encode(mnemonic)), AddressType.p2wpkh);
  final descriptor = Descriptor.forSingleSignature(AddressType.p2wpkh, keyStore, "84'/0'/0'");
  final vault = SingleSignatureVault.fromKeyStore(keyStore, accountIndex: 0);

  return SingleSigVaultListItem(
    id: id,
    name: 'single-$id',
    colorIndex: 0,
    iconIndex: 0,
    descriptor: descriptor.serialize(),
    signerBsmsByAddressType: {AddressType.p2wsh: vault.getSignerBsms(AddressType.p2wsh, '')},
    createdAt: DateTime(2026),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => NetworkType.setNetworkType(NetworkType.mainnet));

  late _FakeWalletProvider walletProvider;
  late WalletCreationProvider creationProvider;
  late SignerAssignmentViewModel viewModel;

  setUp(() {
    walletProvider = _FakeWalletProvider();
    creationProvider = WalletCreationProvider()..setQuorumRequirement(2, 3);
    viewModel = SignerAssignmentViewModel(walletProvider, creationProvider);
  });

  test('단일 서명 지갑을 만들러 가면 생성 상태를 비우고 복귀 플래그를 켠다', () {
    viewModel.prepareSignerCreation(1);

    expect(creationProvider.isCreatingSignerForMultisig, isTrue);
    expect(creationProvider.requiredSignatureCount, isNull);
  });

  test('새 단일 서명 지갑이 추가되면 만들러 간 자리에 배정한다', () {
    viewModel.prepareSignerCreation(1);
    walletProvider.addVault(_makeSingleSig(id: 7, mnemonic: _mnemonicA));

    final assigned = viewModel.assignedVaultList[1];
    expect(assigned.importKeyType, ImportKeyType.internal);
    expect(assigned.singleSigVaultListItem?.id, 7);
    expect(viewModel.assignedVaultList[0].importKeyType, isNull);
    expect(viewModel.unselectedSignerOptions, isEmpty);
    // 지갑 추가 알림이 이름 화면의 저장 분기보다 먼저 오므로, 플래그는 이름 화면이 끌 때까지 남아 있어야 한다
    expect(creationProvider.isCreatingSignerForMultisig, isTrue);
  });

  test('만들러 가지 않았을 때 추가된 지갑은 목록에만 들어간다', () {
    walletProvider.addVault(_makeSingleSig(id: 7, mnemonic: _mnemonicA));

    expect(viewModel.unselectedSignerOptions.map((o) => o.singlesigVaultListItem.id), [7]);
    expect(viewModel.getAssignedVaultListLength(), 0);
  });

  test('이미 채워진 자리에는 배정하지 않는다', () {
    walletProvider.addVault(_makeSingleSig(id: 7, mnemonic: _mnemonicA));
    viewModel.assignInternalSigner(0, 1);

    viewModel.prepareSignerCreation(1);
    walletProvider.addVault(_makeSingleSig(id: 8, mnemonic: _mnemonicB));

    expect(viewModel.assignedVaultList[1].singleSigVaultListItem?.id, 7);
    expect(viewModel.unselectedSignerOptions.map((o) => o.singlesigVaultListItem.id), [8]);
  });

  test('멀티시그 저장 직전에 지워진 정족수를 다시 넣는다', () {
    viewModel.prepareSignerCreation(0);

    viewModel.saveSignersToProvider([]);

    expect(creationProvider.requiredSignatureCount, 2);
    expect(creationProvider.totalSignatureCount, 3);
    expect(creationProvider.walletType, WalletType.multiSignature);
  });

  test('화면을 벗어나면 복귀 플래그를 끄고 지갑 목록 구독을 해제한다', () {
    viewModel.prepareSignerCreation(0);
    viewModel.dispose();

    expect(creationProvider.isCreatingSignerForMultisig, isFalse);
    expect(walletProvider.isListened, isFalse);
  });

  test('이름 화면에서 저장하면 키 배정 화면으로 돌아가고 새 키가 배정된다', () async {
    viewModel.prepareSignerCreation(2);
    creationProvider.setSecretAndPassphrase(Uint8List.fromList(utf8.encode(_mnemonicA)), null);
    final nameViewModel = VaultNameAndIconSetupViewModel(
      walletProvider,
      creationProvider,
      _FakeAuthProvider(),
      initialName: 'new key',
      initialIconIndex: 0,
      initialColorIndex: 0,
      isImported: false,
    );

    final result = await nameViewModel.saveNewVault();

    expect(result.status, VaultNameAndIconSetupSaveStatus.navigateSignerAssignment);
    expect(viewModel.assignedVaultList[2].importKeyType, ImportKeyType.internal);
    expect(viewModel.assignedVaultList[2].singleSigVaultListItem?.id, result.addedWalletId);
    expect(creationProvider.isCreatingSignerForMultisig, isFalse);
  });
}
