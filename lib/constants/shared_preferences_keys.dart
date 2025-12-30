class SharedPrefsKeys {
  static const String jailbreakDetectionIgnored = "JAILBREAK_DETECTION_IGNORED";
  static const String jailbreakDetectionIgnoredTime = "JAILBREAK_DETECTION_IGNORED_TIME";

  static const String hasShownStartGuide = "HAS_SHOWN_START_GUIDE"; // TODO: persistent
  static const String isPinEnabled = "IS_PIN_ENABLED";
  static const String isPinCharacter = "IS_PIN_CHARACTER";
  static const String vaultListLength = "VAULT_LIST_LENGTH";
  static const String kVaultListField = 'VAULT_LIST';
  static const String isBiometricEnabled = "IS_BIOMETRIC_ENABLED";
  static const String hasAlreadyRequestedBioPermission = "HAS_ALREADY_REQUESTED_BIO_PERMISSION"; // TODO: persistent

  static const String kUnlockAvailableAt = 'LOCKOUT_END_TIME';
  static const String kPinInputTurn = 'TOTAL_PIN_ATTEMPT';
  static const String kPinInputCurrentAttemptCount = 'PIN_ATTEMPT';

  static const String kPassphraseUseEnabled = 'PASSPHRASE_USE_ENABLED';
  static const String kIsBtcUnit = "IS_BTC_UNIT";
  static const String kLanguage = 'LANGUAGE';

  static const String kVaultOrder = "VAULT_ORDER"; // 볼트 순서
  static const String kFavoriteVaultIds = "FAVORITE_VAULT_IDS"; // 즐겨찾기된 볼트 목록

  static const String kVaultMode = "VAULT_MODE"; // 볼트 모드 (Secure Storage Mode, Signing-Only Mode) // TODO: persistent

  static const String kSigningModeEdgePanelPosX = "SIGNING_MODE_EDGE_PANEL_POS_X"; // 서명 모드 엣지 패널 위치 X
  static const String kSigningModeEdgePanelPosY = "SIGNING_MODE_EDGE_PANEL_POS_Y"; // 서명 모드 엣지 패널 위치 Y

  static const String kDataSchemeVersion = "DATA_SCHEME_VERSION";
}
