# Contributing / 기여하기

## 가이드라인 / Guidelines

- PRs must be based on the `develop` branch.</br>
  PR은 `develop` 브랜치에서 시작해야 합니다.

- Do not add new packages. Modifications that remove existing packages are welcome.</br>
  새로운 패키지를 추가하지 마세요. 기존 패키지를 제거할 수 있는 수정은 환영입니다.

- Please set up Git hooks (`fvm dart format`):</br>
  Git hooks를 설정해주세요. 커밋 전에 FVM으로 Dart 코드를 포맷팅합니다.

```bash
# 프로젝트 디렉토리 이동 / Change to project directory
cd /path/your/coconut_vault

# Git hook 로컬 경로 설정 / Set local Git hooks path
git config --local core.hooksPath .git/hooks

# pre-commit.sample 제거 / Remove pre-commit.sample
rm -f .git/hooks/pre-commit.sample

# pre-commit 생성 및 script 추가 / Create pre-commit and add script
vi .git/hooks/pre-commit

# 실행 권한 부여 / Make executable
chmod +x .git/hooks/pre-commit
```

**pre-commit script**

```bash
#!/bin/bash
export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.pub-cache/bin:$HOME/fvm/default/bin:$PATH"

if ! command -v fvm >/dev/null 2>&1; then
  echo "fvm을 찾을 수 없습니다. FVM을 설치하거나 PATH를 확인해 주세요."
  exit 1
fi

find . -name "*.dart" -not -path "./coconut_lib/*" -not -path "./.dart_tool/*" -not -path "./build/*" -print0 | xargs -0 fvm dart format --line-length 120 --set-exit-if-changed
if [[ $? -ne 0 ]]; then
  echo "코드 포맷팅에 문제가 있습니다. 다시 커밋해 주세요."
  exit 1
fi
exit 0
```

GitHub Desktop을 사용하는 경우에도 위와 같이 FVM 경로를 `PATH`에 추가해야 합니다. GUI 앱은 터미널과 다른 `PATH`로 Git hook을 실행할 수 있어 `xargs: fvm: No such file or directory` 오류가 발생할 수 있습니다.

---

## Commits / 커밋

All commit messages and branch names must use one of the following prefixes.
</br>모든 커밋과 브랜치명은 다음의 접두사 중 하나를 사용해야 합니다.

| Prefix | Description | 설명 |
|--------|-------------|------|
| `feat` | New feature | 기능 추가 |
| `fix` | Bug fix | 버그 수정 |
| `style` | Code formatting (no logic changes) | 코드 포맷팅, 로직 변경 없음 |
| `refactor` | Code refactoring | 코드 리팩터링 |
| `chore` | Build config, package manager | 빌드 관련 수정, 패키지 매니저 |
| `docs` | Documentation | 문서 수정 |
| `test` | Tests | 테스트 코드 작성 |

**Commit format / 커밋 형식:** `feat(new): new feature`

**Branch format / 브랜치 형식:** `feat/new`

---

## Releases / 릴리스

- **Release branches** are managed per major.minor version (e.g. `release-1.0`). For example, if version `1.0` has been patched twice, the `release-1.0` branch should contain versions `1.0.0` through `1.0.2`.
</br> release 브랜치는 `1.0`처럼 major.minor 버전별로 관리합니다. 예를 들어 `1.0` 버전이 2번 패치되었다면, release-1.0 브랜치에 `1.0.0`~`1.0.2` 버전이 기록되어야 합니다.

- **Never delete release branches.**</br>
  모든 release 브랜치는 삭제하지 않습니다.

- When the minor version is bumped (e.g. `1.0.2` → `1.1.0`), create a new `release-1.1` branch and merge `develop` into it.</br> 
minor 버전이 올라가면 (예: `1.0.2` → `1.1.0`), 새로운 `release-1.1` 브랜치를 만들고 `develop` 브랜치를 머지합니다.

- If changes are needed during the release process, branch off from `develop`, make the changes, and merge into the release branch.</br>
release 과정에서 변경 사항이 생기면, `develop`에서 브랜치를 따서 작업 후 release 브랜치에 머지합니다.

- After a `release-x.y` deployment is complete, add GitHub tags. For example, for version `1.0.0`: tag the final iOS deploy commit as `1.0.0-ios` and the final Android deploy commit as `1.0.0-aos`.</br>
release-x.y 배포가 완료되면 GitHub TAG를 추가합니다. 예를 들어 `1.0.0` 버전이라면 iOS 배포 커밋에 `1.0.0-ios`, Android 배포 커밋에 `1.0.0-aos` 태그를 추가합니다.

---

## Localization (i18n) / 문구 수정

When modifying text strings, edit `**.i18n.yaml` and run the following command to regenerate the localization files:</br>
문구 변경 시 `**.i18n.yaml` 파일을 수정한 후 아래 명령어를 실행하면 `lib/localization/`의 `strings_**.g.dart`, `strings.g.dart` 파일이 업데이트됩니다.

```bash
flutter pub run slang
```
