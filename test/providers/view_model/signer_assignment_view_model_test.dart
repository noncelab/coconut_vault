import 'dart:convert';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/enums/hardware_wallet_type_enum.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/model/single_sig/single_sig_vault_list_item.dart';
import 'package:coconut_vault/providers/view_model/signer_assignment_view_model.dart';
import 'package:coconut_vault/providers/view_model/vault_creation/vault_name_and_icon_setup_view_model.dart';
import 'package:coconut_vault/providers/wallet_creation/wallet_creation_provider.dart';
import 'package:coconut_vault/screens/vault_creation/multisig/signer_assignment_screen.dart';
import 'package:coconut_vault/utils/bip/signer_bsms.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/signer_creation_fakes.dart';

SignerBsms _signerBsmsOf(SingleSigVaultListItem vault) =>
    SignerBsms.parse(vault.getSignerBsmsByAddressType(AddressType.p2wsh, withLabel: false));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => NetworkType.setNetworkType(NetworkType.mainnet));

  late FakeWalletProvider walletProvider;
  late WalletCreationProvider creationProvider;
  late SignerAssignmentViewModel viewModel;

  setUp(() {
    walletProvider = FakeWalletProvider();
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
    walletProvider.addVault(makeSingleSig(id: 7, mnemonic: mnemonicA));

    final assigned = viewModel.assignedVaultList[1];
    expect(assigned.importKeyType, ImportKeyType.internal);
    expect(assigned.singleSigVaultListItem?.id, 7);
    expect(viewModel.assignedVaultList[0].importKeyType, isNull);
    expect(viewModel.unselectedSignerOptions, isEmpty);
    // 지갑 추가 알림이 이름 화면의 저장 분기보다 먼저 오므로, 플래그는 이름 화면이 끌 때까지 남아 있어야 한다
    expect(creationProvider.isCreatingSignerForMultisig, isTrue);
  });

  test('만들러 가지 않았을 때 추가된 지갑은 목록에만 들어간다', () {
    walletProvider.addVault(makeSingleSig(id: 7, mnemonic: mnemonicA));

    expect(viewModel.unselectedSignerOptions.map((o) => o.singlesigVaultListItem.id), [7]);
    expect(viewModel.getAssignedVaultListLength(), 0);
  });

  test('이미 채워진 자리에는 배정하지 않는다', () {
    walletProvider.addVault(makeSingleSig(id: 7, mnemonic: mnemonicA));
    viewModel.assignInternalSigner(0, 1);

    viewModel.prepareSignerCreation(1);
    walletProvider.addVault(makeSingleSig(id: 8, mnemonic: mnemonicB));

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
    creationProvider.setSecretAndPassphrase(Uint8List.fromList(utf8.encode(mnemonicA)), null);
    final nameViewModel = VaultNameAndIconSetupViewModel(
      walletProvider,
      creationProvider,
      FakeAuthProvider(),
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
  test('니모닉을 만든 뒤 저장하지 않고 돌아와도 멀티시그 저장 상태가 된다', () {
    viewModel.prepareSignerCreation(0);
    // 생성 화면이 '다음'에서 secret을 넣고, 뒤로 나오며 버퍼를 0으로만 채운 상태
    creationProvider.setSecretAndPassphrase(Uint8List(16), null);

    expect(viewModel.finishSignerCreation(), isFalse);
    viewModel.saveSignersToProvider([]);

    expect(creationProvider.secret, isEmpty);
    expect(creationProvider.isCreatingSignerForMultisig, isFalse);
    expect(creationProvider.walletType, WalletType.multiSignature);
  });

  test('secret이 남아 있어도 멀티시그 저장 직전에 비운다', () {
    creationProvider.setSecretAndPassphrase(Uint8List.fromList(utf8.encode(mnemonicA)), null);

    viewModel.saveSignersToProvider([]);

    expect(creationProvider.walletType, WalletType.multiSignature);
  });

  test('돌아온 뒤 추가된 지갑은 이전에 만들러 간 자리에 배정하지 않는다', () {
    viewModel.prepareSignerCreation(1);
    viewModel.finishSignerCreation();

    walletProvider.addVault(makeSingleSig(id: 7, mnemonic: mnemonicA));

    expect(viewModel.getAssignedVaultListLength(), 0);
  });

  group('다른 자리에 외부 키로 가져온 키와 같은 지갑', () {
    late SingleSigVaultListItem sameKeyVault;

    setUp(() {
      sameKeyVault = makeSingleSig(id: 7, mnemonic: mnemonicA);
      viewModel.setAssignedVaultList(
        0,
        ImportKeyType.external,
        false,
        _signerBsmsOf(sameKeyVault),
        null,
        HardwareWalletType.keystone,
      );
    });

    test('새로 만들어도 배정하지 않고 돌아올 때 알린다', () {
      viewModel.prepareSignerCreation(1);
      walletProvider.addVault(sameKeyVault);

      expect(viewModel.assignedVaultList[1].importKeyType, isNull);
      expect(viewModel.finishSignerCreation(), isTrue);
      // 알림은 한 번만
      expect(viewModel.finishSignerCreation(), isFalse);
    });

    test('선택지에서 빠지고 직접 배정해도 무시된다', () {
      walletProvider.addVault(sameKeyVault);

      expect(viewModel.assignableSignerOptions, isEmpty);
      viewModel.assignInternalSigner(0, 1);
      expect(viewModel.assignedVaultList[1].importKeyType, isNull);
      expect(viewModel.unselectedSignerOptions, hasLength(1));
    });

    test('외부 키를 지우면 다시 고를 수 있다', () {
      walletProvider.addVault(sameKeyVault);

      viewModel.assignedVaultList[0].reset();

      expect(viewModel.assignableSignerOptions.map((o) => o.singlesigVaultListItem.id), [7]);
    });
  });

  test('저장 후 이름 화면이 뒤로 가기처럼 pop되어도 dispose 정리가 예외 없이 끝난다', () async {
    viewModel.prepareSignerCreation(0);
    creationProvider.setSecretAndPassphrase(Uint8List.fromList(utf8.encode(mnemonicA)), null);
    final nameViewModel = VaultNameAndIconSetupViewModel(
      walletProvider,
      creationProvider,
      FakeAuthProvider(),
      initialName: 'new key',
      initialIconIndex: 0,
      initialColorIndex: 0,
      isImported: false,
    );
    await nameViewModel.saveNewVault();

    // popUntil이 이름 화면의 PopScope에 didPop: true를 넘긴다
    nameViewModel.setPoppedByBack(true);

    expect(nameViewModel.handleDisposeReset, returnsNormally);
  });
}
