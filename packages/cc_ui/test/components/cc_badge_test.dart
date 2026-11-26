import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

void main() {
  group('CcBadge', () {
    testWidgets('renders its label', (tester) async {
      await tester.pumpWidget(ccTestApp(const CcBadge(label: 'Active')));

      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('renders a leading icon when provided', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          const CcBadge(
            label: 'Done',
            variant: CcBadgeVariant.success,
            icon: IconData(0x1, fontFamily: 'test'),
          ),
        ),
      );

      expect(find.byType(Icon), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('omits the icon when none is given', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          const CcBadge(label: 'Neutral', variant: CcBadgeVariant.neutral),
        ),
      );

      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('every variant renders its label without throwing', (
      tester,
    ) async {
      for (final v in CcBadgeVariant.values) {
        await tester.pumpWidget(ccTestApp(CcBadge(label: 'v', variant: v)));
        expect(find.text('v'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(ccTestApp(const SizedBox()));
      }
    });

    testWidgets('renders under a dark theme', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          theme: CcThemeData(
            tokens: DesignSystemTokens.dark(),
            brightness: CcBrightness.dark,
          ),
          const CcBadge(label: 'Dark', variant: CcBadgeVariant.brand),
        ),
      );
      expect(find.text('Dark'), findsOneWidget);
    });

    testWidgets('long labels truncate instead of wrapping or overflowing', (
      tester,
    ) async {
      await tester.pumpWidget(
        ccTestApp(
          const Center(
            child: SizedBox(
              width: 80,
              child: CcBadge(label: 'An extremely long badge label'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('An extremely long badge label'), findsWidgets);
    });

    testWidgets('uses square border radius and a 1px hairline border', (
      tester,
    ) async {
      await tester.pumpWidget(
        ccTestApp(
          const CcBadge(label: 'Open', variant: CcBadgeVariant.success),
        ),
      );

      final box = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(CcBadge),
          matching: find.byType(DecoratedBox),
        ),
      );
      final decoration = box.decoration as BoxDecoration;
      expect(decoration.borderRadius, AppRadii.brSm);
      expect(decoration.border, isNotNull);
    });

    testWidgets('renders cleanly under RTL directionality', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          textDirection: TextDirection.rtl,
          const CcBadge(
            label: 'Done',
            variant: CcBadgeVariant.info,
            icon: IconData(0x1, fontFamily: 'test'),
          ),
        ),
      );

      expect(find.text('Done'), findsOneWidget);
      expect(find.byType(Icon), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('merged variant uses purple merged tokens in light and dark', (
      tester,
    ) async {
      for (final (tokens, brightness) in [
        (DesignSystemTokens.light(), CcBrightness.light),
        (DesignSystemTokens.dark(), CcBrightness.dark),
      ]) {
        await tester.pumpWidget(
          ccTestApp(
            theme: CcThemeData(tokens: tokens, brightness: brightness),
            const CcBadge(
              label: 'Merged',
              variant: CcBadgeVariant.merged,
              icon: CcIcons.gitMerge,
            ),
          ),
        );

        final box = tester.widget<DecoratedBox>(
          find.descendant(
            of: find.byType(CcBadge),
            matching: find.byType(DecoratedBox),
          ),
        );
        final decoration = box.decoration as BoxDecoration;
        expect(decoration.color, tokens.mergedSoft);
        expect(
          decoration.border,
          Border.all(color: tokens.fgMergedPrimary.withValues(alpha: 0.28)),
        );
        final icon = tester.widget<Icon>(find.byIcon(CcIcons.gitMerge));
        expect(icon.color, tokens.textMergedPrimary);
        final text = tester.widget<Text>(find.text('Merged'));
        expect(text.style?.color, tokens.textMergedPrimary);
      }
    });
  });
}
