import 'package:cc_domain/core/domain/value_objects/account_pool.dart';
import 'package:test/test.dart';

AccountAvailability _avail(
  String id, {
  bool signedIn = true,
  bool spent = false,
  DateTime? availableAt,
}) => AccountAvailability(
  id: id,
  signedIn: signedIn,
  spent: spent,
  availableAt: availableAt,
);

Map<String, AccountAvailability> _map(
  List<AccountAvailability> list,
) => {for (final a in list) a.id: a};

void main() {
  group('AccountRotationStrategy', () {
    test('the wire spelling is stable and independent of the Dart name', () {
      // Renaming a Dart symbol must not silently re-point every workspace's
      // stored pool, so the persisted string is pinned here explicitly.
      expect(AccountRotationStrategy.pinned.wire, 'pinned');
      expect(AccountRotationStrategy.roundRobin.wire, 'round_robin');
      expect(AccountRotationStrategy.serial.wire, 'serial');
      for (final s in AccountRotationStrategy.values) {
        expect(AccountRotationStrategy.fromWire(s.wire), s);
      }
    });

    test('an unknown or absent strategy degrades to pinned', () {
      // A pool written by a newer build must not make an older one rotate in a
      // way it does not implement.
      expect(AccountRotationStrategy.fromWire(null), AccountRotationStrategy.pinned);
      expect(
        AccountRotationStrategy.fromWire('weighted-magic'),
        AccountRotationStrategy.pinned,
      );
    });
  });

  group('AccountPool json', () {
    test('round-trips, preserving order', () {
      const pool = AccountPool(
        accountIds: ['c', 'a', 'b'],
        strategy: AccountRotationStrategy.serial,
      );
      final restored = AccountPool.fromJson(pool.toJson());
      expect(restored, pool);
      expect(restored.accountIds, ['c', 'a', 'b']);
    });

    test('a malformed payload reads as unconfigured, not as a crash', () {
      expect(AccountPool.fromJson(const {}).isEmpty, isTrue);
      expect(
        AccountPool.fromJson(const {'account_ids': 'nope'}).isEmpty,
        isTrue,
      );
      expect(
        AccountPool.fromJson(const {
          'account_ids': ['a', 42, '', 'b'],
        }).accountIds,
        ['a', 'b'],
      );
    });
  });

  group('select — nothing configured', () {
    test('an empty pool is unset, NOT all-spent', () {
      // The two mean opposite things to the caller: unset falls back to the
      // server default, all-spent refuses the dispatch. Collapsing them is how
      // a rate-limited pool silently becomes "runs on whatever".
      final choice = AccountSelector.select(
        pool: const AccountPool(),
        availability: _map([_avail('a')]),
      );
      expect(choice, isA<AccountPoolUnset>());
    });

    test('a pool naming only deleted accounts is unset', () {
      final choice = AccountSelector.select(
        pool: const AccountPool(accountIds: ['gone']),
        availability: _map([_avail('a')]),
      );
      expect(choice, isA<AccountPoolUnset>());
    });

    test('a deleted account is skipped, the survivors still run', () {
      // A pool outlives the accounts listed in it.
      final choice = AccountSelector.select(
        pool: const AccountPool(accountIds: ['gone', 'b']),
        availability: _map([_avail('b')]),
      );
      expect((choice as AccountChosen).accountId, 'b');
    });
  });

  group('select — pinned', () {
    test('always takes the first attached account', () {
      final choice = AccountSelector.select(
        pool: const AccountPool(accountIds: ['a', 'b']),
        availability: _map([_avail('a'), _avail('b')]),
      );
      expect((choice as AccountChosen).accountId, 'a');
    });

    test('skips a spent first account rather than failing', () {
      final choice = AccountSelector.select(
        pool: const AccountPool(accountIds: ['a', 'b']),
        availability: _map([_avail('a', spent: true), _avail('b')]),
      );
      expect((choice as AccountChosen).accountId, 'b');
    });

    test('skips a signed-out account', () {
      // Running on one burns a turn to print "please run /login".
      final choice = AccountSelector.select(
        pool: const AccountPool(accountIds: ['a', 'b']),
        availability: _map([_avail('a', signedIn: false), _avail('b')]),
      );
      expect((choice as AccountChosen).accountId, 'b');
    });
  });

  group('select — serial', () {
    test('drains in order, advancing only when one is spent', () {
      const pool = AccountPool(
        accountIds: ['a', 'b', 'c'],
        strategy: AccountRotationStrategy.serial,
      );
      expect(
        (AccountSelector.select(
              pool: pool,
              availability: _map([_avail('a'), _avail('b'), _avail('c')]),
            )
            as AccountChosen)
            .accountId,
        'a',
      );
      expect(
        (AccountSelector.select(
              pool: pool,
              availability: _map([
                _avail('a', spent: true),
                _avail('b'),
                _avail('c'),
              ]),
            )
            as AccountChosen)
            .accountId,
        'b',
      );
      expect(
        (AccountSelector.select(
              pool: pool,
              availability: _map([
                _avail('a', spent: true),
                _avail('b', spent: true),
                _avail('c'),
              ]),
            )
            as AccountChosen)
            .accountId,
        'c',
      );
    });

    test('does not consume the cursor', () {
      final choice = AccountSelector.select(
        pool: const AccountPool(
          accountIds: ['a', 'b'],
          strategy: AccountRotationStrategy.serial,
        ),
        availability: _map([_avail('a'), _avail('b')]),
        cursor: 7,
      );
      expect((choice as AccountChosen).cursor, 7);
    });
  });

  group('select — round robin', () {
    AccountChosen pick(int cursor, {Set<String> spent = const {}}) =>
        AccountSelector.select(
              pool: const AccountPool(
                accountIds: ['a', 'b', 'c'],
                strategy: AccountRotationStrategy.roundRobin,
              ),
              availability: _map([
                for (final id in ['a', 'b', 'c'])
                  _avail(id, spent: spent.contains(id)),
              ]),
              cursor: cursor,
            )
            as AccountChosen;

    test('cycles one step per dispatch and wraps', () {
      expect(pick(0).accountId, 'a');
      expect(pick(0).cursor, 1);
      expect(pick(1).accountId, 'b');
      expect(pick(2).accountId, 'c');
      expect(pick(2).cursor, 0, reason: 'wraps back to the start');
    });

    test('a cursor beyond the pool is taken modulo its length', () {
      // Shrinking a pool must not park the rotation off the end of the list.
      expect(pick(7).accountId, 'b');
    });

    test('a spent account still consumes its turn in the cycle', () {
      // Advancing over the FULL pool keeps the rotation reproducible from the
      // cursor alone; re-balancing over just the usable subset would make the
      // same cursor mean different things as accounts come and go.
      final choice = pick(0, spent: {'a'});
      expect(choice.accountId, 'b');
      expect(choice.cursor, 2);
    });
  });

  group('select — everything spent', () {
    test('refuses, and reports the SOONEST reset', () {
      final early = DateTime.utc(2026, 8, 24, 14, 20);
      final late = DateTime.utc(2026, 8, 24, 19);
      final choice = AccountSelector.select(
        pool: const AccountPool(accountIds: ['a', 'b']),
        availability: _map([
          _avail('a', spent: true, availableAt: late),
          _avail('b', spent: true, availableAt: early),
        ]),
      );
      final spent = choice as AccountsAllSpent;
      expect(spent.accountIds, ['a', 'b']);
      expect(
        spent.earliestReset,
        early,
        reason: 'the operator wants to know when they can come back',
      );
    });

    test('a signed-out account contributes no reset time', () {
      // Being signed out is a configuration problem, not a quota one — it never
      // clears on its own, so it must not be reported as "resets at".
      final at = DateTime.utc(2026, 8, 24, 14, 20);
      final choice = AccountSelector.select(
        pool: const AccountPool(accountIds: ['a', 'b']),
        availability: _map([
          _avail('a', signedIn: false),
          _avail('b', spent: true, availableAt: at),
        ]),
      );
      expect((choice as AccountsAllSpent).earliestReset, at);
    });

    test('all signed out reports no reset time at all', () {
      final choice = AccountSelector.select(
        pool: const AccountPool(accountIds: ['a']),
        availability: _map([_avail('a', signedIn: false)]),
      );
      expect((choice as AccountsAllSpent).earliestReset, isNull);
    });
  });
}
