import 'dart:async';

import 'package:cc_domain/features/meetings/domain/entities/meeting.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_action_item.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_decision.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_segment.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_speaker_label.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late DaoMeetingRepository repo;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, 'ws-1');
    await seedTestWorkspace(global, dbs, 'ws-2');
    repo = DaoMeetingRepository(dbs);
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Meeting meeting0({
    String id = 'm1',
    String workspaceId = 'ws-1',
    String title = 'Test Meeting',
    MeetingStatus status = MeetingStatus.recording,
    String? sourceApp,
    String userNotes = '',
    String? enhancedNotes,
    String? summary,
    String? audioPath,
    DateTime? endedAt,
  }) {
    final now = DateTime(2026, 6, 11, 12, 0, 0);
    return Meeting(
      id: id,
      workspaceId: workspaceId,
      title: title,
      status: status,
      sourceApp: sourceApp,
      userNotes: userNotes,
      enhancedNotes: enhancedNotes,
      summary: summary,
      audioPath: audioPath,
      startedAt: now,
      endedAt: endedAt,
      createdAt: now,
      updatedAt: now,
    );
  }

  MeetingSegment segment({
    String id = 's1',
    String meetingId = 'm1',
    String workspaceId = 'ws-1',
    MeetingSpeaker speaker = MeetingSpeaker.me,
    String text = 'Hello world',
    int startMs = 0,
    int endMs = 1000,
  }) {
    final now = DateTime(2026, 6, 11, 12, 0, 0);
    return MeetingSegment(
      id: id,
      meetingId: meetingId,
      workspaceId: workspaceId,
      speaker: speaker,
      text: text,
      startMs: startMs,
      endMs: endMs,
      createdAt: now,
    );
  }

  // ---------------------------------------------------------------------------
  // upsert
  // ---------------------------------------------------------------------------
  group('upsert', () {
    test('inserts a new meeting', () async {
      final meeting = meeting0();
      await repo.upsert(meeting);

      final result = await repo.getById('ws-1', 'm1');
      expect(result, isNotNull);
      expect(result!.id, 'm1');
      expect(result.title, 'Test Meeting');
      expect(result.status, MeetingStatus.recording);
      expect(result.userNotes, '');
    });

    test('updates an existing meeting on upsert', () async {
      await repo.upsert(meeting0());
      final updated = meeting0(
        title: 'Updated Title',
        status: MeetingStatus.done,
      );
      await repo.upsert(updated);

      final result = await repo.getById('ws-1', 'm1');
      expect(result!.title, 'Updated Title');
      expect(result.status, MeetingStatus.done);
    });

    test('handles nullable fields on insert', () async {
      final meeting = meeting0(
        sourceApp: 'Zoom',
        enhancedNotes: 'enhanced notes',
        summary: 'executive summary',
        audioPath: '/tmp/audio.wav',
        endedAt: DateTime(2026, 6, 11, 13, 0, 0),
      );
      await repo.upsert(meeting);

      final result = await repo.getById('ws-1', 'm1');
      expect(result!.sourceApp, 'Zoom');
      expect(result.enhancedNotes, 'enhanced notes');
      expect(result.summary, 'executive summary');
      expect(result.audioPath, '/tmp/audio.wav');
      expect(result.endedAt, DateTime(2026, 6, 11, 13, 0, 0));
    });

    test('nullable fields persist when absent on update', () async {
      await repo.upsert(meeting0(sourceApp: 'Zoom', endedAt: DateTime(2026)));
      // Value.absentIfNull treats null as absent, so existing values survive.
      await repo.upsert(meeting0());

      final result = await repo.getById('ws-1', 'm1');
      expect(result!.sourceApp, 'Zoom');
      expect(result.endedAt, DateTime(2026));
    });

    test('all MeetingStatus values round-trip', () async {
      for (final status in MeetingStatus.values) {
        final id = 'm-${status.name}';
        await repo.upsert(meeting0(id: id, status: status));
        final result = await repo.getById('ws-1', id);
        expect(result!.status, status);
      }
    });
  });

  // ---------------------------------------------------------------------------
  // getById
  // ---------------------------------------------------------------------------
  group('getById', () {
    test('returns null for non-existent id', () async {
      final result = await repo.getById('ws-1', 'nonexistent');
      expect(result, isNull);
    });

    test('returns null when workspace mismatch', () async {
      await repo.upsert(meeting0());

      final result = await repo.getById('ws-2', 'm1');
      expect(result, isNull);
    });

    test('returns meeting when id and workspace match', () async {
      await repo.upsert(meeting0());

      final result = await repo.getById('ws-1', 'm1');
      expect(result, isNotNull);
      expect(result!.id, 'm1');
      expect(result.workspaceId, 'ws-1');
    });
  });

  // ---------------------------------------------------------------------------
  // getByWorkspace
  // ---------------------------------------------------------------------------
  group('getByWorkspace', () {
    test('returns empty list for workspace with no meetings', () async {
      final result = await repo.getByWorkspace('ws-1');
      expect(result, isEmpty);
    });

    test('returns only meetings for the given workspace', () async {
      await repo.upsert(meeting0(id: 'm1', workspaceId: 'ws-1'));
      await repo.upsert(meeting0(id: 'm2', workspaceId: 'ws-1'));
      await repo.upsert(meeting0(id: 'm3', workspaceId: 'ws-2'));

      final ws1 = await repo.getByWorkspace('ws-1');
      expect(ws1.length, 2);
      expect(ws1.map((m) => m.id), containsAll(['m1', 'm2']));

      final ws2 = await repo.getByWorkspace('ws-2');
      expect(ws2.length, 1);
      expect(ws2.single.id, 'm3');
    });

    test('returns newest first (by createdAt descending)', () async {
      // createdAt is embedded in the entity; upserting with different times
      // should be reflected in ordering.
      final early = DateTime(2026, 6, 1);
      final late = DateTime(2026, 6, 11);

      final m1 = Meeting(
        id: 'm-early',
        workspaceId: 'ws-1',
        title: 'Early',
        status: MeetingStatus.done,
        startedAt: early,
        createdAt: early,
        updatedAt: early,
      );
      final m2 = Meeting(
        id: 'm-late',
        workspaceId: 'ws-1',
        title: 'Late',
        status: MeetingStatus.done,
        startedAt: late,
        createdAt: late,
        updatedAt: late,
      );

      await repo.upsert(m1);
      await repo.upsert(m2);

      final result = await repo.getByWorkspace('ws-1');
      expect(result.length, 2);
      expect(result.first.id, 'm-late');
      expect(result.last.id, 'm-early');
    });
  });

  // ---------------------------------------------------------------------------
  // delete
  // ---------------------------------------------------------------------------
  group('delete', () {
    test('deletes an existing meeting', () async {
      await repo.upsert(meeting0());
      await repo.delete('ws-1', 'm1');

      final result = await repo.getById('ws-1', 'm1');
      expect(result, isNull);
    });

    test('is a no-op when meeting does not exist', () async {
      // Should not throw.
      await repo.delete('ws-1', 'nonexistent');
    });

    test('does not delete meeting from another workspace', () async {
      await repo.upsert(meeting0(workspaceId: 'ws-2'));

      await repo.delete('ws-1', 'm1');

      final result = await repo.getById('ws-2', 'm1');
      expect(result, isNotNull);
    });

    test('cascades deletes to transcript segments', () async {
      await repo.upsert(meeting0());
      await repo.appendSegment(segment());

      await repo.delete('ws-1', 'm1');

      final segments = await repo.getSegments('ws-1', 'm1');
      expect(segments, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // watchByWorkspace
  // ---------------------------------------------------------------------------
  group('watchByWorkspace', () {
    test('emits initial empty list', () async {
      final stream = repo.watchByWorkspace('ws-1');
      await expectLater(stream, emits(isEmpty));
    });

    test('emits newly inserted meetings', () async {
      final stream = repo.watchByWorkspace('ws-1');

      // First emission: empty.
      // After insert: one meeting.
      unawaited(
        expectLater(
          stream,
          emitsInOrder([
            isEmpty,
            predicate<List<Meeting>>(
              (list) => list.length == 1 && list.first.id == 'm1',
            ),
          ]),
        ),
      );

      // Give the stream chance to emit the initial empty value.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await repo.upsert(meeting0());
    });

    test('emits on upsert update', () async {
      await repo.upsert(meeting0(title: 'Old'));

      final stream = repo.watchByWorkspace('ws-1');
      unawaited(
        expectLater(
          stream,
          emitsInOrder([
            predicate<List<Meeting>>(
              (list) => list.length == 1 && list.first.title == 'Old',
            ),
            predicate<List<Meeting>>(
              (list) => list.length == 1 && list.first.title == 'New',
            ),
          ]),
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      await repo.upsert(meeting0(title: 'New'));
    });

    test('does not emit meetings from other workspace', () async {
      // The watch query fires on any table mutation but the WHERE clause
      // filters out rows from other workspaces, so ws-1 may see extra empty
      // emissions when ws-2 row is inserted.
      final stream = repo.watchByWorkspace('ws-1');
      final emissions = <List<Meeting>>[];
      final sub = stream.listen(emissions.add);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      await repo.upsert(meeting0(id: 'm-other', workspaceId: 'ws-2'));
      await repo.upsert(meeting0(id: 'm-ws1', workspaceId: 'ws-1'));

      await Future<void>.delayed(const Duration(milliseconds: 50));
      await sub.cancel();
      // Every emission should only contain ws-1 meetings.
      for (final batch in emissions) {
        for (final m in batch) {
          expect(m.workspaceId, 'ws-1');
        }
      }
      expect(emissions, isNotEmpty);
      // The final emission should include the ws-1 meeting.
      final last = emissions.last;
      expect(last.any((m) => m.id == 'm-ws1'), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // appendSegment & getSegments
  // ---------------------------------------------------------------------------
  group('segments', () {
    test('getSegments returns empty for meeting with no segments', () async {
      await repo.upsert(meeting0());
      final segments = await repo.getSegments('ws-1', 'm1');
      expect(segments, isEmpty);
    });

    test('appendSegment and getSegments round-trip', () async {
      await repo.upsert(meeting0());

      await repo.appendSegment(segment());
      await repo.appendSegment(
        segment(id: 's2', text: 'second', startMs: 1000, endMs: 2000),
      );

      final segments = await repo.getSegments('ws-1', 'm1');
      expect(segments.length, 2);
      expect(segments[0].id, 's1');
      expect(segments[0].text, 'Hello world');
      expect(segments[0].speaker, MeetingSpeaker.me);
      expect(segments[1].id, 's2');
    });

    test('appendSegment upsert updates existing segment', () async {
      await repo.upsert(meeting0());
      await repo.appendSegment(segment(id: 's1', text: 'original'));

      // Upsert same id with different text.
      await repo.appendSegment(segment(id: 's1', text: 'updated'));

      final segments = await repo.getSegments('ws-1', 'm1');
      expect(segments.length, 1);
      expect(segments.single.text, 'updated');
    });

    test('segments are returned oldest first (by startMs ascending)', () async {
      await repo.upsert(meeting0());
      await repo.appendSegment(
        segment(id: 'late', text: 'late', startMs: 5000, endMs: 6000),
      );
      await repo.appendSegment(
        segment(id: 'early', text: 'early', startMs: 0, endMs: 1000),
      );

      final segments = await repo.getSegments('ws-1', 'm1');
      expect(segments[0].id, 'early');
      expect(segments[1].id, 'late');
    });

    test('getSegments with wrong workspaceId returns empty', () async {
      await repo.upsert(meeting0());
      await repo.appendSegment(segment());

      final segments = await repo.getSegments('ws-2', 'm1');
      expect(segments, isEmpty);
    });

    test('all MeetingSpeaker values round-trip', () async {
      await repo.upsert(meeting0());
      await repo.appendSegment(segment(id: 'me', speaker: MeetingSpeaker.me));
      await repo.appendSegment(
        segment(id: 'them', speaker: MeetingSpeaker.them),
      );

      final segments = await repo.getSegments('ws-1', 'm1');
      expect(
        segments.firstWhere((s) => s.id == 'me').speaker,
        MeetingSpeaker.me,
      );
      expect(
        segments.firstWhere((s) => s.id == 'them').speaker,
        MeetingSpeaker.them,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // watchSegments
  // ---------------------------------------------------------------------------
  group('watchSegments', () {
    test('emits initial empty list for meeting with no segments', () async {
      await repo.upsert(meeting0());
      final stream = repo.watchSegments('ws-1', 'm1');
      await expectLater(stream, emits(isEmpty));
    });

    test('emits newly appended segments', () async {
      await repo.upsert(meeting0());

      final stream = repo.watchSegments('ws-1', 'm1');
      unawaited(
        expectLater(
          stream,
          emitsInOrder([
            isEmpty,
            predicate<List<MeetingSegment>>(
              (list) => list.length == 1 && list.first.id == 's1',
            ),
          ]),
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      await repo.appendSegment(segment());
    });

    test('workspace isolation on watchSegments', () async {
      await repo.upsert(meeting0());
      await repo.upsert(meeting0(id: 'm2', workspaceId: 'ws-2'));

      await repo.appendSegment(segment(id: 'ws1s', workspaceId: 'ws-1'));
      await repo.appendSegment(
        segment(id: 'ws2s', meetingId: 'm2', workspaceId: 'ws-2'),
      );

      // Should only see ws-1's segment.
      final segments = await repo.getSegments('ws-1', 'm1');
      expect(segments.length, 1);
      expect(segments.single.id, 'ws1s');
    });
  });

  // ---------------------------------------------------------------------------
  // action items & decisions
  // ---------------------------------------------------------------------------
  group('action items & decisions', () {
    MeetingActionItem item(
      String id,
      String content, {
      String? owner,
      bool done = false,
      String? ticketId,
      int sortOrder = 0,
    }) => MeetingActionItem(
      id: id,
      meetingId: 'm1',
      workspaceId: 'ws-1',
      content: content,
      owner: owner,
      done: done,
      ticketId: ticketId,
      sortOrder: sortOrder,
      createdAt: DateTime(2026, 6, 11, 12),
    );

    test('replaceActionItems + watchActionItems round-trip in order', () async {
      await repo.upsert(meeting0());
      await repo.replaceActionItems('ws-1', 'm1', [
        item('a1', 'First', owner: 'Sam'),
        item('a2', 'Second', sortOrder: 1),
      ]);
      final rows = await repo.watchActionItems('ws-1', 'm1').first;
      expect(rows.map((r) => r.content), ['First', 'Second']);
      expect(rows.first.owner, 'Sam');
    });

    test('re-run carries forward done + ticketId by content', () async {
      await repo.upsert(meeting0());
      await repo.replaceActionItems('ws-1', 'm1', [item('a1', 'Email client')]);
      final first = (await repo.watchActionItems('ws-1', 'm1').first).single;
      await repo.setActionItemDone(
        workspaceId: 'ws-1',
        id: first.id,
        done: true,
      );
      await repo.setActionItemTicket(
        workspaceId: 'ws-1',
        id: first.id,
        ticketId: 'ENG-1',
      );

      // Re-run regenerates the row (fresh id, done=false, no ticket) with the
      // SAME content — the user's triage must survive.
      await repo.replaceActionItems('ws-1', 'm1', [item('a2', 'Email client')]);
      final after = (await repo.watchActionItems('ws-1', 'm1').first).single;
      expect(after.id, 'a2');
      expect(after.done, isTrue, reason: 'done must carry forward');
      expect(after.ticketId, 'ENG-1', reason: 'ticketId must carry forward');
    });

    test('replaceActionItems is workspace-scoped', () async {
      await repo.upsert(meeting0());
      await repo.replaceActionItems('ws-1', 'm1', [item('a1', 'X')]);
      final wrongWs = await repo.watchActionItems('ws-2', 'm1').first;
      expect(wrongWs, isEmpty);
    });

    test('watchActionItemStats counts total + done per meeting', () async {
      await repo.upsert(meeting0());
      await repo.replaceActionItems('ws-1', 'm1', [
        item('a1', 'X'),
        item('a2', 'Y'),
      ]);
      final rows = await repo.watchActionItems('ws-1', 'm1').first;
      await repo.setActionItemDone(
        workspaceId: 'ws-1',
        id: rows.first.id,
        done: true,
      );
      final stats = await repo.watchActionItemStats('ws-1').first;
      expect(stats['m1'], (total: 2, done: 1));
    });

    test('replaceDecisions + watchDecisions + counts round-trip', () async {
      await repo.upsert(meeting0());
      await repo.replaceDecisions('ws-1', 'm1', [
        MeetingDecision(
          id: 'd1',
          meetingId: 'm1',
          workspaceId: 'ws-1',
          content: 'Ship it',
          createdAt: DateTime(2026, 6, 11, 12),
        ),
      ]);
      final rows = await repo.watchDecisions('ws-1', 'm1').first;
      expect(rows.single.content, 'Ship it');
      final counts = await repo.watchDecisionCounts('ws-1').first;
      expect(counts['m1'], 1);
    });

    test('cascade delete removes action items', () async {
      await repo.upsert(meeting0());
      await repo.replaceActionItems('ws-1', 'm1', [item('a1', 'X')]);
      await repo.delete('ws-1', 'm1');
      final rows = await repo.watchActionItems('ws-1', 'm1').first;
      expect(rows, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // manual editing: add / update / delete action items
  // ---------------------------------------------------------------------------
  group('manual action items', () {
    MeetingActionItem item(String id, String content, {int sortOrder = 0}) =>
        MeetingActionItem(
          id: id,
          meetingId: 'm1',
          workspaceId: 'ws-1',
          content: content,
          sortOrder: sortOrder,
          createdAt: DateTime(2026, 6, 11, 12),
        );

    MeetingActionItem manual(
      String id,
      String content, {
      String? owner,
      int sortOrder = 1000000,
    }) => MeetingActionItem(
      id: id,
      meetingId: 'm1',
      workspaceId: 'ws-1',
      content: content,
      owner: owner,
      sortOrder: sortOrder,
      isManual: true,
      createdAt: DateTime(2026, 6, 11, 12),
    );

    test('addActionItem inserts a manual row', () async {
      await repo.upsert(meeting0());
      await repo.addActionItem(manual('a1', 'Follow up with Sam', owner: 'Me'));

      final rows = await repo.watchActionItems('ws-1', 'm1').first;
      expect(rows.single.content, 'Follow up with Sam');
      expect(rows.single.owner, 'Me');
      expect(rows.single.isManual, isTrue);
    });

    test(
      'updateActionItem edits content + owner and marks it manual',
      () async {
        await repo.upsert(meeting0());
        // Seed an AGENT row (isManual=false) via replace.
        await repo.replaceActionItems('ws-1', 'm1', [item('a1', 'Old text')]);
        final seeded = (await repo.watchActionItems('ws-1', 'm1').first).single;
        expect(seeded.isManual, isFalse);

        await repo.updateActionItem(
          workspaceId: 'ws-1',
          id: seeded.id,
          content: 'New text',
          owner: 'Alex',
        );

        final after = (await repo.watchActionItems('ws-1', 'm1').first).single;
        expect(after.content, 'New text');
        expect(after.owner, 'Alex');
        expect(after.isManual, isTrue, reason: 'editing marks the row manual');
      },
    );

    test('updateActionItem clears owner when null', () async {
      await repo.upsert(meeting0());
      await repo.addActionItem(manual('a1', 'X', owner: 'Sam'));
      await repo.updateActionItem(workspaceId: 'ws-1', id: 'a1', content: 'X');
      final after = (await repo.watchActionItems('ws-1', 'm1').first).single;
      expect(after.owner, isNull);
    });

    test('updateActionItem is a no-op across workspaces', () async {
      await repo.upsert(meeting0());
      await repo.addActionItem(manual('a1', 'X'));
      await repo.updateActionItem(
        workspaceId: 'ws-2',
        id: 'a1',
        content: 'hacked',
      );
      final after = (await repo.watchActionItems('ws-1', 'm1').first).single;
      expect(after.content, 'X');
    });

    test('deleteActionItem removes only the targeted row', () async {
      await repo.upsert(meeting0());
      await repo.addActionItem(manual('a1', 'Keep'));
      await repo.addActionItem(manual('a2', 'Drop'));
      await repo.deleteActionItem('ws-1', 'a2');
      final rows = await repo.watchActionItems('ws-1', 'm1').first;
      expect(rows.map((r) => r.content), ['Keep']);
    });

    test('deleteActionItem is a no-op across workspaces', () async {
      await repo.upsert(meeting0());
      await repo.addActionItem(manual('a1', 'X'));
      await repo.deleteActionItem('ws-2', 'a1');
      final rows = await repo.watchActionItems('ws-1', 'm1').first;
      expect(rows, hasLength(1));
    });

    test('re-run preserves manual rows but replaces agent rows', () async {
      await repo.upsert(meeting0());
      // One agent row + one manual row.
      await repo.replaceActionItems('ws-1', 'm1', [item('a1', 'Agent task')]);
      await repo.addActionItem(manual('mine', 'My own task'));

      // Re-run regenerates a different agent set.
      await repo.replaceActionItems('ws-1', 'm1', [
        item('a2', 'Agent task v2'),
      ]);

      final rows = await repo.watchActionItems('ws-1', 'm1').first;
      final contents = rows.map((r) => r.content).toList();
      expect(
        contents,
        contains('My own task'),
        reason: 'manual rows survive a re-run',
      );
      expect(contents, contains('Agent task v2'));
      expect(
        contents,
        isNot(contains('Agent task')),
        reason: 'the prior agent row is replaced',
      );
    });

    test('manual rows with a high sortOrder list after agent rows', () async {
      await repo.upsert(meeting0());
      await repo.replaceActionItems('ws-1', 'm1', [
        item('a1', 'First', sortOrder: 0),
        item('a2', 'Second', sortOrder: 1),
      ]);
      await repo.addActionItem(manual('mine', 'Mine', sortOrder: 1000000));
      final rows = await repo.watchActionItems('ws-1', 'm1').first;
      expect(rows.map((r) => r.content), ['First', 'Second', 'Mine']);
    });
  });

  // ---------------------------------------------------------------------------
  // manual editing: add / update / delete decisions
  // ---------------------------------------------------------------------------
  group('manual decisions', () {
    MeetingDecision agentDecision(String id, String content) => MeetingDecision(
      id: id,
      meetingId: 'm1',
      workspaceId: 'ws-1',
      content: content,
      createdAt: DateTime(2026, 6, 11, 12),
    );

    MeetingDecision manual(String id, String content) => MeetingDecision(
      id: id,
      meetingId: 'm1',
      workspaceId: 'ws-1',
      content: content,
      sortOrder: 1000000,
      isManual: true,
      createdAt: DateTime(2026, 6, 11, 12),
    );

    test('addDecision inserts a manual row', () async {
      await repo.upsert(meeting0());
      await repo.addDecision(manual('d1', 'Adopt Riverpod'));
      final rows = await repo.watchDecisions('ws-1', 'm1').first;
      expect(rows.single.content, 'Adopt Riverpod');
      expect(rows.single.isManual, isTrue);
    });

    test('updateDecision edits content and marks it manual', () async {
      await repo.upsert(meeting0());
      await repo.replaceDecisions('ws-1', 'm1', [agentDecision('d1', 'Old')]);
      final seeded = (await repo.watchDecisions('ws-1', 'm1').first).single;
      expect(seeded.isManual, isFalse);

      await repo.updateDecision(
        workspaceId: 'ws-1',
        id: seeded.id,
        content: 'New',
      );
      final after = (await repo.watchDecisions('ws-1', 'm1').first).single;
      expect(after.content, 'New');
      expect(after.isManual, isTrue);
    });

    test('updateDecision is a no-op across workspaces', () async {
      await repo.upsert(meeting0());
      await repo.addDecision(manual('d1', 'Keep'));
      await repo.updateDecision(
        workspaceId: 'ws-2',
        id: 'd1',
        content: 'hacked',
      );
      final after = (await repo.watchDecisions('ws-1', 'm1').first).single;
      expect(after.content, 'Keep');
    });

    test('deleteDecision removes only the targeted row', () async {
      await repo.upsert(meeting0());
      await repo.addDecision(manual('d1', 'Keep'));
      await repo.addDecision(manual('d2', 'Drop'));
      await repo.deleteDecision('ws-1', 'd2');
      final rows = await repo.watchDecisions('ws-1', 'm1').first;
      expect(rows.map((r) => r.content), ['Keep']);
    });

    test(
      're-run preserves manual decisions but replaces agent decisions',
      () async {
        await repo.upsert(meeting0());
        await repo.replaceDecisions('ws-1', 'm1', [
          agentDecision('d1', 'Agent'),
        ]);
        await repo.addDecision(manual('mine', 'Mine'));

        await repo.replaceDecisions('ws-1', 'm1', [
          agentDecision('d2', 'Agent v2'),
        ]);

        final rows = await repo.watchDecisions('ws-1', 'm1').first;
        final contents = rows.map((r) => r.content).toList();
        expect(contents, contains('Mine'));
        expect(contents, contains('Agent v2'));
        expect(contents, isNot(contains('Agent')));
      },
    );
  });

  // ---------------------------------------------------------------------------
  // updateTitle / updateNotes
  // ---------------------------------------------------------------------------
  group('updateTitle & updateNotes', () {
    test('updateTitle changes only the title', () async {
      await repo.upsert(meeting0(title: 'Old'));
      await repo.updateTitle(
        workspaceId: 'ws-1',
        meetingId: 'm1',
        title: 'New Title',
      );
      final result = await repo.getById('ws-1', 'm1');
      expect(result!.title, 'New Title');
    });

    test(
      'updateTitle is workspace-scoped (no-op in another workspace)',
      () async {
        await repo.upsert(meeting0(title: 'Keep'));
        await repo.updateTitle(
          workspaceId: 'ws-2',
          meetingId: 'm1',
          title: 'Hacked',
        );
        final result = await repo.getById('ws-1', 'm1');
        expect(result!.title, 'Keep');
      },
    );

    test('updateNotes changes only the notes', () async {
      await repo.upsert(meeting0(userNotes: 'old notes'));
      await repo.updateNotes(
        workspaceId: 'ws-1',
        meetingId: 'm1',
        notes: 'new notes',
      );
      final result = await repo.getById('ws-1', 'm1');
      expect(result!.userNotes, 'new notes');
    });

    test(
      'updateNotes is workspace-scoped (no-op in another workspace)',
      () async {
        await repo.upsert(meeting0(userNotes: 'keep'));
        await repo.updateNotes(
          workspaceId: 'ws-2',
          meetingId: 'm1',
          notes: 'hacked',
        );
        final result = await repo.getById('ws-1', 'm1');
        expect(result!.userNotes, 'keep');
      },
    );
  });

  // ---------------------------------------------------------------------------
  // getUnfinalized (cross-workspace sweep)
  // ---------------------------------------------------------------------------
  group('getUnfinalized', () {
    test('returns non-terminal meetings across all workspaces', () async {
      await repo.upsert(
        meeting0(
          id: 'rec',
          workspaceId: 'ws-1',
          status: MeetingStatus.recording,
        ),
      );
      await repo.upsert(
        meeting0(
          id: 'proc',
          workspaceId: 'ws-2',
          status: MeetingStatus.processing,
        ),
      );
      await repo.upsert(
        meeting0(id: 'done', workspaceId: 'ws-1', status: MeetingStatus.done),
      );

      final unfinalized = await repo.getUnfinalized();
      expect(unfinalized.map((m) => m.id).toSet(), {'rec', 'proc'});
    });

    test('returns empty when every meeting is finalized', () async {
      await repo.upsert(meeting0(status: MeetingStatus.done));
      expect(await repo.getUnfinalized(), isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // replaceSegments
  // ---------------------------------------------------------------------------
  group('replaceSegments', () {
    test('replaces a meeting transcript wholesale', () async {
      await repo.upsert(meeting0());
      await repo.appendSegment(segment(id: 'old', text: 'old'));
      await repo.replaceSegments('ws-1', 'm1', [
        segment(id: 'a', text: 'first', startMs: 0, endMs: 1000),
        segment(id: 'b', text: 'second', startMs: 1000, endMs: 2000),
      ]);
      final segments = await repo.getSegments('ws-1', 'm1');
      expect(segments.map((s) => s.id), ['a', 'b']);
    });

    test('clears all segments when given an empty list', () async {
      await repo.upsert(meeting0());
      await repo.appendSegment(segment(id: 's1', text: 'one'));
      await repo.replaceSegments('ws-1', 'm1', []);
      expect(await repo.getSegments('ws-1', 'm1'), isEmpty);
    });

    test('persists diarized speakerLabel + per-block name override', () async {
      await repo.upsert(meeting0());
      await repo.replaceSegments('ws-1', 'm1', [
        segment(id: 's1', text: 'hi'),
        MeetingSegment(
          id: 's2',
          meetingId: 'm1',
          workspaceId: 'ws-1',
          speaker: MeetingSpeaker.them,
          speakerLabel: 'Person 1',
          speakerNameOverride: 'Alice',
          text: 'hello',
          startMs: 0,
          endMs: 1,
          createdAt: DateTime(2026, 6, 11, 12),
        ),
      ]);
      final segments = await repo.getSegments('ws-1', 'm1');
      final s2 = segments.firstWhere((s) => s.id == 's2');
      expect(s2.speakerLabel, 'Person 1');
      expect(s2.speakerNameOverride, 'Alice');
    });

    test('is workspace-scoped', () async {
      await repo.upsert(meeting0());
      await repo.appendSegment(segment(id: 's1', text: 'ws1'));
      // A meeting with the SAME id in another workspace — the id colliding is
      // the point: each workspace's meeting lives in its own database file.
      await repo.upsert(meeting0(workspaceId: 'ws-2'));

      // Replace into ws-2 must not touch ws-1's segments.
      await repo.replaceSegments('ws-2', 'm1', [
        segment(id: 'x', text: 'ws2', workspaceId: 'ws-2'),
      ]);

      expect((await repo.getSegments('ws-1', 'm1')).map((s) => s.id), ['s1']);
      expect((await repo.getSegments('ws-2', 'm1')).map((s) => s.id), ['x']);
    });
  });

  // ---------------------------------------------------------------------------
  // per-segment speaker label / name overrides
  // ---------------------------------------------------------------------------
  group('segment speaker overrides', () {
    test('setSegmentSpeakerLabel stamps a diarization label', () async {
      await repo.upsert(meeting0());
      await repo.appendSegment(segment(id: 's1', text: 'hi'));
      await repo.setSegmentSpeakerLabel('ws-1', 's1', 'Person 2');
      final segments = await repo.getSegments('ws-1', 'm1');
      expect(segments.single.speakerLabel, 'Person 2');
    });

    test(
      'setSegmentSpeakerName sets and clears a per-block name override',
      () async {
        await repo.upsert(meeting0());
        await repo.appendSegment(segment(id: 's1', text: 'hi'));
        await repo.setSegmentSpeakerName('ws-1', 's1', 'Alice');
        var segments = await repo.getSegments('ws-1', 'm1');
        expect(segments.single.speakerNameOverride, 'Alice');

        await repo.setSegmentSpeakerName('ws-1', 's1', null);
        segments = await repo.getSegments('ws-1', 'm1');
        expect(segments.single.speakerNameOverride, isNull);
      },
    );

    test(
      'clearSpeakerNameOverridesForLabel clears overrides for a speaker',
      () async {
        await repo.upsert(meeting0());
        // Two segments on `them` with label 'Person 1', one on `me`.
        await repo.appendSegment(
          MeetingSegment(
            id: 'a',
            meetingId: 'm1',
            workspaceId: 'ws-1',
            speaker: MeetingSpeaker.them,
            speakerLabel: 'Person 1',
            speakerNameOverride: 'Alice',
            text: 'one',
            startMs: 0,
            endMs: 1,
            createdAt: DateTime(2026, 6, 11, 12),
          ),
        );
        await repo.appendSegment(
          MeetingSegment(
            id: 'b',
            meetingId: 'm1',
            workspaceId: 'ws-1',
            speaker: MeetingSpeaker.them,
            speakerLabel: 'Person 1',
            speakerNameOverride: 'Alice',
            text: 'two',
            startMs: 2,
            endMs: 3,
            createdAt: DateTime(2026, 6, 11, 12),
          ),
        );
        await repo.appendSegment(
          MeetingSegment(
            id: 'c',
            meetingId: 'm1',
            workspaceId: 'ws-1',
            speaker: MeetingSpeaker.them,
            speakerLabel: 'Person 2',
            speakerNameOverride: 'Bob',
            text: 'three',
            startMs: 4,
            endMs: 5,
            createdAt: DateTime(2026, 6, 11, 12),
          ),
        );

        await repo.clearSpeakerNameOverridesForLabel(
          workspaceId: 'ws-1',
          meetingId: 'm1',
          channel: MeetingSpeaker.them,
          label: 'Person 1',
        );

        final segments = await repo.getSegments('ws-1', 'm1');
        final a = segments.firstWhere((s) => s.id == 'a');
        final b = segments.firstWhere((s) => s.id == 'b');
        final c = segments.firstWhere((s) => s.id == 'c');
        expect(a.speakerNameOverride, isNull);
        expect(b.speakerNameOverride, isNull);
        expect(
          c.speakerNameOverride,
          'Bob',
          reason: 'other speakers are untouched',
        );
      },
    );
  });

  // ---------------------------------------------------------------------------
  // diarized speakers
  // ---------------------------------------------------------------------------
  group('speakers', () {
    MeetingSpeakerLabel speaker({
      String id = 'sp1',
      String meetingId = 'm1',
      String workspaceId = 'ws-1',
      MeetingSpeaker channel = MeetingSpeaker.them,
      String label = 'Person 1',
      String? displayName,
      List<double>? embedding,
      String? enrolledProfileName,
    }) => MeetingSpeakerLabel(
      id: id,
      meetingId: meetingId,
      workspaceId: workspaceId,
      channel: channel,
      label: label,
      displayName: displayName,
      embedding: embedding,
      enrolledProfileName: enrolledProfileName,
      createdAt: DateTime(2026, 6, 11, 12),
    );

    test(
      'replaceSpeakers + getSpeakers round-trip, ordered by label',
      () async {
        await repo.upsert(meeting0());
        await repo.replaceSpeakers('ws-1', 'm1', [
          speaker(id: 'b', label: 'Person 2', channel: MeetingSpeaker.them),
          speaker(id: 'a', label: 'Person 1', channel: MeetingSpeaker.me),
        ]);
        final speakers = await repo.getSpeakers('ws-1', 'm1');
        expect(speakers.map((s) => s.label), ['Person 1', 'Person 2']);
      },
    );

    test('replaceSpeakers is workspace-scoped', () async {
      await repo.upsert(meeting0());
      // Same meeting id in both workspaces; the rows land in different files.
      await repo.upsert(meeting0(workspaceId: 'ws-2'));
      await repo.replaceSpeakers('ws-2', 'm1', [speaker(workspaceId: 'ws-2')]);
      expect(await repo.getSpeakers('ws-1', 'm1'), isEmpty);
      expect(await repo.getSpeakers('ws-2', 'm1'), hasLength(1));
    });

    test('replaceSpeakers with an empty list clears existing rows', () async {
      await repo.upsert(meeting0());
      await repo.replaceSpeakers('ws-1', 'm1', [speaker()]);
      await repo.replaceSpeakers('ws-1', 'm1', []);
      expect(await repo.getSpeakers('ws-1', 'm1'), isEmpty);
    });

    test('replaceSpeakers persists embedding + enrolledProfileName', () async {
      await repo.upsert(meeting0());
      await repo.replaceSpeakers('ws-1', 'm1', [
        speaker(embedding: [0.1, 0.2, 0.3], enrolledProfileName: 'Alice VP'),
      ]);
      final speakers = await repo.getSpeakers('ws-1', 'm1');
      expect(speakers.single.embedding, [0.1, 0.2, 0.3]);
      expect(speakers.single.enrolledProfileName, 'Alice VP');
    });

    test(
      'replaceSpeakers carries forward displayName + enrolledProfileName',
      () async {
        await repo.upsert(meeting0());
        // First pass: user renames 'Person 1' (them) and enrolls it.
        await repo.replaceSpeakers('ws-1', 'm1', [
          speaker(
            label: 'Person 1',
            channel: MeetingSpeaker.them,
            displayName: 'Alice',
            enrolledProfileName: 'Alice VP',
          ),
        ]);
        // Re-diarization regenerates the row with no displayName — the prior
        // name + enrollment must survive by (channel, label) match.
        await repo.replaceSpeakers('ws-1', 'm1', [
          speaker(id: 'fresh', label: 'Person 1', channel: MeetingSpeaker.them),
        ]);
        final speakers = await repo.getSpeakers('ws-1', 'm1');
        expect(speakers.single.id, 'fresh');
        expect(speakers.single.displayName, 'Alice');
        expect(speakers.single.enrolledProfileName, 'Alice VP');
      },
    );

    test('watchSpeakers emits speakers for the meeting', () async {
      await repo.upsert(meeting0());
      await repo.replaceSpeakers('ws-1', 'm1', [speaker()]);
      final speakers = await repo.watchSpeakers('ws-1', 'm1').first;
      expect(speakers.map((s) => s.label), ['Person 1']);
    });

    test('renameSpeaker sets/clears the displayName by id', () async {
      await repo.upsert(meeting0());
      await repo.replaceSpeakers('ws-1', 'm1', [speaker()]);
      await repo.renameSpeaker(
        workspaceId: 'ws-1',
        id: 'sp1',
        displayName: 'Alice',
      );
      var speakers = await repo.getSpeakers('ws-1', 'm1');
      expect(speakers.single.displayName, 'Alice');

      await repo.renameSpeaker(
        workspaceId: 'ws-1',
        id: 'sp1',
        displayName: null,
      );
      speakers = await repo.getSpeakers('ws-1', 'm1');
      expect(speakers.single.displayName, isNull);
    });

    test(
      'renameSpeakerByLabel upserts the displayName by (channel, label)',
      () async {
        await repo.upsert(meeting0());
        // No speaker row yet — the rename must insert one.
        await repo.renameSpeakerByLabel(
          workspaceId: 'ws-1',
          meetingId: 'm1',
          channel: MeetingSpeaker.them,
          label: 'Person 1',
          displayName: 'Alice',
        );
        var speakers = await repo.getSpeakers('ws-1', 'm1');
        expect(speakers.single.displayName, 'Alice');

        // Second call updates the existing row.
        await repo.renameSpeakerByLabel(
          workspaceId: 'ws-1',
          meetingId: 'm1',
          channel: MeetingSpeaker.them,
          label: 'Person 1',
          displayName: 'Alice 2',
        );
        speakers = await repo.getSpeakers('ws-1', 'm1');
        expect(speakers, hasLength(1));
        expect(speakers.single.displayName, 'Alice 2');
      },
    );

    test(
      'setSpeakerEnrolledProfile records the enrolled voice profile',
      () async {
        await repo.upsert(meeting0());
        await repo.replaceSpeakers('ws-1', 'm1', [
          speaker(label: 'Person 1', channel: MeetingSpeaker.them),
        ]);
        await repo.setSpeakerEnrolledProfile(
          workspaceId: 'ws-1',
          meetingId: 'm1',
          channel: MeetingSpeaker.them,
          label: 'Person 1',
          profileName: 'Alice VP',
        );
        final speakers = await repo.getSpeakers('ws-1', 'm1');
        expect(speakers.single.enrolledProfileName, 'Alice VP');
      },
    );
  });
}
