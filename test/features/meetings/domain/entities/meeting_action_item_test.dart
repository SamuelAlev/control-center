import 'package:cc_domain/features/meetings/domain/entities/meeting_action_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2025, 6, 1, 12, 0);

  group('MeetingActionItem', () {
    test('creates with required fields', () {
      final item = MeetingActionItem(
        id: 'ai1',
        meetingId: 'm1',
        workspaceId: 'ws1',
        content: 'Follow up with design',
        createdAt: now,
      );
      expect(item.id, 'ai1');
      expect(item.meetingId, 'm1');
      expect(item.workspaceId, 'ws1');
      expect(item.content, 'Follow up with design');
      expect(item.owner, isNull);
      expect(item.done, isFalse);
      expect(item.ticketId, isNull);
      expect(item.sortOrder, 0);
      expect(item.isManual, isFalse);
      expect(item.createdAt, now);
    });

    test('creates with all optional fields', () {
      final item = MeetingActionItem(
        id: 'ai2',
        meetingId: 'm2',
        workspaceId: 'ws2',
        content: 'Write tests',
        createdAt: now,
        owner: 'Alice',
        done: true,
        ticketId: 'tck-1',
        sortOrder: 3,
      );
      expect(item.owner, 'Alice');
      expect(item.done, isTrue);
      expect(item.ticketId, 'tck-1');
      expect(item.sortOrder, 3);
    });

    test('asserts workspaceId is not empty', () {
      expect(
        () => MeetingActionItem(
          id: 'ai',
          meetingId: 'm',
          workspaceId: '',
          content: 'x',
          createdAt: now,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('equal items with same fields are equal', () {
      final a = MeetingActionItem(
        id: 'ai1', meetingId: 'm1', workspaceId: 'ws1',
        content: 'Do the thing', createdAt: now,
      );
      final b = MeetingActionItem(
        id: 'ai1', meetingId: 'm1', workspaceId: 'ws1',
        content: 'Do the thing', createdAt: now,
      );
      expect(a, equals(b));
    });

    test('different id means not equal', () {
      final a = MeetingActionItem(
        id: 'ai1', meetingId: 'm1', workspaceId: 'ws1',
        content: 'x', createdAt: now,
      );
      final b = MeetingActionItem(
        id: 'ai2', meetingId: 'm1', workspaceId: 'ws1',
        content: 'x', createdAt: now,
      );
      expect(a, isNot(equals(b)));
    });

    test('different content means not equal', () {
      final a = MeetingActionItem(
        id: 'ai1', meetingId: 'm1', workspaceId: 'ws1',
        content: 'x', createdAt: now,
      );
      final b = MeetingActionItem(
        id: 'ai1', meetingId: 'm1', workspaceId: 'ws1',
        content: 'y', createdAt: now,
      );
      expect(a, isNot(equals(b)));
    });

    test('hashCode stable for equal items', () {
      final a = MeetingActionItem(
        id: 'ai1', meetingId: 'm1', workspaceId: 'ws1',
        content: 'x', createdAt: now,
      );
      final b = MeetingActionItem(
        id: 'ai1', meetingId: 'm1', workspaceId: 'ws1',
        content: 'x', createdAt: now,
      );
      expect(a.hashCode, equals(b.hashCode));
    });

    test('copyWith without args returns equal item', () {
      final item = MeetingActionItem(
        id: 'ai1', meetingId: 'm1', workspaceId: 'ws1',
        content: 'Hello', createdAt: now,
        owner: 'Bob', done: true, ticketId: 't-1', sortOrder: 5,
      );
      final copy = item.copyWith();
      expect(copy, equals(item));
    });

    test('copyWith overrides content', () {
      final item = MeetingActionItem(
        id: 'ai1', meetingId: 'm1', workspaceId: 'ws1',
        content: 'Old', createdAt: now,
      );
      final copy = item.copyWith(content: 'New');
      expect(copy.content, 'New');
      expect(copy.id, item.id);
    });

    test('copyWith overrides owner', () {
      final item = MeetingActionItem(
        id: 'ai1', meetingId: 'm1', workspaceId: 'ws1',
        content: 'x', createdAt: now, owner: 'Alice',
      );
      final copy = item.copyWith(owner: 'Bob');
      expect(copy.owner, 'Bob');
    });

    test('copyWith overrides done', () {
      final item = MeetingActionItem(
        id: 'ai1', meetingId: 'm1', workspaceId: 'ws1',
        content: 'x', createdAt: now, done: false,
      );
      final copy = item.copyWith(done: true);
      expect(copy.done, isTrue);
    });

    test('copyWith overrides ticketId', () {
      final item = MeetingActionItem(
        id: 'ai1', meetingId: 'm1', workspaceId: 'ws1',
        content: 'x', createdAt: now,
      );
      final copy = item.copyWith(ticketId: 'tk-42');
      expect(copy.ticketId, 'tk-42');
    });

    test('copyWith overrides sortOrder', () {
      final item = MeetingActionItem(
        id: 'ai1', meetingId: 'm1', workspaceId: 'ws1',
        content: 'x', createdAt: now, sortOrder: 1,
      );
      final copy = item.copyWith(sortOrder: 99);
      expect(copy.sortOrder, 99);
    });

    test('copyWith overrides isManual', () {
      final item = MeetingActionItem(
        id: 'ai1', meetingId: 'm1', workspaceId: 'ws1',
        content: 'x', createdAt: now,
      );
      final copy = item.copyWith(isManual: true);
      expect(copy.isManual, isTrue);
    });

    test('different isManual means not equal', () {
      final a = MeetingActionItem(
        id: 'ai1', meetingId: 'm1', workspaceId: 'ws1',
        content: 'x', createdAt: now,
      );
      final b = a.copyWith(isManual: true);
      expect(a, isNot(equals(b)));
    });

    test('copyWith uses ?? semantics: null keeps existing', () {
      final item = MeetingActionItem(
        id: 'ai1', meetingId: 'm1', workspaceId: 'ws1',
        content: 'x', createdAt: now,
        owner: 'Original', ticketId: 'tk-1',
      );
      final copy = item.copyWith(owner: null, ticketId: null);
      expect(copy.owner, 'Original');
      expect(copy.ticketId, 'tk-1');
    });
  });

  group('MeetingActionItemStats', () {
    test('typedef compiles and holds total and done', () {
      const stats = (total: 10, done: 3);
      expect(stats.total, 10);
      expect(stats.done, 3);
    });

    test('zero/zero stats', () {
      const stats = (total: 0, done: 0);
      expect(stats.total, 0);
      expect(stats.done, 0);
    });
  });
}
