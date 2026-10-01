# Store locale mapping

## iOS App Store

Use these localizations for iOS:

| Language | Source key | App Store locale |
|---|---|---|
| Korean | `ko` | `ko` |
| English (US) | `en` | `en-US` |
| Japanese | `ja` | `ja` |

## Android Play Store

Use these localizations for Android:

| Language | Source key | Play Store locale |
|---|---|---|
| Korean | `ko` | `ko-KR` |
| English (US) | `en` | `en-US` |
| Japanese | `ja` | `ja-JP` |

## Per-flavor locales

Coconut Vault Lite has no Japanese store listing on the App Store or Play Store, so `liteMainnet` ships only Korean and English. `mainnet` and `regtest` ship all three locales.

| Flavor | iOS locales | Android locales |
|---|---|---|
| `mainnet` | `ko`, `en-US`, `ja` | `ko-KR`, `en-US`, `ja-JP` |
| `regtest` | `ko`, `en-US`, `ja` | `ko-KR`, `en-US`, `ja-JP` |
| `liteMainnet` | `ko`, `en-US` | `ko-KR`, `en-US` |

## Output patterns

For `<flavor>` equal to `mainnet`, `regtest`, or `liteMainnet`:

```text
fastlane/store_metadata/generated/ios/<flavor>/<app-store-locale>/release_notes.txt
fastlane/store_metadata/generated/android/<flavor>/<play-store-locale>/changelogs/<next-version-code>.txt
```

The next Android version code is the current `pubspec.yaml` value for `app_versions.aos_<android-version-key>` plus one, matching the existing Fastlane lane behavior. The Android version key is `fullMainnet` for `mainnet`, `fullRegtest` for `regtest`, and `liteMainnet` for `liteMainnet`.
