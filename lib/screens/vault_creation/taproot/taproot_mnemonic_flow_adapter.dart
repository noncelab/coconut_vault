import 'dart:typed_data';

import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/base_entropy_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_auto_gen_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_coinflip_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_confirmation_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_dice_roll_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_import_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/mnemonic_verify_screen.dart';
import 'package:coconut_vault/screens/vault_creation/single_sig/seed_qr_import_screen.dart';
import 'package:flutter/material.dart';

enum TaprootMnemonicCreationMethod { coinFlip, diceRoll, autoGenerate }

typedef TaprootImportedMnemonicCallback = void Function(Uint8List secret, Uint8List? passphrase);

class TaprootMnemonicFlowAdapter {
  TaprootMnemonicFlowAdapter._();

  static bool isMnemonicImportScreen(Widget widget) => widget is MnemonicImportScreen;

  static bool isSeedQrImportScreen(Widget widget) => widget is SeedQrImportScreen;

  static Widget buildCreationScreen({
    required TaprootMnemonicCreationMethod method,
    required VoidCallback onMnemonicConfirmationRequested,
  }) {
    return switch (method) {
      TaprootMnemonicCreationMethod.coinFlip => MnemonicCoinflipScreen(
        entropyType: EntropyType.manual,
        isEmbedded: true,
        isTaproot: true,
        onMnemonicConfirmationRequested: onMnemonicConfirmationRequested,
      ),
      TaprootMnemonicCreationMethod.diceRoll => MnemonicDiceRollScreen(
        entropyType: EntropyType.manual,
        isEmbedded: true,
        isTaproot: true,
        onMnemonicConfirmationRequested: onMnemonicConfirmationRequested,
      ),
      TaprootMnemonicCreationMethod.autoGenerate => MnemonicAutoGenScreen(
        entropyType: EntropyType.auto,
        isEmbedded: true,
        isTaproot: true,
        onMnemonicConfirmationRequested: onMnemonicConfirmationRequested,
      ),
    };
  }

  static int addCreationConfirmationStep({
    required int Function(Widget widget) addEmbeddedStep,
    required TaprootMnemonicCreationMethod method,
    required VoidCallback onMnemonicReady,
    required VoidCallback onAutoGenerateReady,
  }) {
    final calledFrom = _calledFrom(method);
    if (calledFrom == AppRoutes.mnemonicVerify) {
      onAutoGenerateReady();
      return -1;
    }

    return addEmbeddedStep(
      MnemonicConfirmationScreen(
        calledFrom: calledFrom,
        isEmbedded: true,
        isTaproot: true,
        onMnemonicReady: onMnemonicReady,
      ),
    );
  }

  static int addImportedConfirmationStep({
    required int Function(Widget widget) addEmbeddedStep,
    required VoidCallback onMnemonicReady,
  }) {
    return addEmbeddedStep(
      MnemonicConfirmationScreen(
        calledFrom: AppRoutes.mnemonicImport,
        isEmbedded: true,
        isTaproot: true,
        onMnemonicReady: onMnemonicReady,
      ),
    );
  }

  static int addVerifyStep({
    required int Function(Widget widget) addEmbeddedStep,
    required VoidCallback onVerificationSuccess,
  }) {
    return addEmbeddedStep(
      MnemonicVerifyScreen(isEmbedded: true, isTaproot: true, onVerificationSuccess: onVerificationSuccess),
    );
  }

  static int addVerifiedConfirmationStep({
    required int Function(Widget widget) addEmbeddedStep,
    required VoidCallback onMnemonicReady,
  }) {
    return addEmbeddedStep(
      MnemonicConfirmationScreen(
        calledFrom: AppRoutes.mnemonicVerify,
        isEmbedded: true,
        isTaproot: true,
        onMnemonicReady: onMnemonicReady,
      ),
    );
  }

  static Widget buildMnemonicImportScreen({
    Key? key,
    VoidCallback? onCompleted,
    TaprootImportedMnemonicCallback? onMnemonicConfirmationRequested,
  }) {
    return MnemonicImportScreen(
      key: key,
      isEmbedded: true,
      isTaprootCreationChild: true,
      requirePassphraseConfirmation: true,
      onCompleted: onCompleted,
      onMnemonicConfirmationRequested: onMnemonicConfirmationRequested,
    );
  }

  static Widget buildSeedQrImportScreen({
    Key? key,
    required TaprootImportedMnemonicCallback onMnemonicConfirmationRequested,
  }) {
    return SeedQrImportScreen(
      key: key,
      isEmbedded: true,
      isTaproot: true,
      requirePassphraseConfirmation: true,
      onMnemonicConfirmationRequested: onMnemonicConfirmationRequested,
    );
  }

  static String _calledFrom(TaprootMnemonicCreationMethod method) {
    return switch (method) {
      TaprootMnemonicCreationMethod.coinFlip => AppRoutes.mnemonicCoinflip,
      TaprootMnemonicCreationMethod.diceRoll => AppRoutes.mnemonicDiceRoll,
      TaprootMnemonicCreationMethod.autoGenerate => AppRoutes.mnemonicVerify,
    };
  }
}
