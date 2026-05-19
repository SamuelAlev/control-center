import 'dart:io';

import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/cc_server_core.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:test/test.dart';

import 'helpers/best_effort_delete.dart';

/// Polls until [done], or gives up after [timeout].
///
/// Drift answers `.watch()` from a background isolate, so an emission lands a
/// few event-loop turns after the write that caused it — pumping the queue is
/// not enough to observe one.
Future<void> waitFor(
  bool Function() done, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!done() && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

/// Long enough for an emission to arrive if one were coming — the window a
/// "nothing was emitted" assertion is worth.
Future<void> settle() =>
    Future<void>.delayed(const Duration(milliseconds: 250));

void main() {
  group('PairedDeviceRegistryWatch', () {
    late Directory tmp;
    late GlobalDatabase db;

    setUp(() {
      // These tests deliberately open the same file twice — that IS the
      // scenario (a `cc_server pair` process beside a running server).
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      tmp = Directory.systemTemp.createTempSync('paired_device_watch_test');
      db = GlobalDatabase(openGlobalDatabase(dataDir: tmp.path));
    });

    tearDown(() async {
      await db.close();
      await deleteDirBestEffort(tmp);
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = false;
    });

    /// A SECOND connection to the same file — what `cc_server pair` is from a
    /// running server's point of view. Drift notifies table updates in-process
    /// only, so writes through this one are invisible to streams opened on
    /// [db].
    Future<void> fromAnotherProcess(
      Future<void> Function(GlobalDatabase db) write,
    ) async {
      final other = GlobalDatabase(openGlobalDatabase(dataDir: tmp.path));
      try {
        await write(other);
      } finally {
        await other.close();
      }
    }

    Future<void> pairFromAnotherProcess(String deviceId) =>
        fromAnotherProcess(
          (other) => other.pairedDeviceDao.upsert(
            PairedDevicesTableCompanion(
              id: Value(deviceId),
              userId: const Value('owner'),
              label: Value('Paired $deviceId'),
              platform: const Value('web'),
              pskRef: const Value('file'),
              status: const Value(PairedDeviceStatus.active),
            ),
          ),
        );

    test('an out-of-process pairing reaches an open watch stream', () async {
      final emissions = <List<PairedDevicesTableData>>[];
      final sub = db.pairedDeviceDao.watchAll().listen(emissions.add);
      addTearDown(sub.cancel);
      await waitFor(() => emissions.isNotEmpty);
      expect(emissions.last, isEmpty);

      final watch = PairedDeviceRegistryWatch(global: db);
      addTearDown(watch.dispose);
      await watch.start();

      await pairFromAnotherProcess('phone');
      await settle();
      // The baseline this class exists for: drift never heard about the other
      // connection's write, so the relay and every device list stayed stale.
      expect(emissions.last, isEmpty);

      await watch.refresh();
      await waitFor(() => emissions.last.isNotEmpty);

      expect(emissions.last.map((d) => d.id), ['phone']);
    });

    test('an unchanged registry does not re-emit', () async {
      await pairFromAnotherProcess('phone');

      final watch = PairedDeviceRegistryWatch(global: db);
      addTearDown(watch.dispose);
      await watch.start();

      final emissions = <List<PairedDevicesTableData>>[];
      final sub = db.pairedDeviceDao.watchAll().listen(emissions.add);
      addTearDown(sub.cancel);
      await waitFor(() => emissions.isNotEmpty);
      final initial = emissions.length;

      await watch.refresh();
      await watch.refresh();
      await settle();

      expect(emissions, hasLength(initial));
    });

    test('a connect timestamp alone is not a registry change', () async {
      // `markSeen` runs in-process on every authentication and drift already
      // notifies for it. Digesting it here would re-send the whole device list
      // to every client after each connect.
      await pairFromAnotherProcess('phone');

      final watch = PairedDeviceRegistryWatch(global: db);
      addTearDown(watch.dispose);
      await watch.start();

      final emissions = <List<PairedDevicesTableData>>[];
      final sub = db.pairedDeviceDao.watchAll().listen(emissions.add);
      addTearDown(sub.cancel);
      await waitFor(() => emissions.isNotEmpty);

      await db.pairedDeviceDao.markSeen('phone', DateTime.utc(2026, 8, 28));
      await waitFor(() => emissions.last.single.lastSeenAt != null);
      final afterMarkSeen = emissions.length;

      await watch.refresh();
      await settle();

      expect(emissions, hasLength(afterMarkSeen));
    });

    test('a revocation from another process propagates too', () async {
      await pairFromAnotherProcess('phone');

      final watch = PairedDeviceRegistryWatch(global: db);
      addTearDown(watch.dispose);
      await watch.start();

      final emissions = <List<PairedDevicesTableData>>[];
      final sub = db.pairedDeviceDao.watchAll().listen(emissions.add);
      addTearDown(sub.cancel);
      await waitFor(() => emissions.isNotEmpty);
      expect(emissions.last, hasLength(1));

      await fromAnotherProcess((other) async {
        await other.pairedDeviceDao.remove('phone');
      });
      await watch.refresh();
      await waitFor(() => emissions.last.isEmpty);

      expect(emissions.last, isEmpty);
    });

    test('the poll picks a change up without an explicit refresh', () async {
      final emissions = <List<PairedDevicesTableData>>[];
      final sub = db.pairedDeviceDao.watchAll().listen(emissions.add);
      addTearDown(sub.cancel);
      await waitFor(() => emissions.isNotEmpty);

      final watch = PairedDeviceRegistryWatch(
        global: db,
        interval: const Duration(milliseconds: 50),
      );
      addTearDown(watch.dispose);
      await watch.start();

      await pairFromAnotherProcess('phone');
      await waitFor(() => emissions.last.isNotEmpty);

      expect(emissions.last.map((d) => d.id), ['phone']);
    });
  });
}
