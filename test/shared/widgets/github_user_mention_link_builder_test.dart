import 'package:cc_markdown/cc_markdown.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/widgets/github_reference_link_builder.dart';
import 'package:control_center/shared/utils/github_markdown_preprocessor.dart';
import 'package:control_center/shared/widgets/github_mention_avatar_scope.dart';
import 'package:control_center/shared/widgets/github_user_avatar.dart';
import 'package:control_center/shared/widgets/github_user_mention.dart';
import 'package:control_center/shared/widgets/markdown/markdown_registries.dart';
import 'package:control_center/shared/widgets/markdown/markdown_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      home: CcTheme(
        data: CcThemeData.light(),
        child: Scaffold(body: child),
      ),
    ),
  );
}

Future<void> _pumpMarkdown(
  WidgetTester tester,
  String source, {
  CcNodeBuilder? linkBuilder,
}) async {
  final processed = preprocessGitHubReferences(
    source,
    owner: 'acme',
    repo: 'app',
  );
  await tester.pumpWidget(
    _host(
      Builder(
        builder: (context) {
          return CcMarkdown(
            data: processed,
            style: appMarkdownStyle(context),
            plugins: githubMarkdownPlugins,
            options: githubMarkdownOptions,
            builders: linkBuilder == null
                ? githubMarkdownBuilders
                : githubMarkdownBuilders.withOverrides({'link': linkBuilder}),
            onTapLink: (_) {},
          );
        },
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('GitHubUserMentionLinkBuilder', () {
    testWidgets('renders @login as a GitHubUserMention chip', (tester) async {
      await _pumpMarkdown(tester, 'Thanks @octocat');

      expect(find.byType(GitHubUserMention), findsOneWidget);
      expect(find.text('octocat'), findsOneWidget);
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

    testWidgets('renders @org/team as a team mention', (tester) async {
      await _pumpMarkdown(tester, 'cc @github/linguist');

      final mention = tester.widget<GitHubUserMention>(
        find.byType(GitHubUserMention),
      );
      expect(mention.isTeam, isTrue);
      expect(mention.login, 'github/linguist');
      expect(find.text('github/linguist'), findsOneWidget);
    });

    testWidgets('team mention uses a scoped logo URL', (tester) async {
      await tester.pumpWidget(
        _host(
          GitHubMentionAvatarScope(
            avatars: const {
              'github/linguist': 'https://avatars.githubusercontent.com/t/1',
            },
            child: Builder(
              builder: (context) {
                return CcMarkdown(
                  data: preprocessGitHubReferences(
                    'cc @github/linguist',
                    owner: 'acme',
                    repo: 'app',
                  ),
                  style: appMarkdownStyle(context),
                  plugins: githubMarkdownPlugins,
                  options: githubMarkdownOptions,
                  builders: githubMarkdownBuilders,
                  onTapLink: (_) {},
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(GitHubUserMention), findsOneWidget);
      expect(find.byType(GitHubUserAvatar), findsOneWidget);
    });

    testWidgets('leaves @login in inline code as text', (tester) async {
      await _pumpMarkdown(tester, 'see `@octocat`');

      expect(find.byType(GitHubUserMention), findsNothing);
      expect(
        find.textContaining('octocat', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets(
      'GitHubReferenceLinkBuilder overlay still renders mention chips',
      (tester) async {
        await _pumpMarkdown(
          tester,
          'Thanks @octocat',
          linkBuilder: const GitHubReferenceLinkBuilder(
            currentOwner: 'acme',
            currentRepo: 'app',
            knownWorkspaceRepos: {},
          ),
        );

        expect(find.byType(GitHubUserMention), findsOneWidget);
        expect(find.text('octocat'), findsOneWidget);
      },
    );

    testWidgets('chips an already-linked @mention label', (tester) async {
      await _pumpMarkdown(tester, '[@octocat](https://github.com/octocat)');

      expect(find.byType(GitHubUserMention), findsOneWidget);
      expect(find.text('octocat'), findsOneWidget);
    });
  });
}
