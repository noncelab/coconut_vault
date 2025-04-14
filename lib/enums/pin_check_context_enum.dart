enum PinCheckContextEnum {
  appLaunch, // 앱 구동 후 핀 체크
  sensitiveAction, // 니모닉, xpub 확인, 삭제 등 보안이 필요한 작업
  change, // 핀 변경
  restoreBottomSheet, // 복원 파일 발견 화면의 핀 체크
}
