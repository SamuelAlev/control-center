import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

void main() {
  group('CcAlert', () {
    testWidgets('renders its title', (tester) async {
      await tester.pumpWidget(ccTestApp(const CcAlert(title: 'Heads up')));

      expect(find.text('Heads up'), findsOneWidget);
    });

    testWidgets('renders the description and icon', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          const CcAlert(
            title: 'Build failed',
            variant: CcAlertVariant.danger,
            icon: IconData(0x1, fontFamily: 'test'),
            description: Text('See logs'),
          ),
        ),
      );

      expect(find.text('Build failed'), findsOneWidget);
      expect(find.text('See logs'), findsOneWidget);
      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('omits the description when not provided', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          const CcAlert(title: 'Only title', variant: CcAlertVariant.success),
        ),
      );

      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('every variant renders its default status glyph', (
      tester,
    ) async {
      for (final v in CcAlertVariant.values) {
        await tester.pumpWidget(ccTestApp(CcAlert(title: 'v', variant: v)));
        expect(find.byType(Icon), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(ccTestApp(const SizedBox()));
      }
    });

    testWidgets('renders the action control and fires onClose', (tester) async {
      var closed = 0;
      await tester.pumpWidget(
        ccTestApp(
          CcAlert(
            title: 'Saved',
            variant: CcAlertVariant.warning,
            action: const Text('Undo'),
            onClose: () => closed++,
          ),
        ),
      );

      expect(find.text('Undo'), findsOneWidget);
      // The close (×) control renders only when onClose is supplied. Locate it
      // as the second CcTappable (the alert itself isn't tappable, so the only
      // CcTappable in the tree is the close button) and tap it.
      final close = find.byType(CcTappable);
      expect(close, findsOneWidget);
      await tester.tap(close);
      await tester.pump();
      expect(closed, 1);
    });

    testWidgets('a trailing control sits on the banner edge, past the body', (
      tester,
    ) async {
      await tester.pumpWidget(
        ccTestApp(
          const SizedBox(
            width: 480,
            child: CcAlert(
              title: 'GitHub is reporting problems',
              description: Text('Pull request data may be stale.'),
              trailing: Text('Open githubstatus.com'),
            ),
          ),
        ),
      );

      final trailing = tester.getRect(find.text('Open githubstatus.com'));
      final description = tester.getRect(
        find.text('Pull request data may be stale.'),
      );
      expect(
        trailing.left,
        greaterThan(description.right),
        reason: 'the control trails the body rather than stacking under it',
      );
      expect(
        trailing.top,
        lessThan(description.bottom),
        reason: 'and costs the banner no extra height',
      );
    });

    testWidgets('the close control stays outermost beside a trailing one', (
      tester,
    ) async {
      await tester.pumpWidget(
        ccTestApp(
          SizedBox(
            width: 480,
            child: CcAlert(
              title: 'GitHub is reporting problems',
              trailing: const Text('Open githubstatus.com'),
              onClose: () {},
            ),
          ),
        ),
      );

      expect(
        tester.getRect(find.byType(CcTappable)).left,
        greaterThan(tester.getRect(find.text('Open githubstatus.com')).right),
      );
    });
  });
}
