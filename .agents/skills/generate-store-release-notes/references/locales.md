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

## Output patterns

For `<flavor>` equal to `mainnet` or `regtest`:

```text
fastlane/store_metadata/generated/ios/<flavor>/<app-store-locale>/release_notes.txt
fastlane/store_metadata/generated/android/<flavor>/<play-store-locale>/changelogs/<next-version-code>.txt
```

The next Android version code is the current `pubspec.yaml` value for `app_versions.aos_<flavor>` plus one, matching the existing Fastlane lane behavior.
