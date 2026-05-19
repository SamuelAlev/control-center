import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/shared/widgets/github_mention_avatar_scope.dart';
import 'package:control_center/shared/widgets/github_user_avatar.dart';
import 'package:control_center/shared/widgets/github_user_hover_target.dart';
import 'package:control_center/shared/widgets/github_user_mention.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Widget _wrap(Widget child) {
  return CcTheme(
    data: CcThemeData.light(),
    child: Directionality(textDirection: TextDirection.ltr, child: child),
  );
}

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
  });
}
