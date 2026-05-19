import 'package:cc_infra/cc_infra_web.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/github_user_profile_header.dart';
import 'package:control_center/shared/widgets/github_user_status_badge.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _longStatus =
    "I didn't have time to write a short status, so I wrote a long one instead.";

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: CcTheme(
      data: CcThemeData.light(),
      child: Scaffold(body: Center(child: child)),
    ),
  );
}

Future<void> _hover(WidgetTester tester, Finder target) async {
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(location: Offset.zero);
  addTearDown(gesture.removePointer);
  await tester.pump();
  await gesture.moveTo(tester.getCenter(target));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
}

/// The opacity of the fade the pill's status text rides in on.
double _textOpacity(WidgetTester tester) => tester
    .widget<Opacity>(
      find.ancestor(
        of: find.text(_longStatus),
        matching: find.descendant(
          of: find.byKey(kStatusPillKey),
          matching: find.byType(Opacity),
        ),
      ),
    )
    .opacity;

void main() {
  group('GitHubUserStatusAvatarBadge', () {
    testWidgets('shows the emoji only, keeping the message off the layout', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const GitHubUserStatusAvatarBadge(
            status: GitHubUserStatus(
              isBusy: false,
              message: _longStatus,
              emoji: ':headphones:',
            ),
            avatarSize: 64,
            child: CcAvatar(size: 64, initials: 'C'),
          ),
        ),
      );

      expect(find.text('🎧'), findsOneWidget);
      expect(find.text(_longStatus), findsNothing);
    });

    testWidgets('reveals the status text on hover', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const GitHubUserStatusAvatarBadge(
            status: GitHubUserStatus(
              isBusy: false,
              message: _longStatus,
              emoji: ':headphones:',
            ),
            avatarSize: 64,
            child: CcAvatar(size: 64, initials: 'C'),
          ),
        ),
      );

      await _hover(tester, find.text('🎧'));

      expect(find.text(_longStatus), findsOneWidget);
    });

    testWidgets('unrolls from the badge rightwards, then rolls back', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const GitHubUserStatusAvatarBadge(
            status: GitHubUserStatus(
              isBusy: false,
              message: _longStatus,
              emoji: ':headphones:',
            ),
            avatarSize: 64,
            child: CcAvatar(size: 64, initials: 'C'),
          ),
        ),
      );

      final badgeSize = tester.getSize(find.text('🎧').first);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.text('🎧')));
      await tester.pump(const Duration(milliseconds: 130));
      await tester.pump();

      final pill = find.byKey(kStatusPillKey);

      // Opens at the badge's own width — the circle, not a panel over it.
      final opening = tester.getSize(pill).width;
      await tester.pump(const Duration(milliseconds: 60));
      final growing = tester.getSize(pill).width;
      await tester.pumpAndSettle();
      final open = tester.getSize(pill).width;

      expect(opening, lessThan(growing));
      expect(growing, lessThan(open));
      expect(open, greaterThan(badgeSize.width * 4));

      // The left cap never moves: the pill only extends to the right.
      final left = tester.getTopLeft(pill).dx;
      await gesture.moveTo(Offset.zero);
      await tester.pump();

      // A pointer that grazes the edge must not toggle it — the grace holds.
      await tester.pump(const Duration(milliseconds: 60));
      expect(tester.getSize(pill).width, open);

      // Past the grace it rolls back up, still anchored at the same left cap.
      // The text fades out before the box moves, so sample mid-motion.
      await tester.pump(const Duration(milliseconds: 40));
      await tester.pump(kStatusPillMotion ~/ 2);
      expect(tester.getSize(pill).width, lessThan(open));
      expect(tester.getTopLeft(pill).dx, moreOrLessEquals(left, epsilon: 0.5));

      await tester.pumpAndSettle();
      expect(find.text(_longStatus), findsNothing);
    });

    testWidgets('a pointer that leaves and returns keeps the pill open', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const GitHubUserStatusAvatarBadge(
            status: GitHubUserStatus(
              isBusy: false,
              message: _longStatus,
              emoji: ':headphones:',
            ),
            avatarSize: 64,
            child: CcAvatar(size: 64, initials: 'C'),
          ),
        ),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();
      final target = tester.getCenter(find.byType(CcAvatar));
      await gesture.moveTo(target);
      await tester.pump(const Duration(milliseconds: 130));
      await tester.pumpAndSettle();

      final pill = find.byKey(kStatusPillKey);
      final open = tester.getSize(pill).width;

      await gesture.moveTo(Offset.zero);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      await gesture.moveTo(target);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(tester.getSize(pill).width, open);
    });

    testWidgets('the emoji never blinks out while the pill unrolls', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const GitHubUserStatusAvatarBadge(
            status: GitHubUserStatus(
              isBusy: false,
              message: _longStatus,
              emoji: ':headphones:',
            ),
            avatarSize: 64,
            child: CcAvatar(size: 64, initials: 'C'),
          ),
        ),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.byType(CcAvatar)));
      await tester.pump(const Duration(milliseconds: 130));
      await tester.pump();

      // The pill is opaque and covers the badge, so anything that dims the
      // leading glyph reads as the emoji vanishing out of its own circle.
      final glyph = find.descendant(
        of: find.byKey(kStatusPillKey),
        matching: find.text('🎧'),
      );
      final fades = find.descendant(
        of: find.byKey(kStatusPillKey),
        matching: find.byType(Opacity),
      );

      for (var elapsed = Duration.zero;
          elapsed <= kStatusPillMotion;
          elapsed += kStatusPillMotion ~/ 6) {
        expect(glyph, findsOneWidget);
        expect(find.ancestor(of: glyph, matching: fades), findsNothing);
        await tester.pump(kStatusPillMotion ~/ 6);
      }

      // The text is what fades, and it is still doing so — otherwise the check
      // above would pass on a pill that had stopped animating anything.
      await tester.pumpAndSettle();
      expect(_textOpacity(tester), 1);

      await gesture.moveTo(Offset.zero);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(kStatusPillMotion ~/ 2);

      expect(_textOpacity(tester), 0);
      expect(glyph, findsOneWidget);
      expect(find.ancestor(of: glyph, matching: fades), findsNothing);
    });

    testWidgets('the glyph renders in the style it was measured in', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const GitHubUserStatusAvatarBadge(
            status: GitHubUserStatus(
              isBusy: false,
              message: _longStatus,
              emoji: ':headphones:',
            ),
            avatarSize: 64,
            child: CcAvatar(size: 64, initials: 'C'),
          ),
        ),
      );

      // `Text` merges the ambient DefaultTextStyle unless the style opts out,
      // which had the widget rendering in Manrope while the TextPainter that
      // computes its centring offset measured in the emoji font. Two fonts,
      // two sets of line metrics, and a correction that fit neither.
      final style = tester.widget<Text>(find.text('🎧')).style;
      expect(style?.inherit, isFalse);
      expect(style?.fontFamily, isNotNull);
      // No line-height override: the natural box centres the font's em box.
      expect(style?.height, isNull);
    });

    testWidgets('busy status reads out without hovering', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(
          const GitHubUserStatusAvatarBadge(
            status: GitHubUserStatus(isBusy: true, message: 'Shipping'),
            avatarSize: 64,
            child: CcAvatar(size: 64, initials: 'C'),
          ),
        ),
      );

      // No emoji — the badge still has a glyph to hover.
      expect(find.byType(Icon), findsOneWidget);
      expect(find.bySemanticsLabel('Busy · Shipping'), findsOneWidget);

      handle.dispose();
    });

    testWidgets('renders the avatar verbatim when the status is empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const GitHubUserStatusAvatarBadge(
            status: GitHubUserStatus(isBusy: false),
            avatarSize: 64,
            child: CcAvatar(size: 64, initials: 'C'),
          ),
        ),
      );

      expect(
        find.descendant(
          of: find.byType(GitHubUserStatusAvatarBadge),
          matching: find.byType(MouseRegion),
        ),
        findsNothing,
      );
    });
  });

  group('GitHubUserProfileHeader', () {
    testWidgets('a long status does not overflow a narrow header', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const SizedBox(
            width: 320,
            child: GitHubUserProfileHeader(
              profile: GitHubUserProfile(
                login: 'charlietango',
                name: 'Catalin Tudorache',
                avatarUrl: '',
                status: GitHubUserStatus(
                  isBusy: false,
                  message: _longStatus,
                  emoji: ':headphones:',
                ),
              ),
              avatarSize: 64,
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Catalin Tudorache'), findsOneWidget);
      expect(find.text('🎧'), findsOneWidget);
    });
  });
}
