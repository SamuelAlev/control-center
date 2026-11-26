import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

void main() {
  testWidgets('SourceBadge shows the built-in label by default', (
    tester,
  ) async {
    await tester.pumpWidget(
      ccTestApp(const CcSourceBadge(source: CcConfigSource.project)),
    );

    expect(find.text('Project'), findsOneWidget);
  });

  testWidgets('SourceBadge honors a localized label override', (tester) async {
    await tester.pumpWidget(
      ccTestApp(
        const CcSourceBadge(
          source: CcConfigSource.global,
          label: 'Globalement',
        ),
      ),
    );

    expect(find.text('Globalement'), findsOneWidget);
  });

  testWidgets('ConfigRow renders title, subtitle and source badge', (
    tester,
  ) async {
    await tester.pumpWidget(
      ccTestApp(
        const CcConfigRow(
          title: Text('git push'),
          subtitle: Text('Allowed without confirmation'),
          source: CcConfigSource.project,
        ),
      ),
    );

    expect(find.text('git push'), findsOneWidget);
    expect(find.text('Allowed without confirmation'), findsOneWidget);
    expect(find.byType(CcSourceBadge), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ConfigRow invokes onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      ccTestApp(
        CcConfigRow(
          title: const Text('rule'),
          source: CcConfigSource.defaultValue,
          onTap: () => tapped = true,
        ),
      ),
    );

    await tester.tap(find.text('rule'));
    expect(tapped, isTrue);
  });

  testWidgets('SourceBadge labels the local-override source', (tester) async {
    await tester.pumpWidget(
      ccTestApp(const CcSourceBadge(source: CcConfigSource.localOverride)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Local override'), findsOneWidget);
  });

  testWidgets('SourceBadge labels the default source', (tester) async {
    await tester.pumpWidget(
      ccTestApp(const CcSourceBadge(source: CcConfigSource.defaultValue)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Default'), findsOneWidget);
  });

  testWidgets('SourceBadge labels the inherited source', (tester) async {
    await tester.pumpWidget(
      ccTestApp(const CcSourceBadge(source: CcConfigSource.inherited)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Inherited'), findsOneWidget);
  });

  testWidgets('SourceBadge labels the system source', (tester) async {
    await tester.pumpWidget(
      ccTestApp(const CcSourceBadge(source: CcConfigSource.system)),
    );
    await tester.pumpAndSettle();
    expect(find.text('System'), findsOneWidget);
  });

  testWidgets('ConfigRow renders leading, status and actions slots', (
    tester,
  ) async {
    await tester.pumpWidget(
      ccTestApp(
        const CcConfigRow(
          title: Text('rule'),
          leading: Text('lead'),
          status: Text('ok'),
          actions: Text('edit'),
        ),
      ),
    );
    expect(find.text('rule'), findsOneWidget);
    expect(find.text('lead'), findsOneWidget);
    expect(find.text('ok'), findsOneWidget);
    expect(find.text('edit'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a tappable row is a focusable button for the keyboard', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final before = FocusNode(debugLabel: 'before');
    addTearDown(before.dispose);
    var taps = 0;
    await tester.pumpWidget(
      ccTestApp(
        Column(
          children: [
            Focus(
              focusNode: before,
              child: const SizedBox(width: 10, height: 10),
            ),
            CcConfigRow(title: const Text('Theme'), onTap: () => taps++),
          ],
        ),
      ),
    );
    expect(
      tester.getSemantics(find.byType(CcConfigRow)),
      matchesSemantics(
        label: 'Theme',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
    before.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(taps, 2);
    handle.dispose();
  });

  testWidgets('a trailing control does not also activate the row', (
    tester,
  ) async {
    var rowTaps = 0;
    var actionTaps = 0;
    await tester.pumpWidget(
      ccTestApp(
        CcConfigRow(
          title: const Text('Theme'),
          onTap: () => rowTaps++,
          actions: CcButton(
            onPressed: () => actionTaps++,
            child: const Text('Edit'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Edit'));
    await tester.pump();
    expect((rowTaps, actionTaps), (0, 1));

    // Enter on the focused control activates only the control.
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect((rowTaps, actionTaps), (0, 2));

    await tester.tap(find.text('Theme'));
    await tester.pump();
    expect((rowTaps, actionTaps), (1, 2));
  });
}
