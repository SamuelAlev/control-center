import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/shared/widgets/github_mention_avatar_scope.dart';
import 'package:control_center/shared/widgets/github_user_avatar.dart';
import 'package:control_center/shared/widgets/github_user_hover_target.dart';
import 'package:control_center/shared/widgets/github_user_mention.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Widget _wrap(Widget child) {
  return CcTheme(
    data: CcThemeData.light(),
    child: Directionality(textDirection: TextDirection.ltr, child: child),
  );
}

/// Same, but the chip hugs its content instead of filling the surface — which
/// is how it actually renders inline, and what makes "is the pointer on it"
/// a real question.
Widget _wrapHugging(Widget child) => _wrap(Center(child: child));

/// The mention's own hover wash (CcAvatar has animated containers too).
final Finder _wash = find.descendant(
  of: find.byType(CcTappable),
  matching: find.byType(AnimatedContainer),
);

void main() {
  group('GitHubUserMention', () {
    testWidgets('reserves a 16px avatar box next to the login', (tester) async {
      await tester.pumpWidget(
        _wrap(const GitHubUserMention(login: 'octocat', avatarUrl: '')),
      );

      expect(find.text('octocat'), findsOneWidget);
      expect(find.byType(GitHubUserAvatar), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is SizedBox &&
              w.width == GitHubUserMention.avatarSize &&
              w.height == GitHubUserMention.avatarSize,
        ),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('teams use a glyph, not a user avatar or hover target', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const GitHubUserMention(login: 'Frontend platform', isTeam: true),
        ),
      );

      expect(find.text('Frontend platform'), findsOneWidget);
      expect(find.byType(GitHubUserAvatar), findsNothing);
      expect(find.byType(GitHubUserHoverTarget), findsNothing);
    });

    testWidgets('team mentions render the logo when an avatar URL is known', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const GitHubUserMention(
            login: 'eng',
            avatarUrl: 'https://avatars.githubusercontent.com/t/1',
            isTeam: true,
          ),
        ),
      );

      expect(find.byType(GitHubUserAvatar), findsOneWidget);
      expect(find.byType(GitHubUserHoverTarget), findsNothing);
    });

    testWidgets('team mentions resolve a logo from GitHubMentionAvatarScope', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const GitHubMentionAvatarScope(
            avatars: {'acme/eng': 'https://avatars.githubusercontent.com/t/1'},
            child: GitHubUserMention(login: 'acme/eng', isTeam: true),
          ),
        ),
      );

      expect(find.byType(GitHubUserAvatar), findsOneWidget);
    });

    testWidgets('bots are not wrapped as a profile link', (tester) async {
      await tester.pumpWidget(
        _wrap(const GitHubUserMention(login: 'renovate[bot]', avatarUrl: '')),
      );

      expect(find.text('renovate'), findsOneWidget);
      expect(find.byType(GitHubUserHoverTarget), findsNothing);
    });

    testWidgets('tapping a human mention navigates to the user profile', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/workspaces/ws-1/inbox',
        routes: [
          GoRoute(
            path: '/workspaces/:workspaceId/inbox',
            builder: (_, _) =>
                const GitHubUserMention(login: 'octocat', avatarUrl: ''),
          ),
          GoRoute(
            path: '/workspaces/:workspaceId/users/:login',
            builder: (_, state) =>
                Text('profile:${state.pathParameters['login']}'),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        CcTheme(
          data: CcThemeData.light(),
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('octocat'));
      await tester.pumpAndSettle();

      expect(find.text('profile:octocat'), findsOneWidget);
    });

    testWidgets('washes on hover and returns to transparent on exit', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapHugging(const GitHubUserMention(login: 'octocat', avatarUrl: '')),
      );

      Color washColor() =>
          (tester.widget<AnimatedContainer>(_wash).decoration! as BoxDecoration)
              .color!;

      // At rest the wash is alpha-0 rather than absent, so the animation lerps
      // only alpha and never flashes through grey.
      expect(washColor().a, 0);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      // Park the pointer OFF the chip. `_wrapHugging` centers it precisely so
      // the top-left corner is empty space — an unconstrained chip fills the
      // whole test surface, which would make every pointer position a hover.
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();
      expect(washColor().a, 0);

      await gesture.moveTo(tester.getCenter(find.text('octocat')));
      await tester.pumpAndSettle();

      // A mention is a link; without this it had a click cursor and no visual
      // feedback at all, so nothing said it was pressable.
      expect(washColor().a, greaterThan(0));

      await gesture.moveTo(Offset.zero);
      await tester.pumpAndSettle();
      expect(washColor().a, 0);
    });

    testWidgets('the wash never grows the inline line box', (tester) async {
      await tester.pumpWidget(
        _wrapHugging(const GitHubUserMention(login: 'octocat', avatarUrl: '')),
      );

      // Height is pinned to the avatar: this chip rides in a WidgetSpan inside
      // a paragraph, and a taller chip re-spaces every line of a comment that
      // mentions someone.
      expect(tester.getSize(_wash).height, GitHubUserMention.avatarSize);
    });

    testWidgets('a team mention has no wash and is not tappable', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const GitHubUserMention(login: 'eng', isTeam: true)),
      );

      expect(find.byType(AnimatedContainer), findsNothing);
      expect(find.byType(CcTappable), findsNothing);
    });
  });
}
