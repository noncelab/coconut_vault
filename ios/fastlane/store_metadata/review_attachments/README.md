# App Store Review Attachments

Place exactly one review-attachment file in each flavor subdirectory before running the production fastlane lanes:

- `mainnet/` — attachment for the MAINNET App Store submission
- `regtest/` — attachment for the REGTEST App Store submission

Only one file per directory is allowed. The file path is passed to `upload_to_app_store` as `app_review_attachment_file`.
