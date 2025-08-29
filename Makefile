format:
	dart format . --line-length 100

ready:
	dart pub run build_runner clean && dart pub run build_runner build --delete-conflicting-outputs && dart pub run slang

slang:
	dart pub run slang