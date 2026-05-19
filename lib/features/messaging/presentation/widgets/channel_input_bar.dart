import 'package:cc_domain/cc_domain.dart' show UserDto, WorkspaceMemberDto;
import 'package:cc_domain/core/domain/value_objects/entity_ref.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/channel_provisioning_status.dart';
import 'package:cc_domain/features/pr_review/domain/entities/enriched_pull_request.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_harness/slash_command.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/meetings/providers/meeting_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/mode_dropdown.dart';
import 'package:control_center/features/messaging/presentation/widgets/mode_enforcement_badge.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/messaging/providers/pending_channel_sends_provider.dart';
import 'package:control_center/features/messaging/providers/repo_file_search_provider.dart';
import 'package:control_center/features/pr_review/providers/pr_list_providers.dart';
import 'package:control_center/features/presence/providers/presence_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/skills_settings.dart'
    show SkillInfo, skillListProvider;
import 'package:control_center/features/ticketing/providers/ticketing_providers.dart';
import 'package:control_center/features/todos/providers/todo_command_controller.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_scope.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/composer/composer.dart';
import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:control_center/shared/widgets/composer/mention/mention_source.dart';
import 'package:control_center/shared/widgets/composer/mention/sources/agent_mention_source.dart';
import 'package:control_center/shared/widgets/composer/mention/sources/channel_mention_source.dart';
import 'package:control_center/shared/widgets/composer/mention/sources/file_mention_source.dart';
import 'package:control_center/shared/widgets/composer/mention/sources/meeting_mention_source.dart';
import 'package:control_center/shared/widgets/composer/mention/sources/pr_mention_source.dart';
import 'package:control_center/shared/widgets/composer/mention/sources/scratchpad_mention_source.dart';
import 'package:control_center/shared/widgets/composer/mention/sources/slash_command_source.dart';
import 'package:control_center/shared/widgets/composer/mention/sources/ticket_mention_source.dart';
import 'package:control_center/shared/widgets/composer/mention/sources/user_mention_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notifier that sends channel messages via the use case.
class ChannelMessageSendNotifier extends Notifier<void> {
  @override
  void build() {}

  /// Sends a message and dispatches agents.
  Future<void> send({
    required String content,
    required String channelId,
    required String workspaceId,
    String? conversationId,
    List<StructuredMention>? structuredMentions,
    List<EntityRef>? entityRefs,
  }) async {
    if (content.isEmpty) {
      return;
    }
    final useCase = ref.read(sendChannelMessageUseCaseProvider);
    await useCase.execute(
      content: content,
      channelId: channelId,
      workspaceId: workspaceId,
      conversationId: conversationId,
      structuredMentions: structuredMentions,
      entityRefs: entityRefs,
    );
  }
}

/// Builds a short, space-free `#` reference token for an entity. Prefers a
/// natural key (e.g. a Linear ticket key), else a slug of [fallbackText], else
/// a short id. The real entity id always travels in the mention payload, so
/// this token is purely cosmetic inline text.
String entityMentionToken(String? preferred, String fallbackText, String id) {
  final key = preferred?.trim() ?? '';
  if (key.isNotEmpty) {
    return key.replaceAll(RegExp(r'\s+'), '-');
  }
  final slug = fallbackText
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'(^-+)|(-+$)'), '');
  if (slug.isNotEmpty) {
    return slug.length > 24 ? slug.substring(0, 24) : slug;
  }
  return id.length > 8 ? id.substring(0, 8) : id;
}

/// Assembles the full mention-source list for a messaging composer (channel
/// input bar and thread reply bar share this so they never drift). `@` sources
/// (agents/channels/files/scratchpad) plus `#` entity sources (tickets/PRs/
/// meetings), all fed workspace-scoped data resolved here so the shared
/// composer never depends on feature providers.
///
/// PR autocomplete watches the workspace's PR list (`prsByRepoProvider`, which
/// is keepAlive, batched, and shared with the PR list screen); tickets and
/// meetings are cheap local streams.
List<MentionSource> buildMessagingMentionSources(
  WidgetRef ref,
  String? workspaceId,
) {
  final agents = workspaceId != null
      ? ref.watch(workspaceAgentsProvider(workspaceId)).value ?? const []
      : ref.watch(agentsProvider).value ?? const [];
  // Human `@mention` roster (PRD 16 §15): the workspace's members joined
  // against the live user directory for handle + display name.
  final Map<String, UserDto> usersById =
      ref.watch(usersByIdProvider).value ?? const {};
  final List<UserMentionItem> memberMentionItems = workspaceId == null
      ? const []
      : [
          for (final WorkspaceMemberDto m
              in ref.watch(workspaceMembersProvider(workspaceId)).value ??
                  const <WorkspaceMemberDto>[])
            if (usersById[m.userId] case final user?)
              UserMentionItem(
                id: user.id,
                handle: user.handle,
                displayName: user.displayName,
              ),
        ];
  final channels = workspaceId != null
      ? ref.watch(workspaceChannelsProvider(workspaceId)).value ?? const []
      : ref.watch(channelsProvider).value ?? const [];
  // File mentions search on the SERVER (`repos.searchFiles` — fff over the
  // checkouts cc_server owns), so desktop, web and phone behave identically and
  // no client ever loads a native searcher.
  final fileSearch = ref.watch(repoFileSearchFnProvider);
  final MentionSource? fileMentionSource = workspaceId == null
      ? null
      : FileMentionSource(
          search: (query) async {
            final hits = await fileSearch(workspaceId, query);
            return [for (final h in hits) h.hit];
          },
        );
  final List<Ticket> ticketRows = workspaceId == null
      ? const []
      : ref.watch(workspaceTicketsProvider(workspaceId)).value ?? const [];
  final List<Meeting> meetingRows = workspaceId == null
      ? const []
      : ref.watch(meetingsProvider(workspaceId)).value ?? const [];
  final List<RepoPullRequests> prGroups =
      ref.watch(prsByRepoProvider).value?.repos ?? const [];
  final skills = workspaceId == null
      ? const <SkillInfo>[]
      : ref.watch(skillListProvider(workspaceId)).value ?? const <SkillInfo>[];

  return <MentionSource>[
    AgentMentionSource(agents),
    if (memberMentionItems.isNotEmpty) UserMentionSource(memberMentionItems),
    ChannelMentionSource([
      for (final c in channels) ChannelMentionItem(id: c.id, name: c.name),
    ]),
    if (workspaceId != null) ScratchpadMentionSource(workspaceId: workspaceId),
    ?fileMentionSource,
    if (ticketRows.isNotEmpty)
      TicketMentionSource([
        for (final t in ticketRows)
          TicketMentionItem(
            id: t.id,
            token: entityMentionToken(t.externalKey, t.title, t.id),
            title: t.title,
          ),
      ]),
    if (prGroups.isNotEmpty)
      PrMentionSource([
        for (final g in prGroups)
          for (final pr in g.prs)
            PrMentionItem(
              number: pr.number,
              repoFullName: '${g.repo.githubOwner}/${g.repo.githubRepoName}',
              title: pr.title,
            ),
      ]),
    if (meetingRows.isNotEmpty)
      MeetingMentionSource([
        for (final m in meetingRows)
          MeetingMentionItem(
            id: m.id,
            token: entityMentionToken(null, m.title, m.id),
            title: m.title,
          ),
      ]),
    SlashCommandSource([
      const SlashCommand(
        name: 'plan',
        description: 'Switch to plan mode (read-only research, typed plan)',
      ),
      const SlashCommand(
        name: 'goal',
        description: 'Work toward a goal until it is done',
      ),
      const SlashCommand(
        name: 'loop',
        description: 'Iterate on a task until complete',
      ),
      const SlashCommand(
        name: 'compact',
        description: 'Compact the conversation history and continue',
      ),
      // `/todo` and its subcommands manage this conversation's persisted todo
      // list locally (they never reach the agent). The mention system is flat,
      // so each subcommand is advertised as its own entry.
      const SlashCommand(
        name: 'todo',
        description: 'View and edit the conversation todo list',
      ),
      const SlashCommand(name: 'todo append', description: 'Add a todo item'),
      const SlashCommand(
        name: 'todo start',
        description: 'Mark a todo as in progress',
      ),
      const SlashCommand(name: 'todo done', description: 'Mark a todo as done'),
      const SlashCommand(
        name: 'todo drop',
        description: 'Remove a todo (or clear the list)',
      ),
      const SlashCommand(
        name: 'todo edit',
        description: 'Open the todo editor',
      ),
      const SlashCommand(
        name: 'todo copy',
        description: 'Copy the todo list as markdown',
      ),
      const SlashCommand(
        name: 'todo export',
        description: 'Export the todo list as markdown',
      ),
      const SlashCommand(
        name: 'todo import',
        description: 'Import a markdown checklist',
      ),
      for (final s in skills)
        SlashCommand(
          name: s.name,
          description: s.description.isEmpty ? 'Skill' : s.description,
        ),
    ]),
  ];
}

/// Maps composer `#` entity mentions (ticket/pr/meeting) into [EntityRef]s,
/// de-duplicated by (type, id). Other mention kinds are ignored.
List<EntityRef> entityRefsFromMentions(List<ResolvedMention> mentions) {
  final out = <String, EntityRef>{};
  for (final m in mentions) {
    final EntityRef? ref = switch (m.kind) {
      'ticket' when m.payload?['ticketId'] is String => EntityRef(
        type: EntityRefType.ticket,
        id: m.payload!['ticketId'] as String,
        label: m.payload?['label'] as String?,
      ),
      'pr' when m.payload?['number'] != null => EntityRef(
        type: EntityRefType.pullRequest,
        id: '${m.payload!['number']}',
        label: m.payload?['label'] as String?,
        repoFullName: m.payload?['repoFullName'] as String?,
      ),
      'meeting' when m.payload?['meetingId'] is String => EntityRef(
        type: EntityRefType.meeting,
        id: m.payload!['meetingId'] as String,
        label: m.payload?['label'] as String?,
      ),
      _ => null,
    };
    if (ref != null) {
      out['${ref.type}:${ref.id}'] = ref;
    }
  }
  return out.values.toList(growable: false);
}

/// Provider for the channel message send notifier.
final channelMessageSendProvider =
    NotifierProvider<ChannelMessageSendNotifier, void>(
      ChannelMessageSendNotifier.new,
    );

/// Composer bar with mode selector for sending channel messages.
class ChannelInputBar extends ConsumerStatefulWidget {
  /// Creates a [ChannelInputBar].
  const ChannelInputBar({
    super.key,
    required this.channelId,
    this.conversationId,
  });

  /// The channel ID this bar sends to.
  final String channelId;

  /// The conversation (stream) inside the channel this bar sends to. Null ⇒
  /// the channel's `main` conversation (== channel id).
  final String? conversationId;

  @override
  ConsumerState<ChannelInputBar> createState() => _ChannelInputBarState();
}

class _ChannelInputBarState extends ConsumerState<ChannelInputBar> {
  late final TextEditingController _controller;
  // Captured once (not re-read via `ref` in dispose): `ref.read`/`ref.watch`
  // are unsafe once this widget's own element is unmounting, but calling a
  // plain method on an already-resolved notifier instance is not — it never
  // touches this widget's `ref`/`BuildContext`.
  late final MyPresenceNotifier _presence;

  @override
  void initState() {
    super.initState();
    _presence = ref.read(myPresenceProvider.notifier);
    _controller = TextEditingController()..addListener(_onDraftChanged);
  }

  @override
  void dispose() {
    // Leaving the composer (channel switch/unmount) clears any "typing"
    // presence for this channel rather than waiting out the 5s timer.
    _presence.setTyping(null);
    _controller.removeListener(_onDraftChanged);
    _controller.dispose();
    super.dispose();
  }

  /// Typing presence (PRD 16 §1): a non-empty draft in this channel publishes
  /// `typingInChannelId`. The composer clears its own text on submit (see
  /// [Composer]), which fires this same listener and clears it again — no
  /// separate "clear on send" wiring needed.
  void _onDraftChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    _presence.setTyping(hasText ? widget.channelId : null);
  }

  @override
  Widget build(BuildContext context) {
    final channelId = widget.channelId;
    // The conversation (stream) this composer belongs to; null ⇒ the channel's
    // `main` conversation (== channel id), the same defaulting the server does.
    final conversationId = widget.conversationId ?? channelId;
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final l10n = AppLocalizations.of(context);
    final sources = buildMessagingMentionSources(ref, workspaceId);
    final currentMode = ref.watch(activeChannelModeProvider);

    // Live agent runs in THIS conversation — a run log id equals its agent
    // turn's message id. Drives the composer's stop affordance: while any agent
    // is working, the send button becomes a stop button (when the input is
    // empty). Keyed by the pane's conversation, not the channel: a composer in a
    // parenthesis that watched `main` showed no "running" state for the runs
    // right above it (so no stop button) and would have stopped somebody else's.
    final activeRunIds = workspaceId == null
        ? const <String>[]
        : (ref
                  .watch(
                    conversationActiveRunsProvider((
                      workspaceId: workspaceId,
                      conversationId: conversationId,
                    )),
                  )
                  .asData
                  ?.value
                  .map((r) => r.id)
                  .toList() ??
              const <String>[]);

    return Composer(
      controller: _controller,
      sources: sources,
      hint: l10n.messagePlaceholder,
      minLines: 3,
      // Shift+Tab toggles plan mode (PRD 17 §8). It flips `channels.mode` —
      // the authority every enforcement layer reads — rather than typing a
      // `/plan ` prefix, which the server never saw.
      onPlanToggle: () => ref
          .read(activeChannelModeProvider.notifier)
          .setMode(currentMode == Mode.plan ? Mode.chat : Mode.plan),
      isBusy: activeRunIds.isNotEmpty,
      onStop: activeRunIds.isEmpty
          ? null
          : () => _handleStop(ref, activeRunIds),
      // The mode selector states a guarantee; the badge beside it discloses when
      // the channel's adapter cannot keep it (PRD 24 §3). It renders nothing on
      // the common path, so the toolbar is unchanged for chat mode and for a
      // fully-enforcing adapter.
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ModeDropdown(
            currentMode: currentMode,
            onChanged: (mode) =>
                ref.read(activeChannelModeProvider.notifier).setMode(mode),
          ),
          ModeEnforcementBadge(channelId: channelId, currentMode: currentMode),
        ],
      ),
      onSubmit: (submission) => _handleSubmit(ref, context, submission),
    );
  }

  /// Stops every agent currently working in this channel. Multi-agent rooms can
  /// have several live runs, so all are stopped (each run log id == its agent
  /// turn's message id).
  Future<void> _handleStop(WidgetRef ref, List<String> runLogIds) async {
    final port = ref.read(messagingServiceProvider);
    final workspaceId = ref.requireWorkspaceId();
    for (final id in runLogIds) {
      await port.stopRun(workspaceId, id);
    }
  }

  Future<void> _handleSubmit(
    WidgetRef ref,
    BuildContext context,
    ComposerSubmission s,
  ) async {
    final channelId = widget.channelId;
    final rawContent = _renderContent(s);
    final workspaceId = ref.requireWorkspaceId();

    // `/todo …` is handled entirely on the client (view/edit the persisted
    // list) — intercept it before it reaches the agent.
    final parsedCommand = parseSlashCommand(rawContent.trim());

    // `/plan` sets the conversation's mode rather than travelling as text. The
    // server also recognizes it (from the raw user text), but flipping the mode
    // here is what makes the tool surface, guard preset, sandbox, and prompt
    // agree for THIS turn and every turn after it.
    var content = rawContent;
    if (parsedCommand.isCommand && parsedCommand.command == 'plan') {
      await ref.read(activeChannelModeProvider.notifier).setMode(Mode.plan);
      final rest = parsedCommand.args.trim();
      if (rest.isEmpty) {
        // A bare `/plan` just arms the mode; there is nothing to say yet.
        return;
      }
      content = rest;
      if (!context.mounted) {
        return;
      }
    }

    if (parsedCommand.isCommand && parsedCommand.command == 'todo') {
      await handleTodoSlashCommand(
        ref: ref,
        context: context,
        channelId: channelId,
        workspaceId: workspaceId,
        args: parsedCommand.args,
      );
      return;
    }

    // `/compact` folds older history into an anchored summary server-side and
    // — like `/todo` — never travels as a channel message: persisting it
    // would push the planner's cut one turn back and pollute the transcript.
    // The conversation then continues on the compacted context.
    if (parsedCommand.isCommand && parsedCommand.command == 'compact') {
      if (context.mounted) {
        await _handleCompact(ref, context);
      }
      return;
    }

    // Mid-run steering: if agents are already working in this conversation and
    // the user submits plain conversational text (no @agent, no slash command),
    // nudge the running run(s) instead of queuing a brand-new turn — the loop
    // injects it at the next turn boundary (parity with oh-my-pi / kilocode). If
    // the run just finished (nothing delivered), fall through to a normal send.
    // Scoped to this pane's conversation for the same reason as the stop
    // affordance: steering must reach the runs the user is looking at.
    final hasAgentMention = s.mentions.any((m) => m.kind == 'agent');
    if (!parsedCommand.isCommand &&
        !hasAgentMention &&
        content.trim().isNotEmpty) {
      final activeRuns =
          ref
              .read(
                conversationActiveRunsProvider((
                  workspaceId: workspaceId,
                  conversationId: widget.conversationId ?? channelId,
                )),
              )
              .asData
              ?.value ??
          const [];
      if (activeRuns.isNotEmpty) {
        final port = ref.read(messagingServiceProvider);
        var delivered = false;
        for (final r in activeRuns) {
          delivered = await port.steerRun(r.id, content) || delivered;
        }
        if (delivered) {
          if (context.mounted) {
            CcToastScope.maybeOf(context)?.show(
              'Sent to the running agent as steering.',
              variant: CcToastVariant.neutral,
            );
          }
          return;
        }
      }
    }

    final structured = <StructuredMention>[
      for (final m in s.mentions.where((m) => m.kind == 'agent'))
        if (m.payload?['agentId'] != null)
          StructuredMention(
            agentId: m.payload!['agentId'] as String,
            raw: '@${m.label}',
          ),
    ];
    final entityRefs = entityRefsFromMentions(s.mentions);

    // Gate on provisioning: send now when ready, otherwise park the submission
    // until the background workspace setup completes. The queue auto-flushes on
    // the provisioning → ready transition.
    final status = ref.read(channelProvisioningStatusProvider(channelId));
    if (status != ChannelProvisioningStatus.ready) {
      ref
          .read(pendingChannelSendsProvider(channelId).notifier)
          .enqueue(
            content: content,
            structuredMentions: structured,
            entityRefs: entityRefs,
          );
      return;
    }

    await ref
        .read(channelMessageSendProvider.notifier)
        .send(
          content: content,
          channelId: channelId,
          workspaceId: workspaceId,
          conversationId: widget.conversationId,
          structuredMentions: structured,
          entityRefs: entityRefs,
        );
  }

  /// Runs the server-side compaction pass for this conversation (`/compact`)
  /// and narrates the outcome. The summary message itself arrives through the
  /// normal message watch stream; only the no-op / busy / unavailable paths
  /// need a toast.
  Future<void> _handleCompact(WidgetRef ref, BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final port = ref.read(messagingServiceProvider);
    final ConversationCompactionResult result;
    try {
      result = await port.compactConversation(
        workspaceId: ref.requireWorkspaceId(),
        channelId: widget.channelId,
        conversationId: widget.conversationId,
      );
    } on Object {
      // The op is absent on a host without the dispatch engine (or the call
      // failed) — say so instead of failing silently.
      if (context.mounted) {
        CcToastScope.maybeOf(
          context,
        )?.show(l10n.compactUnavailable, variant: CcToastVariant.warning);
      }
      return;
    }
    if (!context.mounted) {
      return;
    }
    final toast = CcToastScope.maybeOf(context);
    switch (result.status) {
      case ConversationCompactionStatus.compacted:
        toast?.show(l10n.compactDone, variant: CcToastVariant.success);
      case ConversationCompactionStatus.nothingToCompact:
        toast?.show(l10n.compactNothing);
      case ConversationCompactionStatus.agentBusy:
        toast?.show(l10n.compactBusy, variant: CcToastVariant.warning);
      case ConversationCompactionStatus.unavailable:
        toast?.show(l10n.compactUnavailable, variant: CcToastVariant.warning);
    }
  }

  String _renderContent(ComposerSubmission s) {
    final buffer = StringBuffer(s.text.trim());
    for (final a in s.attachments) {
      if (a.kind == 'file' && a.path != null) {
        if (buffer.isNotEmpty) {
          buffer.write('\n');
        }
        buffer.write(a.path);
      }
    }
    return buffer.toString();
  }
}
