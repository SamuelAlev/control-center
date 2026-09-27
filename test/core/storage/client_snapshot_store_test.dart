import 'dart:io';

import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/storage/app_support_path_provider.dart';
import 'package:control_center/core/storage/client_snapshot_store.dart';
import 'package:control_center/core/storage/legacy_snapshot_cleanup.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('cc-client-snapshot-');
    AppSupportPathProvider.setRealAppSupportDirForTesting(root);
  });

  tearDown(() async {
    AppSupportPathProvider.resetForTesting();
    await root.delete(recursive: true);
  });

  Future<RpcSnapshotCache> scope(
    String server,
    String fingerprint,
    String user,
  ) async {
    final cache = RpcSnapshotCache(
      store: await snapshotStoreFor(
        serverId: server,
        fingerprint: fingerprint,
        userId: user,
      ),
    );
    await cache.hydrate();
    return cache;
  }

  test('restart hydrates the verified server/user render scope', () async {
    final original = await scope('server-1', 'pin-1', 'user-1');
    original.write('pr.list', {
      'items': [1, 2],
    });
    await original.flush();

    final restarted = await scope('server-1', 'pin-1', 'user-1');
    expect(restarted.read('pr.list'), {
      'items': [1, 2],
    });
  });

  test(
    'different server, fingerprint and user cannot read another scope',
    () async {
      final original = await scope('server-1', 'pin-1', 'user-1');
      original.write('meeting.list', {
        'items': ['private'],
      });
      await original.flush();

      expect(
        (await scope('server-1', 'pin-1', 'user-2')).read('meeting.list'),
        isNull,
      );
      expect(
        (await scope('server-1', 'pin-2', 'user-1')).read('meeting.list'),
        isNull,
      );
      expect(
        (await scope('server-2', 'pin-1', 'user-1')).read('meeting.list'),
        isNull,
      );
    },
  );

  test('desktop snapshots remain owner-private on disk', () async {
    if (Platform.isWindows) {
      return;
    }
    final store =
        await snapshotStoreFor(
              serverId: 'server-1',
              fingerprint: 'pin-1',
              userId: 'user-1',
            )
            as FileRpcSnapshotStore;
    await store.save('{"version":1,"entries":[]}');
    expect(store.file.statSync().mode & 0x1ff, 0x180);
    expect(store.file.parent.statSync().mode & 0x1ff, 0x1c0);
  });

  test(
    'clear and forget remove persisted snapshots without touching peers',
    () async {
      final first = await scope('server-1', 'pin-1', 'user-1');
      final second = await scope('server-1', 'pin-1', 'user-2');
      final otherServer = await scope('server-2', 'pin-1', 'user-1');
      first.write('pr.list', {
        'items': [1],
      });
      second.write('pr.list', {
        'items': [2],
      });
      otherServer.write('pr.list', {
        'items': [3],
      });
      await Future.wait([first.flush(), second.flush(), otherServer.flush()]);

      first.clear();
      await first.flush();
      expect(
        (await scope('server-1', 'pin-1', 'user-1')).read('pr.list'),
        isNull,
      );
      expect((await scope('server-1', 'pin-1', 'user-2')).read('pr.list'), {
        'items': [2],
      });

      await forgetSnapshotServer('server-1');
      expect(
        (await scope('server-1', 'pin-1', 'user-2')).read('pr.list'),
        isNull,
      );
      expect((await scope('server-2', 'pin-1', 'user-1')).read('pr.list'), {
        'items': [3],
      });
    },
  );
  test('obsolete workspace-only calendar keys are removed exactly', () async {
    final preferences = AppPreferences.inMemory({
      'calendar_events_snapshot__ws-1': '{"private":true}',
      'calendar_events_snapshot__ws-2': '{"private":true}',
      'calendar_events_snapshot_other': 'keep',
      'theme_mode': 'dark',
    });
    await removeLegacyCalendarSnapshots(preferences);
    expect(preferences.getString('calendar_events_snapshot__ws-1'), isNull);
    expect(preferences.getString('calendar_events_snapshot__ws-2'), isNull);
    expect(preferences.getString('calendar_events_snapshot_other'), 'keep');
    expect(preferences.getString('theme_mode'), 'dark');
  });
}
