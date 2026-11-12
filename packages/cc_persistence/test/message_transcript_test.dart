import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/ports/embedding_port.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// An embedder that records each batch it was asked for.
class _Embedder extends EmbeddingPort {
  @override
  bool isReady = true;

  /// The texts of each [embedAll] call.
  final batches = <List<String>>[];

  /// Runs while the first batch is being embedded.
  Future<void> Function()? duringBatch;

  @override
  int get dimension => 4;

  @override
  Future<Float32List> embed(String text) async =>
      Float32List.fromList([text.length.toDouble(), 0, 0, 0]);

  @override
  Future<List<Float32List>> embedAll(List<String> texts) async {
    batches.add(texts);
    final during = duringBatch;
    duringBatch = null;
    await during?.call();
    return super.embedAll(texts);
  }
}

/// A space turn's transcript as rows: one per segment, written once, read
/// back into the `metadata['segments']` wire shape only by the reads that
/// render a turn. And a message's embedding as a side row.
void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late WorkspaceDatabase db;
  late DaoMessagingRepository repo;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, 'ws-1');
    repo = DaoMessagingRepository(dbs);
    db = dbs.of('ws-1');
    await db.messagingDao.insertSpace(
      SpacesTableCompanion.insert(id: 's', name: 'S', workspaceId: 'ws-1'),
    );
    await db.conversationDao.insertConversation(
      ConversationsTableCompanion.insert(
        id: 'c',
        spaceId: 's',
        workspaceId: 'ws-1',
      ),
    );
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  Map<String, dynamic> tool(int i, {required bool done}) => {
    'type': 'tool',
    'toolName': 'Read',
    'toolCallId': 'call-$i',
    'status': done ? 'ok' : 'running',
    if (done) 'outputs': 'body $i',
  };

  Future<int> count(String sql) async =>
      (await db.customSelect(sql).getSingle()).data.values.single as int;

  /// Logs every row written to `transcript_segments` from here on.
  Future<void> logSegmentWrites() async {
    await db.customStatement(
      'CREATE TEMP TABLE segment_writes (op TEXT NOT NULL, seq INTEGER)',
    );
    await db.customStatement(
      'CREATE TEMP TRIGGER segment_insert_log AFTER INSERT ON '
      'transcript_segments BEGIN '
      "INSERT INTO segment_writes VALUES ('insert', NEW.seq); END",
    );
    await db.customStatement(
      'CREATE TEMP TRIGGER segment_update_log AFTER UPDATE ON '
      'transcript_segments BEGIN '
      "INSERT INTO segment_writes VALUES ('update', NEW.seq); END",
    );
  }

  Future<List<(String, int)>> segmentWrites() async {
    final rows = await db
        .customSelect('SELECT op, seq FROM segment_writes ORDER BY rowid')
        .get();
    await db.customStatement('DELETE FROM segment_writes');
    return [for (final r in rows) (r.read<String>('op'), r.read<int>('seq'))];
  }

  Future<void> streamingTurn(String id) => repo.sendMessage(
    workspaceId: 'ws-1',
    spaceId: 's',
    conversationId: 'c',
    content: '',
    senderId: 'agent-1',
    senderType: 'agent',
    messageType: 'agent_turn',
    metadata: const {'agentName': 'Scout', 'streamComplete': false},
    id: id,
  );

  group('streaming writes', () {
    test('each flush writes only the segments it changed', () async {
      await streamingTurn('turn');
      await logSegmentWrites();

      const turnLength = 120;
      for (var i = 0; i < turnLength; i++) {
        await repo.flushStreamingMessage(
          'ws-1',
          'turn',
          metadata: {'transcriptChars': i},
          changedSegments: {i: tool(i, done: false)},
          segmentCount: i + 1,
          writeMetadata: false,
        );
        expect(await segmentWrites(), [('insert', i)]);
        await repo.flushStreamingMessage(
          'ws-1',
          'turn',
          metadata: {'transcriptChars': i},
          changedSegments: {i: tool(i, done: true)},
          segmentCount: i + 1,
          writeMetadata: false,
        );
        expect(await segmentWrites(), [('update', i)]);
      }

      expect(
        await count('SELECT COUNT(*) FROM transcript_segments'),
        turnLength,
      );
    });

    test('a segment whose body is unchanged is never rewritten', () async {
      await streamingTurn('turn');
      final all = [for (var i = 0; i < 30; i++) tool(i, done: true)];
      await repo.flushStreamingMessage(
        'ws-1',
        'turn',
        metadata: const {},
        changedSegments: all.asMap(),
        segmentCount: all.length,
        writeMetadata: false,
      );
      await logSegmentWrites();

      // A flush that names a segment it did not change.
      await repo.flushStreamingMessage(
        'ws-1',
        'turn',
        metadata: const {},
        changedSegments: {3: tool(3, done: true)},
        segmentCount: all.length,
        writeMetadata: false,
      );
      // A whole-transcript write, the shape every non-streaming writer uses.
      await repo.updateMessage(
        'ws-1',
        'turn',
        content: 'done',
        metadata: {
          'agentName': 'Scout',
          'streamComplete': true,
          'segments': [...all, tool(30, done: true)],
        },
      );

      expect(await segmentWrites(), [('insert', 30)]);
    });

    test('a shorter whole transcript drops the rows past its end', () async {
      await streamingTurn('turn');
      await repo.updateMessage(
        'ws-1',
        'turn',
        metadata: {
          'segments': [tool(0, done: true), tool(1, done: true)],
        },
      );
      await repo.updateMessage(
        'ws-1',
        'turn',
        metadata: {
          'segments': [tool(0, done: true)],
        },
      );

      final read = await repo.getMessageById('ws-1', 'turn');
      expect(read!.metadata?['segments'], [tool(0, done: true)]);
    });
  });

  group('wire shape', () {
    Future<List<Map<String, dynamic>>> finishedTurn(String id) async {
      final segments = [
        {'type': 'text', 'text': 'looking'},
        tool(0, done: true),
      ];
      await repo.sendMessage(
        workspaceId: 'ws-1',
        spaceId: 's',
        conversationId: 'c',
        content: 'answer',
        senderId: 'agent-1',
        senderType: 'agent',
        messageType: 'agent_turn',
        metadata: {
          'agentName': 'Scout',
          'streamComplete': true,
          'outcome': 'completed',
          'segments': segments,
        },
        id: id,
      );
      return segments;
    }

    test('a turn read on its own carries its segments', () async {
      final segments = await finishedTurn('turn');

      final read = await repo.getMessageById('ws-1', 'turn');
      expect(read!.metadata?['segments'], segments);
      expect(read.metadata?['agentName'], 'Scout');
      expect(read.metadata?.containsKey('segments_elided'), isFalse);

      final all = await repo.getMessages('ws-1', 's', conversationId: 'c');
      expect(all.single.metadata?['segments'], segments);
    });

    test('a list row says the turn has segments and how many', () async {
      await finishedTurn('turn');
      await repo.sendMessage(
        workspaceId: 'ws-1',
        spaceId: 's',
        conversationId: 'c',
        content: 'thanks',
        senderId: 'user',
        senderType: 'user',
        id: 'plain',
      );

      final listed = await repo.watchMessages('ws-1', 's', 'c').first;
      final turn = listed.firstWhere((m) => m.id == 'turn');
      expect(turn.metadata?.containsKey('segments'), isFalse);
      expect(turn.metadata?['segments_elided'], isTrue);
      expect(turn.metadata?['segment_count'], 2);
      expect(turn.metadata?['agentName'], 'Scout');
      final plain = listed.firstWhere((m) => m.id == 'plain');
      expect(plain.metadata?.containsKey('segments_elided') ?? false, isFalse);
    });

    test('the stored message JSON never holds the transcript', () async {
      await finishedTurn('turn');

      final stored = await db
          .customSelect(
            "SELECT list_metadata FROM conversation_messages WHERE id = 'turn'",
          )
          .getSingle();
      final json =
          jsonDecode(stored.read<String>('list_metadata'))
              as Map<String, dynamic>;
      expect(json.keys, isNot(contains('segments')));
      expect(json.keys, isNot(contains('segment_count')));
    });

    test('a list read does not read the segment table', () async {
      await finishedTurn('turn');

      expect(
        MessagingDao.listedMessageColumns,
        isNot(contains('transcript_segments')),
      );
      expect(
        MessagingDao.listedMessagesFrom,
        isNot(contains('transcript_segments')),
      );
      final plan = await db
          .customSelect(
            'EXPLAIN QUERY PLAN ${MessagingDao.conversationListSql}',
            variables: [Variable.withString('c')],
          )
          .get();
      final text = plan.map((r) => r.data.values.join(' ')).join('\n');
      expect(text, contains('idx_transcripts_message_id'));
      expect(text, isNot(contains('transcript_segments')));
    });
  });

  group('lifecycle', () {
    Future<void> turnWithSegments(String id, {String conversation = 'c'}) =>
        repo.sendMessage(
          workspaceId: 'ws-1',
          spaceId: 's',
          conversationId: conversation,
          content: 'answer',
          senderId: 'agent-1',
          senderType: 'agent',
          messageType: 'agent_turn',
          metadata: {
            'segments': [tool(0, done: true), tool(1, done: true)],
          },
          id: id,
        );

    Future<int> segmentRows() =>
        count('SELECT COUNT(*) FROM transcript_segments');

    test('deleting the message deletes its transcript', () async {
      await turnWithSegments('turn');
      expect(await segmentRows(), 2);

      await db.customStatement(
        "DELETE FROM conversation_messages WHERE id = 'turn'",
      );

      expect(await segmentRows(), 0);
      expect(await count('SELECT COUNT(*) FROM transcripts'), 0);
    });

    test('deleting the conversation deletes its transcripts', () async {
      await turnWithSegments('turn');

      await db.customStatement("DELETE FROM conversations WHERE id = 'c'");

      expect(await segmentRows(), 0);
    });

    test('deleting the space deletes its transcripts', () async {
      await turnWithSegments('turn');

      await repo.deleteSpace('ws-1', 's');

      expect(await segmentRows(), 0);
    });

    test('the run sweep spares a space turn\'s transcript', () async {
      await turnWithSegments('turn');

      final pruned = await db.runTranscriptDao.pruneCompletedBefore(
        DateTime.now().add(const Duration(days: 1)),
      );

      expect(pruned, 0);
      expect(await segmentRows(), 2);
    });

    test('a fork copies a turn\'s transcript', () async {
      await turnWithSegments('turn');

      final forked = await repo.forkConversation(
        workspaceId: 'ws-1',
        spaceId: 's',
        conversationId: 'c',
      );
      final copied = await repo.getMessages(
        'ws-1',
        's',
        conversationId: forked,
      );

      expect(copied.single.id, isNot('turn'));
      expect(copied.single.metadata?['segments'], [
        tool(0, done: true),
        tool(1, done: true),
      ]);
      expect(await segmentRows(), 4);
    });
  });

  group('embeddings', () {
    Future<void> text(String id) => repo.sendMessage(
      workspaceId: 'ws-1',
      spaceId: 's',
      conversationId: 'c',
      content: 'remember $id',
      senderId: 'user',
      senderType: 'user',
      id: id,
    );

    test('a message without a side row is the backlog', () async {
      await text('a');
      await text('b');
      await repo.updateMessageEmbedding(
        'ws-1',
        'a',
        Uint8List.fromList(const [1, 2, 3, 4]),
      );

      final pending = await db.messagingDao.messagesToEmbed(after: 0);
      expect(pending.map((m) => m.id), ['b']);
      final embedded = await repo.getMessagesWithEmbedding('ws-1', 's');
      expect(embedded.single.message.id, 'a');
      expect(embedded.single.embedding, [1, 2, 3, 4]);
    });

    test('the backlog query probes the side table by its key', () async {
      final plan = await db
          .customSelect(
            'EXPLAIN QUERY PLAN ${MessagingDao.messagesToEmbedSql}',
            variables: [Variable.withInt(0), Variable.withInt(10)],
          )
          .get();
      final text = plan.map((r) => r.data.values.join(' ')).join('\n');

      expect(
        text,
        contains('sqlite_autoindex_conversation_message_embeddings_1'),
      );
      expect(text, isNot(contains('SCAN e')));
      // The walk continues from a rowid; it never restarts at the first row.
      expect(text, contains('SEARCH m USING INTEGER PRIMARY KEY (rowid>?)'));
      expect(text, isNot(contains('TEMP B-TREE')));
    });

    test('the backlog is what a writer would have embedded', () async {
      await text('typed');
      await repo.sendMessage(
        workspaceId: 'ws-1',
        spaceId: 's',
        conversationId: 'c',
        content: 'an answer',
        senderId: 'agent-1',
        senderType: 'agent',
        messageType: 'agent_turn',
        id: 'answer',
      );
      await repo.sendMessage(
        workspaceId: 'ws-1',
        spaceId: 's',
        conversationId: 'c',
        content: 'Ada joined',
        senderId: 'system',
        senderType: 'system',
        messageType: 'system',
        id: 'notice',
      );
      await repo.sendMessage(
        workspaceId: 'ws-1',
        spaceId: 's',
        conversationId: 'c',
        content: '',
        senderId: 'agent-1',
        senderType: 'agent',
        messageType: 'agent_turn',
        id: 'empty',
      );
      await text('old');
      await repo.markCompacted('ws-1', const ['old']);

      final pending = await db.messagingDao.messagesToEmbed(after: 0);

      expect(pending.map((m) => m.id), ['typed', 'answer']);
      expect(pending.map((m) => m.content), ['remember typed', 'an answer']);
    });

    test('the backfill embeds every message without a vector, in batches, '
        'once', () async {
      for (final id in ['a', 'b', 'c', 'd', 'e']) {
        await text(id);
      }
      await repo.updateMessageEmbedding(
        'ws-1',
        'c',
        Uint8List.fromList(const [9, 9, 9, 9]),
      );
      final embedder = _Embedder();

      expect(await repo.backfillEmbeddings('ws-1', embedder, batchSize: 2), 4);

      expect(embedder.batches, [
        ['remember a', 'remember b'],
        ['remember d', 'remember e'],
      ]);
      final embedded = await repo.getMessagesWithEmbedding('ws-1', 's');
      expect(embedded.map((m) => m.message.id), ['a', 'b', 'c', 'd', 'e']);
      // The vector its writer stored is not replaced.
      expect(embedded[2].embedding, [9, 9, 9, 9]);

      embedder.batches.clear();
      expect(await repo.backfillEmbeddings('ws-1', embedder), 0);
      expect(embedder.batches, isEmpty);
    });

    test('the backfill embeds nothing while the model is not ready', () async {
      await text('a');
      final embedder = _Embedder()..isReady = false;

      expect(await repo.backfillEmbeddings('ws-1', embedder), 0);

      expect(embedder.batches, isEmpty);
      expect(
        await count('SELECT COUNT(*) FROM conversation_message_embeddings'),
        0,
      );
    });

    test('the backfill skips a message that changed, was embedded or went '
        'away while its batch was being embedded', () async {
      for (final id in ['edited', 'embedded', 'deleted', 'kept']) {
        await text(id);
      }
      final embedder = _Embedder()
        ..duringBatch = () async {
          await repo.updateMessage('ws-1', 'edited', content: 'new text');
          await repo.updateMessageEmbedding(
            'ws-1',
            'embedded',
            Uint8List.fromList(const [7, 7, 7, 7]),
          );
          await db.customStatement(
            "DELETE FROM conversation_messages WHERE id = 'deleted'",
          );
        };

      expect(await repo.backfillEmbeddings('ws-1', embedder), 1);

      final embedded = await repo.getMessagesWithEmbedding('ws-1', 's');
      expect(embedded.map((m) => m.message.id), ['embedded', 'kept']);
      expect(embedded.first.embedding, [7, 7, 7, 7]);
      // The edited message is still the backlog: the next run embeds its
      // new text.
      expect(
        (await db.messagingDao.messagesToEmbed(after: 0)).map((m) => m.content),
        ['new text'],
      );
    });

    test('embedding a message leaves its row and the search index', () async {
      await text('a');
      await db.customStatement(
        'CREATE TEMP TABLE message_updates (id TEXT NOT NULL)',
      );
      await db.customStatement(
        'CREATE TEMP TRIGGER message_update_log AFTER UPDATE ON '
        'conversation_messages BEGIN '
        'INSERT INTO message_updates VALUES (NEW.id); END',
      );
      final ftsBefore = await count(
        'SELECT COUNT(*) FROM conversation_messages_fts',
      );

      await repo.updateMessageEmbedding(
        'ws-1',
        'a',
        Uint8List.fromList(const [1, 2, 3, 4]),
      );
      await repo.updateMessageEmbedding(
        'ws-1',
        'a',
        Uint8List.fromList(const [5, 6, 7, 8]),
      );

      expect(await count('SELECT COUNT(*) FROM message_updates'), 0);
      expect(
        await count('SELECT COUNT(*) FROM conversation_messages_fts'),
        ftsBefore,
      );
      final embedded = await repo.getMessagesWithEmbedding('ws-1', 's');
      expect(embedded.single.embedding, [5, 6, 7, 8]);
    });

    test('deleting the message deletes its embedding', () async {
      await text('a');
      await repo.updateMessageEmbedding(
        'ws-1',
        'a',
        Uint8List.fromList(const [1, 2, 3, 4]),
      );

      await db.customStatement(
        "DELETE FROM conversation_messages WHERE id = 'a'",
      );

      expect(
        await count('SELECT COUNT(*) FROM conversation_message_embeddings'),
        0,
      );
    });
  });
}
