import 'package:cc_domain/core/domain/value_objects/feed_position.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_activity.dart';
import 'package:cc_domain/features/notifications/domain/entities/notification_feed_item.dart';
import 'package:cc_domain/features/notifications/domain/entities/notification_read_mark.dart';
import 'package:test/test.dart';

void main() {
  final second = DateTime.utc(2026, 3, 1, 12);

  group('FeedPosition', () {
    test('orders by time, then by sequence within a second', () {
      final first = FeedPosition(at: second, seq: 4);
      final sameSecondLater = FeedPosition(at: second, seq: 5);
      final nextSecond = FeedPosition(
        at: second.add(const Duration(seconds: 1)),
        seq: 1,
      );

      expect(sameSecondLater.isAfter(first), isTrue);
      expect(first.isAfter(sameSecondLater), isFalse);
      expect(first.isAfter(first), isFalse);
      expect(nextSecond.isAfter(sameSecondLater), isTrue);
    });

    test('round-trips its wire shape and rejects malformed input', () {
      final position = FeedPosition(at: second, seq: 9);
      expect(position.toJson(), {'at': '2026-03-01T12:00:00.000Z', 'seq': 9});
      expect(FeedPosition.fromJson(position.toJson()), position);

      expect(FeedPosition.fromJson(null), isNull);
      expect(FeedPosition.fromJson('2026-03-01'), isNull);
      expect(FeedPosition.fromJson({'at': 'nope', 'seq': 1}), isNull);
      expect(FeedPosition.fromJson({'at': '2026-03-01T12:00:00Z'}), isNull);
      expect(
        FeedPosition.fromJson({'at': '2026-03-01T12:00:00Z', 'seq': -1}),
        isNull,
      );
    });

    test('equality compares instants, not time zones', () {
      expect(
        FeedPosition(at: second, seq: 1),
        FeedPosition(at: second.toLocal(), seq: 1),
      );
      expect(() => FeedPosition(at: second, seq: -1), throwsArgumentError);
    });
  });

  group('NotificationReadMark', () {
    NotificationFeedItem item(int seq) => NotificationFeedItem(
      id: 'n$seq',
      workspaceId: 'ws',
      method: 'notifications/pr_merged',
      params: const {},
      createdAt: second,
      seq: seq,
    );

    test('an item later in the second of the mark is not covered', () {
      final mark = NotificationReadMark(
        workspaceId: 'ws',
        userId: 'u',
        lastSeen: FeedPosition(at: second, seq: 5),
        cleared: FeedPosition(at: second, seq: 3),
      );

      expect(mark.hasSeen(item(5)), isTrue);
      expect(mark.hasSeen(item(6)), isFalse);
      expect(mark.hides(item(3)), isTrue);
      expect(mark.hides(item(4)), isFalse);
    });

    test('no mark covers nothing', () {
      final mark = NotificationReadMark(workspaceId: 'ws', userId: 'u');
      expect(mark.hasSeen(item(1)), isFalse);
      expect(mark.hides(item(1)), isFalse);
    });
  });

  group('SpaceActivity', () {
    test('a conversation is unread past its own cursor, or with none', () {
      final activity = SpaceActivity(
        spaceId: 's',
        lastAgentMessageByConversation: {'c': FeedPosition(at: second, seq: 8)},
      );

      expect(
        activity.conversationUnread('c', FeedPosition(at: second, seq: 7)),
        isTrue,
      );
      expect(
        activity.conversationUnread('c', FeedPosition(at: second, seq: 8)),
        isFalse,
      );
      expect(activity.conversationUnread('c', null), isTrue);
      // No agent message there (or the conversation is archived): never.
      expect(activity.conversationUnread('other', null), isFalse);
    });

    test('a space is unread when any conversation is', () {
      final activity = SpaceActivity(
        spaceId: 's',
        lastAgentMessageByConversation: {
          'a': FeedPosition(at: second, seq: 3),
          'b': FeedPosition(at: second, seq: 8),
        },
      );

      // Reading one conversation leaves the other unread.
      expect(
        activity.unreadFor({'a': FeedPosition(at: second, seq: 3)}),
        isTrue,
      );
      expect(
        activity.unreadFor({
          'a': FeedPosition(at: second, seq: 3),
          'b': FeedPosition(at: second, seq: 8),
        }),
        isFalse,
      );
      expect(const SpaceActivity(spaceId: 's').unreadFor(const {}), isFalse);
    });

    test('round-trips its wire shape', () {
      final activity = SpaceActivity(
        spaceId: 's',
        lastMessageAt: second,
        lastAgentMessageByConversation: {'c': FeedPosition(at: second, seq: 8)},
        openQuestionCount: 2,
        conversationsNeedingInput: const {'c'},
      );
      final json = activity.toJson();
      expect(json['needs_input_conversations'], ['c']);
      expect(json['conversations'], [
        {
          'conversation_id': 'c',
          'last_agent_message': {'at': '2026-03-01T12:00:00.000Z', 'seq': 8},
        },
      ]);
      expect(SpaceActivity.fromJson(json), activity);
    });
  });
}
