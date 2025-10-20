format:
	fvm dart format . --line-length 120

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