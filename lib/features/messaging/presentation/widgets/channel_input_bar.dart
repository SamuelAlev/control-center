import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/value_objects/entity_ref.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/pr_review/domain/entities/enriched_pull_request.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/meetings/providers/meeting_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/file_mention_bindings.dart';
import 'package:control_center/features/messaging/presentation/widgets/mode_dropdown.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_list_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/ticketing/providers/ticketing_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/composer/composer.dart';
import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:control_center/shared/widgets/composer/mention/mention_source.dart';
import 'package:control_center/shared/widgets/composer/mention/sources/agent_mention_source.dart';
import 'package:control_center/shared/widgets/composer/mention/sources/channel_mention_source.dart';
import 'package:control_center/shared/widgets/composer/mention/sources/meeting_mention_source.dart';
import 'package:control_center/shared/widgets/composer/mention/sources/pr_mention_source.dart';
import 'package:control_center/shared/widgets/composer/mention/sources/scratchpad_mention_source.dart';
import 'package:control_center/shared/widgets/composer/mention/sources/ticket_mention_source.dart';
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
    String? workspaceId,
    List<StructuredMention>? structuredMentions,
    List<EntityRef>? entityRefs,
    String? parentMessageId,
  }) async {
    if (content.isEmpty) {
      return;
    }
    final useCase = ref.read(sendChannelMessageUseCaseProvider);
    await useCase.execute(
      content: content,
      channelId: channelId,
      workspaceId: workspaceId,
      structuredMentions: structuredMentions,
      entityRefs: entityRefs,
      parentMessageId: parentMessageId,
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
  final channels = workspaceId != null
      ? ref.watch(workspaceChannelsProvider(workspaceId)).value ?? const []
      : ref.watch(channelsProvider).value ?? const [];
  final List<Repo> repos = workspaceId == null
      ? const []
      : ref.watch(reposForWorkspaceProvider(workspaceId)).value ?? const [];
  // Local-file mentions are desktop-only (native FileSearch); null on web.
  final fileMentionSource = buildFileMentionSource(
    ref,
    [for (final r in repos) r.path],
  );
  final List<Ticket> ticketRows = workspaceId == null
      ? const []
      : ref.watch(workspaceTicketsProvider(workspaceId)).value ?? const [];
  final List<Meeting> meetingRows = workspaceId == null
      ? const []
      : ref.watch(meetingsProvider(workspaceId)).value ?? const [];
  final List<RepoPullRequests> prGroups =
      ref.watch(prsByRepoProvider).value?.repos ?? const [];

  return <MentionSource>[
    AgentMentionSource(agents),
    ChannelMentionSource([
      for (final c in channels)
        ChannelMentionItem(id: c.id, name: c.name, isDm: c.isDm),
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
class ChannelInputBar extends ConsumerWidget {
  /// Creates a [ChannelInputBar].
  const ChannelInputBar({super.key, required this.channelId});

  /// The channel ID this bar sends to.
  final String channelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final l10n = AppLocalizations.of(context);
    final sources = buildMessagingMentionSources(ref, workspaceId);
    final transcriber = composerTranscriber(ref);
    final currentMode = ref.watch(activeChannelModeProvider);

    // Live agent runs in this channel — a run log id equals its agent turn's
    // message id. Drives the composer's stop affordance: while any agent is
    // working, the send button becomes a stop button (when the input is empty).
    final activeRunIds = workspaceId == null
        ? const <String>[]
        : (ref
                .watch(conversationActiveRunsProvider(
                  (workspaceId: workspaceId, conversationId: channelId),
                ))
                .asData
                ?.value
                .map((r) => r.id)
                .toList() ??
            const <String>[]);

    return Composer(
      sources: sources,
      hint: l10n.messagePlaceholder,
      transcriber: transcriber,
      minLines: 3,
      isBusy: activeRunIds.isNotEmpty,
      onStop:
          activeRunIds.isEmpty ? null : () => _handleStop(ref, activeRunIds),
      leading: ModeDropdown(
        currentMode: currentMode,
        onChanged: (mode) =>
            ref.read(activeChannelModeProvider.notifier).setMode(mode),
      ),
      onSubmit: (submission) => _handleSubmit(ref, submission),
    );
  }

  /// Stops every agent currently working in this channel. Multi-agent rooms can
  /// have several live runs, so all are stopped (each run log id == its agent
  /// turn's message id).
  Future<void> _handleStop(WidgetRef ref, List<String> runLogIds) async {
    final port = ref.read(messagingServiceProvider);
    for (final id in runLogIds) {
      await port.stopRun(id);
    }
  }

  Future<void> _handleSubmit(WidgetRef ref, ComposerSubmission s) async {
    final content = _renderContent(s);
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    final structured = <StructuredMention>[
      for (final m in s.mentions.where((m) => m.kind == 'agent'))
        if (m.payload?['agentId'] != null)
          StructuredMention(
            agentId: m.payload!['agentId'] as String,
            raw: '@${m.label}',
          ),
    ];
    await ref
        .read(channelMessageSendProvider.notifier)
        .send(
          content: content,
          channelId: channelId,
          workspaceId: workspaceId,
          structuredMentions: structured,
          entityRefs: entityRefsFromMentions(s.mentions),
        );
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
