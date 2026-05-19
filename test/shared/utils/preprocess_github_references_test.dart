import 'package:control_center/shared/utils/github_markdown_preprocessor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('preprocessGitHubReferences', () {
    test('rewrites a bare @login', () {
      expect(
        preprocessGitHubReferences(
          'Thanks @octocat',
          owner: 'acme',
          repo: 'app',
        ),
        'Thanks [@octocat](control-center://user/octocat)',
      );
    });

    test('rewrites @org/team without truncating to @org', () {
      expect(
        preprocessGitHubReferences(
          'cc @github/linguist',
          owner: 'acme',
          repo: 'app',
        ),
        'cc [@github/linguist](control-center://team/github/linguist)',
      );
    });

    test('rewrites several mentions on one line', () {
      expect(
        preprocessGitHubReferences(
          'Hey @alice and @bob',
          owner: 'acme',
          repo: 'app',
        ),
        'Hey [@alice](control-center://user/alice) and '
        '[@bob](control-center://user/bob)',
      );
    });

    test('skips mentions inside inline code', () {
      expect(
        preprocessGitHubReferences(
          'see `@octocat` in code',
          owner: 'acme',
          repo: 'app',
        ),
        'see `@octocat` in code',
      );
    });

    test('skips mentions inside fenced code', () {
      const src = '```\n@octocat\n```';
      expect(preprocessGitHubReferences(src, owner: 'acme', repo: 'app'), src);
    });

    test('does not treat emails as mentions', () {
      expect(
        preprocessGitHubReferences(
          'write user@example.com',
          owner: 'acme',
          repo: 'app',
        ),
        'write user@example.com',
      );
    });

    test('does not rewrite @ inside a URL path', () {
      expect(
        preprocessGitHubReferences(
          'see https://example.com/@octocat',
          owner: 'acme',
          repo: 'app',
        ),
        'see https://example.com/@octocat',
      );
    });

    test('does not wrap an already-linked @mention', () {
      const src = '[@octocat](https://github.com/octocat)';
      expect(preprocessGitHubReferences(src, owner: 'acme', repo: 'app'), src);
    });

    test('rewrites mentions on heading lines', () {
      expect(
        preprocessGitHubReferences(
          '## Thanks @octocat',
          owner: 'acme',
          repo: 'app',
        ),
        '## Thanks [@octocat](control-center://user/octocat)',
      );
    });

    test('does not rewrite issue shorthand on heading lines', () {
      expect(
        preprocessGitHubReferences(
          '## Tracking #123',
          owner: 'acme',
          repo: 'app',
        ),
        '## Tracking #123',
      );
    });

    test('rewrites #123 and owner/repo#456 on the same line', () {
      expect(
        preprocessGitHubReferences(
          'See #1 and acme/app#2',
          owner: 'acme',
          repo: 'app',
        ),
        'See [#1](control-center://pr/acme/app/1) and '
        '[acme/app#2](control-center://pr/acme/app/2)',
      );
    });

    test('still rewrites mentions when owner/repo are empty', () {
      expect(
        preprocessGitHubReferences('See #123 and @alice', owner: '', repo: ''),
        'See #123 and [@alice](control-center://user/alice)',
      );
    });

    test('skips 6-digit hex-like #numbers', () {
      expect(
        preprocessGitHubReferences('color #ff00aa', owner: 'acme', repo: 'app'),
        'color #ff00aa',
      );
    });
  });
}
