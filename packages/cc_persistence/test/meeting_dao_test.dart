import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

void main() {
  late WorkspaceDatabase db;

  setUp(() async {
    db = createTestDatabase();
    // Scope this test to DAO query logic, not FK enforcement.
    await db.customStatement('PRAGMA foreign_keys = OFF');
  });

  tearDown(() async {
    await db.close();
  });

  MeetingsTableCompanion meeting(String id, String ws) =>
      MeetingsTableCompanion.insert(id: id, workspaceId: ws, title: 'M $id');

  MeetingsTableCompanion meetingWith(String id, String ws, String status) =>
      MeetingsTableCompanion.insert(
        id: id,
        workspaceId: ws,
        title: 'M $id',
        status: Value(status),
      );

  group('MeetingDao workspace isolation', () {
    test('watchByWorkspace returns only the workspace rows', () async {
      await db.meetingDao.upsertMeeting(meeting('m1', 'w1'));
      await db.meetingDao.upsertMeeting(meeting('m2', 'w2'));

      final w1 = await db.meetingDao.watchByWorkspace('w1').first;
      expect(w1.map((m) => m.id), ['m1']);
    });

    test(
      'getById is workspace-scoped (a foreign workspace cannot read it)',
      () async {
        await db.meetingDao.upsertMeeting(meeting('m1', 'w1'));

        expect(await db.meetingDao.getById('w1', 'm1'), isNotNull);
        expect(await db.meetingDao.getById('w2', 'm1'), isNull);
      },
    );

    test('segments are scoped by workspace + meeting', () async {
      await db.meetingDao.upsertMeeting(meeting('m1', 'w1'));
      await db.meetingDao.insertSegment(
        MeetingTranscriptSegmentsTableCompanion.insert(
          id: 's1',
          meetingId: 'm1',
          workspaceId: 'w1',
          speaker: 'me',
          content: 'hello',
          startMs: 0,
          endMs: 1000,
        ),
      );

      final inScope = await db.meetingDao.watchSegments('w1', 'm1').first;
      expect(inScope, hasLength(1));
      expect(inScope.first.content, 'hello');

      final foreign = await db.meetingDao.getSegments('w2', 'm1');
      expect(foreign, isEmpty);
    });

    test('deleteMeeting only deletes within the workspace', () async {
      await db.meetingDao.upsertMeeting(meeting('m1', 'w1'));

      await db.meetingDao.deleteMeeting('w2', 'm1'); // wrong workspace — no-op
      expect(await db.meetingDao.getById('w1', 'm1'), isNotNull);

      await db.meetingDao.deleteMeeting('w1', 'm1');
      expect(await db.meetingDao.getById('w1', 'm1'), isNull);
    });
  });

  group('MeetingDao diarized speakers', () {
    MeetingSpeakersTableCompanion speaker(String id, String ws, String label) =>
        MeetingSpeakersTableCompanion.insert(
          id: id,
          meetingId: 'm1',
          workspaceId: ws,
          channel: 'them',
          label: label,
        );

    test('replaceSpeakers + getSpeakers are workspace-scoped', () async {
      await db.meetingDao.replaceSpeakers('w1', 'm1', [
        speaker('sp1', 'w1', 'Person 1'),
      ]);

      final mine = await db.meetingDao.getSpeakers('w1', 'm1');
      expect(mine.map((s) => s.label), ['Person 1']);

      final foreign = await db.meetingDao.getSpeakers('w2', 'm1');
      expect(foreign, isEmpty);
    });

    test(
      'replaceSpeakers carries a prior displayName forward by label',
      () async {
        await db.meetingDao.replaceSpeakers('w1', 'm1', [
          speaker('sp1', 'w1', 'Person 1'),
        ]);
        await db.meetingDao.setSpeakerDisplayName('w1', 'sp1', 'Alice');

        // Re-diarization regenerates rows with fresh ids; the name must survive.
        await db.meetingDao.replaceSpeakers('w1', 'm1', [
          speaker('sp2', 'w1', 'Person 1'),
        ]);

        final after = await db.meetingDao.getSpeakers('w1', 'm1');
        expect(after.single.displayName, 'Alice');
      },
    );

    test(
      'upsertSpeakerDisplayName inserts a row when none exists yet',
      () async {
        // No speaker rows for this label (e.g. diarization labeled the segment
        // but never persisted the speaker) — the rename must still create it.
        await db.meetingDao.upsertSpeakerDisplayName(
          workspaceId: 'w1',
          meetingId: 'm1',
          channel: 'them',
          label: 'Person 1',
          displayName: 'Alice',
          newId: 'sp-new',
          createdAt: DateTime(2026),
        );

        final mine = await db.meetingDao.getSpeakers('w1', 'm1');
        expect(mine.single.id, 'sp-new');
        expect(mine.single.label, 'Person 1');
        expect(mine.single.displayName, 'Alice');

        // Scoped to the workspace — a foreign workspace can't see the new row.
        expect(await db.meetingDao.getSpeakers('w2', 'm1'), isEmpty);
      },
    );

    test(
      'upsertSpeakerDisplayName updates the existing row by (channel, label)',
      () async {
        await db.meetingDao.replaceSpeakers('w1', 'm1', [
          speaker('sp1', 'w1', 'Person 1'),
        ]);

        await db.meetingDao.upsertSpeakerDisplayName(
          workspaceId: 'w1',
          meetingId: 'm1',
          channel: 'them',
          label: 'Person 1',
          displayName: 'Bob',
          newId: 'sp-unused',
          createdAt: DateTime(2026),
        );

        // Updated in place — no duplicate row, original id kept.
        final after = await db.meetingDao.getSpeakers('w1', 'm1');
        expect(after.single.id, 'sp1');
        expect(after.single.displayName, 'Bob');
      },
    );

    test(
      'setSegmentSpeakerLabel writes the label, scoped to the workspace',
      () async {
        await db.meetingDao.insertSegment(
          MeetingTranscriptSegmentsTableCompanion.insert(
            id: 's1',
            meetingId: 'm1',
            workspaceId: 'w1',
            speaker: 'them',
            content: 'hello',
            startMs: 0,
            endMs: 1000,
          ),
        );

        // Wrong workspace — no-op.
        await db.meetingDao.setSegmentSpeakerLabel('w2', 's1', 'Person 9');
        var seg = (await db.meetingDao.getSegments('w1', 'm1')).single;
        expect(seg.speakerLabel, isNull);

        await db.meetingDao.setSegmentSpeakerLabel('w1', 's1', 'Person 1');
        seg = (await db.meetingDao.getSegments('w1', 'm1')).single;
        expect(seg.speakerLabel, 'Person 1');
      },
    );

    test(
      'setSegmentSpeakerNameOverride sets + clears, scoped to the workspace',
      () async {
        await db.meetingDao.insertSegment(
          MeetingTranscriptSegmentsTableCompanion.insert(
            id: 's1',
            meetingId: 'm1',
            workspaceId: 'w1',
            speaker: 'them',
            content: 'hello',
            startMs: 0,
            endMs: 1000,
          ),
        );

        // Wrong workspace — no-op.
        await db.meetingDao.setSegmentSpeakerNameOverride('w2', 's1', 'Bob');
        var seg = (await db.meetingDao.getSegments('w1', 'm1')).single;
        expect(seg.speakerNameOverride, isNull);

        await db.meetingDao.setSegmentSpeakerNameOverride('w1', 's1', 'Bob');
        seg = (await db.meetingDao.getSegments('w1', 'm1')).single;
        expect(seg.speakerNameOverride, 'Bob');

        // Null clears the override.
        await db.meetingDao.setSegmentSpeakerNameOverride('w1', 's1', null);
        seg = (await db.meetingDao.getSegments('w1', 'm1')).single;
        expect(seg.speakerNameOverride, isNull);
      },
    );

    test(
      'clearSpeakerNameOverridesForLabel clears only the matching speaker',
      () async {
        // Two lines for Person 1 (them) + one line for Person 2 (them), all with
        // per-block overrides.
        for (final (id, label) in [
          ('s1', 'Person 1'),
          ('s2', 'Person 1'),
          ('s3', 'Person 2'),
        ]) {
          await db.meetingDao.insertSegment(
            MeetingTranscriptSegmentsTableCompanion.insert(
              id: id,
              meetingId: 'm1',
              workspaceId: 'w1',
              speaker: 'them',
              speakerLabel: Value(label),
              content: 'x',
              startMs: 0,
              endMs: 1,
            ),
          );
          await db.meetingDao.setSegmentSpeakerNameOverride('w1', id, 'Custom');
        }

        await db.meetingDao.clearSpeakerNameOverridesForLabel(
          workspaceId: 'w1',
          meetingId: 'm1',
          channel: 'them',
          label: 'Person 1',
        );

        final byId = {
          for (final s in await db.meetingDao.getSegments('w1', 'm1')) s.id: s,
        };
        // Person 1's overrides are cleared; Person 2's survives.
        expect(byId['s1']!.speakerNameOverride, isNull);
        expect(byId['s2']!.speakerNameOverride, isNull);
        expect(byId['s3']!.speakerNameOverride, 'Custom');
      },
    );

    test(
      'setSpeakerEnrolledProfileByLabel records + clears the provenance',
      () async {
        await db.meetingDao.replaceSpeakers('w1', 'm1', [
          speaker('sp1', 'w1', 'Person 1'),
        ]);

        await db.meetingDao.setSpeakerEnrolledProfileByLabel(
          workspaceId: 'w1',
          meetingId: 'm1',
          channel: 'them',
          label: 'Person 1',
          profileName: 'Alice',
        );
        expect(
          (await db.meetingDao.getSpeakers(
            'w1',
            'm1',
          )).single.enrolledProfileName,
          'Alice',
        );

        await db.meetingDao.setSpeakerEnrolledProfileByLabel(
          workspaceId: 'w1',
          meetingId: 'm1',
          channel: 'them',
          label: 'Person 1',
          profileName: null,
        );
        expect(
          (await db.meetingDao.getSpeakers(
            'w1',
            'm1',
          )).single.enrolledProfileName,
          isNull,
        );
      },
    );

    test(
      'replaceSpeakers carries enrolledProfileName forward by label',
      () async {
        await db.meetingDao.replaceSpeakers('w1', 'm1', [
          speaker('sp1', 'w1', 'Person 1'),
        ]);
        await db.meetingDao.setSpeakerEnrolledProfileByLabel(
          workspaceId: 'w1',
          meetingId: 'm1',
          channel: 'them',
          label: 'Person 1',
          profileName: 'Alice',
        );

        // Re-diarization regenerates rows with fresh ids; provenance must survive.
        await db.meetingDao.replaceSpeakers('w1', 'm1', [
          speaker('sp2', 'w1', 'Person 1'),
        ]);

        expect(
          (await db.meetingDao.getSpeakers(
            'w1',
            'm1',
          )).single.enrolledProfileName,
          'Alice',
        );
      },
    );
  });

  group('MeetingDao.getUnfinalized (cross-workspace stale sweep)', () {
    test(
      'returns recording + processing across workspaces, never terminal',
      () async {
        await db.meetingDao.upsertMeeting(
          meetingWith('rec', 'w1', 'recording'),
        );
        await db.meetingDao.upsertMeeting(
          meetingWith('proc', 'w2', 'processing'),
        );
        await db.meetingDao.upsertMeeting(meetingWith('done', 'w1', 'done'));
        await db.meetingDao.upsertMeeting(meetingWith('fail', 'w2', 'failed'));

        final stuck = await db.meetingDao.getUnfinalized();

        expect(stuck.map((m) => m.id).toSet(), {
          'rec',
          'proc',
        }, reason: 'only non-terminal meetings, regardless of workspace');
      },
    );

    test('is empty when every meeting is terminal', () async {
      await db.meetingDao.upsertMeeting(meetingWith('done', 'w1', 'done'));
      await db.meetingDao.upsertMeeting(meetingWith('fail', 'w1', 'failed'));

      expect(await db.meetingDao.getUnfinalized(), isEmpty);
    });
  });

  group('MeetingDao.getByWorkspace + upsert ordering', () {
    test(
      'returns workspace rows newest-first, isolates by workspace',
      () async {
        await db.meetingDao.upsertMeeting(
          MeetingsTableCompanion.insert(
            id: 'older',
            workspaceId: 'w1',
            title: 'Older',
            createdAt: Value(DateTime(2026, 1, 1)),
          ),
        );
        await db.meetingDao.upsertMeeting(
          MeetingsTableCompanion.insert(
            id: 'newer',
            workspaceId: 'w1',
            title: 'Newer',
            createdAt: Value(DateTime(2026, 1, 2)),
          ),
        );
        await db.meetingDao.upsertMeeting(meeting('other-ws', 'w2'));

        final rows = await db.meetingDao.getByWorkspace('w1');
        expect(rows.map((m) => m.id), ['newer', 'older']);
        // watchByWorkspace returns the same ordering, scoped.
        final watched = await db.meetingDao.watchByWorkspace('w2').first;
        expect(watched.map((m) => m.id), ['other-ws']);
      },
    );

    test('upsertMeeting updates an existing meeting in place', () async {
      await db.meetingDao.upsertMeeting(meeting('m1', 'w1'));
      await db.meetingDao.upsertMeeting(
        MeetingsTableCompanion.insert(
          id: 'm1',
          workspaceId: 'w1',
          title: 'Renamed',
        ),
      );
      final row = await db.meetingDao.getById('w1', 'm1');
      expect(row!.title, 'Renamed');
    });
  });

  group('MeetingDao.updateMeetingTitle / updateMeetingNotes', () {
    test('updateMeetingTitle writes title + bumps updatedAt, scoped', () async {
      await db.meetingDao.upsertMeeting(meeting('m1', 'w1'));
      // Foreign workspace — no-op.
      await db.meetingDao.updateMeetingTitle('w2', 'm1', 'Hacked');
      expect((await db.meetingDao.getById('w1', 'm1'))!.title, 'M m1');

      await db.meetingDao.updateMeetingTitle('w1', 'm1', 'Real title');
      final row = await db.meetingDao.getById('w1', 'm1');
      expect(row!.title, 'Real title');
    });

    test('updateMeetingNotes writes notes, scoped', () async {
      await db.meetingDao.upsertMeeting(meeting('m1', 'w1'));
      // Foreign workspace — no-op.
      await db.meetingDao.updateMeetingNotes('w2', 'm1', 'noop');
      expect((await db.meetingDao.getById('w1', 'm1'))!.userNotes, '');

      await db.meetingDao.updateMeetingNotes('w1', 'm1', 'my notes');
      final row = await db.meetingDao.getById('w1', 'm1');
      expect(row!.userNotes, 'my notes');
    });
  });

  group('MeetingDao.replaceSegments + insertSegment', () {
    MeetingTranscriptSegmentsTableCompanion seg(
      String id,
      int start,
      String ws,
    ) => MeetingTranscriptSegmentsTableCompanion.insert(
      id: id,
      meetingId: 'm1',
      workspaceId: ws,
      speaker: 'me',
      content: 'seg $id',
      startMs: start,
      endMs: start + 100,
    );

    test('replaceSegments is a delete+insert, ordered by startMs', () async {
      await db.meetingDao.insertSegment(seg('a', 200, 'w1'));
      await db.meetingDao.insertSegment(seg('b', 0, 'w1'));

      // Replace wholesale with a fresh set.
      await db.meetingDao.replaceSegments('w1', 'm1', [
        seg('c', 300, 'w1'),
        seg('d', 100, 'w1'),
      ]);

      final rows = await db.meetingDao.getSegments('w1', 'm1');
      expect(rows.map((s) => s.id), ['d', 'c']); // ascending by startMs
      expect(rows.map((s) => s.startMs), [100, 300]);
    });

    test(
      'replaceSegments with empty list clears the meeting\'s segments',
      () async {
        await db.meetingDao.insertSegment(seg('a', 0, 'w1'));
        await db.meetingDao.replaceSegments('w1', 'm1', const []);
        expect(await db.meetingDao.getSegments('w1', 'm1'), isEmpty);
      },
    );

    test(
      'replaceSegments is workspace-scoped (foreign workspace untouched)',
      () async {
        await db.meetingDao.insertSegment(seg('a', 0, 'w1'));
        await db.meetingDao.insertSegment(seg('b', 0, 'w2'));

        await db.meetingDao.replaceSegments('w1', 'm1', const []);

        expect(await db.meetingDao.getSegments('w1', 'm1'), isEmpty);
        expect((await db.meetingDao.getSegments('w2', 'm1')).map((s) => s.id), [
          'b',
        ]);
      },
    );
  });

  group('MeetingDao action items', () {
    MeetingActionItemsTableCompanion item(
      String id, {
      String ws = 'w1',
      String content = 'do it',
      int sortOrder = 0,
      bool isManual = false,
      bool done = false,
      String? owner,
      String? ticketId,
    }) => MeetingActionItemsTableCompanion.insert(
      id: id,
      meetingId: 'm1',
      workspaceId: ws,
      content: content,
      sortOrder: Value(sortOrder),
      isManual: Value(isManual),
      done: Value(done),
      owner: Value(owner),
      ticketId: Value(ticketId),
    );

    test('watchActionItems orders by sortOrder then createdAt', () async {
      await db.meetingDao.insertActionItem(
        item('i1', content: 'first', sortOrder: 1),
      );
      await db.meetingDao.insertActionItem(
        item('i2', content: 'zero', sortOrder: 0),
      );

      final rows = await db.meetingDao.watchActionItems('w1', 'm1').first;
      expect(rows.map((i) => i.content), ['zero', 'first']);
    });

    test('watchActionItems is scoped to (workspace, meeting)', () async {
      await db.meetingDao.insertActionItem(item('i1'));
      await db.meetingDao.insertActionItem(item('i2', ws: 'w2'));

      expect(
        (await db.meetingDao.watchActionItems('w1', 'm1').first).map(
          (i) => i.id,
        ),
        ['i1'],
      );
      expect(
        (await db.meetingDao.watchActionItems('w2', 'm1').first).map(
          (i) => i.id,
        ),
        ['i2'],
      );
    });

    test(
      'watchActionItemStats reports total + done per meeting, scoped',
      () async {
        await db.meetingDao.insertActionItem(item('a'));
        await db.meetingDao.insertActionItem(item('b', done: true));
        await db.meetingDao.insertActionItem(item('c', done: true));
        // Foreign workspace must not count.
        await db.meetingDao.insertActionItem(item('d', ws: 'w2'));

        final stats = await db.meetingDao.watchActionItemStats('w1').first;
        expect(stats['m1'], (total: 3, done: 2));
        expect(stats.containsKey('none'), isFalse);
      },
    );

    test(
      'replaceActionItems regenerates agent rows, preserves manual rows',
      () async {
        // A manual row survives the re-summarization.
        await db.meetingDao.insertActionItem(item('manual', isManual: true));
        // An agent row that will be replaced.
        await db.meetingDao.insertActionItem(
          item('old-agent', content: 'ship it', isManual: false, done: true),
        );

        await db.meetingDao.replaceActionItems('w1', 'm1', [
          item('new-agent', content: 'ship it', isManual: false),
          item('new2', content: 'write docs', isManual: false),
        ]);

        final rows = await db.meetingDao.watchActionItems('w1', 'm1').first;
        final byId = {for (final r in rows) r.id: r};
        // Manual row untouched; old agent row gone; new agent rows present.
        expect(byId.keys.toSet(), {'manual', 'new-agent', 'new2'});
        // The user's triage state (done) is carried forward by content match.
        expect(byId['new-agent']!.done, isTrue);
      },
    );

    test('replaceActionItems with empty list drops agent rows only', () async {
      await db.meetingDao.insertActionItem(item('agent', isManual: false));
      await db.meetingDao.insertActionItem(item('manual', isManual: true));

      await db.meetingDao.replaceActionItems('w1', 'm1', const []);

      final rows = await db.meetingDao.watchActionItems('w1', 'm1').first;
      expect(rows.map((i) => i.id), ['manual']);
    });

    test('updateActionItemContent marks the row manual, scoped', () async {
      await db.meetingDao.insertActionItem(item('i1', isManual: false));

      // Foreign workspace — no-op.
      await db.meetingDao.updateActionItemContent(
        'w2',
        'i1',
        content: 'noop',
        owner: 'bob',
      );
      final untouched =
          (await db.meetingDao.watchActionItems('w1', 'm1').first).single;
      expect(untouched.isManual, isFalse);

      await db.meetingDao.updateActionItemContent(
        'w1',
        'i1',
        content: 'edited',
        owner: 'alice',
      );
      final row =
          (await db.meetingDao.watchActionItems('w1', 'm1').first).single;
      expect(row.content, 'edited');
      expect(row.owner, 'alice');
      expect(row.isManual, isTrue);
    });

    test(
      'deleteActionItem + setActionItemDone + setActionItemTicket, scoped',
      () async {
        await db.meetingDao.insertActionItem(item('i1'));

        await db.meetingDao.setActionItemDone('w1', 'i1', done: true);
        var row =
            (await db.meetingDao.watchActionItems('w1', 'm1').first).single;
        expect(row.done, isTrue);

        await db.meetingDao.setActionItemTicket('w1', 'i1', 'T-42');
        row = (await db.meetingDao.watchActionItems('w1', 'm1').first).single;
        expect(row.ticketId, 'T-42');

        // Foreign-workspace done/ticket writes are no-ops.
        await db.meetingDao.setActionItemDone('w2', 'i1', done: false);
        await db.meetingDao.setActionItemTicket('w2', 'i1', 'T-x');
        row = (await db.meetingDao.watchActionItems('w1', 'm1').first).single;
        expect(row.done, isTrue);
        expect(row.ticketId, 'T-42');

        // Foreign-workspace delete is a no-op; owning workspace deletes.
        await db.meetingDao.deleteActionItem('w2', 'i1');
        expect(
          await db.meetingDao.watchActionItems('w1', 'm1').first,
          isNotEmpty,
        );
        await db.meetingDao.deleteActionItem('w1', 'i1');
        expect(await db.meetingDao.watchActionItems('w1', 'm1').first, isEmpty);
      },
    );
  });

  group('MeetingDao decisions', () {
    MeetingDecisionsTableCompanion decision(
      String id, {
      String ws = 'w1',
      String content = 'decided',
      int sortOrder = 0,
      bool isManual = false,
    }) => MeetingDecisionsTableCompanion.insert(
      id: id,
      meetingId: 'm1',
      workspaceId: ws,
      content: content,
      sortOrder: Value(sortOrder),
      isManual: Value(isManual),
    );

    test('watchDecisions orders by sortOrder then createdAt, scoped', () async {
      await db.meetingDao.insertDecision(
        decision('d1', content: 'b', sortOrder: 1),
      );
      await db.meetingDao.insertDecision(
        decision('d2', content: 'a', sortOrder: 0),
      );
      await db.meetingDao.insertDecision(decision('d3', ws: 'w2'));

      final rows = await db.meetingDao.watchDecisions('w1', 'm1').first;
      expect(rows.map((d) => d.content), ['a', 'b']);
    });

    test('watchDecisionCounts is per-meeting + workspace-scoped', () async {
      await db.meetingDao.insertDecision(decision('d1'));
      await db.meetingDao.insertDecision(decision('d2'));
      await db.meetingDao.insertDecision(decision('d3', ws: 'w2'));

      final counts = await db.meetingDao.watchDecisionCounts('w1').first;
      expect(counts['m1'], 2);
    });

    test(
      'replaceDecisions regenerates agent rows, preserves manual rows',
      () async {
        await db.meetingDao.insertDecision(decision('manual', isManual: true));
        await db.meetingDao.insertDecision(decision('old', isManual: false));

        await db.meetingDao.replaceDecisions('w1', 'm1', [
          decision('new1', isManual: false),
        ]);

        final rows = await db.meetingDao.watchDecisions('w1', 'm1').first;
        expect(rows.map((d) => d.id).toSet(), {'manual', 'new1'});
      },
    );

    test('replaceDecisions with empty list drops agent rows only', () async {
      await db.meetingDao.insertDecision(decision('agent', isManual: false));
      await db.meetingDao.insertDecision(decision('manual', isManual: true));

      await db.meetingDao.replaceDecisions('w1', 'm1', const []);

      final rows = await db.meetingDao.watchDecisions('w1', 'm1').first;
      expect(rows.map((d) => d.id), ['manual']);
    });

    test('updateDecisionContent marks the row manual, scoped', () async {
      await db.meetingDao.insertDecision(decision('d1', isManual: false));

      // Foreign workspace — no-op.
      await db.meetingDao.updateDecisionContent('w2', 'd1', content: 'noop');
      var row = (await db.meetingDao.watchDecisions('w1', 'm1').first).single;
      expect(row.isManual, isFalse);

      await db.meetingDao.updateDecisionContent('w1', 'd1', content: 'edited');
      row = (await db.meetingDao.watchDecisions('w1', 'm1').first).single;
      expect(row.content, 'edited');
      expect(row.isManual, isTrue);
    });

    test('deleteDecision is workspace-scoped', () async {
      await db.meetingDao.insertDecision(decision('d1'));

      await db.meetingDao.deleteDecision('w2', 'd1');
      expect(await db.meetingDao.watchDecisions('w1', 'm1').first, isNotEmpty);

      await db.meetingDao.deleteDecision('w1', 'd1');
      expect(await db.meetingDao.watchDecisions('w1', 'm1').first, isEmpty);
    });
  });

  group('MeetingDao.watchSpeakers', () {
    test('streams speakers ordered by label, scoped', () async {
      await db.meetingDao.replaceSpeakers('w1', 'm1', [
        MeetingSpeakersTableCompanion.insert(
          id: 'sp1',
          meetingId: 'm1',
          workspaceId: 'w1',
          channel: 'them',
          label: 'Person 2',
        ),
        MeetingSpeakersTableCompanion.insert(
          id: 'sp2',
          meetingId: 'm1',
          workspaceId: 'w1',
          channel: 'them',
          label: 'Person 1',
        ),
      ]);
      await db.meetingDao.replaceSpeakers('w2', 'm1', [
        MeetingSpeakersTableCompanion.insert(
          id: 'sp3',
          meetingId: 'm1',
          workspaceId: 'w2',
          channel: 'them',
          label: 'Other',
        ),
      ]);

      final rows = await db.meetingDao.watchSpeakers('w1', 'm1').first;
      expect(rows.map((s) => s.label), ['Person 1', 'Person 2']);
      expect(
        (await db.meetingDao.watchSpeakers('w2', 'm1').first).map(
          (s) => s.label,
        ),
        ['Other'],
      );
    });
  });
}
