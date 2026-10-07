import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/router/popup_route_tracker.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp, Scaffold;

/// Root-overlay layers (the diff's "+" pill, avatars, search bar) stand down
/// while a dialog is open; this count is what they read.
void main() {
  testWidgets('counts a dialog while it is open, and only then', (
    tester,
  ) async {
    final tracker = PopupRouteTracker();
    addTearDown(tracker.dispose);
    late BuildContext pageContext;
    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [tracker],
        builder: (context, child) =>
            CcTheme(data: CcThemeData.light(), child: child!),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              pageContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    expect(tracker.open.value, 0, reason: 'the page itself is not a popup');

    final closed = showCcDialog<void>(
      context: pageContext,
      builder: (_) => const Text('dialog'),
    );
    await tester.pumpAndSettle();
    expect(tracker.open.value, 1);

    Navigator.of(pageContext, rootNavigator: true).pop();
    await tester.pumpAndSettle();
    await closed;
    expect(tracker.open.value, 0);
  });
}
