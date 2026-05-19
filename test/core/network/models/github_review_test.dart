import 'package:control_center/core/network/models/github_review.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GitHubReviewState', () {
    test('has all expected values', () {
      expect(GitHubReviewState.values.length, 6);
      expect(GitHubReviewState.values, contains(GitHubReviewState.approved));
      expect(
        GitHubReviewState.values,
        contains(GitHubReviewState.changesRequested),
      );
      expect(GitHubReviewState.values, contains(GitHubReviewState.commented));
      expect(GitHubReviewState.values, contains(GitHubReviewState.dismissed));
      expect(GitHubReviewState.values, contains(GitHubReviewState.pending));
      expect(GitHubReviewState.values, contains(GitHubReviewState.unknown));
    });
  });

  group('GitHubReview', () {
    final baseJson = <String, dynamic>{
      'id': 12345,
      'state': 'APPROVED',
      'body': 'LGTM!',
      'submitted_at': '2024-01-15T10:00:00Z',
      'user': <String, dynamic>{
        'login': 'reviewer1',
        'avatar_url': 'https://avatars.githubusercontent.com/u/2?v=4',
      },
    };

    test('fromJson parses approved review', () {
      final review = GitHubReview.fromJson(baseJson);
      expect(review.id, 12345);
      expect(review.state, GitHubReviewState.approved);
      expect(review.body, 'LGTM!');
      expect(review.submittedAt, isNotNull);
      expect(review.user, isNotNull);
      expect(review.user!.login, 'reviewer1');
    });

    test('fromJson parses changes_requested', () {
      final json = <String, dynamic>{
        'id': 1,
        'state': 'CHANGES_REQUESTED',
        'body': 'Please fix',
        'submitted_at': null,
      };
      final review = GitHubReview.fromJson(json);
      expect(review.state, GitHubReviewState.changesRequested);
      expect(review.body, 'Please fix');
    });

    test('fromJson parses commented', () {
      final json = <String, dynamic>{
        'id': 2,
        'state': 'COMMENTED',
        'body': 'Just a comment',
      };
      final review = GitHubReview.fromJson(json);
      expect(review.state, GitHubReviewState.commented);
    });

    test('fromJson parses dismissed', () {
      final json = <String, dynamic>{'id': 3, 'state': 'DISMISSED', 'body': ''};
      final review = GitHubReview.fromJson(json);
      expect(review.state, GitHubReviewState.dismissed);
    });

    test('fromJson parses pending', () {
      final json = <String, dynamic>{'id': 4, 'state': 'PENDING', 'body': ''};
      final review = GitHubReview.fromJson(json);
      expect(review.state, GitHubReviewState.pending);
    });

    test('fromJson parses unknown state', () {
      final json = <String, dynamic>{
        'id': 5,
        'state': 'SOMETHING_ELSE',
        'body': '',
      };
      final review = GitHubReview.fromJson(json);
      expect(review.state, GitHubReviewState.unknown);
    });

    test('fromJson handles null state', () {
      final json = <String, dynamic>{'id': 6, 'state': null, 'body': ''};
      final review = GitHubReview.fromJson(json);
      expect(review.state, GitHubReviewState.unknown);
    });

    test('fromJson handles missing fields', () {
      final json = <String, dynamic>{};
      final review = GitHubReview.fromJson(json);
      expect(review.id, 0);
      expect(review.state, GitHubReviewState.unknown);
      expect(review.body, '');
      expect(review.submittedAt, isNull);
      expect(review.user, isNull);
    });

    test('toJson serializes all fields', () {
      final review = GitHubReview.fromJson(baseJson);
      final json = review.toJson();
      expect(json['id'], 12345);
      expect(json['state'], 'APPROVED');
      expect(json['body'], 'LGTM!');
      expect(json['user'], isA<Map<String, dynamic>>());
    });

    test('toJson handles unknown state as null', () {
      const review = GitHubReview(
        id: 1,
        state: GitHubReviewState.unknown,
        body: '',
        submittedAt: null,
      );
      final json = review.toJson();
      expect(json['state'], isNull);
    });

    test('fromJson toJson round-trip approved', () {
      const review = GitHubReview(
        id: 42,
        state: GitHubReviewState.approved,
        body: 'Approved!',
        submittedAt: null,
      );
      final json = review.toJson();
      final restored = GitHubReview.fromJson(json);
      expect(restored.id, review.id);
      expect(restored.state, review.state);
      expect(restored.body, review.body);
    });

    test('fromJson toJson round-trip changes_requested', () {
      const review = GitHubReview(
        id: 43,
        state: GitHubReviewState.changesRequested,
        body: 'Needs work',
        submittedAt: null,
      );
      final json = review.toJson();
      final restored = GitHubReview.fromJson(json);
      expect(restored.state, GitHubReviewState.changesRequested);
    });

    test('fromJson toJson round-trip dismissed', () {
      const review = GitHubReview(
        id: 44,
        state: GitHubReviewState.dismissed,
        body: 'Dismissed reason',
        submittedAt: null,
      );
      final json = review.toJson();
      final restored = GitHubReview.fromJson(json);
      expect(restored.state, GitHubReviewState.dismissed);
    });

    test('fromJson toJson round-trip pending', () {
      const review = GitHubReview(
        id: 45,
        state: GitHubReviewState.pending,
        body: '',
        submittedAt: null,
      );
      final json = review.toJson();
      final restored = GitHubReview.fromJson(json);
      expect(restored.state, GitHubReviewState.pending);
    });

    test('fromJson toJson round-trip commented', () {
      const review = GitHubReview(
        id: 46,
        state: GitHubReviewState.commented,
        body: 'Nice!',
        submittedAt: null,
      );
      final json = review.toJson();
      final restored = GitHubReview.fromJson(json);
      expect(restored.state, GitHubReviewState.commented);
    });

    test('fromJson case-insensitive state', () {
      final json = <String, dynamic>{'id': 1, 'state': 'approved', 'body': ''};
      final review = GitHubReview.fromJson(json);
      expect(review.state, GitHubReviewState.approved);
    });
  });
}
