#!/usr/bin/env bash

set -euo pipefail

cleanup() {
  unset ANDROID_SIGNING_STORE_PASSWORD
  unset ANDROID_SIGNING_KEY_PASSWORD
  unset SIGNING_PASSWORD
}
trap cleanup EXIT

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ANDROID_DIR="$PROJECT_ROOT/android"
APP_DIR="$ANDROID_DIR/app"

read_property() {
  local key="$1"
  local file="$2"
  sed -n "s/^[[:space:]]*$key[[:space:]]*=[[:space:]]*//p" "$file" | tail -n 1
}

resolve_store_file() {
  local store_file="$1"

  if [[ "$store_file" = /* ]]; then
    printf '%s\n' "$store_file"
  else
    printf '%s\n' "$APP_DIR/$store_file"
  fi
}

if ! command -v keytool >/dev/null 2>&1; then
  echo "keytool was not found. Install a JDK and try again." >&2
  exit 1
fi

validate_signing_password() {
  local key_properties_file="$ANDROID_DIR/key_${KEYSTORE_FLAVOR}.properties"

  if [[ ! -f "$key_properties_file" ]]; then
    echo "Keystore properties file not found: $key_properties_file" >&2
    exit 1
  fi

  local key_alias
  local store_file
  key_alias="$(read_property "keyAlias" "$key_properties_file")"
  store_file="$(read_property "storeFile" "$key_properties_file")"

  if [[ -z "$key_alias" || -z "$store_file" ]]; then
    echo "keyAlias and storeFile are required in $key_properties_file." >&2
    exit 1
  fi

  local resolved_store_file
  resolved_store_file="$(resolve_store_file "$store_file")"

  if [[ ! -f "$resolved_store_file" ]]; then
    echo "Keystore file not found: $resolved_store_file" >&2
    exit 1
  fi

  local keystore_info
  if ! keystore_info="$(keytool -J-Duser.language=en -J-Duser.country=US \
    -list -keystore "$resolved_store_file" -storepass "$SIGNING_PASSWORD" 2>&1)"; then
    echo "Invalid keystore password for $KEYSTORE_FLAVOR." >&2
    exit 1
  fi

  if ! grep -qi "^Keystore type: PKCS12" <<< "$keystore_info"; then
    echo "The $KEYSTORE_FLAVOR keystore must use the PKCS12 format." >&2
    exit 1
  fi

  if ! keytool -J-Duser.language=en -J-Duser.country=US \
    -list -keystore "$resolved_store_file" -alias "$key_alias" -storepass "$SIGNING_PASSWORD" >/dev/null 2>&1; then
    echo "Key alias $key_alias was not found for $KEYSTORE_FLAVOR." >&2
    exit 1
  fi

  echo "Keystore/key password verified for $KEYSTORE_FLAVOR."
}

echo "Select Android flavor to build:"
echo "  1) fullMainnet"
echo "  2) fullRegtest"
echo "  3) liteMainnet"
echo "  4) liteRegtest"

while true; do
  read -r -p "Flavor [1/fullMainnet, 2/fullRegtest, 3/liteMainnet, 4/liteRegtest]: " FLAVOR_INPUT

  case "$FLAVOR_INPUT" in
    1 | fullMainnet)
      FLAVOR="fullMainnet"
      break
      ;;
    2 | fullRegtest)
      FLAVOR="fullRegtest"
      break
      ;;
    3 | liteMainnet)
      FLAVOR="liteMainnet"
      break
      ;;
    4 | liteRegtest)
      FLAVOR="liteRegtest"
      break
      ;;
    *)
      echo "Please enter 1, 2, 3, 4, or the flavor name."
      ;;
  esac
done

# fullMainnet/liteMainnet -> mainnet, fullRegtest/liteRegtest -> regtest
KEYSTORE_FLAVOR="${FLAVOR#full}"
KEYSTORE_FLAVOR="${KEYSTORE_FLAVOR#lite}"
KEYSTORE_FLAVOR="$(echo "$KEYSTORE_FLAVOR" | tr '[:upper:]' '[:lower:]')"

read -r -s -p "Keystore/key password: " SIGNING_PASSWORD
echo

if [[ -z "$SIGNING_PASSWORD" ]]; then
  echo "Password cannot be empty." >&2
  exit 1
fi

validate_signing_password

export ANDROID_SIGNING_STORE_PASSWORD="$SIGNING_PASSWORD"
export ANDROID_SIGNING_KEY_PASSWORD="$SIGNING_PASSWORD"

BUILD_CMD=(
  fvm flutter build appbundle
  --flavor "$FLAVOR"
  --release
)

if [[ "$FLAVOR" == lite* ]]; then
  BUILD_CMD+=(-t lib/main_lite.dart)
fi

cd "$PROJECT_ROOT"
"${BUILD_CMD[@]}"
