// ignore_for_file: avoid_dynamic_calls

import 'package:control_center/core/network/models/github_pull_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GitHubPullRequest', () {
    final baseJson = <String, dynamic>{
      'number': 42,
      'title': 'Add feature X',
      'body': 'This PR adds feature X',
      'state': 'open',
      'draft': false,
      'user': <String, dynamic>{
        'login': 'dev1',
        'avatar_url': 'https://avatars.githubusercontent.com/u/1?v=4',
      },
      'html_url': 'https://github.com/owner/repo/pull/42',
      'node_id': 'PR_kw123',
      'created_at': '2024-01-15T10:00:00Z',
      'updated_at': '2024-01-16T12:00:00Z',
      'merged_at': null,
      'head': <String, dynamic>{'sha': 'abc123def456', 'ref': 'feature/x'},
      'base': <String, dynamic>{'ref': 'main'},
      'requested_reviewers': <dynamic>[],
      'assignees': <dynamic>[],
    };

    test('fromJson parses all fields', () {
      final pr = GitHubPullRequest.fromJson(baseJson);
      expect(pr.number, 42);
      expect(pr.title, 'Add feature X');
      expect(pr.body, 'This PR adds feature X');
      expect(pr.state, 'open');
      expect(pr.isDraft, false);
      expect(pr.userLogin, 'dev1');
      expect(pr.htmlUrl, 'https://github.com/owner/repo/pull/42');
      expect(pr.nodeId, 'PR_kw123');
      expect(pr.author, isNotNull);
      expect(pr.author!.login, 'dev1');
      expect(pr.createdAt, isNotNull);
      expect(pr.updatedAt, isNotNull);
      expect(pr.mergedAt, isNull);
      expect(pr.headSha, 'abc123def456');
      expect(pr.baseRef, 'main');
      expect(pr.headRef, 'feature/x');
      expect(pr.requestedReviewers, isEmpty);
      expect(pr.assignees, isEmpty);
    });

    test('fromJson handles draft PR', () {
      final json = Map<String, dynamic>.from(baseJson)..['draft'] = true;
      final pr = GitHubPullRequest.fromJson(json);
      expect(pr.isDraft, true);
    });

    test('fromJson handles merged PR', () {
      final json = Map<String, dynamic>.from(baseJson)
        ..['merged_at'] = '2024-01-17T08:00:00Z';
      final pr = GitHubPullRequest.fromJson(json);
      expect(pr.mergedAt, isNotNull);
      expect(pr.mergedAt!.day, 17);
    });

    test('fromJson handles closed state', () {
      final json = Map<String, dynamic>.from(baseJson)..['state'] = 'closed';
      final pr = GitHubPullRequest.fromJson(json);
      expect(pr.state, 'closed');
    });

    test('fromJson handles missing optional fields', () {
      final json = <String, dynamic>{
        'number': 1,
        'title': null,
        'body': null,
        'state': null,
        'draft': null,
        'user': null,
        'html_url': null,
        'node_id': null,
        'head': null,
        'base': null,
      };
      final pr = GitHubPullRequest.fromJson(json);
      expect(pr.number, 1);
      expect(pr.title, '');
      expect(pr.body, '');
      expect(pr.state, '');
      expect(pr.isDraft, false);
      expect(pr.userLogin, '');
      expect(pr.htmlUrl, '');
      expect(pr.nodeId, '');
      expect(pr.headSha, '');
      expect(pr.baseRef, '');
      expect(pr.headRef, '');
    });

    test('fromJson parses requested reviewers', () {
      final json = Map<String, dynamic>.from(baseJson)
        ..['requested_reviewers'] = <dynamic>[
          <String, dynamic>{
            'login': 'reviewer1',
            'avatar_url': 'https://example.com/avatar1.png',
          },
          <String, dynamic>{
            'login': 'reviewer2',
            'avatar_url': 'https://example.com/avatar2.png',
          },
        ];
      final pr = GitHubPullRequest.fromJson(json);
      expect(pr.requestedReviewers.length, 2);
      expect(pr.requestedReviewers[0].login, 'reviewer1');
      expect(pr.requestedReviewers[1].login, 'reviewer2');
    });

    test('fromJson handles non-list requested reviewers', () {
      final json = Map<String, dynamic>.from(baseJson)
        ..['requested_reviewers'] = 'not-a-list';
      final pr = GitHubPullRequest.fromJson(json);
      expect(pr.requestedReviewers, isEmpty);
    });

    test('fromJson parses assignees', () {
      final json = Map<String, dynamic>.from(baseJson)
        ..['assignees'] = <dynamic>[
          <String, dynamic>{
            'login': 'assignee1',
            'avatar_url': 'https://example.com/avatar.png',
          },
        ];
      final pr = GitHubPullRequest.fromJson(json);
      expect(pr.assignees.length, 1);
      expect(pr.assignees[0].login, 'assignee1');
    });

    test('toJson round-trip with empty lists', () {
      const pr = GitHubPullRequest(
        number: 1,
        title: 'Test',
        body: 'Body',
        state: 'open',
        isDraft: false,
        userLogin: 'dev',
        htmlUrl: 'https://example.com',
        nodeId: 'N1',
        headSha: 'abc',
        baseRef: 'main',
        headRef: 'feature',
      );
      final json = pr.toJson();
      final restored = GitHubPullRequest.fromJson(json);
      expect(restored.number, 1);
      expect(restored.title, 'Test');
      expect(restored.body, 'Body');
      expect(restored.state, 'open');
      expect(restored.isDraft, false);
      expect(restored.userLogin, 'dev');
      expect(restored.headSha, 'abc');
      expect(restored.baseRef, 'main');
      expect(restored.headRef, 'feature');
    });

    test('toJson round-trip with all fields', () {
      const pr = GitHubPullRequest(
        number: 42,
        title: 'Add feature',
        body: 'Description',
        state: 'open',
        isDraft: false,
        userLogin: 'user',
        htmlUrl: 'https://example.com/pr/42',
        nodeId: 'node-42',
        headSha: 'abcd1234',
        baseRef: 'main',
        headRef: 'feature/x',
        requestedReviewers: [],
        assignees: [],
      );
      final json = pr.toJson();
      final restored = GitHubPullRequest.fromJson(json);
      expect(restored.number, pr.number);
      expect(restored.title, pr.title);
      expect(restored.body, pr.body);
      expect(restored.state, pr.state);
      expect(restored.htmlUrl, pr.htmlUrl);
      expect(restored.nodeId, pr.nodeId);
      expect(restored.headSha, pr.headSha);
      expect(restored.baseRef, pr.baseRef);
      expect(restored.headRef, pr.headRef);
    });

    test('fromJson handles number as double', () {
      final json = <String, dynamic>{
        'number': 5.0,
        'title': 'Float number',
        'body': '',
        'state': '',
        'draft': false,
        'user': null,
        'html_url': '',
        'node_id': '',
        'head': null,
        'base': null,
      };
      final pr = GitHubPullRequest.fromJson(json);
      expect(pr.number, 5);
    });

    test('fromJson handles empty head and base maps', () {
      final json = <String, dynamic>{
        'number': 1,
        'title': '',
        'body': '',
        'state': '',
        'draft': false,
        'user': null,
        'html_url': '',
        'node_id': '',
        'head': <String, dynamic>{},
        'base': <String, dynamic>{},
      };
      final pr = GitHubPullRequest.fromJson(json);
      expect(pr.headSha, '');
      expect(pr.headRef, '');
      expect(pr.baseRef, '');
    });

    test('fromJson handles user without login', () {
      final json = <String, dynamic>{
        'number': 1,
        'title': '',
        'body': '',
        'state': '',
        'draft': false,
        'user': <String, dynamic>{'avatar_url': ''},
        'html_url': '',
        'node_id': '',
        'head': null,
        'base': null,
      };
      final pr = GitHubPullRequest.fromJson(json);
      expect(pr.userLogin, '');
      expect(pr.author, isNotNull);
      expect(pr.author!.login, '');
    });

    test('fromJson handles invalid date strings', () {
      final json = <String, dynamic>{
        'number': 1,
        'title': '',
        'body': '',
        'state': '',
        'draft': false,
        'user': null,
        'html_url': '',
        'node_id': '',
        'head': null,
        'base': null,
        'created_at': 'not-a-date',
        'updated_at': 'also-not-a-date',
        'merged_at': 'nope',
      };
      final pr = GitHubPullRequest.fromJson(json);
      expect(pr.createdAt, isNull);
      expect(pr.updatedAt, isNull);
      expect(pr.mergedAt, isNull);
    });

    test('toJson with author preserves user data', () {
      const pr = GitHubPullRequest(
        number: 1,
        title: 'T',
        body: 'B',
        state: 'open',
        isDraft: false,
        userLogin: 'dev',
        htmlUrl: 'url',
        nodeId: 'n',
        headSha: 'sha',
        baseRef: 'm',
        headRef: 'f',
      );
      final json = pr.toJson();
      expect(json['user'], isA<Map<String, dynamic>>());
      expect(json['user']['login'], 'dev');
    });

    test('toJson handles created/updated/merged dates', () {
      final now = DateTime(2024, 1, 15, 10, 0, 0);
      final pr = GitHubPullRequest(
        number: 1,
        title: 'T',
        body: 'B',
        state: 'open',
        isDraft: false,
        userLogin: 'dev',
        htmlUrl: 'url',
        nodeId: 'n',
        headSha: 'sha',
        baseRef: 'm',
        headRef: 'f',
        createdAt: now,
        updatedAt: now,
        mergedAt: now,
      );
      final json = pr.toJson();
      expect(json['created_at'], contains('2024-01-15'));
      expect(json['updated_at'], contains('2024-01-15'));
      expect(json['merged_at'], contains('2024-01-15'));
    });

    test('toJson with empty sha and refs', () {
      const pr = GitHubPullRequest(
        number: 1,
        title: '',
        body: '',
        state: '',
        isDraft: false,
        userLogin: '',
        htmlUrl: '',
        nodeId: '',
        headSha: '',
        baseRef: '',
        headRef: '',
      );
      final json = pr.toJson();
      expect(json['head']['sha'], '');
      expect(json['head']['ref'], '');
      expect(json['base']['ref'], '');
    });
  });
}
