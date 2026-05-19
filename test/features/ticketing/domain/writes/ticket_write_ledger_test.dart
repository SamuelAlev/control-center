import 'package:cc_domain/features/ticketing/domain/writes/ticket_write_ledger.dart';
import 'package:cc_domain/features/ticketing/domain/writes/ticket_write_result.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeLedgerRepo implements TicketWriteLedgerRepository {
  final Map<String, TicketWriteLedgerEntry> store = {};
  String _key(String w, String id) => '$w|$id';

  @override
  Future<TicketWriteLedgerEntry?> find(String w, String id) async =>
      store[_key(w, id)];
  @override
  Future<void> record(TicketWriteLedgerEntry e) async =>
      store[_key(e.workspaceId, e.writeId)] = e;
}

void main() {
  late _FakeLedgerRepo repo;
  late TicketWriteLedger ledger;
  const ws = 'ws-1';

  setUp(() {
    repo = _FakeLedgerRepo();
    ledger = TicketWriteLedger(repository: repo, now: () => DateTime.utc(2026));
  });

  test('runs the write the first time and records it', () async {
    var calls = 0;
    final result = await ledger.runOnce(
      workspaceId: ws,
      writeId: 'w1',
      operation: 'comment_add',
      run: () async {
        calls++;
        return const TicketWriteResult.ok({'ticket_id': 't1'});
      },
    );
    expect(calls, 1);
    expect(result.ok, isTrue);
    expect(result.deduplicated, isFalse);
    expect(repo.store, hasLength(1));
  });

  test('replays the cached result on a retry with meta.deduplicated', () async {
    var calls = 0;
    Future<TicketWriteResult> run() async {
      calls++;
      return const TicketWriteResult.ok({'ticket_id': 't1', 'commented': true});
    }

    final first = await ledger.runOnce(
      workspaceId: ws,
      writeId: 'w1',
      operation: 'comment_add',
      run: run,
    );
    final second = await ledger.runOnce(
      workspaceId: ws,
      writeId: 'w1',
      operation: 'comment_add',
      run: run,
    );

    expect(calls, 1, reason: 'the write must run only once');
    expect(first.deduplicated, isFalse);
    expect(second.deduplicated, isTrue);
    expect(second.data['ticket_id'], 't1');
    expect(second.toJson()['meta'], {'deduplicated': true});
  });

  test('does not dedupe when no writeId is given', () async {
    var calls = 0;
    Future<TicketWriteResult> run() async {
      calls++;
      return const TicketWriteResult.ok({});
    }

    await ledger.runOnce(
      workspaceId: ws,
      writeId: null,
      operation: 'x',
      run: run,
    );
    await ledger.runOnce(
      workspaceId: ws,
      writeId: '',
      operation: 'x',
      run: run,
    );
    expect(calls, 2);
    expect(repo.store, isEmpty);
  });

  test('does not cache a failure (retryable with same writeId)', () async {
    var calls = 0;
    final first = await ledger.runOnce(
      workspaceId: ws,
      writeId: 'w1',
      operation: 'status_set',
      run: () async {
        calls++;
        return const TicketWriteResult.failure(
          TicketWriteErrorCode.conflict,
          'lost race',
        );
      },
    );
    expect(first.ok, isFalse);
    expect(repo.store, isEmpty);

    final second = await ledger.runOnce(
      workspaceId: ws,
      writeId: 'w1',
      operation: 'status_set',
      run: () async {
        calls++;
        return const TicketWriteResult.ok({'ticket_id': 't1'});
      },
    );
    expect(calls, 2, reason: 'a failed write must be retryable');
    expect(second.ok, isTrue);
    expect(second.deduplicated, isFalse);
  });

  test('isolates writeIds per workspace', () async {
    var calls = 0;
    Future<TicketWriteResult> run() async {
      calls++;
      return const TicketWriteResult.ok({});
    }

    await ledger.runOnce(
      workspaceId: 'ws-a',
      writeId: 'shared',
      operation: 'x',
      run: run,
    );
    await ledger.runOnce(
      workspaceId: 'ws-b',
      writeId: 'shared',
      operation: 'x',
      run: run,
    );
    expect(
      calls,
      2,
      reason: 'same writeId in different workspaces is distinct',
    );
  });
}
