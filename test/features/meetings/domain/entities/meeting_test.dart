import 'package:control_center/features/meetings/domain/entities/meeting.dart';
import 'package:test/test.dart';

final _baseNow = DateTime(2025, 6, 1, 12, 0, 0);
final _laterNow = DateTime(2025, 6, 1, 13, 0, 0);

Meeting _baseMeeting() => Meeting(
      id: 'meeting-1',
      workspaceId: 'ws-1',
      title: 'Sprint Review',
      status: MeetingStatus.recording,
      createdAt: _baseNow,
      updatedAt: _baseNow,
      startedAt: _baseNow,
      sourceApp: 'Zoom',
      userNotes: 'discussed roadmap',
      enhancedNotes: '## Summary\n\nWe aligned on Q3 goals.',
      summary: 'Q3 alignment meeting',
      audioPath: '/tmp/audio.wav',
      endedAt: _laterNow,
    );

void main() {
  group('Meeting constructor', () {
    test('throws assertion when workspaceId is empty', () {
      expect(
        () => Meeting(
          id: 'm',
          workspaceId: '',
          title: 'T',
          status: MeetingStatus.done,
          createdAt: _baseNow,
          updatedAt: _baseNow,
          startedAt: _baseNow,
        ),
        throwsA(isA<AssertionError>().having(
          (e) => e.message,
          'message',
          'Meeting workspaceId must not be empty',
        )),
      );
    });

    test('defaults optional fields to null / empty', () {
      final m = Meeting(
        id: 'm',
        workspaceId: 'ws',
        title: 'T',
        status: MeetingStatus.done,
        createdAt: _baseNow,
        updatedAt: _baseNow,
        startedAt: _baseNow,
      );
      expect(m.sourceApp, isNull);
      expect(m.userNotes, '');
      expect(m.enhancedNotes, isNull);
      expect(m.summary, isNull);
      expect(m.audioPath, isNull);
      expect(m.endedAt, isNull);
    });

    test('accepts and stores all fields', () {
      final m = _baseMeeting();
      expect(m.id, 'meeting-1');
      expect(m.workspaceId, 'ws-1');
      expect(m.title, 'Sprint Review');
      expect(m.status, MeetingStatus.recording);
      expect(m.sourceApp, 'Zoom');
      expect(m.userNotes, 'discussed roadmap');
      expect(m.enhancedNotes, '## Summary\n\nWe aligned on Q3 goals.');
      expect(m.summary, 'Q3 alignment meeting');
      expect(m.audioPath, '/tmp/audio.wav');
      expect(m.startedAt, _baseNow);
      expect(m.endedAt, _laterNow);
      expect(m.createdAt, _baseNow);
      expect(m.updatedAt, _baseNow);
    });

    test('title preserved as-is (no trimming)', () {
      const t = '  padded title  ';
      final m = Meeting(
        id: 'm',
        workspaceId: 'ws',
        title: t,
        status: MeetingStatus.done,
        createdAt: _baseNow,
        updatedAt: _baseNow,
        startedAt: _baseNow,
      );
      expect(m.title, t);
    });

    test('empty userNotes accepted', () {
      final m = Meeting(
        id: 'm',
        workspaceId: 'ws',
        title: 'T',
        status: MeetingStatus.done,
        createdAt: _baseNow,
        updatedAt: _baseNow,
        startedAt: _baseNow,
        userNotes: '',
      );
      expect(m.userNotes, '');
    });
  });

  group('Meeting.isEnhanced', () {
    test('false when enhancedNotes is null', () {
      final m = Meeting(
        id: 'm',
        workspaceId: 'ws',
        title: 'T',
        status: MeetingStatus.done,
        createdAt: _baseNow,
        updatedAt: _baseNow,
        startedAt: _baseNow,
      );
      expect(m.isEnhanced, false);
    });

    test('false when enhancedNotes is empty', () {
      final m = Meeting(
        id: 'm',
        workspaceId: 'ws',
        title: 'T',
        status: MeetingStatus.done,
        createdAt: _baseNow,
        updatedAt: _baseNow,
        startedAt: _baseNow,
        enhancedNotes: '',
      );
      expect(m.isEnhanced, false);
    });

    test('true when enhancedNotes is non-empty', () {
      final m = Meeting(
        id: 'm',
        workspaceId: 'ws',
        title: 'T',
        status: MeetingStatus.done,
        createdAt: _baseNow,
        updatedAt: _baseNow,
        startedAt: _baseNow,
        enhancedNotes: 'some notes',
      );
      expect(m.isEnhanced, true);
    });

    test('true for whitespace-only enhancedNotes', () {
      final m = Meeting(
        id: 'm',
        workspaceId: 'ws',
        title: 'T',
        status: MeetingStatus.done,
        createdAt: _baseNow,
        updatedAt: _baseNow,
        startedAt: _baseNow,
        enhancedNotes: '   ',
      );
      expect(m.isEnhanced, true);
    });
  });

  group('Meeting.copyWith', () {
    test('no args returns identical copy', () {
      final original = _baseMeeting();
      final copy = original.copyWith();
      expect(copy, original);
      expect(identical(copy, original), false);
    });

    test('overrides title', () {
      final copy = _baseMeeting().copyWith(title: 'New Title');
      expect(copy.title, 'New Title');
      expect(copy.id, 'meeting-1');
      expect(copy.workspaceId, 'ws-1');
      expect(copy.status, MeetingStatus.recording);
    });

    test('overrides status', () {
      final copy = _baseMeeting().copyWith(status: MeetingStatus.done);
      expect(copy.status, MeetingStatus.done);
    });

    test('overrides userNotes', () {
      final copy = _baseMeeting().copyWith(userNotes: 'updated notes');
      expect(copy.userNotes, 'updated notes');
    });

    test('overrides enhancedNotes', () {
      final copy =
          _baseMeeting().copyWith(enhancedNotes: '## Revised\n\nNew content');
      expect(copy.enhancedNotes, '## Revised\n\nNew content');
    });

    test('overrides summary', () {
      final copy = _baseMeeting().copyWith(summary: 'New summary');
      expect(copy.summary, 'New summary');
    });

    test('overrides audioPath', () {
      final copy = _baseMeeting().copyWith(audioPath: '/tmp/new.wav');
      expect(copy.audioPath, '/tmp/new.wav');
    });

    test('overrides sourceApp', () {
      final copy = _baseMeeting().copyWith(sourceApp: 'Meet');
      expect(copy.sourceApp, 'Meet');
    });

    test('overrides endedAt', () {
      final newEnd = DateTime(2026, 1, 1);
      final copy = _baseMeeting().copyWith(endedAt: newEnd);
      expect(copy.endedAt, newEnd);
    });

    test('overrides updatedAt', () {
      final newUpdate = DateTime(2026, 1, 1);
      final copy = _baseMeeting().copyWith(updatedAt: newUpdate);
      expect(copy.updatedAt, newUpdate);
    });

    test('copies immutable fields: id, workspaceId, startedAt, createdAt', () {
      final copy = _baseMeeting().copyWith();
      expect(copy.id, 'meeting-1');
      expect(copy.workspaceId, 'ws-1');
      expect(copy.startedAt, _baseNow);
      expect(copy.createdAt, _baseNow);
    });

    test('overrides multiple fields at once', () {
      final copy = _baseMeeting().copyWith(
        title: 'Retro',
        status: MeetingStatus.done,
        userNotes: '',
        enhancedNotes: 'final',
      );
      expect(copy.title, 'Retro');
      expect(copy.status, MeetingStatus.done);
      expect(copy.userNotes, '');
      expect(copy.enhancedNotes, 'final');
      expect(copy.id, 'meeting-1');
      expect(copy.workspaceId, 'ws-1');
      expect(copy.sourceApp, 'Zoom');
    });

    test('preserves null endedAt when no override', () {
      final m = Meeting(
        id: 'm',
        workspaceId: 'ws',
        title: 'T',
        status: MeetingStatus.recording,
        createdAt: _baseNow,
        updatedAt: _baseNow,
        startedAt: _baseNow,
      );
      final copy = m.copyWith(title: 'New');
      expect(copy.endedAt, isNull);
    });

    test('can set previously null endedAt', () {
      final m = Meeting(
        id: 'm',
        workspaceId: 'ws',
        title: 'T',
        status: MeetingStatus.recording,
        createdAt: _baseNow,
        updatedAt: _baseNow,
        startedAt: _baseNow,
      );
      final copy = m.copyWith(endedAt: _laterNow);
      expect(copy.endedAt, _laterNow);
    });

    test('preserves null sourceApp when no override', () {
      final m = Meeting(
        id: 'm',
        workspaceId: 'ws',
        title: 'T',
        status: MeetingStatus.done,
        createdAt: _baseNow,
        updatedAt: _baseNow,
        startedAt: _baseNow,
      );
      final copy = m.copyWith(title: 'New');
      expect(copy.sourceApp, isNull);
    });
  });

  group('Meeting equality', () {
    test('identical instance is equal', () {
      final m = _baseMeeting();
      expect(m == m, true);
    });

    test('same field values → equal', () {
      expect(_baseMeeting(), _baseMeeting());
    });

    test('different id → not equal', () {
      final a = _baseMeeting();
      final b = Meeting(
        id: 'meeting-2',
        workspaceId: 'ws-1',
        title: 'Sprint Review',
        status: MeetingStatus.recording,
        createdAt: _baseNow,
        updatedAt: _baseNow,
        startedAt: _baseNow,
        sourceApp: 'Zoom',
        userNotes: 'discussed roadmap',
        enhancedNotes: '## Summary\n\nWe aligned on Q3 goals.',
        summary: 'Q3 alignment meeting',
        audioPath: '/tmp/audio.wav',
        endedAt: _laterNow,
      );
      expect(a != b, true);
    });

    test('different workspaceId → not equal', () {
      final a = _baseMeeting();
      final b = Meeting(
        id: 'meeting-1',
        workspaceId: 'ws-2',
        title: 'Sprint Review',
        status: MeetingStatus.recording,
        createdAt: _baseNow,
        updatedAt: _baseNow,
        startedAt: _baseNow,
        sourceApp: 'Zoom',
        userNotes: 'discussed roadmap',
        enhancedNotes: '## Summary\n\nWe aligned on Q3 goals.',
        summary: 'Q3 alignment meeting',
        audioPath: '/tmp/audio.wav',
        endedAt: _laterNow,
      );
      expect(a != b, true);
    });

    test('different title → not equal', () {
      final a = _baseMeeting();
      final b = _baseMeeting().copyWith(title: 'Different');
      expect(a != b, true);
    });

    test('different status → not equal', () {
      final a = _baseMeeting();
      final b = _baseMeeting().copyWith(status: MeetingStatus.failed);
      expect(a != b, true);
    });

    test('different userNotes → not equal', () {
      final a = _baseMeeting();
      final b = _baseMeeting().copyWith(userNotes: 'different');
      expect(a != b, true);
    });

    test('different enhancedNotes → not equal', () {
      final a = _baseMeeting();
      final b = _baseMeeting().copyWith(enhancedNotes: 'different');
      expect(a != b, true);
    });

    test('different summary → not equal', () {
      final a = _baseMeeting();
      final b = _baseMeeting().copyWith(summary: 'different');
      expect(a != b, true);
    });

    test('different audioPath → not equal', () {
      final a = _baseMeeting();
      final b = _baseMeeting().copyWith(audioPath: '/tmp/other.wav');
      expect(a != b, true);
    });

    test('different sourceApp → not equal', () {
      final a = _baseMeeting();
      final b = _baseMeeting().copyWith(sourceApp: 'DifferentApp');
      expect(a != b, true);
    });

    test('different endedAt → not equal', () {
      final a = _baseMeeting();
      final b = _baseMeeting().copyWith(endedAt: DateTime(2026, 7, 1));
      expect(a != b, true);
    });

    test('different startedAt → not equal', () {
      final a = _baseMeeting();
      final b = Meeting(
        id: 'meeting-1',
        workspaceId: 'ws-1',
        title: 'Sprint Review',
        status: MeetingStatus.recording,
        createdAt: _baseNow,
        updatedAt: _baseNow,
        startedAt: DateTime(2025, 1, 1),
        sourceApp: 'Zoom',
        userNotes: 'discussed roadmap',
        enhancedNotes: '## Summary\n\nWe aligned on Q3 goals.',
        summary: 'Q3 alignment meeting',
        audioPath: '/tmp/audio.wav',
        endedAt: _laterNow,
      );
      expect(a != b, true);
    });

    test('createdAt and updatedAt are NOT part of equality', () {
      final a = _baseMeeting();
      final b = Meeting(
        id: 'meeting-1',
        workspaceId: 'ws-1',
        title: 'Sprint Review',
        status: MeetingStatus.recording,
        createdAt: DateTime(2000, 1, 1),
        updatedAt: DateTime(2000, 1, 1),
        startedAt: _baseNow,
        sourceApp: 'Zoom',
        userNotes: 'discussed roadmap',
        enhancedNotes: '## Summary\n\nWe aligned on Q3 goals.',
        summary: 'Q3 alignment meeting',
        audioPath: '/tmp/audio.wav',
        endedAt: _laterNow,
      );
      expect(a, b);
    });

    test('different type → not equal', () {
      final m = _baseMeeting();
      // ignore: unrelated_type_equality_checks
      expect(m == 'not a meeting', false);
    });

  });

  group('Meeting.hashCode', () {
    test('equal instances have equal hashCodes', () {
      expect(_baseMeeting().hashCode, _baseMeeting().hashCode);
    });

    test('copyWith with no overrides yields same hashCode', () {
      final original = _baseMeeting();
      expect(original.copyWith().hashCode, original.hashCode);
    });

    test('different id yields different hashCode', () {
      final a = _baseMeeting();
      final b = Meeting(
        id: 'meeting-2',
        workspaceId: 'ws-1',
        title: 'Sprint Review',
        status: MeetingStatus.recording,
        createdAt: _baseNow,
        updatedAt: _baseNow,
        startedAt: _baseNow,
        sourceApp: 'Zoom',
        userNotes: 'discussed roadmap',
        enhancedNotes: '## Summary\n\nWe aligned on Q3 goals.',
        summary: 'Q3 alignment meeting',
        audioPath: '/tmp/audio.wav',
        endedAt: _laterNow,
      );
      expect(a.hashCode != b.hashCode, true);
    });

    test('hashCode unaffected by createdAt/updatedAt', () {
      final a = _baseMeeting();
      final b = Meeting(
        id: 'meeting-1',
        workspaceId: 'ws-1',
        title: 'Sprint Review',
        status: MeetingStatus.recording,
        createdAt: DateTime(2000, 1, 1),
        updatedAt: DateTime(2000, 1, 1),
        startedAt: _baseNow,
        sourceApp: 'Zoom',
        userNotes: 'discussed roadmap',
        enhancedNotes: '## Summary\n\nWe aligned on Q3 goals.',
        summary: 'Q3 alignment meeting',
        audioPath: '/tmp/audio.wav',
        endedAt: _laterNow,
      );
      expect(a.hashCode, b.hashCode);
    });
  });

  group('MeetingStatus', () {
    test('fromStorage returns correct status for valid input', () {
      expect(MeetingStatus.fromStorage('recording'), MeetingStatus.recording);
      expect(MeetingStatus.fromStorage('processing'), MeetingStatus.processing);
      expect(MeetingStatus.fromStorage('done'), MeetingStatus.done);
      expect(MeetingStatus.fromStorage('failed'), MeetingStatus.failed);
    });

    test('fromStorage defaults to done for null', () {
      expect(MeetingStatus.fromStorage(null), MeetingStatus.done);
    });

    test('fromStorage defaults to done for unknown string', () {
      expect(MeetingStatus.fromStorage('bogus'), MeetingStatus.done);
    });

    test('toStorage returns name', () {
      expect(MeetingStatus.recording.toStorage(), 'recording');
      expect(MeetingStatus.done.toStorage(), 'done');
      expect(MeetingStatus.failed.toStorage(), 'failed');
      expect(MeetingStatus.processing.toStorage(), 'processing');
    });

    test('all four status values exist', () {
      expect(MeetingStatus.values, hasLength(4));
    });
  });

  group('Meeting edge cases', () {
    test('unicode title and notes', () {
      final m = Meeting(
        id: 'm-emoji',
        workspaceId: 'ws',
        title: 'Sprint \u{1f680} Review',
        status: MeetingStatus.done,
        createdAt: _baseNow,
        updatedAt: _baseNow,
        startedAt: _baseNow,
        userNotes: '\u{1f44d} discussed roadmap',
        enhancedNotes: '## \u6458\u8981\n\n\u5bf9\u9f50\u4e86Q3\u76ee\u6807\u3002',
      );
      expect(m.title, 'Sprint \u{1f680} Review');
      expect(m.userNotes, '\u{1f44d} discussed roadmap');
      expect(m.enhancedNotes, '## \u6458\u8981\n\n\u5bf9\u9f50\u4e86Q3\u76ee\u6807\u3002');
      expect(m.isEnhanced, true);
    });

    test('very long title', () {
      final longTitle = 'A' * 10000;
      final m = Meeting(
        id: 'm',
        workspaceId: 'ws',
        title: longTitle,
        status: MeetingStatus.done,
        createdAt: _baseNow,
        updatedAt: _baseNow,
        startedAt: _baseNow,
      );
      expect(m.title, longTitle);
      expect(m.title.length, 10000);
    });

    test('multiline userNotes', () {
      const notes = 'line1\nline2\nline3';
      final m = Meeting(
        id: 'm',
        workspaceId: 'ws',
        title: 'T',
        status: MeetingStatus.done,
        createdAt: _baseNow,
        updatedAt: _baseNow,
        startedAt: _baseNow,
        userNotes: notes,
      );
      expect(m.userNotes, notes);
    });

    test('dates far in the past and future', () {
      final m = Meeting(
        id: 'm',
        workspaceId: 'ws',
        title: 'T',
        status: MeetingStatus.done,
        createdAt: DateTime(1970, 1, 1),
        updatedAt: DateTime(2100, 12, 31),
        startedAt: DateTime(2025, 6, 1, 12),
      );
      expect(m.createdAt, DateTime(1970, 1, 1));
      expect(m.updatedAt, DateTime(2100, 12, 31));
    });

    test('endedAt is null when recording ongoing', () {
      final m = Meeting(
        id: 'm',
        workspaceId: 'ws',
        title: 'T',
        status: MeetingStatus.recording,
        createdAt: _baseNow,
        updatedAt: _baseNow,
        startedAt: _baseNow,
      );
      expect(m.endedAt, isNull);
    });
  });
}
