import 'dart:async';

import 'package:cc_domain/features/settings/domain/entities/claude_account.dart';
import 'package:control_center/features/settings/providers/claude_account_providers.dart';
import 'package:control_center/features/settings/providers/claude_sign_in_watch.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_claude_accounts_repository.dart';

const _signedOut = ClaudeAccount(id: 'work', label: 'Work');

/// A lapsed sign-in the CLI renews by itself: the host still calls it signed
/// in.
final _lapsed = ClaudeAccount(
  id: 'personal',
  label: 'Personal',
  loggedIn: true,
  credentialExpiresAt: DateTime.utc(2000),
);

void main() {
  late FakeClaudeAccountsRepository repo;
  late ProviderContainer container;

  /// Every set the watch reported, in order.
  late List<Set<String>> reported;

  /// Starts watching, as an open sign-in surface does, and lets the first
  /// reading land. `testWidgets` is used for its clock: time only moves when
  /// the test pumps.
  Future<ProviderSubscription<Set<String>>> watch(
    WidgetTester tester, {
    List<ClaudeAccount> accounts = const [_signedOut],
  }) async {
    repo = FakeClaudeAccountsRepository(accounts: accounts);
    container = ProviderContainer(
      overrides: [claudeAccountsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    reported = [];
    // The roster is on screen behind the surface.
    container.listen(claudeAccountsProvider, (_, _) {});
    final subscription = container.listen(
      claudeSignInsProvider,
      (_, now) => reported.add(now),
    );
    await tester.pump();
    return subscription;
  }

  Future<void> tick(WidgetTester tester, [int times = 1]) async {
    for (var i = 0; i < times; i++) {
      await tester.pump(claudeSignInPollInterval);
      await tester.pump();
    }
  }

  testWidgets('reads at once, then every two seconds', (tester) async {
    await watch(tester);
    expect(repo.stateReads, 1);

    await tick(tester, 3);

    expect(repo.stateReads, 4);
    expect(reported, isEmpty);
  });

  testWidgets('reports a finished sign-in and re-reads the roster', (
    tester,
  ) async {
    await watch(tester);
    expect(repo.rosterReads, 1);

    repo.signIn('work');
    await tick(tester);

    expect(reported, [
      {'work'},
    ]);
    expect(repo.rosterReads, 2);
    expect(
      container.read(claudeAccountsProvider).value!.single.account.loggedIn,
      isTrue,
    );

    // Reported once: the same credential is not a second sign-in.
    await tick(tester, 3);
    expect(reported, hasLength(1));
    expect(repo.rosterReads, 2);
  });

  testWidgets('an account that was fine before the watch is not reported', (
    tester,
  ) async {
    await watch(tester, accounts: [_lapsed]);

    await tick(tester, 3);
    expect(reported, isEmpty);

    // Signing it in again writes another credential, and that is reported.
    repo.signIn('personal');
    await tick(tester);
    expect(reported, [
      {'personal'},
    ]);
  });

  testWidgets('keeps what it reported when the next account follows', (
    tester,
  ) async {
    await watch(tester, accounts: [_signedOut, _lapsed]);

    repo.signIn('work');
    await tick(tester);
    repo.signIn('personal');
    await tick(tester);

    expect(reported, [
      {'work'},
      {'work', 'personal'},
    ]);
    expect(repo.rosterReads, 3);
  });

  testWidgets('a reading that fails is skipped, not a verdict', (tester) async {
    await watch(tester);

    repo.stateFailure = StateError('server restarting');
    repo.signIn('work');
    await tick(tester, 2);
    expect(reported, isEmpty);

    repo.stateFailure = null;
    await tick(tester);
    expect(reported, [
      {'work'},
    ]);
  });

  testWidgets('a slow answer is not asked for twice', (tester) async {
    await watch(tester);
    repo.stateGate = Completer<void>();

    await tick(tester, 4);
    expect(repo.stateReads, 2, reason: 'one reading in flight, none queued');

    repo.stateGate!.complete();
    repo.stateGate = null;
    await tick(tester);
    expect(repo.stateReads, 3);
  });

  testWidgets('asks nothing once nobody watches', (tester) async {
    final subscription = await watch(tester);
    await tick(tester);
    final asked = repo.stateReads;

    subscription.close();
    await tester.pump();
    await tick(tester, 5);

    expect(repo.stateReads, asked);
  });

  testWidgets('each watch starts from its own first reading', (tester) async {
    final first = await watch(tester);
    repo.signIn('work');
    await tick(tester);
    expect(reported, hasLength(1));
    first.close();
    await tester.pump();
    await tick(tester);

    // The next surface opens on an account that is already signed in.
    final again = <Set<String>>[];
    container.listen(claudeSignInsProvider, (_, now) => again.add(now));
    await tester.pump();
    await tick(tester, 2);

    expect(container.read(claudeSignInsProvider), isEmpty);
    expect(again, isEmpty);
  });
}
