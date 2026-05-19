import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_table/pr_bulk_action_bar.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_table/pr_repo_rail.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_table/pr_repo_section_card.dart';
import 'package:control_center/features/pr_review/providers/pr_table_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The repo-grouped PR table — the inbox's view (left rail + section card)
/// keyed by repository. The left rail lists every repo with its PR count
/// (repos are never hidden; a filtered-out repo shows a 0 count); selecting a
/// repo shows that repo's card in the detail pane and the first repo is
/// preselected. Cards are always open (no accordion) and sort updated-desc.
/// When [selectable] is on, rows carry checkboxes and a floating bulk-action
/// bar (close / assign / ask-for-review) rides at the bottom, acting across the
/// whole selection (not just the shown repo).
///
/// Shared by the pull-request queue and the user-profile PR view. Each screen
/// shapes and orders [sections]; this widget renders the rail + detail and
/// overlays the bulk bar.
class PrRepoView extends ConsumerStatefulWidget {
  /// Creates a [PrRepoView].
  const PrRepoView({
    super.key,
    required this.sections,
    this.selectable = false,
  });

  /// Every repo + its (filtered) items, in rail order. Never hidden — a repo
  /// with no matching items still appears with a 0 count.
  final List<PrRepoSectionData> sections;

  /// Whether rows are selectable and the bulk-action bar is shown.
  final bool selectable;

  @override
  ConsumerState<PrRepoView> createState() => _PrRepoViewState();
}

class _PrRepoViewState extends ConsumerState<PrRepoView> {
  final ScrollController _scrollController = ScrollController();

  /// The repo whose card is shown. Null until the user picks one — the build
  /// falls back to the first section so the first repo is preselected.
  String? _selectedRepoId;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sections = widget.sections;
    if (sections.isEmpty) {
      return const SizedBox.shrink();
    }

    final ids = {for (final s in sections) s.repo.id};
    final selectedId =
        (_selectedRepoId != null && ids.contains(_selectedRepoId))
        ? _selectedRepoId!
        : sections.first.repo.id;
    final selected = sections.firstWhere((s) => s.repo.id == selectedId);
    final allItems = [for (final s in sections) ...s.items];

    // The bottom spacing sits OUTSIDE the scroll view (as margin, not
    // padding): inside the scroll view it would stretch the scroll viewport
    // — and with it the scrollbar track — past the card's bottom border to
    // the window edge. Outside, the viewport ends at the card's box.
    final detail = Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      child: SingleChildScrollView(
        controller: _scrollController,
        key: const PageStorageKey('pr-repo-detail'),
        padding: const EdgeInsets.only(right: AppSpacing.md),
        child: PrRepoSectionCard(
          items: selected.items,
          selectable: widget.selectable,
        ),
      ),
    );

    final body = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 224,
          child: SingleChildScrollView(
            child: PrRepoRail(
              entries: [
                for (final section in sections)
                  (repo: section.repo, count: section.items.length),
              ],
              selectedRepoId: selectedId,
              onSelect: (id) => setState(() => _selectedRepoId = id),
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
