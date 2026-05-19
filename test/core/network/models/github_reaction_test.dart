import 'package:control_center/core/network/models/github_reaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GitHubReactionSummary', () {
    test(
      'fromJson parses all reaction types',
      timeout: const Timeout.factor(2),
      () {
        final json = <String, dynamic>{
          'total_count': 42,
          '+1': 10,
          '-1': 2,
          'laugh': 5,
          'hooray': 8,
          'confused': 1,
          'heart': 7,
          'rocket': 6,
          'eyes': 3,
        };
        final summary = GitHubReactionSummary.fromJson(json);

        expect(summary.totalCount, 42);
        expect(summary.plusOne, 10);
        expect(summary.minusOne, 2);
        expect(summary.laugh, 5);
        expect(summary.hooray, 8);
        expect(summary.confused, 1);
        expect(summary.heart, 7);
        expect(summary.rocket, 6);
        expect(summary.eyes, 3);
      },
    );

    test(
      'fromJson handles missing fields with defaults',
      timeout: const Timeout.factor(2),
      () {
        final summary = GitHubReactionSummary.fromJson({});

        expect(summary.totalCount, 0);
        expect(summary.plusOne, 0);
        expect(summary.minusOne, 0);
        expect(summary.laugh, 0);
        expect(summary.hooray, 0);
        expect(summary.confused, 0);
        expect(summary.heart, 0);
        expect(summary.rocket, 0);
        expect(summary.eyes, 0);
      },
    );

    test(
      'fromJson handles null values',
      timeout: const Timeout.factor(2),
      () {
        final json = <String, dynamic>{
          'total_count': null,
          '+1': null,
          '-1': null,
          'laugh': null,
          'hooray': null,
          'confused': null,
          'heart': null,
          'rocket': null,
          'eyes': null,
        };
        final summary = GitHubReactionSummary.fromJson(json);

        expect(summary.totalCount, 0);
        expect(summary.plusOne, 0);
        expect(summary.minusOne, 0);
        expect(summary.heart, 0);
      },
    );

    test(
      'toJson serializes all reaction types',
      timeout: const Timeout.factor(2),
      () {
        const summary = GitHubReactionSummary(
          totalCount: 15,
          plusOne: 5,
          minusOne: 1,
          laugh: 2,
          hooray: 3,
          confused: 0,
          heart: 2,
          rocket: 1,
          eyes: 1,
        );
        final json = summary.toJson();

        expect(json['total_count'], 15);
        expect(json['+1'], 5);
        expect(json['-1'], 1);
        expect(json['laugh'], 2);
        expect(json['hooray'], 3);
        expect(json['confused'], 0);
        expect(json['heart'], 2);
        expect(json['rocket'], 1);
        expect(json['eyes'], 1);
      },
    );

    test(
      'fromJson toJson round-trip',
      timeout: const Timeout.factor(2),
      () {
        const original = GitHubReactionSummary(
          totalCount: 100,
          plusOne: 30,
          minusOne: 5,
          laugh: 10,
          hooray: 15,
          confused: 2,
          heart: 20,
          rocket: 12,
          eyes: 6,
        );
        final json = original.toJson();
        final restored = GitHubReactionSummary.fromJson(json);

        expect(restored.totalCount, original.totalCount);
        expect(restored.plusOne, original.plusOne);
        expect(restored.minusOne, original.minusOne);
        expect(restored.laugh, original.laugh);
        expect(restored.hooray, original.hooray);
        expect(restored.confused, original.confused);
        expect(restored.heart, original.heart);
        expect(restored.rocket, original.rocket);
        expect(restored.eyes, original.eyes);
      },
    );

    test(
      'default constructor zeros all fields',
      timeout: const Timeout.factor(2),
      () {
        const summary = GitHubReactionSummary();
        expect(summary.totalCount, 0);
        expect(summary.plusOne, 0);
        expect(summary.minusOne, 0);
        expect(summary.laugh, 0);
        expect(summary.hooray, 0);
        expect(summary.confused, 0);
        expect(summary.heart, 0);
        expect(summary.rocket, 0);
        expect(summary.eyes, 0);
      },
    );
  });

  group('GitHubReaction', () {
    test(
      'fromJson parses all fields including user',
      timeout: const Timeout.factor(2),
      () {
        final json = <String, dynamic>{
          'id': 42,
          'content': 'heart',
          'user': {
            'login': 'octocat',
            'avatar_url': 'https://example.com/a.png',
          },
        };
        final reaction = GitHubReaction.fromJson(json);

        expect(reaction.id, 42);
        expect(reaction.content, 'heart');
        expect(reaction.user, isNotNull);
        expect(reaction.user!.login, 'octocat');
        expect(reaction.user!.avatarUrl, 'https://example.com/a.png');
      },
    );

    test(
      'fromJson handles null user',
      timeout: const Timeout.factor(2),
      () {
        final json = <String, dynamic>{
          'id': 10,
          'content': '+1',
          'user': null,
        };
        final reaction = GitHubReaction.fromJson(json);

        expect(reaction.id, 10);
        expect(reaction.content, '+1');
        expect(reaction.user, isNull);
      },
    );

    test(
      'fromJson handles missing fields with defaults',
      timeout: const Timeout.factor(2),
      () {
        final json = <String, dynamic>{};
        final reaction = GitHubReaction.fromJson(json);

        expect(reaction.id, 0);
        expect(reaction.content, '');
        expect(reaction.user, isNull);
      },
    );

    test(
      'fromJson handles user as non-map gracefully',
      timeout: const Timeout.factor(2),
      () {
        final json = <String, dynamic>{
          'id': 5,
          'content': 'rocket',
          'user': 'not-a-map',
        };
        final reaction = GitHubReaction.fromJson(json);

        expect(reaction.id, 5);
        expect(reaction.content, 'rocket');
        expect(reaction.user, isNull);
      },
    );

    test(
      'holds all valid content types',
      timeout: const Timeout.factor(2),
      () {
        const contents = ['+1', '-1', 'laugh', 'hooray', 'confused', 'heart', 'rocket', 'eyes'];
        for (final content in contents) {
          final reaction = GitHubReaction(id: 1, content: content);
          expect(reaction.content, content);
        }
      },
    );
  });
}
