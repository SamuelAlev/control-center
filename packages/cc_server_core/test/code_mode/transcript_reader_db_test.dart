import 'dart:convert';

import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_domain/features/messaging/domain/ports/conversation_transcript_port.dart';
import 'package:cc_domain/features/messaging/domain/ports/transcript_store.dart';
import 'package:cc_infra/src/messaging/conversation_transcript_reader.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:test/test.dart';

import '../helpers/seed_spaces.dart';
import '../helpers/test_database.dart';

/// The transcript reader `history()` pages, over the real per-workspace
/// databases: what it returns, and what one read takes from the database
/// in a conversation of thousands of turns.
void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late DaoMessagingRepository messages;
  late _Counting store;
  late ConversationTranscriptReader reader;
  final t0 = DateTime.utc(2026, 11, 19, 14);

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, 'ws-1');
    await seedTestWorkspace(global, dbs, 'ws-2');
    await seedConversation(dbs.of('ws-1'), 'conv-1', spaceId: 'space-1');
    messages = DaoMessagingRepository(dbs);
    store = _Counting(DaoTranscriptStore(dbs));
    reader = ConversationTranscriptReader(store);
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  Future<void> person(
    String id,
    String text, {
    String conversationId = 'conv-1',
  }) => messages.sendMessage(
    workspaceId: 'ws-1',
    spaceId: 'space-1',
    conversationId: conversationId,
    id: id,
    content: text,
    senderId: 'user-1',
    senderType: SenderType.user.wireName,
  );

  Future<void> turn(String id, List<TranscriptSegment> segments) async {
    final metadata = {'runId': 'run-$id'};
    await messages.sendMessage(
      workspaceId: 'ws-1',
      spaceId: 'space-1',
      conversationId: 'conv-1',
      id: id,
      content: '',
      senderId: 'agent-1',
      senderType: SenderType.agent.wireName,
      messageType: MessageType.agentTurn.wire,
      metadata: metadata,
    );
    await messages.flushStreamingMessage(
      'ws-1',
      id,
      metadata: metadata,
      changedSegments: {
        for (var i = 0; i < segments.length; i++) i: segments[i].toJson(),
      },
      segmentCount: segments.length,
      writeMetadata: true,
    );
  }

  /// The place where message [id] starts.
  Future<String> at(String id) async {
    final row = await dbs
        .of('ws-1')
        .customSelect(
          'SELECT rowid AS r, created_at AS c FROM conversation_messages '
          'WHERE id = ?',
          variables: [Variable.withString(id)],
        )
        .getSingle();
    return TranscriptCursor(
      orderAt: row.read<int>('c'),
      rowId: row.read<int>('r'),
      seq: 0,
      messageId: id,
    ).encode();
  }

  /// Message [id]'s row id.
  Future<int> rowIdOf(String id) async => (await dbs
          .of('ws-1')
          .customSelect(
            'SELECT rowid AS r FROM conversation_messages WHERE id = ?',
            variables: [Variable.withString(id)],
          )
          .getSingle())
      .read<int>('r');

  /// Hard-deletes message [id], as the steering queue's removal does.
  Future<void> delete(String id) =>
      dbs.of('ws-1').messagingDao.deleteMessageById(id);

  Future<void> revert(String id) => dbs.of('ws-1').customStatement(
    'UPDATE conversation_messages SET reverted = 1 WHERE id = ?',
    [id],
  );

  ToolSegment tool(String name, String outputs, {DateTime? prunedAt}) =>
      ToolSegment(
        toolName: name,
        toolCallId: 'call-$name',
        inputs: const {'command': 'make test'},
        outputs: outputs,
        startedAt: t0,
        prunedAt: prunedAt,
      );

  Future<TranscriptPage> page({
    String? start,
    int limit = ConversationTranscriptPort.maxPageRows,
    Set<TranscriptRole>? roles,
    Set<String>? tools,
    String workspaceId = 'ws-1',
    String conversationId = 'conv-1',
  }) => reader.page(
    workspaceId: workspaceId,
    conversationId: conversationId,
    start: start,
    limit: limit,
    roles: roles,
    tools: tools,
  );

  /// Every row from [start] on, a page at a time, with the store's take of
  /// each read.
  Future<({List<TranscriptRow> rows, List<_Take> takes})> all({
    Set<TranscriptRole>? roles,
    Set<String>? tools,
  }) async {
    final rows = <TranscriptRow>[];
    final takes = <_Take>[];
    String? start;
    do {
      store.reset();
      final p = await page(start: start, roles: roles, tools: tools);
      takes.add(store.take);
      rows.addAll(p.rows);
      start = p.nextStart;
    } while (start != null);
    return (rows: rows, takes: takes);
  }

  test('rows in order: person, agent text, tool, compaction in place, '
      'folded turns marked', () async {
    await person('m-1', 'please fix the build');
    await messages.markCompacted('ws-1', ['m-1']);
    await messages.sendMessage(
      workspaceId: 'ws-1',
      spaceId: 'space-1',
      conversationId: 'conv-1',
      id: 'm-2',
      content: 'Summary of the earlier turns',
      senderId: SenderType.systemSenderId,
      senderType: SenderType.system.wireName,
      messageType: MessageType.compaction.wire,
    );
    await turn('m-3', [
      ReasoningSegment(text: 'thinking', startedAt: t0),
      TextSegment(text: 'Running the tests.', startedAt: t0),
      TextSegment(text: '  ', startedAt: t0),
      tool('bash', 'ok'),
      ErrorSegment(message: 'tool crashed', startedAt: t0),
    ]);
    final p = await page();
    expect(p.messageCount, 3);
    expect(p.nextStart, isNull);
    expect(p.rows.map((r) => r.role), [
      TranscriptRole.person,
      TranscriptRole.compaction,
      TranscriptRole.agent,
      TranscriptRole.tool,
      TranscriptRole.system,
    ]);
    expect(p.rows.map((r) => r.id), ['m-1', 'm-2', 'm-3:1', 'm-3:3', 'm-3:4']);
    expect(p.rows.first.folded, isTrue);
    expect(p.rows.first.authorId, 'user-1');
    expect(p.rows[1].authorId, isNull);
    expect(p.rows[2].runId, 'run-m-3');
    expect(p.rows[2].at.isAtSameMomentAs(t0), isTrue);
    expect(p.rows[3].tool, 'bash');
    expect(p.rows[3].text, 'input: {"command":"make test"}\noutput: ok');
  });

  test('a cut output gives its handle, wherever its marker stands; a lost '
      'one says so', () async {
    await turn('m-1', [
      tool(
        'bash',
        'head\n\n[output omitted: 9000 chars; resume with '
            'read_output(handle: "h-42", offset: 4000)]\n\n${'tail\n' * 400}',
      ),
      tool('grep', 'x [output omitted: 10 chars (original not stored)]'),
      tool('read', 'gone', prunedAt: t0),
      tool('task', '${'y' * 50} … [123456 bytes, truncated]'),
      tool('ls', 'fine'),
    ]);
    final rows = (await page()).rows;
    expect(rows[0].outputHandle, 'h-42');
    expect(rows[0].outputLost, isFalse);
    expect(
      [for (final r in rows.skip(1)) r.outputLost],
      [true, true, true, false],
    );
    expect(rows.skip(1).every((r) => r.outputHandle == null), isTrue);
  });

  test('pages at 50 rows, or fewer when asked, from where the last page '
      'ended', () async {
    for (var i = 0; i < 120; i++) {
      await person('m-$i', 'line $i');
    }
    final first = await page();
    expect(first.rows, hasLength(ConversationTranscriptPort.maxPageRows));
    expect(first.messageCount, 120);
    final every = await all();
    expect(every.rows.map((r) => r.id), [for (var i = 0; i < 120; i++) 'm-$i']);
    expect(every.takes, hasLength(3));
    final few = await page(limit: 7, start: first.nextStart!);
    expect(few.rows.map((r) => r.id), [for (var i = 50; i < 57; i++) 'm-$i']);
  });

  test('a message reverted between two pages neither skips nor repeats a '
      'row: the next page starts where the last one ended', () async {
    for (var i = 0; i < 120; i++) {
      await person('m-$i', 'line $i');
    }
    await turn('t-0', [
      TextSegment(text: 'one', startedAt: t0),
      TextSegment(text: 'two', startedAt: t0),
      TextSegment(text: 'three', startedAt: t0),
    ]);
    final first = await page();
    expect(first.rows.last.id, 'm-49');
    // Before the boundary, and the boundary's own message.
    await revert('m-10');
    await revert('m-49');
    final second = await page(start: first.nextStart!);
    expect(second.rows.first.id, 'm-50');
    final third = await page(start: second.nextStart!);
    expect(third.rows.first.id, 'm-100');
    // A reverted message where the next page would start: the next one.
    await revert('m-100');
    expect((await page(start: second.nextStart!)).rows.first.id, 'm-101');
    // Inside a turn: the page resumes at its next segment.
    final one = await page(start: await at('t-0'), limit: 1);
    expect(one.rows.single.id, 't-0:0');
    await revert('m-119');
    final rest = await page(start: one.nextStart!);
    expect(rest.rows.map((r) => r.id), ['t-0:1', 't-0:2']);
    expect(rest.nextStart, isNull);
    // A place that names no message of the conversation reads as empty.
    final nowhere = await page(
      start: const TranscriptCursor(
        orderAt: 999999999999,
        rowId: 999999,
        seq: 0,
        messageId: 'nowhere',
      ).encode(),
    );
    expect(nowhere.rows, isEmpty);
    expect(nowhere.nextStart, isNull);
  });

  test('a message deleted where the next page starts moves the place '
      'nowhere: the next page starts at the first live message after it, '
      'and is not read as the end', () async {
    for (var i = 0; i < 6; i++) {
      await person('d-$i', 'line $i');
    }
    final first = await page(limit: 2);
    expect(first.rows.map((r) => r.id), ['d-0', 'd-1']);
    await delete('d-1');
    final second = await page(start: first.nextStart!, limit: 2);
    expect(second.rows.map((r) => r.id), ['d-2', 'd-3']);
    expect(second.nextStart, isNotNull);
  });

  test('a deleted newest message whose row id a new one takes: the next '
      'page starts the new message whole, never inside it', () async {
    await person('p-0', 'before');
    await turn('b-0', [
      for (var i = 0; i < 4; i++) TextSegment(text: 'old $i', startedAt: t0),
    ]);
    final first = await page(limit: 3);
    expect(first.rows.map((r) => r.id), ['p-0', 'b-0:0', 'b-0:1']);
    final reused = await rowIdOf('b-0');
    await delete('b-0');
    await turn('b-1', [
      for (var i = 0; i < 4; i++) TextSegment(text: 'new $i', startedAt: t0),
    ]);
    expect(await rowIdOf('b-1'), reused, reason: 'the row id is taken again');
    final second = await page(start: first.nextStart!);
    expect(second.rows.map((r) => r.id), [
      'b-1:0',
      'b-1:1',
      'b-1:2',
      'b-1:3',
    ]);
  });

  test('cuts a long row by character at 16,384, pages at 64 KiB, and reads '
      'on in a cut row', () async {
    await seedConversation(dbs.of('ws-1'), 'conv-2', spaceId: 'space-1');
    for (var i = 0; i < 10; i++) {
      await person(
        'b-$i',
        i == 9 ? '😀' * 20000 : 'x' * 20000,
        conversationId: 'conv-2',
      );
    }
    final big = await page(conversationId: 'conv-2');
    // Each row is cut to 16384 characters; four fit in 64 KiB.
    expect(big.rows, hasLength(4));
    expect(big.rows.first.cut, isTrue);
    expect(big.rows.first.fullLength, 20000);
    expect(
      big.rows.first.text,
      hasLength(ConversationTranscriptPort.maxRowChars),
    );
    expect(big.nextStart, await at('b-4'));
    final slice = await reader.slice(
      workspaceId: 'ws-1',
      conversationId: 'conv-2',
      rowId: 'b-0',
      offset: 16384,
    );
    expect(slice!.text, hasLength(20000 - 16384));
    expect(slice.nextOffset, isNull);

    // Characters, not UTF-16 units: an astral row is cut whole.
    final astral = (await page(
      conversationId: 'conv-2',
      start: await at('b-9'),
    )).rows.single;
    expect(
      astral.text.runes,
      hasLength(ConversationTranscriptPort.maxRowChars),
    );
    expect(astral.text.runes.every((r) => r == 0x1F600), isTrue);
    expect(astral.fullLength, 20000);
    final rest = await reader.slice(
      workspaceId: 'ws-1',
      conversationId: 'conv-2',
      rowId: 'b-9',
      offset: 20000 - 3,
    );
    expect(rest!.text, '😀😀😀');
    expect(rest.nextOffset, isNull);
    expect(
      await reader.slice(
        workspaceId: 'ws-1',
        conversationId: 'conv-2',
        rowId: 'b-9',
        offset: 20000,
      ),
      isNull,
    );
  });

  test('filters by role and by tool', () async {
    await person('m-1', 'hi');
    await turn('m-2', [tool('bash', 'a'), tool('grep', 'b')]);
    expect((await page(roles: {TranscriptRole.person})).rows.map((r) => r.id), [
      'm-1',
    ]);
    expect((await page(tools: {'grep'})).rows.map((r) => r.id), ['m-2:1']);
    expect(
      (await page(
        roles: {TranscriptRole.person, TranscriptRole.agent},
      )).rows.map((r) => r.id),
      ['m-1'],
    );
  });

  test('a conversation of another workspace reads as empty', () async {
    await person('m-1', 'secret');
    final p = await page(workspaceId: 'ws-2');
    expect(p.rows, isEmpty);
    expect(p.messageCount, 0);
    expect(p.nextStart, isNull);
    expect(
      await reader.slice(
        workspaceId: 'ws-2',
        conversationId: 'conv-1',
        rowId: 'm-1',
        offset: 0,
      ),
      isNull,
    );
    expect(
      await reader.slice(
        workspaceId: 'ws-1',
        conversationId: 'conv-2',
        rowId: 'm-1',
        offset: 0,
      ),
      isNull,
      reason: 'a row of another conversation',
    );
  });

  group('a run of its own (a subagent)', () {
    setUp(() async {
      final db = dbs.of('ws-1');
      await db
          .into(db.agentsTable)
          .insert(
            AgentsTableCompanion.insert(
              id: 'agent-1',
              name: 'ceo',
              title: 'CEO',
              agentMdPath: '/agents/ceo.md',
              workspaceId: 'ws-1',
              skills: 'dart',
            ),
          );
      await db
          .into(db.agentRunLogsTable)
          .insert(
            AgentRunLogsTableCompanion.insert(
              id: 'child-1',
              agentId: 'agent-1',
              workspaceId: 'ws-1',
              startedAt: Value(t0),
              status: const Value('running'),
              agentRole: const Value('sub'),
            ),
          );
      final segments = [
        TextSegment(text: 'looking', startedAt: t0),
        tool('bash', 'ok'),
        TextSegment(text: 'x' * 20000, startedAt: t0),
      ];
      await DaoRunTranscriptRepository(dbs).write(
        runId: 'child-1',
        workspaceId: 'ws-1',
        changedSegments: {
          for (var i = 0; i < segments.length; i++) i: segments[i].toJson(),
        },
        segmentCount: segments.length,
        transcriptChars: 20000,
        startedAt: t0,
        updatedAt: t0,
      );
    });

    Future<TranscriptPage> pageRun(
      String ws,
      String run, {
      String? start,
      int limit = ConversationTranscriptPort.maxPageRows,
      Set<TranscriptRole>? roles,
      Set<String>? tools,
    }) => reader.pageRun(
      workspaceId: ws,
      runId: run,
      start: start,
      limit: limit,
      roles: roles,
      tools: tools,
    );

    test("pages its own segments, with the run as each row's run", () async {
      final p = await pageRun('ws-1', 'child-1');
      expect(
        [for (final r in p.rows) r.id],
        ['child-1:0', 'child-1:1', 'child-1:2'],
      );
      expect(p.messageCount, isNull);
      expect(p.nextStart, isNull);
      expect(p.rows.every((r) => r.runId == 'child-1'), isTrue);
      expect(p.rows[1].tool, 'bash');
      expect(p.rows[2].cut, isTrue);
      expect(p.rows[2].fullLength, 20000);
      final two = await pageRun('ws-1', 'child-1', limit: 2);
      expect(two.nextStart, '2');
      expect(
        (await pageRun('ws-1', 'child-1', start: '2')).rows.single.id,
        'child-1:2',
      );
      final tools = await pageRun(
        'ws-1',
        'child-1',
        roles: {TranscriptRole.tool},
        tools: {'bash'},
      );
      expect(tools.rows.single.id, 'child-1:1');
    });

    test('reads on in a cut row', () async {
      final slice = await reader.sliceRun(
        workspaceId: 'ws-1',
        runId: 'child-1',
        rowId: 'child-1:2',
        offset: ConversationTranscriptPort.maxRowChars,
      );
      expect(
        slice!.text,
        hasLength(20000 - ConversationTranscriptPort.maxRowChars),
      );
      expect(slice.nextOffset, isNull);
      expect(
        await reader.sliceRun(
          workspaceId: 'ws-1',
          runId: 'child-2',
          rowId: 'child-1:2',
          offset: 0,
        ),
        isNull,
      );
    });

    test('another workspace or another run reads as empty', () async {
      for (final (ws, run) in [('ws-2', 'child-1'), ('ws-1', 'child-2')]) {
        final p = await pageRun(ws, run);
        expect(p.rows, isEmpty, reason: '$ws/$run');
        expect(p.nextStart, isNull);
      }
    });
  });

  test('in a conversation of thousands of turns with large tool outputs, '
      'one read takes a bounded number of rows and bytes, and paging with a '
      'filter finds every match', () async {
    const turns = 3000;
    final big = 'z' * (256 * 1024);
    for (var i = 0; i < turns; i++) {
      if (i % 10 == 0) {
        await person('p-$i', 'carry on $i');
      }
      await turn('t-$i', [
        TextSegment(text: 'step $i', startedAt: t0),
        tool('bash', 'built $i\n${'log line\n' * 200}'),
        if (i % 100 == 7) tool('grep', '$i:$big'),
        ErrorSegment(message: 'flaky $i', startedAt: t0),
      ]);
    }
    const messageCount = turns + turns ~/ 10;
    final ids = [
      for (var i = 0; i < turns; i++) ...[if (i % 10 == 0) 'p-$i', 't-$i'],
    ];
    expect(ids, hasLength(messageCount));
    // The window, and the one message past it that says where the next
    // page starts.
    final bound = _Take(
      messages: ConversationTranscriptPort.maxScanMessages + 1,
      segments: ConversationTranscriptPort.maxPageRows,
      texts: ConversationTranscriptPort.maxPageRows,
      textBytes: CodeModeLimits.historyReadTextBytes,
    );
    expect(CodeModeLimits.historyScanMessages, bound.messages - 1);

    // A filter that matches little: every match, in order, and no read
    // past the bound.
    final grep = await all(tools: {'grep'});
    expect(grep.rows.map((r) => r.id), [
      for (var i = 0; i < turns; i++)
        if (i % 100 == 7) 't-$i:2',
    ]);
    expect(grep.rows.every((r) => r.cut && r.fullLength! > 256 * 1024), isTrue);
    // Each read scans one window of messages and reads only the rows
    // that matched in it: 200 messages and the next, 2 segments, 32 KiB of
    // text.
    expect(grep.takes.first.messages, bound.messages);
    expect(grep.takes.first.texts, 2);
    expect(
      grep.takes,
      hasLength(
        (messageCount / ConversationTranscriptPort.maxScanMessages).ceil(),
      ),
    );
    for (final take in grep.takes) {
      expect(take.within(bound), isTrue, reason: '$take');
    }

    // A filter that matches nothing: empty pages that still say where to
    // read on, until the end.
    store.reset();
    final none = await page(roles: {TranscriptRole.compaction});
    expect(none.rows, isEmpty);
    expect(none.nextStart, await at(ids[200]));
    expect(none.messageCount, messageCount);
    expect(store.take.within(bound), isTrue, reason: '${store.take}');
    final nothing = await all(roles: {TranscriptRole.compaction});
    expect(nothing.rows, isEmpty);
    expect(nothing.takes.every((t) => t.within(bound)), isTrue);

    // Unfiltered reads deep in the conversation cost the same as the first.
    for (final start in [
      null,
      await at(ids[1500]),
      await at(ids[messageCount - 3]),
    ]) {
      store.reset();
      final p = await page(start: start);
      expect(p.rows, isNotEmpty);
      expect(store.take.within(bound), isTrue, reason: '$start ${store.take}');
    }
    // A page over a large output: its row is cut, the page stays in
    // 64 KiB, and it says where to read on.
    store.reset();
    final atBig = await page(start: await at('t-707'));
    expect(atBig.rows.take(3).map((r) => r.id), [
      't-707:0',
      't-707:1',
      't-707:2',
    ]);
    expect(
      atBig.rows
          .map((r) => utf8.encode(r.text).length)
          .fold(0, (a, b) => a + b),
      lessThanOrEqualTo(ConversationTranscriptPort.maxPageBytes),
    );
    expect(atBig.nextStart, isNotNull);
    expect(store.take.within(bound), isTrue, reason: '${store.take}');
  }, timeout: const Timeout(Duration(minutes: 2)));
}

/// What reads took from the store.
class _Take {
  _Take({
    this.messages = 0,
    this.segments = 0,
    this.texts = 0,
    this.textBytes = 0,
  });

  int messages;
  int segments;
  int texts;
  int textBytes;

  bool within(_Take bound) =>
      messages <= bound.messages &&
      segments <= bound.segments &&
      texts <= bound.texts &&
      textBytes <= bound.textBytes;

  @override
  String toString() =>
      'messages $messages, segments $segments, texts $texts, '
      'text bytes $textBytes';
}

/// The real store, counting the rows and the text each read takes from it.
class _Counting implements TranscriptStore {
  _Counting(this._inner);

  final TranscriptStore _inner;

  _Take take = _Take();

  void reset() => take = _Take();

  TranscriptStoreText? _text(TranscriptStoreText? text) {
    take.texts++;
    if (text != null) {
      take.textBytes += utf8.encode(text.text).length;
    }
    return text;
  }

  @override
  Future<int> messageCount({
    required String workspaceId,
    required String conversationId,
  }) => _inner.messageCount(
    workspaceId: workspaceId,
    conversationId: conversationId,
  );

  @override
  Future<List<TranscriptStoreMessage>> messages({
    required String workspaceId,
    required String conversationId,
    required TranscriptStorePlace? from,
    required int limit,
  }) async {
    final rows = await _inner.messages(
      workspaceId: workspaceId,
      conversationId: conversationId,
      from: from,
      limit: limit,
    );
    take.messages += rows.length;
    return rows;
  }

  @override
  Future<List<TranscriptStoreSegment>> segments({
    required String workspaceId,
    required String? messageId,
    required String? runId,
    required int fromSeq,
    required int limit,
    required Set<TranscriptSegmentKind> kinds,
    required Set<String>? tools,
  }) async {
    final rows = await _inner.segments(
      workspaceId: workspaceId,
      messageId: messageId,
      runId: runId,
      fromSeq: fromSeq,
      limit: limit,
      kinds: kinds,
      tools: tools,
    );
    take.segments += rows.length;
    return rows;
  }

  @override
  Future<TranscriptStoreText?> messageText({
    required String workspaceId,
    required String conversationId,
    required String messageId,
    required int from,
    required int chars,
  }) async => _text(
    await _inner.messageText(
      workspaceId: workspaceId,
      conversationId: conversationId,
      messageId: messageId,
      from: from,
      chars: chars,
    ),
  );

  @override
  Future<TranscriptStoreText?> segmentText({
    required String workspaceId,
    required String? conversationId,
    required String? messageId,
    required String? runId,
    required int seq,
    required int from,
    required int chars,
  }) async => _text(
    await _inner.segmentText(
      workspaceId: workspaceId,
      conversationId: conversationId,
      messageId: messageId,
      runId: runId,
      seq: seq,
      from: from,
      chars: chars,
    ),
  );

  @override
  Future<DateTime?> runStartedAt({
    required String workspaceId,
    required String runId,
  }) => _inner.runStartedAt(workspaceId: workspaceId, runId: runId);
}
