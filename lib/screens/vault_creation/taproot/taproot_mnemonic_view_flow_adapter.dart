import 'dart:convert';
import 'dart:typed_data';

import 'package:coconut_vault/enums/pin_check_context_enum.dart';
import 'package:coconut_vault/screens/wallet_info/single_sig_menu/mnemonic_view_screen.dart';
import 'package:flutter/material.dart';

typedef TaprootDeviceAuthDialogLauncher =
    Future<void> Function({
      required BuildContext context,
      required void Function(BuildContext dialogContext) onConfirm,
    });

typedef TaprootBiometricOrPinAuthenticator =
    Future<void> Function({
      required BuildContext context,
      required PinCheckContextEnum pinCheckContext,
      required VoidCallback onSuccess,
    });

typedef TaprootMnemonicViewReadyCallback = void Function(Uint8List mnemonic, Uint8List? passphrase);

class TaprootMnemonicViewFlowAdapter {
  TaprootMnemonicViewFlowAdapter._();

  static Widget buildMnemonicViewStep({
    required GlobalKey<MnemonicViewScreenState> mnemonicViewKey,
    required int walletId,
    required bool buildPassphraseToggle,
    required bool emptyPassphraseAsNull,
    bool showPassphraseWarningSubWidget = false,
    required VoidCallback onAuthCanceled,
    required TaprootMnemonicViewReadyCallback onMnemonicReady,
  }) {
    return Stack(
      children: [
        MnemonicViewScreen(
          key: mnemonicViewKey,
          walletId: walletId,
          autoLoadMnemonic: false,
          isEmbedded: true,
          buildPassphraseToggle: buildPassphraseToggle,
          requirePassphraseConfirmation: true,
          showPassphraseWarningSubWidget: showPassphraseWarningSubWidget,
          onAuthCanceled: onAuthCanceled,
          onNextButtonPressed: () {
            final mnemonicViewState = mnemonicViewKey.currentState;
            if (mnemonicViewState == null) {
              return;
            }

            onMnemonicReady(
              mnemonicViewState.mnemonic,
              _passphraseBytes(mnemonicViewState.passphrase, emptyPassphraseAsNull: emptyPassphraseAsNull),
            );
          },
        ),
      ],
    );
  }

  static void showDeviceAuthDialog({
    required BuildContext context,
    required GlobalKey<MnemonicViewScreenState> mnemonicViewKey,
    required TaprootDeviceAuthDialogLauncher showDeviceAuthDialog,
    required TaprootBiometricOrPinAuthenticator authenticateWithBiometricOrPin,
  }) {
    showDeviceAuthDialog(
      context: context,
      onConfirm: (dialogContext) {
        authenticateWithBiometricOrPin(
          context: context,
          pinCheckContext: PinCheckContextEnum.sensitiveAction,
          onSuccess: () {
            if (dialogContext.mounted) {
              Navigator.pop(dialogContext);
            }
            mnemonicViewKey.currentState?.setMnemonic();
          },
        );
      },
    );
  }

  static Uint8List? _passphraseBytes(String passphrase, {required bool emptyPassphraseAsNull}) {
    if (passphrase.isEmpty && emptyPassphraseAsNull) {
      return null;
    }

    return Uint8List.fromList(utf8.encode(passphrase));
  }
}
