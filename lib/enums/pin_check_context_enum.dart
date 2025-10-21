enum PinCheckContextEnum {
  appLaunch, // 앱 구동 후 핀 체크
  appResumed, // 앱이 포그라운드로 돌아왔을 때 핀 체크
  sensitiveAction, // 니모닉, xpub 확인 등 보안이 필요한 작업
  pinChange, // 핀 변경
  seedDeletion, // 삭제
}
