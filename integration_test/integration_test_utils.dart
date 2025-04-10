import 'package:flutter_test/flutter_test.dart';

/// Waits for a widget to appear on the screen with a timeout (100초).
/// Returns true if the widget was found, false if it timed out.
Future<bool> waitForWidget(WidgetTester tester, Finder finder,
    {String? timeoutMessage, int timeoutSeconds = 60}) async {
  bool found = false;
  for (int i = 0; i < timeoutSeconds && !found; i++) {
    await tester.pump(const Duration(seconds: 1));
    found = finder.evaluate().isNotEmpty;
  }
  if (timeoutMessage != null) {
    expect(found, true, reason: timeoutMessage);
  }
  return found;
}
