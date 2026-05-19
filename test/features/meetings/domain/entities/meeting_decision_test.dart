import 'package:control_center/features/meetings/domain/entities/meeting_decision.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2025, 6, 1, 12, 0);

  group('MeetingDecision', () {
    // ---- construction ----

    test('creates with required fields', () {
      final decision = MeetingDecision(
        id: 'd1',
        meetingId: 'm1',
        workspaceId: 'ws1',
        content: 'Switch to Riverpod',
        createdAt: now,
      );
      expect(decision.id, 'd1');
      expect(decision.meetingId, 'm1');
      expect(decision.workspaceId, 'ws1');
      expect(decision.content, 'Switch to Riverpod');
      expect(decision.sortOrder, 0);
      expect(decision.createdAt, now);
    });

    test('creates with sortOrder override', () {
      final decision = MeetingDecision(
        id: 'd2',
        meetingId: 'm2',
        workspaceId: 'ws2',
        content: 'Decision',
        createdAt: now,
        sortOrder: 7,
      );
      expect(decision.sortOrder, 7);
    });

    test('asserts workspaceId is not empty', () {
      expect(
        () => MeetingDecision(
          id: 'd',
          meetingId: 'm',
          workspaceId: '',
          content: 'x',
          createdAt: now,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    // ---- equality ----

    test('equal decisions with same fields are equal', () {
      final a = MeetingDecision(
        id: 'd1',
        meetingId: 'm1',
        workspaceId: 'ws1',
        content: 'Go with plan A',
        createdAt: now,
      );
      final b = MeetingDecision(
        id: 'd1',
        meetingId: 'm1',
        workspaceId: 'ws1',
        content: 'Go with plan A',
        createdAt: now,
      );
      expect(a, equals(b));
    });

    test('different id means not equal', () {
      final a = MeetingDecision(
        id: 'd1',
        meetingId: 'm1',
        workspaceId: 'ws1',
        content: 'x',
        createdAt: now,
      );
      final b = MeetingDecision(
        id: 'd2',
        meetingId: 'm1',
        workspaceId: 'ws1',
        content: 'x',
        createdAt: now,
      );
      expect(a, isNot(equals(b)));
    });

    test('different content means not equal', () {
      final a = MeetingDecision(
        id: 'd1',
        meetingId: 'm1',
        workspaceId: 'ws1',
        content: 'x',
        createdAt: now,
      );
      final b = MeetingDecision(
        id: 'd1',
        meetingId: 'm1',
        workspaceId: 'ws1',
        content: 'y',
        createdAt: now,
      );
      expect(a, isNot(equals(b)));
    });

    test('different sortOrder means not equal', () {
      final a = MeetingDecision(
        id: 'd1',
        meetingId: 'm1',
        workspaceId: 'ws1',
        content: 'x',
        createdAt: now,
        sortOrder: 0,
      );
      final b = MeetingDecision(
        id: 'd1',
        meetingId: 'm1',
        workspaceId: 'ws1',
        content: 'x',
        createdAt: now,
        sortOrder: 1,
      );
      expect(a, isNot(equals(b)));
    });

    test('hashCode stable for equal decisions', () {
      final a = MeetingDecision(
        id: 'd1',
        meetingId: 'm1',
        workspaceId: 'ws1',
        content: 'x',
        createdAt: now,
      );
      final b = MeetingDecision(
        id: 'd1',
        meetingId: 'm1',
        workspaceId: 'ws1',
        content: 'x',
        createdAt: now,
      );
      expect(a.hashCode, equals(b.hashCode));
    });

    test('hashCode differs for different content', () {
      final a = MeetingDecision(
        id: 'd1',
        meetingId: 'm1',
        workspaceId: 'ws1',
        content: 'x',
        createdAt: now,
      );
      final b = MeetingDecision(
        id: 'd1',
        meetingId: 'm1',
        workspaceId: 'ws1',
        content: 'y',
        createdAt: now,
      );
      expect(a.hashCode, isNot(equals(b.hashCode)));
    });
  });
}
