#!/usr/bin/env bash
# lite 빌드의 트리쉐이킹 결과를 검증합니다.
# liteMainnet release APK를 --analyze-size로 빌드한 뒤, 생성된 코드 분석 JSON에서
# lite에 포함되면 안 되는 파일이 있는지 확인합니다.
#
# 사용법: ./tool/verify_lite_treeshake.sh  (또는 make verify-lite-treeshake)
set -euo pipefail
cd "$(dirname "$0")/.."

ANALYSIS_DIR="$HOME/.flutter-devtools"

# lite 빌드에 포함되면 안 되는 파일 목록 (현재 트리쉐이킹 결과 기준).
# 의도적으로 다시 포함해야 하는 변경이 생기면 이 목록을 갱신하세요.
FORBIDDEN=(
  "screens/common/pin_check_screen"
  "screens/common/pin_input_screen"
  "screens/settings/pin_setting_screen"
  "screens/common/vault_mode_selection_screen"
  "screens/wallet_info/single_sig_menu/passphrase_verification_screen"
  "screens/wallet_info/single_sig_menu/passphrase_check_screen"
  "screens/wallet_info/passphrase_check_bottom_sheet"
  "screens/vault_creation/taproot/"
  "screens/wallet_info/taproot_wallet_info_screen"
  "screens/wallet_info/taproot_sync_qr_screen"
  "screens/airgap/taproot_sign_screen"
  "screens/airgap/psbt_qr_code_screen"
  "screens/common/ios_bluetooth_auth_notification_screen"
  "screens/common/menu_grid"
  "screens/common/date_selector_bottom_sheet"
)

echo "== lite release 빌드 (--analyze-size) =="
ANDROID_USE_DEBUG_SIGNING_FOR_RELEASE_RUN=true \
  fvm flutter build apk --flavor liteMainnet --release \
  -t lib/main_lite.dart --analyze-size --target-platform android-arm64

LATEST=$(ls -t "$ANALYSIS_DIR"/apk-code-size-analysis_*.json | head -1)
echo "== 분석 파일: $LATEST =="

fail=0
for pattern in "${FORBIDDEN[@]}"; do
  if grep -q "$pattern" "$LATEST"; then
    echo "❌ lite 빌드에 포함되면 안 되는 코드가 있습니다: $pattern"
    fail=1
  fi
done

if [ "$fail" -ne 0 ]; then
  echo "트리쉐이킹 검증 실패"
  exit 1
fi
echo "✅ 트리쉐이킹 검증 통과"
