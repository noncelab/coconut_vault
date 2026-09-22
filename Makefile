format:
	find . -name "*.dart" -not -path "./coconut_lib/*" -not -path "./.dart_tool/*" -not -path "./build/*" | xargs fvm dart format --line-length 120

ready:
	fvm dart pub run build_runner clean && fvm dart pub run build_runner build --delete-conflicting-outputs && fvm dart pub run slang

slang:
	fvm dart pub run slang

ios-full-mainnet:
	fvm flutter build ios --flavor fullMainnet --release

aos-full-mainnet:
	fvm flutter build appbundle --flavor fullMainnet --release

ios-full-regtest:
	fvm flutter build ios --flavor fullRegtest --release

aos-full-regtest:
	fvm flutter build appbundle --flavor fullRegtest --release

ios-lite-mainnet:
	fvm flutter build ios --flavor liteMainnet --release -t lib/main_lite.dart

aos-lite-mainnet:
	fvm flutter build appbundle --flavor liteMainnet --release -t lib/main_lite.dart

ios-lite-regtest:
	fvm flutter build ios --flavor liteRegtest --release -t lib/main_lite.dart

aos-lite-regtest:
	fvm flutter build appbundle --flavor liteRegtest --release -t lib/main_lite.dart

# lite 빌드 트리쉐이킹 검증 (lite에 포함되면 안 되는 코드가 없는지 확인)
verify-lite-treeshake:
	./tool/verify_lite_treeshake.sh

# fastlane
pre-deploy: 
	fastlane pre_deploy

# FASTLANE_USER(Apple ID) 미설정 시 프롬프트 후 export (하위 fastlane 프로세스에 전달)
ASK_APPLE_ID = FASTLANE_USER="$${FASTLANE_USER:-}"; \
	if [ -z "$$FASTLANE_USER" ]; then printf "Apple ID Username: "; IFS= read -r FASTLANE_USER; fi; \
	if [ -z "$$FASTLANE_USER" ]; then echo "Apple ID username cannot be empty." >&2; exit 1; fi; \
	export FASTLANE_USER;

fastlane-mainnet:
	@$(ASK_APPLE_ID) \
	cd android && caffeinate -dimsu fastlane release_android_mainnet && cd .. && cd ios && caffeinate -dimsu fastlane release_ios_mainnet skip_prep:true

fastlane-regtest:
	@$(ASK_APPLE_ID) \
	cd android && caffeinate -dimsu fastlane release_android_regtest && cd .. && cd ios && caffeinate -dimsu fastlane release_ios_regtest skip_prep:true

fastlane-lite-mainnet:
	@$(ASK_APPLE_ID) \
	cd android && caffeinate -dimsu fastlane release_android_lite_mainnet && cd .. && cd ios && caffeinate -dimsu fastlane release_ios_lite_mainnet skip_prep:true

# Production draft/App Store preparation (manual review submission remains required)
ifeq ($(SKIP_PREP),true)
PRODUCTION_PREP_COMMAND := true
else
PRODUCTION_PREP_COMMAND := $(MAKE) pre-deploy
endif

fastlane-production-mainnet:
	@$(ASK_APPLE_ID) \
	$(PRODUCTION_PREP_COMMAND) && \
	(cd android/fastlane_production && caffeinate -dimsu bundle exec fastlane prepare_android_mainnet_production) && \
	(cd ios/fastlane_production && caffeinate -dimsu bundle exec fastlane prepare_ios_mainnet_production skip_prep:true)

fastlane-production-regtest:
	@$(ASK_APPLE_ID) \
	$(PRODUCTION_PREP_COMMAND) && \
	(cd android/fastlane_production && caffeinate -dimsu bundle exec fastlane prepare_android_regtest_production) && \
	(cd ios/fastlane_production && caffeinate -dimsu bundle exec fastlane prepare_ios_regtest_production skip_prep:true)

include Makefile.test
