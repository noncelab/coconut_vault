# Store Release Note Sources

Write the Korean source release notes in each flavor directory as `release_notes.ko.md`.

- `mainnet/release_notes.ko.md`
- `regtest/release_notes.ko.md`

The `generate-store-release-notes` skill reads these files and generates localized
metadata under `fastlane/store_metadata/generated/`.
