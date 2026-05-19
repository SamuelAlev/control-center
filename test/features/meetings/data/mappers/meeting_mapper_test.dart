import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/features/meetings/data/mappers/meeting_mapper.dart';
import 'package:control_center/features/meetings/domain/entities/meeting.dart';
import 'package:control_center/features/meetings/domain/entities/meeting_segment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MeetingMapper mapper;

  setUp(() {
    mapper = const MeetingMapper();
  });

  group('MeetingMapper.toDomain', () {
    test('maps all fields correctly with non-null optional values',
        timeout: const Timeout.factor(2), () {
      final now = DateTime(2026, 6, 11, 12, 0, 0);
      final started = DateTime(2026, 6, 11, 11, 0, 0);
      final ended = DateTime(2026, 6, 11, 11, 45, 0);
      final updated = DateTime(2026, 6, 11, 12, 30, 0);

      final row = MeetingsTableData(
        id: 'meeting-1',
        workspaceId: 'ws-1',
        title: 'Sprint Review',
        status: 'done',
        mode: 'remote',
        titleIsCustom: false,
        sourceApp: 'Google Meet',
        userNotes: 'Discussed velocity',
        enhancedNotes: 'AI-enhanced notes',
        summary: 'Executive summary',
        audioPath: '/audio/meeting-1.wav',
        startedAt: started,
        endedAt: ended,
        createdAt: now,
        updatedAt: updated,
      );

      final meeting = mapper.toDomain(row);

      expect(meeting.id, 'meeting-1');
      expect(meeting.workspaceId, 'ws-1');
      expect(meeting.title, 'Sprint Review');
      expect(meeting.status, MeetingStatus.done);
      expect(meeting.mode, MeetingMode.remote);
      expect(meeting.sourceApp, 'Google Meet');
      expect(meeting.userNotes, 'Discussed velocity');
      expect(meeting.enhancedNotes, 'AI-enhanced notes');
      expect(meeting.summary, 'Executive summary');
      expect(meeting.audioPath, '/audio/meeting-1.wav');
      expect(meeting.startedAt, started);
      expect(meeting.endedAt, ended);
      expect(meeting.createdAt, now);
      expect(meeting.updatedAt, updated);
    });

    test('maps all nullable fields as null when absent',
        timeout: const Timeout.factor(2), () {
      final now = DateTime(2026, 6, 11);
      final started = DateTime(2026, 6, 10);

      final row = MeetingsTableData(
        id: 'meeting-2',
        workspaceId: 'ws-2',
        title: 'Minimal Meeting',
        status: 'recording',
        mode: 'remote',
        titleIsCustom: false,
        userNotes: '',
        startedAt: started,
        createdAt: now,
        updatedAt: now,
        // All nullable fields omitted (null)
      );

      final meeting = mapper.toDomain(row);

      expect(meeting.sourceApp, isNull);
      expect(meeting.enhancedNotes, isNull);
      expect(meeting.summary, isNull);
      expect(meeting.audioPath, isNull);
      expect(meeting.endedAt, isNull);
    });

    test('MeetingStatus.fromStorage is used for status field',
        timeout: const Timeout.factor(2), () {
      final now = DateTime(2026, 6, 11);

      // Test all known status values
      final statusCases = {
        'recording': MeetingStatus.recording,
        'processing': MeetingStatus.processing,
        'done': MeetingStatus.done,
        'failed': MeetingStatus.failed,
      };

      for (final entry in statusCases.entries) {
        final row = MeetingsTableData(
          id: 'meeting-${entry.key}',
          workspaceId: 'ws-1',
          title: 'Test',
          status: entry.key,
          mode: 'remote',
        titleIsCustom: false,
          userNotes: '',
          startedAt: now,
          createdAt: now,
          updatedAt: now,
        );

        expect(mapper.toDomain(row).status, entry.value,
            reason: 'Status "${entry.key}" should map to ${entry.value}');
      }
    });

    test('MeetingStatus.fromStorage defaults to done for unknown status',
        timeout: const Timeout.factor(2), () {
      final now = DateTime(2026, 6, 11);

      final row = MeetingsTableData(
        id: 'meeting-unknown',
        workspaceId: 'ws-1',
        title: 'Unknown Status Meeting',
        status: 'nonexistent_status',
        mode: 'remote',
        titleIsCustom: false,
        userNotes: '',
        startedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      expect(mapper.toDomain(row).status, MeetingStatus.done);
    });

    test('defaults userNotes to empty string when mapped',
        timeout: const Timeout.factor(2), () {
      final now = DateTime(2026, 6, 11);

      final row = MeetingsTableData(
        id: 'meeting-blank-notes',
        workspaceId: 'ws-1',
        title: 'Blank Notes',
        status: 'done',
        mode: 'remote',
        titleIsCustom: false,
        userNotes: '',
        startedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      final meeting = mapper.toDomain(row);
      expect(meeting.userNotes, isEmpty);
    });

    test('preserves timestamp fields exactly', timeout: const Timeout.factor(2),
        () {
      final started = DateTime(2025, 1, 15, 9, 30, 0, 500);
      final ended = DateTime(2025, 1, 15, 10, 45, 30, 250);
      final created = DateTime(2025, 1, 15, 10, 45, 31);
      final updated = DateTime(2025, 1, 16, 8, 0, 0);

      final row = MeetingsTableData(
        id: 'ts-test',
        workspaceId: 'ws-1',
        title: 'Timestamp Test',
        status: 'done',
        mode: 'remote',
        titleIsCustom: false,
        userNotes: '',
        startedAt: started,
        endedAt: ended,
        createdAt: created,
        updatedAt: updated,
      );

      final meeting = mapper.toDomain(row);

      expect(meeting.startedAt, same(started));
      expect(meeting.endedAt, same(ended));
      expect(meeting.createdAt, same(created));
      expect(meeting.updatedAt, same(updated));
    });

    test('preserves non-empty userNotes', timeout: const Timeout.factor(2), () {
      final now = DateTime(2026, 6, 11);

      final row = MeetingsTableData(
        id: 'meeting-notes',
        workspaceId: 'ws-1',
        title: 'Notes',
        status: 'done',
        mode: 'remote',
        titleIsCustom: false,
        userNotes: 'Action item: follow up with design team',
        startedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      final meeting = mapper.toDomain(row);
      expect(meeting.userNotes, 'Action item: follow up with design team');
    });

    test('maps titleIsCustom', timeout: const Timeout.factor(2), () {
      final now = DateTime(2026, 6, 11);
      MeetingsTableData row({required bool custom}) => MeetingsTableData(
            id: 'meeting-title-custom-$custom',
            workspaceId: 'ws-1',
            title: 'Title',
            titleIsCustom: custom,
            status: 'done',
            mode: 'remote',
            userNotes: '',
            startedAt: now,
            createdAt: now,
            updatedAt: now,
          );

      expect(mapper.toDomain(row(custom: true)).titleIsCustom, isTrue);
      expect(mapper.toDomain(row(custom: false)).titleIsCustom, isFalse);
    });
  });

  group('MeetingMapper.segmentToDomain', () {
    test('maps all fields correctly', timeout: const Timeout.factor(2), () {
      final now = DateTime(2026, 6, 11, 12, 0, 0);

      final row = MeetingTranscriptSegmentsTableData(
        id: 'seg-1',
        meetingId: 'meeting-1',
        workspaceId: 'ws-1',
        speaker: 'me',
        content: 'Hello, can everyone hear me?',
        startMs: 0,
        endMs: 3500,
        createdAt: now,
      );

      final segment = mapper.segmentToDomain(row);

      expect(segment.id, 'seg-1');
      expect(segment.meetingId, 'meeting-1');
      expect(segment.workspaceId, 'ws-1');
      expect(segment.speaker, MeetingSpeaker.me);
      expect(segment.speakerLabel, isNull);
      expect(segment.text, 'Hello, can everyone hear me?');
      expect(segment.startMs, 0);
      expect(segment.endMs, 3500);
      expect(segment.createdAt, now);
    });

    test('MeetingSpeaker.fromStorage is used for speaker field',
        timeout: const Timeout.factor(2), () {
      final now = DateTime(2026, 6, 11);

      // 'me' should map to MeetingSpeaker.me
      final meRow = MeetingTranscriptSegmentsTableData(
        id: 'seg-me',
        meetingId: 'meeting-1',
        workspaceId: 'ws-1',
        speaker: 'me',
        content: 'My notes',
        startMs: 0,
        endMs: 1000,
        createdAt: now,
      );

      expect(mapper.segmentToDomain(meRow).speaker, MeetingSpeaker.me);

      // 'them' should map to MeetingSpeaker.them
      final themRow = MeetingTranscriptSegmentsTableData(
        id: 'seg-them',
        meetingId: 'meeting-1',
        workspaceId: 'ws-1',
        speaker: 'them',
        content: 'Their response',
        startMs: 1000,
        endMs: 2500,
        createdAt: now,
      );

      expect(mapper.segmentToDomain(themRow).speaker, MeetingSpeaker.them);
    });

    test('MeetingSpeaker.fromStorage defaults to them for unknown speaker',
        timeout: const Timeout.factor(2), () {
      final now = DateTime(2026, 6, 11);

      final row = MeetingTranscriptSegmentsTableData(
        id: 'seg-unknown',
        meetingId: 'meeting-1',
        workspaceId: 'ws-1',
        speaker: 'unknown_speaker',
        content: 'Unrecognized speaker text',
        startMs: 0,
        endMs: 500,
        createdAt: now,
      );

      expect(
          mapper.segmentToDomain(row).speaker, MeetingSpeaker.them);
    });

    test('maps content field to text', timeout: const Timeout.factor(2), () {
      final now = DateTime(2026, 6, 11);

      final row = MeetingTranscriptSegmentsTableData(
        id: 'seg-text',
        meetingId: 'meeting-1',
        workspaceId: 'ws-1',
        speaker: 'me',
        content: 'Mapping content → text',
        startMs: 2000,
        endMs: 5000,
        createdAt: now,
      );

      final segment = mapper.segmentToDomain(row);
      expect(segment.text, 'Mapping content → text');
    });

    test('maps empty content correctly', timeout: const Timeout.factor(2), () {
      final now = DateTime(2026, 6, 11);

      final row = MeetingTranscriptSegmentsTableData(
        id: 'seg-empty',
        meetingId: 'meeting-1',
        workspaceId: 'ws-1',
        speaker: 'them',
        content: '',
        startMs: 5000,
        endMs: 5000,
        createdAt: now,
      );

      final segment = mapper.segmentToDomain(row);
      expect(segment.text, isEmpty);
    });

    test('preserves millisecond offsets exactly', timeout: const Timeout.factor(2),
        () {
      final now = DateTime(2026, 6, 11);

      final edgeCases = [
        (0, 0), // Zero-length segment
        (0, 1), // Minimum positive
        (999999, 1000000), // Large values
      ];

      for (final (start, end) in edgeCases) {
        final row = MeetingTranscriptSegmentsTableData(
          id: 'seg-$start-$end',
          meetingId: 'meeting-1',
          workspaceId: 'ws-1',
          speaker: 'me',
          content: 'Segment at $start-$end',
          startMs: start,
          endMs: end,
          createdAt: now,
        );

        final segment = mapper.segmentToDomain(row);
        expect(segment.startMs, start,
            reason: 'startMs should be $start');
        expect(segment.endMs, end, reason: 'endMs should be $end');
      }
    });

    test('preserves createdAt timestamp exactly',
        timeout: const Timeout.factor(2), () {
      final created = DateTime(2025, 6, 15, 14, 30, 0, 123);

      final row = MeetingTranscriptSegmentsTableData(
        id: 'seg-ts',
        meetingId: 'meeting-1',
        workspaceId: 'ws-1',
        speaker: 'me',
        content: 'Timestamp preservation test',
        startMs: 100,
        endMs: 200,
        createdAt: created,
      );

      final segment = mapper.segmentToDomain(row);
      expect(segment.createdAt, same(created));
    });
  });
}
