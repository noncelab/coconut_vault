class SharedPrefsKeys {
  static const String hasShownStartGuide = "HAS_SHOWN_START_GUIDE";
  static const String isPinEnabled = "IS_PIN_ENABLED";
  static const String isPinCharacter = "IS_PIN_CHARACTER";
  static const String vaultListLength = "VAULT_LIST_LENGTH";
  static const String kVaultListField = 'VAULT_LIST';
  static const String canCheckBiometrics = "CAN_CHECK_BIOMETRICS";
  static const String isBiometricEnabled = "IS_BIOMETRIC_ENABLED";
  static const String hasAlreadyRequestedBluetoothPermission =
      "HAS_ALREADY_REQUESTED_BLUETOOTH_PERMISSION";
  static const String hasAlreadyRequestedBioPermission = "HAS_ALREADY_REQUESTED_BIO_PERMISSION";
  static const String hasBiometricsPermission = "HAS_BIOMETRICS_PERMISSION";

  static const String kUnlockAvailableAt = 'LOCKOUT_END_TIME';
  static const String kPinInputTurn = 'TOTAL_PIN_ATTEMPT';
  static const String kPinInputCurrentAttemptCount = 'PIN_ATTEMPT';

  static const String kAppVersion = 'APP_VERSION';

  static const String kPassphraseUseEnabled = 'PASSPHRASE_USE_ENABLED';
  static const String kIsBtcUnit = "IS_BTC_UNIT";
  static const String kLanguage = 'LANGUAGE';

  static const String kVaultOrder = "VAULT_ORDER"; // 볼트 순서
  static const String kFavoriteVaultIds = "FAVORITE_VAULT_IDS"; // 즐겨찾기된 볼트 목록

  static const String kVaultMode = "VAULT_MODE"; // 볼트 모드 (Secure Storage Mode, Signing-Only Mode)
}
