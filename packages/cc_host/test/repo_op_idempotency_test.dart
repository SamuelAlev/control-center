import 'package:cc_domain/cc_domain.dart';
import 'package:cc_host/cc_host.dart';
import 'package:test/test.dart';

/// An in-memory [WriteLedgerPort] for the dispatcher idempotency tests.
class _FakeLedger implements WriteLedgerPort {
  final Map<String, Map<String, dynamic>> _rows = {};
  int records = 0;

  String _k(String ws, String key) => '$ws|$key';

  @override
  Future<Map<String, dynamic>?> find(String workspaceId, String key) async =>
      _rows[_k(workspaceId, key)];

  @override
  Future<void> record({
    required String workspaceId,
    required String key,
    required String opName,
    required Map<String, dynamic> data,
  }) async {
    records++;
    _rows.putIfAbsent(_k(workspaceId, key), () => data);
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
