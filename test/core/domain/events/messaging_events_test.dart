import 'package:control_center/core/domain/events/domain_event_bus.dart';
import 'package:control_center/core/domain/events/messaging_events.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MessageReceived',() {
    test('constructs with all fields', timeout: const Timeout.factor(2), () {
      final now = DateTime(2026, 5, 18);
      final event = MessageReceived(
        channelId: 'ch-1',
        messageId: 'msg-1',
        senderName: 'Agent Smith',
        contentPreview: 'Hello world...',
        isAgentMessage: true,
        workspaceId: 'ws-1',
        occurredAt: now,
      );

      expect(event.channelId, 'ch-1');
      expect(event.messageId, 'msg-1');
      expect(event.senderName, 'Agent Smith');
      expect(event.contentPreview, 'Hello world...');
      expect(event.isAgentMessage, isTrue);
      expect(event.workspaceId, 'ws-1');
      expect(event.occurredAt, now);
    });

    test('supports nullable workspaceId', timeout: const Timeout.factor(2), () {
      final event = MessageReceived(
        channelId: 'ch-1',
        messageId: 'msg-1',
        senderName: 'User',
        contentPreview: 'Hi',
        isAgentMessage: false,
        workspaceId: null,
        occurredAt: DateTime.now(),
      );

      expect(event.workspaceId, isNull);
    });

    test('isAgentMessage false for user messages', timeout: const Timeout.factor(2), () {
      final event = MessageReceived(
        channelId: 'ch-1',
        messageId: 'msg-1',
        senderName: 'User',
        contentPreview: 'Hi',
        isAgentMessage: false,
        workspaceId: null,
        occurredAt: DateTime.now(),
      );

      expect(event.isAgentMessage, isFalse);
    });

    test('is a DomainEvent', timeout: const Timeout.factor(2), () {
      final event = MessageReceived(
        channelId: 'ch-1',
        messageId: 'msg-1',
        senderName: 'A',
        contentPreview: '',
        isAgentMessage: true,
        workspaceId: null,
        occurredAt: DateTime.now(),
      );

      expect(event, isA<DomainEvent>());
    });

    test('type filtering on bus', timeout: const Timeout.factor(2), () async {
      final bus = DomainEventBus();
      addTearDown(bus.dispose);

      final received = <MessageReceived>[];
      bus.on<MessageReceived>().listen(received.add);

      bus.publish(
        MessageReceived(
          channelId: 'ch-1',
          messageId: 'msg-1',
          senderName: 'Bot',
          contentPreview: 'Done',
          isAgentMessage: true,
          workspaceId: 'ws-1',
          occurredAt: DateTime.now(),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 10));
      expect(received, hasLength(1));
      expect(received.first.channelId, 'ch-1');
    });
  });

  group('ConversationDeleted',() {
    test('constructs with all fields', timeout: const Timeout.factor(2), () {
      final now = DateTime(2026, 5, 18);
      final event = ConversationDeleted(
        channelId: 'ch-1',
        workspaceId: 'ws-1',
        occurredAt: now,
      );

      expect(event.channelId, 'ch-1');
      expect(event.workspaceId, 'ws-1');
      expect(event.occurredAt, now);
    });

    test('supports nullable workspaceId', timeout: const Timeout.factor(2), () {
      final event = ConversationDeleted(
        channelId: 'ch-1',
        workspaceId: null,
        occurredAt: DateTime.now(),
      );

      expect(event.workspaceId, isNull);
    });

    test('is a DomainEvent', timeout: const Timeout.factor(2), () {
      final event = ConversationDeleted(
        channelId: 'ch-1',
        occurredAt: DateTime.now(),
      );

      expect(event, isA<DomainEvent>());
    });

    test('type filtering on bus', timeout: const Timeout.factor(2), () async {
      final bus = DomainEventBus();
      addTearDown(bus.dispose);

      final received = <ConversationDeleted>[];
      bus.on<ConversationDeleted>().listen(received.add);

      bus.publish(
        ConversationDeleted(
          channelId: 'ch-1',
          workspaceId: null,
          occurredAt: DateTime.now(),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 10));
      expect(received, hasLength(1));
      expect(received.first.channelId, 'ch-1');
    });
  });
}
