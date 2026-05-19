import 'dart:async';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/messaging_events.dart';
import 'package:cc_domain/core/domain/ports/embedding_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/services/agent_mention_parser.dart';
import 'package:cc_domain/core/domain/value_objects/conversation_mode.dart';
import 'package:cc_domain/core/domain/value_objects/entity_ref.dart';
import 'package:cc_domain/core/domain/value_objects/output_contract_mode.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_infra/src/dispatch/agent_dispatch_service.dart';
import 'package:cc_infra/src/messaging/active_stream_registry.dart';
import 'package:cc_infra/src/messaging/agent_responder_resolver.dart';
import 'package:cc_infra/src/messaging/agent_stream_processor.dart';
import 'package:cc_infra/src/messaging/agent_working_directory.dart';

/// Service implementing the [MessagingPort] contract.
class MessagingService implements MessagingPort {
  /// Creates a [MessagingService].
  MessagingService(
    this._repo, {
    AgentRepository? agentRepo,
    required AgentDispatchService agentDispatchService,
    required this.streamRegistry,
    required AgentStreamProcessor streamProcessor,
    EmbeddingPort? embeddingPort,
    DomainEventBus? eventBus,
  }) : _agentRepo = agentRepo,
       _agentDispatchService = agentDispatchService,
       _embeddingPort = embeddingPort,
       _eventBus = eventBus,
       _streamProcessor = streamProcessor;

  final MessagingRepository _repo;
  final AgentRepository? _agentRepo;
  final AgentDispatchService _agentDispatchService;
  /// Registry for active agent output streams.
  final ActiveStreamRegistry streamRegistry;
  final EmbeddingPort? _embeddingPort;
  final DomainEventBus? _eventBus;
  final AgentStreamProcessor _streamProcessor;
  final _mentionParser = const AgentMentionParser();

  /// Opens a direct message channel with the given agent.
  @override
  Future<Channel> openDm(String agentId, {String? workspaceId}) =>
      _repo.openDm(agentId, workspaceId: workspaceId);

  @override
  Future<Channel> createGroup(
    String name,
    List<String> agentIds, {
    ConversationMode mode = ConversationMode.chat,
    String? workspaceId,
    String? pipelineRunId,
  }) =>
      _repo.createGroup(
        name,
        agentIds,
        mode: mode,
        workspaceId: workspaceId,
        pipelineRunId: pipelineRunId,
      );

  @override
  Future<void> sendUserMessage(
    String channelId,
    String content, {
    String? parentMessageId,
    Map<String, dynamic>? metadata,
  }) async {
    final messageId = await _repo.sendMessage(
      channelId: channelId,
      content: content,
      senderId: 'user',
      senderType: 'user',
      metadata: metadata,
      parentMessageId: parentMessageId,
    );
    _embedLastMessage(channelId, content);
    _notifyMessageReceived(
      channelId: channelId,
      content: content,
      isAgentMessage: false,
      messageId: messageId,
    );
  }

  void _embedLastMessage(String channelId, String content) {
    final port = _embeddingPort;
    if (port == null || !port.isReady || content.isEmpty) {
      return;
    }
    unawaited(
      _repo.getMessages(channelId).then((messages) async {
        final last = messages.lastOrNull;
        if (last == null || last.content != content) {
          return;
        }
        try {
          final vec = await port.embed(content);
          await _repo.updateMessageEmbedding(last.id, Uint8List.view(vec.buffer));
        } catch (_) {}
      }),
    );
  }

  @override
  Future<void> sendAndDispatch(
    String channelId,
    String content, {
    String? workspaceId,
    List<StructuredMention>? structuredMentions,
    List<EntityRef>? entityRefs,
    String? parentMessageId,
  }) async {
    // `#`-tagged entities ride along on the user message's metadata so the
    // bubble can render live chips and the references are durable.
    final metadata = (entityRefs != null && entityRefs.isNotEmpty)
        ? <String, dynamic>{
            'entityRefs': [for (final r in entityRefs) r.toJson()],
          }
        : null;
    final agentRepo = _agentRepo;
    if (agentRepo == null) {
      await sendUserMessage(
        channelId,
        content,
        parentMessageId: parentMessageId,
        metadata: metadata,
      );
      return;
    }

    final allAgents = workspaceId != null
        ? await agentRepo.watchByWorkspace(workspaceId).first
        : await agentRepo.watchAll().first;
    if (allAgents.isEmpty) {
      await sendUserMessage(
        channelId,
        content,
        parentMessageId: parentMessageId,
        metadata: metadata,
      );
      return;
    }

    final mentions = _mentionParser.parseMentions(content);

    final mentionedAgents = <String, Agent>{};
    for (final name in mentions) {
      final agent = allAgents
          .where(
            (a) =>
                a.name.toLowerCase() == name ||
                a.name.toLowerCase().startsWith(name),
          )
          .firstOrNull;
      if (agent != null) {
        mentionedAgents[agent.id] = agent;
        await addAgentToChannel(channelId, agent.id);
      }
    }

    await sendUserMessage(
      channelId,
      content,
      parentMessageId: parentMessageId,
      metadata: metadata,
    );

    final priorMessages = await _repo.getMessages(channelId);
    final lastMsg = priorMessages.length >= 2 ? priorMessages[priorMessages.length - 2] : null;
    if (lastMsg != null && lastMsg.isPlan && lastMsg.planStatus == 'pending') {
      await refinePlan(
        channelId: channelId,
        feedback: content,
        workspaceId: workspaceId,
      );
      return;
    }

    final stripped = _mentionParser.stripMentions(content);
    if (stripped.isEmpty) {
      return;
    }

    final Map<String, Agent> targets;
    if (mentionedAgents.isNotEmpty) {
      targets = mentionedAgents;
    } else {
      final participants = await _repo.getParticipants(channelId);
      final participantAgentIds =
          participants.where((p) => !p.isUser).map((p) => p.agentId).toSet();
      final availableAgents =
          allAgents.where((a) => participantAgentIds.contains(a.id)).toList();

      final channel = workspaceId != null
          ? await _repo
              .watchChannelsByWorkspace(workspaceId)
              .first
              .then((cs) => cs.where((c) => c.id == channelId).firstOrNull)
          : await _repo
              .watchChannels()
              .first
              .then((cs) => cs.where((c) => c.id == channelId).firstOrNull);

      String? lastAgentSenderId;
      final messages = await _repo.getMessages(channelId);
      if (messages.isNotEmpty) {
        final lastAgentMsg = messages.reversed.where(
          (m) =>
              m.senderType == ChannelSenderType.agent &&
              (m.messageType == ChannelMessageType.text ||
                  m.messageType == ChannelMessageType.agentTurn),
        ).firstOrNull;
        lastAgentSenderId = lastAgentMsg?.senderId;
      }

      final agent = AgentResponderResolver.resolveDefault(
        agents: availableAgents,
        isDm: channel?.isDm ?? false,
        lastAgentSenderId: lastAgentSenderId,
      );
      targets = agent != null ? {agent.id: agent} : {};
    }

    for (final agent in targets.values) {
      unawaited(
        dispatchAgent(
          channelId: channelId,
          agentId: agent.id,
          prompt: stripped,
          workspaceId: workspaceId,
          parentMessageId: parentMessageId,
        ),
      );
    }
  }

  @override
  Future<void> addAgentToChannel(String channelId, String agentId) async {
    final participants = await _repo.getParticipants(channelId);
    final alreadyPresent = participants.any((p) => p.agentId == agentId);
    if (alreadyPresent) {
      return;
    }

    if (participants.length == 2) {
      final existingAgent = participants.where((p) => !p.isUser).firstOrNull;
      final existingName = existingAgent != null
          ? (await _agentRepo?.getById(existingAgent.agentId))?.name ?? ''
          : '';
      final newAgent = await _agentRepo?.getById(agentId);
      final newName = newAgent?.name ?? agentId;
      final groupName = [existingName, newName]
          .where((n) => n.isNotEmpty)
          .join(', ');
      if (groupName.isNotEmpty) {
        await _repo.updateChannelName(channelId, groupName);
      }
    }

    await _repo.addParticipant(channelId, agentId);

    final agent = await _agentRepo?.getById(agentId);
    final name = agent?.name ?? agentId;

    await _repo.sendMessage(
      channelId: channelId,
      content: '$name joined the channel',
      senderId: 'system',
      senderType: 'agent',
      messageType: 'system',
    );
  }

  @override
  Future<bool> channelExists(String channelId) =>
      _repo.channelExists(channelId);

  @override
  Future<void> refinePlan({
    required String channelId,
    required String feedback,
    String? workspaceId,
  }) async {
    final messages = await _repo.getMessages(channelId);
    final pendingPlan = messages.reversed.firstWhere(
      (m) => m.isPlan && m.planStatus == 'pending',
      orElse: () => messages.reversed.firstWhere(
        (m) => m.isPlan,
        orElse: () => throw StateError('No plan found in channel $channelId'),
      ),
    );

    final existingMeta = Map<String, dynamic>.from(pendingPlan.metadata ?? {});
    existingMeta['planStatus'] = 'refining';
    await _repo.updateMessage(
      pendingPlan.id,
      content: pendingPlan.content,
      metadata: existingMeta,
    );

    await sendUserMessage(channelId, feedback);

    final agent = await _agentRepo?.getById(pendingPlan.senderId);
    if (agent != null) {
      unawaited(
        dispatchAgent(
          channelId: channelId,
          agentId: agent.id,
          prompt: 'The user provided feedback on your plan: $feedback. '
              'Please refine the plan accordingly and produce an updated plan.',
          workspaceId: workspaceId,
          parentMessageId: pendingPlan.id,
        ),
      );
    }
  }

  @override
  Future<String?> dispatchAgent({
    required String channelId,
    required String agentId,
    required String prompt,
    String? workspaceId,
    String? ticketId,
    String? pipelineRunId,
    String? pipelineStepId,
    String? inReplyToAgentId,
    WakeContext? wakeContext,
    String? parentMessageId,
    Map<String, dynamic>? expectedOutputSchema,
    OutputContractMode outputContractMode = OutputContractMode.strict,
  }) async {
    if (prompt.isEmpty) {
      return null;
    }

    final agent = await _agentRepo?.getById(agentId);
    final agentName = agent?.name ?? agentId;
    // Attribute the turn to the agent that triggered it (a consult or a
    // delegation) so multi-agent rooms read as a conversation.
    final inReplyToAgentName = inReplyToAgentId == null
        ? null
        : (await _agentRepo?.getById(inReplyToAgentId))?.name;
    final workingDirectory = agent != null
        ? workingDirectoryFromAgentMdPath(agent.agentMdPath)
        : '/tmp';
    final adapterId = agent?.adapterId;

    final result = await _agentDispatchService.dispatch(
      agentId: agentId,
      prompt: prompt,
      workingDirectory: workingDirectory,
      adapterId: adapterId,
      workspaceId: workspaceId,
      conversationId: channelId,
      channelId: channelId,
      ticketId: ticketId,
      pipelineRunId: pipelineRunId,
      pipelineStepId: pipelineStepId,
      expectedOutputSchema: expectedOutputSchema,
      outputContractMode: outputContractMode,
      wakeContext: wakeContext,
    );

    final messageId = result.runLog.id;

    streamRegistry.register(messageId);

    await _repo.sendMessage(
      channelId: channelId,
      content: '',
      senderId: agentId,
      senderType: 'agent',
      messageType: 'agent_turn',
      id: messageId,
      metadata: {
        'agentName': agentName,
        'streamComplete': false,
        'inReplyToAgentId': ?inReplyToAgentId,
        'inReplyToAgentName': ?inReplyToAgentName,
      },
      parentMessageId: parentMessageId,
    );

    _streamProcessor.processStream(
      stream: result.stream,
      dispatchResult: result,
      channelId: channelId,
      agentId: agentId,
      agentName: agentName,
      messageId: messageId,
      workingDirectory: workingDirectory,
    );

    return messageId;
  }

  @override
  Future<void> retryAgentTurn({
    required String channelId,
    required String failedMessageId,
  }) async {
    final failed = await _repo.getMessageById(failedMessageId);
    if (failed == null) {
      return;
    }
    final agentId = failed.senderId;
    // Mark the failed message as retried so the bubble hides its Retry button.
    final meta = Map<String, dynamic>.from(failed.metadata ?? {})
      ..['retried'] = true;
    await _repo.updateMessage(
      failedMessageId,
      content: failed.content,
      metadata: meta,
    );
    await dispatchAgent(
      channelId: channelId,
      agentId: agentId,
      prompt: 'Your previous attempt in this channel failed before finishing. '
          'Review the conversation above and re-attempt the task.',
    );
  }

  /// Stops the in-flight agent run identified by [runLogId] (== the agent
  /// turn's message id). Delegates to the dispatch service, which terminates
  /// only that dispatch and finalizes the run; the closed event stream drives
  /// the turn to its interrupted final state. No-op for a finished run.
  @override
  Future<void> stopRun(String runLogId) =>
      _agentDispatchService.stopRun(runLogId);

  /// Deletes a channel and publishes a deletion event.
  @override
  Future<void> deleteChannel(String channelId) async {
    await _repo.deleteChannel(channelId);
    // Let listeners (e.g. the worktree GC) tear down per-conversation resources.
    _eventBus?.publish(
      ConversationDeleted(channelId: channelId, occurredAt: DateTime.now()),
    );
  }

  /// Updates the name of a channel.
  Future<void> updateChannelName(String channelId, String name) =>
      _repo.updateChannelName(channelId, name);

  /// Clears all messages in a channel.
  @override
  Future<void> clearChannelMessages(String channelId) =>
      _repo.clearChannelMessages(channelId);

  /// Removes a participant from a channel.
  @override
  Future<void> removeParticipant(String channelId, String agentId) =>
      _repo.removeParticipant(channelId, agentId);

  void _notifyMessageReceived({
    required String channelId,
    required String content,
    required bool isAgentMessage,
    String messageId = '',
    String senderName = 'You',
  }) {
    final bus = _eventBus;
    if (bus == null) {
      return;
    }

    final preview = content.length > 120
        ? '${content.substring(0, 120)}…'
        : content;

    bus.publish(MessageReceived(
      channelId: channelId,
      messageId: messageId,
      senderName: senderName,
      contentPreview: preview,
      isAgentMessage: isAgentMessage,
      // This path only ever emits user messages, which never raise a
      // notification (the mapper drops non-agent messages), so the owning
      // workspace is left unresolved here.
      workspaceId: null,
      occurredAt: DateTime.now(),
    ));
  }
}
