# Integration Tests

이 폴더는 실제 모바일 기기에서 실행되어야 하는 통합 테스트들을 포함하고 있습니다.

## 테스트 실행 환경

- 실제 모바일 기기가 연결되어 있어야 합니다.
- Regtest flavor를 사용합니다.

## 테스트 실행 방법

각 테스트 파일은 다음 명령어로 실행할 수 있습니다:

```bash
flutter test integration_test/<test_file>.dart --flavor fullRegtest
```

## 디버깅을 하고 싶을 때
### vscode 사용하는 경우
.vscode/launch.json
```
...
   "configuration": [
      ...
      {
            "name": "update_preparation_test Integration Test (Debug)",
            "request": "launch",
            "type": "dart",
            "program": "integration_test/[테스트 파일 이름].dart",
            "toolArgs": [
              "--flavor=fullRegtest",
            ]
        },
   ]
```
launch.json 파일 수정 후, 해당 테스트 파일을 엽니다. vscode 왼쪽 메뉴에서 Run And Debug 메뉴를 연 후 설정한 configuration을 선택한 후 왼쪽의 재생버튼 모양을 누릅니다.
또는 해당 테스트 파일이 열려있고 포커스 된 상태에서 `F5` 키를 눌러 실행합니다.

### Android Studio 사용하는 경우
우측 상단에 main.dart 버튼을 눌러서 Edit Configuration을 누르고 윈도우 좌측 상단에 + 버튼 누릅니다.
Flutter Test를 클릭해주고, Test File 경로를 지정합니다. Additional args에 --flavor fullRegtest 입력하고 OK 버튼을 눌러서 Configuration 파일 추가합니다.
특정 테스트만 진행하고 싶은 경우 IDE 좌측 숫자 부분에 디버그 아이콘 눌러서 Configuration 추가하여 실행합니다. 

### 현재 포함된 테스트들

1. `secure_key_generator_test.dart`
   - 암호화 키 생성의 안전성 검증
   - 실제 디바이스의 엔트로피 소스 활용
   - 키의 유니크성과 랜덤성 검증

2. `update_preparation_test.dart`
   - 데이터 백업전 니모닉 확인 기능 
   - 백업 데이터 암호화/복호화 기능 검증
   - 파일 저장 및 삭제 기능 검증
   - 보안 스토리지 연동 검증

3. `app_lock_test.dart`
   - 비밀번호 생성 확인 기능
   - 앱 잠금해제 기능 검증
   - 앱 잠금해제 화면에서 비밀번호 오입력 시 앱 잠금(App Locked) 기능 검증
   - 앱 잠금해제 여러번 실패시 앱 영구 잠금(PermanantlyLocked) 기능 검증
   - 앱 초기화 기능 검증

4. `app_flow_test.dart`
   - 앱 첫 시작 시 Tutorial 화면으로 진입하는 통합테스트
   - 추가된 지갑이 있을 때 PinCheckScreen -> VaultListScreen으로 진입하는 통합테스트
   - 추가된 지갑이 없을 때 PinCheckScreen을 거치지 않고 바로 VaultListScreen으로 진입하는 통합테스트
   - 복원 파일이 존재하고 앱 업데이트가 완료됐을 때 PinCheckScreen -> VaultListRestorationScreen -> VaultListScreen으로 진입하는 통합테스트
   - 복원 파일이 존재하고 앱 업데이트가 안됐을 때 RestorationInfoScreen -> PinCheckScreen -> VaultListRestorationScreen -> VaultList으로 진입하는 통합테스트

## Android mainnet 싱글시그 생성 테스트

이 테스트들은 Android 우선으로 작성되었으며 에뮬레이터에서도 실행할 수 있습니다. 다음 세 엔트리포인트는 코인 플립, 주사위, 자동 생성, 니모닉 가져오기 및 SeedQR 가져오기 경로를 공유합니다.

> **경고: 아래 테스트는 매 테스트 시작 전에 선택한 mainnet 앱 flavor의 SharedPreferences와 secure storage를 전부 삭제합니다. 기존 mainnet 볼트와 앱 설정이 영구적으로 삭제될 수 있으므로 개인 키나 실제 자금이 연결된 기기에서는 절대로 실행하지 마세요. 테스트 전용 Android 에뮬레이터를 사용하세요.**

안전 저장 모드(fullMainnet):

```bash
fvm flutter test integration_test/single_sig_full_mainnet_safe_storage_test.dart --flavor fullMainnet -d <ANDROID_DEVICE_ID>
```

서명 전용 모드(fullMainnet):

```bash
fvm flutter test integration_test/single_sig_full_mainnet_signing_only_test.dart --flavor fullMainnet -d <ANDROID_DEVICE_ID>
```

liteMainnet(서명 전용 고정):

```bash
fvm flutter test integration_test/single_sig_lite_mainnet_test.dart --flavor liteMainnet -d <ANDROID_DEVICE_ID>
```

특정 비-SeedQR 테스트만 실행하려면 테스트 이름을 지정할 수 있습니다.

```bash
fvm flutter test integration_test/single_sig_full_mainnet_safe_storage_test.dart --flavor fullMainnet -d <ANDROID_DEVICE_ID> \
  --plain-name "imports a mnemonic and creates a wallet"
```

## Android mainnet 멀티시그 생성 테스트

이 테스트들은 Android 우선으로 작성되었으며 에뮬레이터에서도 실행할 수 있습니다. 내부 싱글시그 지갑 2개를 fixture API로 준비한 뒤 production UI를 통해 2-of-2 멀티시그를 생성하는 경로를 검증합니다.

> **경고: 아래 테스트는 매 테스트 시작 전에 선택한 mainnet 앱 flavor의 SharedPreferences와 secure storage를 전부 삭제합니다. 기존 mainnet 볼트와 앱 설정이 영구적으로 삭제될 수 있으므로 개인 키나 실제 자금이 연결된 기기에서는 절대로 실행하지 마세요. 테스트 전용 Android 에뮬레이터를 사용하세요.**

안전 저장 모드(fullMainnet):

```bash
fvm flutter test integration_test/multisig_full_mainnet_safe_storage_test.dart --flavor fullMainnet -d <ANDROID_DEVICE_ID>
```

서명 전용 모드(fullMainnet):

```bash
fvm flutter test integration_test/multisig_full_mainnet_signing_only_test.dart --flavor fullMainnet -d <ANDROID_DEVICE_ID>
```

liteMainnet(서명 전용 고정):

```bash
fvm flutter test integration_test/multisig_lite_mainnet_test.dart --flavor liteMainnet -d <ANDROID_DEVICE_ID>
```

특정 테스트만 실행하려면 테스트 이름을 지정할 수 있습니다.

```bash
fvm flutter test integration_test/multisig_full_mainnet_safe_storage_test.dart --flavor fullMainnet -d <ANDROID_DEVICE_ID> \
  --plain-name "creates a 2-of-2 multisig from two internal single-sig wallets"
```

### SeedQR 반자동 절차

SeedQR 테스트에는 카메라 입력만 수동으로 필요합니다.

1. 테스트 전용 Android 에뮬레이터를 실행하고 카메라 권한을 허용합니다.
2. 테스트가 SeedQR 스캐너 화면에서 대기하면 CLI에 출력되는 `000000000000000000000000000000000000000000000003` 문자열로 만든 Standard SeedQR을 카메라에 보여 줍니다. 이는 `abandon` 11개와 `about`으로 구성된 공개 테스트 니모닉입니다.
3. QR을 인식하면 테스트가 확인 화면의 경고를 닫고 다음 생성 단계까지 자동 진행합니다.
4. 스캔 대기 시간은 5분입니다. 제한 시간 안에 QR을 제시하지 않으면 테스트가 실패합니다.
5. 테스트 니모닉에 자금을 보내지 말고, 실제 복구 문구를 카메라에 제시하지 마세요.

## 주의사항

- 기존 regtest 테스트 일부는 실제 디바이스의 저장소와 보안 기능을 사용합니다.
- 각 테스트는 실행 후 자동으로 테스트 데이터를 정리합니다. 설치했던 앱도 삭제합니다.
- 테스트 실패 시 디바이스에 테스트 데이터가 남아있을 수 있으니 수동 정리가 필요할 수 있습니다.
- mainnet 싱글시그 생성 테스트는 종료 시가 아니라 **시작 시 앱 데이터를 삭제**하므로 테스트 실패 여부와 관계없이 기존 데이터 복구가 불가능할 수 있습니다.
