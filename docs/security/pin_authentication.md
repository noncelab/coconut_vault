# 볼트 PIN verifier 및 제한 상태 저장

참고: `coconut_wallet`의 `enhance/756-wallet-pin-security`
(`40e89b57151a6dbc0cd5e123782cefaf8f3748ed`). 월렛의 KDF 구현을 사용하고 볼트의 기존 제한 정책을 유지한다.

## 보안 레코드

- `vault_pin_verifier_v1`: JSON 형식 버전 1, `algorithm=argon2id`, `argonVersion=19`,
  `memory=19456` KiB, `iterations=2`, `parallelism=1`, 문자 PIN 여부,
  16바이트 salt와 32바이트 verifier의 Base64 값.
- 설정·변경·레거시 이전마다 `Random.secure()`로 새 salt를 생성한다.
- `cryptography` 2.7.0, 별도 isolate를 사용한다. Flutter 3.29.1/Dart 3.7에서 실제 연산과
  메인 isolate 실행 지속을 테스트했다. 19MiB 비용의 저사양 실제 기기 성능은 별도 측정이 필요하다.
- `vault_pin_lock_v1`: 버전, 회차(`turn`), 회차 내 실패 횟수(`attempts`),
  다음 인증 가능 절대 시각(`unlockAt`). 영구 잠금은 회차 8과 `-1`로 저장한다.
- PIN 해제는 명시적 `disabled` 레코드를 저장한다. 앱 종료로 표시용 SharedPreferences 갱신이
  누락되어도 보안 레코드의 PIN 설정 여부와 문자 PIN 여부를 다음 시작에서 복구한다.
- 두 레코드는 기존 SecureStorage의 Android 암호화 설정과 iOS passcode 접근 설정을 사용한다.
  시드·지갑 암호화와 Secure Zone 키 생성·저장 구조는 변경하지 않는다.

## 이전과 중단 복구

1. 시작 시 보안 제한 레코드를 엄격하게 읽는다. 없다면 기존 SharedPreferences의 회차·실패 횟수·
   제한 시각을 보안 저장하고 동일한 값이 읽히는지 확인한 후 기존 제한 키를 제거한다.
2. 신규 verifier가 없을 때만 기존 `VAULT_PIN` SHA-256을 검증한다.
3. 올바른 기존 PIN을 입력한 경우 Argon2id 레코드를 생성·저장하고 읽어서 확인한다.
4. 그 이후 기존 SHA-256 키를 삭제하고, 인증 성공에 따른 제한 초기화를 저장한 뒤 성공을 반환한다.

기존 버전은 `실패 횟수=3 → 회차 증가 → 제한 시각 → 실패 횟수=0`을 각각 저장했다.
중단 시 실패 횟수 3이 저장된 회차에 이미 반영되었는지 구별할 수 없으므로, 이전 시에는
저장된 회차를 유지하고 범위를 벗어난 실패 횟수는 0으로 정규화한다. 회차가 없으면 1회차의
대기를 적용한다. 불완전한 상태는 해당 회차의 대기를 다시 적용하되 더 늦은 기존 시각은 유지한다.
이 정책은 모호한 중간 상태에서 한 회차를 덜 셀 수 있지만, 중복 집계로 지갑 삭제를 앞당기지 않는다.
최대 회차 이상 또는 회차가 남아 있는 상태의 제한 시각 `-1`은 영구 잠금으로 보존한다.
단, 회차가 없거나 0인데 `-1`만 남은 경우는 이전 버전의 잠금 해제 흔적일 수 있으므로
1회차 대기 후 PIN 인증을 요구한다. 이 상태만으로 영구 잠금과 지갑 자동 삭제를 복원하지 않는다.
이 예외는 레거시 이전에만 적용하며, 이미 저장된 새 보안 제한 레코드에는 적용하지 않는다.

잘못된 PIN이나 생체인증 성공은 verifier를 이전하지 않는다. 새 레코드가 존재하면 그것만 사용하며,
파싱·버전·알고리즘·비용·바이트 길이 오류 시 SHA-256으로 우회하지 않는다.

새 레코드 저장 이전에 중단되면 SHA-256으로, 저장 이후에 중단되면 같은 PIN으로 새 verifier를
검증하여 복구한다. 읽기 확인 실패 시에도 SHA-256은 삭제하지 않는다. 삭제 실패 시에도 새 레코드는
권위 있는 기록으로 남고 다음 PIN 인증에서 삭제를 재시도한다. 쓰기 결과를 확인할 수 없는 경우
현재 실행에서는 인증을 차단하고 재실행 후 실제 저장 상태를 다시 읽는다.
PIN 변경 쓰기가 중단된 경우에도 재실행 시 실제 저장된 verifier와 PIN 유형을 사용한다.

새 형식을 지원하지 않는 이전 앱 버전으로의 다운그레이드는 지원하지 않는다.

## 제한 정책

- 앱 시작 PIN 인증에서만 잘못된 PIN을 실패로 집계한다. PIN 변경 전 확인·동일 PIN 검사 등
  다른 진입점은 기존처럼 실패를 집계하지 않는다.
- 회차당 3회, 최대 8회차. 대기 시간은 1/5/15/30/60/180/480분, 8회차는 영구 잠금이다.
  기존 상수(8회차 600분 포함)는 그대로이며 영구 잠금 분기가 우선한다.
- 디버그 빌드는 기존처럼 임시 대기 7초를 사용한다. 저장된 절대 시각을 재사용하여
  앱 재실행·화면 재진입 시 대기를 새로 시작하거나 초기화하지 않는다.
- 성공한 PIN과 기존의 생체인증 성공 처리 경로는 제한을 초기화한다.
  초기화 저장이 실패하면 인증 성공 콜백을 실행하지 않는다.
- 영구 잠금 시 기존 지갑/인증 초기화 흐름을 실행하고 영구 잠금은 유지한다.
  지갑 정리 중에는 인증 보안 레코드를 보존하고 AuthProvider가 인증 초기화를 완료한다.
  최종 실패 저장 직후 종료되었다면 다음 PIN 화면에서 지갑 초기화를 이어서 수행한다.
  기존 재시작 버튼으로 영구 잠금을 해제한다.
- 월렛의 KDF 실행 전 시도 예약 정책은 적용하지 않는다. 기존 볼트처럼 잘못된 PIN 판정 후
  실패를 기록하며, 기록이 저장·확인되기 전에는 잘못된 PIN 결과도 반환하지 않는다.
- 하나의 공유 서비스에서 검증·설정·초기화·상태 변경을 배타적으로 실행한다.
  실행 중 추가 요청은 고정 인증 오류로 거절한다.
- 보안 레코드 읽기·쓰기·확인이 실패하면 인증을 허용하거나 제한을 임의로 초기화하지 않는다.
  새 verifier가 있는데 제한 레코드가 없어진 경우에도 SharedPreferences 초기값으로 복구하지 않는다.

## 저장 완료와 민감 정보

Android `flutter_secure_storage` 9.x는 `apply()`를 사용한다. 별도 백그라운드 MethodChannel에서
`FlutterSecureKeyStorage`와 볼트 설정의 `SecureStorage_v2`에 빈 `commit()`을 수행한 후
읽어서 값을 확인한다. 채널은 인증 값 없이 `flush`만 전달한다. 플러그인 버전/파일명 변경 시 함께 검토한다.

인증 저장은 오류를 null로 바꾸거나 원본 예외를 로그로 출력하는 일반 저장소 read/write 경로를
사용하지 않는다. 인증 경계에서 오류를 고정 메시지로 바꾸며, PIN·salt·verifier·레코드를
로그·분석·오류 메시지에 넣지 않는다. 소유한 PIN·salt·KDF 결과 바이트는 finally에서 지운다.
Dart의 불변 String 및 런타임 내부 사본까지 완전히 제거하는 보장은 하지 않는다.

최초 설치의 기존 Keychain 정리는 splash와 인증 초기화가 동일한 Future를 공유하여 새 인증 기록을
뒤늦게 삭제하지 않도록 한다. 인증 초기화는 정리 완료를 기다린다.

## 검증

테스트 전용 PIN/메모리 저장소와 모의 OS 생체인증으로 검증한다.

```sh
/Users/pio/fvm/versions/3.29.1/bin/flutter test test/services/security --reporter expanded
```

신규/문자 PIN 설정·변경, 무작위 salt, SHA-256 이전, 잘못된 PIN/생체인증 시 이전 방지,
레코드 손상·KDF 비용 변조, 저장 전후 중단·읽기 확인·삭제 실패, SharedPreferences 실제 이전,
재시작과 절대 시각 유지, 동시 인증 요청, 기존 회차/대기/영구 잠금, 인증 초기화 저장 실패,
지갑 삭제 중 인증 상태 보존, 메타데이터 복구, 민감 오류 제거, 버퍼 정리,
실제 Argon2id isolate와 RFC 9106 알고리즘 벡터를 포함한다.

실제 Android/iOS 기기의 강제 종료·저장 장치 오류 및 저사양 기기 성능은 이 단위 테스트의 검증 범위 밖이다.

## 변경 파일

| 역할 | 파일 |
| --- | --- |
| verifier·제한 저장·이전·동시 실행 제어 | `lib/services/security/pin_auth_service.dart` |
| Argon2id isolate | `lib/services/security/pin_kdf.dart` |
| 기존 인증 API 연결 | `lib/providers/auth_provider.dart` |
| PIN 입력·설정·저장 오류 처리 | `lib/screens/common/pin_check_screen.dart`, `lib/screens/settings/pin_setting_screen.dart` |
| 시작 상태 복구·최초 설치 정리 직렬화 | `lib/app_shell.dart`, `lib/providers/view_model/splash_view_model.dart`, `lib/services/security/first_launch_secure_storage_cleanup.dart` |
| 지갑 초기화 중 인증 상태 보존·iOS 검사 | `lib/repository/wallet_storage_cleaner.dart`, `lib/services/secure_zone/secure_zone_availability_checker.dart` |
| Android 디스크 저장 확인 | `android/app/src/main/kotlin/onl/coconut/vault/MainActivity.kt`, `PinAuthStorageHandler.kt` |
| 의존성 | `pubspec.yaml` (`cryptography: 2.7.0`; 기존 정책에 따라 lockfile은 Git 제외) |
| 테스트 | `test/services/security/pin_auth_service_test.dart`, `test/services/security/wallet_cleanup_auth_state_test.dart` |
| 설명 | `docs/security/pin_authentication.md` |

### 손상된 제한 레코드가 있는 전체 초기화

전체 초기화 usecase는 지갑 및 관련 설정 정리가 끝난 뒤에만 `afterWalletDeletion` 경로를 사용한다.
이 경로는 손상된 이전 제한/verifier를 파싱하지 않고 새 제한 레코드와 명시적인 PIN 해제 레코드를
저장·읽기 확인한다. 영구 잠금 유지가 요청되면 새 제한 레코드에도 영구 잠금을 기록한다.
일반 인증·PIN 해제·모드 변경은 기존의 엄격한 검증 경로를 유지한다.

저장 실패로 상태가 불확실해져도 일반 인증은 차단하고, 명시적인 전체 초기화 재시도만 허용한다.
새 레코드 확인이 완료되어야 AuthProvider가 초기화 완료 상태를 반영한다.
회귀 테스트에는 손상된 두 레코드, 실패한 시작 복구, 쓰기·읽기 확인 실패 및 재시도,
영구 잠금 유지, 동시 실행 차단, 지갑 삭제 이후에만 복구 경로를 호출하는 순서를 포함한다.
