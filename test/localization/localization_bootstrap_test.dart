import 'package:coconut_vault/app_bootstrap.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bootstrap awaits deferred Thai translations and uses only other for Thai quantities', () async {
    await setupPluralResolvers();
    final translations = AppLocale.th.translations;
    expect(translations.$meta.locale, AppLocale.th);
    final resolver = translations.$meta.cardinalResolver;
    expect(resolver, isNotNull);
    for (final count in [0, 1, 2, 5, 1.5]) {
      expect(resolver!(count, zero: 'zero', one: 'one', two: 'two', few: 'few', many: 'many', other: 'other'), 'other');
    }
    expect(resolver!(1), '');
    await LocaleSettings.setLocale(AppLocale.th);
    expect(t.confirm, matches(RegExp(r'[\u0E00-\u0E7F]')));
    expect(AppLocale.ko.translations.$meta.cardinalResolver!(1, one: 'one', other: 'other'), 'one');
    expect(AppLocale.en.translations.$meta.cardinalResolver!(2, one: 'one', other: 'other'), 'other');
  });
}
