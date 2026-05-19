import 'package:cc_domain/features/pr_review/domain/usecases/classify_pr_inbox_use_case.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/inbox/presentation/widgets/inbox_pr_row.dart';
import 'package:control_center/features/inbox/providers/inbox_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_list_display_prefs_provider.dart';
import 'package:control_center/features/pr_review/providers/pr_table_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/pinned_header_bleed_guard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The detail table for one repository in the repo-grouped PR view — the
/// inbox's section card with both the accordion and the repo-title header
/// removed: which repo this is (name + count) already reads from the selected
/// left-rail entry, so the card is just a sortable column header (hosting the
/// "select all" box, aligned with the row checkboxes) over the repo's rows.
/// Rows sort by the shared [inboxSortProvider] (default: updated-desc) and never
/// repeat the repo name ([InboxPrRow.showRepo] is false here).
///
/// Built as a SLIVER GROUP (it must sit in a `CustomScrollView`'s slivers):
/// the column header is a pinned [SliverPersistentHeader] so the checkbox /
/// title / changes / updated labels stay at the top of the viewport while the
/// rows scroll beneath. The card's frame splits across the two slivers — the
/// header paints the top edge and the hairline under the labels, the body the
/// side and bottom edges.
class PrRepoSectionCard extends ConsumerWidget {
  /// Creates a [PrRepoSectionCard].
  const PrRepoSectionCard({
    super.key,
    required this.items,
    this.selectable = false,
  });

  /// The repo's pull requests (already filtered; sorted here for display).
  final List<PrInboxItem> items;

  /// Whether rows carry a selection checkbox and the column header a
  /// "select all" box.
  final bool selectable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final sort = ref.watch(inboxSortProvider);
    final sorted = sortInboxItems(items, sort);

    final selection = selectable
        ? ref.watch(prTableSelectionProvider)
        : const <String>{};
    final selecting = selection.isNotEmpty;
    final allSelected =
        sorted.isNotEmpty && sorted.every((i) => selection.contains(i.key));

    void toggleAll() {
      final keys = sorted.map((i) => i.key);
      final notifier = ref.read(prTableSelectionProvider.notifier);
      if (allSelected) {
        notifier.removeAll(keys);
      } else {
        notifier.addAll(keys);
      }
    }

    final cardDecoration = BoxDecoration(
      color: tokens.panel,
      borderRadius: AppRadii.brMd,
      border: Border.all(color: tokens.borderSecondary),
    );

    if (sorted.isEmpty) {
      return SliverToBoxAdapter(
        child: DecoratedBox(
          decoration: cardDecoration,
          child: const _EmptyRow(),
        ),
      );
    }

    return SliverMainAxisGroup(
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _ColumnHeaderDelegate(
            child: _ColumnHeaderRow(
              selectable: selectable,
              allSelected: allSelected,
              onToggleAll: selectable ? toggleAll : null,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: tokens.panel,
              border: Border(
                left: BorderSide(color: tokens.borderSecondary),
                right: BorderSide(color: tokens.borderSecondary),
                bottom: BorderSide(color: tokens.borderSecondary),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < sorted.length; i++) ...[
                  if (i > 0) CcDivider(color: tokens.borderSoft),
                  InboxPrRow(
                    item: sorted[i],
                    showRepo: false,
                    selecting: selecting,
                    selected: selectable && selection.contains(sorted[i].key),
                    onToggleSelect: selectable
                        ? () => ref
                              .read(prTableSelectionProvider.notifier)
                              .toggle(sorted[i].key)
                        : null,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The pinned column header of a repo's PR table. The extent is exact and
/// fixed: the 22px sort-header line box (3px padding + the 16px
/// [CcTypography.caption] line) inside 8px vertical padding, framed by the
/// card's 1px top border and the 1px hairline that separates the labels from
/// the rows — the cut the rows scroll beneath once the header is pinned.
class _ColumnHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _ColumnHeaderDelegate({required this.child});

  /// The column header content (select-all box, sortable labels).
  final Widget child;

  static const double _extent = 40;

  @override
  double get minExtent => _extent;

  @override
  double get maxExtent => _extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    // See [PinnedHeaderBleedGuard]: the ClipRect keeps the header's content
    // inside its box, the guard covers the partial device pixel above the top
    // border where the row scrolling beneath would otherwise show through.
    return PinnedHeaderBleedGuard(
      child: ClipRect(
        child: SizedBox(
          height: _extent,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: tokens.panel,
              border: Border.all(color: tokens.borderSecondary),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_ColumnHeaderDelegate old) => old.child != child;
}

/// A presentational "select all" checkbox for the column header: filled accent
/// box when every row is selected, an empty bordered box otherwise. The header
/// row owns the tap.
class _SelectAllBox extends StatelessWidget {
  const _SelectAllBox({
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final accent = tokens.accent;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: InboxRowMetrics.select,
        height: InboxRowMetrics.select,
        decoration: BoxDecoration(
          color: selected ? accent : tokens.panel,
          borderRadius: AppRadii.brSm,
          border: Border.all(
            color: selected
                ? accent
                : enabled
                ? tokens.lineStrong
                : tokens.borderSecondary,
          ),
        ),
        child: selected
            ? Icon(AppIcons.check, size: 11, color: tokens.accentOn)
            : null,
      ),
    );
  }
}

/// The compact "no open pull requests" line for a repo with no matching PRs
/// (repos are never hidden; a filtered-out repo shows a 0 count in the rail and
/// this row in the detail).
class _EmptyRow extends StatelessWidget {
  const _EmptyRow();

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: InboxRowMetrics.hPad,
        vertical: 12,
      ),
      child: Text(
        l10n.noOpenPullRequests,
        style: CcTypography.caption.copyWith(color: tokens.idle),
      ),
    );
  }
}

/// The sortable column header (title / changes / updated) aligned with
/// [InboxRowMetrics], hosting the leading "select all" checkbox when
/// [selectable] so it lines up with the row checkboxes, right beside the author
/// (person) icon. One global sort ([inboxSortProvider]) drives every section.
class _ColumnHeaderRow extends ConsumerWidget {
  const _ColumnHeaderRow({
    required this.selectable,
    required this.allSelected,
    required this.onToggleAll,
  });

  final bool selectable;
  final bool allSelected;
  final VoidCallback? onToggleAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final sort = ref.watch(inboxSortProvider);
    final props = ref.watch(
      prListDisplayPrefsProvider.select((p) => p.properties),
    );

    void toggle(InboxSortColumn column) =>
        ref.read(inboxSortProvider.notifier).toggle(column);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: InboxRowMetrics.hPad,
        vertical: 8,
      ),
      child: Row(
        children: [
          if (selectable) ...[
            _SelectAllBox(
              selected: allSelected,
              enabled: onToggleAll != null,
              onTap: onToggleAll,
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          if (props.contains(PrRowProperty.author)) ...[
            // Reserve the same width the rows give their avatar so the title
            // column lines up; the person icon centers within that slot.
            SizedBox(
              width: InboxRowMetrics.avatar,
              child: Icon(AppIcons.user, size: 13, color: tokens.idle),
            ),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: _SortHeader(
                label: l10n.inboxColumnTitle,
                column: InboxSortColumn.title,
                sort: sort,
                onTap: () => toggle(InboxSortColumn.title),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          const SizedBox(width: InboxRowMetrics.status),
          if (props.contains(PrRowProperty.diff))
            SizedBox(
              width: InboxRowMetrics.changes,
              child: Align(
                alignment: Alignment.centerRight,
                child: _SortHeader(
                  label: l10n.inboxColumnChanges,
                  column: InboxSortColumn.changes,
                  sort: sort,
                  onTap: () => toggle(InboxSortColumn.changes),
                  rightAligned: true,
                ),
              ),
            ),
          if (props.contains(PrRowProperty.updated))
            SizedBox(
              width: InboxRowMetrics.updated,
              child: Align(
                alignment: Alignment.centerRight,
                child: _SortHeader(
                  label: l10n.inboxColumnUpdated,
                  column: InboxSortColumn.updated,
                  sort: sort,
                  onTap: () => toggle(InboxSortColumn.updated),
                  rightAligned: true,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SortHeader extends StatelessWidget {
  const _SortHeader({
    required this.label,
    required this.column,
    required this.sort,
    required this.onTap,
    this.rightAligned = false,
  });

  final String label;
  final InboxSortColumn column;
  final InboxSort sort;
  final VoidCallback onTap;

  /// Whether this header labels a right-aligned value column (changes /
  /// updated). When set, the sort caret is nudged right by its optical padding
  /// so its *visible* edge meets the flush-right values below, rather than the
  /// icon box's edge (the chevron glyph carries ~2px of transparent inset).
  final bool rightAligned;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final active = sort.column == column;
    final color = active ? tokens.textSecondary : tokens.idle;

    return CcTappable(
      onPressed: onTap,
      semanticLabel: label,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        final Widget caret = Icon(
          active
              ? (sort.ascending ? AppIcons.chevronUp : AppIcons.chevronDown)
              : AppIcons.chevronsUpDown,
          size: 12,
          color: hovered ? tokens.textSecondary : color,
        );
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CcTypography.caption.copyWith(
                    color: hovered ? tokens.textSecondary : color,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 3),
              // Nudge the caret right by its optical padding on right-aligned
              // value columns so its visible edge meets the flush-right values.
              rightAligned
                  ? Transform.translate(
                      offset: const Offset(_caretOpticalInset, 0),
                      child: caret,
                    )
                  : caret,
            ],
          ),
        );
      },
    );
  }
}

/// The chevron glyph's built-in transparent right padding at size 12: the
/// distance the caret is nudged right so its visible edge aligns with the
/// flush-right value columns below it.
const double _caretOpticalInset = 2;
