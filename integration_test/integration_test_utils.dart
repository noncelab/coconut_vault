import 'dart:convert';
import 'dart:typed_data';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/constants/secure_storage_keys.dart';
import 'package:coconut_vault/constants/shared_preferences_keys.dart';
import 'package:coconut_vault/repository/wallet_repository.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/model/multisig/multisig_wallet.dart';
import 'package:coconut_vault/model/single_sig/single_sig_wallet_create_dto.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/repository/secure_storage_repository.dart';
import 'package:coconut_vault/repository/shared_preferences_repository.dart';
import 'package:coconut_vault/utils/hash_util.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Waits for a widget to appear on the screen with a timeout (100초).
/// Returns true if the widget was found, false if it timed out.
Future<bool> waitForWidget(
  WidgetTester tester,
  Finder finder, {
  String? timeoutMessage,
  int timeoutSeconds = 60,
}) async {
  bool found = false;
  for (int i = 0; i < timeoutSeconds && !found; i++) {
    await tester.pump(const Duration(seconds: 1));
    found = finder.evaluate().isNotEmpty;
  }
  if (timeoutMessage != null) {
    expect(found, true, reason: timeoutMessage);
  }
  return found;
}

Future<void> waitForWidgetAndTap(
  WidgetTester tester,
  Finder element,
  String elementName, {
  int timeoutSeconds = 60,
}) async {
  await waitForWidget(
    tester,
    element,
    timeoutMessage: "$elementName not found after $timeoutSeconds seconds",
    timeoutSeconds: timeoutSeconds,
  );
  await tester.tap(element);
  await tester.pumpAndSettle();
}

Future<void> setBackupFile(bool isEnabled) async {
  if (!isEnabled) return;
  // 백업데이터가 있는 경우에는 핀코드도 설정되어 있어야 한다.
  await saveBackupData();
  await savePinCode("0000");
}

Future<void> setWalletData(bool isEnabled) async {
  if (!isEnabled) return;
  // 월렛이 있는 경우에는 핀코드도 설정되어 있어야 한다.
  await addWallets();
  await savePinCode("0000");
}

Future<void> setIsUpdated(bool isUpdated) async {
  // 업데이트가 되었다면 이전 버전 정보가 저장되어야 한다.
  if (isUpdated) {
    await saveAppVersion("1.0.0");
  } else {
    await saveCurrentAppVersion();
  }
}

Future<void> skipTutorial(bool skip) async {
  final prefs = await SharedPreferences.getInstance();
  prefs.setBool(SharedPrefsKeys.hasShownStartGuide, skip);
}

Future<void> savePinCode(String pinCode) async {
  final SecureStorageRepository storageService = SecureStorageRepository();
  final SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
  await storageService.write(key: SecureStorageKeys.kVaultPin, value: hashString(pinCode));
  await sharedPreferences.setBool(SharedPrefsKeys.isPinEnabled, true);
}

Future<void> saveAppVersion(String version) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(SharedPrefsKeys.kAppVersion, version);
}

Future<void> saveCurrentAppVersion() async {
  final PackageInfo packageInfo = await PackageInfo.fromPlatform();
  await saveAppVersion(packageInfo.version.split('-').first);
}

Future<void> saveBackupData() async {
  var backupData = [
    {
      "id": 1,
      "name": "Test Wallet1",
      "colorIndex": 0,
      "iconIndex": 0,
      "vaultType": "singleSignature",
      "secret": "thank split shrimp error own spirit slow glow act evidence globe slight",
      "passphrase": "",
      "linkedMultisigInfo": {"2": 0},
      "signerBsms":
          "BSMS 1.0\n00\n[B928B226/48'/1'/0'/2']Vpub5mHQNgTYgzTpc85RnEQkA4yA5zC2vX4uDS3w7H8B6RKkNnD93Yb3QinD8NBa9oQrcg2NwTGjh3hKyToUn7PSPZcVyiSbbEJCkFcN8ub6aRM\nTest Wallet1",
    },
    {
      "id": 2,
      "name": "Test Wallet2",
      "colorIndex": 0,
      "iconIndex": 0,
      "vaultType": "multiSignature",
      "signers": [
        {
          "id": 0,
          "innerVaultId": 1,
          "name": "Inside Wallet",
          "iconIndex": 0,
          "colorIndex": 0,
          "signerBsms":
              "BSMS 1.0\n00\n[E0C42931/48'/1'/0'/2']Vpub5nNFgHQhQCGEaWtoLrnzWjDvngmwS9A8qT8g1tjkWrbvYwLGrcYupy8jFXmJqyFd9u6aeRTvuLKMrGZ8jdfbarYvLS8rK4Z8Qp5uvKjLTNt\nttt\n",
          "memo": null,
          "keyStore":
              "{\"fingerprint\":\"E0C42931\",\"hdWallet\":\"{\\\"publicKey\\\":\\\"02b4738642a07009443ff12a85b2f4a7806291de4c2a481fb2c0432a8468badf6c\\\",\\\"chainCode\\\":\\\"c7323611efb46993ed234e3028fdfd5c9d2c93b74cda8572c2599aa2a70d13a3\\\"}\",\"extendedPublicKey\":\"Vpub5nNFgHQhQCGEaWtoLrnzWjDvngmwS9A8qT8g1tjkWrbvYwLGrcYupy8jFXmJqyFd9u6aeRTvuLKMrGZ8jdfbarYvLS8rK4Z8Qp5uvKjLTNt\"}",
        },
        {
          "id": 0,
          "innerVaultId": null,
          "name": "여여려",
          "iconIndex": null,
          "colorIndex": null,
          "signerBsms":
              "BSMS 1.0\n00\n[858FA201/48'/1'/0'/2']Vpub5ncWX3M18jrGdytgNZfayhkzj37RpXHH5k11QsEC4BBJZga64W92KFDVg8CRoEyBAm4eZqXUTKEgx991ri14aWkBhAsgjak5pMHa8wjYirr\n여여려\n",
          "memo": "memo test",
          "keyStore":
              "{\"fingerprint\":\"858FA201\",\"hdWallet\":\"{\\\"publicKey\\\":\\\"03ae52f4371a5b32c87de3eb446cb790bb382f7f24f03d3780707c536f66e8ac55\\\",\\\"chainCode\\\":\\\"cd7f31d5c34c19359454ae5074a96ff556f9a2dcfca5adef1130a9cb68d04d8e\\\"}\",\"extendedPublicKey\":\"Vpub5ncWX3M18jrGdytgNZfayhkzj37RpXHH5k11QsEC4BBJZga64W92KFDVg8CRoEyBAm4eZqXUTKEgx991ri14aWkBhAsgjak5pMHa8wjYirr\"}",
        },
      ],
      "coordinatorBsms":
          "BSMS 1.0\nwsh(sortedmulti(2,[E0C42931/48'/1'/0'/2']Vpub5nNFgHQhQCGEaWtoLrnzWjDvngmwS9A8qT8g1tjkWrbvYwLGrcYupy8jFXmJqyFd9u6aeRTvuLKMrGZ8jdfbarYvLS8rK4Z8Qp5uvKjLTNt/<0;1>/*,[858FA201/48'/1'/0'/2']Vpub5ncWX3M18jrGdytgNZfayhkzj37RpXHH5k11QsEC4BBJZga64W92KFDVg8CRoEyBAm4eZqXUTKEgx991ri14aWkBhAsgjak5pMHa8wjYirr/<0;1>/*))#9zfcfeny\n/0/*,/1/*\nbcrt1quajap24pe8z07dshjtln7lmrz4cree8y444ku8wgfugqnnn68qzqggqd52",
      "requiredSignatureCount": 2,
    },
  ];

  // await UpdatePreparation.encryptAndSave(data: jsonEncode(backupData));
}

Future<int> addSingleSigWallets({WalletProvider? walletProvider}) async {
  final singleSig2 = SingleSigWalletCreateDto(
    2,
    "New Wallet3",
    0,
    0,
    utf8.encode("primary exotic display destroy wrap zoo among scan length despair lend yard"),
    Uint8List(0),
  );

  final singleSig3 = SingleSigWalletCreateDto(
    3,
    "Test Wallet4",
    0,
    0,
    utf8.encode("dwarf aim crash town chalk device bulb simple space draft ball canoe"),
    Uint8List(0),
  );

  if (walletProvider != null) {
    await walletProvider.addSingleSigVault(singleSig2);
    await walletProvider.addSingleSigVault(singleSig3);
  } else {
    WalletRepository walletRepository = WalletRepository();
    await walletRepository.addSinglesigWallet(singleSig2);
    await walletRepository.addSinglesigWallet(singleSig3);
    await SharedPrefsRepository().setInt(SharedPrefsKeys.vaultListLength, walletRepository.vaultList.length);
  }
  return 2;
}

Future<int> addWallets({WalletProvider? walletProvider}) async {
  // single sig wallet
  final singleSig = SingleSigWalletCreateDto(
    1,
    "Test Wallet1",
    0,
    0,
    utf8.encode("thank split shrimp error own spirit slow glow act evidence globe slight"),
    Uint8List(0),
  );

  // multisig wallet
  String internalWalletBsms = '''
BSMS 1.0
00
[E0C42931/48'/1'/0'/2']Vpub5nNFgHQhQCGEaWtoLrnzWjDvngmwS9A8qT8g1tjkWrbvYwLGrcYupy8jFXmJqyFd9u6aeRTvuLKMrGZ8jdfbarYvLS8rK4Z8Qp5uvKjLTNt
ttt
''';
  String outsideWalletBsms = '''
BSMS 1.0
00
[858FA201/48'/1'/0'/2']Vpub5ncWX3M18jrGdytgNZfayhkzj37RpXHH5k11QsEC4BBJZga64W92KFDVg8CRoEyBAm4eZqXUTKEgx991ri14aWkBhAsgjak5pMHa8wjYirr
여여려
''';
  List<KeyStore> keyStores = [KeyStore.fromSignerBsms(internalWalletBsms), KeyStore.fromSignerBsms(outsideWalletBsms)];
  List<MultisigSigner> signers = [
    MultisigSigner(
      id: 0,
      innerVaultId: 1,
      name: "Inside Wallet",
      iconIndex: 0,
      colorIndex: 0,
      signerBsms: internalWalletBsms,
      keyStore: keyStores[0],
    ),
    MultisigSigner(
      id: 0,
      signerBsms: outsideWalletBsms,
      name: outsideWalletBsms.split('\n')[3],
      memo: 'memo test',
      keyStore: keyStores[1],
    ),
  ];

  if (walletProvider != null) {
    await walletProvider.addSingleSigVault(singleSig);
    await walletProvider.addMultisigVault("Test Wallet2", 0, 0, signers, 2);
  } else {
    WalletRepository walletRepository = WalletRepository();
    await walletRepository.addSinglesigWallet(singleSig);
    await walletRepository.addMultisigWallet(MultisigWallet(null, "Test Wallet2", 0, 0, signers, 2));
    await SharedPrefsRepository().setInt(SharedPrefsKeys.vaultListLength, walletRepository.vaultList.length);
  }
  return 2;
}
