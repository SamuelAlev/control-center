import 'package:cc_domain/features/model_routing/model_routing.dart';
import 'package:test/test.dart';

UsageReport _report(
  String provider,
  DateTime fetchedAt, {
  required double primaryUsed,
  required double secondaryUsed,
  DateTime? primaryReset,
  DateTime? secondaryReset,
}) => UsageReport(
  provider: provider,
  fetchedAt: fetchedAt,
  limits: [
    UsageLimit(
      id: '5h',
      label: '5 hour',
      scope: UsageScope(provider: provider),
      window: UsageWindow(
        id: '5h',
        label: '5 hour',
        durationMs: const Duration(hours: 5).inMilliseconds,
        resetsAt: primaryReset,
      ),
      amount: UsageAmount(usedFraction: primaryUsed),
    ),
    UsageLimit(
      id: '7d',
      label: '7 day',
      scope: UsageScope(provider: provider),
      window: UsageWindow(
        id: '7d',
        label: '7 day',
        durationMs: const Duration(days: 7).inMilliseconds,
        resetsAt: secondaryReset,
      ),
      amount: UsageAmount(usedFraction: secondaryUsed),
    ),
  ],
);

void main() {
  final now = DateTime.utc(2025, 12, 1, 12);
  const ranker = CredentialRanker();

  const accountA = CredentialAccount(
    id: 'a',
    providerId: 'anthropic',
    email: 'a@x.com',
    order: 0,
  );
  const accountB = CredentialAccount(
    id: 'b',
    providerId: 'anthropic',
    email: 'b@x.com',
    order: 1,
  );

  test('ranks the account with the most remaining headroom first', () {
    // A is heavily used (80% on 7d), B has plenty of room (10%).
    final result = ranker.rank(
      [accountA, accountB],
      now: now,
      reports: {
        'a': _report(
          'anthropic',
          now,
          primaryUsed: 0.5,
          secondaryUsed: 0.8,
          secondaryReset: now.add(const Duration(days: 3)),
        ),
        'b': _report(
          'anthropic',
          now,
          primaryUsed: 0.2,
          secondaryUsed: 0.1,
          secondaryReset: now.add(const Duration(days: 6)),
        ),
      },
    );
    expect(result.best!.id, 'b');
    expect(result.ordered.map((a) => a.id), ['b', 'a']);
  });

  test('an exhausted account is blocked and sorts last', () {
    final reset = now.add(const Duration(hours: 2));
    final result = ranker.rank(
      [accountA, accountB],
      now: now,
      reports: {
        'a': _report(
          'anthropic',
          now,
          primaryUsed: 1.0,
          secondaryUsed: 1.0,
          primaryReset: reset,
        ),
        'b': _report('anthropic', now, primaryUsed: 0.3, secondaryUsed: 0.3),
      },
    );
    expect(result.best!.id, 'b');
    expect(result.ordered.last.id, 'a');
    expect(result.blocks.single.accountId, 'a');
    expect(result.blocks.single.blockedUntil, reset);
  });

  test('both blocked → earlier unblock time first', () {
    final soon = now.add(const Duration(minutes: 30));
    final later = now.add(const Duration(hours: 4));
    final result = ranker.rank(
      [accountA, accountB],
      now: now,
      reports: {
        'a': _report(
          'anthropic',
          now,
          primaryUsed: 1.0,
          secondaryUsed: 1.0,
          primaryReset: later,
        ),
        'b': _report(
          'anthropic',
          now,
          primaryUsed: 1.0,
          secondaryUsed: 1.0,
          primaryReset: soon,
        ),
      },
    );
    expect(result.ordered.first.id, 'b'); // unblocks sooner
  });

  test('priority boost wins over headroom', () {
    const proAccount = CredentialAccount(
      id: 'pro',
      providerId: 'anthropic',
      priorityBoost: true,
      order: 1,
    );
    final result = ranker.rank(
      [accountA, proAccount],
      now: now,
      reports: {
        'a': _report('anthropic', now, primaryUsed: 0.1, secondaryUsed: 0.1),
        'pro': _report('anthropic', now, primaryUsed: 0.7, secondaryUsed: 0.7),
      },
    );
    expect(result.best!.id, 'pro');
  });

  test('canReusePreferred keeps a healthy warm credential', () {
    final healthy = _report(
      'anthropic',
      now,
      primaryUsed: 0.3,
      secondaryUsed: 0.3,
    );
    expect(
      ranker.canReusePreferred(accountA, report: healthy, now: now),
      isTrue,
    );
    final exhausted = _report(
      'anthropic',
      now,
      primaryUsed: 1.0,
      secondaryUsed: 1.0,
    );
    expect(
      ranker.canReusePreferred(accountA, report: exhausted, now: now),
      isFalse,
    );
  });

  test('a low-usage account outranks one with no usage data (neutral 0.5)', () {
    // Account B has no report → its drain/fraction default to 0.5 (neutral),
    // so a genuinely low-usage account A (0.1) ranks ahead of it.
    final result = ranker.rank(
      [accountA, accountB],
      now: now,
      reports: {
        'a': _report('anthropic', now, primaryUsed: 0.1, secondaryUsed: 0.1),
        // 'b' deliberately absent → no signal.
      },
    );
    expect(result.best!.id, 'a');
  });

  test('session id deterministically breaks a tie', () {
    // Identical metrics → leading tie; session id picks one stably.
    final reports = {
      'a': _report('anthropic', now, primaryUsed: 0.5, secondaryUsed: 0.5),
      'b': _report('anthropic', now, primaryUsed: 0.5, secondaryUsed: 0.5),
    };
    final first = ranker.rank(
      [accountA, accountB],
      now: now,
      reports: reports,
      sessionId: 'session-xyz',
    );
    final again = ranker.rank(
      [accountA, accountB],
      now: now,
      reports: reports,
      sessionId: 'session-xyz',
    );
    expect(first.best!.id, again.best!.id); // stable across calls
  });
}
