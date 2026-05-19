import 'package:cc_domain/features/meetings/domain/entities/meeting_segment.dart';
import 'package:test/test.dart';

final _baseTime = DateTime(2025, 6, 1, 12, 0, 0);

MeetingSegment _base() => MeetingSegment(
      id: 'seg-1',
      meetingId: 'meeting-1',
      workspaceId: 'ws-1',
      speaker: MeetingSpeaker.me,
      text: 'Hello world',
      startMs: 0,
      endMs: 5000,
      createdAt: _baseTime,
    );

void main() {
  group('MeetingSegment constructor', () {
    test('throws assertion when workspaceId is empty', () {
      expect(
        () => MeetingSegment(
          id: 'seg-1',
          meetingId: 'meeting-1',
          workspaceId: '',
          speaker: MeetingSpeaker.me,
          text: 'Hello',
          startMs: 0,
          endMs: 5000,
          createdAt: _baseTime,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('stores all fields', () {
      final seg = _base();
      expect(seg.id, 'seg-1');
      expect(seg.meetingId, 'meeting-1');
      expect(seg.workspaceId, 'ws-1');
      expect(seg.speaker, MeetingSpeaker.me);
      expect(seg.text, 'Hello world');
      expect(seg.startMs, 0);
      expect(seg.endMs, 5000);
      expect(seg.createdAt, _baseTime);
    });

    test('accepts THEM speaker', () {
      final seg = MeetingSegment(
        id: 'seg-2',
        meetingId: 'meeting-1',
        workspaceId: 'ws-2',
        speaker: MeetingSpeaker.them,
        text: 'Hi there',
        startMs: 5000,
        endMs: 10000,
        createdAt: _baseTime,
      );
      expect(seg.speaker, MeetingSpeaker.them);
    });

    test('accepts empty text', () {
      final seg = MeetingSegment(
        id: 'seg-3',
        meetingId: 'meeting-2',
        workspaceId: 'ws-3',
        speaker: MeetingSpeaker.me,
        text: '',
        startMs: 0,
        endMs: 0,
        createdAt: _baseTime,
      );
      expect(seg.text, '');
    });

    test('accepts negative startMs', () {
      final seg = MeetingSegment(
        id: 'seg-4',
        meetingId: 'meeting-3',
        workspaceId: 'ws-4',
        speaker: MeetingSpeaker.me,
        text: 'earlier',
        startMs: -100,
        endMs: 200,
        createdAt: _baseTime,
      );
      expect(seg.startMs, -100);
    });
  });

  group('MeetingSegment equality', () {
    test('identical segments are equal', () {
      expect(_base(), equals(_base()));
    });

    test('same values different instance are equal', () {
      final a = _base();
      final b = _base();
      expect(a, equals(b));
    });

    test('different id is not equal', () {
      final a = _base();
      final b = MeetingSegment(
        id: 'seg-2',
        meetingId: 'meeting-1',
        workspaceId: 'ws-1',
        speaker: MeetingSpeaker.me,
        text: 'Hello world',
        startMs: 0,
        endMs: 5000,
        createdAt: _baseTime,
      );
      expect(a, isNot(equals(b)));
    });

    test('different meetingId is not equal', () {
      final a = _base();
      final b = MeetingSegment(
        id: 'seg-1',
        meetingId: 'meeting-2',
        workspaceId: 'ws-1',
        speaker: MeetingSpeaker.me,
        text: 'Hello world',
        startMs: 0,
        endMs: 5000,
        createdAt: _baseTime,
      );
      expect(a, isNot(equals(b)));
    });

    test('different workspaceId is not equal', () {
      final a = _base();
      final b = MeetingSegment(
        id: 'seg-1',
        meetingId: 'meeting-1',
        workspaceId: 'ws-2',
        speaker: MeetingSpeaker.me,
        text: 'Hello world',
        startMs: 0,
        endMs: 5000,
        createdAt: _baseTime,
      );
      expect(a, isNot(equals(b)));
    });

    test('different speaker is not equal', () {
      final a = _base();
      final b = MeetingSegment(
        id: 'seg-1',
        meetingId: 'meeting-1',
        workspaceId: 'ws-1',
        speaker: MeetingSpeaker.them,
        text: 'Hello world',
        startMs: 0,
        endMs: 5000,
        createdAt: _baseTime,
      );
      expect(a, isNot(equals(b)));
    });

    test('different text is not equal', () {
      final a = _base();
      final b = MeetingSegment(
        id: 'seg-1',
        meetingId: 'meeting-1',
        workspaceId: 'ws-1',
        speaker: MeetingSpeaker.me,
        text: 'Different',
        startMs: 0,
        endMs: 5000,
        createdAt: _baseTime,
      );
      expect(a, isNot(equals(b)));
    });

    test('different startMs is not equal', () {
      final a = _base();
      final b = MeetingSegment(
        id: 'seg-1',
        meetingId: 'meeting-1',
        workspaceId: 'ws-1',
        speaker: MeetingSpeaker.me,
        text: 'Hello world',
        startMs: 100,
        endMs: 5000,
        createdAt: _baseTime,
      );
      expect(a, isNot(equals(b)));
    });

    test('different endMs is not equal', () {
      final a = _base();
      final b = MeetingSegment(
        id: 'seg-1',
        meetingId: 'meeting-1',
        workspaceId: 'ws-1',
        speaker: MeetingSpeaker.me,
        text: 'Hello world',
        startMs: 0,
        endMs: 6000,
        createdAt: _baseTime,
      );
      expect(a, isNot(equals(b)));
    });

    test('createdAt not part of equality', () {
      final a = _base();
      final b = MeetingSegment(
        id: 'seg-1',
        meetingId: 'meeting-1',
        workspaceId: 'ws-1',
        speaker: MeetingSpeaker.me,
        text: 'Hello world',
        startMs: 0,
        endMs: 5000,
        createdAt: DateTime(2026, 1, 1),
      );
      expect(a, equals(b));
    });
  });

  group('MeetingSegment hashCode', () {
    test('identical segments have same hashCode', () {
      expect(_base().hashCode, equals(_base().hashCode));
    });

    test('same values different instance have same hashCode', () {
      final a = _base();
      final b = _base();
      expect(a.hashCode, equals(b.hashCode));
    });

    test('createdAt does not affect hashCode', () {
      final a = _base();
      final b = MeetingSegment(
        id: 'seg-1',
        meetingId: 'meeting-1',
        workspaceId: 'ws-1',
        speaker: MeetingSpeaker.me,
        text: 'Hello world',
        startMs: 0,
        endMs: 5000,
        createdAt: DateTime(2026, 1, 1),
      );
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different field produces different hashCode', () {
      final a = _base();
      final b = MeetingSegment(
        id: 'seg-1',
        meetingId: 'meeting-1',
        workspaceId: 'ws-1',
        speaker: MeetingSpeaker.me,
        text: 'Different',
        startMs: 0,
        endMs: 5000,
        createdAt: _baseTime,
      );
      expect(a.hashCode, isNot(equals(b.hashCode)));
    });
  });

  group('MeetingSpeaker', () {
    test('fromStorage returns matching value', () {
      expect(MeetingSpeaker.fromStorage('me'), MeetingSpeaker.me);
      expect(MeetingSpeaker.fromStorage('them'), MeetingSpeaker.them);
    });

    test('fromStorage defaults to them for null', () {
      expect(MeetingSpeaker.fromStorage(null), MeetingSpeaker.them);
    });

    test('fromStorage defaults to them for unknown value', () {
      expect(MeetingSpeaker.fromStorage('unknown'), MeetingSpeaker.them);
    });

    test('toStorage returns name string', () {
      expect(MeetingSpeaker.me.toStorage(), 'me');
      expect(MeetingSpeaker.them.toStorage(), 'them');
    });
  });
}
