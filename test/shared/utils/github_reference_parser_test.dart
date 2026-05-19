import 'package:control_center/shared/utils/github_reference_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ---------------------------------------------------------------------------
  // GitHubPrReference
  // ---------------------------------------------------------------------------
  group('GitHubPrReference', () {
    test('constructor stores owner, repo, number', () {
      const ref = GitHubPrReference(
        owner: 'flutter',
        repo: 'flutter',
        number: 123,
      );
      expect(ref.owner, 'flutter');
      expect(ref.repo, 'flutter');
      expect(ref.number, 123);
    });

    test('toString() returns formatted string', () {
      const ref = GitHubPrReference(
        owner: 'dart-lang',
        repo: 'sdk',
        number: 4567,
      );
      expect(ref.toString(), 'GitHubPrReference(dart-lang/sdk#4567)');
    });
  });

  // ---------------------------------------------------------------------------
  // GitHubIssueReference
  // ---------------------------------------------------------------------------
  group('GitHubIssueReference', () {
    test('constructor stores owner, repo, number', () {
      const ref = GitHubIssueReference(
        owner: 'nodejs',
        repo: 'node',
        number: 99,
      );
      expect(ref.owner, 'nodejs');
      expect(ref.repo, 'node');
      expect(ref.number, 99);
    });

    test('toString() returns formatted string', () {
      const ref = GitHubIssueReference(
        owner: 'rust-lang',
        repo: 'rust',
        number: 1001,
      );
      expect(ref.toString(), 'GitHubIssueReference(rust-lang/rust#1001)');
    });
  });

  // ---------------------------------------------------------------------------
  // GitHubCommitReference
  // ---------------------------------------------------------------------------
  group('GitHubCommitReference', () {
    test('constructor stores owner, repo, sha', () {
      const ref = GitHubCommitReference(
        owner: 'torvalds',
        repo: 'linux',
        sha: 'abc123def456abc123def456abc123def456abcd',
      );
      expect(ref.owner, 'torvalds');
      expect(ref.repo, 'linux');
      expect(ref.sha, 'abc123def456abc123def456abc123def456abcd');
    });

    test('number getter returns 0', () {
      const ref = GitHubCommitReference(
        owner: 'a',
        repo: 'b',
        sha: '1234567890abcdef1234567890abcdef12345678',
      );
      expect(ref.number, 0);
    });

    test('shortSha returns first 7 chars when sha >= 7 chars', () {
      const ref = GitHubCommitReference(
        owner: 'a',
        repo: 'b',
        sha: 'abcdef123456789012345678901234567890abcd',
      );
      expect(ref.shortSha, 'abcdef1');
    });

    test('shortSha returns full sha when sha < 7 chars', () {
      const ref = GitHubCommitReference(
        owner: 'a',
        repo: 'b',
        sha: 'abc12',
      );
      expect(ref.shortSha, 'abc12');
    });

    test('toString() uses shortSha in output', () {
      const ref = GitHubCommitReference(
        owner: 'golang',
        repo: 'go',
        sha: 'fedcba9876fedcba9876fedcba9876fedcba98',
      );
      expect(ref.toString(), 'GitHubCommitReference(golang/go@fedcba9)');
    });
  });

  // ---------------------------------------------------------------------------
  // parseGitHubUrl
  // ---------------------------------------------------------------------------
  group('parseGitHubUrl', () {
    group('PR URLs', () {
      test('parses basic https PR URL', () {
        final ref = parseGitHubUrl(
          'https://github.com/flutter/flutter/pull/42',
        );
        expect(ref, isA<GitHubPrReference>());
        final pr = ref as GitHubPrReference;
        expect(pr.owner, 'flutter');
        expect(pr.repo, 'flutter');
        expect(pr.number, 42);
      });

      test('parses http (non-https) PR URL', () {
        final ref = parseGitHubUrl(
          'http://github.com/owner/repo/pull/1',
        );
        expect(ref, isA<GitHubPrReference>());
        final pr = ref as GitHubPrReference;
        expect(pr.owner, 'owner');
        expect(pr.repo, 'repo');
        expect(pr.number, 1);
      });

      test('parses PR URL with trailing slash', () {
        final ref = parseGitHubUrl(
          'https://github.com/owner/repo/pull/99/',
        );
        expect(ref, isA<GitHubPrReference>());
        final pr = ref as GitHubPrReference;
        expect(pr.owner, 'owner');
        expect(pr.repo, 'repo');
        expect(pr.number, 99);
      });

      test('parses PR URL with query string', () {
        final ref = parseGitHubUrl(
          'https://github.com/owner/repo/pull/55?tab=commits&w=1',
        );
        expect(ref, isA<GitHubPrReference>());
        final pr = ref as GitHubPrReference;
        expect(pr.owner, 'owner');
        expect(pr.repo, 'repo');
        expect(pr.number, 55);
      });

      test('parses PR URL with fragment', () {
        final ref = parseGitHubUrl(
          'https://github.com/owner/repo/pull/77#issuecomment-123',
        );
        expect(ref, isA<GitHubPrReference>());
        final pr = ref as GitHubPrReference;
        expect(pr.owner, 'owner');
        expect(pr.repo, 'repo');
        expect(pr.number, 77);
      });
    });

    group('issue URLs', () {
      test('parses basic issue URL', () {
        final ref = parseGitHubUrl(
          'https://github.com/dart-lang/sdk/issues/100',
        );
        expect(ref, isA<GitHubIssueReference>());
        final issue = ref as GitHubIssueReference;
        expect(issue.owner, 'dart-lang');
        expect(issue.repo, 'sdk');
        expect(issue.number, 100);
      });

      test('parses issue URL with trailing slash', () {
        final ref = parseGitHubUrl(
          'https://github.com/owner/repo/issues/42/',
        );
        expect(ref, isA<GitHubIssueReference>());
        final issue = ref as GitHubIssueReference;
        expect(issue.owner, 'owner');
        expect(issue.repo, 'repo');
        expect(issue.number, 42);
      });

      test('parses issue URL with query string', () {
        final ref = parseGitHubUrl(
          'https://github.com/owner/repo/issues/5?q=is%3Aopen',
        );
        expect(ref, isA<GitHubIssueReference>());
        final issue = ref as GitHubIssueReference;
        expect(issue.owner, 'owner');
        expect(issue.repo, 'repo');
        expect(issue.number, 5);
      });
    });

    group('commit URLs', () {
      test('parses singular commit URL', () {
        final ref = parseGitHubUrl(
          'https://github.com/owner/repo/commit/abcdef1234567890abcdef1234567890abcdef12',
        );
        expect(ref, isA<GitHubCommitReference>());
        final commit = ref as GitHubCommitReference;
        expect(commit.owner, 'owner');
        expect(commit.repo, 'repo');
        expect(commit.sha, 'abcdef1234567890abcdef1234567890abcdef12');
      });

      test('parses plural commits URL', () {
        final ref = parseGitHubUrl(
          'https://github.com/owner/repo/commits/1234567890abcdef1234567890abcdef12345678',
        );
        expect(ref, isA<GitHubCommitReference>());
        final commit = ref as GitHubCommitReference;
        expect(commit.owner, 'owner');
        expect(commit.repo, 'repo');
        expect(commit.sha, '1234567890abcdef1234567890abcdef12345678');
      });

      test('normalizes SHA to lowercase', () {
        final ref = parseGitHubUrl(
          'https://github.com/owner/repo/commit/ABCDEF1234567890ABCDEF1234567890ABCDEF12',
        );
        expect(ref, isA<GitHubCommitReference>());
        final commit = ref as GitHubCommitReference;
        expect(commit.sha, 'abcdef1234567890abcdef1234567890abcdef12');
      });

      test('parses commit URL with trailing slash', () {
        final ref = parseGitHubUrl(
          'https://github.com/owner/repo/commit/abcdef1234567890abcdef1234567890abcdef12/',
        );
        expect(ref, isA<GitHubCommitReference>());
      });
    });

    group('unrecognized and non-GitHub URLs', () {
      test('returns null for non-GitHub domain', () {
        expect(
          parseGitHubUrl('https://gitlab.com/owner/repo/pull/123'),
          isNull,
        );
      });

      test('returns null for GitHub URL without PR/issue/commit path', () {
        expect(
          parseGitHubUrl('https://github.com/flutter/flutter'),
          isNull,
        );
      });

      test('returns null for arbitrary URL', () {
        expect(
          parseGitHubUrl('https://example.com/something'),
          isNull,
        );
      });

      test('returns null for empty string', () {
        expect(parseGitHubUrl(''), isNull);
      });

      test('returns null for malformed GitHub URL with missing number', () {
        expect(
          parseGitHubUrl('https://github.com/owner/repo/pull/'),
          isNull,
        );
      });
    });
  });

  // ---------------------------------------------------------------------------
  // parseGitHubAppScheme
  // ---------------------------------------------------------------------------
  group('parseGitHubAppScheme', () {
    test('parses valid control-center://pr URL', () {
      final ref = parseGitHubAppScheme(
        'control-center://pr/flutter/flutter/150',
      );
      expect(ref, isA<GitHubPrReference>());
      final pr = ref as GitHubPrReference;
      expect(pr.owner, 'flutter');
      expect(pr.repo, 'flutter');
      expect(pr.number, 150);
    });

    test('parses app scheme with hyphens in owner/repo', () {
      final ref = parseGitHubAppScheme(
        'control-center://pr/dart-lang/sdk/42',
      );
      expect(ref, isA<GitHubPrReference>());
      final pr = ref as GitHubPrReference;
      expect(pr.owner, 'dart-lang');
      expect(pr.repo, 'sdk');
      expect(pr.number, 42);
    });

    test('returns null for control-center URL without pr path', () {
      expect(
        parseGitHubAppScheme('control-center://issues/owner/repo/123'),
        isNull,
      );
    });

    test('returns null for URL with extra path segment', () {
      expect(
        parseGitHubAppScheme('control-center://pr/owner/repo/123/extra'),
        isNull,
      );
    });

    test('returns null for GitHub web URL (not app scheme)', () {
      expect(
        parseGitHubAppScheme(
          'https://github.com/flutter/flutter/pull/42',
        ),
        isNull,
      );
    });

    test('returns null for empty string', () {
      expect(parseGitHubAppScheme(''), isNull);
    });

    test('returns null for garbage input', () {
      expect(parseGitHubAppScheme('not-a-url'), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // parseAnyGitHubReference
  // ---------------------------------------------------------------------------
  group('parseAnyGitHubReference', () {
    test('parses GitHub web URL (first path via parseGitHubUrl)', () {
      final ref = parseAnyGitHubReference(
        'https://github.com/flutter/flutter/pull/42',
        currentOwner: 'unused',
        currentRepo: 'unused',
      );
      expect(ref, isA<GitHubPrReference>());
    });

    test('parses app scheme URL (fallback to parseGitHubAppScheme)', () {
      final ref = parseAnyGitHubReference(
        'control-center://pr/owner/repo/99',
        currentOwner: 'unused',
        currentRepo: 'unused',
      );
      expect(ref, isA<GitHubPrReference>());
      final pr = ref as GitHubPrReference;
      expect(pr.owner, 'owner');
      expect(pr.repo, 'repo');
      expect(pr.number, 99);
    });

    test('returns null when neither parser matches', () {
      expect(
        parseAnyGitHubReference(
          'https://example.com/not/github',
          currentOwner: 'ignored',
          currentRepo: 'ignored',
        ),
        isNull,
      );
    });

    test('prefers parseGitHubUrl result over parseGitHubAppScheme', () {
      // Even though parseGitHubAppScheme would also match something,
      // the web URL path should take priority.
      final ref = parseAnyGitHubReference(
        'https://github.com/flutter/flutter/pull/10',
        currentOwner: 'ignored',
        currentRepo: 'ignored',
      );
      expect(ref, isA<GitHubPrReference>());
      final pr = ref as GitHubPrReference;
      expect(pr.number, 10);
      expect(pr.owner, 'flutter');
    });
  });
}
