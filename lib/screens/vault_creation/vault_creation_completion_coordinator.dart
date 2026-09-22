import 'dart:typed_data';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/app_routes_params.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/constants/build_config.dart';
import 'package:coconut_vault/enums/wallet_enums.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/exception/user_canceled_auth_exception.dart';
import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/view_model/vault_creation/vault_name_and_icon_setup_view_model.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/providers/wallet_creation/wallet_creation_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/utils/icon_util.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/utils/popup_util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> proceedToVaultCreationCompletion(
  BuildContext context, {
  bool isImported = false,
  bool replaceCurrentRoute = false,
  Object? routeArguments,
  VoidCallback? onLiteCreationStarted,
  VoidCallback? onLiteCreationFinished,
}) async {
  try {
    if (!kIsLiteBuild) {
      if (replaceCurrentRoute) {
        Navigator.pushReplacementNamed(context, AppRoutes.vaultNameSetup, arguments: routeArguments);
      } else {
        Navigator.pushNamed(context, AppRoutes.vaultNameSetup, arguments: routeArguments);
      }
      return;
    }

    onLiteCreationStarted?.call();
    await _createVaultInLiteBuild(context, isImported: isImported);
  } on UserCanceledAuthException catch (e) {
    Logger.error(e);
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (context) {
        return CoconutPopup(
          languageCode: context.read<VisibilityProvider>().appLanguage.code,
          title: t.errors.creation_error,
          description: t.alert.auth_canceled_when_encrypt.description,
          rightButtonText: t.confirm,
          onTapRight: () => Navigator.of(context).pop(),
        );
      },
    );
  } catch (e) {
    Logger.error(e);
    if (!context.mounted) return;
    await showInfoPopup(context, t.errors.creation_error, e.toString());
  } finally {
    if (kIsLiteBuild) {
      try {
        onLiteCreationFinished?.call();
      } catch (e) {
        Logger.error(e);
        if (context.mounted) {
          await showInfoPopup(context, t.errors.creation_error, e.toString());
        }
      }
    }
  }
}

/// 라이트 빌드 전용: 이름/아이콘 설정 화면(VaultNameAndIconSetupScreen)을 거치지 않고
/// [WalletCreationProvider]에 모인 정보로 지갑을 바로 생성한 뒤 완료 화면으로 이동한다.
///
/// 이름 규칙:
/// - 싱글시그: master fingerprint (대문자)
/// - 멀티시그: 'Multisig [descriptor checksum]' (소문자, ex. Multisig c8eu4g73)
///
/// 아이콘은 coconut, 색상은 gray로 고정한다.
Future<void> _createVaultInLiteBuild(BuildContext context, {bool isImported = false}) async {
  final walletProvider = context.read<WalletProvider>();
  final walletCreationProvider = context.read<WalletCreationProvider>();
  final authProvider = context.read<AuthProvider>();

  // 지갑 리스트 로딩이 진행 중이면 중복 이름/지갑 검사를 위해 완료를 기다린다.
  if (walletProvider.isVaultListLoading) {
    await walletProvider.loadVaultList();
  }

  final viewModel = VaultNameAndIconSetupViewModel(
    walletProvider,
    walletCreationProvider,
    authProvider,
    initialName: _liteVaultName(walletProvider, walletCreationProvider),
    initialIconIndex: CustomIcons.icons.indexOf(CustomIcons.coconut),
    initialColorIndex: CoconutColors.colorPalette.indexOf(CoconutColors.gray600),
    isImported: isImported,
  );

  try {
    final result = await viewModel.saveNewVault();
    if (!context.mounted) return;

    if (result.status == VaultNameAndIconSetupSaveStatus.duplicateName) {
      CoconutToast.showToast(text: t.toast.name_already_used2, context: context, isVisibleIcon: true);
      return;
    }

    if (result.status == VaultNameAndIconSetupSaveStatus.navigateMultisigSetupInfo) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.multisigSetupInfo,
        (Route<dynamic> route) => route.settings.name == '/',
        arguments: {'id': result.multisigVaultId},
      );
      return;
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/',
      (Route<dynamic> route) => false,
      arguments: VaultHomeNavArgs(addedWalletId: result.addedWalletId!),
    );
  } finally {
    viewModel.dispose();
  }
}

String _liteVaultName(WalletProvider walletProvider, WalletCreationProvider creationProvider) {
  switch (creationProvider.walletType) {
    case WalletType.singleSignature:
      return _singleSigMasterFingerprint(creationProvider);
    case WalletType.multiSignature:
      return _multisigDescriptorChecksumName(walletProvider, creationProvider);
    case WalletType.taproot:
      throw UnimplementedError('Taproot vault creation is not supported in lite build');
  }
}

/// 싱글시그 지갑 이름: master fingerprint (대문자)
String _singleSigMasterFingerprint(WalletCreationProvider creationProvider) {
  Seed? seed;
  KeyStore? keyStore;
  try {
    seed = Seed.fromMnemonic(
      Uint8List.fromList(creationProvider.secret),
      passphrase: creationProvider.passphrase != null ? Uint8List.fromList(creationProvider.passphrase!) : null,
    );
    keyStore = KeyStore.fromSeed(seed, AddressType.p2wpkh);
    final mfp = keyStore.masterFingerprint.toUpperCase();
    return '${mfp.substring(0, 4)} ${mfp.substring(4)}';
  } finally {
    keyStore?.wipeSeed();
    seed?.wipe();
  }
}

/// 멀티시그 지갑 이름: 'Multisig [descriptor checksum]' ex) Multisig c8eu4g73
String _multisigDescriptorChecksumName(WalletProvider walletProvider, WalletCreationProvider creationProvider) {
  // 저장 시점과 동일한 descriptor가 되도록 내부 지갑과 매칭되는 MFP 교정을 미리 적용한다.
  final sanitizedSigners = walletProvider.sanitizeSignerMfp(creationProvider.signers!);
  final multisigVault = MultisignatureVault.fromKeyStoreList(
    sanitizedSigners.map((signer) => signer.keyStore).toList(),
    creationProvider.requiredSignatureCount!,
    addressType: AddressType.p2wsh,
  );

  final checksum = multisigVault.descriptor.split('#').last;
  return 'Multisig $checksum';
}
