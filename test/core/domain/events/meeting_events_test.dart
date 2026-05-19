import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/meeting_events.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MeetingRecordingStopped', () {
    test('constructs with all required fields', () {
      final now = DateTime(2026, 6, 10, 14, 30);
      final event = MeetingRecordingStopped(
        workspaceId: 'ws-abc',
        meetingId: 'meeting-42',
        title: 'Sprint Planning',
        userNotes: 'Discuss timeline',
        transcript: 'Alice: Hello\nBob: Hi Alice',
        occurredAt: now,
      );

      expect(event.workspaceId, 'ws-abc');
      expect(event.meetingId, 'meeting-42');
      expect(event.title, 'Sprint Planning');
      expect(event.userNotes, 'Discuss timeline');
      expect(event.transcript, 'Alice: Hello\nBob: Hi Alice');
      expect(event.occurredAt, now);
    });

    test('accepts empty strings for optional content fields', () {
      final event = MeetingRecordingStopped(
        workspaceId: 'ws-1',
        meetingId: 'm-1',
        title: '',
        userNotes: '',
        transcript: '',
        occurredAt: DateTime.now(),
      );

      expect(event.title, '');
      expect(event.userNotes, '');
      expect(event.transcript, '');
    });

    test('accepts multiline transcript', () {
      const transcript = 'Speaker A: First line\n'
          'Speaker B: Second line\n'
          'Speaker A: Third line\n'
          'Speaker C: Fourth line with special !@#\$%^';

      final event = MeetingRecordingStopped(
        workspaceId: 'ws-1',
        meetingId: 'm-1',
        title: 'Test',
        userNotes: '',
        transcript: transcript,
        occurredAt: DateTime.now(),
      );

      expect(event.transcript, transcript);
    });

    test('implements DomainEvent interface', () {
      final event = MeetingRecordingStopped(
        workspaceId: 'ws-1',
        meetingId: 'm-1',
        title: 'Test',
        userNotes: '',
        transcript: '',
        occurredAt: DateTime.now(),
      );

      expect(event, isA<DomainEvent>());
    });

    test('distinct events are independent', () {
      final a = MeetingRecordingStopped(
        workspaceId: 'ws-a',
        meetingId: 'ma',
        title: 'Title A',
        userNotes: 'Notes A',
        transcript: 'T A',
        occurredAt: DateTime(2026, 1, 1),
      );
      final b = MeetingRecordingStopped(
        workspaceId: 'ws-b',
        meetingId: 'mb',
        title: 'Title B',
        userNotes: 'Notes B',
        transcript: 'T B',
        occurredAt: DateTime(2026, 6, 10),
      );

      expect(a.workspaceId, isNot(b.workspaceId));
      expect(a.meetingId, isNot(b.meetingId));
      expect(a.occurredAt, isNot(b.occurredAt));
    });
  });
}
