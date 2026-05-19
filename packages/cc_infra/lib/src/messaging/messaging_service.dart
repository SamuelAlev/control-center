import 'dart:async';
import 'dart:typed_data';

import 'package:cc_domain/cc_domain.dart' show WorkspaceMismatchException;
import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/messaging_events.dart';
import 'package:cc_domain/core/domain/ports/embedding_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/services/agent_mention_parser.dart';
import 'package:cc_domain/core/domain/services/user_mention_parser.dart';
import 'package:cc_domain/core/domain/value_objects/entity_ref.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/output_contract_mode.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/mention_context.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/channel_origin.dart';
import 'package:cc_harness/context.dart';
import 'package:cc_infra/src/dispatch/agent_dispatch_service.dart';
import 'package:cc_infra/src/messaging/active_stream_registry.dart';
import 'package:cc_infra/src/messaging/agent_responder_resolver.dart';
import 'package:cc_infra/src/messaging/agent_stream_processor.dart';
import 'package:cc_infra/src/messaging/agent_working_directory.dart';
import 'package:cc_infra/src/messaging/conversation_compaction_service.dart';

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
    Future<String?> Function()? resolveDefaultUserId,
    Future<bool> Function(String workspaceId, String channelId)?
    dispatchBlocked,
    Future<List<MentionableMember>> Function(String workspaceId)? listMembers,
    Future<String?> Function({
      required String workspaceId,
      required String channelId,
      required String agentId,
      required String prompt,
      String? conversationId,
      String? requestedByUserId,
    })?
    goalCommandHandler,
    ConversationCompactionService? compactionService,
  }) : _agentRepo = agentRepo,
       _agentDispatchService = agentDispatchService,
       _embeddingPort = embeddingPort,
       _eventBus = eventBus,
       _resolveDefaultUserId = resolveDefaultUserId,
       _dispatchBlocked = dispatchBlocked,
       _listMembers = listMembers,
       _goalCommandHandler = goalCommandHandler,
       _compactionService = compactionService,
       _streamProcessor = streamProcessor;

  final MessagingRepository _repo;
  final AgentRepository? _agentRepo;

  /// When set, a true answer refuses a dispatch into the channel — a human
  /// holds a take-over on its worktree (PRD 16 §8).
  final Future<bool> Function(String workspaceId, String channelId)?
  _dispatchBlocked;
  final AgentDispatchService _agentDispatchService;

  /// Optional goal-command interceptor (the goal supervisor's startGoal
  /// wrapper, injected — MessagingService never imports the supervisor). When
  /// set and a dispatch prompt begins with `/goal ` or `/loop `, the prompt is
  /// routed to this handler instead of a plain dispatch; the handler returns
  /// the first run's message id. Null keeps historical behavior (the harness
  /// handles the slash command in-session).
  final Future<String?> Function({
    required String workspaceId,
    required String channelId,
    required String agentId,
    required String prompt,
    String? conversationId,
    String? requestedByUserId,
  })?
  _goalCommandHandler;

  /// Registry for active agent output streams.
  final ActiveStreamRegistry streamRegistry;
  final EmbeddingPort? _embeddingPort;
  final DomainEventBus? _eventBus;
  final AgentStreamProcessor _streamProcessor;

  /// Anchored-compaction maintenance pass, injected so `/compact` can force it
  /// out-of-band (the automatic pass runs post-turn from the stream
  /// processor). Null in tests — `compactConversation` then reports
  /// [ConversationCompactionStatus.unavailable].
  final ConversationCompactionService? _compactionService;

  /// Resolves the fallback author for programmatic "user" messages (pipeline
  /// steps, team dispatch) that have no acting human in context: the server
  /// owner. Null in tests that never exercise those paths.
  final Future<String?> Function()? _resolveDefaultUserId;

  /// Lists a workspace's human members for `@handle` mention resolution
  /// (PRD 16 §15). Null in tests/contexts with no identity layer wired — human
  /// mentions then simply never resolve (agent mentions are unaffected).
  final Future<List<MentionableMember>> Function(String workspaceId)?
  _listMembers;
  final _mentionParser = const AgentMentionParser();
  final _userMentionParser = const UserMentionParser();

  /// The author id for a human message: the acting user when supplied, else
  /// the owner fallback. Loud when neither exists — messages are never
  /// attributed to a sentinel.
  Future<String> _authorUserId(String? senderUserId) async {
    if (senderUserId != null && senderUserId.isNotEmpty) {
      return senderUserId;
    }
    final fallback = await _resolveDefaultUserId?.call();
    if (fallback == null || fallback.isEmpty) {
      throw StateError(
        'No acting user for a human-authored message and no owner fallback '
        'is wired',
      );
    }
    return fallback;
  }

  @override
  Future<Channel> createChannel(
    String workspaceId,
    String name,
    List<String> agentIds, {
    Mode mode = Mode.chat,
    String? pipelineRunId,
    String? createdByUserId,
    ChannelOrigin origin = ChannelOrigin.user,
    List<String> repoIds = const [],
  }) async {
    final channel = await _repo.createChannel(
      workspaceId,
      name,
      agentIds,
      mode: mode,
      pipelineRunId: pipelineRunId,
      createdByUserId: createdByUserId,
      origin: origin,
      repoIds: repoIds,
    );
    // Single chokepoint for both desktop-embedded and RPC paths: publish so the
    // background provisioner can set up the conversation workspace (worktrees +
    // overlay + `.mcp.json`) without blocking the create call.
    _eventBus?.publish(
      ChannelCreated(
        channelId: channel.id,
        workspaceId: channel.workspaceId,
        occurredAt: DateTime.now(),
      ),
    );
    return channel;
  }

  @override
  Future<void> sendUserMessage(
    String workspaceId,
    String channelId,
    String content, {
    String? senderUserId,
    String? conversationId,
    Map<String, dynamic>? metadata,
  }) async {
    final messageId = await _repo.sendMessage(
      workspaceId: workspaceId,
      channelId: channelId,
      content: content,
      senderId: await _authorUserId(senderUserId),
      senderType: 'user',
      metadata: metadata,
      conversationId: conversationId,
    );
    _embedLastMessage(workspaceId, channelId, content);
    _notifyMessageReceived(
      workspaceId: workspaceId,
      channelId: channelId,
      content: content,
      isAgentMessage: false,
      messageId: messageId,
      mentions: _decodeMentionPrincipals(metadata),
    );
  }

  /// Decodes `metadata['mentions']` (see [MessagingService.sendAndDispatch])
  /// into wire-ready [Principal]s for the [MessageReceived] notification
  /// event (PRD 16 §7/§15) — a human mention rides this path so a mentioned
  /// teammate is notified even though the message itself is human-authored
  /// (which otherwise never raises a notification).
  List<Principal> _decodeMentionPrincipals(Map<String, dynamic>? metadata) {
    final raw = metadata?['mentions'];
    if (raw is! List) {
      return const [];
    }
    final principals = <Principal>[];
    for (final m in raw) {
      if (m is Map<String, dynamic>) {
        final mention = MessageMention.fromJson(m);
        principals.add(Principal.of(mention.principalType, mention.agentId));
      }
    }
    return principals;
  }

  void _embedLastMessage(String workspaceId, String channelId, String content) {
    final port = _embeddingPort;
    if (port == null || !port.isReady || content.isEmpty) {
      return;
    }
    unawaited(
      _repo.getMessages(workspaceId, channelId).then((messages) async {
        final last = messages.lastOrNull;
        if (last == null || last.content != content) {
          return;
        }
        try {
          final vec = await port.embed(content);
          await _repo.updateMessageEmbedding(
            workspaceId,
            last.id,
            Uint8List.view(vec.buffer),
          );
        } catch (_) {}
      }),
    );
  }

  @override
  Future<void> sendAndDispatch(
    String workspaceId,
    String channelId,
    String content, {
    String? senderUserId,
    String? conversationId,
    List<StructuredMention>? structuredMentions,
    List<EntityRef>? entityRefs,
    Map<String, dynamic>? metadata,
  }) async {
    // `#`-tagged entities ride along on the user message's metadata so the
    // bubble can render live chips and the references are durable; a caller's
    // own provenance (e.g. the chat bridge's `chat` block) rides beside them.
    final baseMetadata = (entityRefs != null && entityRefs.isNotEmpty)
        ? <String, dynamic>{
            ...?metadata,
            'entityRefs': [for (final r in entityRefs) r.toJson()],
          }
        : metadata;
    final agentRepo = _agentRepo;
    if (agentRepo == null) {
      await sendUserMessage(
        workspaceId,
        channelId,
        content,
        senderUserId: senderUserId,
        conversationId: conversationId,
        metadata: baseMetadata,
      );
      return;
    }

    final allAgents = await agentRepo.watchByWorkspace(workspaceId).first;
    if (allAgents.isEmpty) {
      await sendUserMessage(
        workspaceId,
        channelId,
        content,
        senderUserId: senderUserId,
        conversationId: conversationId,
        metadata: baseMetadata,
      );
      return;
    }

    final mentions = _mentionParser.parseMentions(content);

    final mentionedAgents = <String, Agent>{};
    final agentClaimedTokens = <String>{};
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
        agentClaimedTokens.add(name);
        await addAgentToChannel(workspaceId, channelId, agent.id);
      }
    }

    // PRD 16 §15: any `@token` that did not resolve to an agent is tried
    // against the workspace's human members, by handle. A resolved human
    // mention never dispatches anything — it rides the message's metadata
    // purely for notification routing (PRD 16 §7).
    final listMembers = _listMembers;
    final mentionedUsers = listMembers != null
        ? _userMentionParser.resolveMentions(
            content,
            await listMembers(workspaceId),
            excludeTokens: agentClaimedTokens,
          )
        : const <MentionableMember>[];

    final resolvedMentions = <MessageMention>[
      for (final a in mentionedAgents.values)
        MessageMention(agentId: a.id, raw: '@${a.name}'),
      for (final u in mentionedUsers)
        MessageMention(
          agentId: u.id,
          raw: '@${u.handle}',
          principalType: PrincipalType.user,
        ),
    ];
    final mergedMetadata = resolvedMentions.isEmpty
        ? baseMetadata
        : <String, dynamic>{
            ...?baseMetadata,
            'mentions': [for (final m in resolvedMentions) m.toJson()],
          };

    await sendUserMessage(
      workspaceId,
      channelId,
      content,
      senderUserId: senderUserId,
      conversationId: conversationId,
      metadata: mergedMetadata,
    );

    final priorMessages = await _repo.getMessages(
      workspaceId,
      channelId,
      conversationId: conversationId,
    );
    final lastMsg = priorMessages.length >= 2
        ? priorMessages[priorMessages.length - 2]
        : null;
    if (lastMsg != null && lastMsg.isPlan && lastMsg.planStatus == 'pending') {
      await refinePlan(
        workspaceId: workspaceId,
        channelId: channelId,
        feedback: content,
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
      final participants = await _repo.getParticipants(workspaceId, channelId);
      final participantAgentIds = participants
          .where((p) => !p.isUser)
          .map((p) => p.principalId)
          .toSet();
      final availableAgents = allAgents
          .where((a) => participantAgentIds.contains(a.id))
          .toList();

      String? lastAgentSenderId;
      final messages = await _repo.getMessages(
        workspaceId,
        channelId,
        conversationId: conversationId,
      );
      if (messages.isNotEmpty) {
        final lastAgentMsg = messages.reversed
            .where(
              (m) =>
                  m.senderType == ChannelSenderType.agent &&
                  (m.messageType == ChannelMessageType.text ||
                      m.messageType == ChannelMessageType.agentTurn),
            )
            .firstOrNull;
        lastAgentSenderId = lastAgentMsg?.senderId;
      }

      final agent = AgentResponderResolver.resolveDefault(
        agents: availableAgents,
        lastAgentSenderId: lastAgentSenderId,
      );
      targets = agent != null ? {agent.id: agent} : {};
    }

    for (final agent in targets.values) {
      unawaited(
        dispatchAgent(
          workspaceId: workspaceId,
          channelId: channelId,
          agentId: agent.id,
          prompt: stripped,
          // The human whose message triggered these runs: their git identity
          // co-authors the agents' commits and their own GitHub token (when
          // stored) backs the runs.
          requestedByUserId: senderUserId,
          conversationId: conversationId,
        ),
      );
    }
  }

  @override
  Future<void> addAgentToChannel(
    String workspaceId,
    String channelId,
    String agentId, {
    bool renameForGroup = true,
  }) async {
    final participants = await _repo.getParticipants(workspaceId, channelId);
    final alreadyPresent = participants.any(
      (p) => !p.isUser && p.principalId == agentId,
    );
    if (alreadyPresent) {
      return;
    }

    if (renameForGroup && participants.length == 2) {
      final existingAgent = participants.where((p) => !p.isUser).firstOrNull;
      final existing = existingAgent == null
          ? null
          : await _agentRepo?.getById(workspaceId, existingAgent.principalId);
      final existingName = existing?.name ?? '';
      final newAgent = await _agentRepo?.getById(workspaceId, agentId);
      final newName = newAgent?.name ?? agentId;
      final groupName = [
        existingName,
        newName,
      ].where((n) => n.isNotEmpty).join(', ');
      if (groupName.isNotEmpty) {
        await _repo.updateChannelName(workspaceId, channelId, groupName);
      }
    }

    await _repo.addParticipant(workspaceId, channelId, agentId);

    final agent = await _agentRepo?.getById(workspaceId, agentId);
    final name = agent?.name ?? agentId;

    await _repo.sendMessage(
      workspaceId: workspaceId,
      channelId: channelId,
      content: '$name joined the channel',
      senderId: 'system',
      senderType: 'agent',
      messageType: 'system',
    );
  }

  @override
  Future<bool> channelExists(String workspaceId, String channelId) =>
      _repo.channelExists(workspaceId, channelId);

  /// Posts a system message into the channel — senderId 'system', senderType
  /// 'agent', messageType 'system', the same shape as the take-over refusal.
  /// Used by the goal supervisor to narrate goal lifecycle events.
  Future<void> postSystemMessage(
    String workspaceId,
    String channelId,
    String content, {
    String? conversationId,
  }) => _repo.sendMessage(
    workspaceId: workspaceId,
    channelId: channelId,
    content: content,
    senderId: 'system',
    senderType: 'agent',
    messageType: 'system',
    conversationId: conversationId,
  );

  @override
  Future<void> refinePlan({
    required String workspaceId,
    required String channelId,
    required String feedback,
  }) async {
    final messages = await _repo.getMessages(workspaceId, channelId);
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
      workspaceId,
      pendingPlan.id,
      content: pendingPlan.content,
      metadata: existingMeta,
    );

    // Keep the refinement turn in the same conversation the plan lives in.
    final conversationId = pendingPlan.conversationId;
    await sendUserMessage(
      workspaceId,
      channelId,
      feedback,
      conversationId: conversationId,
    );

    final agent = await _agentRepo?.getById(workspaceId, pendingPlan.senderId);
    if (agent != null) {
      unawaited(
        dispatchAgent(
          workspaceId: workspaceId,
          channelId: channelId,
          agentId: agent.id,
          prompt:
              'The user provided feedback on your plan: $feedback. '
              'Please refine the plan accordingly and produce an updated plan.',
          conversationId: conversationId,
        ),
      );
    }
  }

  @override
  Future<String?> dispatchAgent({
    required String workspaceId,
    required String channelId,
    required String agentId,
    required String prompt,
    String? ticketId,
    String? pipelineRunId,
    String? pipelineStepId,
    String? inReplyToAgentId,
    String? requestedByUserId,
    WakeContext? wakeContext,
    String? conversationId,
    Map<String, dynamic>? expectedOutputSchema,
    OutputContractMode outputContractMode = OutputContractMode.strict,
  }) async {
    // Durable-goal interception: a `/goal ` or `/loop ` prompt becomes a
    // supervised objective instead of a one-off dispatch. Exact token match,
    // case-sensitive, same as parseSlashCommand in cc_harness.
    final goalHandler = _goalCommandHandler;
    if (goalHandler != null) {
      final trimmed = prompt.trimLeft();
      if (trimmed.startsWith('/goal ') || trimmed.startsWith('/loop ')) {
        return goalHandler(
          workspaceId: workspaceId,
          channelId: channelId,
          agentId: agentId,
          prompt: prompt,
          conversationId: conversationId,
          requestedByUserId: requestedByUserId,
        );
      }
    }
    return dispatchAgentRun(
      workspaceId: workspaceId,
      channelId: channelId,
      agentId: agentId,
      prompt: prompt,
      ticketId: ticketId,
      pipelineRunId: pipelineRunId,
      pipelineStepId: pipelineStepId,
      inReplyToAgentId: inReplyToAgentId,
      requestedByUserId: requestedByUserId,
      wakeContext: wakeContext,
      conversationId: conversationId,
      expectedOutputSchema: expectedOutputSchema,
      outputContractMode: outputContractMode,
    );
  }

  /// The plain agent dispatch with no goal-command interception. This is the
  /// goal supervisor's dispatcher target: its first run re-sends the verbatim
  /// `/goal ...` prompt and must never loop back into the command handler.
  Future<String?> dispatchAgentRun({
    required String workspaceId,
    required String channelId,
    required String agentId,
    required String prompt,
    String? ticketId,
    String? pipelineRunId,
    String? pipelineStepId,
    String? inReplyToAgentId,
    String? requestedByUserId,
    WakeContext? wakeContext,
    String? conversationId,
    Map<String, dynamic>? expectedOutputSchema,
    OutputContractMode outputContractMode = OutputContractMode.strict,
    int? costCapCents,
  }) async {
    if (prompt.isEmpty) {
      return null;
    }
    // The conversation (stream) this run belongs to; defaults to the channel's
    // `main` conversation (== the channel id). The run only ever sees this
    // conversation's history, and its turn is posted back into it.
    final convId = conversationId ?? channelId;

    // Take-over gate: while a human holds the conversation's worktree, no
    // agent may be dispatched into it — resuming into a half-finished human
    // edit silently corrupts the run (PRD 16 §8). Loud, never a silent no-op.
    final blocked = _dispatchBlocked;
    if (blocked != null && await blocked(workspaceId, channelId)) {
      await _repo.sendMessage(
        workspaceId: workspaceId,
        channelId: channelId,
        content:
            'Dispatch refused: a human has taken over this conversation\'s '
            'worktree. Hand it back to resume agent work.',
        senderId: 'system',
        senderType: 'agent',
        messageType: 'system',
      );
      return null;
    }

    final agent = await _agentRepo?.getById(workspaceId, agentId);
    final agentName = agent?.name ?? agentId;
    // Attribute the turn to the agent that triggered it (a consult or a
    // delegation) so multi-agent rooms read as a conversation.
    final inReplyToAgentName = inReplyToAgentId == null
        ? null
        : (await _agentRepo?.getById(workspaceId, inReplyToAgentId))?.name;
    final workingDirectory = agent != null
        ? workingDirectoryFromAgentMdPath(agent.agentMdPath)
        : '/tmp';
    final adapterId = agent?.adapterId;
    // Build the mention context so the agent knows who's in the channel —
    // both agent teammates and human members (PRD 16 §15: principals).
    MentionContext? mentionContext;
    final roster = <MentionRosterEntry>[];
    try {
      final participants = await _repo.getParticipants(workspaceId, channelId);
      for (final p in participants) {
        if (!p.isUser && p.principalId != agentId) {
          final teammate = await _agentRepo?.getById(
            workspaceId,
            p.principalId,
          );
          roster.add(
            MentionRosterEntry.agent(
              agentId: p.principalId,
              name: teammate?.name ?? p.principalId,
              isTopLevel: teammate?.isTopLevel ?? false,
            ),
          );
        }
      }
    } catch (_) {
      // Best-effort — participant lookup failure shouldn't block dispatch.
    }
    final listMembers = _listMembers;
    if (listMembers != null) {
      try {
        for (final m in await listMembers(workspaceId)) {
          roster.add(
            MentionRosterEntry.user(userId: m.id, name: m.displayName),
          );
        }
      } catch (_) {
        // Best-effort.
      }
    }
    if (roster.isNotEmpty) {
      mentionContext = MentionContext(
        summonedBy: requestedByUserId ?? 'user',
        channelRoster: roster,
      );
    }

    final result = await _agentDispatchService.dispatch(
      agentId: agentId,
      prompt: prompt,
      workingDirectory: workingDirectory,
      adapterId: adapterId,
      workspaceId: workspaceId,
      conversationId: convId,
      channelId: channelId,
      ticketId: ticketId,
      pipelineRunId: pipelineRunId,
      pipelineStepId: pipelineStepId,
      requestedByUserId: requestedByUserId,
      expectedOutputSchema: expectedOutputSchema,
      outputContractMode: outputContractMode,
      wakeContext: wakeContext,
      mentionContext: mentionContext,
      costCapCents: costCapCents,
    );

    final messageId = result.runLog.id;

    streamRegistry.register(messageId, channelId: channelId);

    await _repo.sendMessage(
      workspaceId: workspaceId,
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
      conversationId: convId,
    );

    _streamProcessor.processStream(
      stream: result.stream,
      dispatchResult: result,
      workspaceId: workspaceId,
      channelId: channelId,
      agentId: agentId,
      agentName: agentName,
      messageId: messageId,
      workingDirectory: workingDirectory,
      // Threaded onto the completed turn's `MessageReceived` notification
      // (PRD 16 §7) so a notification receiver can tell "my run" from
      // "someone else's run" and suppress the latter.
      requestedByUserId: requestedByUserId,
    );

    return messageId;
  }

  @override
  Future<void> retryAgentTurn({
    required String workspaceId,
    required String channelId,
    required String failedMessageId,
  }) async {
    final failed = await _repo.getMessageById(workspaceId, failedMessageId);
    if (failed == null) {
      return;
    }
    final agentId = failed.senderId;
    // Mark the failed message as retried so the bubble hides its Retry button.
    final meta = Map<String, dynamic>.from(failed.metadata ?? {})
      ..['retried'] = true;
    await _repo.updateMessage(
      workspaceId,
      failedMessageId,
      content: failed.content,
      metadata: meta,
    );
    // The retry is dispatched with the SAME context as the turn it replaces, or
    // it becomes a second-class run:
    //  * a foreign/absent `workspaceId` ⇒ the run log carries the wrong
    //    workspace, so every workspace-scoped surface misses it (the composer
    //    never shows "running" and offers no stop, the bubble never shimmers,
    //    the roster/run tree never lists it) and the ownership check on
    //    `stopRun`/`pauseRun`/`steer` rejects it — an unstoppable run. It also
    //    loses the per-conversation isolated worktree and falls back to the
    //    agent's global config dir.
    //  * no `conversationId` ⇒ the retry lands in the channel's `main`
    //    conversation even when the failed turn belonged to a parenthesis.
    await dispatchAgent(
      workspaceId: workspaceId,
      channelId: channelId,
      agentId: agentId,
      prompt:
          'Your previous attempt in this channel failed before finishing. '
          'Review the conversation above and re-attempt the task.',
      conversationId: failed.conversationId,
    );
  }

  /// Stops the in-flight agent run identified by [runLogId] (== the agent
  /// turn's message id) within [workspaceId]. Delegates to the dispatch service,
  /// which terminates only that dispatch and finalizes the run; the closed event
  /// stream drives the turn to its interrupted final state. No-op for a finished
  /// run.
  @override
  Future<void> stopRun(String workspaceId, String runLogId) =>
      _agentDispatchService.stopRun(workspaceId, runLogId);

  /// Pauses the in-flight run [runLogId] at its next clean turn boundary.
  /// Delegates to the dispatch service; returns false when the run isn't
  /// pausable (finished, or an external-CLI transport with no boundary).
  @override
  Future<bool> pauseRun(String runLogId) =>
      _agentDispatchService.pauseRun(runLogId);

  /// Releases a previously paused run [runLogId], continuing it.
  @override
  Future<bool> resumeRun(String runLogId) =>
      _agentDispatchService.resumeRun(runLogId);

  /// Delivers a mid-run steering message to the in-flight run [runLogId].
  /// Delegates to the dispatch service, which routes it to the live harness
  /// loop's steering inbox.
  @override
  Future<bool> steerRun(
    String runLogId,
    String message, {
    bool followUp = false,
  }) => _agentDispatchService.steerRun(runLogId, message, followUp: followUp);

  /// Fallback character budget when the channel's agent has no configured
  /// `contextSize` (mirrors the client meter's default; the window only feeds
  /// the pressure gate, which a forced compaction skips anyway).
  static const int _defaultContextChars = 1000000;

  /// Forces an anchored-compaction pass over the conversation (`/compact`).
  /// Refuses while a turn is streaming in the channel — the prune pass
  /// read-modify-writes transcript metadata and would race the live turn's
  /// writes (a lost update on the in-flight message).
  @override
  Future<ConversationCompactionResult> compactConversation({
    required String workspaceId,
    required String channelId,
    String? conversationId,
  }) async {
    final service = _compactionService;
    if (service == null) {
      return const ConversationCompactionResult(
        status: ConversationCompactionStatus.unavailable,
      );
    }
    if (streamRegistry.activeIn(channelId).isNotEmpty) {
      return const ConversationCompactionResult(
        status: ConversationCompactionStatus.agentBusy,
      );
    }
    // `conversation_id` arrives from the client and the DAO filters messages
    // by conversation alone — the op's channel-ownership check proves nothing
    // about a foreign conversation id. Deny loudly unless the conversation
    // provably belongs to this channel, BEFORE anything is mutated. (An empty
    // conversation can't prove ownership either way, but `maintain` no-ops on
    // empty history, so nothing can be mutated through that path.)
    if (conversationId != null && conversationId != channelId) {
      final scoped = await _repo.getMessages(
        workspaceId,
        channelId,
        conversationId: conversationId,
      );
      if (scoped.any((m) => m.channelId != channelId)) {
        throw const WorkspaceMismatchException(
          'Conversation belongs to a different channel.',
        );
      }
    }
    // Window + turn label come from the channel's agent when it is
    // unambiguous (a DM); multi-agent rooms fall back to the defaults.
    Agent? agent;
    final participants = await _repo.getParticipants(workspaceId, channelId);
    final agentIds = [
      for (final p in participants)
        if (!p.isUser) p.principalId,
    ];
    if (agentIds.length == 1) {
      agent = await _agentRepo?.getById(workspaceId, agentIds.first);
    }
    final windowTokens = TokenEstimator.instance.windowTokensFromChars(
      agent?.contextSize ?? _defaultContextChars,
    );
    final outcome = await service.maintain(
      workspaceId: workspaceId,
      channelId: channelId,
      conversationId: conversationId,
      contextWindowTokens: windowTokens,
      selfAgentName: agent?.name ?? 'assistant',
      force: true,
    );
    return ConversationCompactionResult(
      status: outcome.didSomething
          ? ConversationCompactionStatus.compacted
          : ConversationCompactionStatus.nothingToCompact,
      compactedMessageCount: outcome.compactedMessageCount,
    );
  }

  /// Deletes a channel and publishes a deletion event.
  @override
  Future<void> deleteChannel(String workspaceId, String channelId) async {
    await _repo.deleteChannel(workspaceId, channelId);
    // Let listeners (e.g. the worktree GC) tear down per-conversation resources.
    _eventBus?.publish(
      ChannelDeleted(channelId: channelId, occurredAt: DateTime.now()),
    );
  }

  /// Updates the name of a channel.
  Future<void> updateChannelName(
    String workspaceId,
    String channelId,
    String name,
  ) => _repo.updateChannelName(workspaceId, channelId, name);

  /// Clears all messages in a channel.
  @override
  Future<void> clearChannelMessages(String workspaceId, String channelId) =>
      _repo.clearChannelMessages(workspaceId, channelId);

  /// Removes a participant from a channel.
  @override
  Future<void> removeParticipant(
    String workspaceId,
    String channelId,
    String agentId,
  ) => _repo.removeParticipant(workspaceId, channelId, agentId);

  void _notifyMessageReceived({
    required String workspaceId,
    required String channelId,
    required String content,
    required bool isAgentMessage,
    String messageId = '',
    String senderName = 'You',
    List<Principal> mentions = const [],
  }) {
    final bus = _eventBus;
    if (bus == null) {
      return;
    }

    final preview = content.length > 120
        ? '${content.substring(0, 120)}…'
        : content;

    // A human mention (PRD 16 §15) DOES notify (PRD 16 §7) even though the
    // sender is human, and the workspace scopes + deep-links that notification
    // exactly like an agent-message one. Un-mentioned human messages raise no
    // notification at all (the mapper drops them), so the workspace is simply
    // carried along for both.
    bus.publish(
      MessageReceived(
        channelId: channelId,
        messageId: messageId,
        senderName: senderName,
        contentPreview: preview,
        isAgentMessage: isAgentMessage,
        workspaceId: workspaceId,
        mentions: mentions,
        occurredAt: DateTime.now(),
      ),
    );
  }
}
