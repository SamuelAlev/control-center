import 'dart:math' as math;

import 'package:cc_domain/features/subscriptions/subscriptions.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/subscriptions/presentation/widgets/subscription_usage_pill.dart';
import 'package:control_center/features/subscriptions/providers/subscription_usage_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _usage = SubscriptionUsage(
  providerId: 'claude',
  displayName: 'Claude',
  status: SubscriptionStatus.ok,
  windows: [
    SubscriptionWindow(
      id: '5h',
      label: 'Session',
      usedFraction: 0.4,
      resetsAt: DateTime.utc(2030, 1, 1, 12),
    ),
  ],
  fetchedAt: DateTime.utc(2030),
);

class _FixedUsage extends SubscriptionUsageNotifier {
  @override
  Future<List<SubscriptionUsage>> build() async => [_usage];
}

/// Regression coverage for the hover↔rest border transition of the title-bar
/// usage pill.
///
/// The hover border used to be the raw translucent `lineStrong` token
/// (fg@16%) animated against the opaque `borderPrimary` rest token.
/// `Color.lerp` interpolates RGB and alpha independently, so mid-tween the
/// border was ~58% ink — composited over the light fill it rendered DARKER
/// than either endpoint, flashing a dark border on every unhover. The fix
/// pre-blends the token into an opaque endpoint (as CcButtonTokens.secondary
/// does), so the invariant under test is: at any point of the tween the
/// painted border stays between the two endpoints — never darker than both.
void main() {
  final themes = [
    ('light', CcThemeData.light()),
    (
      'dark',
      CcThemeData(
        tokens: DesignSystemTokens.dark(),
        brightness: CcBrightness.dark,
      ),
    ),
  ];

  for (final (label, theme) in themes) {
    group('pill border hover transition ($label)', () {
      testWidgets('mid-tween border never dips past the endpoints', (
        tester,
      ) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              subscriptionUsageProvider.overrideWith(_FixedUsage.new),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('en'),
              home: CcTheme(
                data: theme,
                child: const Scaffold(
                  body: Center(child: SubscriptionUsagePill()),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        BoxDecoration pillDecoration() {
          final box = tester.widget<DecoratedBox>(
            find
                .descendant(
                  of: find.byType(AnimatedContainer),
                  matching: find.byType(DecoratedBox),
                )
                .first,
          );
          return box.decoration as BoxDecoration;
        }

        Border borderOf(BoxDecoration deco) => deco.border! as Border;

        final restColor = borderOf(pillDecoration()).top.color;
        expect(restColor.a, 1.0, reason: 'rest border must be opaque');

        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.addPointer(location: Offset.zero);
        addTearDown(gesture.removePointer);

        await gesture.moveTo(tester.getCenter(find.byType(AnimatedContainer)));
        await tester.pumpAndSettle();
        final hoverColor = borderOf(pillDecoration()).top.color;
        expect(hoverColor.a, 1.0, reason: 'hover border must be opaque');
        // The fix must still strengthen the border on hover.
        expect(hoverColor, isNot(restColor));

        // Leave mid-tween: half of the 120 ms easeOut transition.
        await gesture.moveTo(const Offset(-1000, -1000));
        await tester.pump(const Duration(milliseconds: 60));
        final midColor = borderOf(pillDecoration()).top.color;
        await tester.pumpAndSettle();

        expect(
          midColor.a,
          1.0,
          reason:
              'mid-tween border went translucent (${midColor.a}); a '
              'translucent↔opaque lerp composites darker than both endpoints '
              'over the light fill — the reported dark-border flicker',
        );
        // Channel-wise betweenness: with opaque endpoints the interpolated
        // RGB must stay inside the endpoints' channel ranges.
        const eps = 1 / 255;
        void between(double rest, double hover, double mid, String channel) {
          final lo = math.min(rest, hover) - eps;
          final hi = math.max(rest, hover) + eps;
          expect(
            mid,
            inInclusiveRange(lo, hi),
            reason: '$channel dipped outside [$lo, $hi] mid-tween',
          );
        }

        between(restColor.r, hoverColor.r, midColor.r, 'red');
        between(restColor.g, hoverColor.g, midColor.g, 'green');
        between(restColor.b, hoverColor.b, midColor.b, 'blue');
      });
    });
  }
}
