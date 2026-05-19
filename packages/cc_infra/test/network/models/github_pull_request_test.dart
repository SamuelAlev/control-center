import 'package:cc_domain/core/domain/entities/github_user.dart';
import 'package:cc_infra/src/network/models/github_pull_request.dart';
import 'package:cc_infra/src/network/models/github_reaction.dart';
import 'package:test/test.dart';

/// Exercises [GitHubPullRequest]'s dense fromJson/toJson surface — the SWR
/// cache round-trips this model, so a missing branch in either direction
/// would silently drop fields on reload. Focuses on the branches the shared
/// `github_models_test.dart` doesn't reach: reactions, author, assignees,
/// draft handling, and toJson re-reading.
void main() {
  GitHubPullRequest full() => GitHubPullRequest.fromJson({
    'number': 5,
    'title': 't',
    'body': 'b',
    'state': 'open',
    'draft': true,
    'user': {'login': 'sam', 'avatar_url': 'avatar', 'name': 'Sam'},
    'html_url': 'u',
    'node_id': 'n',
    'created_at': '2026-01-01T00:00:00Z',
    'updated_at': '2026-01-02T00:00:00Z',
    'merged_at': null,
    'head': {'sha': 'hs', 'ref': 'feature'},
    'base': {'sha': 'bs', 'ref': 'main'},
    'requested_reviewers': [
      {'login': 'rev1', 'avatar_url': 'a1'},
      {'login': 'rev2', 'avatar_url': 'a2'},
    ],
    'assignees': [
      {'login': 'asg', 'avatar_url': 'aa'},
    ],
    'reactions': {'total_count': 3, '+1': 2, 'heart': 1},
    'body_html': '<p>html</p>',
    'changed_files': 7,
    'commits': 4,
    'mergeable_state': 'clean',
  });

  group('GitHubPullRequest.fromJson (dense payload)', () {
    test('maps every field including nested author/reactions/reviewers', () {
      final pr = full();
      expect(pr.number, 5);
      expect(pr.isDraft, isTrue);
      expect(pr.userLogin, 'sam');
      expect(pr.author, isA<GitHubUser>());
      expect(pr.author!.name, 'Sam');
      expect(pr.headSha, 'hs');
      expect(pr.headRef, 'feature');
      expect(pr.baseSha, 'bs');
      expect(pr.baseRef, 'main');
      expect(pr.requestedReviewers, hasLength(2));
      expect(pr.requestedReviewers.first.login, 'rev1');
      expect(pr.assignees.single.login, 'asg');
      expect(pr.reactions, isA<GitHubReactionSummary>());
      expect(pr.reactions!.plusOne, 2);
      expect(pr.reactions!.heart, 1);
      expect(pr.bodyHtml, '<p>html</p>');
      expect(pr.changedFiles, 7);
      expect(pr.commitsCount, 4);
      expect(pr.mergeableState, 'clean');
      expect(pr.createdAt, DateTime.utc(2026, 1, 1));
      expect(pr.mergedAt, isNull);
    });

    test('requested_reviewers/assignees ignore non-map entries', () {
      final pr = GitHubPullRequest.fromJson({
        'number': 1,
        'requested_reviewers': [
          {'login': 'ok'},
          'not-a-map',
          42,
        ],
        'assignees': <dynamic>[],
      });
      expect(pr.requestedReviewers.single.login, 'ok');
      expect(pr.assignees, isEmpty);
    });

    test('rejects a non-map reactions object gracefully', () {
      final pr = GitHubPullRequest.fromJson({'reactions': 'oops'});
      expect(pr.reactions, isNull);
    });

    test(
      'falls back to nested pull_request.merged_at (search/issues shape)',
      () {
        final pr = GitHubPullRequest.fromJson({
          'number': 1,
          'state': 'closed',
          'merged_at': null,
          'pull_request': {'merged_at': '2026-03-03T00:00:00Z'},
        });
        expect(pr.mergedAt, DateTime.utc(2026, 3, 3));
      },
    );

    test('number coercion + null user → empty author', () {
      final pr = GitHubPullRequest.fromJson({'number': 9.0});
      expect(pr.number, 9);
      expect(pr.author, isNull);
      expect(pr.userLogin, '');
      expect(pr.headSha, '');
    });
  });

  group('GitHubPullRequest.toJson round-trip', () {
    test('re-reads a fully-populated PR', () {
      final restored = GitHubPullRequest.fromJson(full().toJson());
      expect(restored.number, 5);
      expect(restored.title, 't');
      expect(restored.body, 'b');
      expect(restored.state, 'open');
      expect(restored.isDraft, isTrue);
      expect(restored.userLogin, 'sam');
      expect(restored.author?.name, 'Sam');
      expect(restored.headSha, 'hs');
      expect(restored.baseSha, 'bs');
      expect(restored.headRef, 'feature');
      expect(restored.baseRef, 'main');
      expect(restored.requestedReviewers.map((u) => u.login).toList(), [
        'rev1',
        'rev2',
      ]);
      expect(restored.assignees.single.login, 'asg');
      expect(restored.reactions?.plusOne, 2);
      expect(restored.bodyHtml, '<p>html</p>');
      expect(restored.changedFiles, 7);
      expect(restored.commitsCount, 4);
      expect(restored.mergeableState, 'clean');
    });

    test('emits a synthetic user object when author is null', () {
      final pr = GitHubPullRequest.fromJson({'number': 1, 'user': null});
      final json = pr.toJson();
      expect((json['user'] as Map)['login'], '');
      // Optional fields are omitted at defaults.
      expect(json.containsKey('body_html'), isFalse);
      expect(json.containsKey('changed_files'), isFalse);
      expect(json.containsKey('commits'), isFalse);
      expect(json.containsKey('mergeable_state'), isFalse);
      expect(json.containsKey('reactions'), isFalse);
    });
  });
}
