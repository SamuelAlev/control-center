import 'dart:io';

import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_server_core/cc_server_core.dart';
import 'package:test/test.dart';

import 'helpers/best_effort_delete.dart';
import 'helpers/native_staging.dart';
import 'helpers/test_database.dart';

/// End-to-end RPC smoke for the Spaces · Conversations · Threads surface:
/// a real server boots on a temp data dir, a paired client creates a
/// space, ensures its standing conversation, posts into it, opens a thread
/// anchored to that message and replies inside the thread — asserting the
/// thread carries the anchor, both streams stay independent, and the anchor
/// validation rejects nested and cross-space threads.
void main() {
  if (!hostHasServerNatives) {
    test(
      'native libraries are staged for server boot',
      () {
        fail(
          'Native libraries not found — run scripts/natives/build_natives.sh. '
          'They are REQUIRED; cc_server refuses to boot without them.',
        );
      },
      skip: skipServerBootWithoutNatives(
        reason: 'Native libraries are not built on CI runners',
      ),
    );
    return;
  }

  test('spaces, conversations and threads round-trip over RPC', () async {
    final tmp = Directory.systemTemp.createTempSync('cc_server_threads_e2e');
    // The boot preflight refuses to start without the native libraries;
    // stage whatever this machine has into the data dir (see the helper).
    await stageServerNatives(tmp.path);
    addTearDown(() => deleteDirBestEffort(tmp));

    const deviceId = 'threads-test-device';
    const psk = 'test-psk-threads-please-and-thank-you-0123456789';
    const workspaceId = 'ws-threads';

    final seed = openSeedDatabases(tmp.path);
    await seed.global.workspaceRegistryDao.upsertWorkspace(
      const WorkspacesTableCompanion(
        id: Value(workspaceId),
        name: Value('Threads'),
      ),
    );
    await seed.global.pairedDeviceDao.upsert(
      const PairedDevicesTableCompanion(
        id: Value(deviceId),
        workspaceId: Value(workspaceId),
        label: Value('threads e2e'),
        pskRef: Value('file'),
        status: Value(PairedDeviceStatus.active),
      ),
    );
    await seed.close();
    await FileSecretsStore(dataDir: tmp.path).writePsk(deviceId, psk);

    final server = await runCcServer(
      args: ['--data-dir', tmp.path, '--port', '0'],
    );
    addTearDown(server.shutdown);

    final client = await connectRemoteRpc(
      uri: Uri.parse('ws://127.0.0.1:${server.rpc.boundPort}/rpc'),
      deviceId: deviceId,
      psk: psk,
    );
    addTearDown(client.close);
    await client.initialize();
    client.activeWorkspaceId = workspaceId;

    // 1. Create the space, then ensure its standing conversation — no
    // main-id aliasing: the returned id is a fresh uuid.
    final spaceData = await client.call('messaging.createSpace', {
      'name': 'Build',
      'agent_ids': const <String>[],
    });
    final spaceId =
        (spaceData['space'] as Map<String, dynamic>)['id'] as String;
    final ensured = await client.call('conversation.ensure', {
      'space_id': spaceId,
    });
    final standing =
        (ensured['conversation'] as Map<String, dynamic>)['id'] as String;
    expect(standing, isNot(spaceId));

    // 2. Post a message into the standing conversation (stream A).
    final first = await client.call('messaging.sendMessage', {
      'space_id': spaceId,
      'conversation_id': standing,
      'content': 'anchor me',
    });
    final anchorMessageId = first['message_id'] as String;

    // 3. Open a thread anchored to that message (stream B).
    final threadData = await client.call('conversation.create', {
      'space_id': spaceId,
      'title': 'Thread it',
      'anchor_message_id': anchorMessageId,
    });
    final thread = threadData['conversation'] as Map<String, dynamic>;
    final threadId = thread['id'] as String;
    expect(thread['anchor_message_id'], anchorMessageId);

    // 4. Reply inside the thread; it must not leak into the parent stream.
    final reply = await client.call('messaging.sendMessage', {
      'space_id': spaceId,
      'conversation_id': threadId,
      'content': 'inside the thread',
    });
    final replyId = reply['message_id'] as String;

    final list = await client.call('conversation.list', {'space_id': spaceId});
    final conversations = (list['conversations'] as List)
        .cast<Map<String, dynamic>>();
    expect(conversations.length, 2);
    expect(
      conversations.firstWhere((c) => c['id'] == threadId)['anchor_message_id'],
      anchorMessageId,
    );

    final parentStream = await client.call('messaging.getMessages', {
      'space_id': spaceId,
      'conversation_id': standing,
    });
    final parentIds = (parentStream['messages'] as List)
        .cast<Map<String, dynamic>>()
        .map((m) => m['id'])
        .toList();
    expect(parentIds, contains(anchorMessageId));
    expect(parentIds, isNot(contains(replyId)));

    final threadStream = await client.call('messaging.getMessages', {
      'space_id': spaceId,
      'conversation_id': threadId,
    });
    final threadIds = (threadStream['messages'] as List)
        .cast<Map<String, dynamic>>()
        .map((m) => m['id'])
        .toList();
    expect(threadIds, [replyId]);

    // 5. Threads never nest: anchoring to the thread's own message fails.
    expect(
      () => client.call('conversation.create', {
        'space_id': spaceId,
        'title': 'Nested',
        'anchor_message_id': replyId,
      }),
      throwsA(
        isA<RemoteRpcException>().having(
          (e) => e.message,
          'message',
          contains('Threads cannot nest.'),
        ),
      ),
    );

    // 6. Cross-space anchors are refused: a message from ANOTHER space of the
    // same workspace must not anchor a thread here.
    final otherData = await client.call('messaging.createSpace', {
      'name': 'Other',
      'agent_ids': const <String>[],
    });
    final otherSpaceId =
        (otherData['space'] as Map<String, dynamic>)['id'] as String;
    final foreign = await client.call('messaging.sendMessage', {
      'space_id': otherSpaceId,
      'content': 'foreign message',
    });
    expect(
      () => client.call('conversation.create', {
        'space_id': spaceId,
        'title': 'Cross-space',
        'anchor_message_id': foreign['message_id'] as String,
      }),
      throwsA(
        isA<RemoteRpcException>().having(
          (e) => e.message,
          'message',
          contains('Anchor message not found in this space.'),
        ),
      ),
    );
  });
}
