# secure_zone_repository

AOS: strong_box_keystore.dart
iOS: secure_enclave_keystore.dart
각각 다른 파일에 기능이 구현되어 있습니다.

## AOS와 iOS의 큰 차이
AOS: encrypt, decrypt시 기기 인증이 요청되며, 5분 안에 여러번 요청 시 처음 1번만 요청됩니다. 5분이 경과한 후에 다시 요청되도록 설정했습니다. (HardwareBackedKeystorePlugin.kt 참고)
iOS: decrypt할 때 기기 인증이 항상 요청된다.

## 기기 패스코드 제거 시
AOS, iOS: 이전 데이터 무효화 (제거 후 같은 걸로 설정해도 이미 무효화된 상태)

## 기기 패스코드 변경 시
AOS, iOS: 기존 데이터 영향 없음

## AOS 보안 폴더 내에서 '생체 인증'으로 secure_zone 접근 권한 갱신 안되는 문제
삼성에서 보안 폴더 기능을 제공하기 시작한 건 Android 13 (API level 33) 이상부터 입니다.
삼성 휴대폰 One UI 8 (Android 16 / API level 36) 미만 기기에서, 보안 폴더 내에서는 '생체 인증'으로 KeyStore 접근을 위한 인증이 안되는 문제가 있습니다. 따라서 안드로이드에서 2차 AUTH_NEEDED 예외 발생 시 'PIN/Pattern/Password'로 인증을 강제하는 로직을 추가했습니다.
