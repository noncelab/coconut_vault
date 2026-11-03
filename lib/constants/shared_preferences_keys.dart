class SharedPrefsKeys {
  static const String jailbreakDetectionIgnored = "JAILBREAK_DETECTION_IGNORED";
  static const String jailbreakDetectionIgnoredTime = "JAILBREAK_DETECTION_IGNORED_TIME";

  static const String hasShownStartGuide = "HAS_SHOWN_START_GUIDE";

  static const String kDataSchemeVersion = "DATA_SCHEME_VERSION";
  // VaultDataSchema v3 migration: Taproot wallets with legacy descriptors
  static const String kWalletIdsWithUnacknowledgedOlderToAfterBackupUpdate =
      "WALLET_IDS_WITH_UNACKNOWLEDGED_OLDER_TO_AFTER_BACKUP_UPDATE";

  // 주요 설정
  static const String isPinCharacter = "IS_PIN_CHARACTER";

  static const String isBiometricEnabled = "IS_BIOMETRIC_ENABLED";
  static const String hasAlreadyRequestedBioPermission = "HAS_ALREADY_REQUESTED_BIO_PERMISSION";

  static const String kPassphraseUseEnabled = "PASSPHRASE_USE_ENABLED";
  static const String kChangeAccountEnabled = "CHANGE_ACCOUNT_ENABLED";
  static const String kIsBtcUnit = "IS_BTC_UNIT";
  static const String kLanguage = "LANGUAGE";
  static const String kNumberFormatPreset = "NUMBER_FORMAT_PRESET";

  static const String kVaultMode = "VAULT_MODE"; // 볼트 모드 (Secure Storage Mode, Signing-Only Mode)
  static const String kVaultModeTransitionMarker = "VAULT_MODE_TRANSITION_MARKER"; // 모드 전환 중 마커

  // 부가 설정
  static const String kSigningModeEdgePanelPosX = "SIGNING_MODE_EDGE_PANEL_POS_X"; // 서명 모드 엣지 패널 위치 X
  static const String kSigningModeEdgePanelPosY = "SIGNING_MODE_EDGE_PANEL_POS_Y"; // 서명 모드 엣지 패널 위치 Y

  // ---------- 초기화 대상 ----------
  // PIN
  static const String isPinEnabled = "IS_PIN_ENABLED";

  // 볼트 목록
  static const String kVaultListField = "VAULT_LIST";
  static const String kNextIdField = "nextId";
  static const String kVaultOrder = "VAULT_ORDER"; // 볼트 순서
  static const String kFavoriteVaultIds = "FAVORITE_VAULT_IDS"; // 즐겨찾기된 볼트 목록

  // PIN 시도 기록
  static const String kUnlockAvailableAt = "LOCKOUT_END_TIME";
  static const String kPinInputTurn = "TOTAL_PIN_ATTEMPT";
  static const String kPinInputCurrentAttemptCount = "PIN_ATTEMPT";

  // ---------- Deprecated ----------
  /// 볼트 개수를 별도로 저장하던 레거시 키. `kVaultListField` 존재 여부로 대체되었으며
  /// 앱 시작 시 잔여 값 정리용으로만 유지합니다.
  static const String kDeprecatedVaultListLength = "VAULT_LIST_LENGTH";
}
