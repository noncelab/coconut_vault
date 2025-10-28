# secure_zone_repository

AOS: strong_box_keystore.dart
iOS: secure_enclave_keystore.dart
각각 다른 파일에 기능이 구현되어 있습니다.

## AOS와 iOS의 큰 차이
AOS: encrypt, decrypt시 기기 인증이 요청되며, 5분 안에 여러번 요청 시 처음 1번만 요청됩니다. 5분이 경과한 후에 다시 요청되도록 설정했습니다. (StrongboxKeystorePlugin.kt 참고)
iOS: decrypt, delete 할 때 기기 인증이 항상 요청된다.