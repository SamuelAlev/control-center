import 'dart:async';

import 'package:cc_ui/src/components/cc_dialog.dart';
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
      // No inherited yellow underline, and a sane (not 48px) base size.
      expect(resolved!.decoration, TextDecoration.none);
      expect(resolved!.fontSize, 14);
    },
  );
  testWidgets('CcDialog renders title, content, and actions', (tester) async {
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

  testWidgets('showCcDialog opens the builder result and pops a value',
      (tester) async {
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

  testWidgets('showCcDialog dismisses when tapping outside the panel',
      (tester) async {
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

  testWidgets('showCcDialog ignores outside taps when not dismissible',
      (tester) async {
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
    showCcDialog<void>(
      context: dialogHost,
      barrierDismissible: false,
      builder: (context) => const CcDialog(content: Text('Stay put')),
    );

    await tester.pumpAndSettle();
    expect(find.text('Stay put'), findsOneWidget);

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    // Still present — the barrier is not dismissible.
    expect(find.text('Stay put'), findsOneWidget);
  });
}
