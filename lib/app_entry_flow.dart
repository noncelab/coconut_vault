/// 앱 진입 시 상태 플로우를 나타냅니다.
enum AppEntryFlow {
  splash,
  firstLaunch,
  securityPrecheck, // 보안 검사 실행
  vaultModeSelection, // 앱 최초 실행 시 보안 검사 통과 후 모드 선택
  pinCheck,
  vaultHome,
  vaultResetCompleted, // 지갑 초기화 완료 상태
  cannotAccessToSecureZone, // 보안 영역 접근 불가 상태
}
