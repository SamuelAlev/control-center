import 'dart:async';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_host/cc_host.dart';
import 'package:test/test.dart';

/// An in-memory [WriteLedgerPort] for the dispatcher idempotency tests. A key
/// mapped to null is claimed and not yet completed.
class _FakeLedger implements WriteLedgerPort {
  final Map<String, Map<String, dynamic>?> _rows = {};
  int records = 0;
  int releases = 0;

  String _k(String ws, String key) => '$ws|$key';

  bool holds(String ws, String key) => _rows.containsKey(_k(ws, key));

  @override
  Future<WriteLedgerClaim> claim({
    required String workspaceId,
    required String key,
    required String opName,
  }) async {
    final k = _k(workspaceId, key);
    if (!_rows.containsKey(k)) {
      _rows[k] = null;
      return const LedgerClaimed();
    }
    final data = _rows[k];
    return data == null ? const LedgerInProgress() : LedgerReplay(data);
  }

  @override
  Future<bool> complete({
    required String workspaceId,
    required String key,
    required Map<String, dynamic> data,
  }) async {
    final k = _k(workspaceId, key);
    if (!_rows.containsKey(k) || _rows[k] != null) {
      return false;
    }
    records++;
    _rows[k] = data;
    return true;
  }

  @override
  Future<void> release({
    required String workspaceId,
    required String key,
  }) async {
    final k = _k(workspaceId, key);
    if (_rows.containsKey(k) && _rows[k] == null) {
      releases++;
      _rows.remove(k);
    }
  }
}

/// PRD 19 §3/§4: dispatcher-level idempotency dedupe and dry-run preview.
void main() {
  RepoOpDispatcher dispatcher(List<RepoOp> ops, {WriteLedgerPort? ledger}) =>
      RepoOpDispatcher(registry: RepoOpRegistry(ops), writeLedger: ledger);

  Future<Map<String, dynamic>> call(
    RepoOpDispatcher d,
    String op, {
    Map<String, dynamic> args = const {'workspace_id': 'ws-1'},
    String? idempotencyKey,
    bool dryRun = false,
  }) => d.call(
    id: 1,
    params: {
      'op': op,
      'idempotency_key': ?idempotencyKey,
      if (dryRun) 'dry_run': true,
      'args': args,
    },
    deviceId: 'caller',
    userId: 'user-1',
    sessionCapability: SessionCapability.fullClient,
  );

  group('idempotency dedupe', () {
    test(
      'a repeated key applies once and returns deduplicated: true',
      () async {
        var runs = 0;
        final ledger = _FakeLedger();
        final d = dispatcher([
          RepoOp(
            name: 'thing.mutate',
            kind: RepoOpKind.mutate,
            undoClass: UndoClass.reversible,
            handler: (ctx) async {
              runs++;
              return {'applied': runs};
            },
          ),
        ], ledger: ledger);

        final first = await call(d, 'thing.mutate', idempotencyKey: 'k1');
        expect(first['error'], isNull);
        expect((first['result'] as Map)['data'], {'applied': 1});
        expect((first['result'] as Map)['deduplicated'], isNull);

        final replay = await call(d, 'thing.mutate', idempotencyKey: 'k1');
        expect((replay['result'] as Map)['deduplicated'], isTrue);
        // Byte-identical replay of the first application's result.
        expect((replay['result'] as Map)['data'], {'applied': 1});
        // The handler ran exactly once; the ledger recorded exactly once.
        expect(runs, 1);
        expect(ledger.records, 1);
      },
    );

    test(
      'a duplicate arriving while the first is running is refused',
      () async {
        var runs = 0;
        final gate = Completer<void>();
        final ledger = _FakeLedger();
        final d = dispatcher([
          RepoOp(
            name: 'thing.mutate',
            kind: RepoOpKind.mutate,
            handler: (ctx) async {
              runs++;
              await gate.future;
              return {'applied': runs};
            },
          ),
        ], ledger: ledger);

        final first = call(d, 'thing.mutate', idempotencyKey: 'k1');
        final second = await call(d, 'thing.mutate', idempotencyKey: 'k1');
        final error = second['error'] as Map;
        expect(error['code'], RpcErrorCodes.conflict);
        expect((error['data'] as Map)['kind'], idempotencyInProgressKind);

        gate.complete();
        expect(((await first)['result'] as Map)['data'], {'applied': 1});
        expect(runs, 1);
        final replay = await call(d, 'thing.mutate', idempotencyKey: 'k1');
        expect((replay['result'] as Map)['deduplicated'], isTrue);
        expect(runs, 1);
      },
    );

    test('a failed handler releases the key so a retry runs', () async {
      var runs = 0;
      final ledger = _FakeLedger();
      final d = dispatcher([
        RepoOp(
          name: 'thing.mutate',
          kind: RepoOpKind.mutate,
          handler: (ctx) async {
            runs++;
            if (runs == 1) {
              throw StateError('transient');
            }
            return {'applied': runs};
          },
        ),
      ], ledger: ledger);

      final failed = await call(d, 'thing.mutate', idempotencyKey: 'k1');
      expect(failed['error'], isNotNull);
      expect(ledger.holds('ws-1', 'k1'), isFalse);

      final retry = await call(d, 'thing.mutate', idempotencyKey: 'k1');
      expect((retry['result'] as Map)['data'], {'applied': 2});
      expect((retry['result'] as Map)['deduplicated'], isNull);
      expect(runs, 2);
    });

    test('a refusal before the handler releases the key', () async {
      var runs = 0;
      final ledger = _FakeLedger();
      final d = dispatcher([
        RepoOp(
          name: 'thing.destroy',
          kind: RepoOpKind.destructive,
          handler: (ctx) async {
            runs++;
            return {'ok': true};
          },
        ),
      ], ledger: ledger);

      // No approver: destructive ops are refused before the handler.
      final refused = await call(d, 'thing.destroy', idempotencyKey: 'k1');
      expect((refused['error'] as Map)['code'], RpcErrorCodes.unauthorized);
      expect(runs, 0);
      expect(ledger.holds('ws-1', 'k1'), isFalse);
      expect(ledger.releases, 1);
    });

    test('distinct keys each apply', () async {
      var runs = 0;
      final d = dispatcher([
        RepoOp(
          name: 'thing.mutate',
          kind: RepoOpKind.mutate,
          handler: (ctx) async {
            runs++;
            return {'applied': runs};
          },
        ),
      ], ledger: _FakeLedger());
      await call(d, 'thing.mutate', idempotencyKey: 'a');
      await call(d, 'thing.mutate', idempotencyKey: 'b');
      expect(runs, 2);
    });

    test('no key means no dedupe (every call applies)', () async {
      var runs = 0;
      final d = dispatcher([
        RepoOp(
          name: 'thing.mutate',
          kind: RepoOpKind.mutate,
          handler: (ctx) async {
            runs++;
            return {'applied': runs};
          },
        ),
      ], ledger: _FakeLedger());
      await call(d, 'thing.mutate');
      await call(d, 'thing.mutate');
      expect(runs, 2);
    });

    test('reads are never deduped even with a key', () async {
      var runs = 0;
      final ledger = _FakeLedger();
      final d = dispatcher([
        RepoOp(
          name: 'thing.get',
          kind: RepoOpKind.read,
          handler: (ctx) async {
            runs++;
            return {'read': runs};
          },
        ),
      ], ledger: ledger);
      await call(d, 'thing.get', idempotencyKey: 'k');
      await call(d, 'thing.get', idempotencyKey: 'k');
      expect(runs, 2);
      expect(ledger.records, 0);
    });
  });

  group('failure logging', () {
    final logged = <String>[];
    final errors = <Object?>[];
    setUp(() {
      logged.clear();
      errors.clear();
      CcHostLog.sink = (level, message, [error, stackTrace]) {
        logged.add(message);
        errors.add(error);
      };
    });
    tearDown(() => CcHostLog.sink = null);

    test('an unmapped failure is logged only through describeError', () async {
      final d = RepoOpDispatcher(
        registry: RepoOpRegistry([
          RepoOp(
            name: 'thing.mutate',
            kind: RepoOpKind.mutate,
            handler: (ctx) async => throw StateError('bound value: secret'),
          ),
        ]),
        describeError: (e) => 'redacted ${e.runtimeType}',
      );
      final res = await call(d, 'thing.mutate');
      expect((res['error'] as Map)['code'], RpcErrorCodes.internalError);
      expect(logged.single, contains('redacted StateError'));
      expect(logged.single, isNot(contains('secret')));
      // The raw error object is never handed to the log sink either.
      expect(errors.single, isNull);
    });
  });

  group('dry-run preview', () {
    test('a preview op returns its ActionPreview and never applies', () async {
      var applied = false;
      final d = dispatcher([
        RepoOp(
          name: 'thing.merge',
          kind: RepoOpKind.mutate,
          undoClass: UndoClass.irreversible,
          preview: (ctx) async => const ActionPreview(
            summary: 'Merge 5 PRs',
            warnings: ['cannot be undone'],
          ),
          handler: (ctx) async {
            applied = true;
            return {'ok': true};
          },
        ),
      ]);
      final res = await call(d, 'thing.merge', dryRun: true);
      expect(res['error'], isNull);
      expect((res['result'] as Map)['dry_run'], isTrue);
      final preview = ActionPreview.fromJson(
        ((res['result'] as Map)['data'] as Map).cast<String, dynamic>(),
      );
      expect(preview.summary, 'Merge 5 PRs');
      expect(preview.warnings, ['cannot be undone']);
      expect(applied, isFalse);
    });

    test('an op with no preview rejects dry-run honestly', () async {
      final d = dispatcher([
        RepoOp(
          name: 'thing.mutate',
          kind: RepoOpKind.mutate,
          handler: (ctx) async => {'ok': true},
        ),
      ]);
      final res = await call(d, 'thing.mutate', dryRun: true);
      expect((res['error'] as Map)['code'], RpcErrorCodes.validation);
      expect((res['error'] as Map)['message'], contains('dry-run'));
    });
  });
}
