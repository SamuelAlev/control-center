import 'package:cc_server_core/src/forge/github_rate_budget.dart';
import 'package:test/test.dart';

void main() {
  late DateTime now;
  late GitHubRateBudget budget;

  setUp(() {
    now = DateTime.utc(2026, 11, 8, 12);
    budget = GitHubRateBudget(now: () => now);
  });

  Map<String, String> headers({
    required int remaining,
    int limit = 5000,
    Duration resetIn = const Duration(minutes: 30),
    String? resource,
  }) => {
    'X-RateLimit-Remaining': '$remaining',
    'X-RateLimit-Limit': '$limit',
    'x-ratelimit-reset': '${now.add(resetIn).millisecondsSinceEpoch ~/ 1000}',
    'x-ratelimit-resource': ?resource,
  };

  test('nothing observed is not low', () {
    expect(budget.isLow('ws1'), isFalse);
    expect(budget.lowUntil('ws1'), isNull);
  });

  test('under 15% of the limit is low, at or over is not', () {
    budget.observe('ws1', headers(remaining: 749));
    expect(budget.isLow('ws1'), isTrue);

    budget.observe('ws1', headers(remaining: 750));
    expect(budget.isLow('ws1'), isFalse);
  });

  test('header names are matched case-insensitively', () {
    budget.observe('ws1', {
      'X-RATELIMIT-REMAINING': '1',
      'X-RATELIMIT-LIMIT': '5000',
    });

    expect(budget.isLow('ws1'), isTrue);
  });

  test('a response without rate-limit headers changes nothing', () {
    budget
      ..observe('ws1', headers(remaining: 10))
      ..observe('ws1', {'content-type': 'application/json'});

    expect(budget.isLow('ws1'), isTrue);
  });

  test('a low reading stops counting once its window resets', () {
    budget.observe(
      'ws1',
      headers(remaining: 3, resetIn: const Duration(minutes: 10)),
    );
    expect(budget.isLow('ws1'), isTrue);
    expect(budget.lowUntil('ws1'), now.add(const Duration(minutes: 10)));

    now = now.add(const Duration(minutes: 10, seconds: 1));

    expect(budget.isLow('ws1'), isFalse);
  });

  test('resources are tracked apart: a low graphql bucket is low', () {
    budget
      ..observe('ws1', headers(remaining: 4900))
      ..observe('ws1', headers(remaining: 100, resource: 'graphql'))
      // A healthy core reading does not mask the low graphql one.
      ..observe('ws1', headers(remaining: 4800, resource: 'core'));

    expect(budget.isLow('ws1'), isTrue);
  });

  test('quotas are kept per workspace and per person', () {
    budget.observe('ws1', headers(remaining: 1), userId: 'u1');

    expect(budget.isLow('ws1', userId: 'u1'), isTrue);
    expect(budget.isLow('ws1'), isFalse, reason: 'the automation quota');
    expect(budget.isLow('ws2', userId: 'u1'), isFalse);

    budget.forgetWorkspace('ws1');
    expect(budget.isLow('ws1', userId: 'u1'), isFalse);
  });
}
