import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_table/pr_bulk_action_bar.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_table/pr_repo_load_more_footer.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_table/pr_repo_rail.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_table/pr_repo_section_card.dart';
import 'package:control_center/features/pr_review/providers/pr_table_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Width of the repo rail in the grouped PR table.
const double kPrRepoRailWidth = 224;

/// How close (in pixels) to the end of the shown repo's rows the next page
/// starts loading.
const double kPrRepoLoadMoreExtent = 600;

/// The repo-grouped PR table — the inbox's view (left rail + section card)
/// keyed by repository. The left rail lists every repo with its PR count
/// (repos are never hidden; a filtered-out repo shows a 0 count); selecting a
/// repo shows that repo's card in the detail pane and the first repo is
/// preselected. Cards are always open (no accordion) and sort updated-desc.
/// When [selectable] is on, rows carry checkboxes and a floating bulk-action
/// bar (close / assign / ask-for-review) rides at the bottom, acting across the
/// whole selection (not just the shown repo).
///
/// Shared by the pull-request queue. The user-profile PR view composes the
/// same rail and section card into a page [CustomScrollView] instead so the
/// scrollbar can sit on the pane edge.
class PrRepoView extends ConsumerStatefulWidget {
  /// Creates a [PrRepoView].
  const PrRepoView({
    super.key,
    required this.sections,
    this.selectable = false,
    this.selectedRepoId,
    this.onSelect,
    this.totals = const {},
    this.paging = const {},
    this.onLoadMore,
  });

  /// Every repo + its (filtered) items, in rail order. Never hidden — a repo
  /// with no matching items still appears with a 0 count.
  final List<PrRepoSectionData> sections;

  /// Whether rows are selectable and the bulk-action bar is shown.
  final bool selectable;

  /// The repo whose card is shown. When set (and present in [sections]) this
  /// is the source of truth — used by the queue so `?repo=` on the list URL
  /// can land on a specific org/repo. When null, the first section is
  /// preselected and rail taps stay local.
  final String? selectedRepoId;

  /// Invoked with the tapped repo id. When set, the parent owns selection
  /// (typically by writing the list URL); local state is not updated.
  final ValueChanged<String>? onSelect;

  /// Rail counts that override a section's loaded item count, keyed by repo
  /// id: the forge's total when the shown items are only the first pages.
  final Map<String, int> totals;

  /// Per-repo paging state, keyed by repo id. A repo without an entry has
  /// nothing more to load.
  final Map<String, PrRepoPaging> paging;

  /// Loads the next page of the given repo's PRs. Called when the shown repo
  /// scrolls near its end (or its rows do not fill the pane) and on retry.
  final ValueChanged<String>? onLoadMore;

  @override
  ConsumerState<PrRepoView> createState() => _PrRepoViewState();
}

/// The rail id to highlight for an `owner/repo` query.
///
/// Matching is case-insensitive on [Repo.fullName]. An empty or unknown
/// query falls back to the first repo so the detail pane is never blank.
String? prListSelectedRepoId({
  required Iterable<Repo> repos,
  String? repoFullName,
}) {
  final list = List<Repo>.of(repos, growable: false);
  if (list.isEmpty) {
    return null;
  }
  final needle = repoFullName?.trim();
  if (needle == null || needle.isEmpty) {
    return list.first.id;
  }
  final lower = needle.toLowerCase();
  for (final repo in list) {
    if (repo.fullName.toLowerCase() == lower) {
      return repo.id;
    }
  }
  return list.first.id;
}

class _PrRepoViewState extends ConsumerState<PrRepoView> {
  final ScrollController _scrollController = ScrollController();

  /// Local selection when the parent does not drive [PrRepoView.selectedRepoId].
  /// Null until the user picks one — the build falls back to the first
  /// section so the first repo is preselected.
  String? _selectedRepoId;

  /// The repo whose card is shown, as of the last build.
  String? _shownRepoId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_maybeLoadMore);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Asks for the shown repo's next page once the scroll position is within
  /// [kPrRepoLoadMoreExtent] of its end — including when its rows are too
  /// few to scroll at all. A failed load waits for an explicit retry.
  void _maybeLoadMore() {
    final id = _shownRepoId;
    final onLoadMore = widget.onLoadMore;
    final paging = id == null ? null : widget.paging[id];
    if (id == null ||
        onLoadMore == null ||
        paging == null ||
        !paging.hasMore ||
        paging.loading ||
        paging.failed ||
        !_scrollController.hasClients) {
      return;
    }
    // Attached is not laid out: until the viewport's first layout (a repo
    // switch, a pane that is not built yet) the position has no extents and
    // `extentAfter` throws. The listener or the next frame's check retries.
    final position = _scrollController.position;
    if (!position.hasContentDimensions || !position.hasPixels) {
      return;
    }
    if (position.extentAfter < kPrRepoLoadMoreExtent) {
      onLoadMore(id);
    }
  }

  void _onSelect(String id) {
    if (widget.onSelect != null) {
      widget.onSelect!(id);
      return;
    }
    setState(() => _selectedRepoId = id);
  }

  @override
  Widget build(BuildContext context) {
    final sections = widget.sections;
    if (sections.isEmpty) {
      return const SizedBox.shrink();
    }

    final ids = {for (final s in sections) s.repo.id};
    final controlledId = widget.selectedRepoId;
    final selectedId = (controlledId != null && ids.contains(controlledId))
        ? controlledId
        : (_selectedRepoId != null && ids.contains(_selectedRepoId))
        ? _selectedRepoId!
        : sections.first.repo.id;
    final selected = sections.firstWhere((s) => s.repo.id == selectedId);
    final allItems = [for (final s in sections) ...s.items];
    final paging = widget.paging[selectedId];
    _shownRepoId = selectedId;
    // Re-checked after every layout: a page that lands without filling the
    // pane (or a filter that leaves few rows) must keep loading on its own.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _maybeLoadMore();
      }
    });

    // The bottom spacing sits OUTSIDE the scroll view (as margin, not
    // padding): inside the scroll view it would stretch the scroll viewport
    // — and with it the scrollbar track — past the card's bottom border to
    // the window edge. Outside, the viewport ends at the card's box.
    //
    // The scroll hint fades the TRAILING edge only: the section card's
    // column header is a PINNED sliver, so a leading fade would dim a header
    // that is not scrolling — the same false "there is more above" signal
    // the hint exists to avoid. Content sliding under the pinned header
    // already reads as scrolled.
    final detail = Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      child: CcScrollArea(
        fadeStart: false,
        child: CustomScrollView(
          controller: _scrollController,
          key: const PageStorageKey('pr-repo-detail'),
          slivers: [
            SliverPadding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.md),
              sliver: PrRepoSectionCard(
                items: selected.items,
                selectable: widget.selectable,
              ),
            ),
            if (paging != null && paging.hasMore)
              PrRepoLoadMoreFooter(
                paging: paging,
                onRetry: () => widget.onLoadMore?.call(selectedId),
              ),
          ],
        ),
      ),
    );

    final body = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: kPrRepoRailWidth,
          child: SingleChildScrollView(
            primary: false,
            child: PrRepoRail(
              entries: [
                for (final section in sections)
                  (
                    repo: section.repo,
                    count:
                        widget.totals[section.repo.id] ?? section.items.length,
                  ),
              ],
              selectedRepoId: selectedId,
              onSelect: _onSelect,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xl),
        Expanded(child: detail),
      ],
    );

    if (!widget.selectable) {
      return body;
    }
    return Stack(
      children: [
        body,
        Positioned(
          left: 0,
          right: 0,
          bottom: AppSpacing.lg,
          child: Center(child: PrBulkActionBar(allItems: allItems)),
        ),
      ],
    );
  }
}
