import 'package:cc_ui/src/components/cc_banner.dart';
import 'package:cc_ui/src/components/cc_button.dart';
import 'package:cc_ui/src/components/cc_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

void main() {
  group('CcBanner', () {
    testWidgets('renders the title and body', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          const CcBanner(title: 'Storage full', body: 'Delete old files.'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Storage full'), findsOneWidget);
      expect(find.text('Delete old files.'), findsOneWidget);
    });

    testWidgets('renders without a body', (tester) async {
      await tester.pumpWidget(ccTestApp(const CcBanner(title: 'Heads up')));
      await tester.pumpAndSettle();

      expect(find.text('Heads up'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders an empty body as no body', (tester) async {
      await tester.pumpWidget(
        ccTestApp(const CcBanner(title: 'Title', body: '')),
      );
      await tester.pumpAndSettle();

      // Empty-string body is treated as absent: only the title text is present.
      expect(find.text('Title'), findsOneWidget);
      expect(find.text(''), findsNothing);
    });

    testWidgets('renders a status glyph for every variant', (tester) async {
      for (final variant in CcBannerVariant.values) {
        await tester.pumpWidget(
          ccTestApp(CcBanner(title: 'v', variant: variant)),
        );
        await tester.pumpAndSettle();

        // The leading status glyph is always present (color is never the only
        // signal), regardless of variant.
        expect(
          find.descendant(
            of: find.byType(CcBanner),
            matching: find.byType(Icon),
          ),
          findsWidgets,
          reason: 'variant $variant should render a default glyph',
        );
      }
    });

    testWidgets('uses a custom icon when provided', (tester) async {
      await tester.pumpWidget(
        ccTestApp(const CcBanner(title: 'Custom', icon: CcIcons.house)),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(CcIcons.house), findsOneWidget);
    });

    testWidgets('renders action buttons and fires their callbacks', (
      tester,
    ) async {
      var primary = 0;
      var secondary = 0;
      await tester.pumpWidget(
        ccTestApp(
          CcBanner(
            title: 'Sync conflict',
            actions: [
              CcBannerAction(
                label: 'Keep mine',
                onPressed: () => primary++,
                primary: true,
              ),
              CcBannerAction(label: 'Use theirs', onPressed: () => secondary++),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Keep mine'), findsOneWidget);
      expect(find.text('Use theirs'), findsOneWidget);

      await tester.tap(find.text('Keep mine'));
      await tester.pump();
      expect(primary, 1);

      await tester.tap(find.text('Use theirs'));
      await tester.pump();
      expect(secondary, 1);
    });

    testWidgets('the primary action uses the accent variant', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          const CcBanner(
            title: 't',
            actions: [
              CcBannerAction(label: 'Loud', onPressed: _noop, primary: true),
              CcBannerAction(label: 'Quiet', onPressed: _noop),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find each button by its label and assert its variant.
      final loud = tester.widget<CcButton>(
        find.ancestor(of: find.text('Loud'), matching: find.byType(CcButton)),
      );
      expect(loud.variant, CcButtonVariant.accent);

      final quiet = tester.widget<CcButton>(
        find.ancestor(of: find.text('Quiet'), matching: find.byType(CcButton)),
      );
      expect(quiet.variant, CcButtonVariant.secondary);
    });

    testWidgets('renders a dismiss control and fires onDismiss', (
      tester,
    ) async {
      var dismissed = 0;
      await tester.pumpWidget(
        ccTestApp(
          CcBanner(
            title: 'Bye',
            onDismiss: () => dismissed++,
            dismissLabel: 'Close',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The close control is the trailing × on the title row.
      final close = find.descendant(
        of: find.byType(CcBanner),
        matching: find.byIcon(CcIcons.x),
      );
      await tester.tap(close);
      await tester.pump();

      expect(dismissed, 1);
    });

    testWidgets('hides the dismiss control when onDismiss is null', (
      tester,
    ) async {
      await tester.pumpWidget(ccTestApp(const CcBanner(title: 'No close')));
      await tester.pumpAndSettle();

      // No close (×) control renders without an onDismiss handler.
      expect(
        find.descendant(
          of: find.byType(CcBanner),
          matching: find.byIcon(CcIcons.x),
        ),
        findsNothing,
      );
    });

    testWidgets('is announced as a live region with the title as its label', (
      tester,
    ) async {
      await tester.pumpWidget(
        ccTestApp(const CcBanner(title: 'Important update')),
      );
      await tester.pumpAndSettle();

      // The banner wraps its content in a Semantics(container, liveRegion)
      // node labelled with the title — verify the widget config directly.
      final semantics = tester.widget<Semantics>(
        find
            .descendant(
              of: find.byType(CcBanner),
              matching: find.byType(Semantics),
            )
            .first,
      );
      expect(semantics.properties.liveRegion, isTrue);
      expect(semantics.properties.label, 'Important update');
    });
  });
}

void _noop() {}
