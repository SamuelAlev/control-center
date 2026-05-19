import 'package:control_center/core/database/app_database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_database.dart';

void main() {
  late AppDatabase db;

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

    test('getById is workspace-scoped (a foreign workspace cannot read it)',
        () async {
      await db.meetingDao.upsertMeeting(meeting('m1', 'w1'));

      expect(await db.meetingDao.getById('w1', 'm1'), isNotNull);
      expect(await db.meetingDao.getById('w2', 'm1'), isNull);
    });

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
    MeetingSpeakersTableCompanion speaker(
      String id,
      String ws,
      String label,
    ) =>
        MeetingSpeakersTableCompanion.insert(
          id: id,
          meetingId: 'm1',
          workspaceId: ws,
          channel: 'them',
          label: label,
        );

    test('replaceSpeakers + getSpeakers are workspace-scoped', () async {
      await db.meetingDao
          .replaceSpeakers('w1', 'm1', [speaker('sp1', 'w1', 'Person 1')]);

      final mine = await db.meetingDao.getSpeakers('w1', 'm1');
      expect(mine.map((s) => s.label), ['Person 1']);

      final foreign = await db.meetingDao.getSpeakers('w2', 'm1');
      expect(foreign, isEmpty);
    });

    test('replaceSpeakers carries a prior displayName forward by label',
        () async {
      await db.meetingDao
          .replaceSpeakers('w1', 'm1', [speaker('sp1', 'w1', 'Person 1')]);
      await db.meetingDao.setSpeakerDisplayName('w1', 'sp1', 'Alice');

      // Re-diarization regenerates rows with fresh ids; the name must survive.
      await db.meetingDao
          .replaceSpeakers('w1', 'm1', [speaker('sp2', 'w1', 'Person 1')]);

      final after = await db.meetingDao.getSpeakers('w1', 'm1');
      expect(after.single.displayName, 'Alice');
    });

    test('setSegmentSpeakerLabel writes the label, scoped to the workspace',
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
    });
  });

  group('MeetingDao.getUnfinalized (cross-workspace stale sweep)', () {
    test('returns recording + processing across workspaces, never terminal',
        () async {
      await db.meetingDao.upsertMeeting(meetingWith('rec', 'w1', 'recording'));
      await db.meetingDao.upsertMeeting(meetingWith('proc', 'w2', 'processing'));
      await db.meetingDao.upsertMeeting(meetingWith('done', 'w1', 'done'));
      await db.meetingDao.upsertMeeting(meetingWith('fail', 'w2', 'failed'));

      final stuck = await db.meetingDao.getUnfinalized();

      expect(
        stuck.map((m) => m.id).toSet(),
        {'rec', 'proc'},
        reason: 'only non-terminal meetings, regardless of workspace',
      );
    });

    test('is empty when every meeting is terminal', () async {
      await db.meetingDao.upsertMeeting(meetingWith('done', 'w1', 'done'));
      await db.meetingDao.upsertMeeting(meetingWith('fail', 'w1', 'failed'));

      expect(await db.meetingDao.getUnfinalized(), isEmpty);
    });
  });
}
