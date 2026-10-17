import 'dart:async';
import 'dart:io';

import 'package:cc_host/cc_host.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/src/catalog/pending_question_watch.dart';
import 'package:drift/native.dart';
import 'package:test/test.dart';

void main() {
  test(
    'only live authorized waiters appear, including after a storage snapshot',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'question_watch_',
      );
      final global = GlobalDatabase.forTesting(NativeDatabase.memory());
      final databases = WorkspaceDatabaseManager(
        dataDir: directory.path,
        global: global,
        executorFactory: (_) => NativeDatabase.memory(),
      );
      final changes = StreamController<void>();
      final pending = <String>{};
      StreamIterator<Map<String, dynamic>>? snapshots;
      try {
        for (final workspace in ['ws-a', 'ws-b']) {
          await global.workspaceRegistryDao.upsertWorkspace(
            WorkspacesTableCompanion(
              id: Value(workspace),
              name: Value(workspace),
            ),
          );
          await databases.create(workspace);
        }
        final messaging = DaoMessagingRepository(databases);
        Future<String> question(String workspace, String name) async {
          final space = await messaging.createSpace(workspace, name, const []);
          final conversation = await databases
              .of(workspace)
              .conversationDao
              .ensureStandingConversation(
                workspaceId: workspace,
                spaceId: space.id,
              );
          return messaging.sendMessage(
            workspaceId: workspace,
            spaceId: space.id,
            conversationId: conversation,
            senderId: 'agent',
            senderType: 'agent',
            messageType: 'user_question',
            content: name,
            metadata: {'question': name, 'answered': false},
          );
        }

        final active = await question('ws-a', 'Actionable question');
        final restricted = await question('ws-a', 'Restricted question');
        final foreign = await question('ws-b', 'Foreign question');
        final deniedMessage = await messaging.getMessageById(
          'ws-a',
          restricted,
        );
        final query = pendingQuestionWatchQuery(
          workspaceDbs: databases,
          isPending: pending.contains,
          pendingChanges: changes.stream,
          viewerTraceRestricted: (_, spaceId, _) async =>
              spaceId == deniedMessage!.spaceId,
        );
        final stream = StreamIterator(
          query.handler(
            const WatchQueryContext(
              workspaceId: 'ws-a',
              deviceId: 'phone',
              userId: 'operator',
              args: {},
            ),
          ),
        );
        snapshots = stream;
        Future<List<String>> nextIds() async {
          expect(
            await stream.moveNext().timeout(const Duration(seconds: 3)),
            isTrue,
          );
          return (stream.current['questions'] as List)
              .map((row) => (row as Map)['id'] as String)
              .toList();
        }

        // Persisted unanswered rows from a previous process have no live asker.
        expect(await nextIds(), isEmpty);

        // Registration happens after persisting the question. It must refresh
        // this same subscription even if no further database write occurs.
        pending.addAll([active, restricted, foreign]);
        changes.add(null);
        expect(await nextIds(), [active]);

        // An asker can close before its asynchronous metadata update arrives.
        pending.remove(active);
        changes.add(null);
        expect(await nextIds(), isEmpty);
      } finally {
        await snapshots?.cancel();
        await changes.close();
        await databases.closeAll();
        await global.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
