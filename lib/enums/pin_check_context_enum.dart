enum PinCheckContextEnum {
  appLaunch, // 앱 구동 후 핀 체크
  appResume, // 앱이 다시 활성화될 때 (AppLifecycleState.paused) TODO: lock은 Deprecated
  sensitiveAction, // 니모닉, xpub 확인, 삭제 등 보안이 필요한 작업
  change // 핀 변경
}
