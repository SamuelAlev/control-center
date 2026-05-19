import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/ports/run_credential_gate_port.dart';
import 'package:cc_domain/core/domain/value_objects/account_pool.dart';
import 'package:cc_infra/src/claude_accounts/claude_account_store.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Records every subprocess the store would have run, and answers with a
/// scripted result. No `claude` binary is required — and must not be: a test
/// that shells out to the real CLI would pass or fail based on whether the
/// machine running it happens to be signed in.
class _FakeProcess {
  _FakeProcess();

  final List<({String exe, List<String> args, Map<String, String>? env})>
  calls = [];

  /// Keyed by a PREFIX of the joined arguments (`auth status`,
  /// `find-generic-password -s Claude Code-credentials-abc12345`).
  final Map<String, ProcessResult> results = {};

  ProcessResult fallback = ProcessResult(0, 1, '', 'not scripted');

  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    Map<String, String>? environment,
  }) async {
    calls.add((exe: executable, args: arguments, env: environment));
    final key = arguments.isEmpty ? '' : arguments.join(' ');
    // LONGEST matching prefix wins. `Claude Code-credentials` is a prefix of
    // every namespaced `Claude Code-credentials-<hash>`, so first-match would
    // silently answer an account's own lookup with the default credential —
    // which is exactly the confusion these tests exist to rule out.
    String? best;
    for (final entry in results.entries) {
      if (key.startsWith(entry.key) &&
          (best == null || entry.key.length > best.length)) {
        best = entry.key;
      }
    }
    return best == null ? fallback : results[best]!;
  }
}

String _statusJson({
  bool loggedIn = true,
  String? email = 'me@example.com',
  String? org = 'Acme',
  String? plan = 'max',
}) => jsonEncode({
  'loggedIn': loggedIn,
  'authMethod': loggedIn ? 'claude.ai' : 'none',
  'email': email,
  'orgName': org,
  'subscriptionType': plan,
});

String _credentials({required int expiresAt}) => jsonEncode({
  'claudeAiOauth': {
    'accessToken': 'tok-$expiresAt',
    'refreshToken': 'refresh-$expiresAt',
    'expiresAt': expiresAt,
  },
});

void main() {
  late Directory dataDir;
  late _FakeProcess proc;
  late ClaudeAccountStore store;

  setUp(() {
    dataDir = Directory.systemTemp.createTempSync('cc-claude-acct-');
    proc = _FakeProcess();
    store = ClaudeAccountStore(dataDir: dataDir.path, runProcess: proc.run);
  });

  tearDown(() {
    if (dataDir.existsSync()) {
      dataDir.deleteSync(recursive: true);
    }
  });

  group('registry', () {
    test('starts empty and creates a directory per account', () async {
      expect(await store.list(), isEmpty);

      final a = await store.create(label: 'Work');
      expect(a.id, 'work');
      expect(Directory(store.configDirFor('work')).existsSync(), isTrue);
      expect(a.isDefault, isTrue, reason: 'the first account is the default');

      final b = await store.create(label: 'Personal');
      expect(b.isDefault, isFalse, reason: 'adding one must not re-point runs');
      expect((await store.list()).map((x) => x.id), ['work', 'personal']);
    });

    test('ids are directory-safe and never escape the accounts root', () async {
      final a = await store.create(label: '../../etc/passwd');
      expect(a.id, isNot(contains('/')));
      expect(a.id, isNot(contains('..')));
      expect(
        p.isWithin(store.root, store.configDirFor(a.id)),
        isTrue,
        reason: 'the label is operator input and becomes a directory name',
      );
    });

    test(
      'duplicate labels get distinct ids and distinct directories',
      () async {
        final a = await store.create(label: 'Work');
        final b = await store.create(label: 'Work');
        expect(a.id, isNot(b.id));
        expect(store.configDirFor(a.id), isNot(store.configDirFor(b.id)));
      },
    );

    test('setDefault moves the flag to exactly one account', () async {
      await store.create(label: 'Work');
      await store.create(label: 'Personal');
      await store.setDefault('personal');
      final accounts = await store.list();
      expect(accounts.where((a) => a.isDefault).map((a) => a.id), ['personal']);
    });

    test('removing the default promotes a survivor', () async {
      await store.create(label: 'Work');
      await store.create(label: 'Personal');
      await store.remove('work');
      final accounts = await store.list();
      expect(accounts.map((a) => a.id), ['personal']);
      expect(
        accounts.single.isDefault,
        isTrue,
        reason: 'a dispatch must never resolve to nothing while accounts exist',
      );
      expect(Directory(store.configDirFor('work')).existsSync(), isFalse);
    });

    test('remove logs out BEFORE deleting the directory', () async {
      await store.create(label: 'Work');
      await store.remove('work');
      // The directory IS the credential; deleting it first would strand a live
      // refresh token that we then never revoke.
      expect(proc.calls.single.args, ['auth', 'logout']);
      expect(
        proc.calls.single.env?['CLAUDE_CONFIG_DIR'],
        store.configDirFor('work'),
      );
    });

    test('a failing logout still removes the account', () async {
      await store.create(label: 'Work');
      proc.fallback = ProcessResult(0, 1, '', 'network down');
      await store.remove('work');
      expect(await store.list(), isEmpty);
    });
  });

  group('resolveConfigDir', () {
    test('returns null when no accounts exist', () async {
      // The CLI then resolves its own credential, which is exactly the
      // pre-existing behaviour — so a machine that never configures an account
      // is not regressed by this feature.
      expect(await store.resolveConfigDir(), isNull);
    });

    test('falls back to the default account', () async {
      await store.create(label: 'Work');
      await store.create(label: 'Personal');
      await store.setDefault('personal');
      expect(await store.resolveConfigDir(), store.configDirFor('personal'));
    });

    test('honours an explicit account', () async {
      await store.create(label: 'Work');
      await store.create(label: 'Personal');
      expect(
        await store.resolveConfigDir(accountId: 'personal'),
        store.configDirFor('personal'),
      );
    });

    test(
      'an account that no longer exists falls back, it does not fail',
      () async {
        await store.create(label: 'Work');
        // A conversation outlives the account pinned on it. Refusing to dispatch
        // would be a worse answer than running on the account the operator would
        // have picked anyway.
        expect(
          await store.resolveConfigDir(accountId: 'deleted-account'),
          store.configDirFor('work'),
        );
      },
    );

    test('recreates a directory that was deleted underneath us', () async {
      await store.create(label: 'Work');
      Directory(store.configDirFor('work')).deleteSync(recursive: true);
      final dir = await store.resolveConfigDir();
      // bwrap aborts the WHOLE spawn on a missing `--bind` source, so a
      // vanished directory must not reach the sandbox.
      expect(Directory(dir!).existsSync(), isTrue);
    });
  });

  group('keychain -> file mirror', () {
    // The load-bearing half on macOS. `CLAUDE_CONFIG_DIR` does NOT move the
    // credential to a file — it namespaces the KEYCHAIN service by
    // sha256(configDir)[:8]. The sandbox denies `~/Library/Keychains`, so
    // without this mirror an account reads as signed in everywhere the server
    // looks and signed out in every run.
    test('the service name is derived from the config dir', () {
      // Pinned against a real observed pairing, so a change in the derivation
      // fails here rather than as "signed out" on every dispatch.
      expect(
        ClaudeAccountStore.keychainServiceFor(
          '/Users/samuel.alev/dev/control-center/apps/cc_server/data/'
          'claude-accounts/account',
        ),
        'Claude Code-credentials-ec489220',
      );
      expect(
        ClaudeAccountStore.keychainServiceFor('/a'),
        isNot(ClaudeAccountStore.keychainServiceFor('/b')),
      );
    });

    test('copies the namespaced item into the account directory', () async {
      final a = await store.create(label: 'Work');
      final service = ClaudeAccountStore.keychainServiceFor(
        store.configDirFor(a.id),
      );
      proc.results['find-generic-password -s $service'] = ProcessResult(
        0,
        0,
        _credentials(expiresAt: 100),
        '',
      );

      expect(await store.syncCredentialFromKeychain(a.id), isTrue);
      final file = File(p.join(store.configDirFor(a.id), '.credentials.json'));
      expect(file.existsSync(), isTrue);
      expect(file.readAsStringSync(), contains('tok-100'));
    }, skip: !Platform.isMacOS ? 'macOS keychain only' : null);

    test('resolveConfigDir mirrors before handing the dir to a run', () async {
      final a = await store.create(label: 'Work');
      final service = ClaudeAccountStore.keychainServiceFor(
        store.configDirFor(a.id),
      );
      proc.results['find-generic-password -s $service'] = ProcessResult(
        0,
        0,
        _credentials(expiresAt: 100),
        '',
      );
      final dir = await store.resolveConfigDir();
      expect(File(p.join(dir!, '.credentials.json')).existsSync(), isTrue);
    }, skip: !Platform.isMacOS ? 'macOS keychain only' : null);

    test('NEVER clobbers a newer credential', () async {
      // A run that outlives its access token refreshes in-sandbox and can only
      // write the file. Overwriting that with the staler keychain copy would
      // hand the CLI a refresh token the provider may already have rotated
      // away — turning a working account into a dead one.
      final a = await store.create(label: 'Work');
      final file = File(p.join(store.configDirFor(a.id), '.credentials.json'))
        ..writeAsStringSync(_credentials(expiresAt: 500));
      final service = ClaudeAccountStore.keychainServiceFor(
        store.configDirFor(a.id),
      );
      proc.results['find-generic-password -s $service'] = ProcessResult(
        0,
        0,
        _credentials(expiresAt: 100),
        '',
      );

      expect(await store.syncCredentialFromKeychain(a.id), isTrue);
      expect(file.readAsStringSync(), contains('tok-500'));
    }, skip: !Platform.isMacOS ? 'macOS keychain only' : null);

    test('replaces an older or corrupt file', () async {
      final a = await store.create(label: 'Work');
      final file = File(p.join(store.configDirFor(a.id), '.credentials.json'))
        ..writeAsStringSync('{ not json');
      final service = ClaudeAccountStore.keychainServiceFor(
        store.configDirFor(a.id),
      );
      proc.results['find-generic-password -s $service'] = ProcessResult(
        0,
        0,
        _credentials(expiresAt: 100),
        '',
      );

      expect(await store.syncCredentialFromKeychain(a.id), isTrue);
      expect(file.readAsStringSync(), contains('tok-100'));
    }, skip: !Platform.isMacOS ? 'macOS keychain only' : null);

    test('no keychain item leaves an existing file alone', () async {
      final a = await store.create(label: 'Work');
      final file = File(p.join(store.configDirFor(a.id), '.credentials.json'))
        ..writeAsStringSync(_credentials(expiresAt: 500));
      expect(await store.syncCredentialFromKeychain(a.id), isTrue);
      expect(file.readAsStringSync(), contains('tok-500'));
    });

    test('no keychain item and no file reports no credential', () async {
      final a = await store.create(label: 'Work');
      expect(await store.syncCredentialFromKeychain(a.id), isFalse);
    });
  });

  group('status', () {
    test('fills identity from `claude auth status --json`', () async {
      await store.create(label: 'Work');
      proc.results['auth status'] = ProcessResult(0, 0, _statusJson(), '');
      final account = (await store.listWithStatus()).single;
      expect(account.loggedIn, isTrue);
      expect(account.email, 'me@example.com');
      expect(account.orgName, 'Acme');
      expect(account.subscriptionType, 'max');
      expect(account.subtitle, 'max · Acme');
      expect(account.statusError, isNull);
    });

    test('probes each account in its OWN directory', () async {
      await store.create(label: 'Work');
      await store.create(label: 'Personal');
      proc.results['auth status'] = ProcessResult(0, 0, _statusJson(), '');
      await store.listWithStatus();
      final dirs = proc.calls
          .where((c) => c.args.first == 'auth')
          .map((c) => c.env?['CLAUDE_CONFIG_DIR'])
          .toSet();
      expect(dirs, {
        store.configDirFor('work'),
        store.configDirFor('personal'),
      });
    });

    test('a logged-out account is reported, not treated as an error', () async {
      await store.create(label: 'Work');
      proc.results['auth status'] = ProcessResult(
        0,
        0,
        _statusJson(loggedIn: false, email: null, org: null, plan: null),
        '',
      );
      final account = (await store.listWithStatus()).single;
      expect(account.loggedIn, isFalse);
      expect(account.statusError, isNull);
    });

    test(
      'an unreadable status is an error, distinct from logged out',
      () async {
        await store.create(label: 'Work');
        proc.results['auth status'] = ProcessResult(0, 127, '', 'not found');
        final account = (await store.listWithStatus()).single;
        expect(account.loggedIn, isFalse);
        expect(
          account.statusError,
          isNotNull,
          reason: '"we could not tell" must not render as "you are signed out"',
        );
      },
    );

    test(
      'an auto-generated label adopts the email; a chosen one does not',
      () async {
        await store.create();
        await store.create(label: 'My work login');
        proc.results['auth status'] = ProcessResult(0, 0, _statusJson(), '');
        final accounts = await store.listWithStatus();
        expect(accounts[0].label, 'me@example.com');
        expect(accounts[1].label, 'My work login');
      },
    );
  });

  group('loginCommand', () {
    test('scopes the login to the account directory', () async {
      final a = await store.create(label: 'Work');
      final cmd = store.loginCommand(a.id);
      expect(cmd.argv, ['claude', 'auth', 'login']);
      expect(cmd.environment['CLAUDE_CONFIG_DIR'], store.configDirFor(a.id));
    });

    test('carries --email and --console when asked', () async {
      final a = await store.create(label: 'Work');
      final cmd = store.loginCommand(
        a.id,
        email: 'me@example.com',
        console: true,
      );
      expect(cmd.argv, contains('--console'));
      expect(cmd.argv, containsAllInOrder(['--email', 'me@example.com']));
    });
  });

  group('bootstrapFromKeychain', () {
    test('seeds the first account from the keychain blob', () async {
      const blob = '{"claudeAiOauth":{"accessToken":"sk-ant-oat01-x"}}';
      proc.results['find-generic-password'] = ProcessResult(0, 0, blob, '');
      proc.results['auth status'] = ProcessResult(0, 0, _statusJson(), '');

      final account = await store.bootstrapFromKeychain();
      expect(account, isNotNull);
      final creds = File(
        p.join(store.configDirFor(account!.id), '.credentials.json'),
      );
      expect(creds.existsSync(), isTrue);
      expect(creds.readAsStringSync(), blob);
    }, skip: !Platform.isMacOS ? 'macOS keychain only' : null);

    test('does nothing when accounts already exist', () async {
      await store.create(label: 'Work');
      proc.results['find-generic-password'] = ProcessResult(
        0,
        0,
        '{"claudeAiOauth":{"accessToken":"x"}}',
        '',
      );
      expect(await store.bootstrapFromKeychain(), isNull);
      expect((await store.list()).length, 1);
    });

    test('a non-credential blob is refused, not copied', () async {
      // Half-written or unexpected content would look signed-in and fail on
      // the first request instead of at bootstrap.
      proc.results['find-generic-password'] = ProcessResult(
        0,
        0,
        'garbage',
        '',
      );
      expect(await store.bootstrapFromKeychain(), isNull);
      expect(await store.list(), isEmpty);
    }, skip: !Platform.isMacOS ? 'macOS keychain only' : null);

    test('no keychain item leaves the install with no accounts', () async {
      proc.results['find-generic-password'] = ProcessResult(0, 44, '', '');
      expect(await store.bootstrapFromKeychain(), isNull);
      expect(await store.list(), isEmpty);
    }, skip: !Platform.isMacOS ? 'macOS keychain only' : null);
  });

  group('durability', () {
    test('a corrupt registry reads as empty rather than throwing', () async {
      await store.create(label: 'Work');
      File(p.join(store.root, 'accounts.json')).writeAsStringSync('{ not json');
      expect(await store.list(), isEmpty);
    });

    test('the registry stores no probe-derived state', () async {
      // A persisted `logged_in` / `email` is an answer from the CLI, and a
      // stored copy goes stale the moment the operator signs in or out — a
      // file that confidently contradicts `claude auth status`.
      await store.create(label: 'Work');
      final raw = jsonDecode(
        File(p.join(store.root, 'accounts.json')).readAsStringSync(),
      );
      expect(raw, isA<List<dynamic>>());
      final row = (raw as List).single as Map<String, dynamic>;
      expect(row.keys.toSet(), {'id', 'label', 'is_default'});
    });

    test('the registry survives a reopen', () async {
      await store.create(label: 'Work');
      await store.setDefault('work');
      final reopened = ClaudeAccountStore(
        dataDir: dataDir.path,
        runProcess: proc.run,
      );
      final accounts = await reopened.list();
      expect(accounts.single.id, 'work');
      expect(accounts.single.isDefault, isTrue);
    });
  });

  group('availability + rotation', () {
    late DateTime clock;

    ClaudeAccountStore build({
      Future<({double usedFraction, DateTime? resetsAt})?> Function(String)?
      probe,
    }) => ClaudeAccountStore(
      dataDir: dataDir.path,
      runProcess: proc.run,
      probeUsage: probe,
      now: () => clock,
    );

    setUp(() {
      clock = DateTime.utc(2026, 8, 24, 12);
    });

    Future<void> seed(List<String> labels) async {
      for (final l in labels) {
        final a = await store.create(label: l);
        File(
          p.join(store.configDirFor(a.id), '.credentials.json'),
        ).writeAsStringSync(_credentials(expiresAt: 999));
      }
    }

    test('a fully-spent plan is spent; a partly-used one is not', () async {
      await seed(['Work', 'Personal']);
      // Strictly 100%: the operator asked for each account to be drained fully
      // rather than advanced early.
      final s = build(
        probe: (dir) async => dir.endsWith('work')
            ? (usedFraction: 1.0, resetsAt: null)
            : (usedFraction: 0.99, resetsAt: null),
      );
      final avail = await s.availability();
      expect(avail['work']!.spent, isTrue);
      expect(avail['personal']!.spent, isFalse, reason: '99% still has room');
    });

    test('a cooldown makes an account spent and reports its reset', () async {
      await seed(['Work']);
      final until = clock.add(const Duration(minutes: 20));
      await store.markRateLimited('work', until: until);

      final s = build();
      final avail = await s.availability();
      expect(avail['work']!.spent, isTrue);
      expect(avail['work']!.availableAt, until);
    });

    test('an expired cooldown stops counting', () async {
      await seed(['Work']);
      await store.markRateLimited(
        'work',
        until: clock.subtract(const Duration(minutes: 1)),
      );
      final avail = await build().availability();
      expect(avail['work']!.spent, isFalse);
    });

    test('the cooldown survives a reopen', () async {
      // A bounced server must not send the next run straight back into the
      // account that just refused it.
      await seed(['Work']);
      final until = clock.add(const Duration(hours: 2));
      await store.markRateLimited('work', until: until);
      final reopened = ClaudeAccountStore(
        dataDir: dataDir.path,
        runProcess: proc.run,
        now: () => clock,
      );
      expect((await reopened.list()).single.rateLimitedUntil, until);
    });

    test('a rate-limit with no reported reset parks for the default', () async {
      await seed(['Work']);
      // The clocked store, not the ambient one: the default cooldown is
      // measured from `now`, which is exactly what the seam exists to pin.
      final s = build();
      await s.markRateLimited('work');
      final until = (await s.list()).single.rateLimitedUntil!;
      expect(until, clock.add(ClaudeAccountStore.defaultCooldown));
    });

    test('a failing usage probe never makes an account look spent', () async {
      // One flaky request must not stop every run in the workspace.
      await seed(['Work']);
      final s = build(probe: (_) async => throw StateError('boom'));
      expect((await s.availability())['work']!.spent, isFalse);
    });

    test(
      'usage is cached, so the dispatch path cannot throttle itself',
      () async {
        await seed(['Work']);
        var calls = 0;
        final s = build(
          probe: (_) async {
            calls++;
            return (usedFraction: 0.1, resetsAt: null);
          },
        );
        await s.availability();
        await s.availability();
        expect(calls, 1);
      },
    );

    test(
      'resolveForDispatch returns the chosen account then the rest',
      () async {
        await seed(['Work', 'Personal', 'Third']);
        final s = build();
        final plan = await s.resolveForDispatch(
          pool: const AccountPool(
            accountIds: ['work', 'personal', 'third'],
            strategy: AccountRotationStrategy.roundRobin,
          ),
          cursor: 1,
        );
        expect(plan.active?.accountId, 'personal');
        expect(plan.nextCursor, 2);
        // Failover order is POOL order, not rotation order: once the first
        // choice failed the question is which of these can finish the work.
        expect(
          [for (final c in plan.candidates) c.accountId],
          ['personal', 'work', 'third'],
        );
      },
    );

    test('a conversation pin gets no failover', () async {
      // The operator named ONE account; quietly running on another would make
      // the picker a suggestion rather than a choice.
      await seed(['Work', 'Personal']);
      final plan = await build().resolveForDispatch(
        pool: const AccountPool(accountIds: ['work', 'personal']),
        pinnedAccountId: 'personal',
      );
      expect([for (final c in plan.candidates) c.accountId], ['personal']);
    });

    test('every account spent refuses with the soonest reset', () async {
      await seed(['Work', 'Personal']);
      final early = clock.add(const Duration(minutes: 10));
      await store.markRateLimited(
        'work',
        until: clock.add(const Duration(hours: 3)),
      );
      await store.markRateLimited('personal', until: early);

      final plan = await build().resolveForDispatch(
        pool: const AccountPool(accountIds: ['work', 'personal']),
      );
      expect(plan.candidates, isEmpty);
      expect(plan.allSpent?.earliestReset, early);
    });

    test('no pool keeps the single-default behaviour', () async {
      await seed(['Work', 'Personal']);
      final plan = await build().resolveForDispatch();
      expect([for (final c in plan.candidates) c.accountId], ['work']);
    });

    // The hole that mattered most. A POOL is the advanced setup, so the install
    // that never opens that screen — one account, the common case — was the one
    // whose only way to learn its plan was spent was to watch `claude -p` fail.
    test('a spent single account is refused even with no pool', () async {
      await seed(['Work']);
      final resetsAt = clock.add(const Duration(hours: 2));
      final plan = await build(
        probe: (_) async => (usedFraction: 1.0, resetsAt: resetsAt),
      ).resolveForDispatch();

      expect(plan.candidates, isEmpty);
      expect(plan.allSpent?.reason, RunCredentialReason.planSpent);
      expect(plan.allSpent?.accountIds, ['work']);
      expect(plan.allSpent?.earliestReset, resetsAt);
    });

    test('a spent PINNED account is refused too', () async {
      // A pin is an explicit instruction, not an exemption from the plan's
      // limits — running it anyway would spend a turn to be told the same
      // thing by the CLI.
      await seed(['Work', 'Personal']);
      final plan = await build(
        probe: (dir) async => dir.endsWith('personal')
            ? (usedFraction: 1.0, resetsAt: null)
            : null,
      ).resolveForDispatch(pinnedAccountId: 'personal');

      expect(plan.candidates, isEmpty);
      expect(plan.allSpent?.reason, RunCredentialReason.planSpent);
    });

    test(
      'a SIGNED-OUT single account still resolves — the session decides',
      () async {
        // Deliberately not refused here. `CLAUDE_CODE_OAUTH_TOKEN` /
        // `ANTHROPIC_API_KEY` in the run's environment make the CLI work with an
        // empty directory, and this store cannot see a run's env; refusing on
        // the directory alone would take a working install offline.
        final a = await store.create(label: 'Work');
        expect(
          File(
            p.join(store.configDirFor(a.id), '.credentials.json'),
          ).existsSync(),
          isFalse,
        );
        final plan = await build().resolveForDispatch();
        expect([for (final c in plan.candidates) c.accountId], ['work']);
        expect(plan.allSpent, isNull);
      },
    );

    test(
      'a pool with nobody signed in reports signed-out, not spent',
      () async {
        await store.create(label: 'Work');
        await store.create(label: 'Personal');
        final plan = await build().resolveForDispatch(
          pool: const AccountPool(accountIds: ['work', 'personal']),
        );
        expect(plan.candidates, isEmpty);
        expect(plan.allSpent?.reason, RunCredentialReason.signedOut);
        expect(plan.allSpent?.earliestReset, isNull);
      },
    );

    group('credential expiry', () {
      // An access token lives hours and the CLI renews it from the refresh
      // token the moment it runs, so EVERY account nobody used overnight
      // presents an expired one. Treating that as signed out would empty the
      // rotation each morning and refuse every dispatch — a worse failure than
      // the 401 the check exists to pre-empt.
      test('an expired token with a refresh token stays usable', () async {
        await seed(['Work']);
        File(
          p.join(store.configDirFor('work'), '.credentials.json'),
        ).writeAsStringSync(
          _credentials(
            expiresAt: clock
                .subtract(const Duration(hours: 6))
                .millisecondsSinceEpoch,
          ),
        );

        final avail = await build().availability();
        expect(avail['work']!.signedIn, isTrue);
      });

      test('an expired token with NOTHING to renew it is signed out', () async {
        // The frozen-snapshot case: a directory nothing ever logged into, so no
        // refresh token — it 401s every run and every usage probe until a human
        // signs in.
        await seed(['Work']);
        File(
          p.join(store.configDirFor('work'), '.credentials.json'),
        ).writeAsStringSync(
          jsonEncode({
            'claudeAiOauth': {
              'accessToken': 'tok',
              'expiresAt': clock
                  .subtract(const Duration(hours: 6))
                  .millisecondsSinceEpoch,
            },
          }),
        );

        final avail = await build().availability();
        expect(avail['work']!.signedIn, isFalse);
        expect(avail['work']!.spent, isFalse, reason: 'not a quota problem');
      });

      test(
        'an expired token whose REFRESH token also ran out is signed out',
        () async {
          // The refresh token outlives the access token by weeks, not hours —
          // but it does expire, and past that instant there is nothing left to
          // renew from. Indistinguishable from a healthy account by the access
          // expiry alone, which is why the renewability test reads both.
          await seed(['Work']);
          File(
            p.join(store.configDirFor('work'), '.credentials.json'),
          ).writeAsStringSync(
            jsonEncode({
              'claudeAiOauth': {
                'accessToken': 'tok',
                'refreshToken': 'refresh',
                'expiresAt': clock
                    .subtract(const Duration(hours: 6))
                    .millisecondsSinceEpoch,
                'refreshTokenExpiresAt': clock
                    .subtract(const Duration(days: 2))
                    .millisecondsSinceEpoch,
              },
            }),
          );

          final avail = await build().availability();
          expect(avail['work']!.signedIn, isFalse);
        },
      );

      test(
        'a refresh token with no stated expiry is taken at its word',
        () async {
          // An unknown deadline must not be read as a passed one: that would
          // sideline every account whose credential simply omits the field.
          await seed(['Work']);
          File(
            p.join(store.configDirFor('work'), '.credentials.json'),
          ).writeAsStringSync(
            _credentials(
              expiresAt: clock
                  .subtract(const Duration(hours: 6))
                  .millisecondsSinceEpoch,
            ),
          );

          final avail = await build().availability();
          expect(avail['work']!.signedIn, isTrue);
        },
      );

      test(
        'a live token is reported on the roster, not treated as a fault',
        () async {
          await seed(['Work']);
          final expiry = clock.add(const Duration(hours: 4));
          File(
            p.join(store.configDirFor('work'), '.credentials.json'),
          ).writeAsStringSync(
            _credentials(expiresAt: expiry.millisecondsSinceEpoch),
          );
          proc.results['auth status'] = ProcessResult(0, 0, _statusJson(), '');

          final listed = await build().listWithStatus();
          expect(listed.single.loggedIn, isTrue);
          expect(
            listed.single.credentialExpiresAt?.millisecondsSinceEpoch,
            expiry.millisecondsSinceEpoch,
          );
        },
      );
    });

    group('an observed auth failure', () {
      // The credential file's mtime is what decides whether the recorded
      // failure still stands, so the tests have to place it relative to the
      // injected clock rather than to the machine's wall time.
      void ageCredential(String accountId, Duration before) {
        File(
          p.join(store.configDirFor(accountId), '.credentials.json'),
        ).setLastModifiedSync(clock.subtract(before));
      }

      test(
        'takes the account out of rotation, without pretending it is spent',
        () async {
          await seed(['Work', 'Personal']);
          ageCredential('work', const Duration(hours: 1));
          await build().markAuthFailed('work', reason: '401 token expired');

          final avail = await build().availability();
          // Signed OUT, not spent: nothing but a human signing in fixes it, and
          // a cooldown would hand it back to the rotation on a timer.
          expect(avail['work']!.signedIn, isFalse);
          expect(avail['work']!.spent, isFalse);
          expect(avail['personal']!.signedIn, isTrue);
        },
      );

      test('is skipped by resolveForDispatch, including as failover', () async {
        await seed(['Work', 'Personal', 'Third']);
        ageCredential('work', const Duration(hours: 1));
        await build().markAuthFailed('work');

        final plan = await build().resolveForDispatch(
          pool: const AccountPool(accountIds: ['work', 'personal', 'third']),
        );
        expect(
          [for (final c in plan.candidates) c.accountId],
          ['personal', 'third'],
        );
      });

      test('outlives a restart', () async {
        await seed(['Work']);
        ageCredential('work', const Duration(hours: 1));
        await build().markAuthFailed('work', reason: 'nope');

        final reopened = ClaudeAccountStore(
          dataDir: dataDir.path,
          runProcess: proc.run,
          now: () => clock,
        );
        expect((await reopened.availability())['work']!.signedIn, isFalse);
        expect((await reopened.list()).single.authFailedReason, 'nope');
      });

      test('clears itself once a NEWER credential lands', () async {
        // A re-login (or an in-sandbox refresh) rewrites the file — the one
        // event that can make the account work again — so nothing has to be
        // cleared by hand.
        await seed(['Work']);
        ageCredential('work', const Duration(hours: 1));
        await build().markAuthFailed('work');
        expect((await build().availability())['work']!.signedIn, isFalse);

        File(
          p.join(store.configDirFor('work'), '.credentials.json'),
        ).setLastModifiedSync(clock.add(const Duration(minutes: 1)));
        expect((await build().availability())['work']!.signedIn, isTrue);
      });

      test(
        'is reported by the settings list, which the CLI probe cannot see',
        () async {
          // `claude auth status` reads the credential's shape, not whether the
          // provider still honours it — so it keeps saying "logged in" about a
          // directory whose token expired hours ago.
          await seed(['Work']);
          ageCredential('work', const Duration(hours: 1));
          await build().markAuthFailed('work', reason: '401 token expired');
          proc.results['auth status'] = ProcessResult(0, 0, _statusJson(), '');

          final listed = await build().listWithStatus();
          expect(listed.single.loggedIn, isFalse);
          expect(listed.single.statusError, contains('401'));
        },
      );

      test(
        'the settings list drops a failure a newer credential repaired',
        () async {
          await seed(['Work']);
          ageCredential('work', const Duration(hours: 1));
          await build().markAuthFailed('work');
          File(
            p.join(store.configDirFor('work'), '.credentials.json'),
          ).setLastModifiedSync(clock.add(const Duration(minutes: 1)));
          proc.results['auth status'] = ProcessResult(0, 0, _statusJson(), '');

          expect((await build().listWithStatus()).single.loggedIn, isTrue);
          // …and the record does not outlive the problem it describes.
          expect((await store.list()).single.authFailedAt, isNull);
        },
      );
    });
  });

  group('labels', () {
    test('a learned email is PERSISTED, not just returned', () async {
      // The picker does not probe. If the adoption lived only in the probe's
      // result, Settings would show the address while the picker still showed
      // "Account 1" — two surfaces disagreeing about one account.
      await store.create();
      proc.results['auth status'] = ProcessResult(0, 0, _statusJson(), '');
      await store.listWithStatus();
      expect((await store.list()).single.label, 'me@example.com');
    });

    test('a label the operator chose is never overwritten', () async {
      await store.create(label: 'My work login');
      proc.results['auth status'] = ProcessResult(0, 0, _statusJson(), '');
      await store.listWithStatus();
      expect((await store.list()).single.label, 'My work login');
    });

    test('no email leaves the generated label alone', () async {
      await store.create();
      proc.results['auth status'] = ProcessResult(
        0,
        0,
        _statusJson(email: null),
        '',
      );
      await store.listWithStatus();
      expect((await store.list()).single.label, 'Account 1');
    });
  });

  group('the seeded account follows the default login', () {
    // It has no keychain item of its own — nothing ever logged into its
    // directory — so without this it is frozen at the moment of seeding.
    // Measured on a real install: its snapshot expired at 21:57 while the
    // default item was good until 05:54, and every run on it then 401'd while
    // the usage flyout said "no usage reported".
    test('mirrors the DEFAULT item when it has none of its own', () async {
      proc.results['find-generic-password -s Claude Code-credentials -w'] =
          ProcessResult(0, 0, _credentials(expiresAt: 900), '');
      proc.results['auth status'] = ProcessResult(0, 0, _statusJson(), '');
      final account = await store.bootstrapFromKeychain();
      expect(account, isNotNull);
      expect((await store.list()).single.tracksDefaultLogin, isTrue);

      // The default item moves on; the account must move with it.
      proc.results['find-generic-password -s Claude Code-credentials -w'] =
          ProcessResult(0, 0, _credentials(expiresAt: 9000), '');
      expect(await store.syncCredentialFromKeychain(account!.id), isTrue);
      final file = File(
        p.join(store.configDirFor(account.id), '.credentials.json'),
      );
      expect(file.readAsStringSync(), contains('tok-9000'));
    }, skip: !Platform.isMacOS ? 'macOS keychain only' : null);

    test('an account signed in through its OWN directory does not', () async {
      // Its own item is authoritative; falling back to the default would swap
      // one login's credential for another's.
      final a = await store.create(label: 'Work');
      expect((await store.list()).single.tracksDefaultLogin, isFalse);
      proc.results['find-generic-password -s Claude Code-credentials -w'] =
          ProcessResult(0, 0, _credentials(expiresAt: 9000), '');
      expect(await store.syncCredentialFromKeychain(a.id), isFalse);
      expect(
        File(
          p.join(store.configDirFor(a.id), '.credentials.json'),
        ).existsSync(),
        isFalse,
      );
    }, skip: !Platform.isMacOS ? 'macOS keychain only' : null);
  });

  group('prepareForRun — the interactive gates a dispatch cannot answer', () {
    test('marks the run\'s working directory trusted', () async {
      final account = await store.create(label: 'A');
      const cwd = '/tmp/space/agents/qa';

      await store.prepareForRun(accountId: account.id, workingDirectory: cwd);

      final config = jsonDecode(
        File(
          p.join(store.configDirFor(account.id), '.claude.json'),
        ).readAsStringSync(),
      );
      // Untrusted, Claude Code IGNORES the project's `permissions.allow`
      // entries and only says so on stderr — the run succeeds with fewer
      // permissions than it was configured with, which reads as an agent
      // refusing to do its job.
      final projects = (config as Map)['projects'] as Map;
      expect((projects[cwd] as Map)['hasTrustDialogAccepted'], isTrue);
    });

    test('keeps the rest of an existing .claude.json', () async {
      final account = await store.create(label: 'A');
      final configFile =
          File(p.join(store.configDirFor(account.id), '.claude.json'))
            ..writeAsStringSync(
              jsonEncode({
                'oauthAccount': {'accountUuid': 'abc'},
                'projects': {
                  '/other': {'hasTrustDialogAccepted': true, 'note': 'keep me'},
                },
              }),
            );

      await store.prepareForRun(
        accountId: account.id,
        workingDirectory: '/tmp/new',
      );

      final config =
          jsonDecode(configFile.readAsStringSync()) as Map<String, dynamic>;
      // The file holds the account's credential pointer; clobbering it to
      // record a trust bit would sign the account out.
      expect(config['oauthAccount'], {'accountUuid': 'abc'});
      final projects = config['projects'] as Map;
      expect((projects['/other'] as Map)['note'], 'keep me');
      expect((projects['/tmp/new'] as Map)['hasTrustDialogAccepted'], isTrue);
    });

    test('propagates the operator\'s managed-settings consent', () async {
      final home = Directory.systemTemp.createTempSync('cc_home_');
      addTearDown(() => home.deleteSync(recursive: true));
      final consent =
          File(p.join(home.path, '.claude', 'remote-settings-consent.json'))
            ..createSync(recursive: true)
            ..writeAsStringSync('{"version":1,"records":{}}');

      final scoped = ClaudeAccountStore(
        dataDir: dataDir.path,
        runProcess: proc.run,
        claudeHome: () => home.path,
      );
      final account = await scoped.create(label: 'A');
      await scoped.prepareForRun(
        accountId: account.id,
        workingDirectory: '/tmp/x',
      );

      final copied = File(
        p.join(scoped.configDirFor(account.id), 'remote-settings-consent.json'),
      );
      expect(copied.existsSync(), isTrue);
      expect(copied.readAsStringSync(), consent.readAsStringSync());
    });

    test('never fabricates consent the operator has not given', () async {
      final home = Directory.systemTemp.createTempSync('cc_home_');
      addTearDown(() => home.deleteSync(recursive: true));

      final scoped = ClaudeAccountStore(
        dataDir: dataDir.path,
        runProcess: proc.run,
        claudeHome: () => home.path,
      );
      final account = await scoped.create(label: 'A');
      await scoped.prepareForRun(
        accountId: account.id,
        workingDirectory: '/tmp/x',
      );

      // With nothing to propagate, nothing is approved. This is the boundary
      // that keeps the feature "carry a decision a human made" rather than
      // "auto-accept a dialog nobody ever saw".
      expect(
        File(
          p.join(
            scoped.configDirFor(account.id),
            'remote-settings-consent.json',
          ),
        ).existsSync(),
        isFalse,
      );
    });

    test('is a no-op for an unknown account', () async {
      await store.prepareForRun(accountId: 'nope', workingDirectory: '/tmp/x');
      expect(Directory(store.configDirFor('nope')).existsSync(), isFalse);
    });
  });

  group('prepareForRun — CLI attribution suppression', () {
    File settingsFile(ClaudeAccountStore s, String id) =>
        File(p.join(s.configDirFor(id), 'settings.json'));

    test('seeds the attribution block into a fresh account dir', () async {
      final account = await store.create(label: 'A');

      await store.prepareForRun(
        accountId: account.id,
        workingDirectory: '/tmp/x',
      );

      final settings =
          jsonDecode(settingsFile(store, account.id).readAsStringSync())
              as Map<String, dynamic>;
      // `CLAUDE_CONFIG_DIR` makes this file the CLI's user-scope settings, so
      // without it every pooled account commits with the CLI's stock
      // `Co-Authored-By: Claude` trailer.
      expect(settings['attribution'], {
        'commits': false,
        'pullRequests': false,
      });
      // The deprecated key is deliberately never written.
      expect(settings.containsKey('includeCoAuthoredBy'), isFalse);
    });

    test('is idempotent — a correctly seeded file is not rewritten', () async {
      final account = await store.create(label: 'A');
      final file = settingsFile(store, account.id)
        ..writeAsStringSync(
          jsonEncode({
            'attribution': {'commits': false, 'pullRequests': false},
            'theme': 'dark',
          }),
          flush: true,
        );
      // `prepareForRun` runs before EVERY dispatch; rewriting the file each
      // time would churn a settings file the CLI may be reading.
      final before = file.lastModifiedSync();
      await store.prepareForRun(
        accountId: account.id,
        workingDirectory: '/tmp/x',
      );
      expect(file.lastModifiedSync(), before);
      expect(
        jsonDecode(file.readAsStringSync()),
        containsPair('theme', 'dark'),
      );
    });

    test('keeps unrelated keys when merging the block in', () async {
      final account = await store.create(label: 'A');
      final file = settingsFile(store, account.id)
        ..writeAsStringSync('{"effortLevel": "high"}');

      await store.prepareForRun(
        accountId: account.id,
        workingDirectory: '/tmp/x',
      );

      final settings = jsonDecode(file.readAsStringSync()) as Map;
      expect(settings['effortLevel'], 'high');
      expect(settings['attribution'], {
        'commits': false,
        'pullRequests': false,
      });
    });

    test('respects an explicit attribution block the operator wrote', () async {
      final account = await store.create(label: 'A');
      final file = settingsFile(store, account.id)
        ..writeAsStringSync(
          jsonEncode({
            'attribution': {
              'commits': true,
              'pullRequests': false,
              'commitByline': 'Signed-off-by: Acme Bot <bot@acme.dev>',
            },
          }),
        );

      await store.prepareForRun(
        accountId: account.id,
        workingDirectory: '/tmp/x',
      );

      // Suppression is a default, not a policy: an operator who customized
      // attribution in an account dir has said their piece.
      final settings = jsonDecode(file.readAsStringSync()) as Map;
      expect((settings['attribution'] as Map)['commits'], isTrue);
      expect(
        (settings['attribution'] as Map)['commitByline'],
        'Signed-off-by: Acme Bot <bot@acme.dev>',
      );
    });

    test('leaves a settings.json that is not a JSON object alone', () async {
      final account = await store.create(label: 'A');
      final file = settingsFile(store, account.id)
        ..writeAsStringSync('[1, 2, 3]');

      await store.prepareForRun(
        accountId: account.id,
        workingDirectory: '/tmp/x',
      );

      // The CLI's to repair, not ours to overwrite — clobbering it could
      // discard whatever the operator staged there.
      expect(file.readAsStringSync(), '[1, 2, 3]');
    });
  });
}
