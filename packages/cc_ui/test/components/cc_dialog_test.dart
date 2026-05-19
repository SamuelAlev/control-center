import 'dart:async';

import 'package:cc_ui/src/components/cc_dialog.dart';
import 'package:cc_ui/src/components/cc_icons.dart';
import 'package:cc_ui/src/foundation/cc_tappable.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

void main() {
  testWidgets(
    'showCcDialog supplies a complete text style over a bad ambient default',
    (tester) async {
      // Reproduce the production overlay: the only ambient DefaultTextStyle a
      // root-overlay dialog inherits is WidgetsApp's error fallback — a giant
      // font with a double yellow underline. The dialog must override it.
      late BuildContext dialogHost;
      await tester.pumpWidget(
        CcTheme(
          data: CcThemeData.light(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: MediaQuery(
              data: const MediaQueryData(),
              child: DefaultTextStyle(
                style: const TextStyle(
                  fontSize: 48,
                  decoration: TextDecoration.underline,
                  decorationColor: Color(0xFFFFFF00),
                  decorationStyle: TextDecorationStyle.double,
                ),
                child: Navigator(
                  onGenerateRoute: (settings) => PageRouteBuilder<void>(
                    pageBuilder: (context, animation, secondaryAnimation) {
                      dialogHost = context;
                      return const SizedBox.expand();
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      TextStyle? resolved;
      unawaited(
        showCcDialog<void>(
          context: dialogHost,
          builder: (context) => Builder(
            builder: (context) {
              resolved = DefaultTextStyle.of(context).style;
              return const CcDialog(content: Text('Body'));
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Body'), findsOneWidget);
      expect(resolved, isNotNull);
      // No inherited yellow underline and a sane (not 48px) base size.
      expect(resolved!.decoration, TextDecoration.none);
      expect(resolved!.fontSize, 14);
    },
  );
  testWidgets('CcDialog renders title, content and actions', (tester) async {
    await tester.pumpWidget(
      ccTestApp(
        const CcDialog(
          title: 'Delete workspace',
          content: Text('This cannot be undone.'),
          actions: [Text('Cancel'), Text('Delete')],
        ),
      ),
    );

    expect(find.text('Delete workspace'), findsOneWidget);
    expect(find.text('This cannot be undone.'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
  });

  testWidgets('CcDialog renders without a title or actions', (tester) async {
    await tester.pumpWidget(
      ccTestApp(const CcDialog(content: Text('Just a body'))),
    );

    expect(find.text('Just a body'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('showCcDialog opens the builder result and pops a value', (
    tester,
  ) async {
    late BuildContext dialogHost;
    Object? result;

    await tester.pumpWidget(
      ccTestApp(
        Navigator(
          onGenerateRoute: (settings) => PageRouteBuilder<void>(
            pageBuilder: (context, animation, secondaryAnimation) {
              dialogHost = context;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );

    final future = showCcDialog<String>(
      context: dialogHost,
      builder: (context) => CcDialog(
        title: 'Confirm',
        content: const Text('Are you sure?'),
        actions: [
          CcTappable(
            onPressed: () => Navigator.of(context).pop('ok'),
            builder: (context, states) => const Text('OK'),
          ),
        ],
      ),
    ).then((value) => result = value);

    await tester.pumpAndSettle();
    expect(find.text('Are you sure?'), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await future;

    expect(result, 'ok');
    expect(find.text('Are you sure?'), findsNothing);
  });

  testWidgets('showCcDialog dismisses when tapping outside the panel', (
    tester,
  ) async {
    late BuildContext dialogHost;

    await tester.pumpWidget(
      ccTestApp(
        Navigator(
          onGenerateRoute: (settings) => PageRouteBuilder<void>(
            pageBuilder: (context, animation, secondaryAnimation) {
              dialogHost = context;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );

    final future = showCcDialog<void>(
      context: dialogHost,
      builder: (context) => const CcDialog(content: Text('Dismiss me')),
    );

    await tester.pumpAndSettle();
    expect(find.text('Dismiss me'), findsOneWidget);

    // Tap well outside the centered panel. The frosted scrim is ignore-pointer,
    // so the tap reaches the route barrier and dismisses the dialog.
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    await future;
    expect(find.text('Dismiss me'), findsNothing);
  });

  testWidgets('showCcDialog ignores outside taps when not dismissible', (
    tester,
  ) async {
    late BuildContext dialogHost;

    await tester.pumpWidget(
      ccTestApp(
        Navigator(
          onGenerateRoute: (settings) => PageRouteBuilder<void>(
            pageBuilder: (context, animation, secondaryAnimation) {
              dialogHost = context;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );

    // Fire and forget — the dialog is never popped here.
    unawaited(
      showCcDialog<void>(
        context: dialogHost,
        barrierDismissible: false,
        builder: (context) => const CcDialog(content: Text('Stay put')),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Stay put'), findsOneWidget);

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    // Still present — the barrier is not dismissible.
    expect(find.text('Stay put'), findsOneWidget);
  });

  testWidgets('CcDialog renders a close control that fires onClose', (
    tester,
  ) async {
    var closed = 0;
    await tester.pumpWidget(
      ccTestApp(
        CcDialog(
          title: 'With close',
          content: const Text('Body'),
          onClose: () => closed++,
        ),
      ),
    );
    // The close (×) control renders only when onClose is supplied.
    final close = find.descendant(
      of: find.byType(CcDialog),
      matching: find.byIcon(CcIcons.x),
    );
    expect(close, findsOneWidget);
    await tester.tap(close);
    await tester.pump();
    expect(closed, 1);
  });

  group('showCcConfirmDialog', () {
    Future<BuildContext> pumpHost(WidgetTester tester) async {
      late BuildContext dialogHost;
      await tester.pumpWidget(
        ccTestApp(
          Navigator(
            onGenerateRoute: (settings) => PageRouteBuilder<void>(
              pageBuilder: (context, animation, secondaryAnimation) {
                dialogHost = context;
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      );
      return dialogHost;
    }

    testWidgets('resolves true on confirm and false on cancel', (tester) async {
      final host = await pumpHost(tester);

      bool? result;
      unawaited(
        showCcConfirmDialog(
          context: host,
          title: 'Delete agent',
          message: 'The agent and its run history are removed.',
          confirmLabel: 'Delete agent',
          cancelLabel: 'Cancel',
          danger: true,
        ).then((v) => result = v),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete agent').last);
      await tester.pumpAndSettle();
      expect(result, isTrue);

      unawaited(
        showCcConfirmDialog(
          context: host,
          title: 'Delete agent',
          message: 'The agent and its run history are removed.',
          confirmLabel: 'Delete agent',
          cancelLabel: 'Cancel',
          danger: true,
        ).then((v) => result = v),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(result, isFalse);
    });

    testWidgets('typeToConfirm arms the confirm button only on exact match', (
      tester,
    ) async {
      final host = await pumpHost(tester);

      bool? result;
      unawaited(
        showCcConfirmDialog(
          context: host,
          title: 'Delete workspace',
          message: 'Every agent, space and run log is destroyed.',
          confirmLabel: 'Delete workspace',
          cancelLabel: 'Cancel',
          danger: true,
          typeToConfirm: 'acme-prod',
          typeToConfirmLabel: 'Type the workspace name to confirm',
        ).then((v) => result = v),
      );
      await tester.pumpAndSettle();

      // Unarmed: tapping the confirm button does nothing.
      await tester.tap(find.text('Delete workspace').last);
      await tester.pumpAndSettle();
      expect(result, isNull);

      // A near-miss keeps it disarmed.
      await tester.enterText(find.byType(EditableText), 'acme-dev');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete workspace').last);
      await tester.pumpAndSettle();
      expect(result, isNull);

      // The exact resource name arms it.
      await tester.enterText(find.byType(EditableText), 'acme-prod');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete workspace').last);
      await tester.pumpAndSettle();
      expect(result, isTrue);
    });
  });

  group('focus restoration', () {
    testWidgets('does not focus a trigger that left the tree while open', (
      tester,
    ) async {
      final panel = FocusScopeNode(debugLabel: 'panel');
      addTearDown(panel.dispose);
      var showPanel = true;
      var showAutofocus = false;
      late StateSetter setter;
      late BuildContext host;

      await tester.pumpWidget(
        ccTestApp(
          Navigator(
            onGenerateRoute: (settings) => PageRouteBuilder<void>(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  StatefulBuilder(
                    builder: (context, setState) {
                      setter = setState;
                      host = context;
                      return Column(
                        children: [
                          if (showPanel)
                            FocusScope(
                              node: panel,
                              autofocus: true,
                              child: const SizedBox(width: 10, height: 10),
                            ),
                          if (showAutofocus)
                            const Focus(
                              autofocus: true,
                              child: SizedBox(width: 10, height: 10),
                            ),
                        ],
                      );
                    },
                  ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // A panel scope holds the focus, as a popover/menu panel does.
      expect(FocusManager.instance.primaryFocus, panel);

      unawaited(
        showCcDialog<void>(
          context: host,
          builder: (context) => const CcDialog(content: Text('Body')),
        ),
      );
      await tester.pumpAndSettle();

      // The trigger is torn down while the dialog is up (the popover behind it
      // closes, the page below rebuilds, a list item recycles…).
      setter(() => showPanel = false);
      await tester.pumpAndSettle();
      expect(panel.parent, isNull);

      Navigator.of(host).pop();
      await tester.pumpAndSettle();

      // Restoring focus to the detached scope would re-register it as the route
      // scope's focusedChild through its stale ancestors cache; the next
      // autofocus request then trips FocusScopeNode.focusedChild's assertion
      // (and in release, the primary focus sits on a detached subtree).
      setter(() => showAutofocus = true);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(FocusManager.instance.primaryFocus, isNot(panel));
    });

    testWidgets('focuses the trigger again when it is still mounted', (
      tester,
    ) async {
      final trigger = FocusNode(debugLabel: 'trigger');
      addTearDown(trigger.dispose);
      late BuildContext host;

      await tester.pumpWidget(
        ccTestApp(
          Navigator(
            onGenerateRoute: (settings) => PageRouteBuilder<void>(
              pageBuilder: (context, animation, secondaryAnimation) {
                host = context;
                return Focus(
                  focusNode: trigger,
                  autofocus: true,
                  child: const SizedBox(width: 10, height: 10),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(trigger.hasPrimaryFocus, isTrue);

      unawaited(
        showCcDialog<void>(
          context: host,
          builder: (context) => const CcDialog(content: Text('Body')),
        ),
      );
      await tester.pumpAndSettle();
      expect(trigger.hasPrimaryFocus, isFalse);

      Navigator.of(host).pop();
      await tester.pumpAndSettle();
      expect(trigger.hasPrimaryFocus, isTrue);
    });
  });
}
