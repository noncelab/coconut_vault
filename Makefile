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

# 로컬 테스트용: 연결된 기기에 lite mainnet debug 앱 설치 및 실행
aos-lite-mainnet-run:
	fvm flutter run --flavor liteMainnet -t lib/main_lite.dart

ios-lite-regtest:
	fvm flutter build ios --flavor liteRegtest --release -t lib/main_lite.dart

aos-lite-regtest:
	fvm flutter build appbundle --flavor liteRegtest --release -t lib/main_lite.dart

# 로컬 테스트용: 연결된 기기에 lite regtest debug 앱 설치 및 실행
aos-lite-regtest-run:
	fvm flutter run --flavor liteRegtest -t lib/main_lite.dart

aos-release:
	./android/scripts/build_android_release.sh

# lite 빌드 트리쉐이킹 검증 (lite에 포함되면 안 되는 코드가 없는지 확인)
verify-lite-treeshake:
	./tool/verify_lite_treeshake.sh

# fastlane
pre-deploy: 
	bundle exec fastlane pre_deploy

ifeq ($(SKIP_PREP),true)
PREP_COMMAND := true
else
PREP_COMMAND := $(MAKE) pre-deploy
endif


FASTLANE_USER :=
-include ios/fastlane/.env
export FASTLANE_USER

REQUIRE_APPLE_ID = if [ -z "$${FASTLANE_USER:-}" ]; then echo "FASTLANE_USER must be set in ios/fastlane/.env." >&2; exit 1; fi;

fastlane-mainnet:
	@$(REQUIRE_APPLE_ID) \
	$(PREP_COMMAND) && \
	cd android && caffeinate -dimsu bundle exec fastlane release_android_mainnet && cd .. && cd ios && caffeinate -dimsu bundle exec fastlane release_ios_mainnet skip_prep:true

fastlane-regtest:
	@$(REQUIRE_APPLE_ID) \
	$(PREP_COMMAND) && \
	cd android && caffeinate -dimsu bundle exec fastlane release_android_regtest && cd .. && cd ios && caffeinate -dimsu bundle exec fastlane release_ios_regtest skip_prep:true

fastlane-lite-mainnet:
	@$(REQUIRE_APPLE_ID) \
	$(PREP_COMMAND) && \
	cd android && caffeinate -dimsu bundle exec fastlane release_android_lite_mainnet && cd .. && cd ios && caffeinate -dimsu bundle exec fastlane release_ios_lite_mainnet skip_prep:true

# Production draft/App Store preparation (manual review submission remains required)

fastlane-production-mainnet:
	@$(REQUIRE_APPLE_ID) \
	$(PREP_COMMAND) && \
	(cd android/fastlane_production && caffeinate -dimsu bundle exec fastlane prepare_android_mainnet_production) && \
	(cd ios/fastlane_production && caffeinate -dimsu bundle exec fastlane prepare_ios_mainnet_production skip_prep:true)

fastlane-production-regtest:
	@$(REQUIRE_APPLE_ID) \
	$(PREP_COMMAND) && \
	(cd android/fastlane_production && caffeinate -dimsu bundle exec fastlane prepare_android_regtest_production) && \
	(cd ios/fastlane_production && caffeinate -dimsu bundle exec fastlane prepare_ios_regtest_production skip_prep:true)

fastlane-production-lite-mainnet:
	@$(REQUIRE_APPLE_ID) \
	$(PREP_COMMAND) && \
	(cd android/fastlane_production && caffeinate -dimsu bundle exec fastlane prepare_android_lite_mainnet_production) && \
	(cd ios/fastlane_production && caffeinate -dimsu bundle exec fastlane prepare_ios_lite_mainnet_production skip_prep:true)

include Makefile.test
