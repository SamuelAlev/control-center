import 'dart:convert';
import 'dart:io';

import 'package:cc_infra/src/sandboxing/claude_native_session.dart';
import 'package:cc_infra/src/sandboxing/file_claude_native_session_store.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../helpers/windows_safe_delete.dart';

ClaudeNativeSessionScope scope({
  String workspace = 'ws-1',
  String conversation = 'conv-1',
  String agent = 'agent-1',
  String account = '/accounts/a',
  String workdir = '/work/tree',
  String policy = 'policy-v1',
}) => ClaudeNativeSessionScope(
  workspaceId: workspace,
  conversationId: conversation,
  agentId: agent,
  accountId: account,
  workdir: workdir,
  policyFingerprint: policy,
);

void main() {
  group('ClaudeNativeSessionScope', () {
    test('identical parts produce the same key', () {
      expect(scope().storageKey, scope().storageKey);
    });

    test('every scope part changes the key', () {
      final base = scope().storageKey;
      expect(scope(workspace: 'ws-2').storageKey, isNot(base));
      expect(scope(conversation: 'conv-2').storageKey, isNot(base));
      expect(scope(agent: 'agent-2').storageKey, isNot(base));
      expect(scope(account: '/accounts/b').storageKey, isNot(base));
      expect(scope(workdir: '/work/other').storageKey, isNot(base));
      expect(scope(policy: 'policy-v2').storageKey, isNot(base));
    });

    test('parts cannot be smuggled across the delimiter', () {
      // A value that embeds the join delimiter must not collide with a scope
      // whose parts split differently.
      final a = scope(workspace: 'a', conversation: 'b').storageKey;
      final b = scope(workspace: 'a\u0000conv=b', conversation: '').storageKey;
      expect(a, isNot(b));
    });
  });

  group('ClaudeModelUsageSnapshot', () {
    test('delta subtracts and floors at zero', () {
      const before = ClaudeModelUsageSnapshot(inputTokens: 10, costUsd: 1.0);
      const after = ClaudeModelUsageSnapshot(inputTokens: 25, costUsd: 1.75);
      final d = after.delta(before);
      expect(d.inputTokens, 15);
      expect(d.costUsd, closeTo(0.75, 1e-9));
      // A counter that shrank (a reset) must not produce a negative.
      final shrunk = before.delta(after);
      expect(shrunk.inputTokens, 0);
    });

    test('round-trips through JSON', () {
      const snap = ClaudeModelUsageSnapshot(
        inputTokens: 1,
        outputTokens: 2,
        cacheReadTokens: 3,
        cacheWriteTokens: 4,
        costUsd: 0.5,
        costBasis: 'list',
      );
      final restored = ClaudeModelUsageSnapshot.fromJson(snap.toJson());
      expect(restored.inputTokens, 1);
      expect(restored.outputTokens, 2);
      expect(restored.cacheReadTokens, 3);
      expect(restored.cacheWriteTokens, 4);
      expect(restored.costUsd, 0.5);
      expect(restored.costBasis, 'list');
    });
  });

  group('ClaudeNativeSessionRecord', () {
    ClaudeNativeSessionRecord record() => ClaudeNativeSessionRecord(
      storageKey: scope().storageKey,
      sessionId: 'sess-abc',
      policyFingerprint: 'policy-v1',
      conversationRevision: 'rev-1',
      createdAt: DateTime.utc(2026, 1, 1),
      lastUsedAt: DateTime.utc(2026, 1, 2),
      turns: 3,
      cumulativeCostUsd: 1.25,
      modelUsage: const {
        'main': ClaudeModelUsageSnapshot(inputTokens: 9, costUsd: 1.25),
      },
    );

    test('round-trips through JSON, baseline included', () {
      final restored = ClaudeNativeSessionRecord.fromJson(record().toJson())!;
      expect(restored.storageKey, scope().storageKey);
      expect(restored.sessionId, 'sess-abc');
      expect(restored.policyFingerprint, 'policy-v1');
      expect(restored.turns, 3);
      expect(restored.cumulativeCostUsd, 1.25);
      expect(restored.modelUsage['main']!.inputTokens, 9);
      expect(restored.createdAt, DateTime.utc(2026, 1, 1));
      // The delivered-conversation cursor and the CLI-restorability flag
      // travel with the record.
      expect(restored.conversationRevision, 'rev-1');
      expect(restored.cliRestoresTotals, isFalse);
    });

    test(
      'a record with no conversation cursor cannot establish continuity',
      () {
        final json = record().toJson()..remove('conversationRevision');
        expect(ClaudeNativeSessionRecord.fromJson(json), isNull);
      },
    );

    test('the cursor lists are bounded to the most recent window', () {
      final long = [for (var i = 0; i < 400; i++) 'k$i'];
      final bounded = ClaudeNativeSessionRecord.bound(long);
      expect(bounded, hasLength(ClaudeNativeSessionRecord.maxCursorEntries));
      // The most recent window is what a delta is drawn from.
      expect(bounded.last, 'k399');
      expect(bounded.first, isNot('k0'));
      // A short list is returned untouched.
      expect(ClaudeNativeSessionRecord.bound(const ['a', 'b']), ['a', 'b']);
    });

    test('a record missing its ids is rejected (degrades to no resume)', () {
      expect(ClaudeNativeSessionRecord.fromJson(const {}), isNull);
      expect(
        ClaudeNativeSessionRecord.fromJson(const {
          'storageKey': 'k',
          'sessionId': '',
          'policyFingerprint': 'p',
        }),
        isNull,
      );
    });
  });

  group('InMemoryClaudeNativeSessionStore', () {
    test('saves, loads and clears by workspace + key', () async {
      final store = InMemoryClaudeNativeSessionStore();
      final key = scope().storageKey;
      expect(await store.load(workspaceId: 'ws-1', storageKey: key), isNull);
      await store.save(
        workspaceId: 'ws-1',
        record: ClaudeNativeSessionRecord(
          storageKey: key,
          sessionId: 's',
          policyFingerprint: 'p',
          conversationRevision: 'rev',
          createdAt: DateTime.utc(2026),
          lastUsedAt: DateTime.utc(2026),
        ),
      );
      expect(
        (await store.load(workspaceId: 'ws-1', storageKey: key))!.sessionId,
        's',
      );
      await store.clear(workspaceId: 'ws-1', storageKey: key);
      expect(await store.load(workspaceId: 'ws-1', storageKey: key), isNull);
    });

    test('NoopClaudeNativeSessionStore remembers nothing', () async {
      const store = NoopClaudeNativeSessionStore();
      await store.save(
        workspaceId: 'ws-1',
        record: ClaudeNativeSessionRecord(
          storageKey: 'k',
          sessionId: 's',
          policyFingerprint: 'p',
          conversationRevision: 'rev',
          createdAt: DateTime.utc(2026),
          lastUsedAt: DateTime.utc(2026),
        ),
      );
      expect(await store.load(workspaceId: 'ws-1', storageKey: 'k'), isNull);
    });
  });

  group('FileClaudeNativeSessionStore', () {
    late Directory root;
    late FileClaudeNativeSessionStore store;

    setUp(() {
      root = Directory.systemTemp.createTempSync('cc_claude_sessions_');
      store = FileClaudeNativeSessionStore(
        workspaceDir: (ws) => p.join(root.path, ws),
      );
    });

    tearDown(() => deleteDirBestEffort(root));

    ClaudeNativeSessionRecord record(String key, {String id = 'sess-1'}) =>
        ClaudeNativeSessionRecord(
          storageKey: key,
          sessionId: id,
          policyFingerprint: 'p',
          conversationRevision: 'rev',
          createdAt: DateTime.utc(2026),
          lastUsedAt: DateTime.utc(2026),
          cumulativeCostUsd: 0.5,
        );

    test(
      'survives a restart (a fresh store instance reads the record)',
      () async {
        final key = scope().storageKey;
        await store.save(workspaceId: 'ws-1', record: record(key));

        final reopened = FileClaudeNativeSessionStore(
          workspaceDir: (ws) => p.join(root.path, ws),
        );
        final loaded = await reopened.load(
          workspaceId: 'ws-1',
          storageKey: key,
        );
        expect(loaded, isNotNull);
        expect(loaded!.sessionId, 'sess-1');
        expect(loaded.cumulativeCostUsd, 0.5);
      },
    );

    test('keeps scopes apart', () async {
      final a = scope().storageKey;
      final b = scope(conversation: 'conv-2').storageKey;
      await store.save(
        workspaceId: 'ws-1',
        record: record(a, id: 'A'),
      );
      await store.save(
        workspaceId: 'ws-1',
        record: record(b, id: 'B'),
      );

      expect(
        (await store.load(workspaceId: 'ws-1', storageKey: a))!.sessionId,
        'A',
      );
      expect(
        (await store.load(workspaceId: 'ws-1', storageKey: b))!.sessionId,
        'B',
      );
    });

    test('keeps workspaces apart even for the same key', () async {
      final key = scope().storageKey;
      await store.save(
        workspaceId: 'ws-1',
        record: record(key, id: 'ONE'),
      );
      await store.save(
        workspaceId: 'ws-2',
        record: record(key, id: 'TWO'),
      );
      expect(
        (await store.load(workspaceId: 'ws-1', storageKey: key))!.sessionId,
        'ONE',
      );
      expect(
        (await store.load(workspaceId: 'ws-2', storageKey: key))!.sessionId,
        'TWO',
      );
    });

    test('a later save replaces the earlier one', () async {
      final key = scope().storageKey;
      await store.save(
        workspaceId: 'ws-1',
        record: record(key, id: 'old'),
      );
      await store.save(
        workspaceId: 'ws-1',
        record: record(key, id: 'new'),
      );
      expect(
        (await store.load(workspaceId: 'ws-1', storageKey: key))!.sessionId,
        'new',
      );
    });

    test(
      'clear removes the record and a missing record loads as null',
      () async {
        final key = scope().storageKey;
        await store.save(workspaceId: 'ws-1', record: record(key));
        await store.clear(workspaceId: 'ws-1', storageKey: key);
        expect(await store.load(workspaceId: 'ws-1', storageKey: key), isNull);
        // Clearing again is harmless.
        await store.clear(workspaceId: 'ws-1', storageKey: key);
      },
    );

    /// Every record file the store has written for [workspace].
    List<File> filesFor(String workspace) {
      final dir = Directory(p.join(root.path, workspace));
      if (!dir.existsSync()) {
        return const [];
      }
      return [
        for (final entity in dir.listSync(recursive: true))
          if (entity is File && entity.path.endsWith('.json')) entity,
      ];
    }

    test('a corrupt file degrades to null, not a throw', () async {
      final key = scope().storageKey;
      await store.save(workspaceId: 'ws-1', record: record(key));
      await filesFor('ws-1').single.writeAsString('{ not json');

      expect(await store.load(workspaceId: 'ws-1', storageKey: key), isNull);
    });

    test('a missing workspace or key is a no-op', () async {
      await store.save(workspaceId: '', record: record('k'));
      await store.save(workspaceId: 'ws-1', record: record(''));
      expect(await store.load(workspaceId: '', storageKey: 'k'), isNull);
      expect(await store.load(workspaceId: 'ws-1', storageKey: ''), isNull);
      expect(filesFor('ws-1'), isEmpty);
    });

    test('concurrent saves of one key end with one valid record', () async {
      final key = scope().storageKey;
      await Future.wait([
        for (var i = 0; i < 6; i++)
          store.save(
            workspaceId: 'ws-1',
            record: record(key, id: 'i$i'),
          ),
      ]);
      final files = filesFor('ws-1');
      // Exactly one record file, fully written and decodable — no partial
      // write left behind.
      expect(files, hasLength(1));
      expect(
        jsonDecode(await files.single.readAsString()),
        isA<Map<String, dynamic>>(),
      );
      expect(
        (await store.load(workspaceId: 'ws-1', storageKey: key))!.sessionId,
        startsWith('i'),
      );
    });
  });
}
