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