fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

### pre_deploy

```sh
[bundle exec] fastlane pre_deploy
```

배포 전에 실행하는 공통 함수

### deploy_aos_regtest_internal

```sh
[bundle exec] fastlane deploy_aos_regtest_internal
```

[Android] 코코넛 볼트 학습용 내부테스트 업로드

### deploy_aos_mainnet_internal

```sh
[bundle exec] fastlane deploy_aos_mainnet_internal
```

[Android] 코코넛 볼트 내부테스트 업로드

### deploy_ios_regtest_internal

```sh
[bundle exec] fastlane deploy_ios_regtest_internal
```

[iOS] 코코넛 볼트 학습용 내부테스트 업로드

### deploy_ios_mainnet_internal

```sh
[bundle exec] fastlane deploy_ios_mainnet_internal
```

[iOS] 코코넛 볼트 내부테스트 업로드

### deploy_regtest_internal

```sh
[bundle exec] fastlane deploy_regtest_internal
```

코코넛 볼트 학습용 업로드

### deploy_mainnet_internal

```sh
[bundle exec] fastlane deploy_mainnet_internal
```

코코넛 볼트 빌드버전 업데이트

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
