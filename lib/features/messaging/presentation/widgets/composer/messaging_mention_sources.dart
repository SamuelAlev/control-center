/// The mention sources a messaging composer offers, and the `#` token an
/// entity mention renders as.
///
/// **Why this is not in `space_input_bar.dart`.** The space input bar and the
/// thread reply bar both build this list, and the whole point of assembling it
/// in one place is that the two cannot drift — a source added for one and
/// forgotten for the other is a mention that works in a space and silently does
/// nothing in a thread. Keeping it inside one of the two consumers makes the
/// other one's dependency look accidental.
library;

import 'package:cc_domain/cc_domain.dart' show UserDto, WorkspaceMemberDto;
import 'package:cc_domain/core/domain/value_objects/entity_ref.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting.dart';
import 'package:cc_domain/features/pr_review/domain/entities/enriched_pull_request.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_harness/slash_command.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/meetings/providers/meeting_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/composer/messaging_slash_commands.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/messaging/providers/repo_file_search_provider.dart';
import 'package:control_center/features/pr_review/providers/pr_list_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/skills_settings.dart'
    show SkillInfo, skillListProvider;
import 'package:control_center/features/settings/providers/skill_security_providers.dart'
    show RepoSkillDto, repoSkillListProvider;
import 'package:control_center/features/ticketing/providers/ticketing_providers.dart';
import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:control_center/shared/widgets/composer/mention/mention_source.dart';
import 'package:control_center/shared/widgets/composer/mention/sources/agent_mention_source.dart';
import 'package:control_center/shared/widgets/composer/mention/sources/file_mention_source.dart';
import 'package:control_center/shared/widgets/composer/mention/sources/meeting_mention_source.dart';
import 'package:control_center/shared/widgets/composer/mention/sources/pr_mention_source.dart';
import 'package:control_center/shared/widgets/composer/mention/sources/scratchpad_mention_source.dart';
import 'package:control_center/shared/widgets/composer/mention/sources/slash_command_source.dart';
import 'package:control_center/shared/widgets/composer/mention/sources/space_mention_source.dart';
import 'package:control_center/shared/widgets/composer/mention/sources/ticket_mention_source.dart';
import 'package:control_center/shared/widgets/composer/mention/sources/user_mention_source.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// Assembles the full mention-source list for a messaging composer (space
/// input bar and thread reply bar share this so they never drift). `@` sources
/// (agents/spaces/files/scratchpad) plus `#` entity sources (tickets/PRs/
/// meetings), all fed workspace-scoped data resolved here so the shared
/// composer never depends on feature providers.
///
/// PR autocomplete watches the workspace's PR list (`prsByRepoProvider`, which
/// is keepAlive, batched and shared with the PR list screen); tickets and
/// meetings are cheap local streams.
List<MentionSource> buildMessagingMentionSources(
  WidgetRef ref,
  String? workspaceId, {
  String? spaceId,
}) {
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
  final spaces = workspaceId != null
      ? ref.watch(workspaceSpacesProvider(workspaceId)).value ?? const []
      : ref.watch(spacesProvider).value ?? const [];
  // File mentions search on the SERVER (`repos.searchFiles` — fff over the
  // checkouts cc_server owns), so desktop, web and phone behave identically and
  // no client ever loads a native searcher. Inside a space the search runs on
  // that conversation's isolated worktrees: mentioning a file means the copy
  // the agents in this conversation are editing, including one they created.
  final fileSearch = ref.watch(repoFileSearchFnProvider);
  final mentionSpaceId = (spaceId != null && spaceId.isNotEmpty)
      ? spaceId
      : null;
  final MentionSource? fileMentionSource = workspaceId == null
      ? null
      : FileMentionSource(
          search: (query) async {
            final hits = await fileSearch(
              workspaceId,
              query,
              spaceId: mentionSpaceId,
            );
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
  // Skills the space's checked-out repos ship. Offered under their qualified
  // `repo:name` and badged with the repo, because a bare name says nothing
  // about which service's conventions it encodes and two repos may each ship
  // a `testing`.
  final repoSkills = spaceId == null || spaceId.isEmpty
      ? const <RepoSkillDto>[]
      : ref.watch(repoSkillListProvider(spaceId)).value ??
            const <RepoSkillDto>[];

  return <MentionSource>[
    AgentMentionSource(agents),
    if (memberMentionItems.isNotEmpty) UserMentionSource(memberMentionItems),
    SpaceMentionSource([
      for (final c in spaces) SpaceMentionItem(id: c.id, name: c.name),
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
              repoFullName: '${g.repo.remoteOwner}/${g.repo.remoteName}',
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
      ...kMessagingSlashCommands,
      // Skills carry their own `skill:` namespace so they never collide with
      // the builtins above — a skill named `plan` or `compact` was otherwise
      // shadowed for good, and every skill added narrowed the names a future
      // builtin could take.
      for (final s in skills)
        SlashCommand(
          name: '$skillCommandPrefix${s.name}',
          description: s.description.isEmpty ? 'Skill' : s.description,
        ),
      for (final s in repoSkills)
        SlashCommand(
          name: '$skillCommandPrefix${s.qualifiedName}',
          description: s.description.isEmpty ? 'Skill' : s.description,
          badge: s.repo,
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
