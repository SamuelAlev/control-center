import 'dart:async';
import 'dart:typed_data';
import 'package:cc_domain/cc_domain.dart' show WorkspaceMismatchException;
import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/messaging_events.dart';
import 'package:cc_domain/core/domain/ports/embedding_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/services/agent_mention_parser.dart';
import 'package:cc_domain/core/domain/services/user_mention_parser.dart';
import 'package:cc_domain/core/domain/value_objects/entity_ref.dart';
import 'package:cc_domain/core/domain/value_objects/file_reference.dart';
import 'package:cc_domain/core/domain/value_objects/message_attachment.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/output_contract_mode.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/mention_context.dart';
import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/services/mention_wake_policy.dart';
import 'package:cc_domain/features/messaging/domain/services/peer_delegation_guards.dart';
import 'package:cc_domain/features/messaging/domain/services/space_factory.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_kind.dart';
import 'package:cc_harness/context.dart';
import 'package:cc_infra/src/dispatch/agent_dispatch_service.dart';
import 'package:cc_infra/src/dispatch/guided_goal_service.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/messaging/active_stream_registry.dart';
import 'package:cc_infra/src/messaging/agent_responder_resolver.dart';
import 'package:cc_infra/src/messaging/agent_stream_processor.dart';
import 'package:cc_infra/src/messaging/agent_working_directory.dart';
import 'package:cc_infra/src/messaging/conversation_compaction_service.dart';
import 'package:cc_infra/src/messaging/conversation_side_channel_service.dart';
import 'package:cc_infra/src/messaging/conversation_title_service.dart';
import 'package:cc_infra/src/messaging/prompt_attachments.dart';
import 'package:cc_infra/src/messaging/steering_queue_service.dart';

/// Service implementing the [MessagingPort] contract.
class MessagingService implements MessagingPort {
  /// Creates a [MessagingService].
  MessagingService(
    this._repo, {
    AgentRepository? agentRepo,
    ConversationRepository? conversationRepo,
    required AgentDispatchService agentDispatchService,
    required this.streamRegistry,
    required AgentStreamProcessor streamProcessor,
    EmbeddingPort? embeddingPort,
    DomainEventBus? eventBus,
    Future<String?> Function()? resolveDefaultUserId,
    Future<bool> Function(String workspaceId, String spaceId)? dispatchBlocked,
    Future<List<MentionableMember>> Function(String workspaceId)? listMembers,
    Future<String?> Function({
      required String workspaceId,
      required String spaceId,
      required String agentId,
      required String prompt,
      String? conversationId,
      String? requestedByUserId,
    })?
    goalCommandHandler,
    ConversationCompactionService? compactionService,
    ConversationSideChannelService? sideChannelService,
    GuidedGoalService? guidedGoalService,
    ConversationTitleService? titleService,
    PromptAttachmentResolver? promptAttachments,
    Future<void> Function({
      required String workspaceId,
      required String spaceId,
    })?
    cancelProvisioning,
  }) : _agentRepo = agentRepo,
       _promptAttachments = promptAttachments,
       _cancelProvisioning = cancelProvisioning,
       _conversationRepo = conversationRepo,
       _agentDispatchService = agentDispatchService,
       _embeddingPort = embeddingPort,
       _eventBus = eventBus,
       _resolveDefaultUserId = resolveDefaultUserId,
       _dispatchBlocked = dispatchBlocked,
       _listMembers = listMembers,
       _goalCommandHandler = goalCommandHandler,
       _compactionService = compactionService,
       _sideChannelService = sideChannelService,
       _guidedGoalService = guidedGoalService,
       _titleService = titleService,
       _streamProcessor = streamProcessor;

  final MessagingRepository _repo;
  final AgentRepository? _agentRepo;

  /// Gives the human's attachments a body an agent can open — see
  /// [PromptAttachmentResolver]. Null (a host with no blob store, a test)
  /// leaves every `@[file:…]` token as written, which is what happened
  /// everywhere before this existed.
  final PromptAttachmentResolver? _promptAttachments;

  /// Resolves the space's standing conversation for a dispatch that names no
  /// conversation (a ticket, a pipeline step, the chat bridge, a review hub
  /// hand-off). Conversation ids are their own uuids — there is no
  /// space-id aliasing to fall back on, and `conversation_messages.conversation_id`
  /// is a NOT NULL foreign key, so guessing the space id would fail the insert
  /// outright.
  final ConversationRepository? _conversationRepo;

  /// When set, a true answer refuses a dispatch into the space — a human
  /// holds a take-over on its worktree (PRD 16 §8).
  final Future<bool> Function(String workspaceId, String spaceId)?
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
    required String spaceId,
    required String agentId,
    required String prompt,
    String? conversationId,
    String? requestedByUserId,
  })?
  _goalCommandHandler;

  /// Stops a space's in-flight workspace provisioning (the clone). Injected
  /// because the provisioning service lives above this layer; null on a host
  /// that provisions nothing, where cancelling is correctly a no-op.
  final Future<void> Function({
    required String workspaceId,
    required String spaceId,
  })?
  _cancelProvisioning;

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

  @override
  Future<GuidedGoalStepResult> guidedGoalStep({
    required String workspaceId,
    required String rough,
    List<String> transcript = const [],
  }) async {
    final service = _guidedGoalService;
    if (service == null) {
      return const GuidedGoalStepResult(unavailable: true);
    }
    final step = await service.step(
      workspaceId: workspaceId,
      roughObjective: rough,
      transcript: transcript,
    );
    return GuidedGoalStepResult(
      question: step.question,
      objective: step.objective,
      missing: [for (final m in step.missing) m.name],
      weaknesses: step.weaknesses,
      unavailable: step.unavailable,
    );
  }

  /// Backs `/handoff` and `/btw`: one question about the conversation
  /// that never becomes part of it. Null in tests and on hosts with no
  /// one-shot runner — `askAside` then reports `unavailable`.
  final ConversationSideChannelService? _sideChannelService;

  /// Runs the `/goal` objective interview. Null leaves the feature off.
  final GuidedGoalService? _guidedGoalService;

  /// Automatic conversation titling, injected so the human send path can
  /// fire-and-forget a small-model title once the message persists. Null in
  /// tests. Only `sendAndDispatch` (the human chat path) hooks it —
  /// programmatic sends (pipeline steps, the chat bridge) carry configured
  /// conversation titles and never reach that method.
  final ConversationTitleService? _titleService;

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

  /// Resolves the `@mentions` in an agent's own finished turn to the teammates
  /// to wake (exact names only — see [MentionWakePolicy]).
  final _wakePolicy = const MentionWakePolicy();

  /// Depth and cycle caps for a wake chain, shared with the peer/delegation
  /// tools so "how far can one agent reach" has one answer.
  final _wakeGuards = const DelegationGuards();

  /// Backstop for wake chains that are individually legal but repeat: the
  /// cycle guard already makes a loop impossible WITHIN one chain, so this
  /// bounds how often a given ordered pair can restart one.
  final _wakeRateLimiter = PairRateLimiter(
    maxPerWindow: 5,
    window: const Duration(minutes: 5),
  );

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

  /// The conversation a dispatch that named none belongs to: the space's
  /// standing conversation, minted if the space has none yet.
  ///
  /// Returns null only when no [ConversationRepository] is wired (tests) — the
  /// message repository then resolves it itself on write. It NEVER falls back
  /// to the space id: conversations own their uuid since the Space cutover, so
  /// that value names no row and `conversation_messages.conversation_id` is a
  /// NOT NULL foreign key.
  Future<String?> _standingConversationId(
    String workspaceId,
    String spaceId,
  ) async {
    final repo = _conversationRepo;
    if (repo == null) {
      return null;
    }
    final conversation = await repo.ensure(
      workspaceId: workspaceId,
      spaceId: spaceId,
    );
    return conversation.id;
  }

  @override
  Future<String?> createConversation({
    required String workspaceId,
    required String spaceId,
    required String title,
    String? createdByPrincipalId,
    bool reuseExisting = false,
  }) async {
    final repo = _conversationRepo;
    if (repo == null) {
      return null;
    }
    // The space must exist before a conversation row can reference it —
    // `conversations.space_id` is a foreign key, so a stale id would fail the
    // insert rather than return null.
    if (!await _repo.spaceExists(workspaceId, spaceId)) {
      return null;
    }
    if (reuseExisting) {
      // Match on the trimmed title and only against ACTIVE streams: an
      // archived thread was closed deliberately, and reopening it by writing
      // into it would be a stranger decision than opening a fresh one.
      final wanted = title.trim().toLowerCase();
      final siblings = await repo.listForSpace(
        workspaceId: workspaceId,
        spaceId: spaceId,
      );
      for (final c in siblings) {
        if (!c.isArchived &&
            !c.isThread &&
            c.title.trim().toLowerCase() == wanted) {
          return c.id;
        }
      }
    }
    final conversation = await repo.create(
      workspaceId: workspaceId,
      spaceId: spaceId,
      title: title,
      createdByPrincipalId: createdByPrincipalId,
    );
    return conversation.id;
  }

  @override
  Future<Space> createSpace(
    String workspaceId,
    String name,
    List<String> agentIds, {
    Mode mode = Mode.chat,
    String? pipelineRunId,
    String? createdByUserId,
    SpaceKind kind = SpaceKind.topic,
    List<String>? repoIds,
    Map<String, String>? repoBranches,
  }) {
    // Through [SpaceFactory], not `_repo` directly: writing the row and
    // publishing `SpaceCreated` are one operation, and a space created without
    // the event never provisions its checkout.
    return SpaceFactory(repository: _repo, eventBus: _eventBus).create(
      workspaceId,
      name,
      agentIds,
      mode: mode,
      pipelineRunId: pipelineRunId,
      createdByUserId: createdByUserId,
      kind: kind,
      repoIds: repoIds,
      repoBranches: repoBranches,
    );
  }

  @override
  Future<void> cancelSpaceProvisioning(
    String workspaceId,
    String spaceId,
  ) async {
    final cancel = _cancelProvisioning;
    if (cancel == null) {
      return;
    }
    await cancel(workspaceId: workspaceId, spaceId: spaceId);
  }

  @override
  Future<void> sendUserMessage(
    String workspaceId,
    String spaceId,
    String content, {
    String? senderUserId,
    String? conversationId,
    Map<String, dynamic>? metadata,
  }) async {
    // Resolved once and reused: it is both the stored author and — on the
    // event below — what lets a client tell its own operator's message from
    // everyone else's.
    final authorUserId = await _authorUserId(senderUserId);
    final messageId = await _repo.sendMessage(
      workspaceId: workspaceId,
      spaceId: spaceId,
      content: content,
      senderId: authorUserId,
      senderType: 'user',
      metadata: metadata,
      conversationId: conversationId,
    );
    _embedLastMessage(workspaceId, spaceId, content);
    _notifyMessageReceived(
      workspaceId: workspaceId,
      spaceId: spaceId,
      content: content,
      isAgentMessage: false,
      messageId: messageId,
      mentions: _decodeMentionPrincipals(metadata),
      senderUserId: authorUserId,
    );
  }

  /// Fires the (optional) automatic titling pass for a just-persisted human
  /// message. Fire-and-forget by design — a slow or failing model must never
  /// sit on the send path.
  void _maybeGenerateTitle({
    required String workspaceId,
    required String spaceId,
    String? conversationId,
  }) {
    final titleService = _titleService;
    if (titleService == null) {
      return;
    }
    unawaited(
      titleService.maybeGenerate(
        workspaceId: workspaceId,
        spaceId: spaceId,
        conversationId: conversationId,
      ),
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

  void _embedLastMessage(String workspaceId, String spaceId, String content) {
    final port = _embeddingPort;
    if (port == null || !port.isReady || content.isEmpty) {
      return;
    }
    unawaited(
      _repo.getMessages(workspaceId, spaceId).then((messages) async {
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
    String spaceId,
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
    // What the human attached. The composer uploaded the bytes and put
    // `blob:sha256:` references on the metadata; this is where they become
    // something a run can use.
    final attachments = MessageAttachment.attachmentsFromMetadata(metadata);
    // Pictures ride the user turn as images, so the model sees the screenshot
    // and the question together rather than a message that mentions one.
    final promptImageRefs = <String>[
      for (final a in attachments)
        if (a.isImage && a.isUploaded) a.path,
    ];
    final agentRepo = _agentRepo;
    if (agentRepo == null) {
      await sendUserMessage(
        workspaceId,
        spaceId,
        content,
        senderUserId: senderUserId,
        conversationId: conversationId,
        metadata: baseMetadata,
      );
      _maybeGenerateTitle(
        workspaceId: workspaceId,
        spaceId: spaceId,
        conversationId: conversationId,
      );
      return;
    }

    final allAgents = await agentRepo.watchByWorkspace(workspaceId).first;
    if (allAgents.isEmpty) {
      await sendUserMessage(
        workspaceId,
        spaceId,
        content,
        senderUserId: senderUserId,
        conversationId: conversationId,
        metadata: baseMetadata,
      );
      _maybeGenerateTitle(
        workspaceId: workspaceId,
        spaceId: spaceId,
        conversationId: conversationId,
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
        await addAgentToSpace(workspaceId, spaceId, agent.id);
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
      spaceId,
      content,
      senderUserId: senderUserId,
      conversationId: conversationId,
      metadata: mergedMetadata,
    );

    // Automatic titling: one fire-and-forget pass, never on the send path.
    // The service itself is off unless the WORKSPACE has a title model set,
    // and only ever renames conversations still carrying a default title.
    _maybeGenerateTitle(
      workspaceId: workspaceId,
      spaceId: spaceId,
      conversationId: conversationId,
    );

    await dispatchResponderForText(
      workspaceId: workspaceId,
      spaceId: spaceId,
      conversationId: conversationId,
      content: content,
      senderUserId: senderUserId,
      mentionedAgents: mentionedAgents,
      allAgents: allAgents,
      attachments: attachments,
      promptImageRefs: promptImageRefs,
    );
  }

  /// The responder half of a user message: decides which agent(s) should
  /// answer [content] and dispatches them.
  ///
  /// Factored out of [sendAndDispatch] (which calls it after persisting the
  /// message) so the steering queue's run-end conversion can reuse it — its
  /// rows are already persisted by then, so only the dispatch half of a normal
  /// send remains. Behaviour is identical to typing [content] as a fresh
  /// message once the run that queued it has ended.
  Future<void> dispatchResponderForText({
    required String workspaceId,
    required String spaceId,
    String? conversationId,
    required String content,
    String? senderUserId,
    Map<String, Agent> mentionedAgents = const {},
    List<Agent>? allAgents,
    List<MessageAttachment> attachments = const [],
    List<String> promptImageRefs = const [],
  }) async {
    final agentRepo = _agentRepo;
    if (agentRepo == null) {
      return;
    }
    final roster = allAgents ?? await agentRepo.watchByWorkspace(
      workspaceId,
    ).first;
    if (roster.isEmpty) {
      return;
    }

    final priorMessages = await _repo.getMessages(
      workspaceId,
      spaceId,
      conversationId: conversationId,
    );
    final lastMsg = priorMessages.length >= 2
        ? priorMessages[priorMessages.length - 2]
        : null;
    if (lastMsg != null && lastMsg.isPlan && lastMsg.planStatus == 'pending') {
      await refinePlan(
        workspaceId: workspaceId,
        spaceId: spaceId,
        feedback: content,
      );
      return;
    }

    final stripped = _mentionParser.stripMentions(content);
    if (stripped.isEmpty) {
      return;
    }

    // Give every `@[file:…]` token a real path before an agent reads it.
    //
    // The STORED message keeps the token — that is what the transcript renders
    // as a chip, and what a later reader matches back to the attachment strip.
    // The prompt cannot: no adapter has ever heard of a `blob:sha256:`
    // reference, and the sender's own path means nothing on a server that is
    // usually another machine. So the bytes are written into the space's
    // `attachments/` dir and the token is replaced IN PLACE by that file's
    // path, which is the only form every adapter — CLI or built-in harness —
    // can open. A name with nothing behind it is left exactly as typed.
    final promptText = await _withAttachmentPaths(
      workspaceId: workspaceId,
      spaceId: spaceId,
      text: stripped,
      attachments: attachments,
    );

    final Map<String, Agent> targets;
    if (mentionedAgents.isNotEmpty) {
      targets = mentionedAgents;
    } else {
      final participants = await _repo.getParticipants(workspaceId, spaceId);
      final participantAgentIds = participants
          .where((p) => !p.isUser)
          .map((p) => p.principalId)
          .toSet();
      final availableAgents = roster
          .where((a) => participantAgentIds.contains(a.id))
          .toList();

      String? lastAgentSenderId;
      final messages = await _repo.getMessages(
        workspaceId,
        spaceId,
        conversationId: conversationId,
      );
      if (messages.isNotEmpty) {
        final lastAgentMsg = messages.reversed
            .where(
              (m) =>
                  m.senderType == SenderType.agent &&
                  (m.messageType == MessageType.text ||
                      m.messageType == MessageType.agentTurn),
            )
            .firstOrNull;
        lastAgentSenderId = lastAgentMsg?.senderId;
      }

      // The conversation's owner, when it has one: a fan-out opens a stream
      // per agent and records whose it is. Without it, a reply typed into
      // "QA review" before QA had said anything fell through to "the first
      // top-level agent in the space" — which, in a review space holding
      // three reviewers, is a coin toss.
      Agent? owner;
      final ownerId = conversationId == null
          ? null
          : (await _conversationRepo?.getById(
              workspaceId: workspaceId,
              conversationId: conversationId,
            ))?.createdByPrincipalId;
      if (ownerId != null && ownerId.isNotEmpty) {
        owner = roster.where((a) => a.id == ownerId).firstOrNull;
      }

      final agent = AgentResponderResolver.resolveDefault(
        agents: availableAgents,
        lastAgentSenderId: lastAgentSenderId,
        leadHint: owner,
      );
      targets = agent != null ? {agent.id: agent} : {};
    }

    for (final agent in targets.values) {
      unawaited(
        dispatchAgent(
          workspaceId: workspaceId,
          spaceId: spaceId,
          agentId: agent.id,
          prompt: promptText,
          // The human whose message triggered these runs: their git identity
          // co-authors the agents' commits and their own GitHub token (when
          // stored) backs the runs.
          requestedByUserId: senderUserId,
          conversationId: conversationId,
          promptImageRefs: promptImageRefs,
        ),
      );
    }
  }

  /// [text] with every `@[file:<name>]` reference replaced by the path the
  /// named attachment was materialized to.
  ///
  /// Returns [text] untouched when nothing is attached, when no resolver is
  /// wired, or when the resolver fails — a run that answers about a picture it
  /// cannot open is a worse outcome than one that never starts, but only
  /// slightly, and a thrown exception here would take the whole turn.
  Future<String> _withAttachmentPaths({
    required String workspaceId,
    required String spaceId,
    required String text,
    required List<MessageAttachment> attachments,
  }) async {
    final resolver = _promptAttachments;
    if (resolver == null || attachments.isEmpty || !text.contains('@[file:')) {
      return text;
    }
    Map<String, String> paths;
    try {
      paths = await resolver(
        workspaceId: workspaceId,
        spaceId: spaceId,
        attachments: attachments,
      );
    } on Object catch (e) {
      CcInfraLog.warning('Attachment materialization failed for $spaceId: $e');
      return text;
    }
    return paths.isEmpty ? text : expandFileRefs(text, (name) => paths[name]);
  }

  @override
  Future<void> addAgentToSpace(
    String workspaceId,
    String spaceId,
    String agentId, {
    bool renameForGroup = true,
  }) async {
    final participants = await _repo.getParticipants(workspaceId, spaceId);
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
        await _repo.updateSpaceName(workspaceId, spaceId, groupName);
      }
    }

    await _repo.addParticipant(workspaceId, spaceId, agentId);

    final agent = await _agentRepo?.getById(workspaceId, agentId);
    final name = agent?.name ?? agentId;

    await _repo.sendMessage(
      workspaceId: workspaceId,
      spaceId: spaceId,
      content: '$name joined the space',
      senderId: 'system',
      senderType: 'agent',
      messageType: 'system',
    );
  }

  @override
  Future<bool> spaceExists(String workspaceId, String spaceId) =>
      _repo.spaceExists(workspaceId, spaceId);

  /// Posts a system message into the space — senderId 'system', senderType
  /// 'agent', messageType 'system', the same shape as the take-over refusal.
  /// Used by the goal supervisor to narrate goal lifecycle events.
  Future<void> postSystemMessage(
    String workspaceId,
    String spaceId,
    String content, {
    String? conversationId,
  }) => _repo.sendMessage(
    workspaceId: workspaceId,
    spaceId: spaceId,
    content: content,
    senderId: 'system',
    senderType: 'agent',
    messageType: 'system',
    conversationId: conversationId,
  );

  @override
  Future<void> refinePlan({
    required String workspaceId,
    required String spaceId,
    required String feedback,
  }) async {
    final messages = await _repo.getMessages(workspaceId, spaceId);
    final pendingPlan = messages.reversed.firstWhere(
      (m) => m.isPlan && m.planStatus == 'pending',
      orElse: () => messages.reversed.firstWhere(
        (m) => m.isPlan,
        orElse: () => throw StateError('No plan found in space $spaceId'),
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
      spaceId,
      feedback,
      conversationId: conversationId,
    );

    final agent = await _agentRepo?.getById(workspaceId, pendingPlan.senderId);
    if (agent != null) {
      unawaited(
        dispatchAgent(
          workspaceId: workspaceId,
          spaceId: spaceId,
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
    required String spaceId,
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
    List<String> promptImageRefs = const [],
    String? modelOverride,
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
          spaceId: spaceId,
          agentId: agentId,
          prompt: prompt,
          conversationId: conversationId,
          requestedByUserId: requestedByUserId,
        );
      }
    }
    return dispatchAgentRun(
      workspaceId: workspaceId,
      spaceId: spaceId,
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
      promptImageRefs: promptImageRefs,
      modelOverride: modelOverride,
    );
  }

  /// The plain agent dispatch with no goal-command interception. This is the
  /// goal supervisor's dispatcher target: its first run re-sends the verbatim
  /// `/goal ...` prompt and must never loop back into the command handler.
  ///
  /// [mentionChain] is the ordered list of agents whose `@mentions` led to this
  /// run, oldest first and NOT including [agentId]. Empty for a run a human (or
  /// a ticket, pipeline or tool) started. It is what makes the wake chain's
  /// depth and cycle guards enforceable at a chokepoint: without it, A→B→A is
  /// indistinguishable from two unrelated dispatches. It rides in memory only —
  /// a chain never outlives the process that is executing it.
  Future<String?> dispatchAgentRun({
    required String workspaceId,
    required String spaceId,
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
    List<String> mentionChain = const [],
    List<String> promptImageRefs = const [],
    String? modelOverride,
  }) async {
    if (prompt.isEmpty) {
      return null;
    }
    // The conversation (stream) this run belongs to. A caller that names none
    // (a ticket, a pipeline step, the chat bridge) lands in the space's
    // standing conversation — resolved, never guessed: conversation ids are
    // their own uuids since the Space cutover, so the old `?? spaceId`
    // aliasing now points at a row that does not exist. The run only ever sees
    // this conversation's history and its turn is posted back into it.
    final convId =
        conversationId ?? await _standingConversationId(workspaceId, spaceId);

    // Take-over gate: while a human holds the conversation's worktree, no
    // agent may be dispatched into it — resuming into a half-finished human
    // edit silently corrupts the run (PRD 16 §8). Loud, never a silent no-op.
    final blocked = _dispatchBlocked;
    if (blocked != null && await blocked(workspaceId, spaceId)) {
      await _repo.sendMessage(
        workspaceId: workspaceId,
        spaceId: spaceId,
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
    // Build the mention context so the agent knows who's in the space —
    // both agent teammates and human members (PRD 16 §15: principals).
    MentionContext? mentionContext;
    final roster = <MentionRosterEntry>[];
    try {
      final participants = await _repo.getParticipants(workspaceId, spaceId);
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
        // Who actually summoned this turn. An agent-authored `@mention` names
        // the mentioning AGENT — attributing its wake to the human who happens
        // to own the run told the woken agent to answer the wrong party.
        summonedBy: inReplyToAgentName ?? requestedByUserId ?? 'user',
        spaceRoster: roster,
      );
    }

    final result = await _agentDispatchService.dispatch(
      agentId: agentId,
      prompt: prompt,
      workingDirectory: workingDirectory,
      adapterId: adapterId,
      workspaceId: workspaceId,
      conversationId: convId,
      spaceId: spaceId,
      ticketId: ticketId,
      pipelineRunId: pipelineRunId,
      pipelineStepId: pipelineStepId,
      requestedByUserId: requestedByUserId,
      expectedOutputSchema: expectedOutputSchema,
      outputContractMode: outputContractMode,
      wakeContext: wakeContext,
      mentionContext: mentionContext,
      costCapCents: costCapCents,
      promptImageRefs: promptImageRefs,
      modelOverride: modelOverride,
    );

    final messageId = result.runLog.id;

    streamRegistry.register(messageId, spaceId: spaceId);

    await _repo.sendMessage(
      workspaceId: workspaceId,
      spaceId: spaceId,
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
      spaceId: spaceId,
      agentId: agentId,
      agentName: agentName,
      messageId: messageId,
      workingDirectory: workingDirectory,
      // Threaded onto the completed turn's `MessageReceived` notification
      // (PRD 16 §7) so a notification receiver can tell "my run" from
      // "someone else's run" and suppress the latter.
      requestedByUserId: requestedByUserId,
      onTurnCompleted: (content) => _wakeMentionedAgents(
        workspaceId: workspaceId,
        spaceId: spaceId,
        conversationId: convId,
        senderAgentId: agentId,
        senderAgentName: agentName,
        content: content,
        chain: mentionChain,
        requestedByUserId: requestedByUserId,
      ),
    );

    return messageId;
  }

  /// How much of the mentioning turn the woken agent receives as its prompt.
  /// The full text stays in the conversation, which the woken agent also reads
  /// as history, so this only bounds the summons itself.
  static const int _wakePromptMaxChars = 4000;

  /// Wakes the teammates an agent named in its OWN finished turn ("@architect
  /// can you weigh in?").
  ///
  /// The prompt's Summons block promises this, so it is honoured here at a
  /// chokepoint rather than left as inert prose — an unkept promise made every
  /// handoff an agent believed it had performed silently vanish.
  ///
  /// What bounds it (none of it by prompt instruction):
  ///
  /// * **What counts as a mention** — [AgentMentionParser.parseProseMentions]:
  ///   never inside code, never an address or a version pin.
  /// * **Who it resolves to** — [MentionWakePolicy]: exact name, no prefix
  ///   match, ambiguity resolves to nobody, self-mentions do nothing.
  /// * **How far it can travel** — [DelegationGuards] depth and cycle checks
  ///   over [chain]. Autonomy and budget are NOT checked here: this path mints
  ///   no new authority and inherits the run's own envelope, unlike
  ///   `delegate_task`, which can hand work to a differently-scoped agent.
  /// * **How often** — [PairRateLimiter], per ordered pair.
  ///
  /// Best-effort throughout: the turn that produced the mention is already
  /// persisted and completed, so nothing here may throw back into it.
  Future<void> _wakeMentionedAgents({
    required String workspaceId,
    required String spaceId,
    required String? conversationId,
    required String senderAgentId,
    required String senderAgentName,
    required String content,
    required List<String> chain,
    required String? requestedByUserId,
  }) async {
    try {
      final agentRepo = _agentRepo;
      if (agentRepo == null) {
        return;
      }
      final tokens = _mentionParser.parseProseMentions(content);
      if (tokens.isEmpty) {
        return;
      }

      final candidates = await agentRepo.watchByWorkspace(workspaceId).first;
      final targets = _wakePolicy.resolveTargets(
        tokens: tokens,
        candidates: candidates,
        selfAgentId: senderAgentId,
      );
      // An unresolved token is prose, not a failed mention: agents write "@" in
      // sentences all the time, and narrating every one of them would turn the
      // space into a nag. A REFUSED wake is different — that one names a real
      // teammate we deliberately declined to reach, so it is reported below.
      if (targets.isEmpty) {
        return;
      }

      // The chain the woken agents inherit: everyone on this wake path, the
      // agent that just spoke last.
      final chainSoFar = [...chain, senderAgentId];
      final refusals = <String>[];

      final depth = _wakeGuards.checkDepth(chain.length);
      if (!depth.allowed) {
        await _postWakeRefusals(workspaceId, spaceId, conversationId, [
          '${depth.refusal} No agent was woken by this turn.',
        ]);
        return;
      }

      final now = DateTime.now();
      for (final target in targets) {
        final cycle = _wakeGuards.checkCycle(chainSoFar, target.agent.id);
        if (!cycle.allowed) {
          refusals.add('@${target.agent.name}: ${cycle.refusal}');
          continue;
        }
        if (!_wakeRateLimiter.tryAcquire(senderAgentId, target.agent.id, now)) {
          refusals.add(
            '@${target.agent.name}: rate limited — $senderAgentName has woken '
            'it too many times in a short window.',
          );
          continue;
        }

        await addAgentToSpace(workspaceId, spaceId, target.agent.id);
        unawaited(
          dispatchAgentRun(
            workspaceId: workspaceId,
            spaceId: spaceId,
            agentId: target.agent.id,
            prompt: _wakePrompt(senderAgentName, content),
            conversationId: conversationId,
            // Attributes the woken turn to the agent that summoned it, which
            // is also what the woken agent's own Summons block reads.
            inReplyToAgentId: senderAgentId,
            // The human behind the original run stays the acting user, so the
            // woken agent commits under the same identity and token.
            requestedByUserId: requestedByUserId,
            mentionChain: chainSoFar,
          ),
        );
      }

      await _postWakeRefusals(workspaceId, spaceId, conversationId, refusals);
    } catch (_) {
      // A wake is a courtesy on top of a turn that already succeeded.
    }
  }

  /// The prompt a woken agent receives: the mentioning turn, attributed.
  String _wakePrompt(String fromName, String content) {
    final body = content.length <= _wakePromptMaxChars
        ? content
        : '${content.substring(0, _wakePromptMaxChars)}\n'
              '…(truncated — the full turn is in this conversation)';
    return '$fromName mentioned you in this conversation:\n\n$body';
  }

  /// Posts refused wakes as one system message. A guard that declines silently
  /// is indistinguishable from the bug this feature exists to fix.
  Future<void> _postWakeRefusals(
    String workspaceId,
    String spaceId,
    String? conversationId,
    List<String> refusals,
  ) async {
    if (refusals.isEmpty) {
      return;
    }
    await _repo.sendMessage(
      workspaceId: workspaceId,
      spaceId: spaceId,
      content: refusals.length == 1
          ? 'Mention not delivered — ${refusals.single}'
          : 'Mentions not delivered:\n${refusals.map((r) => '• $r').join('\n')}',
      senderId: 'system',
      senderType: 'agent',
      messageType: 'system',
      conversationId: conversationId,
    );
  }

  @override
  Future<void> retryAgentTurn({
    required String workspaceId,
    required String spaceId,
    required String failedMessageId,
    String? modelOverride,
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
    //  * no `conversationId` ⇒ the retry lands in the space's standing
    //    conversation even when the failed turn belonged to a side one.
    // What went wrong is worth telling the retry, so it can do something
    // different rather than repeat the same approach and fail the same way.
    final failure = (failed.metadata?['errorMessage'] as String?)?.trim();
    await dispatchAgent(
      workspaceId: workspaceId,
      spaceId: spaceId,
      agentId: agentId,
      prompt:
          'Your previous attempt in this space failed before finishing'
          '${failure == null || failure.isEmpty ? '' : ': $failure'}. '
          'Review the conversation above and re-attempt the task. If the '
          'previous approach is what failed, try a different one rather than '
          'repeating it.',
      conversationId: failed.conversationId,
      modelOverride: modelOverride,
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

  /// The durable steering queue, wired by the runtime after construction
  /// (the queue service needs this service's dispatch tail, so the dependency
  /// cannot run the other way at build time). Null only in tests that never
  /// touch the queue surface — the methods below then answer "nothing
  /// queued / not deliverable".
  SteeringQueueService? steeringQueueService;

  /// Queues a persisted steering message against the conversation's live runs
  /// (see [SteeringQueueService.enqueue] for the full contract).
  @override
  Future<({String messageId, bool steerable})?> enqueueSteering({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    required String content,
  }) async {
    final result = await steeringQueueService?.enqueue(
      workspaceId: workspaceId,
      spaceId: spaceId,
      conversationId: conversationId,
      content: content,
      senderUserId: await _authorUserId(null),
    );
    return result == null
        ? null
        : (messageId: result.messageId, steerable: result.steerable);
  }

  @override
  Future<bool> editSteering({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    required String messageId,
    required String content,
  }) async => await steeringQueueService?.edit(
        workspaceId: workspaceId,
        conversationId: conversationId,
        messageId: messageId,
        content: content,
      ) ??
      false;

  @override
  Future<bool> deleteSteering({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    required String messageId,
  }) async => await steeringQueueService?.delete(
        workspaceId: workspaceId,
        conversationId: conversationId,
        messageId: messageId,
      ) ??
      false;

  @override
  Future<void> reorderSteering({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    required List<String> orderedIds,
  }) async => await steeringQueueService?.reorder(
    workspaceId: workspaceId,
    conversationId: conversationId,
    orderedIds: orderedIds,
  );

  @override
  Future<bool> deliverSteering({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    required String messageId,
  }) async => await steeringQueueService?.deliver(
        workspaceId: workspaceId,
        conversationId: conversationId,
        messageId: messageId,
      ) ??
      false;

  /// Fallback character budget when the space's agent has no configured
  /// `contextSize` (mirrors the client meter's default; the window only feeds
  /// the pressure gate, which a forced compaction skips anyway).
  static const int _defaultContextChars = 1000000;

  /// Forces an anchored-compaction pass over the conversation (`/compact`).
  /// Refuses while a turn is streaming in the space — the prune pass
  /// read-modify-writes transcript metadata and would race the live turn's
  /// writes (a lost update on the in-flight message).
  @override
  @override
  Future<ConversationSideChannelResult> askAside({
    required String workspaceId,
    required String spaceId,
    String? conversationId,
    required String kind,
    String input = '',
  }) async {
    final service = _sideChannelService;
    if (service == null) {
      return const ConversationSideChannelResult(unavailable: true);
    }
    // Same isolation check as compaction: the op proves the SPACE is ours, not
    // that a client-supplied conversation id belongs to it.
    if (conversationId != null && conversationId != spaceId) {
      final scoped = await _repo.getMessages(
        workspaceId,
        spaceId,
        conversationId: conversationId,
      );
      if (scoped.any((m) => m.spaceId != spaceId)) {
        throw const WorkspaceMismatchException(
          'Conversation belongs to a different space.',
        );
      }
    }
    final result = kind == 'handoff'
        ? await service.handoff(
            workspaceId: workspaceId,
            spaceId: spaceId,
            conversationId: conversationId,
            focus: input,
          )
        : await service.aside(
            workspaceId: workspaceId,
            spaceId: spaceId,
            conversationId: conversationId,
            question: input,
          );
    return ConversationSideChannelResult(
      text: result.text,
      unavailable: result.unavailable,
      empty: result.empty,
    );
  }

  @override
  Future<ConversationShakeResult> shakeConversation({
    required String workspaceId,
    required String spaceId,
    String? conversationId,
    String target = 'tool_output',
  }) async {
    final service = _compactionService;
    if (service == null) {
      return const ConversationShakeResult(unavailable: true);
    }
    // Same race as compaction: rewriting transcript segments while a turn is
    // streaming would fight the live writes.
    if (streamRegistry.activeIn(spaceId).isNotEmpty) {
      return const ConversationShakeResult();
    }
    // Same isolation check as compaction: the op proves the SPACE is ours,
    // not that a client-supplied conversation id belongs to it.
    if (conversationId != null && conversationId != spaceId) {
      final scoped = await _repo.getMessages(
        workspaceId,
        spaceId,
        conversationId: conversationId,
      );
      if (scoped.any((m) => m.spaceId != spaceId)) {
        throw const WorkspaceMismatchException(
          'Conversation belongs to a different space.',
        );
      }
    }
    final outcome = await service.shake(
      workspaceId: workspaceId,
      spaceId: spaceId,
      conversationId: conversationId,
      target: switch (target) {
        'images' => ShakeTarget.images,
        'all' => ShakeTarget.all,
        _ => ShakeTarget.toolOutput,
      },
    );
    return ConversationShakeResult(
      tokensReclaimed: outcome.tokensReclaimed,
      messagesTouched: outcome.messagesTouched,
      imagesDropped: outcome.imagesDropped,
    );
  }

  @override
  Future<ConversationCompactionResult> compactConversation({
    required String workspaceId,
    required String spaceId,
    String? conversationId,
  }) async {
    final service = _compactionService;
    if (service == null) {
      return const ConversationCompactionResult(
        status: ConversationCompactionStatus.unavailable,
      );
    }
    if (streamRegistry.activeIn(spaceId).isNotEmpty) {
      return const ConversationCompactionResult(
        status: ConversationCompactionStatus.agentBusy,
      );
    }
    // `conversation_id` arrives from the client and the DAO filters messages
    // by conversation alone — the op's space-ownership check proves nothing
    // about a foreign conversation id. Deny loudly unless the conversation
    // provably belongs to this space, BEFORE anything is mutated. (An empty
    // conversation can't prove ownership either way, but `maintain` no-ops on
    // empty history, so nothing can be mutated through that path.)
    if (conversationId != null && conversationId != spaceId) {
      final scoped = await _repo.getMessages(
        workspaceId,
        spaceId,
        conversationId: conversationId,
      );
      if (scoped.any((m) => m.spaceId != spaceId)) {
        throw const WorkspaceMismatchException(
          'Conversation belongs to a different space.',
        );
      }
    }
    // Window + turn label come from the space's agent when it is
    // unambiguous (a DM); multi-agent rooms fall back to the defaults.
    Agent? agent;
    final participants = await _repo.getParticipants(workspaceId, spaceId);
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
      spaceId: spaceId,
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

  /// Deletes a space and publishes a deletion event.
  @override
  Future<void> deleteSpace(String workspaceId, String spaceId) async {
    await _repo.deleteSpace(workspaceId, spaceId);
    // Let listeners (e.g. the worktree GC) tear down per-conversation resources.
    _eventBus?.publish(
      SpaceDeleted(
        spaceId: spaceId,
        workspaceId: workspaceId,
        occurredAt: DateTime.now(),
      ),
    );
  }

  /// Archives a space. No [SpaceDeleted]: archiving is a reversible hide, so
  /// nothing (worktree GC, retention sweeps) may tear the space's resources
  /// down — restore expects them all intact.
  @override
  Future<void> archiveSpace(String workspaceId, String spaceId) =>
      _repo.archiveSpace(workspaceId, spaceId);

  /// Restores an archived space.
  @override
  Future<void> unarchiveSpace(String workspaceId, String spaceId) =>
      _repo.unarchiveSpace(workspaceId, spaceId);

  /// Updates the name of a space.
  @override
  Future<void> updateSpaceName(
    String workspaceId,
    String spaceId,
    String name,
  ) => _repo.updateSpaceName(workspaceId, spaceId, name);

  /// The space's effective repo selection (null → all repos, empty → none).
  @override
  Future<List<String>?> getSpaceRepos(String workspaceId, String spaceId) =>
      _repo.spaceRepoSelection(workspaceId, spaceId);

  /// Replaces the space's repo selection. Neither half of the worktree work is
  /// this service's job — the RPC op (`messaging.setSpaceRepos`) drives the
  /// provisioner's `releaseSpaceReposOutside` for deselected repos AND the
  /// re-provision that checks out newly selected ones, alongside this write.
  @override
  Future<void> setSpaceRepos(
    String workspaceId,
    String spaceId,
    List<String>? repoIds,
  ) => _repo.setSpaceRepos(workspaceId, spaceId, repoIds);

  /// Clears all messages in a space.
  @override
  Future<void> clearSpaceMessages(String workspaceId, String spaceId) =>
      _repo.clearSpaceMessages(workspaceId, spaceId);

  /// Removes a participant from a space.
  @override
  Future<void> removeParticipant(
    String workspaceId,
    String spaceId,
    String agentId,
  ) => _repo.removeParticipant(workspaceId, spaceId, agentId);

  void _notifyMessageReceived({
    required String workspaceId,
    required String spaceId,
    required String content,
    required bool isAgentMessage,
    String messageId = '',
    String senderName = 'You',
    List<Principal> mentions = const [],
    String? senderUserId,
  }) {
    final bus = _eventBus;
    if (bus == null) {
      return;
    }

    final preview = content.length > 120
        ? '${content.substring(0, 120)}…'
        : content;

    // A human mention (PRD 16 §15) DOES notify (PRD 16 §7) even though the
    // sender is human and the workspace scopes + deep-links that notification
    // exactly like an agent-message one. Un-mentioned human messages raise no
    // notification at all (the mapper drops them), so the workspace is simply
    // carried along for both.
    bus.publish(
      MessageReceived(
        spaceId: spaceId,
        messageId: messageId,
        senderName: senderName,
        contentPreview: preview,
        isAgentMessage: isAgentMessage,
        workspaceId: workspaceId,
        mentions: mentions,
        senderUserId: senderUserId,
        occurredAt: DateTime.now(),
      ),
    );
  }
}
