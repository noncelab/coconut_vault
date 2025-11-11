# Secure Storage Repository

## iOS
```dart
static const IOSOptions iosOptions = IOSOptions(accessibility: KeychainAccessibility.passcode, synchronizable: false);
```
기기 패스코드 제거 시: 해당 접근성 수준으로 저장된 모든 Keychain 항목이 자동으로 삭제됨
기기 패스코드 재설정 시: 이전 데이터는 복구되지 않으며, 새로 저장해야 합니다.
기기 패스코드 변경 시: 영향 없음

## AOS
```dart
static const AndroidOptions androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
    sharedPreferencesName: 'SecureStorage_v2',
    preferencesKeyPrefix: 'v2_');
```
기기 패스코드 제거 시: 영향 없음
기기 패스코드 재설정 시: 영향 없음
기기 패스코드 변경 시: 영향 없음
