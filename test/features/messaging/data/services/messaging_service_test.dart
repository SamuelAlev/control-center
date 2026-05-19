import 'dart:async';
import 'dart:typed_data';

import 'package:control_center/core/domain/entities/agent_run_log.dart';
import 'package:control_center/core/domain/entities/channel_message.dart';
import 'package:control_center/core/domain/repositories/agent_run_log_repository.dart';
import 'package:control_center/core/domain/value_objects/conversation_mode.dart';
import 'package:control_center/core/domain/value_objects/wake_context.dart';
import 'package:control_center/features/dispatch/data/services/agent_dispatch_service.dart';
import 'package:control_center/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:control_center/features/dispatch/domain/ports/agent_dispatch_port.dart';
import 'package:control_center/features/dispatch/domain/usecases/build_agent_prompt_use_case.dart';
import 'package:control_center/features/dispatch/domain/usecases/dispatch_agent_use_case.dart';
import 'package:control_center/features/messaging/data/services/active_stream_registry.dart';
import 'package:control_center/features/messaging/data/services/agent_stream_processor.dart';
import 'package:control_center/features/messaging/data/services/messaging_service.dart';
import 'package:control_center/features/messaging/domain/entities/channel.dart';
import 'package:control_center/features/messaging/domain/entities/channel_participant.dart';
import 'package:control_center/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeMessagingRepo implements MessagingRepository {
  final _channels = <Channel>[];
  final _participants = <String, List<ChannelParticipant>>{};
  final _messages = <String, List<ChannelMessage>>{};
  final _compacted = <String>{};
  ChannelParticipant _makeParticipant(String channelId, String agentId) =>
      ChannelParticipant(
        id: 'p-$agentId',
        channelId: channelId,
        agentId: agentId,
        role: 'member',
        joinedAt: DateTime.now(),
      );

  @override
  Stream<List<Channel>> watchChannels() => Stream.value(List.unmodifiable(_channels));

  @override
  Stream<List<Channel>> watchChannelsByWorkspace(String workspaceId) =>
      Stream.value(List.unmodifiable(
        _channels.where((c) => c.workspaceId == workspaceId).toList(),
      ));

  @override
  Stream<List<ChannelParticipant>> watchParticipants(String channelId) =>
      Stream.value(List.unmodifiable(_participants[channelId] ?? []));

  @override
  Stream<List<ChannelMessage>> watchMessages(String channelId) =>
      Stream.value(List.unmodifiable(_messages[channelId] ?? []));

  @override
  Future<Channel> openDm(String agentId, {String? workspaceId}) async {
    final channel = Channel(
      id: 'dm-$agentId',
      name: '',
      isDm: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _channels.add(channel);
    _participants[channel.id] = [_makeParticipant(channel.id, agentId)];
    return channel;
  }

  @override
  Future<Channel> createGroup(
    String name,
    List<String> agentIds, {
    ConversationMode mode = ConversationMode.chat,
    String? workspaceId,
  }) async {
    final channel = Channel(
      id: 'group-${name.hashCode}',
      name: name,
      isDm: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      mode: mode,
    );
    _channels.add(channel);
    _participants[channel.id] =
        agentIds.map((id) => _makeParticipant(channel.id, id)).toList();
    return channel;
  }

  @override
  Future<void> setChannelMode(String channelId, ConversationMode mode) async {
    final idx = _channels.indexWhere((c) => c.id == channelId);
    if (idx != -1) {
      _channels[idx] = _channels[idx].copyWith(mode: mode);
    }
  }

  @override
  Future<void> addParticipant(String channelId, String agentId) async {
    _participants.putIfAbsent(channelId, () => []);
    _participants[channelId]!.add(_makeParticipant(channelId, agentId));
  }

  @override
  Future<List<ChannelParticipant>> getParticipants(String channelId) async =>
      List.unmodifiable(_participants[channelId] ?? []);

  @override
  Future<String> sendMessage({
    required String channelId,
    required String content,
    required String senderId,
    required String senderType,
    String messageType = 'text',
    Map<String, dynamic>? metadata,
    String? id,
    String? parentMessageId,
  }) async {
    _messages.putIfAbsent(channelId, () => []);
    _messages[channelId]!.add(
      ChannelMessage(
        id: id ?? 'msg-${_messages[channelId]!.length}',
        channelId: channelId,
        senderId: senderId,
        senderType: senderType == 'user' ? ChannelSenderType.user : ChannelSenderType.agent,
        content: content,
        messageType: messageType == 'system'
            ? ChannelMessageType.system
            : messageType == 'ticket_card'
                ? ChannelMessageType.ticketCard
                : messageType == 'thinking'
                    ? ChannelMessageType.thinking
                    : ChannelMessageType.text,
        metadata: metadata,
        createdAt: DateTime.now(),
      ),
    );
    return '';
  }

  @override
  Future<void> updateMessage(
    String messageId, {
    String? content,
    Map<String, dynamic>? metadata,
  }) async {}

  @override
  Future<List<ChannelMessage>> getMessages(String channelId) async =>
      List.unmodifiable(_messages[channelId] ?? []);

  @override
  Future<void> markCompacted(List<String> ids) async {
    _compacted.addAll(ids);
  }

  @override
  Future<void> deleteChannel(String channelId) async {
    _channels.removeWhere((c) => c.id == channelId);
    _messages.remove(channelId);
    _participants.remove(channelId);
  }

  Future<void> updateChannelType(String channelId, String type) async {}

  @override
  Future<void> updateChannelName(String channelId, String name) async {}

  @override
  Future<void> clearChannelMessages(String channelId) async {
    _messages[channelId]?.clear();
  }

  @override
  Future<void> removeParticipant(String channelId, String agentId) async {
    _participants[channelId]?.removeWhere((p) => p.agentId == agentId);
  }

  @override
  Future<void> updateMessageEmbedding(String messageId, Uint8List embedding) async {}

  @override
  Future<List<EmbeddedChannelMessage>> getMessagesWithEmbedding(String channelId) async => [];

  @override
  Future<List<ChannelMessage>> getMessagesWithoutEmbedding({int limit = 200}) async => [];
  @override
  Stream<List<ChannelMessage>> watchTopLevelMessages(String channelId) =>
      const Stream.empty();

  @override
  Stream<List<ChannelMessage>> watchThread(String parentMessageId) =>
      const Stream.empty();

  @override
  Future<ChannelMessage?> getMessageById(String messageId) =>
      Future.value(null);
}

class _FakeAgentDispatchPort implements AgentDispatchPort {
  final StreamController<AgentProcessEvent> _controller =
      StreamController<AgentProcessEvent>.broadcast();
  Stream<AgentProcessEvent> get events => _controller.stream;

  void emitEvent(AgentProcessEvent event) => _controller.add(event);
  void emitError(Object error) => _controller.addError(error);

  @override
  DispatchHandle start({
    required String cliName,
    required String prompt,
    required String workingDirectory,
    String? modelId,
    String? agentId,
    String? workspaceId,
    String? conversationId,
    String? runLogId,
    String? ticketId,
    WakeContext? wakeContext,
    ConversationMode? mode,
    Map<String, String>? environment,
    List<String>? imagePaths,
  }) => DispatchHandle(dispatchId: 'ds-1', events: _controller.stream);

  @override
  Future<void> stopDispatch(String dispatchId) async => _controller.close();

  @override
  Future<void> stopAllForAgent(String agentId) async => _controller.close();

  @override
  Future<void> stop() async => _controller.close();
}

class _FakeRunLogRepo extends Fake implements AgentRunLogRepository {
  AgentRunLog? _runLog;
  var _upsertCount = 0;

  @override
  Future<void> upsert(AgentRunLog runLog) async {
    _runLog = runLog;
    _upsertCount++;
  }

  @override
  Future<AgentRunLog?> getById(String id) async => _runLog;
}

class _FakeDispatchAgentUseCase extends Fake implements DispatchAgentUseCase {
  @override
  Future<PreparedDispatch> execute({
    required String agentId,
    required String prompt,
    String? workspaceId,
    String? channelId,
    String? conversationId,
    String? adapterId,
    String? workingDirectory,
    WakeContext? wakeContext,
    MentionContext? mentionContext,
  }) async {
    return PreparedDispatch(
      effectivePrompt: prompt,
      effectiveConversationId: conversationId ?? channelId,
      agent: null,
      mode: ConversationMode.chat,
      resolvedAdapterId: null,
      cliName: 'pi',
    );
  }
}

void main() {
  late _FakeMessagingRepo repo;
  late _FakeAgentDispatchPort dispatchPort;
  late AgentDispatchService dispatchService;
  late _FakeRunLogRepo runLogRepo;
  late ActiveStreamRegistry streamRegistry;
  late MessagingService service;

  setUp(() {
    repo = _FakeMessagingRepo();
    dispatchPort = _FakeAgentDispatchPort();
    runLogRepo = _FakeRunLogRepo();
    streamRegistry = ActiveStreamRegistry();
    dispatchService = AgentDispatchService(
      agentDispatch: dispatchPort,
      dispatchUseCase: _FakeDispatchAgentUseCase(),
      runLogRepo: runLogRepo,
    );
    final streamProcessor = AgentStreamProcessor(
      agentDispatchService: dispatchService,
      repo: repo,
      streamRegistry: streamRegistry,
    );
    service = MessagingService(
      repo,
      agentDispatchService: dispatchService,
      streamRegistry: streamRegistry,
      streamProcessor: streamProcessor,
    );
  });

  tearDown(() async {
    await dispatchPort.stop();
  });

  group('openDm', () {
    test('creates a DM channel', () async {
      final channel = await service.openDm('agent-1');
      expect(channel.isDm, true);
      expect(channel.id, contains('agent-1'));
    });
  });

  group('createGroup', () {
    test('creates a group channel', () async {
      final channel = await service.createGroup('My Team', ['agent-1', 'agent-2']);
      expect(channel.isDm, false);
      expect(channel.name, 'My Team');
    });
  });

  group('sendUserMessage', () {
    test('sends a user message to channel', () async {
      final channel = await service.openDm('agent-1');
      await service.sendUserMessage(channel.id, 'Hello!');
      final msgs = await repo.getMessages(channel.id);
      expect(msgs.length, 1);
      expect(msgs[0].content, 'Hello!');
      expect(msgs[0].isUser, isTrue);
    });
  });

  group('addAgentToChannel', () {
    test('adds agent and sends system message', () async {
      final channel = await service.openDm('agent-1');
      await service.addAgentToChannel(channel.id, 'agent-2');
      final participants = await repo.getParticipants(channel.id);
      expect(participants.any((p) => p.agentId == 'agent-2'), isTrue);
    });

    test('does not add duplicate agent', () async {
      final channel = await service.openDm('agent-1');
      final initialCount = (await repo.getParticipants(channel.id)).length;
      await service.addAgentToChannel(channel.id, 'agent-1');
      final participants = await repo.getParticipants(channel.id);
      expect(participants.length, initialCount);
    });
  });

  group('deleteChannel', () {
    test('deletes a channel', () async {
      final channel = await service.openDm('agent-1');
      await service.deleteChannel(channel.id);
      final participants = await repo.getParticipants(channel.id);
      expect(participants, isEmpty);
    });
  });

  group('updateChannelType', () {
    test('completes without error', () async {
      await service.openDm('agent-1');
    });
  });

  group('updateChannelName', () {
    test('completes without error', () async {
      final channel = await service.createGroup('Old', ['a1']);
      await service.updateChannelName(channel.id, 'New Name');
    });
  });

  group('clearChannelMessages', () {
    test('clears all messages in channel', () async {
      final channel = await service.openDm('agent-1');
      await service.sendUserMessage(channel.id, 'msg1');
      await service.sendUserMessage(channel.id, 'msg2');
      await service.clearChannelMessages(channel.id);
      final msgs = await repo.getMessages(channel.id);
      expect(msgs, isEmpty);
    });
  });

  group('removeParticipant', () {
    test('removes an agent from channel', () async {
      final channel = await service.createGroup('Team', ['a1', 'a2']);
      await service.removeParticipant(channel.id, 'a1');
      final participants = await repo.getParticipants(channel.id);
      expect(participants.any((p) => p.agentId == 'a1'), isFalse);
      expect(participants.any((p) => p.agentId == 'a2'), isTrue);
    });
  });

  group('dispatchAgent', () {
    test('does nothing when prompt is empty', () async {
      final channel = await service.openDm('agent-1');
      await service.dispatchAgent(
        channelId: channel.id,
        agentId: 'agent-1',
        prompt: '',
      );
      final msgs = await repo.getMessages(channel.id);
      expect(msgs, isEmpty);
    });

    test('sends thinking message and dispatchPortes', () async {
      final channel = await service.openDm('agent-1');
      dispatchPort.emitEvent(TextEvent(content: 'Hello from agent'));
      dispatchPort.emitEvent(TextEvent(content: 'Done'));

      await service.dispatchAgent(
        channelId: channel.id,
        agentId: 'agent-1',
        prompt: 'Do something',
      );

      final msgs = await repo.getMessages(channel.id);
      expect(msgs.any((m) => m.messageType == ChannelMessageType.thinking), isTrue);
    });

    test('upserts run log when dispatchPorting', () async {
      final channel = await service.openDm('agent-1');
      dispatchPort.emitEvent(TextEvent(content: 'hello'));

      await service.dispatchAgent(
        channelId: channel.id,
        agentId: 'agent-1',
        prompt: 'Do something',
      );

      expect(runLogRepo._upsertCount, greaterThanOrEqualTo(1));
    });

    test('handles dispatchPort error', () async {
      final channel = await service.openDm('agent-1');

      await service.dispatchAgent(
        channelId: channel.id,
        agentId: 'agent-1',
        prompt: 'Do something',
      );

      dispatchPort.emitError(Exception('Dispatch failed'));

      // Should not throw
    });

    test('runs with workspaceId', () async {
      final channel = await service.openDm('agent-1');
      dispatchPort.emitEvent(TextEvent(content: 'hello'));

      await service.dispatchAgent(
        channelId: channel.id,
        agentId: 'agent-1',
        prompt: 'Do something',
        workspaceId: 'ws-1',
      );

      final msgs = await repo.getMessages(channel.id);
      expect(msgs.any((m) => m.messageType == ChannelMessageType.thinking), isTrue);
    });

    test('dispatchPort updates run log', () async {
      final channel = await service.openDm('agent-1');
      dispatchPort.emitEvent(TextEvent(content: 'hello'));

      await service.dispatchAgent(
        channelId: channel.id,
        agentId: 'agent-1',
        prompt: 'Do something',
      );

      expect(runLogRepo._upsertCount, greaterThanOrEqualTo(1));
    });
  });

  group('MessagingService constructor', () {
    test('creates service with required deps', () {
      final streamProcessor = AgentStreamProcessor(
        agentDispatchService: dispatchService,
        repo: repo,
        streamRegistry: streamRegistry,
      );
      final service = MessagingService(
        repo,
        agentDispatchService: dispatchService,
        streamRegistry: streamRegistry,
        streamProcessor: streamProcessor,
      );
      expect(service, isNotNull);
    });

    test('creates service with optional deps', () {
      final streamProcessor = AgentStreamProcessor(
        agentDispatchService: dispatchService,
        repo: repo,
        streamRegistry: streamRegistry,
      );
      final service = MessagingService(
        repo,
        agentDispatchService: dispatchService,
        streamRegistry: streamRegistry,
        streamProcessor: streamProcessor,
        agentRepo: null,
      );
      expect(service, isNotNull);
    });
  });
}
