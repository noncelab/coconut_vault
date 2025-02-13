class SharedPrefsKeys {
  static const String hasShownStartGuide = "HAS_SHOWN_START_GUIDE";
  static const String isPinEnabled = "IS_PIN_ENABLED";
  static const String vaultListLength = "VAULT_LIST_LENGTH";
  static const String canCheckBiometrics = "CAN_CHECK_BIOMETRICS";
  static const String isBiometricEnabled = "IS_BIOMETRIC_ENABLED";
  static const String hasAlreadyRequestedBluetoothPermission =
      "HAS_ALREADY_REQUESTED_BLUETOOTH_PERMISSION";
  static const String hasAlreadyRequestedBioPermission =
      "HAS_ALREADY_REQUESTED_BIO_PERMISSION";
  static const String hasBiometricsPermission = "HAS_BIOMETRICS_PERMISSION";

  // AppUnlockManager
  static String kLockoutEndDateTime = 'LOCKOUT_END_TIME';
  static String kTotalPinInputAttemptCount = 'TOTAL_PIN_ATTEMPT';
  static String kPinInputAttemptCount = 'PIN_ATTEMPT';
}
