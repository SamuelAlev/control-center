import 'package:cc_domain/core/domain/notifications/notification_category.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppNotification constructor', () {
    test('fields stored correctly, defaults are null', () {
      const notification = AppNotification(
        category: NotificationCategory.agentRunCompleted,
        title: 'Run Completed',
        body: 'Agent finished running',
        route: '/workspace/ws-1',
        workspaceId: 'ws-1',
      );

      expect(notification.category, NotificationCategory.agentRunCompleted);
      expect(notification.title, 'Run Completed');
      expect(notification.body, 'Agent finished running');
      expect(notification.route, '/workspace/ws-1');
      expect(notification.workspaceId, 'ws-1');
      expect(notification.channelId, isNull);
    });
  });

  group('AppNotification ==', () {
    test('identical same instance', () {
      const notification = AppNotification(
        category: NotificationCategory.agentRunCompleted,
        title: 'Run Completed',
        body: 'Agent finished running',
        route: '/workspace/ws-1',
        workspaceId: 'ws-1',
      );

      expect(notification == notification, isTrue);
    });

    test('equal with same fields', () {
      const a = AppNotification(
        category: NotificationCategory.agentRunCompleted,
        title: 'Run Completed',
        body: 'Agent finished running',
        route: '/workspace/ws-1',
        workspaceId: 'ws-1',
      );
      const b = AppNotification(
        category: NotificationCategory.agentRunCompleted,
        title: 'Run Completed',
        body: 'Agent finished running',
        route: '/workspace/ws-1',
        workspaceId: 'ws-1',
      );

      expect(a, equals(b));
    });

    test('not equal when category differs', () {
      const a = AppNotification(
        category: NotificationCategory.agentRunCompleted,
        title: 'Run Completed',
        body: 'Agent finished running',
        route: '/workspace/ws-1',
        workspaceId: 'ws-1',
      );
      const b = AppNotification(
        category: NotificationCategory.prMerged,
        title: 'Run Completed',
        body: 'Agent finished running',
        route: '/workspace/ws-1',
        workspaceId: 'ws-1',
      );

      expect(a, isNot(equals(b)));
    });

    test('not equal when title differs', () {
      const a = AppNotification(
        category: NotificationCategory.agentRunCompleted,
        title: 'Run Completed',
        body: 'Agent finished running',
        route: '/workspace/ws-1',
        workspaceId: 'ws-1',
      );
      const b = AppNotification(
        category: NotificationCategory.agentRunCompleted,
        title: 'Different Title',
        body: 'Agent finished running',
        route: '/workspace/ws-1',
        workspaceId: 'ws-1',
      );

      expect(a, isNot(equals(b)));
    });

    test('not equal when body differs', () {
      const a = AppNotification(
        category: NotificationCategory.agentRunCompleted,
        title: 'Run Completed',
        body: 'Agent finished running',
        route: '/workspace/ws-1',
        workspaceId: 'ws-1',
      );
      const b = AppNotification(
        category: NotificationCategory.agentRunCompleted,
        title: 'Run Completed',
        body: 'Different body',
        route: '/workspace/ws-1',
        workspaceId: 'ws-1',
      );

      expect(a, isNot(equals(b)));
    });

    test('not equal when route differs', () {
      const a = AppNotification(
        category: NotificationCategory.agentRunCompleted,
        title: 'Run Completed',
        body: 'Agent finished running',
        route: '/workspace/ws-1',
        workspaceId: 'ws-1',
      );
      const b = AppNotification(
        category: NotificationCategory.agentRunCompleted,
        title: 'Run Completed',
        body: 'Agent finished running',
        route: '/different-route',
        workspaceId: 'ws-1',
      );

      expect(a, isNot(equals(b)));
    });

    test('not equal when workspaceId differs', () {
      const a = AppNotification(
        category: NotificationCategory.agentRunCompleted,
        title: 'Run Completed',
        body: 'Agent finished running',
        route: '/workspace/ws-1',
        workspaceId: 'ws-1',
      );
      const b = AppNotification(
        category: NotificationCategory.agentRunCompleted,
        title: 'Run Completed',
        body: 'Agent finished running',
        route: '/workspace/ws-1',
        workspaceId: 'ws-2',
      );

      expect(a, isNot(equals(b)));
    });

    test('not equal when channelId differs', () {
      const a = AppNotification(
        category: NotificationCategory.agentRunCompleted,
        title: 'Run Completed',
        body: 'Agent finished running',
        route: '/workspace/ws-1',
        workspaceId: 'ws-1',
        channelId: 'ch-1',
      );
      const b = AppNotification(
        category: NotificationCategory.agentRunCompleted,
        title: 'Run Completed',
        body: 'Agent finished running',
        route: '/workspace/ws-1',
        workspaceId: 'ws-1',
        channelId: 'ch-2',
      );

      expect(a, isNot(equals(b)));
    });
  });

  group('AppNotification hashCode', () {
    test('same fields produce same hashCode', () {
      const a = AppNotification(
        category: NotificationCategory.agentRunCompleted,
        title: 'Run Completed',
        body: 'Agent finished running',
        route: '/workspace/ws-1',
        workspaceId: 'ws-1',
      );
      const b = AppNotification(
        category: NotificationCategory.agentRunCompleted,
        title: 'Run Completed',
        body: 'Agent finished running',
        route: '/workspace/ws-1',
        workspaceId: 'ws-1',
      );

      expect(a.hashCode, equals(b.hashCode));
    });

    test('different field produces different hashCode', () {
      const a = AppNotification(
        category: NotificationCategory.agentRunCompleted,
        title: 'Run Completed',
        body: 'Agent finished running',
        route: '/workspace/ws-1',
        workspaceId: 'ws-1',
      );
      const b = AppNotification(
        category: NotificationCategory.prMerged,
        title: 'Run Completed',
        body: 'Agent finished running',
        route: '/workspace/ws-1',
        workspaceId: 'ws-1',
      );

      expect(a.hashCode, isNot(equals(b.hashCode)));
    });
  });

  group('Null workspaceId and channelId', () {
    test('equality works when both are null', () {
      const a = AppNotification(
        category: NotificationCategory.newMessage,
        title: 'New Message',
        body: 'You have a new message',
        route: '/messages',
        workspaceId: null,
      );
      const b = AppNotification(
        category: NotificationCategory.newMessage,
        title: 'New Message',
        body: 'You have a new message',
        route: '/messages',
        workspaceId: null,
      );

      expect(a, equals(b));
    });

    test('not equal when workspaceId is null in one but not the other', () {
      const a = AppNotification(
        category: NotificationCategory.newMessage,
        title: 'New Message',
        body: 'You have a new message',
        route: '/messages',
        workspaceId: null,
      );
      const b = AppNotification(
        category: NotificationCategory.newMessage,
        title: 'New Message',
        body: 'You have a new message',
        route: '/messages',
        workspaceId: 'ws-1',
      );

      expect(a, isNot(equals(b)));
    });

    test('not equal when channelId is null in one but not the other', () {
      const a = AppNotification(
        category: NotificationCategory.newMessage,
        title: 'New Message',
        body: 'You have a new message',
        route: '/messages',
        workspaceId: null,
        channelId: null,
      );
      const b = AppNotification(
        category: NotificationCategory.newMessage,
        title: 'New Message',
        body: 'You have a new message',
        route: '/messages',
        workspaceId: null,
        channelId: 'ch-1',
      );

      expect(a, isNot(equals(b)));
    });
  });
}
