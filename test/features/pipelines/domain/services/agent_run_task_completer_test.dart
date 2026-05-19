import 'dart:async';

import 'package:control_center/core/domain/entities/channel_message.dart';
import 'package:control_center/core/domain/events/agent_events.dart';
import 'package:control_center/core/domain/events/domain_event_bus.dart';
import 'package:control_center/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:control_center/features/pipelines/domain/ports/ticket_workflow_port.dart';
import 'package:control_center/features/pipelines/domain/services/agent_run_task_completer.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_status.dart';
import 'package:control_center/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Fakes ────────────────────────────────────────────────────────────────────

class _FakeEventBus implements DomainEventBus {
  final _controller = StreamController<DomainEvent>.broadcast();
  final List<Type> subscribedTypes = [];

  @override
  void publish(DomainEvent event) => _controller.add(event);

  @override
  Stream<T> on<T extends DomainEvent>() {
    if (!subscribedTypes.contains(T)) {
      subscribedTypes.add(T);
    }
    return _controller.stream.where((e) => e is T).cast<T>();
  }

  @override
  void dispose() => _controller.close();
}

class _FakeTicketRepository implements TicketRepository {
  List<Ticket> forAgentResult = const [];
  int forAgentCallCount = 0;
  Object? forAgentThrow;

  @override
  Future<List<Ticket>> forAgent(String workspaceId, String agentId) async {
    forAgentCallCount++;
    if (forAgentThrow != null) {
      throw forAgentThrow!;
    }
    return forAgentResult;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTicketWorkflow implements TicketWorkflowPort {
  final List<_CompleteTicketCall> completeTicketCalls = [];
  Object? completeTicketThrow;
  bool throwOnlyFirst = false;
  int _callCount = 0;

  @override
  Future<void> completeTicket(
    String ticketId, {
    required String workspaceId,
    Map<String, dynamic>? output,
    bool force = false,
  }) async {
    _callCount++;
    completeTicketCalls.add(_CompleteTicketCall(
      ticketId: ticketId,
      workspaceId: workspaceId,
      output: output,
      force: force,
    ));
    if (completeTicketThrow != null &&
        (!throwOnlyFirst || _callCount == 1)) {
      throw completeTicketThrow!;
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _CompleteTicketCall {
  _CompleteTicketCall({
    required this.ticketId,
    required this.workspaceId,
    this.output,
    this.force = false,
  });

  final String ticketId;
  final String workspaceId;
  final Map<String, dynamic>? output;
  final bool force;
}

class _FakeMessagingRepository implements MessagingRepository {
  List<ChannelMessage> getMessagesResult = const [];
  int getMessagesCallCount = 0;

  @override
  Future<List<ChannelMessage>> getMessages(String channelId) async {
    getMessagesCallCount++;
    return getMessagesResult;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ThrowingGetMessages extends _FakeMessagingRepository {
  @override
  Future<List<ChannelMessage>> getMessages(String channelId) async {
    throw Exception('messaging down');
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

Ticket _makeTicket({
  String id = 'ticket-1',
  String workspaceId = 'ws-1',
  String? channelId = 'ch-1',
  String? pipelineRunId = 'run-1',
  String? pipelineStepId = 'step-1',
  TicketStatus status = TicketStatus.inProgress,
}) {
  final now = DateTime(2025, 1, 1);
  return Ticket(
    id: id,
    workspaceId: workspaceId,
    title: 'Test $id',
    status: status,
    channelId: channelId,
    pipelineRunId: pipelineRunId,
    pipelineStepId: pipelineStepId,
    createdAt: now,
    updatedAt: now,
  );
}

AgentRunCompleted _makeEvent({
  String agentId = 'agent-1',
  String? workspaceId = 'ws-1',
  String? conversationId = 'ch-1',
}) =>
    AgentRunCompleted(
      agentId: agentId,
      workspaceId: workspaceId,
      conversationId: conversationId,
      occurredAt: DateTime(2025, 1, 1),
    );

ChannelMessage _makeMessage({
  String id = 'msg-1',
  String channelId = 'ch-1',
  String senderId = 'agent-1',
  ChannelSenderType senderType = ChannelSenderType.agent,
  String content = 'task output',
  DateTime? createdAt,
}) =>
    ChannelMessage(
      id: id,
      channelId: channelId,
      senderId: senderId,
      senderType: senderType,
      content: content,
      messageType: ChannelMessageType.text,
      createdAt: createdAt ?? DateTime(2025, 1, 1),
    );

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  late _FakeEventBus eventBus;
  late _FakeTicketRepository ticketRepo;
  late _FakeTicketWorkflow ticketWorkflow;
  late _FakeMessagingRepository messagingRepo;
  late AgentRunTaskCompleter completer;

  setUp(() {
    eventBus = _FakeEventBus();
    ticketRepo = _FakeTicketRepository();
    ticketWorkflow = _FakeTicketWorkflow();
    messagingRepo = _FakeMessagingRepository();
    completer = AgentRunTaskCompleter(
      eventBus: eventBus,
      ticketRepository: ticketRepo,
      ticketWorkflow: ticketWorkflow,
      messagingRepository: messagingRepo,
    );
    completer.start();
  });

  tearDown(() {
    completer.dispose();
  });

  group('start / dispose', () {
    test('start subscribes to AgentRunCompleted events', () {
      expect(eventBus.subscribedTypes, contains(AgentRunCompleted));
    });

    test('dispose stops listening', () async {
      completer.dispose();
      ticketRepo.forAgentResult = [_makeTicket()];
      eventBus.publish(_makeEvent());
      await pumpEventQueue();
      expect(ticketRepo.forAgentCallCount, 0);
    });
  });

  group('_onCompleted — early exits', () {
    test('no workspaceId → returns without querying tickets', () async {
      eventBus.publish(_makeEvent(workspaceId: null));
      await pumpEventQueue();
      expect(ticketRepo.forAgentCallCount, 0);
    });

    test('forAgent returns empty → no completion', () async {
      ticketRepo.forAgentResult = [];
      eventBus.publish(_makeEvent());
      await pumpEventQueue();
      expect(ticketRepo.forAgentCallCount, 1);
      expect(ticketWorkflow.completeTicketCalls, isEmpty);
    });

    test('all tickets terminal → filtered out', () async {
      ticketRepo.forAgentResult = [
        _makeTicket(id: 't1', status: TicketStatus.done),
        _makeTicket(id: 't2', status: TicketStatus.failed),
        _makeTicket(id: 't3', status: TicketStatus.cancelled),
      ];
      eventBus.publish(_makeEvent());
      await pumpEventQueue();
      expect(ticketWorkflow.completeTicketCalls, isEmpty);
    });

    test('tickets missing pipelineRunId → filtered out', () async {
      ticketRepo.forAgentResult = [
        _makeTicket(id: 't1', pipelineRunId: null),
      ];
      eventBus.publish(_makeEvent());
      await pumpEventQueue();
      expect(ticketWorkflow.completeTicketCalls, isEmpty);
    });

    test('tickets missing pipelineStepId → filtered out', () async {
      ticketRepo.forAgentResult = [
        _makeTicket(id: 't1', pipelineStepId: null),
      ];
      eventBus.publish(_makeEvent());
      await pumpEventQueue();
      expect(ticketWorkflow.completeTicketCalls, isEmpty);
    });

    test('conversationId present but ticket channelId differs → filtered out',
        () async {
      ticketRepo.forAgentResult = [
        _makeTicket(id: 't1', channelId: 'other-ch'),
      ];
      eventBus.publish(_makeEvent(conversationId: 'ch-1'));
      await pumpEventQueue();
      expect(ticketWorkflow.completeTicketCalls, isEmpty);
    });

    test('conversationId null → channelId mismatch filter not applied',
        () async {
      ticketRepo.forAgentResult = [
        _makeTicket(id: 't1', channelId: 'any-channel'),
      ];
      eventBus.publish(_makeEvent(conversationId: null));
      await pumpEventQueue();
      expect(ticketWorkflow.completeTicketCalls.length, 1);
    });
  });

  group('_onCompleted — successful completion', () {
    test('completes ticket with harvested agent message as output', () async {
      final ticket = _makeTicket(id: 't1');
      ticketRepo.forAgentResult = [ticket];
      messagingRepo.getMessagesResult = [
        _makeMessage(
          id: 'msg-1',
          senderId: 'agent-1',
          senderType: ChannelSenderType.agent,
          content: 'Task done!',
          createdAt: DateTime(2025, 1, 1, 12, 0),
        ),
      ];

      eventBus.publish(_makeEvent());
      await pumpEventQueue();

      expect(ticketWorkflow.completeTicketCalls.length, 1);
      final call = ticketWorkflow.completeTicketCalls.first;
      expect(call.ticketId, 't1');
      expect(call.workspaceId, 'ws-1');
      expect(call.output, {'result': 'Task done!'});
    });

    test('uses empty string when no conversationId', () async {
      final ticket = _makeTicket(id: 't1', channelId: 'any');
      ticketRepo.forAgentResult = [ticket];

      eventBus.publish(_makeEvent(conversationId: null));
      await pumpEventQueue();

      expect(ticketWorkflow.completeTicketCalls.length, 1);
      final call = ticketWorkflow.completeTicketCalls.first;
      expect(call.output, {'result': ''});
      expect(messagingRepo.getMessagesCallCount, 0);
    });

    test('uses empty string when _latestAgentMessage returns null', () async {
      final ticket = _makeTicket(id: 't1');
      ticketRepo.forAgentResult = [ticket];
      messagingRepo.getMessagesResult = [];

      eventBus.publish(_makeEvent());
      await pumpEventQueue();

      expect(ticketWorkflow.completeTicketCalls.length, 1);
      final call = ticketWorkflow.completeTicketCalls.first;
      expect(call.output, {'result': ''});
    });

    test('completes multiple matching candidates', () async {
      ticketRepo.forAgentResult = [
        _makeTicket(id: 't1', channelId: 'ch-1'),
        _makeTicket(id: 't2', channelId: 'ch-1'),
        _makeTicket(id: 't3', channelId: 'ch-1'),
      ];
      messagingRepo.getMessagesResult = [
        _makeMessage(content: 'output'),
      ];

      eventBus.publish(_makeEvent());
      await pumpEventQueue();

      expect(ticketWorkflow.completeTicketCalls.length, 3);
      expect(
        ticketWorkflow.completeTicketCalls.map((c) => c.ticketId),
        ['t1', 't2', 't3'],
      );
    });

    test(
        'each completed ticket uses ticket.workspaceId, not event.workspaceId',
        () async {
      ticketRepo.forAgentResult = [
        _makeTicket(id: 't1', workspaceId: 'ws-ticket'),
      ];
      messagingRepo.getMessagesResult = [
        _makeMessage(content: 'ok'),
      ];

      eventBus.publish(_makeEvent(workspaceId: 'ws-event'));
      await pumpEventQueue();

      final call = ticketWorkflow.completeTicketCalls.first;
      expect(call.workspaceId, 'ws-ticket');
    });
  });

  group('_latestAgentMessage', () {
    test('returns most recent agent message content', () async {
      messagingRepo.getMessagesResult = [
        _makeMessage(
          id: 'older',
          senderId: 'agent-1',
          senderType: ChannelSenderType.agent,
          content: 'older message',
          createdAt: DateTime(2025, 1, 1, 10, 0),
        ),
        _makeMessage(
          id: 'newer',
          senderId: 'agent-1',
          senderType: ChannelSenderType.agent,
          content: 'newest message',
          createdAt: DateTime(2025, 1, 1, 12, 0),
        ),
      ];
      ticketRepo.forAgentResult = [_makeTicket()];

      eventBus.publish(_makeEvent());
      await pumpEventQueue();

      final call = ticketWorkflow.completeTicketCalls.first;
      expect(call.output, {'result': 'newest message'});
    });

    test('skips messages from other senders', () async {
      messagingRepo.getMessagesResult = [
        _makeMessage(
          id: 'other-agent',
          senderId: 'agent-2',
          senderType: ChannelSenderType.agent,
          content: 'not mine',
          createdAt: DateTime(2025, 1, 1, 12, 0),
        ),
        _makeMessage(
          id: 'mine',
          senderId: 'agent-1',
          senderType: ChannelSenderType.agent,
          content: 'my message',
          createdAt: DateTime(2025, 1, 1, 10, 0),
        ),
      ];
      ticketRepo.forAgentResult = [_makeTicket()];

      eventBus.publish(_makeEvent());
      await pumpEventQueue();

      final call = ticketWorkflow.completeTicketCalls.first;
      expect(call.output, {'result': 'my message'});
    });

    test('skips user messages even when senderId matches', () async {
      messagingRepo.getMessagesResult = [
        _makeMessage(
          id: 'user-msg',
          senderId: 'agent-1',
          senderType: ChannelSenderType.user,
          content: 'human message',
          createdAt: DateTime(2025, 1, 1, 12, 0),
        ),
      ];
      ticketRepo.forAgentResult = [_makeTicket()];

      eventBus.publish(_makeEvent());
      await pumpEventQueue();

      final call = ticketWorkflow.completeTicketCalls.first;
      expect(call.output, {'result': ''});
    });

    test('returns null when no messages exist', () async {
      messagingRepo.getMessagesResult = [];
      ticketRepo.forAgentResult = [_makeTicket()];

      eventBus.publish(_makeEvent());
      await pumpEventQueue();

      final call = ticketWorkflow.completeTicketCalls.first;
      expect(call.output, {'result': ''});
    });
  });

  group('_onCompleted — error handling', () {
    test('forAgent throws → caught, no crash, no completion', () async {
      ticketRepo.forAgentThrow = Exception('DB down');
      eventBus.publish(_makeEvent());
      await pumpEventQueue();
      expect(ticketWorkflow.completeTicketCalls, isEmpty);
    });

    test('completeTicket throws for one ticket → loop aborted by outer catch',
        () async {
      ticketRepo.forAgentResult = [
        _makeTicket(id: 't1'),
        _makeTicket(id: 't2'),
        _makeTicket(id: 't3'),
      ];
      messagingRepo.getMessagesResult = [
        _makeMessage(content: 'ok'),
      ];
      ticketWorkflow.completeTicketThrow = Exception('boom');
      ticketWorkflow.throwOnlyFirst = true;

      eventBus.publish(_makeEvent());
      await pumpEventQueue();

      // The for loop is inside the single try/catch, so the throw from t1
      // is caught by the outer handler and t2/t3 are never reached.
      expect(ticketWorkflow.completeTicketCalls.length, 1);
    });

    test(
        'error during message harvesting → caught, completeTicket never reached',
        () async {
      // Dispose the default completer so only the throwing one listens.
      completer.dispose();

      final throwingMsgs = _ThrowingGetMessages();
      final altCompleter = AgentRunTaskCompleter(
        eventBus: eventBus,
        ticketRepository: ticketRepo,
        ticketWorkflow: ticketWorkflow,
        messagingRepository: throwingMsgs,
      );
      altCompleter.start();
      addTearDown(altCompleter.dispose);

      ticketRepo.forAgentResult = [_makeTicket()];

      eventBus.publish(_makeEvent());
      await pumpEventQueue();

      expect(ticketWorkflow.completeTicketCalls, isEmpty);
    });
  });
}
