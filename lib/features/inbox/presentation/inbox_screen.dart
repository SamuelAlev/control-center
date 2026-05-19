import 'package:cc_domain/features/pr_review/domain/usecases/classify_pr_inbox_use_case.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/inbox/domain/inbox_attention_item.dart';
import 'package:control_center/features/inbox/presentation/widgets/inbox_attention_card.dart';
import 'package:control_center/features/inbox/presentation/widgets/inbox_hero_header.dart';
import 'package:control_center/features/inbox/presentation/widgets/inbox_rail.dart';
import 'package:control_center/features/inbox/presentation/widgets/inbox_section_card.dart';
import 'package:control_center/features/inbox/providers/inbox_providers.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_filter/pr_filter_bar.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_filter/pr_filter_menu.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pull_request_list/pr_display_options_button.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pull_request_list/pr_list_shared.dart'
    show EmptyConfigState;
import 'package:control_center/features/pr_review/providers/pr_filter_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_list_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/providers/last_checked_provider.dart';
import 'package:control_center/shared/utils/repo_filters.dart';
import 'package:control_center/shared/widgets/empty_state.dart';
import 'package:control_center/shared/widgets/page_wrapper.dart';
import 'package:control_center/shared/widgets/refresh_control.dart';
import 'package:control_center/shared/widgets/scoped_shortcuts.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The inbox: every pull request that involves
/// the operator, classified into fixed review-lifecycle sections — plus a
/// pinned attention strip for the non-PR items that block them (stuck agents,
/// failed syncs). A shader-backed hero heads the page (the inbox's earned
/// brand moment) with the filter, display
/// and refresh actions parked in its eyebrow row; below it a left rail
/// mirrors the sections with live counts and jumps
/// the list; the shared PR filter menu/bar (status, author, reviewers,
/// content, repo owner/name, dates, quick to review) and the shared display
/// options narrow the view.
class InboxScreen extends ConsumerStatefulWidget {
  /// Creates an [InboxScreen].
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  final ScrollController _scrollController = ScrollController();
  final Map<PrInboxSection, GlobalKey> _sectionKeys = {
    for (final s in PrInboxSection.values) s: GlobalKey(),
  };
  final CcOverlayController _filterMenuController = CcOverlayController();
  PrInboxSection? _railSelection;

  /// The distance below the viewport's top edge at which a section is
  /// considered "current". A small lead makes the rail switch to a section
  /// just as its card reaches the top, rather than a beat behind it.
  static const double _railActivationLead = 72;

  /// Whether a manual refresh (server sweep + overlay refetch) is in flight,
  /// so the refresh icon spins for the whole fetch — the live open-list
  /// subscription itself never re-enters a loading state on a forced sweep.
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    // The rail highlight tracks scroll position (scrollspy). A post-frame
    // sync sets the initial highlight once the list is laid out.
    _scrollController.addListener(_syncRailToScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncRailToScroll());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_syncRailToScroll);
    _scrollController.dispose();
    _filterMenuController.dispose();
    super.dispose();
  }

  /// Recomputes which section the rail highlights from the current scroll
  /// geometry by measuring each present section card and delegating the
  /// decision to [resolveInboxRailSection].
  void _syncRailToScroll() {
    if (!mounted || !_scrollController.hasClients) {
      return;
    }
    final position = _scrollController.position;

    final revealOffsets = <PrInboxSection, double>{};
    for (final section in PrInboxSection.values) {
      final box = _sectionKeys[section]?.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.attached) {
        continue;
      }
      revealOffsets[section] = RenderAbstractViewport.of(
        box,
      ).getOffsetToReveal(box, 0).offset;
    }

    final active = resolveInboxRailSection(
      offset: position.pixels,
      maxScrollExtent: position.maxScrollExtent,
      revealOffsets: revealOffsets,
    );

    if (active != _railSelection) {
      setState(() => _railSelection = active);
    }
  }

  /// Forces an immediate server-side GitHub sweep and refetches the lazily
  /// loaded merged/reviewed overlays, spinning the refresh icon until every
  /// fetch settles.
  Future<void> _refresh() async {
    if (_refreshing) {
      return;
    }
    setState(() => _refreshing = true);
    try {
      await Future.wait([
        // The open list is live (server-pushed snapshots); this forces an
        // immediate server-side GitHub sweep instead of tearing down the
        // subscription.
        ref.read(prsByRepoProvider.notifier).forceRefresh(),
        ref.read(recentlyMergedPrsProvider.notifier).refreshNow(),
        ref.read(reviewedByMePrKeysProvider.notifier).refreshNow(),
      ]);
    } catch (_) {
      // Each surface keeps its last snapshot / shows its own error; the spin
      // just stops.
    } finally {
      if (mounted) {
        setState(() => _refreshing = false);
      }
    }
  }

  void _jumpTo(PrInboxSection section) {
    setState(() => _railSelection = section);
    final ctx = _sectionKeys[section]?.currentContext;
    if (ctx == null) {
      return;
    }
    Scrollable.ensureVisible(
      ctx,
      duration: CcMotion.resolve(context, CcMotion.normal),
      curve: CcMotion.standard,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dataAsync = ref.watch(inboxDataProvider);
    final openState = ref.watch(prsByRepoProvider).value;
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final repos = githubLinkedReposOf(
      workspaceId == null
          ? const AsyncData([])
          : ref.watch(reposForWorkspaceProvider(workspaceId)),
    );

    // Stamp freshness whenever the snapshot successfully (re)loads.
    ref.listen(prsByRepoProvider, (_, next) {
      if (next is AsyncData && !next.isLoading) {
        ref.read(lastCheckedProvider.notifier).stamp('inbox');
      }
    });

    // Re-sync the rail highlight once the list (re)builds with data — the
    // section cards it measures only exist after data resolves, and their
    // geometry shifts as sections appear or disappear.
    ref.listen(inboxDataProvider, (_, next) {
      if (next.hasValue) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _syncRailToScroll(),
        );
      }
    });
    final lastChecked = ref.watch(
      lastCheckedProvider.select((m) => m['inbox']),
    );

    final isAuthed = openState?.authenticated ?? true;
    final attention = buildInboxAttentionItems(context, ref);

    return ScopedShortcuts(
      scope: '/inbox',
      bindings: {'inbox.open-filter': _filterMenuController.show},
      child: PageWrapper(
        // No header: the shader hero is the page header and carries the
        // actions (filter, display options, refresh) in its title row.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InboxHeroHeader(
              actions: [
                PrFilterButton(
                  scope: inboxFilterScope,
                  controller: _filterMenuController,
                ),
                const SizedBox(width: AppSpacing.xs),
                const PrDisplayOptionsButton(),
                const SizedBox(width: AppSpacing.xs),
                RefreshControl(
                  lastChecked: lastChecked,
                  // Every in-flight fetch spins the icon: `dataAsync.isLoading`
                  // is only the open list's INITIAL load — the server's
                  // pushed snapshot never re-enters it — so the live sweep
                  // flag and the merged/reviewed overlays' own loads are
                  // folded in explicitly.
                  isLoading:
                      dataAsync.isLoading ||
                      _refreshing ||
                      (openState?.sweeping ?? false) ||
                      ref.watch(recentlyMergedPrsProvider).isLoading ||
                      ref.watch(reviewedByMePrKeysProvider).isLoading,
                  onRefresh: _refresh,
                ),
              ],
            ),
            Expanded(
              child: _buildBody(
                l10n: l10n,
                dataAsync: dataAsync,
                isAuthed: isAuthed,
                hasRepos: repos.isNotEmpty,
                attention: attention,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody({
    required AppLocalizations l10n,
    required AsyncValue<PrInboxData> dataAsync,
    required bool isAuthed,
    required bool hasRepos,
    required List<InboxAttentionItem> attention,
  }) {
    if (!isAuthed) {
      return EmptyConfigState(
        icon: AppIcons.gitPullRequest,
        message: l10n.connectGitHubToLoadPrs,
        hint: l10n.signInWithGhAuth,
      );
    }
    if (dataAsync.hasError && dataAsync.value == null) {
      return Center(
        child: CcAlert(
          variant: CcAlertVariant.danger,
          title: l10n.failedToLoad,
          description: Text(dataAsync.error.toString()),
        ),
      );
    }
    final data = dataAsync.value;
    if (data == null) {
      return const Center(child: CcSpinner());
    }
    if (!hasRepos && data.isEmpty && attention.isEmpty) {
      return EmptyConfigState(
        icon: AppIcons.inbox,
        message: l10n.noRepositoriesConfigured,
        hint: l10n.addGithubRepoPrompt,
        action: CcButton(
          onPressed: () => GoRouter.of(
            context,
          ).go(settingsReposRoute(context.currentWorkspaceId!)),
          icon: AppIcons.settings,
          child: Text(l10n.repositoriesSettings),
        ),
      );
    }

    final counts = {
      for (final section in PrInboxSection.values)
        section: data.of(section).length,
    };

    final filtersActive = ref.watch(
      inboxListFiltersProvider.select((f) => f.isActive),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The active-filters bar (chips + "add filter"); renders nothing
          // while no filter is active, so the gap is gated too.
          if (filtersActive) ...[
            PrFilterBar(scope: inboxFilterScope),
            const SizedBox(height: AppSpacing.md),
          ],
          Expanded(
            child: data.isEmpty && attention.isEmpty
                // Nothing to review: the rail has no counts to mirror, so the
                // empty state takes the full width alone.
                ? EmptyState(
                    message: l10n.inboxAllCaughtUp,
                    icon: AppIcons.checkCircle2,
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 224,
                        child: InboxRail(
                          counts: counts,
                          selected: _railSelection,
                          onSelect: _jumpTo,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xl),
                      Expanded(
                        child: ListView(
                          // Exact scroll restoration (PRD 19 §8): the offset
                          // is restored when the operator navigates back to
                          // the inbox.
                          key: const PageStorageKey('inbox-sections'),
                          controller: _scrollController,
                          // The right inset keeps the cards (and their age
                          // column) clear of the overlaying scrollbar.
                          padding: const EdgeInsets.only(
                            right: AppSpacing.md,
                            bottom: AppSpacing.xl,
                          ),
                          children: [
                            if (attention.isNotEmpty) ...[
                              InboxAttentionCard(items: attention),
                              const SizedBox(height: AppSpacing.md),
                            ],
                            // Empty sections render no card at all — the rail
                            // is the always-complete map; the list shows only
                            // work.
                            for (final section in PrInboxSection.values)
                              if (data.of(section).isNotEmpty) ...[
                                KeyedSubtree(
                                  key: _sectionKeys[section],
                                  child: InboxSectionCard(
                                    section: section,
                                    items: data.of(section),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                              ],
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// Scroll-spy decision for the inbox rail: the deepest section whose card has
/// crossed the activation line, pinned to the last section at the very bottom
/// and to the first section while scrolled above the topmost card.
///
/// [revealOffsets] maps each PRESENT section (in enum order) to the scroll
/// offset that would reveal its card's top edge. The bottom pin is gated on
/// [offset] > 0: when the whole list fits in the viewport
/// (`maxScrollExtent` == 0), top == bottom and an ungated pin would highlight
/// the LAST section while the operator is still at the top.
@visibleForTesting
PrInboxSection? resolveInboxRailSection({
  required double offset,
  required double maxScrollExtent,
  required Map<PrInboxSection, double> revealOffsets,
  double activationLead = _InboxScreenState._railActivationLead,
}) {
  PrInboxSection? firstPresent;
  PrInboxSection? lastPresent;
  PrInboxSection? active;

  for (final section in PrInboxSection.values) {
    final revealOffset = revealOffsets[section];
    if (revealOffset == null) {
      continue;
    }
    firstPresent ??= section;
    lastPresent = section;
    if (revealOffset <= offset + activationLead) {
      active = section;
    }
  }

  // At the end of the list the last section may be too short to ever reach
  // the top on its own; pin it so hitting the bottom always lands on it.
  if (lastPresent != null &&
      offset > 0 &&
      offset >= maxScrollExtent - activationLead) {
    active = lastPresent;
  }
  // Above the first card (e.g. viewing the attention strip) keep the first
  // section highlighted rather than clearing the rail.
  return active ?? firstPresent;
}
