import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/ports/run_credential_gate_port.dart';
import 'package:cc_domain/core/domain/repositories/workspace_settings_repository.dart';
import 'package:cc_domain/core/domain/value_objects/account_pool.dart';
import 'package:cc_infra/cc_infra.dart' show CredentialCooldownStore;
import 'package:cc_server_core/cc_server_core.dart';
import 'package:test/test.dart';

/// In-memory settings, so the rotation rules are exercised without a database.
class _Settings implements WorkspaceSettingsRepository {
  final Map<String, String> values = {};

  @override
  Future<String?> get(String workspaceId, String key) async =>
      values['$workspaceId/$key'];

  @override
  Future<void> set(String workspaceId, String key, String? value) async {
    if (value == null) {
      values.remove('$workspaceId/$key');
    } else {
      values['$workspaceId/$key'] = value;
    }
  }

  @override
  Future<Map<String, String>> getAll(String workspaceId) async => {};

  @override
  Stream<Map<String, String>> watchAll(String workspaceId) =>
      const Stream.empty();
}

void main() {
  late _Settings settings;
  late Directory dir;
  late DateTime clock;
  late CredentialCooldownStore cooldowns;

  const ws = 'ws-1';
  const provider = 'openai';

  setUp(() {
    settings = _Settings();
    dir = Directory.systemTemp.createTempSync('cc-harness-rot-');
    clock = DateTime.utc(2026, 8, 24, 12);
    cooldowns = CredentialCooldownStore(dataDir: dir.path, now: () => clock);
  });

  tearDown(() {
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });

  Future<void> setPool(AccountPool pool, {String? agentId}) => settings.set(
    ws,
    accountPoolKey(AccountPoolLanes.harness(provider), agentId)!,
    jsonEncode(pool.toJson()),
  );

  Future<AccountPoolOrder> resolve({
    String? agentId,
    List<String> credentialIds = const ['a', 'b', 'c'],
  }) => resolveHarnessRotationOrder(
    settings: settings,
    cooldowns: cooldowns,
    workspaceId: ws,
    agentId: agentId,
    providerId: provider,
    credentialIds: credentialIds,
  );

  Future<List<String>?> order({
    String? agentId,
    List<String> credentialIds = const ['a', 'b', 'c'],
  }) async {
    final answer = await resolve(
      agentId: agentId,
      credentialIds: credentialIds,
    );
    expect(answer.refusal, isNull);
    return answer.order;
  }

  group('unconfigured', () {
    test('no pool leaves the store order alone', () async {
      // Null, not a reordered list: every install that never opens the screen
      // must keep the exact chain it had before pools existed.
      expect(await order(), isNull);
    });

    test('one credential still follows the pool', () async {
      // Consulted even for one key, so a pool that excludes it can refuse.
      await setPool(const AccountPool(accountIds: ['a']));
      expect(await order(credentialIds: ['a']), ['a']);
    });

    test(
      'a corrupt pool falls through instead of stopping the dispatch',
      () async {
        await settings.set(
          ws,
          accountPoolKey(AccountPoolLanes.harness(provider), null)!,
          '{ not json',
        );
        expect(await order(), isNull);
      },
    );
  });

  group('a pool naming only removed credentials', () {
    test('refuses, exactly as the Claude Code lane does', () async {
      // Ignoring it would fall back to every stored key — the ones the pool
      // was written to keep this scope off.
      await setPool(const AccountPool(accountIds: ['gone', 'also-gone']));
      final answer = await resolve();
      expect(answer.order, isNull);
      expect(answer.refusal?.reason, RunCredentialReason.accountsRemoved);
      expect(answer.refusal?.accountIds, ['gone', 'also-gone']);
    });

    test('refuses with only one key left on the store', () async {
      await setPool(const AccountPool(accountIds: ['gone']), agentId: 'ag');
      final answer = await resolve(agentId: 'ag', credentialIds: ['a']);
      expect(answer.refusal?.reason, RunCredentialReason.accountsRemoved);
    });
  });

  group('pinned / serial', () {
    test('leads with the first attached credential', () async {
      await setPool(const AccountPool(accountIds: ['c', 'a']));
      expect(await order(), ['c', 'a']);
    });

    test('the pool also RESTRICTS which credentials may be spent', () async {
      // 'b' is stored but not attached, so it must not appear as a fallback
      // target — attaching a subset is how a workspace says "not that key".
      await setPool(const AccountPool(accountIds: ['a', 'c']));
      expect(await order(), ['a', 'c']);
    });

    test('serial skips a cooling-off credential', () async {
      await setPool(
        const AccountPool(
          accountIds: ['a', 'b', 'c'],
          strategy: AccountRotationStrategy.serial,
        ),
      );
      await cooldowns.mark(provider, 'a');
      final result = await order();
      expect(result!.first, 'b', reason: 'a is spent');
      // …but 'a' stays in the chain: FallbackProvider retries a capacity error
      // on the same target after backoff, so a window that reopens mid-turn
      // can still serve the run.
      expect(result, containsAll(['a', 'b', 'c']));
    });
  });

  group('round robin', () {
    setUp(() async {
      await setPool(
        const AccountPool(
          accountIds: ['a', 'b', 'c'],
          strategy: AccountRotationStrategy.roundRobin,
        ),
      );
    });

    test('a different credential leads each dispatch, and it wraps', () async {
      expect((await order())!.first, 'a');
      expect((await order())!.first, 'b');
      expect((await order())!.first, 'c');
      expect((await order())!.first, 'a');
    });

    test('the cursor is persisted BEFORE the run', () async {
      // Two dispatches racing must not read the same cursor and lead with the
      // same credential.
      await order();
      expect(
        settings
            .values['$ws/${accountPoolKey(AccountPoolLanes.harness(provider), null)}.cursor'],
        '1',
      );
    });

    test('the others stay as fallback behind the leader', () async {
      expect(await order(), ['a', 'b', 'c']);
      expect(await order(), [
        'b',
        'a',
        'c',
      ], reason: 'leader first, pool order after');
    });
  });

  group('scope', () {
    test('an agent pool overrides the workspace one', () async {
      await setPool(const AccountPool(accountIds: ['a', 'b', 'c']));
      await setPool(const AccountPool(accountIds: ['c']), agentId: 'agent-1');
      expect(await order(agentId: 'agent-1'), ['c']);
      expect(await order(), ['a', 'b', 'c']);
    });

    test(
      'an empty agent pool falls back to the workspace, not to nothing',
      () async {
        // An empty list is what an editor leaves behind when the last row is
        // removed; reading it as a deliberate opt-out would stop every run for
        // that agent.
        await setPool(const AccountPool(accountIds: ['a', 'b']));
        await setPool(const AccountPool(), agentId: 'agent-1');
        expect(await order(agentId: 'agent-1'), ['a', 'b']);
      },
    );

    test(
      'agent and workspace pools keep separate round-robin cursors',
      () async {
        await setPool(
          const AccountPool(
            accountIds: ['a', 'b'],
            strategy: AccountRotationStrategy.roundRobin,
          ),
        );
        await setPool(
          const AccountPool(
            accountIds: ['b', 'c'],
            strategy: AccountRotationStrategy.roundRobin,
          ),
          agentId: 'agent-1',
        );
        // Advancing one must not move the other's position.
        expect((await order())!.first, 'a');
        expect((await order(agentId: 'agent-1'))!.first, 'b');
        expect((await order())!.first, 'b');
        expect((await order(agentId: 'agent-1'))!.first, 'c');
      },
    );
  });

  group('everything cooling off', () {
    test('still hands over the pool rather than refusing', () async {
      // Unlike the Claude Code lane, which refuses before spawning: the harness
      // retries a capacity error on the same target after backoff, so refusing
      // here would be strictly worse than letting the chain try.
      await setPool(const AccountPool(accountIds: ['a', 'b']));
      await cooldowns.mark(provider, 'a');
      await cooldowns.mark(provider, 'b');
      expect(await order(), ['a', 'b']);
    });
  });

  group('prunedAccountPools — one clean-up for every lane', () {
    String pool(List<String> ids) =>
        jsonEncode(AccountPool(accountIds: ids).toJson());

    final settings = {
      'claude_accounts.pool': pool(['gone', 'a', 'b']),
      'claude_accounts.pool.agent.x': pool(['gone', 'a']),
      'claude_accounts.pool.agent.y': pool(['b']),
      'claude_accounts.pool.agent.x.cursor': '3',
      'harness_accounts.pool.openai': pool(['gone', 'a']),
      'harness_accounts.pool.openai.agent.x': pool(['gone', 'b']),
      'harness_accounts.pool.openai-compat': pool(['gone', 'a']),
      'unrelated': 'value',
    };

    List<String> ids(String json) => AccountPool.fromJson(
      jsonDecode(json) as Map<String, dynamic>,
    ).accountIds;

    test('the Claude lane touches only Claude pools', () {
      final out = prunedAccountPools(
        settings,
        lane: AccountPoolLanes.claudeCode,
        existing: {'a', 'b'},
      );
      expect(out.keys, {
        'claude_accounts.pool',
        'claude_accounts.pool.agent.x',
      });
      expect(ids(out['claude_accounts.pool']!), ['a', 'b']);
      expect(ids(out['claude_accounts.pool.agent.x']!), ['a']);
    });

    test("a harness lane touches only that provider's pools", () {
      final out = prunedAccountPools(
        settings,
        lane: AccountPoolLanes.harness('openai'),
        existing: {'a', 'b'},
      );
      expect(out.keys, {
        'harness_accounts.pool.openai',
        'harness_accounts.pool.openai.agent.x',
      });
    });

    test('leaves a pool alone rather than emptying it', () {
      // Emptied, the agent would inherit the workspace's accounts — exactly
      // the ones it was configured to stay off.
      expect(
        prunedAccountPools(
          {
            'claude_accounts.pool.agent.x': pool(['gone']),
          },
          lane: AccountPoolLanes.claudeCode,
          existing: {'a'},
        ),
        isEmpty,
      );
    });

    test('skips a corrupt pool and an unknown lane', () {
      expect(
        prunedAccountPools(
          {'claude_accounts.pool': '{not json'},
          lane: AccountPoolLanes.claudeCode,
          existing: {'a'},
        ),
        isEmpty,
      );
      expect(
        prunedAccountPools(settings, lane: 'nope', existing: {'a'}),
        isEmpty,
      );
    });
  });

  group('accountPoolKey', () {
    test('keeps the keys existing pools were written under', () {
      expect(
        accountPoolKey(AccountPoolLanes.claudeCode, null),
        'claude_accounts.pool',
      );
      expect(
        accountPoolKey(AccountPoolLanes.claudeCode, 'ag'),
        'claude_accounts.pool.agent.ag',
      );
      expect(
        accountPoolKey(AccountPoolLanes.harness('qwen'), 'ag'),
        'harness_accounts.pool.qwen.agent.ag',
      );
    });

    test('refuses a lane it does not know', () {
      expect(accountPoolKey('anything', null), isNull);
      expect(accountPoolKey('harness:', null), isNull);
    });
  });
}
