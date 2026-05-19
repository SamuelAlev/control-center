import 'package:cc_infra/src/network/models/github_viewer_activity.dart';
import 'package:test/test.dart';

void main() {
  group('GitHubViewerPr.fromNode', () {
    test('decodes the identity fields', () {
      final pr = GitHubViewerPr.fromNode(const {
        'number': 42,
        'title': 'Add widgets',
        'updatedAt': '2026-01-02T03:04:05Z',
        'repository': {'nameWithOwner': 'acme/widgets'},
      });

      expect(pr, isNotNull);
      expect(pr!.repoFullName, 'acme/widgets');
      expect(pr.number, 42);
      expect(pr.title, 'Add widgets');
      expect(pr.key, 'acme/widgets#42');
      expect(pr.owner, 'acme');
      expect(pr.name, 'widgets');
    });

    test('decodes the merger, so a client can drop its own merge', () {
      final pr = GitHubViewerPr.fromNode(const {
        'number': 42,
        'repository': {'nameWithOwner': 'acme/widgets'},
        'mergedBy': {'login': 'octocat'},
      });

      expect(pr?.mergedByLogin, 'octocat');
    });

    test('an unmerged PR has no merger', () {
      // `mergedBy` is null on every open PR, and on a merge GitHub attributes
      // to no user (a deleted account). Unknown must stay null so the client's
      // self-suppression degrades to notifying rather than guessing.
      final pr = GitHubViewerPr.fromNode(const {
        'number': 42,
        'repository': {'nameWithOwner': 'acme/widgets'},
        'mergedBy': null,
      });

      expect(pr, isNotNull);
      expect(pr!.mergedByLogin, isNull);
    });

    test('a node missing its identity fields decodes to null', () {
      expect(GitHubViewerPr.fromNode(const {}), isNull);
      expect(
        GitHubViewerPr.fromNode(const {
          'number': 0,
          'repository': {'nameWithOwner': 'acme/widgets'},
        }),
        isNull,
      );
    });

    test('the merger participates in equality', () {
      const base = GitHubViewerPr(
        repoFullName: 'acme/widgets',
        number: 42,
        title: 'Add widgets',
      );
      const merged = GitHubViewerPr(
        repoFullName: 'acme/widgets',
        number: 42,
        title: 'Add widgets',
        mergedByLogin: 'octocat',
      );
      expect(base, isNot(equals(merged)));
      expect(base.hashCode, isNot(equals(merged.hashCode)));
      expect(merged, equals(merged));
    });
  });
}
