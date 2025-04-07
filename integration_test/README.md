# Integration Tests

이 폴더는 실제 모바일 기기에서 실행되어야 하는 통합 테스트들을 포함하고 있습니다.

## 테스트 실행 환경

- 실제 모바일 기기가 연결되어 있어야 합니다.
- 기본적으로 디버그 모드로 실행됩니다. (release 모드는 `--release` 플래그 추가)
- Regtest flavor를 사용합니다.

## 테스트 실행 방법

각 테스트 파일은 다음 명령어로 실행할 수 있습니다:

```bash
# 디버그 모드로 실행 (기본)
flutter test integration_test/<test_file>.dart --flavor regtest

# release 모드로 실행
flutter test integration_test/<test_file>.dart --flavor regtest --release
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
              "--flavor=regtest",
            ]
        },
   ]
```
launch.json 파일 수정 후, 해당 테스트 파일을 엽니다. vscode 왼쪽 메뉴에서 Run And Debug 메뉴를 연 후 설정한 configuration을 선택한 후 왼쪽의 재생버튼 모양을 누릅니다.

### 현재 포함된 테스트들

1. `secure_key_generator_test.dart`
   - 암호화 키 생성의 안전성 검증
   - 실제 디바이스의 엔트로피 소스 활용
   - 키의 유니크성과 랜덤성 검증

2. `update_preparation_test.dart`
   - 백업 데이터 암호화/복호화 기능 검증
   - 파일 저장 및 삭제 기능 검증
   - 보안 스토리지 연동 검증

## 주의사항

- 테스트는 실제 디바이스의 저장소와 보안 기능을 사용합니다.
- 각 테스트는 실행 후 자동으로 테스트 데이터를 정리합니다. 설치했던 앱도 삭제합니다.
- 테스트 실패 시 디바이스에 테스트 데이터가 남아있을 수 있으니 수동 정리가 필요할 수 있습니다.
