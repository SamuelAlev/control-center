import 'dart:async';

import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/features/pr_review/domain/entities/enriched_pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/usecases/classify_pr_inbox_use_case.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_log_entry.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/forge/providers/forge_providers.dart';
import 'package:control_center/features/inbox/presentation/models/inbox_attention_item.dart';
import 'package:control_center/features/messaging/providers/pending_confirmations_provider.dart';
import 'package:control_center/features/pr_review/providers/pr_filter_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_lane_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_list_display_prefs_provider.dart';
import 'package:control_center/features/pr_review/providers/pr_list_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/ticketing/providers/ticketing_providers.dart'
    show workspaceSyncLogsProvider;
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/app_router.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/repo_filters.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Attention strip (non-PR items: blocked agents, failed syncs)
// ─────────────────────────────────────────────────────────────────────────────

/// A source that contributes items to the inbox's pinned attention strip
/// (PRD 19 §7).
///
/// Mirrors the command-palette `CommandSource` registry: each source decides
/// which of its states genuinely *block* the operator or *request* them and
/// emits only those — the strict inclusion rule that keeps the strip from
/// becoming a second notification firehose.
abstract class InboxAttentionSource {
  /// Stable id (for dedup / diagnostics).
  String get id;

  /// The items this source contributes right now (may be empty).
  List<InboxAttentionItem> buildItems(BuildContext context, WidgetRef ref);
}

class _AgentApprovalsSource implements InboxAttentionSource {
  @override
  String get id => 'agent-approvals';

  @override
  List<InboxAttentionItem> buildItems(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final pending = ref.watch(pendingConfirmationsProvider).value ?? const [];
    final router = ref.read(routerProvider);
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    return [
      for (final c in pending)
        InboxAttentionItem(
          // A blocked agent is the definition of "blocks something".
          id: 'agent-approval:${c.id}',
          severity: InboxAttentionSeverity.blocking,
          title: c.title,
          subtitle: c.detail.isEmpty ? null : c.detail,
          icon: AppIcons.bot,
          actionLabel: l10n.inboxReview,
          waitingSince: DateTime.tryParse(c.createdAt),
          onAction: () {
            if (workspaceId != null && c.conversationId.isNotEmpty) {
              router.go(channelRoute(workspaceId, c.conversationId));
            }
          },
        ),
    ];
  }
}

/// The most-recent FAILED sync per vendor (a failed sync blocks that vendor's
/// mirror). Collapsing to one-per-vendor keeps a flapping connector from
/// flooding the strip — the strict inclusion rule in action.
List<TicketSyncLogEntry> latestSyncFailures(List<TicketSyncLogEntry> logs) {
  final byVendor = <String, TicketSyncLogEntry>{};
  for (final e in logs) {
    if (e.outcome != SyncOutcome.failed) {
      continue;
    }
    final prev = byVendor[e.vendor];
    if (prev == null || e.createdAt.isAfter(prev.createdAt)) {
      byVendor[e.vendor] = e;
    }
  }
  return byVendor.values.toList();
}

class _SyncFailureSource implements InboxAttentionSource {
  @override
  String get id => 'sync-failures';

  @override
  List<InboxAttentionItem> buildItems(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return const [];
    }
    final logs =
        ref.watch(workspaceSyncLogsProvider(workspaceId)).value ?? const [];
    final router = ref.read(routerProvider);
    return [
      for (final f in latestSyncFailures(logs))
        InboxAttentionItem(
          id: 'sync-failure:${f.vendor}',
          severity: InboxAttentionSeverity.blocking,
          title: '${l10n.inboxSyncFailed}: ${f.vendor}',
          subtitle: f.message,
          icon: AppIcons.cloudOff,
          actionLabel: l10n.inboxOpen,
          waitingSince: f.createdAt,
          // Sync health is a workspace concern and lives on Workspace →
          // General alongside the ticket-sync configuration it reports on.
          onAction: () => router.go(settingsWorkspaceGeneralRoute(workspaceId)),
        ),
    ];
  }
}

/// The registered attention sources. Features add theirs here (or via a DI
/// override) exactly like the command-palette sources.
final inboxAttentionSourcesProvider = Provider<List<InboxAttentionSource>>(
  (_) => [_AgentApprovalsSource(), _SyncFailureSource()],
);

/// The aggregated, sorted attention strip. Rebuilds reactively as its sources'
/// providers emit (blocked agents come and go, syncs recover).
List<InboxAttentionItem> buildInboxAttentionItems(
  BuildContext context,
  WidgetRef ref,
) {
  final sources = ref.watch(inboxAttentionSourcesProvider);
  final items = <InboxAttentionItem>[];
  for (final source in sources) {
    items.addAll(source.buildItems(context, ref));
  }
  return sortInboxAttentionItems(items);
}

// ─────────────────────────────────────────────────────────────────────────────
// Sidebar badge count
// ─────────────────────────────────────────────────────────────────────────────

/// Live count of open PRs awaiting my review across the active workspace,
/// computed SERVER-SIDE from the open-PR poller's snapshot.
///
/// The sidebar badge is always on, so it must not pin the full PR list
/// (titles, bodies, checks) in client memory the way watching
/// [prsByRepoProvider] would — this subscribes to a single int instead. The
/// full list loads only while a PR surface (list, inbox, palette) is open.
final needsMyReviewCountProvider = StreamProvider<int>((ref) {
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (workspaceId == null) {
    return Stream.value(0);
  }
  return ref
      .watch(openPrListRepositoryProvider)
      .watchNeedsMyReviewCount(workspaceId);
});

/// The count for the sidebar badge (host-global blocked agents + PRs awaiting
/// me). Kept cheap: blocked agents + sync failures come from already-warm
/// source providers and the PR count is the server-derived lite feed.
final inboxCountProvider = Provider<int>((ref) {
  final pending = ref.watch(pendingConfirmationsProvider).value ?? const [];
  var count = pending.length;
  count += ref.watch(needsMyReviewCountProvider).value ?? 0;
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (workspaceId != null) {
    final logs =
        ref.watch(workspaceSyncLogsProvider(workspaceId)).value ?? const [];
    count += latestSyncFailures(logs).length;
  }
  return count;
});

// ─────────────────────────────────────────────────────────────────────────────
// Filters, sort, collapse state
// ─────────────────────────────────────────────────────────────────────────────

/// Every PR loaded into the inbox (open + recently merged), flattened — the
/// population the filter menu's facet counts and the filter bar run over.
final inboxPopulationProvider = Provider.autoDispose<List<PullRequest>>((ref) {
  final open = ref.watch(prsByRepoProvider).value?.repos ?? const [];
  final merged = ref.watch(recentlyMergedPrsProvider).value ?? const [];
  return [for (final rp in open) ...rp.prs, for (final rp in merged) ...rp.prs];
});

/// The inbox's filter scope: its own `PrListFilters` instance
/// (`inboxListFiltersProvider` — same axes and menu as the PR queue, but
/// independent state) over the inbox population.
final inboxFilterScope = PrFilterScope(
  filters: inboxListFiltersProvider,
  population: inboxPopulationProvider,
);

/// The sortable columns of an inbox section.
enum InboxSortColumn {
  /// Alphabetical by PR title.
  title,

  /// By diff churn (additions + deletions).
  changes,

  /// By last update.
  updated,
}

/// One global sort applied to every section's rows.
class InboxSort {
  /// Creates an [InboxSort].
  const InboxSort({required this.column, required this.ascending});

  /// The active column.
  final InboxSortColumn column;

  /// Sort direction.
  final bool ascending;
}

/// Default direction when a column becomes active.
bool _defaultAscending(InboxSortColumn column) =>
    column == InboxSortColumn.title;

/// Holds the inbox's column sort; clicking the active column flips direction.
class InboxSortNotifier extends Notifier<InboxSort> {
  @override
  /// Builds the default sort from the shared display "Ordering" (the same
  /// select as the PR queue popover): recent → updated desc, oldest →
  /// updated asc, largest → changes desc. A column-header click overrides it
  /// for the session; changing the Ordering rebuilds this and resets the
  /// override.
  InboxSort build() {
    final ordering = ref.watch(prListSortProvider);
    return switch (ordering) {
      PrListSort.recent => const InboxSort(
        column: InboxSortColumn.updated,
        ascending: false,
      ),
      PrListSort.oldest => const InboxSort(
        column: InboxSortColumn.updated,
        ascending: true,
      ),
      PrListSort.largest => const InboxSort(
        column: InboxSortColumn.changes,
        ascending: false,
      ),
    };
  }

  /// Activates [column], or flips direction when it is already active.
  void toggle(InboxSortColumn column) {
    state = state.column == column
        ? InboxSort(column: column, ascending: !state.ascending)
        : InboxSort(column: column, ascending: _defaultAscending(column));
  }
}

/// Provides the inbox's column sort.
final inboxSortProvider = NotifierProvider<InboxSortNotifier, InboxSort>(
  InboxSortNotifier.new,
);

/// One rendered subgroup inside an inbox section under a non-flat grouping:
/// the subheader's label + user (author grouping only; drives the avatar),
/// and the subgroup's items in display order. A null `label` means no
/// subheader (flat).
typedef InboxItemGroup = ({
  String? label,
  PrUser? user,
  List<PrInboxItem> items,
});

/// Buckets a section's already-sorted [items] per the shared display
/// [grouping]: `author` → one subgroup per author login (the operator first,
/// then alphabetical); everything else → flat. `repository` deliberately
/// stays flat here (explicit product decision: the inbox is one stream per
/// lifecycle section, never separated by repo — the row's `repo #number`
/// meta carries that context); `status` is flat because the lifecycle
/// sections already encode it. Within a subgroup the incoming order is
/// preserved.
List<InboxItemGroup> groupInboxItems(
  List<PrInboxItem> items, {
  required PrListGrouping grouping,
  required Map<ForgeHost, String> viewerLogins,
}) {
  switch (grouping) {
    case PrListGrouping.status:
    case PrListGrouping.none:
    case PrListGrouping.repository:
      return [if (items.isNotEmpty) (label: null, user: null, items: items)];
    case PrListGrouping.author:
      // "Me" is per forge: a login only counts as the operator when it matches
      // their account on the forge that PR actually came from, so an unrelated
      // GitLab user who happens to share a GitHub handle is not folded in.
      final mine = <String>{};
      final byAuthor = <String, List<PrInboxItem>>{};
      final userOf = <String, PrUser>{};
      for (final item in items) {
        final author = item.pr.author;
        final login = author?.login.toLowerCase() ?? '';
        byAuthor.putIfAbsent(login, () => []).add(item);
        if (author != null) {
          userOf.putIfAbsent(login, () => author);
        }
        final viewer = viewerLogins[item.repo.forge]?.toLowerCase() ?? '';
        if (viewer.isNotEmpty && viewer == login) {
          mine.add(login);
        }
      }
      final logins = byAuthor.keys.toList()
        ..sort((a, b) {
          final aMe = mine.contains(a) ? 0 : 1;
          final bMe = mine.contains(b) ? 0 : 1;
          return aMe != bMe ? aMe.compareTo(bMe) : a.compareTo(b);
        });
      return [
        for (final login in logins)
          (
            label: userOf[login]?.login ?? login,
            user: userOf[login],
            items: byAuthor[login]!,
          ),
      ];
  }
}

/// Orders [items] per [sort]. Items arrive most-recently-updated first from
/// the classifier, so `updated desc` is a no-op.
List<PrInboxItem> sortInboxItems(List<PrInboxItem> items, InboxSort sort) {
  final epoch = DateTime.fromMillisecondsSinceEpoch(0);
  final copy = List<PrInboxItem>.of(items);
  int compare(PrInboxItem a, PrInboxItem b) => switch (sort.column) {
    InboxSortColumn.title => a.pr.title.toLowerCase().compareTo(
      b.pr.title.toLowerCase(),
    ),
    InboxSortColumn.changes => (a.pr.additions + a.pr.deletions).compareTo(
      b.pr.additions + b.pr.deletions,
    ),
    InboxSortColumn.updated => (a.pr.updatedAt ?? epoch).compareTo(
      b.pr.updatedAt ?? epoch,
    ),
  };
  copy.sort((a, b) => sort.ascending ? compare(a, b) : compare(b, a));
  return copy;
}

/// Tracks which inbox sections are collapsed.
class CollapsedInboxSectionsNotifier extends Notifier<Set<PrInboxSection>> {
  @override
  /// Builds the initial set (no sections collapsed).
  Set<PrInboxSection> build() => const {};

  /// Toggles the collapsed state of [section].
  void toggle(PrInboxSection section) {
    final next = Set<PrInboxSection>.from(state);
    if (!next.add(section)) {
      next.remove(section);
    }
    state = next;
  }
}

/// Set of collapsed inbox sections.
final collapsedInboxSectionsProvider =
    NotifierProvider<CollapsedInboxSectionsNotifier, Set<PrInboxSection>>(
      CollapsedInboxSectionsNotifier.new,
    );

// ─────────────────────────────────────────────────────────────────────────────
// Data
// ─────────────────────────────────────────────────────────────────────────────

/// The last merged-history page per `workspace|login`, seeded into
/// [recentlyMergedPrsProvider] on revisit (see `LastGoodStore`).
final lastGoodMergedPrsProvider =
    NotifierProvider<
      LastGoodStore<List<RepoPullRequests>>,
      Map<String, List<RepoPullRequests>>
    >(LastGoodStore.new);

/// The operator's recently merged PRs across the workspace's repos, joined
/// back to the canonical `Repo` entities.
///
/// One server-side `author:<me> is:merged` search history page per load —
/// fetched only while the inbox is open (autoDispose), refreshed by the
/// inbox's refresh action. The classifier applies the merged window on top.
///
/// Stale-while-revalidate: a revisit seeds the previous page from
/// [lastGoodMergedPrsProvider] instantly (the search is a server-side GitHub
/// call — without the seed, the "Merging and recently merged" section pops in
/// empty seconds later), then swaps in the fresh page when it lands.
final recentlyMergedPrsProvider =
    AsyncNotifierProvider.autoDispose<
      RecentlyMergedPrsNotifier,
      List<RepoPullRequests>
    >(RecentlyMergedPrsNotifier.new);

/// Holds the recently-merged history page; see [recentlyMergedPrsProvider].
class RecentlyMergedPrsNotifier extends AsyncNotifier<List<RepoPullRequests>> {
  @override
  Future<List<RepoPullRequests>> build() async {
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final login = ref.watch(currentUserLoginProvider);
    if (workspaceId == null || login.isEmpty) {
      return const [];
    }
    // Watched (not read) so the build re-runs when the repos stream emits:
    // the first run can race an unloaded repo list and join to an empty page;
    // the re-run joins against the real repos. See the stamp guard in
    // [_fetch].
    ref.watch(reposForWorkspaceProvider(workspaceId));
    final key = '$workspaceId|$login';
    final lastGood = ref.read(lastGoodMergedPrsProvider)[key];
    final fresh = _fetch(workspaceId, login, key);
    if (lastGood == null) {
      return fresh;
    }
    var disposed = false;
    ref.onDispose(() => disposed = true);
    unawaited(
      fresh.then(
        (groups) {
          if (!disposed) {
            state = AsyncData(groups);
          }
        },
        onError: (_) {
          // A failed refresh keeps the stale page — better-stale-than-broken.
        },
      ),
    );
    return lastGood;
  }

  /// The server-side `author:<me> is:merged` search, joined back to the
  /// workspace's canonical `Repo` entities and stamped into the store.
  Future<List<RepoPullRequests>> _fetch(
    String workspaceId,
    String login,
    String key,
  ) async {
    final groups = await ref
        .read(openPrListRepositoryProvider)
        .closedByAuthorForWorkspace(workspaceId, login);
    // Read the repos stream's CURRENT value: a still-loading stream joins
    // to an empty page — joinable only after the real repos arrive, so the
    // empty page is never stamped as the workspace's last-good snapshot
    // (which a revisit would then seed as a blank flash). The build
    // re-runs when the stream emits, so the real page follows.
    final reposAsync = ref.read(reposForWorkspaceProvider(workspaceId));
    final repos = forgeLinkedReposOf(reposAsync);
    final reposById = {for (final r in repos) r.id: r};
    final result = [
      for (final g in groups)
        if (reposById[g.repoId] != null && g.prs.isNotEmpty)
          RepoPullRequests(repo: reposById[g.repoId]!, prs: g.prs),
    ];
    if (reposAsync.hasValue || groups.every((g) => g.prs.isEmpty)) {
      ref.read(lastGoodMergedPrsProvider.notifier).stamp(key, result);
    }
    return result;
  }

  /// Explicit user refresh: refetches and replaces the page, keeping the
  /// current value visible until the search lands (the inbox's refresh
  /// affordance spins on its own `_refreshing` flag for the duration).
  Future<void> refreshNow() async {
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    final login = ref.read(currentUserLoginProvider);
    if (workspaceId == null || login.isEmpty) {
      return;
    }
    try {
      state = AsyncData(
        await _fetch(workspaceId, login, '$workspaceId|$login'),
      );
    } catch (_) {
      // Keep the last good page — the surface shows its own error affordance.
    }
  }
}

/// Narrows [byRepo] through the inbox's [PrListFilters] instance — the same
/// predicate as the PR queue ([prPassesFilters]), so status, author,
/// reviewer, content, repo owner/name, date windows and quick-to-review all
/// apply here too. [includeDrafts] is the shared "show drafts" display
/// option.
/// Narrows [byRepo] through the inbox's filters, resolving "me" per repo.
///
/// [viewerLogins] maps each forge to the operator's login there, because a
/// mixed-forge workspace has no single "current login" to compare against.
List<RepoPullRequests> applyInboxFilters(
  List<RepoPullRequests> byRepo, {
  required PrListFilters filters,
  required Map<ForgeHost, String> viewerLogins,
  required bool includeDrafts,
  Map<String, Set<String>> viewerTeamsByOrg = const {},
}) {
  return [
    for (final rp in byRepo)
      RepoPullRequests(
        repo: rp.repo,
        prs: [
          for (final pr in rp.prs)
            if (prPassesFilters(
              pr,
              filters: filters,
              currentLogin: viewerLogins[rp.repo.forge] ?? '',
              includeDrafts: includeDrafts,
              viewerTeamsByOrg: viewerTeamsByOrg,
            ))
              pr,
        ],
      ),
  ];
}

/// The classified inbox for the active workspace, narrowed by
/// [inboxListFiltersProvider] and the shared display prefs (draft
/// visibility, merged window).
///
/// Progressive by design: the open-PR snapshot drives loading/error state,
/// while the merged history and the reviewed-by-me overlay enrich the result
/// as they arrive (their absence only empties "Merging and recently merged" /
/// "Waiting for author" momentarily — no spinner gate).
final inboxDataProvider = Provider.autoDispose<AsyncValue<PrInboxData>>((ref) {
  final viewerLogins = ref.watch(viewerLoginsProvider);
  final filters = ref.watch(inboxListFiltersProvider);
  final showDrafts = ref.watch(
    prListDisplayPrefsProvider.select((p) => p.showDrafts),
  );
  final mergedWindow = ref.watch(
    prListDisplayPrefsProvider.select((p) => p.mergedWindow),
  );
  final openAsync = ref.watch(prsByRepoProvider);
  final merged = ref.watch(recentlyMergedPrsProvider).value ?? const [];
  final reviewedKeys =
      ref.watch(reviewedByMePrKeysProvider).value ?? const <String>{};
  final viewerTeams =
      ref.watch(viewerGitHubTeamsProvider).value ??
      const <String, Set<String>>{};

  return openAsync.whenData(
    (state) => const ClassifyPrInboxUseCase().execute(
      openByRepo: applyInboxFilters(
        state.repos,
        filters: filters,
        viewerLogins: viewerLogins,
        includeDrafts: showDrafts,
        viewerTeamsByOrg: viewerTeams,
      ),
      mergedByRepo: applyInboxFilters(
        merged,
        filters: filters,
        viewerLogins: viewerLogins,
        includeDrafts: showDrafts,
        viewerTeamsByOrg: viewerTeams,
      ),
      viewerLoginByForge: viewerLogins,
      reviewedByMeKeys: reviewedKeys,
      viewerTeamsByOrg: viewerTeams,
      mergedWindow: mergedWindow.duration,
    ),
  );
});
