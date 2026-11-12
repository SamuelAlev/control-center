import 'package:cc_host/cc_host.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/src/write_ledger_adapter.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, 'ws-a');
    await seedTestWorkspace(global, dbs, 'ws-b');
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  Future<WriteLedgerClaim> claim(DaoWriteLedger ledger, String key) =>
      ledger.claim(workspaceId: 'ws-a', key: key, opName: 'thing.mutate');

  test('claim, in progress, complete, replay', () async {
    final ledger = DaoWriteLedger(dbs);
    expect(await claim(ledger, 'k'), isA<LedgerClaimed>());
    expect(await claim(ledger, 'k'), isA<LedgerInProgress>());
    expect(
      await ledger.complete(workspaceId: 'ws-a', key: 'k', data: {'n': 1}),
      isTrue,
    );
    final replay = await claim(ledger, 'k');
    expect(replay, isA<LedgerReplay>());
    expect((replay as LedgerReplay).data, {'n': 1});
    // Keys are per workspace.
    expect(
      await ledger.claim(workspaceId: 'ws-b', key: 'k', opName: 'x'),
      isA<LedgerClaimed>(),
    );
  });

  test('a released claim can be taken again', () async {
    final ledger = DaoWriteLedger(dbs);
    expect(await claim(ledger, 'k'), isA<LedgerClaimed>());
    await ledger.release(workspaceId: 'ws-a', key: 'k');
    expect(await claim(ledger, 'k'), isA<LedgerClaimed>());
  });

  test('a claim left by a previous process is dropped, not refused', () async {
    // The previous server process claimed `k` and died before completing it.
    expect(await claim(DaoWriteLedger(dbs), 'k'), isA<LedgerClaimed>());
    final earlier = DaoWriteLedger(dbs);
    expect(
      await earlier.claim(workspaceId: 'ws-a', key: 'done', opName: 'x'),
      isA<LedgerClaimed>(),
    );
    await earlier.complete(workspaceId: 'ws-a', key: 'done', data: {'ok': 1});

    final restarted = DaoWriteLedger(dbs);
    expect(await claim(restarted, 'k'), isA<LedgerClaimed>());
    // Completed results survive the sweep.
    expect(await claim(restarted, 'done'), isA<LedgerReplay>());
    // Its own claims are never swept again in this process.
    expect(await claim(restarted, 'k'), isA<LedgerInProgress>());
  });
}
