import 'package:control_center/shared/utils/github_user_mention_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseGitHubMentionLink', () {
    test('parses control-center://user/<login>', () {
      final mention = parseGitHubMentionLink(
        url: 'control-center://user/octocat',
      );
      expect(mention, isNotNull);
      expect(mention!.login, 'octocat');
      expect(mention.isTeam, isFalse);
    });

    test('parses control-center://team/<org>/<slug>', () {
      final mention = parseGitHubMentionLink(
        url: 'control-center://team/github/linguist',
      );
      expect(mention, isNotNull);
      expect(mention!.login, 'github/linguist');
      expect(mention.isTeam, isTrue);
    });

    test('parses an @login label regardless of href', () {
      final mention = parseGitHubMentionLink(
        url: 'https://github.com/octocat',
        label: '@octocat',
      );
      expect(mention, isNotNull);
      expect(mention!.login, 'octocat');
      expect(mention.isTeam, isFalse);
    });

    test('parses an @org/team label', () {
      final mention = parseGitHubMentionLink(
        url: 'https://github.com/orgs/github/teams/linguist',
        label: '@github/linguist',
      );
      expect(mention!.isTeam, isTrue);
      expect(mention.login, 'github/linguist');
    });

    test('ignores a GitHub profile URL whose label is not an @mention', () {
      expect(
        parseGitHubMentionLink(
          url: 'https://github.com/octocat',
          label: 'octocat',
        ),
        isNull,
      );
    });

    test('ignores unrelated links', () {
      expect(
        parseGitHubMentionLink(url: 'https://example.com', label: 'click here'),
        isNull,
      );
    });
  });
}
