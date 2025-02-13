///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import

part of 'strings.g.dart';

// Path: <root>
typedef TranslationsKr = Translations; // ignore: unused_element

class Translations implements BaseTranslations<AppLocale, Translations> {
  /// Returns the current translations of the given [context].
  ///
  /// Usage:
  /// final t = Translations.of(context);
  static Translations of(BuildContext context) =>
      InheritedLocaleData.of<AppLocale, Translations>(context).translations;

  /// You can call this constructor and build your own translation instance of this locale.
  /// Constructing via the enum [AppLocale.build] is preferred.
  Translations(
      {Map<String, Node>? overrides,
      PluralResolver? cardinalResolver,
      PluralResolver? ordinalResolver})
      : assert(overrides == null,
            'Set "translation_overrides: true" in order to enable this feature.'),
        $meta = TranslationMetadata(
          locale: AppLocale.kr,
          overrides: overrides ?? {},
          cardinalResolver: cardinalResolver,
          ordinalResolver: ordinalResolver,
        ) {
    $meta.setFlatMapFunction(_flatMapFunction);
  }

  /// Metadata for the translations of <kr>.
  @override
  final TranslationMetadata<AppLocale, Translations> $meta;

  /// Access flat map
  dynamic operator [](String key) => $meta.getTranslation(key);

  late final Translations _root = this; // ignore: unused_field

  // Translations
  String get coconut_vault => 'Coconut Vault';
  String get btc => 'BTC';
  String get hour => '시간';
  String get minute => '분';
  String get second => '초';
  String get settings => '설정';
  String get confirm => '확인';
  String get complete => '완료';
  String get cancel => '취소';
  String get next => '다음';
  String get save => '저장';
  String get select => '선택';
  String get warning => '주의';
  String get security => '보안';
  String get yes => '네';
  String get no => '아니오';
  String get front => '앞';
  String get back => '뒤';
  String get memo => '메모';
  String get close => '닫기';
  String get delete => '지우기';
  String get remove => '삭제하기';
  String get stop => '그만하기';
  String get start => '시작하기';
  String get quit => '종료하기';
  String get import => '가져오기';
  String get export => '내보내기';
  String get passphrase => '패스프레이즈';
  String get mnemonic => '니모닉 문구';
  String get testnet => '테스트넷';
  String get license => '라이선스';
  String get name => '이름';
  String get skip => '건너뛰기';
  String get restore => '복원하기';
  String get change => '잔돈';
  String get receiving => '입금';
  String get info => '정보';
  String get email_subject => '[코코넛 볼트] 이용 관련 문의';
  String get signature => '서명';
  String get sign_completion => '서명 완료';
  String get sign => '서명하기';
  String get signed_tx => '서명 트랜잭션';
  String get sign_completed => '서명을 완료했습니다';
  String get stop_sign => '서명 종료하기';
  String get select_completed => '선택 완료';
  String get checklist => '확인 사항';
  String get wallet_id => '지갑 ID';
  String get mnemonic_wordlist => '니모닉 문구 단어집';
  String get singlesig_wallet => '일반 지갑';
  String get multisig_wallet => '다중 서명 지갑';
  String get extended_public_key => '확장 공개키';
  String get app_info => '앱 정보';
  String get inquiry_details => '문의 내용';
  String get license_details => '라이선스 안내';
  String get external_wallet => '외부 지갑';
  String get recipient => '보낼 주소';
  String get send_amount => '보낼 수량';
  String get estimated_fee => '예상 수수료';
  String get total_amount => '총 소요 수량';
  String get key_list => '키 목록';
  String get view_mnemonic => '니모닉 문구 보기';
  String get view_passphrase => '패스프레이즈 보기';
  String get view_app_info => '앱 정보 보기';
  String get view_all => '전체 보기';
  String get view_details_info => '상세 정보 보기';
  String get view_address => '주소 보기';
  String get view_tutorial => '튜토리얼 보기';
  String get delete_all => '모두 지우기';
  String get delete_one => '하나 지우기';
  String get re_select => '다시 고르기';
  String name_info({required Object name}) => '${name} 정보';
  String name_wallet({required Object name}) => '${name} 지갑';
  String bitcoin_text({required Object bitcoin}) => '${bitcoin} BTC';
  String sign_required({required Object count}) => '${count}개의 서명이 필요합니다';
  String name_text_count({required Object count}) => '(${count} / 20)';
  String wallet_subtitle({required Object name, required Object index}) =>
      '${name}의 ${index}번 키';
  String get forgot_password => '비밀번호가 기억나지 않나요?';
  String get scan_qr_url_link =>
      '네트워크가 활성화된 기기에서 QR 코드를 스캔하시거나 위의 URL 주소로 접속해 주세요.';
  String get scan_qr_email_link =>
      '네트워크가 활성화된 기기에서 QR 코드를 스캔하시거나 위의 주소로 메일을 전송해 주세요';
  String get developer_option => '개발자 옵션';
  late final TranslationsVaultListTabKr vault_list_tab =
      TranslationsVaultListTabKr.internal(_root);
  late final TranslationsAppUnavailableNotificationScreenKr
      app_unavailable_notification_screen =
      TranslationsAppUnavailableNotificationScreenKr.internal(_root);
  late final TranslationsIosBluetoothAuthNotificationScreenKr
      ios_bluetooth_auth_notification_screen =
      TranslationsIosBluetoothAuthNotificationScreenKr.internal(_root);
  late final TranslationsPinCheckScreenKr pin_check_screen =
      TranslationsPinCheckScreenKr.internal(_root);
  late final TranslationsPinSettingScreenKr pin_setting_screen =
      TranslationsPinSettingScreenKr.internal(_root);
  late final TranslationsSecuritySelfCheckScreenKr security_self_check_screen =
      TranslationsSecuritySelfCheckScreenKr.internal(_root);
  late final TranslationsTutorialScreenKr tutorial_screen =
      TranslationsTutorialScreenKr.internal(_root);
  late final TranslationsMultisigKr multisig =
      TranslationsMultisigKr.internal(_root);
  late final TranslationsAccountSelectionBottomSheetScreenKr
      account_selection_bottom_sheet_screen =
      TranslationsAccountSelectionBottomSheetScreenKr.internal(_root);
  late final TranslationsPsbtConfirmationScreenKr psbt_confirmation_screen =
      TranslationsPsbtConfirmationScreenKr.internal(_root);
  late final TranslationsPsbtScannerScreenKr psbt_scanner_screen =
      TranslationsPsbtScannerScreenKr.internal(_root);
  late final TranslationsSignedTransactionQrScreenKr
      signed_transaction_qr_screen =
      TranslationsSignedTransactionQrScreenKr.internal(_root);
  late final TranslationsSinglesigSignScreenKr singlesig_sign_screen =
      TranslationsSinglesigSignScreenKr.internal(_root);
  late final TranslationsAppInfoScreenKr app_info_screen =
      TranslationsAppInfoScreenKr.internal(_root);
  late final TranslationsReadFileViewScreenKr read_file_view_screen =
      TranslationsReadFileViewScreenKr.internal(_root);
  late final TranslationsLicenseScreenKr license_screen =
      TranslationsLicenseScreenKr.internal(_root);
  late final TranslationsMnemonicWordListScreenKr mnemonic_word_list_screen =
      TranslationsMnemonicWordListScreenKr.internal(_root);
  late final TranslationsSettingsScreenKr settings_screen =
      TranslationsSettingsScreenKr.internal(_root);
  late final TranslationsGuideScreenKr guide_screen =
      TranslationsGuideScreenKr.internal(_root);
  late final TranslationsWelcomeScreenKr welcome_screen =
      TranslationsWelcomeScreenKr.internal(_root);
  late final TranslationsMnemonicCoinFlipScreenKr mnemonic_coin_flip_screen =
      TranslationsMnemonicCoinFlipScreenKr.internal(_root);
  late final TranslationsMnemonicConfirmScreenKr mnemonic_confirm_screen =
      TranslationsMnemonicConfirmScreenKr.internal(_root);
  late final TranslationsMnemonicGenerateScreenKr mnemonic_generate_screen =
      TranslationsMnemonicGenerateScreenKr.internal(_root);
  late final TranslationsMnemonicImportScreenKr mnemonic_import_screen =
      TranslationsMnemonicImportScreenKr.internal(_root);
  late final TranslationsSelectVaultTypeScreenKr select_vault_type_screen =
      TranslationsSelectVaultTypeScreenKr.internal(_root);
  late final TranslationsVaultCreationOptionsScreenKr
      vault_creation_options_screen =
      TranslationsVaultCreationOptionsScreenKr.internal(_root);
  late final TranslationsVaultNameIconSetupScreenKr
      vault_name_icon_setup_screen =
      TranslationsVaultNameIconSetupScreenKr.internal(_root);
  late final TranslationsAssignSignersScreenKr assign_signers_screen =
      TranslationsAssignSignersScreenKr.internal(_root);
  late final TranslationsConfirmImportingScreenKr confirm_importing_screen =
      TranslationsConfirmImportingScreenKr.internal(_root);
  late final TranslationsSelectMultisigQuorumScreenKr
      select_multisig_quorum_screen =
      TranslationsSelectMultisigQuorumScreenKr.internal(_root);
  late final TranslationsSignerQrBottomSheetKr signer_qr_bottom_sheet =
      TranslationsSignerQrBottomSheetKr.internal(_root);
  late final TranslationsSignerScannerBottomSheetKr
      signer_scanner_bottom_sheet =
      TranslationsSignerScannerBottomSheetKr.internal(_root);
  late final TranslationsSignerScannerScreenKr signer_scanner_screen =
      TranslationsSignerScannerScreenKr.internal(_root);
  late final TranslationsAddressListScreenKr address_list_screen =
      TranslationsAddressListScreenKr.internal(_root);
  late final TranslationsExportDetailScreenKr export_detail_screen =
      TranslationsExportDetailScreenKr.internal(_root);
  late final TranslationsMnemonicViewScreenKr mnemonic_view_screen =
      TranslationsMnemonicViewScreenKr.internal(_root);
  late final TranslationsMultiSigBsmsScreenKr multi_sig_bsms_screen =
      TranslationsMultiSigBsmsScreenKr.internal(_root);
  late final TranslationsMultiSigMemoBottomSheetKr multi_sig_memo_bottom_sheet =
      TranslationsMultiSigMemoBottomSheetKr.internal(_root);
  late final TranslationsMultiSigSettingScreenKr multi_sig_setting_screen =
      TranslationsMultiSigSettingScreenKr.internal(_root);
  late final TranslationsSelectExportTypeScreenKr select_export_type_screen =
      TranslationsSelectExportTypeScreenKr.internal(_root);
  late final TranslationsSignerBsmsScreenKr signer_bsms_screen =
      TranslationsSignerBsmsScreenKr.internal(_root);
  late final TranslationsSyncToWalletScreenKr sync_to_wallet_screen =
      TranslationsSyncToWalletScreenKr.internal(_root);
  late final TranslationsVaultMenuScreenKr vault_menu_screen =
      TranslationsVaultMenuScreenKr.internal(_root);
  late final TranslationsVaultSettingsKr vault_settings =
      TranslationsVaultSettingsKr.internal(_root);
  late final TranslationsBottomSheetKr bottom_sheet =
      TranslationsBottomSheetKr.internal(_root);
  late final TranslationsAlertKr alert = TranslationsAlertKr.internal(_root);
  late final TranslationsToastKr toast = TranslationsToastKr.internal(_root);
  late final TranslationsErrorsKr errors = TranslationsErrorsKr.internal(_root);
  late final TranslationsTooltipKr tooltip =
      TranslationsTooltipKr.internal(_root);
}

// Path: vault_list_tab
class TranslationsVaultListTabKr {
  TranslationsVaultListTabKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get add_wallet => '지갑을 추가해 주세요';
  String get top_right_icon => '오른쪽 위 + 버튼을 눌러도 추가할 수 있어요';
  String get btn_add => '바로 추가하기';
}

// Path: app_unavailable_notification_screen
class TranslationsAppUnavailableNotificationScreenKr {
  TranslationsAppUnavailableNotificationScreenKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get network_on => '휴대폰이 외부와 연결된 상태예요';
  String get text1_1 => '안전한 사용을 위해';
  String get text1_2 => '지금 바로 ';
  String get text1_3 => '앱을 종료';
  String get text1_4 => '해 주세요';
  String get text2 => '네트워크 및 블루투스';
  String get text3 => '개발자 옵션 OFF';
  String get check_status => '상태를 확인해 주세요';
}

// Path: ios_bluetooth_auth_notification_screen
class TranslationsIosBluetoothAuthNotificationScreenKr {
  TranslationsIosBluetoothAuthNotificationScreenKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get allow_permission => '코코넛 볼트에 블루투스 권한을 허용해 주세요';
  String get text1_1 => '안전한 사용을 위해';
  String get text1_2 => '지금 바로 앱을 종료하신 후';
  String get text1_3 => '설정 화면에서';
  String get text1_4 => '코코넛 볼트의 ';
  String get text1_5 => '블루투스 권한';
  String get text1_6 => '을';
  String get text1_7 => '허용해 주세요';
}

// Path: pin_check_screen
class TranslationsPinCheckScreenKr {
  TranslationsPinCheckScreenKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get enter_password => '비밀번호를 눌러주세요';
  String get warning => '⚠︎ 3회 모두 틀리면 볼트를 초기화해야 합니다';
}

// Path: pin_setting_screen
class TranslationsPinSettingScreenKr {
  TranslationsPinSettingScreenKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get set_password => '안전한 볼트 사용을 위해\n먼저 비밀번호를 설정할게요';
  String get enter_again => '다시 한번 확인할게요';
  String get new_password => '새로운 비밀번호를 눌러주세요';
  String get keep_in_mind => '반드시 기억할 수 있는 비밀번호로 설정해 주세요';
}

// Path: security_self_check_screen
class TranslationsSecuritySelfCheckScreenKr {
  TranslationsSecuritySelfCheckScreenKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get check1 => '나의 개인키는 내가 스스로 책임집니다.';
  String get check2 => '니모닉 문구 화면을 캡처하거나 촬영하지 않습니다.';
  String get check3 => '니모닉 문구를 네트워크와 연결된 환경에 저장하지 않습니다.';
  String get check4 => '니모닉 문구의 순서와 단어의 철자를 확인합니다.';
  String get check5 => '패스프레이즈에 혹시 의도하지 않은 문자가 포함되지는 않았는지 한번 더 확인합니다.';
  String get check6 => '니모닉 문구와 패스프레이즈는 아무도 없는 안전한 곳에서 확인합니다.';
  String get check7 => '니모닉 문구와 패스프레이즈를 함께 보관하지 않습니다.';
  String get check8 => '소액으로 보내기 테스트를 한 후 지갑 사용을 시작합니다.';
  String get check9 => '위 사항을 주기적으로 점검하고, 안전하게 니모닉 문구를 보관하겠습니다.';
  String get guidance => '아래 자가 점검 항목을 숙지하고 니모닉 문구를 반드시 안전하게 보관합니다.';
}

// Path: tutorial_screen
class TranslationsTutorialScreenKr {
  TranslationsTutorialScreenKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get title1 => '튜토리얼을 참고하시면\n더욱 쉽게 사용할 수 있어요';
  String get title2 => '도움이 필요하신가요?';
  String get subtitle => '튜토리얼과 함께 사용해 보세요';
  String get content => '인터넷 주소창에 입력해 주세요\ncoconut.onl';
}

// Path: multisig
class TranslationsMultisigKr {
  TranslationsMultisigKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String nth_key({required Object index}) => '${index}번 키 -';
}

// Path: account_selection_bottom_sheet_screen
class TranslationsAccountSelectionBottomSheetScreenKr {
  TranslationsAccountSelectionBottomSheetScreenKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get text => '서명할 계정을 선택해주세요.';
}

// Path: psbt_confirmation_screen
class TranslationsPsbtConfirmationScreenKr {
  TranslationsPsbtConfirmationScreenKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get title => '스캔 정보 확인';
  String get guide => '월렛에서 스캔한 정보가 맞는지 다시 한번 확인해 주세요.';
  String get self_sending => '내 지갑으로 보내는 트랜잭션입니다.';
  String get warning =>
      '⚠️ 해당 지갑으로 만든 psbt가 아닐 수 있습니다. 또는 잔액이 없는 트랜잭션일 수 있습니다.';
}

// Path: psbt_scanner_screen
class TranslationsPsbtScannerScreenKr {
  TranslationsPsbtScannerScreenKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get guide_multisig => '월렛에서 만든 보내기 정보 또는 외부 볼트에서 다중 서명 중인 정보를 스캔해주세요.';
  String get guide_singlesig => '월렛에서 만든 보내기 정보를 스캔해 주세요. 반드시 지갑 이름이 같아야 해요.';
}

// Path: signed_transaction_qr_screen
class TranslationsSignedTransactionQrScreenKr {
  TranslationsSignedTransactionQrScreenKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get guide_multisig =>
      '다중 서명을 완료했어요. 보내기 정보를 생성한 월렛으로 아래 QR 코드를 스캔해 주세요.';
  String guide_singlesig({required Object name}) =>
      '월렛의 \'${name} 지갑\'에서 만든 보내기 정보에 서명을 완료했어요. 월렛으로 아래 QR 코드를 스캔해 주세요.';
}

// Path: singlesig_sign_screen
class TranslationsSinglesigSignScreenKr {
  TranslationsSinglesigSignScreenKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get text => '이미 서명된 트랜잭션입니다';
}

// Path: app_info_screen
class TranslationsAppInfoScreenKr {
  TranslationsAppInfoScreenKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get made_by_team_pow => '포우팀이 만듭니다.';
  String get category1_ask => '궁금한 점이 있으신가요?';
  String get go_to_pow => 'POW 커뮤니티 바로가기';
  String get ask_to_telegram => '텔레그램 채널로 문의하기';
  String get ask_to_x => 'X로 문의하기';
  String get ask_to_email => '이메일로 문의하기';
  String get category2_opensource => 'Coconut Vault는 오픈소스입니다';
  String get license => '라이선스 안내';
  String get mit_license => 'MIT License';
  String get coconut_lib => 'coconut_lib';
  String get coconut_wallet => 'coconut_wallet';
  String get coconut_vault => 'coconut_vuault';
  String get github => 'Github';
  String get contribution => '오픈소스 개발 참여하기';
  String version_and_date(
          {required Object version, required Object releasedAt}) =>
      'CoconutVault ver. ${version} (released at ${releasedAt})';
  String get inquiry => '문의 내용';
}

// Path: read_file_view_screen
class TranslationsReadFileViewScreenKr {
  TranslationsReadFileViewScreenKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get mit_license => 'MIT LICENSE';
  String get contribution => '오픈소스 개발 참여하기';
}

// Path: license_screen
class TranslationsLicenseScreenKr {
  TranslationsLicenseScreenKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get text1 =>
      '코코넛 볼트는 MIT 라이선스를 따르며 저작권은 대한민국의 논스랩 주식회사에 있습니다. MIT 라이선스 전문은 ';
  String get text2 =>
      '에서 확인해 주세요.\n\n이 애플리케이션에 포함된 타사 소프트웨어에 대한 저작권을 다음과 같이 명시합니다. 이에 대해 궁금한 사항이 있으시면 ';
  String get text3 => '으로 문의해 주시기 바랍니다.';
}

// Path: mnemonic_word_list_screen
class TranslationsMnemonicWordListScreenKr {
  TranslationsMnemonicWordListScreenKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get search_mnemonic_word => '영문으로 검색해 보세요';
  String result({required Object text}) => '\'${text}\' 검색 결과';
  String get such_no_result => '검색 결과가 없어요';
}

// Path: settings_screen
class TranslationsSettingsScreenKr {
  TranslationsSettingsScreenKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get use_biometric => '생체 인증 사용하기';
  String get change_password => '비밀번호 바꾸기';
  String get set_password => '비밀번호 설정하기';
}

// Path: guide_screen
class TranslationsGuideScreenKr {
  TranslationsGuideScreenKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get keep_network_off => '안전한 비트코인 보관을 위해,\n항상 연결 상태를 OFF로 유지해주세요';
  String get network_status => '네트워크 상태';
  String get bluetooth_status => '블루투스 상태';
  String get developer_option => '개발자 옵션';
  String get turn_off_network_and_bluetooth => '네트워크와 블루투스를 모두 꺼주세요';
  String get disable_developer_option => '개발자 옵션을 비활성화 해주세요';
  String get on => 'ON';
  String get off => 'OFF';
}

// Path: welcome_screen
class TranslationsWelcomeScreenKr {
  TranslationsWelcomeScreenKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get greeting => '원활한 코코넛 볼트 사용을 위해\n잠깐만 시간을 내주세요';
  String get guide1_1 => '볼트는';
  String guide1_2({required Object suffix}) => '네트워크, 블루투스 연결${suffix}이';
  String get guide1_3 => '꺼져있는 상태';
  String get guide1_4 => '에서만';
  String get guide1_5 => '사용하실 수 있어요';
  String get guide2_1 => '즉,';
  String get guide2_2 => '연결이 감지되면';
  String get guide2_3 => '앱을 사용하실 수 없게';
  String get guide2_4 => '설계되어 있어요';
  String get guide3_1 => '안전한 사용';
  String get guide3_2 => '을 위한';
  String get guide3_3 => '조치이오니';
  String get guide3_4 => '사용 시 유의해 주세요';
  String get understood => '모두 이해했어요 :)';
}

// Path: mnemonic_coin_flip_screen
class TranslationsMnemonicCoinFlipScreenKr {
  TranslationsMnemonicCoinFlipScreenKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get title => '니모닉 문구 만들기';
  String get words_passphrase => ' 단어, 패스프레이즈 ';
  String get use => '사용';
  String get do_not => '안함';
  String get enter_passphrase => '패스프레이즈를 입력해 주세요';
  String get coin_head => '앞';
  String get coin_tail => '뒤';
}

// Path: mnemonic_confirm_screen
class TranslationsMnemonicConfirmScreenKr {
  TranslationsMnemonicConfirmScreenKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get text1 => '입력하신 정보가 맞는지\n다시 한번 확인해 주세요.';
  String text2({required Object count}) => ' (총 ${count} 글자)';
  late final TranslationsMnemonicConfirmScreenWarningKr warning =
      TranslationsMnemonicConfirmScreenWarningKr.internal(_root);
  String get btn_confirm_completed => '확인 완료';
}

// Path: mnemonic_generate_screen
class TranslationsMnemonicGenerateScreenKr {
  TranslationsMnemonicGenerateScreenKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get title => '새 니모닉 문구';
  String get select_word_length => '단어 수를 고르세요';
  String get twelve => '12 단어';
  String get twenty_four => '24 단어';
  String get use_passphrase => '패스프레이즈를 사용하실 건가요?';
  String get ensure_backup => '니모닉을 틀림없이 백업했습니다.';
  String get word_passphrase => ' 단어, 패스프레이즈 ';
  String get use => '사용';
  String get do_not => '안함';
  String get enter_passphrase => '패스프레이즈를 입력해 주세요';
  String get backup_guide => '안전한 장소에서 니모닉 문구를 백업해 주세요';
  String get backup_complete => '백업 완료';
  String get warning => '입력하신 패스프레이즈는 보관과 유출에 유의해 주세요';
}

// Path: mnemonic_import_screen
class TranslationsMnemonicImportScreenKr {
  TranslationsMnemonicImportScreenKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get title => '복원하기';
  String get enter_mnemonic_phrase => '니모닉 문구를 입력해 주세요';
  String get put_spaces_between_words => '단어 사이에 띄어쓰기를 넣어주세요';
  String get use_passphrase => '패스프레이즈 사용';
  String get enter_passphrase => '패스프레이즈를 입력해 주세요';
}

// Path: select_vault_type_screen
class TranslationsSelectVaultTypeScreenKr {
  TranslationsSelectVaultTypeScreenKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get title => '지갑 만들기';
  String get singlesig => '하나의 니모닉 문구를 보관하는 단일 서명 지갑이에요';
  String get multisig => '지정한 수의 서명이 필요한 지갑이에요';
  String get empty_key => '현재 볼트에 사용할 수 있는 키가 없어요';
  String get loading_keys => '볼트에 보관된 키를 불러오는 중이에요';
}

// Path: vault_creation_options_screen
class TranslationsVaultCreationOptionsScreenKr {
  TranslationsVaultCreationOptionsScreenKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get coin_flip => '동전을 던져 직접 만들게요';
  String get auto_generate => '앱에서 만들어 주세요';
  String get import_mnemonic => '사용 중인 니모닉 문구가 있어요';
}

// Path: vault_name_icon_setup_screen
class TranslationsVaultNameIconSetupScreenKr {
  TranslationsVaultNameIconSetupScreenKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get title => '이름 설정';
  String get saving => '저장 중이에요.';
}

// Path: assign_signers_screen
class TranslationsAssignSignersScreenKr {
  TranslationsAssignSignersScreenKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get order_keys => '동일한 순서를 유지하도록 키 순서를 정렬 할게요';
  String get data_verifying => '데이터 검증 중이에요';
  String get use_internal_key => '이 볼트에 있는 키 사용하기';
}

// Path: confirm_importing_screen
class TranslationsConfirmImportingScreenKr {
  TranslationsConfirmImportingScreenKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get guide1 => '다른 볼트에서 가져온 ';
  String get guide2 => '정보가 일치하는지 ';
  String get guide3 => '확인해 주세요.';
  String get scan_info => '스캔한 정보';
  String get memo => '메모';
  String get placeholder => '키에 대한 간단한 메모를 추가하세요';
}

// Path: select_multisig_quorum_screen
class TranslationsSelectMultisigQuorumScreenKr {
  TranslationsSelectMultisigQuorumScreenKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get total_key_count => '전체 키의 수';
  String get required_signature_count => '필요한 서명 수';
  String get one_or_two_of_n =>
      '하나의 키를 분실하거나 키 보관자 중 한 명이 부재중이더라도 비트코인을 보낼 수 있어요.';
  String get n_of_n =>
      '모든 키가 있어야만 비트코인을 보낼 수 있어요. 단 하나의 키만 잃어버려도 자금에 접근할 수 없게 되니 분실에 각별히 신경써 주세요.';
  String get one_of_n =>
      '하나의 키만 있어도 비트코인을 이동시킬 수 있어요. 상대적으로 보안성이 낮기 때문에 권장하지 않아요.';
}

// Path: signer_qr_bottom_sheet
class TranslationsSignerQrBottomSheetKr {
  TranslationsSignerQrBottomSheetKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get text1 => '서명 트랜잭션 내보내기';
  String get text2_1 => '번 키가 보관된 볼트에서 다중 서명 지갑 ';
  String get text2_2 => ' 선택 - ';
  String get text2_3 => '다중 서명하기';
  String get text2_4 => '를 눌러 아래 QR 코드를 스캔해 주세요.';
}

// Path: signer_scanner_bottom_sheet
class TranslationsSignerScannerBottomSheetKr {
  TranslationsSignerScannerBottomSheetKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get title => '서명 업데이트';
  String get guide =>
      '다른 볼트에서 서명을 추가했나요? 정보를 업데이트 하기 위해 추가된 서명 트랜잭션의 QR 코드를 스캔해 주세요.';
}

// Path: signer_scanner_screen
class TranslationsSignerScannerScreenKr {
  TranslationsSignerScannerScreenKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get title1 => '다중 서명 지갑 가져오기';
  String get title2 => '외부 지갑 서명하기';
  String get guide1_1 => '다른 볼트에서 만든 다중 서명 지갑을 추가할 수 있어요. 추가 하시려는 다중 서명 지갑의 ';
  String get guide1_2 => '지갑 설정 정보 ';
  String get guide1_3 => '화면에 나타나는 QR 코드를 스캔해 주세요.';
  String get guide2_1 => '키를 보관 중인 볼트';
  String get guide2_2 => '의 홈 화면에서 지갑 선택 - ';
  String get guide2_3 => '다중 서명 키로 사용하기 ';
  String get guide2_4 => '메뉴를 선택해 주세요. 화면에 보이는 QR 코드를 스캔합니다.';
}

// Path: address_list_screen
class TranslationsAddressListScreenKr {
  TranslationsAddressListScreenKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String title({required Object name}) => '${name}의 주소';
  String address_index({required Object index}) => '주소 - ${index}';
}

// Path: export_detail_screen
class TranslationsExportDetailScreenKr {
  TranslationsExportDetailScreenKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get title => '내보내기 상세 정보';
}

// Path: mnemonic_view_screen
class TranslationsMnemonicViewScreenKr {
  TranslationsMnemonicViewScreenKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get view_passphrase => '패스프레이즈 보기';
  String get visible_while_pressing => '누르는 동안 보여요';
  String get space_as_blank => ' 공백 문자는 빈칸으로 표시됩니다.';
}

// Path: multi_sig_bsms_screen
class TranslationsMultiSigBsmsScreenKr {
  TranslationsMultiSigBsmsScreenKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  late final TranslationsMultiSigBsmsScreenBottomSheetKr bottom_sheet =
      TranslationsMultiSigBsmsScreenBottomSheetKr.internal(_root);
  String get title => '지갑 설정 정보';
  String get text1 => '안전한 다중 서명 지갑 관리를 위한 표준에 따라 지갑 설정 정보를 관리하고 공유합니다.';
  String get text2 => '모든 키가 볼트에 저장되어 있습니다.';
  String get text3 => '같은 키를 보관하고 있는 다른 볼트에서도 이 QR을 읽어 다중 서명 지갑을 추가할 수 있습니다.';
  String text4({required Object gen}) =>
      '이 다중 서명 지갑에 지정된 **${gen}** 키의 니모닉 문구는 현재 다른 볼트에 있습니다.';
  String text5({required Object gen}) =>
      '**${gen}** 키 보관 지갑 - **다중 서명 지갑 가져오기**에서 아래 QR 코드를 읽어 주세요. 다중 서명 트랜잭션에 **${gen}** 키로 서명하기 위해 이 절차가 반드시 필요합니다.';
  String gen1({required Object first}) => '${first}번';
  String gen2({required Object first, required Object last}) =>
      '${first}번과 ${last}번';
  String gen3({required Object first, required Object last}) =>
      '${first}번 또는 ${last}번';
  String get view_detail => '상세 정보 보기';
}

// Path: multi_sig_memo_bottom_sheet
class TranslationsMultiSigMemoBottomSheetKr {
  TranslationsMultiSigMemoBottomSheetKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get imported_wallet_memo => '외부 지갑 메모';
  String get placeholder => '메모를 작성해주세요.';
}

// Path: multi_sig_setting_screen
class TranslationsMultiSigSettingScreenKr {
  TranslationsMultiSigSettingScreenKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get edit_memo => '메모 수정';
  String get add_memo => '메모 추가';
  String get view_bsms => '지갑 설정 정보 보기';
  String tooltip({required Object total, required Object count}) =>
      '${total}개의 키 중 ${count}개로 서명해야 하는\n다중 서명 지갑이예요.';
}

// Path: select_export_type_screen
class TranslationsSelectExportTypeScreenKr {
  TranslationsSelectExportTypeScreenKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get title => '내보내기';
  String get export_type => '어떤 용도로 사용하시나요?';
  String get watch_only => '월렛에\n보기 전용 지갑 추가';
  String get multisig => '다른 볼트에서\n다중 서명 키로 사용';
}

// Path: signer_bsms_screen
class TranslationsSignerBsmsScreenKr {
  TranslationsSignerBsmsScreenKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get guide1_1 => '다른 볼트';
  String get guide1_2 => '에서 다중 서명 지갑을 생성 중이시군요! 다른 볼트에서 ';
  String get guide1_3 => '가져오기 + 버튼';
  String get guide1_4 => '을 누른 후 나타난 가져오기 화면에서, 아래 ';
  String get guide1_5 => 'QR 코드를 스캔';
  String get guide1_6 => '해 주세요.';
  String get export_info => '내보낼 정보';
}

// Path: sync_to_wallet_screen
class TranslationsSyncToWalletScreenKr {
  TranslationsSyncToWalletScreenKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String title({required Object name}) => '${name} 내보내기';
  String get guide1_1 => '월렛';
  String get guide1_2 => '에서 + 버튼을 누르고, 아래 ';
  String get guide1_3 => 'QR 코드를 스캔';
  String get guide1_4 => '해 주세요. 안전한 보기 전용 지갑을 사용하실 수 있어요.';
  String get view_detail => '상세 정보 보기';
}

// Path: vault_menu_screen
class TranslationsVaultMenuScreenKr {
  TranslationsVaultMenuScreenKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  late final TranslationsVaultMenuScreenTitleKr title =
      TranslationsVaultMenuScreenTitleKr.internal(_root);
  late final TranslationsVaultMenuScreenDescriptionKr description =
      TranslationsVaultMenuScreenDescriptionKr.internal(_root);
}

// Path: vault_settings
class TranslationsVaultSettingsKr {
  TranslationsVaultSettingsKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get used_in_multisig => '다중 서명 지갑에서 사용 중입니다';
  String get of => '의 ';
  String nth({required Object index}) => '${index} 번';
  String get key => ' 키';
}

// Path: bottom_sheet
class TranslationsBottomSheetKr {
  TranslationsBottomSheetKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get view_mit_license => 'MIT 라이선스 전문 보기';
  String get contact_by_email => '이메일 문의';
  String get ask_about_license => '[볼트] 라이선스 문의';
  String get mnemonic_backup => '생성된 니모닉 문구를\n백업해 주세요.';
  String get mnemonic_backup_and_confirm_passphrase =>
      '생성된 니모닉 문구를 백업하시고\n패스프레이즈를 확인해 주세요.';
}

// Path: alert
class TranslationsAlertKr {
  TranslationsAlertKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String confirm_deletion({required Object name}) =>
      '정말로 볼트에서 ${name} 정보를 삭제하시겠어요?';
  String get bio_title1 => '잠금 해제 시 생체 인증을 사용하시겠습니까?';
  String get bio_title2 => '생체 인증을 진행해 주세요.';
  String get bio_title3 => '생체 인증 권한이 필요합니다.';
  String get bio_title4 => '생체 인증 권한이 거부되었습니다.';
  String get bio_text =>
      '생체 인증을 통한 잠금 해제를 하시려면\n설정 > 코코넛 볼트에서 생체 인증 권한을 허용해 주세요.';
  String get bio_btn => '설정화면으로 이동';
  late final TranslationsAlertForgotPasswordKr forgot_password =
      TranslationsAlertForgotPasswordKr.internal(_root);
  late final TranslationsAlertUnchangePasswordKr unchange_password =
      TranslationsAlertUnchangePasswordKr.internal(_root);
  late final TranslationsAlertExitSignKr exit_sign =
      TranslationsAlertExitSignKr.internal(_root);
  late final TranslationsAlertStopSignKr stop_sign =
      TranslationsAlertStopSignKr.internal(_root);
  late final TranslationsAlertReselectKr reselect =
      TranslationsAlertReselectKr.internal(_root);
  late final TranslationsAlertEmptyVaultKr empty_vault =
      TranslationsAlertEmptyVaultKr.internal(_root);
  late final TranslationsAlertQuitCreatingMutisigWalletKr
      quit_creating_mutisig_wallet =
      TranslationsAlertQuitCreatingMutisigWalletKr.internal(_root);
  late final TranslationsAlertResetNthKeyKr reset_nth_key =
      TranslationsAlertResetNthKeyKr.internal(_root);
  late final TranslationsAlertStopImportingKr stop_importing =
      TranslationsAlertStopImportingKr.internal(_root);
  late final TranslationsAlertDuplicateKeyKr duplicate_key =
      TranslationsAlertDuplicateKeyKr.internal(_root);
  late final TranslationsAlertSameWalletKr same_wallet =
      TranslationsAlertSameWalletKr.internal(_root);
  late final TranslationsAlertIncludeInternalKeyKr include_internal_key =
      TranslationsAlertIncludeInternalKeyKr.internal(_root);
  late final TranslationsAlertWalletCreationFailedKr wallet_creation_failed =
      TranslationsAlertWalletCreationFailedKr.internal(_root);
  late final TranslationsAlertStopCreatingMnemonicKr stop_creating_mnemonic =
      TranslationsAlertStopCreatingMnemonicKr.internal(_root);
  late final TranslationsAlertStopGeneratingMnemonicKr
      stop_generating_mnemonic =
      TranslationsAlertStopGeneratingMnemonicKr.internal(_root);
  late final TranslationsAlertStopImportingMnemonicKr stop_importing_mnemonic =
      TranslationsAlertStopImportingMnemonicKr.internal(_root);
  String get erase_all_entered_so_far => '정말로 지금까지 입력한 정보를\n모두 지우시겠어요?';
}

// Path: toast
class TranslationsToastKr {
  TranslationsToastKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get clipboard_copied => '클립보드에 복사되었어요.';
  String get back_exit => '뒤로 가기 버튼을 한 번 더 누르면 종료됩니다.';
  String get scroll_down => '스크롤을 내려서 모두 확인해주세요';
  String get data_updated => '정보를 수정했어요';
  String get name_already_used => '이미 사용하고 있는 이름으로는 바꿀 수 없어요';
  String get name_already_used2 => '이미 사용 중인 이름은 설정할 수 없어요';
  String get name_multisig_in_use => '다중 서명 지갑에 사용되고 있어 삭제할 수 없어요.';
  String get mnemonic_already_added => '이미 추가되어 있는 니모닉이에요';
  String get mnemonic_copied => '니모닉 문구가 복사됐어요';
  String multisig_already_added({required Object name}) =>
      '이미 추가되어 있는 다중 서명 지갑이에요. (${name})';
}

// Path: errors
class TranslationsErrorsKr {
  TranslationsErrorsKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get invalid_singlesig_qr_error => '잘못된 QR이에요. 다시 시도해 주세요.';
  String get invalid_multisig_qr_error =>
      '잘못된 QR이예요.\n가져올 다중 서명 지갑의 정보 화면에서 "지갑 설정 정보 보기"에 나오는 QR 코드를 스캔해 주세요.';
  String get unsupport_bsms_version_error =>
      '지원하지 않는 BSMS 버전이에요. BSMS 1.0만 지원됩니다.';
  String get unsupport_derivation_path_error => '커스텀 파생 경로는 지원되지 않아요.';
  String get duplicate_multisig_registered_error => '이미 등록된 다중 서명 지갑입니다.';
  String get pin_incorrect_error => '비밀번호가 일치하지 않아요';
  String get duplicate_pin_error => '이미 사용중인 비밀번호예요';
  String get pin_processing_error => '처리 중 문제가 발생했어요';
  String pin_incorrect_with_remaining_attempts_error({required Object count}) =>
      '${count}번 다시 시도할 수 있어요';
  String get pin_max_attempts_exceeded_error => '더 이상 시도할 수 없어요\n앱을 종료해 주세요';
  String retry_after({required Object time}) => '${time} 후 재시도 할 수 있어요';
  String get pin_exceeded_reset => '더 이상 시도할 수 없어요\n앱을 초기화 한 후에 이용할 수 있어요';
  String invalid_word_error({required Object filter}) => '잘못된 단어예요. ${filter}';
  String get invalid_mnemonic_phrase => '잘못된 니모닉 문구예요';
  String get data_loading_error => '데이터를 불러오는 중 오류가 발생했습니다.';
  String get data_not_found_error => '데이터가 없습니다.';
  String get cannot_sign_error => '서명할 수 없는 트랜잭션이에요.';
  String get invalid_sign_error => '잘못된 서명 정보에요. 다시 시도해 주세요.';
  String scan_error({required Object error}) => '[스캔 실패] ${error}';
  String sign_error({required Object error}) => '[서명 실패]: ${error}';
  String device_info_unavailable_error({required Object error}) =>
      '디바이스 정보를 불러올 수 없음 : ${error}';
  String get camera_permission_error => '카메라 권한이 없습니다.';
  String get creation_error => '생성 실패';
  String get export_error => '내보내기 실패';
  String psbt_parsing_error({required Object error}) => 'psbt 파싱 실패: ${error}';
  String get not_related_multisig_wallet_error =>
      '이 지갑을 키로 사용한 다중 서명 지갑이 아닙니다.';
}

// Path: tooltip
class TranslationsTooltipKr {
  TranslationsTooltipKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get mfp => '지갑의 고유 값이에요.\n마스터 핑거프린트(MFP)라고도 해요.';
}

// Path: mnemonic_confirm_screen.warning
class TranslationsMnemonicConfirmScreenWarningKr {
  TranslationsMnemonicConfirmScreenWarningKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get contains_space_character => '⚠︎ 공백 문자가 포함되어 있습니다.';
  String get long_passphrase => '⚠︎ 긴 패스프레이즈: 스크롤을 끝까지 내려 모두 확인해 주세요.';
}

// Path: multi_sig_bsms_screen.bottom_sheet
class TranslationsMultiSigBsmsScreenBottomSheetKr {
  TranslationsMultiSigBsmsScreenBottomSheetKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get title => '지갑 상세 정보';
  String get info_copied => '지갑 상세 정보가 복사됐어요';
}

// Path: vault_menu_screen.title
class TranslationsVaultMenuScreenTitleKr {
  TranslationsVaultMenuScreenTitleKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String menu1({required Object name}) => '${name} 정보';
  String get menu2 => '서명하기';
  String get menu3 => '주소 보기';
  String get menu4 => '지갑 정보 내보내기';
  String get menu5 => '다중 서명 키로 사용하기';
  String get menu6 => '다중 서명 지갑 가져오기';
  String menu7({required Object name}) => '${name} 정보';
  String get menu8 => '다중 서명하기';
}

// Path: vault_menu_screen.description
class TranslationsVaultMenuScreenDescriptionKr {
  TranslationsVaultMenuScreenDescriptionKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get menu1 => '저장된 니모닉 문구 등을 확인할 수 있어요';
  String get menu2 => '월렛에서 만든 정보를 스캔하고 서명해요';
  String menu3({required Object name}) => '${name}에서 추출한 주소를 확인해요';
  String get menu4 => '보기 전용 지갑을 월렛에 추가해요';
  String get menu5 => '다른 볼트에 내 키를 다중 서명 키로 등록해요';
  String get menu6 => '이 키가 포함된 다중 서명 지갑 정보를 추가해요';
  String get menu7 => '다중 서명 지갑의 정보를 확인할 수 있어요';
  String get menu8 => '전송 정보를 스캔하고 서명해요';
}

// Path: alert.forgot_password
class TranslationsAlertForgotPasswordKr {
  TranslationsAlertForgotPasswordKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get title => '비밀번호를 잊으셨나요?';
  String get description1 => '[초기화하기]를 눌러 비밀번호를 초기화할 수 있어요.\n';
  String get description2 => '비밀번호를 초기화하면 저장된 정보가 삭제돼요. 그래도 초기화 하시겠어요?';
  String get btn_reset => '초기화하기';
}

// Path: alert.unchange_password
class TranslationsAlertUnchangePasswordKr {
  TranslationsAlertUnchangePasswordKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get title => '비밀번호를 유지하시겠어요?';
  String get description => '[그만하기]를 누르면 설정 화면으로 돌아갈게요.';
}

// Path: alert.exit_sign
class TranslationsAlertExitSignKr {
  TranslationsAlertExitSignKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get title => '서명하기 종료';
  String get description => '서명을 종료하고 홈화면으로 이동해요.\n정말 종료하시겠어요?';
}

// Path: alert.stop_sign
class TranslationsAlertStopSignKr {
  TranslationsAlertStopSignKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get title => '서명하기 중단';
  String get description => '서명 내역이 사라져요.\n정말 그만하시겠어요?';
}

// Path: alert.reselect
class TranslationsAlertReselectKr {
  TranslationsAlertReselectKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get title => '다시 고르기';
  String get description => '지금까지 입력한 정보가 모두 지워져요.\n정말로 다시 선택하시겠어요?';
}

// Path: alert.empty_vault
class TranslationsAlertEmptyVaultKr {
  TranslationsAlertEmptyVaultKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get title => '볼트에 저장된 키가 없어요';
  String get description => '키를 사용하기 위해 일반 지갑을 먼저 만드시겠어요?';
}

// Path: alert.quit_creating_mutisig_wallet
class TranslationsAlertQuitCreatingMutisigWalletKr {
  TranslationsAlertQuitCreatingMutisigWalletKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get title => '다중 서명 지갑 만들기 중단';
  String get description => '정말 지갑 생성을 그만하시겠어요?';
}

// Path: alert.reset_nth_key
class TranslationsAlertResetNthKeyKr {
  TranslationsAlertResetNthKeyKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String title({required Object index}) => '${index}번 키 초기화';
  String get description => '지정한 키 정보를 삭제하시겠어요?';
}

// Path: alert.stop_importing
class TranslationsAlertStopImportingKr {
  TranslationsAlertStopImportingKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get title => '가져오기 중단';
  String get description => '스캔된 정보가 사라집니다.\n정말 가져오기를 그만하시겠어요?';
}

// Path: alert.duplicate_key
class TranslationsAlertDuplicateKeyKr {
  TranslationsAlertDuplicateKeyKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get title => '이미 추가된 키입니다';
  String get description => '중복되지 않는 다른 키로 가져와 주세요';
}

// Path: alert.same_wallet
class TranslationsAlertSameWalletKr {
  TranslationsAlertSameWalletKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get title => '보유하신 지갑 중 하나입니다';
  String description({required Object name}) => '\'${name}\'와 같은 지갑입니다';
}

// Path: alert.include_internal_key
class TranslationsAlertIncludeInternalKeyKr {
  TranslationsAlertIncludeInternalKeyKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get title => '외부 지갑 개수 초과';
  String get description => '적어도 1개는 이 볼트에 있는 키를 사용해 주세요';
}

// Path: alert.wallet_creation_failed
class TranslationsAlertWalletCreationFailedKr {
  TranslationsAlertWalletCreationFailedKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get title => '지갑 생성 실패';
  String get description => '유효하지 않은 정보입니다.';
}

// Path: alert.stop_creating_mnemonic
class TranslationsAlertStopCreatingMnemonicKr {
  TranslationsAlertStopCreatingMnemonicKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get title => '니모닉 만들기 중단';
  String get description => '정말 니모닉 만들기를 그만하시겠어요?';
}

// Path: alert.stop_generating_mnemonic
class TranslationsAlertStopGeneratingMnemonicKr {
  TranslationsAlertStopGeneratingMnemonicKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get title => '니모닉 생성 중단';
  String get description => '정말 니모닉 생성을 그만하시겠어요?';
}

// Path: alert.stop_importing_mnemonic
class TranslationsAlertStopImportingMnemonicKr {
  TranslationsAlertStopImportingMnemonicKr.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get title => '복원 중단';
  String get description => '정말 복원하기를 그만하시겠어요?';
}

/// Flat map(s) containing all translations.
/// Only for edge cases! For simple maps, use the map function of this library.
extension on Translations {
  dynamic _flatMapFunction(String path) {
    switch (path) {
      case 'coconut_vault':
        return 'Coconut Vault';
      case 'btc':
        return 'BTC';
      case 'hour':
        return '시간';
      case 'minute':
        return '분';
      case 'second':
        return '초';
      case 'settings':
        return '설정';
      case 'confirm':
        return '확인';
      case 'complete':
        return '완료';
      case 'cancel':
        return '취소';
      case 'next':
        return '다음';
      case 'save':
        return '저장';
      case 'select':
        return '선택';
      case 'warning':
        return '주의';
      case 'security':
        return '보안';
      case 'yes':
        return '네';
      case 'no':
        return '아니오';
      case 'front':
        return '앞';
      case 'back':
        return '뒤';
      case 'memo':
        return '메모';
      case 'close':
        return '닫기';
      case 'delete':
        return '지우기';
      case 'remove':
        return '삭제하기';
      case 'stop':
        return '그만하기';
      case 'start':
        return '시작하기';
      case 'quit':
        return '종료하기';
      case 'import':
        return '가져오기';
      case 'export':
        return '내보내기';
      case 'passphrase':
        return '패스프레이즈';
      case 'mnemonic':
        return '니모닉 문구';
      case 'testnet':
        return '테스트넷';
      case 'license':
        return '라이선스';
      case 'name':
        return '이름';
      case 'skip':
        return '건너뛰기';
      case 'restore':
        return '복원하기';
      case 'change':
        return '잔돈';
      case 'receiving':
        return '입금';
      case 'info':
        return '정보';
      case 'email_subject':
        return '[코코넛 볼트] 이용 관련 문의';
      case 'signature':
        return '서명';
      case 'sign_completion':
        return '서명 완료';
      case 'sign':
        return '서명하기';
      case 'signed_tx':
        return '서명 트랜잭션';
      case 'sign_completed':
        return '서명을 완료했습니다';
      case 'stop_sign':
        return '서명 종료하기';
      case 'select_completed':
        return '선택 완료';
      case 'checklist':
        return '확인 사항';
      case 'wallet_id':
        return '지갑 ID';
      case 'mnemonic_wordlist':
        return '니모닉 문구 단어집';
      case 'singlesig_wallet':
        return '일반 지갑';
      case 'multisig_wallet':
        return '다중 서명 지갑';
      case 'extended_public_key':
        return '확장 공개키';
      case 'app_info':
        return '앱 정보';
      case 'inquiry_details':
        return '문의 내용';
      case 'license_details':
        return '라이선스 안내';
      case 'external_wallet':
        return '외부 지갑';
      case 'recipient':
        return '보낼 주소';
      case 'send_amount':
        return '보낼 수량';
      case 'estimated_fee':
        return '예상 수수료';
      case 'total_amount':
        return '총 소요 수량';
      case 'key_list':
        return '키 목록';
      case 'view_mnemonic':
        return '니모닉 문구 보기';
      case 'view_passphrase':
        return '패스프레이즈 보기';
      case 'view_app_info':
        return '앱 정보 보기';
      case 'view_all':
        return '전체 보기';
      case 'view_details_info':
        return '상세 정보 보기';
      case 'view_address':
        return '주소 보기';
      case 'view_tutorial':
        return '튜토리얼 보기';
      case 'delete_all':
        return '모두 지우기';
      case 'delete_one':
        return '하나 지우기';
      case 're_select':
        return '다시 고르기';
      case 'name_info':
        return ({required Object name}) => '${name} 정보';
      case 'name_wallet':
        return ({required Object name}) => '${name} 지갑';
      case 'bitcoin_text':
        return ({required Object bitcoin}) => '${bitcoin} BTC';
      case 'sign_required':
        return ({required Object count}) => '${count}개의 서명이 필요합니다';
      case 'name_text_count':
        return ({required Object count}) => '(${count} / 20)';
      case 'wallet_subtitle':
        return ({required Object name, required Object index}) =>
            '${name}의 ${index}번 키';
      case 'forgot_password':
        return '비밀번호가 기억나지 않나요?';
      case 'scan_qr_url_link':
        return '네트워크가 활성화된 기기에서 QR 코드를 스캔하시거나 위의 URL 주소로 접속해 주세요.';
      case 'scan_qr_email_link':
        return '네트워크가 활성화된 기기에서 QR 코드를 스캔하시거나 위의 주소로 메일을 전송해 주세요';
      case 'developer_option':
        return '개발자 옵션';
      case 'vault_list_tab.add_wallet':
        return '지갑을 추가해 주세요';
      case 'vault_list_tab.top_right_icon':
        return '오른쪽 위 + 버튼을 눌러도 추가할 수 있어요';
      case 'vault_list_tab.btn_add':
        return '바로 추가하기';
      case 'app_unavailable_notification_screen.network_on':
        return '휴대폰이 외부와 연결된 상태예요';
      case 'app_unavailable_notification_screen.text1_1':
        return '안전한 사용을 위해';
      case 'app_unavailable_notification_screen.text1_2':
        return '지금 바로 ';
      case 'app_unavailable_notification_screen.text1_3':
        return '앱을 종료';
      case 'app_unavailable_notification_screen.text1_4':
        return '해 주세요';
      case 'app_unavailable_notification_screen.text2':
        return '네트워크 및 블루투스';
      case 'app_unavailable_notification_screen.text3':
        return '개발자 옵션 OFF';
      case 'app_unavailable_notification_screen.check_status':
        return '상태를 확인해 주세요';
      case 'ios_bluetooth_auth_notification_screen.allow_permission':
        return '코코넛 볼트에 블루투스 권한을 허용해 주세요';
      case 'ios_bluetooth_auth_notification_screen.text1_1':
        return '안전한 사용을 위해';
      case 'ios_bluetooth_auth_notification_screen.text1_2':
        return '지금 바로 앱을 종료하신 후';
      case 'ios_bluetooth_auth_notification_screen.text1_3':
        return '설정 화면에서';
      case 'ios_bluetooth_auth_notification_screen.text1_4':
        return '코코넛 볼트의 ';
      case 'ios_bluetooth_auth_notification_screen.text1_5':
        return '블루투스 권한';
      case 'ios_bluetooth_auth_notification_screen.text1_6':
        return '을';
      case 'ios_bluetooth_auth_notification_screen.text1_7':
        return '허용해 주세요';
      case 'pin_check_screen.enter_password':
        return '비밀번호를 눌러주세요';
      case 'pin_check_screen.warning':
        return '⚠︎ 3회 모두 틀리면 볼트를 초기화해야 합니다';
      case 'pin_setting_screen.set_password':
        return '안전한 볼트 사용을 위해\n먼저 비밀번호를 설정할게요';
      case 'pin_setting_screen.enter_again':
        return '다시 한번 확인할게요';
      case 'pin_setting_screen.new_password':
        return '새로운 비밀번호를 눌러주세요';
      case 'pin_setting_screen.keep_in_mind':
        return '반드시 기억할 수 있는 비밀번호로 설정해 주세요';
      case 'security_self_check_screen.check1':
        return '나의 개인키는 내가 스스로 책임집니다.';
      case 'security_self_check_screen.check2':
        return '니모닉 문구 화면을 캡처하거나 촬영하지 않습니다.';
      case 'security_self_check_screen.check3':
        return '니모닉 문구를 네트워크와 연결된 환경에 저장하지 않습니다.';
      case 'security_self_check_screen.check4':
        return '니모닉 문구의 순서와 단어의 철자를 확인합니다.';
      case 'security_self_check_screen.check5':
        return '패스프레이즈에 혹시 의도하지 않은 문자가 포함되지는 않았는지 한번 더 확인합니다.';
      case 'security_self_check_screen.check6':
        return '니모닉 문구와 패스프레이즈는 아무도 없는 안전한 곳에서 확인합니다.';
      case 'security_self_check_screen.check7':
        return '니모닉 문구와 패스프레이즈를 함께 보관하지 않습니다.';
      case 'security_self_check_screen.check8':
        return '소액으로 보내기 테스트를 한 후 지갑 사용을 시작합니다.';
      case 'security_self_check_screen.check9':
        return '위 사항을 주기적으로 점검하고, 안전하게 니모닉 문구를 보관하겠습니다.';
      case 'security_self_check_screen.guidance':
        return '아래 자가 점검 항목을 숙지하고 니모닉 문구를 반드시 안전하게 보관합니다.';
      case 'tutorial_screen.title1':
        return '튜토리얼을 참고하시면\n더욱 쉽게 사용할 수 있어요';
      case 'tutorial_screen.title2':
        return '도움이 필요하신가요?';
      case 'tutorial_screen.subtitle':
        return '튜토리얼과 함께 사용해 보세요';
      case 'tutorial_screen.content':
        return '인터넷 주소창에 입력해 주세요\ncoconut.onl';
      case 'multisig.nth_key':
        return ({required Object index}) => '${index}번 키 -';
      case 'account_selection_bottom_sheet_screen.text':
        return '서명할 계정을 선택해주세요.';
      case 'psbt_confirmation_screen.title':
        return '스캔 정보 확인';
      case 'psbt_confirmation_screen.guide':
        return '월렛에서 스캔한 정보가 맞는지 다시 한번 확인해 주세요.';
      case 'psbt_confirmation_screen.self_sending':
        return '내 지갑으로 보내는 트랜잭션입니다.';
      case 'psbt_confirmation_screen.warning':
        return '⚠️ 해당 지갑으로 만든 psbt가 아닐 수 있습니다. 또는 잔액이 없는 트랜잭션일 수 있습니다.';
      case 'psbt_scanner_screen.guide_multisig':
        return '월렛에서 만든 보내기 정보 또는 외부 볼트에서 다중 서명 중인 정보를 스캔해주세요.';
      case 'psbt_scanner_screen.guide_singlesig':
        return '월렛에서 만든 보내기 정보를 스캔해 주세요. 반드시 지갑 이름이 같아야 해요.';
      case 'signed_transaction_qr_screen.guide_multisig':
        return '다중 서명을 완료했어요. 보내기 정보를 생성한 월렛으로 아래 QR 코드를 스캔해 주세요.';
      case 'signed_transaction_qr_screen.guide_singlesig':
        return ({required Object name}) =>
            '월렛의 \'${name} 지갑\'에서 만든 보내기 정보에 서명을 완료했어요. 월렛으로 아래 QR 코드를 스캔해 주세요.';
      case 'singlesig_sign_screen.text':
        return '이미 서명된 트랜잭션입니다';
      case 'app_info_screen.made_by_team_pow':
        return '포우팀이 만듭니다.';
      case 'app_info_screen.category1_ask':
        return '궁금한 점이 있으신가요?';
      case 'app_info_screen.go_to_pow':
        return 'POW 커뮤니티 바로가기';
      case 'app_info_screen.ask_to_telegram':
        return '텔레그램 채널로 문의하기';
      case 'app_info_screen.ask_to_x':
        return 'X로 문의하기';
      case 'app_info_screen.ask_to_email':
        return '이메일로 문의하기';
      case 'app_info_screen.category2_opensource':
        return 'Coconut Vault는 오픈소스입니다';
      case 'app_info_screen.license':
        return '라이선스 안내';
      case 'app_info_screen.mit_license':
        return 'MIT License';
      case 'app_info_screen.coconut_lib':
        return 'coconut_lib';
      case 'app_info_screen.coconut_wallet':
        return 'coconut_wallet';
      case 'app_info_screen.coconut_vault':
        return 'coconut_vuault';
      case 'app_info_screen.github':
        return 'Github';
      case 'app_info_screen.contribution':
        return '오픈소스 개발 참여하기';
      case 'app_info_screen.version_and_date':
        return ({required Object version, required Object releasedAt}) =>
            'CoconutVault ver. ${version} (released at ${releasedAt})';
      case 'app_info_screen.inquiry':
        return '문의 내용';
      case 'read_file_view_screen.mit_license':
        return 'MIT LICENSE';
      case 'read_file_view_screen.contribution':
        return '오픈소스 개발 참여하기';
      case 'license_screen.text1':
        return '코코넛 볼트는 MIT 라이선스를 따르며 저작권은 대한민국의 논스랩 주식회사에 있습니다. MIT 라이선스 전문은 ';
      case 'license_screen.text2':
        return '에서 확인해 주세요.\n\n이 애플리케이션에 포함된 타사 소프트웨어에 대한 저작권을 다음과 같이 명시합니다. 이에 대해 궁금한 사항이 있으시면 ';
      case 'license_screen.text3':
        return '으로 문의해 주시기 바랍니다.';
      case 'mnemonic_word_list_screen.search_mnemonic_word':
        return '영문으로 검색해 보세요';
      case 'mnemonic_word_list_screen.result':
        return ({required Object text}) => '\'${text}\' 검색 결과';
      case 'mnemonic_word_list_screen.such_no_result':
        return '검색 결과가 없어요';
      case 'settings_screen.use_biometric':
        return '생체 인증 사용하기';
      case 'settings_screen.change_password':
        return '비밀번호 바꾸기';
      case 'settings_screen.set_password':
        return '비밀번호 설정하기';
      case 'guide_screen.keep_network_off':
        return '안전한 비트코인 보관을 위해,\n항상 연결 상태를 OFF로 유지해주세요';
      case 'guide_screen.network_status':
        return '네트워크 상태';
      case 'guide_screen.bluetooth_status':
        return '블루투스 상태';
      case 'guide_screen.developer_option':
        return '개발자 옵션';
      case 'guide_screen.turn_off_network_and_bluetooth':
        return '네트워크와 블루투스를 모두 꺼주세요';
      case 'guide_screen.disable_developer_option':
        return '개발자 옵션을 비활성화 해주세요';
      case 'guide_screen.on':
        return 'ON';
      case 'guide_screen.off':
        return 'OFF';
      case 'welcome_screen.greeting':
        return '원활한 코코넛 볼트 사용을 위해\n잠깐만 시간을 내주세요';
      case 'welcome_screen.guide1_1':
        return '볼트는';
      case 'welcome_screen.guide1_2':
        return ({required Object suffix}) => '네트워크, 블루투스 연결${suffix}이';
      case 'welcome_screen.guide1_3':
        return '꺼져있는 상태';
      case 'welcome_screen.guide1_4':
        return '에서만';
      case 'welcome_screen.guide1_5':
        return '사용하실 수 있어요';
      case 'welcome_screen.guide2_1':
        return '즉,';
      case 'welcome_screen.guide2_2':
        return '연결이 감지되면';
      case 'welcome_screen.guide2_3':
        return '앱을 사용하실 수 없게';
      case 'welcome_screen.guide2_4':
        return '설계되어 있어요';
      case 'welcome_screen.guide3_1':
        return '안전한 사용';
      case 'welcome_screen.guide3_2':
        return '을 위한';
      case 'welcome_screen.guide3_3':
        return '조치이오니';
      case 'welcome_screen.guide3_4':
        return '사용 시 유의해 주세요';
      case 'welcome_screen.understood':
        return '모두 이해했어요 :)';
      case 'mnemonic_coin_flip_screen.title':
        return '니모닉 문구 만들기';
      case 'mnemonic_coin_flip_screen.words_passphrase':
        return ' 단어, 패스프레이즈 ';
      case 'mnemonic_coin_flip_screen.use':
        return '사용';
      case 'mnemonic_coin_flip_screen.do_not':
        return '안함';
      case 'mnemonic_coin_flip_screen.enter_passphrase':
        return '패스프레이즈를 입력해 주세요';
      case 'mnemonic_coin_flip_screen.coin_head':
        return '앞';
      case 'mnemonic_coin_flip_screen.coin_tail':
        return '뒤';
      case 'mnemonic_confirm_screen.text1':
        return '입력하신 정보가 맞는지\n다시 한번 확인해 주세요.';
      case 'mnemonic_confirm_screen.text2':
        return ({required Object count}) => ' (총 ${count} 글자)';
      case 'mnemonic_confirm_screen.warning.contains_space_character':
        return '⚠︎ 공백 문자가 포함되어 있습니다.';
      case 'mnemonic_confirm_screen.warning.long_passphrase':
        return '⚠︎ 긴 패스프레이즈: 스크롤을 끝까지 내려 모두 확인해 주세요.';
      case 'mnemonic_confirm_screen.btn_confirm_completed':
        return '확인 완료';
      case 'mnemonic_generate_screen.title':
        return '새 니모닉 문구';
      case 'mnemonic_generate_screen.select_word_length':
        return '단어 수를 고르세요';
      case 'mnemonic_generate_screen.twelve':
        return '12 단어';
      case 'mnemonic_generate_screen.twenty_four':
        return '24 단어';
      case 'mnemonic_generate_screen.use_passphrase':
        return '패스프레이즈를 사용하실 건가요?';
      case 'mnemonic_generate_screen.ensure_backup':
        return '니모닉을 틀림없이 백업했습니다.';
      case 'mnemonic_generate_screen.word_passphrase':
        return ' 단어, 패스프레이즈 ';
      case 'mnemonic_generate_screen.use':
        return '사용';
      case 'mnemonic_generate_screen.do_not':
        return '안함';
      case 'mnemonic_generate_screen.enter_passphrase':
        return '패스프레이즈를 입력해 주세요';
      case 'mnemonic_generate_screen.backup_guide':
        return '안전한 장소에서 니모닉 문구를 백업해 주세요';
      case 'mnemonic_generate_screen.backup_complete':
        return '백업 완료';
      case 'mnemonic_generate_screen.warning':
        return '입력하신 패스프레이즈는 보관과 유출에 유의해 주세요';
      case 'mnemonic_import_screen.title':
        return '복원하기';
      case 'mnemonic_import_screen.enter_mnemonic_phrase':
        return '니모닉 문구를 입력해 주세요';
      case 'mnemonic_import_screen.put_spaces_between_words':
        return '단어 사이에 띄어쓰기를 넣어주세요';
      case 'mnemonic_import_screen.use_passphrase':
        return '패스프레이즈 사용';
      case 'mnemonic_import_screen.enter_passphrase':
        return '패스프레이즈를 입력해 주세요';
      case 'select_vault_type_screen.title':
        return '지갑 만들기';
      case 'select_vault_type_screen.singlesig':
        return '하나의 니모닉 문구를 보관하는 단일 서명 지갑이에요';
      case 'select_vault_type_screen.multisig':
        return '지정한 수의 서명이 필요한 지갑이에요';
      case 'select_vault_type_screen.empty_key':
        return '현재 볼트에 사용할 수 있는 키가 없어요';
      case 'select_vault_type_screen.loading_keys':
        return '볼트에 보관된 키를 불러오는 중이에요';
      case 'vault_creation_options_screen.coin_flip':
        return '동전을 던져 직접 만들게요';
      case 'vault_creation_options_screen.auto_generate':
        return '앱에서 만들어 주세요';
      case 'vault_creation_options_screen.import_mnemonic':
        return '사용 중인 니모닉 문구가 있어요';
      case 'vault_name_icon_setup_screen.title':
        return '이름 설정';
      case 'vault_name_icon_setup_screen.saving':
        return '저장 중이에요.';
      case 'assign_signers_screen.order_keys':
        return '동일한 순서를 유지하도록 키 순서를 정렬 할게요';
      case 'assign_signers_screen.data_verifying':
        return '데이터 검증 중이에요';
      case 'assign_signers_screen.use_internal_key':
        return '이 볼트에 있는 키 사용하기';
      case 'confirm_importing_screen.guide1':
        return '다른 볼트에서 가져온 ';
      case 'confirm_importing_screen.guide2':
        return '정보가 일치하는지 ';
      case 'confirm_importing_screen.guide3':
        return '확인해 주세요.';
      case 'confirm_importing_screen.scan_info':
        return '스캔한 정보';
      case 'confirm_importing_screen.memo':
        return '메모';
      case 'confirm_importing_screen.placeholder':
        return '키에 대한 간단한 메모를 추가하세요';
      case 'select_multisig_quorum_screen.total_key_count':
        return '전체 키의 수';
      case 'select_multisig_quorum_screen.required_signature_count':
        return '필요한 서명 수';
      case 'select_multisig_quorum_screen.one_or_two_of_n':
        return '하나의 키를 분실하거나 키 보관자 중 한 명이 부재중이더라도 비트코인을 보낼 수 있어요.';
      case 'select_multisig_quorum_screen.n_of_n':
        return '모든 키가 있어야만 비트코인을 보낼 수 있어요. 단 하나의 키만 잃어버려도 자금에 접근할 수 없게 되니 분실에 각별히 신경써 주세요.';
      case 'select_multisig_quorum_screen.one_of_n':
        return '하나의 키만 있어도 비트코인을 이동시킬 수 있어요. 상대적으로 보안성이 낮기 때문에 권장하지 않아요.';
      case 'signer_qr_bottom_sheet.text1':
        return '서명 트랜잭션 내보내기';
      case 'signer_qr_bottom_sheet.text2_1':
        return '번 키가 보관된 볼트에서 다중 서명 지갑 ';
      case 'signer_qr_bottom_sheet.text2_2':
        return ' 선택 - ';
      case 'signer_qr_bottom_sheet.text2_3':
        return '다중 서명하기';
      case 'signer_qr_bottom_sheet.text2_4':
        return '를 눌러 아래 QR 코드를 스캔해 주세요.';
      case 'signer_scanner_bottom_sheet.title':
        return '서명 업데이트';
      case 'signer_scanner_bottom_sheet.guide':
        return '다른 볼트에서 서명을 추가했나요? 정보를 업데이트 하기 위해 추가된 서명 트랜잭션의 QR 코드를 스캔해 주세요.';
      case 'signer_scanner_screen.title1':
        return '다중 서명 지갑 가져오기';
      case 'signer_scanner_screen.title2':
        return '외부 지갑 서명하기';
      case 'signer_scanner_screen.guide1_1':
        return '다른 볼트에서 만든 다중 서명 지갑을 추가할 수 있어요. 추가 하시려는 다중 서명 지갑의 ';
      case 'signer_scanner_screen.guide1_2':
        return '지갑 설정 정보 ';
      case 'signer_scanner_screen.guide1_3':
        return '화면에 나타나는 QR 코드를 스캔해 주세요.';
      case 'signer_scanner_screen.guide2_1':
        return '키를 보관 중인 볼트';
      case 'signer_scanner_screen.guide2_2':
        return '의 홈 화면에서 지갑 선택 - ';
      case 'signer_scanner_screen.guide2_3':
        return '다중 서명 키로 사용하기 ';
      case 'signer_scanner_screen.guide2_4':
        return '메뉴를 선택해 주세요. 화면에 보이는 QR 코드를 스캔합니다.';
      case 'address_list_screen.title':
        return ({required Object name}) => '${name}의 주소';
      case 'address_list_screen.address_index':
        return ({required Object index}) => '주소 - ${index}';
      case 'export_detail_screen.title':
        return '내보내기 상세 정보';
      case 'mnemonic_view_screen.view_passphrase':
        return '패스프레이즈 보기';
      case 'mnemonic_view_screen.visible_while_pressing':
        return '누르는 동안 보여요';
      case 'mnemonic_view_screen.space_as_blank':
        return ' 공백 문자는 빈칸으로 표시됩니다.';
      case 'multi_sig_bsms_screen.bottom_sheet.title':
        return '지갑 상세 정보';
      case 'multi_sig_bsms_screen.bottom_sheet.info_copied':
        return '지갑 상세 정보가 복사됐어요';
      case 'multi_sig_bsms_screen.title':
        return '지갑 설정 정보';
      case 'multi_sig_bsms_screen.text1':
        return '안전한 다중 서명 지갑 관리를 위한 표준에 따라 지갑 설정 정보를 관리하고 공유합니다.';
      case 'multi_sig_bsms_screen.text2':
        return '모든 키가 볼트에 저장되어 있습니다.';
      case 'multi_sig_bsms_screen.text3':
        return '같은 키를 보관하고 있는 다른 볼트에서도 이 QR을 읽어 다중 서명 지갑을 추가할 수 있습니다.';
      case 'multi_sig_bsms_screen.text4':
        return ({required Object gen}) =>
            '이 다중 서명 지갑에 지정된 **${gen}** 키의 니모닉 문구는 현재 다른 볼트에 있습니다.';
      case 'multi_sig_bsms_screen.text5':
        return ({required Object gen}) =>
            '**${gen}** 키 보관 지갑 - **다중 서명 지갑 가져오기**에서 아래 QR 코드를 읽어 주세요. 다중 서명 트랜잭션에 **${gen}** 키로 서명하기 위해 이 절차가 반드시 필요합니다.';
      case 'multi_sig_bsms_screen.gen1':
        return ({required Object first}) => '${first}번';
      case 'multi_sig_bsms_screen.gen2':
        return ({required Object first, required Object last}) =>
            '${first}번과 ${last}번';
      case 'multi_sig_bsms_screen.gen3':
        return ({required Object first, required Object last}) =>
            '${first}번 또는 ${last}번';
      case 'multi_sig_bsms_screen.view_detail':
        return '상세 정보 보기';
      case 'multi_sig_memo_bottom_sheet.imported_wallet_memo':
        return '외부 지갑 메모';
      case 'multi_sig_memo_bottom_sheet.placeholder':
        return '메모를 작성해주세요.';
      case 'multi_sig_setting_screen.edit_memo':
        return '메모 수정';
      case 'multi_sig_setting_screen.add_memo':
        return '메모 추가';
      case 'multi_sig_setting_screen.view_bsms':
        return '지갑 설정 정보 보기';
      case 'multi_sig_setting_screen.tooltip':
        return ({required Object total, required Object count}) =>
            '${total}개의 키 중 ${count}개로 서명해야 하는\n다중 서명 지갑이예요.';
      case 'select_export_type_screen.title':
        return '내보내기';
      case 'select_export_type_screen.export_type':
        return '어떤 용도로 사용하시나요?';
      case 'select_export_type_screen.watch_only':
        return '월렛에\n보기 전용 지갑 추가';
      case 'select_export_type_screen.multisig':
        return '다른 볼트에서\n다중 서명 키로 사용';
      case 'signer_bsms_screen.guide1_1':
        return '다른 볼트';
      case 'signer_bsms_screen.guide1_2':
        return '에서 다중 서명 지갑을 생성 중이시군요! 다른 볼트에서 ';
      case 'signer_bsms_screen.guide1_3':
        return '가져오기 + 버튼';
      case 'signer_bsms_screen.guide1_4':
        return '을 누른 후 나타난 가져오기 화면에서, 아래 ';
      case 'signer_bsms_screen.guide1_5':
        return 'QR 코드를 스캔';
      case 'signer_bsms_screen.guide1_6':
        return '해 주세요.';
      case 'signer_bsms_screen.export_info':
        return '내보낼 정보';
      case 'sync_to_wallet_screen.title':
        return ({required Object name}) => '${name} 내보내기';
      case 'sync_to_wallet_screen.guide1_1':
        return '월렛';
      case 'sync_to_wallet_screen.guide1_2':
        return '에서 + 버튼을 누르고, 아래 ';
      case 'sync_to_wallet_screen.guide1_3':
        return 'QR 코드를 스캔';
      case 'sync_to_wallet_screen.guide1_4':
        return '해 주세요. 안전한 보기 전용 지갑을 사용하실 수 있어요.';
      case 'sync_to_wallet_screen.view_detail':
        return '상세 정보 보기';
      case 'vault_menu_screen.title.menu1':
        return ({required Object name}) => '${name} 정보';
      case 'vault_menu_screen.title.menu2':
        return '서명하기';
      case 'vault_menu_screen.title.menu3':
        return '주소 보기';
      case 'vault_menu_screen.title.menu4':
        return '지갑 정보 내보내기';
      case 'vault_menu_screen.title.menu5':
        return '다중 서명 키로 사용하기';
      case 'vault_menu_screen.title.menu6':
        return '다중 서명 지갑 가져오기';
      case 'vault_menu_screen.title.menu7':
        return ({required Object name}) => '${name} 정보';
      case 'vault_menu_screen.title.menu8':
        return '다중 서명하기';
      case 'vault_menu_screen.description.menu1':
        return '저장된 니모닉 문구 등을 확인할 수 있어요';
      case 'vault_menu_screen.description.menu2':
        return '월렛에서 만든 정보를 스캔하고 서명해요';
      case 'vault_menu_screen.description.menu3':
        return ({required Object name}) => '${name}에서 추출한 주소를 확인해요';
      case 'vault_menu_screen.description.menu4':
        return '보기 전용 지갑을 월렛에 추가해요';
      case 'vault_menu_screen.description.menu5':
        return '다른 볼트에 내 키를 다중 서명 키로 등록해요';
      case 'vault_menu_screen.description.menu6':
        return '이 키가 포함된 다중 서명 지갑 정보를 추가해요';
      case 'vault_menu_screen.description.menu7':
        return '다중 서명 지갑의 정보를 확인할 수 있어요';
      case 'vault_menu_screen.description.menu8':
        return '전송 정보를 스캔하고 서명해요';
      case 'vault_settings.used_in_multisig':
        return '다중 서명 지갑에서 사용 중입니다';
      case 'vault_settings.of':
        return '의 ';
      case 'vault_settings.nth':
        return ({required Object index}) => '${index} 번';
      case 'vault_settings.key':
        return ' 키';
      case 'bottom_sheet.view_mit_license':
        return 'MIT 라이선스 전문 보기';
      case 'bottom_sheet.contact_by_email':
        return '이메일 문의';
      case 'bottom_sheet.ask_about_license':
        return '[볼트] 라이선스 문의';
      case 'bottom_sheet.mnemonic_backup':
        return '생성된 니모닉 문구를\n백업해 주세요.';
      case 'bottom_sheet.mnemonic_backup_and_confirm_passphrase':
        return '생성된 니모닉 문구를 백업하시고\n패스프레이즈를 확인해 주세요.';
      case 'alert.confirm_deletion':
        return ({required Object name}) => '정말로 볼트에서 ${name} 정보를 삭제하시겠어요?';
      case 'alert.bio_title1':
        return '잠금 해제 시 생체 인증을 사용하시겠습니까?';
      case 'alert.bio_title2':
        return '생체 인증을 진행해 주세요.';
      case 'alert.bio_title3':
        return '생체 인증 권한이 필요합니다.';
      case 'alert.bio_title4':
        return '생체 인증 권한이 거부되었습니다.';
      case 'alert.bio_text':
        return '생체 인증을 통한 잠금 해제를 하시려면\n설정 > 코코넛 볼트에서 생체 인증 권한을 허용해 주세요.';
      case 'alert.bio_btn':
        return '설정화면으로 이동';
      case 'alert.forgot_password.title':
        return '비밀번호를 잊으셨나요?';
      case 'alert.forgot_password.description1':
        return '[초기화하기]를 눌러 비밀번호를 초기화할 수 있어요.\n';
      case 'alert.forgot_password.description2':
        return '비밀번호를 초기화하면 저장된 정보가 삭제돼요. 그래도 초기화 하시겠어요?';
      case 'alert.forgot_password.btn_reset':
        return '초기화하기';
      case 'alert.unchange_password.title':
        return '비밀번호를 유지하시겠어요?';
      case 'alert.unchange_password.description':
        return '[그만하기]를 누르면 설정 화면으로 돌아갈게요.';
      case 'alert.exit_sign.title':
        return '서명하기 종료';
      case 'alert.exit_sign.description':
        return '서명을 종료하고 홈화면으로 이동해요.\n정말 종료하시겠어요?';
      case 'alert.stop_sign.title':
        return '서명하기 중단';
      case 'alert.stop_sign.description':
        return '서명 내역이 사라져요.\n정말 그만하시겠어요?';
      case 'alert.reselect.title':
        return '다시 고르기';
      case 'alert.reselect.description':
        return '지금까지 입력한 정보가 모두 지워져요.\n정말로 다시 선택하시겠어요?';
      case 'alert.empty_vault.title':
        return '볼트에 저장된 키가 없어요';
      case 'alert.empty_vault.description':
        return '키를 사용하기 위해 일반 지갑을 먼저 만드시겠어요?';
      case 'alert.quit_creating_mutisig_wallet.title':
        return '다중 서명 지갑 만들기 중단';
      case 'alert.quit_creating_mutisig_wallet.description':
        return '정말 지갑 생성을 그만하시겠어요?';
      case 'alert.reset_nth_key.title':
        return ({required Object index}) => '${index}번 키 초기화';
      case 'alert.reset_nth_key.description':
        return '지정한 키 정보를 삭제하시겠어요?';
      case 'alert.stop_importing.title':
        return '가져오기 중단';
      case 'alert.stop_importing.description':
        return '스캔된 정보가 사라집니다.\n정말 가져오기를 그만하시겠어요?';
      case 'alert.duplicate_key.title':
        return '이미 추가된 키입니다';
      case 'alert.duplicate_key.description':
        return '중복되지 않는 다른 키로 가져와 주세요';
      case 'alert.same_wallet.title':
        return '보유하신 지갑 중 하나입니다';
      case 'alert.same_wallet.description':
        return ({required Object name}) => '\'${name}\'와 같은 지갑입니다';
      case 'alert.include_internal_key.title':
        return '외부 지갑 개수 초과';
      case 'alert.include_internal_key.description':
        return '적어도 1개는 이 볼트에 있는 키를 사용해 주세요';
      case 'alert.wallet_creation_failed.title':
        return '지갑 생성 실패';
      case 'alert.wallet_creation_failed.description':
        return '유효하지 않은 정보입니다.';
      case 'alert.stop_creating_mnemonic.title':
        return '니모닉 만들기 중단';
      case 'alert.stop_creating_mnemonic.description':
        return '정말 니모닉 만들기를 그만하시겠어요?';
      case 'alert.stop_generating_mnemonic.title':
        return '니모닉 생성 중단';
      case 'alert.stop_generating_mnemonic.description':
        return '정말 니모닉 생성을 그만하시겠어요?';
      case 'alert.stop_importing_mnemonic.title':
        return '복원 중단';
      case 'alert.stop_importing_mnemonic.description':
        return '정말 복원하기를 그만하시겠어요?';
      case 'alert.erase_all_entered_so_far':
        return '정말로 지금까지 입력한 정보를\n모두 지우시겠어요?';
      case 'toast.clipboard_copied':
        return '클립보드에 복사되었어요.';
      case 'toast.back_exit':
        return '뒤로 가기 버튼을 한 번 더 누르면 종료됩니다.';
      case 'toast.scroll_down':
        return '스크롤을 내려서 모두 확인해주세요';
      case 'toast.data_updated':
        return '정보를 수정했어요';
      case 'toast.name_already_used':
        return '이미 사용하고 있는 이름으로는 바꿀 수 없어요';
      case 'toast.name_already_used2':
        return '이미 사용 중인 이름은 설정할 수 없어요';
      case 'toast.name_multisig_in_use':
        return '다중 서명 지갑에 사용되고 있어 삭제할 수 없어요.';
      case 'toast.mnemonic_already_added':
        return '이미 추가되어 있는 니모닉이에요';
      case 'toast.mnemonic_copied':
        return '니모닉 문구가 복사됐어요';
      case 'toast.multisig_already_added':
        return ({required Object name}) => '이미 추가되어 있는 다중 서명 지갑이에요. (${name})';
      case 'errors.invalid_singlesig_qr_error':
        return '잘못된 QR이에요. 다시 시도해 주세요.';
      case 'errors.invalid_multisig_qr_error':
        return '잘못된 QR이예요.\n가져올 다중 서명 지갑의 정보 화면에서 "지갑 설정 정보 보기"에 나오는 QR 코드를 스캔해 주세요.';
      case 'errors.unsupport_bsms_version_error':
        return '지원하지 않는 BSMS 버전이에요. BSMS 1.0만 지원됩니다.';
      case 'errors.unsupport_derivation_path_error':
        return '커스텀 파생 경로는 지원되지 않아요.';
      case 'errors.duplicate_multisig_registered_error':
        return '이미 등록된 다중 서명 지갑입니다.';
      case 'errors.pin_incorrect_error':
        return '비밀번호가 일치하지 않아요';
      case 'errors.duplicate_pin_error':
        return '이미 사용중인 비밀번호예요';
      case 'errors.pin_processing_error':
        return '처리 중 문제가 발생했어요';
      case 'errors.pin_incorrect_with_remaining_attempts_error':
        return ({required Object count}) => '${count}번 다시 시도할 수 있어요';
      case 'errors.pin_max_attempts_exceeded_error':
        return '더 이상 시도할 수 없어요\n앱을 종료해 주세요';
      case 'errors.retry_after':
        return ({required Object time}) => '${time} 후 재시도 할 수 있어요';
      case 'errors.pin_exceeded_reset':
        return '더 이상 시도할 수 없어요\n앱을 초기화 한 후에 이용할 수 있어요';
      case 'errors.invalid_word_error':
        return ({required Object filter}) => '잘못된 단어예요. ${filter}';
      case 'errors.invalid_mnemonic_phrase':
        return '잘못된 니모닉 문구예요';
      case 'errors.data_loading_error':
        return '데이터를 불러오는 중 오류가 발생했습니다.';
      case 'errors.data_not_found_error':
        return '데이터가 없습니다.';
      case 'errors.cannot_sign_error':
        return '서명할 수 없는 트랜잭션이에요.';
      case 'errors.invalid_sign_error':
        return '잘못된 서명 정보에요. 다시 시도해 주세요.';
      case 'errors.scan_error':
        return ({required Object error}) => '[스캔 실패] ${error}';
      case 'errors.sign_error':
        return ({required Object error}) => '[서명 실패]: ${error}';
      case 'errors.device_info_unavailable_error':
        return ({required Object error}) => '디바이스 정보를 불러올 수 없음 : ${error}';
      case 'errors.camera_permission_error':
        return '카메라 권한이 없습니다.';
      case 'errors.creation_error':
        return '생성 실패';
      case 'errors.export_error':
        return '내보내기 실패';
      case 'errors.psbt_parsing_error':
        return ({required Object error}) => 'psbt 파싱 실패: ${error}';
      case 'errors.not_related_multisig_wallet_error':
        return '이 지갑을 키로 사용한 다중 서명 지갑이 아닙니다.';
      case 'tooltip.mfp':
        return '지갑의 고유 값이에요.\n마스터 핑거프린트(MFP)라고도 해요.';
      default:
        return null;
    }
  }
}
