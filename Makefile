format:
	find . -name "*.dart" -not -path "./coconut_lib/*" -not -path "./.dart_tool/*" -not -path "./build/*" | xargs fvm dart format --line-length 120

ready:
	fvm dart pub run build_runner clean && fvm dart pub run build_runner build --delete-conflicting-outputs && fvm dart pub run slang

slang:
	fvm dart pub run slang

ios-mainnet:
	fvm flutter build ios --flavor mainnet --release

aos-mainnet:
	fvm flutter build appbundle --flavor mainnet --release

ios-regtest:
	fvm flutter build ios --flavor regtest --release

aos-regtest:
	fvm flutter build appbundle --flavor regtest --release

# fastlane
pre-deploy: 
	fastlane pre_deploy

fastlane-mainnet:
	cd android && caffeinate -dimsu fastlane release_android_mainnet && cd .. && cd ios && caffeinate -dimsu fastlane release_ios_mainnet skip_prep:true

fastlane-regtest:
	cd android && caffeinate -dimsu fastlane release_android_regtest && cd .. && cd ios && caffeinate -dimsu fastlane release_ios_regtest skip_prep:true

# Production draft/App Store preparation (manual review submission remains required)
ifeq ($(SKIP_PREP),true)
PRODUCTION_PREP_COMMAND := true
else
PRODUCTION_PREP_COMMAND := $(MAKE) pre-deploy
endif

fastlane-production-mainnet:
	@FASTLANE_USER="$${FASTLANE_USER:-}"; \
	if [ -z "$$FASTLANE_USER" ]; then printf "Apple ID Username: "; IFS= read -r FASTLANE_USER; fi; \
	if [ -z "$$FASTLANE_USER" ]; then echo "Apple ID username cannot be empty." >&2; exit 1; fi; \
	export FASTLANE_USER; \
	$(PRODUCTION_PREP_COMMAND) && \
	(cd android/fastlane_production && caffeinate -dimsu bundle exec fastlane prepare_android_mainnet_production) && \
	(cd ios/fastlane_production && caffeinate -dimsu bundle exec fastlane prepare_ios_mainnet_production skip_prep:true)

fastlane-production-regtest:
	@FASTLANE_USER="$${FASTLANE_USER:-}"; \
	if [ -z "$$FASTLANE_USER" ]; then printf "Apple ID Username: "; IFS= read -r FASTLANE_USER; fi; \
	if [ -z "$$FASTLANE_USER" ]; then echo "Apple ID username cannot be empty." >&2; exit 1; fi; \
	export FASTLANE_USER; \
	$(PRODUCTION_PREP_COMMAND) && \
	(cd android/fastlane_production && caffeinate -dimsu bundle exec fastlane prepare_android_regtest_production) && \
	(cd ios/fastlane_production && caffeinate -dimsu bundle exec fastlane prepare_ios_regtest_production skip_prep:true)

include Makefile.test
