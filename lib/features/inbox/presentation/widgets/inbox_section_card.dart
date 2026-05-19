import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/usecases/classify_pr_inbox_use_case.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/forge/providers/forge_providers.dart';
import 'package:control_center/features/inbox/presentation/widgets/inbox_pr_row.dart';
import 'package:control_center/features/inbox/providers/inbox_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_list_display_prefs_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/github_user_avatar.dart';
import 'package:control_center/shared/widgets/pinned_header_bleed_guard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The display label of an inbox [section].
String inboxSectionLabel(AppLocalizations l10n, PrInboxSection section) =>
    switch (section) {
      PrInboxSection.needsYourReview => l10n.inboxSectionNeedsYourReview,
      PrInboxSection.returnedToYou => l10n.inboxSectionReturnedToYou,
      PrInboxSection.approved => l10n.inboxSectionApproved,
      PrInboxSection.drafts => l10n.inboxSectionDrafts,
      PrInboxSection.waitingForReviewers =>
        l10n.inboxSectionWaitingForReviewers,
      PrInboxSection.mergingAndMerged => l10n.inboxSectionMergingAndMerged,
      PrInboxSection.waitingForAuthor => l10n.inboxSectionWaitingForAuthor,
    };

/// One collapsible section as a SLIVER GROUP (it must sit in a
/// `CustomScrollView`'s slivers): the accordion header row (chevron, count,
/// title) is a pinned [SliverPersistentHeader] that stays at the top of the
/// viewport while the section's rows scroll beneath it, yielding to the next
/// section's header when its own body has scrolled past. When expanded, the
/// sortable column-header row and the PR rows scroll normally below it.
///
/// The card's frame is split across the two slivers: the header paints the
/// top edge (and the bottom edge while collapsed) plus the hairline that
/// separates it from the column labels — which doubles as the visual cut once
/// rows slide underneath — and the body paints the side and bottom edges.
class InboxSectionCard extends ConsumerWidget {
  /// Creates an [InboxSectionCard].
  const InboxSectionCard({
    super.key,
    required this.section,
    required this.items,
    this.headerKey,
  });

  /// Which section this card renders.
  final PrInboxSection section;

  /// The section's classified items (unsorted display order comes from the
  /// global [inboxSortProvider]).
  final List<PrInboxItem> items;

  /// Attached to the pinned header's box so the inbox rail's scrollspy can
  /// measure the section's reveal offset and rail taps can reveal it.
  final GlobalKey? headerKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final collapsed = ref.watch(
      collapsedInboxSectionsProvider.select((s) => s.contains(section)),
    );
    final sort = ref.watch(inboxSortProvider);
    final sorted = sortInboxItems(items, sort);
    // The shared display Grouping subgroups the rows within each lifecycle
    // section (author only; repository/status/none stay flat — the inbox is
    // never separated by repo and the sections already encode status).
    final grouping = ref.watch(
      prListDisplayPrefsProvider.select((p) => p.grouping),
    );
    final groups = groupInboxItems(
      sorted,
      grouping: grouping,
      viewerLogins: ref.watch(viewerLoginsProvider),
    );
    final expanded = !collapsed && sorted.isNotEmpty;

    return SliverMainAxisGroup(
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _SectionHeaderDelegate(
            anchorKey: headerKey,
            child: _SectionHeaderRow(
              section: section,
              count: items.length,
              collapsed: collapsed,
              onToggle: () => ref
                  .read(collapsedInboxSectionsProvider.notifier)
                  .toggle(section),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: AnimatedSize(
            duration: CcMotion.resolve(context, CcMotion.normal),
            curve: CcMotion.standard,
            alignment: Alignment.topCenter,
            child: !expanded
                ? const SizedBox(width: double.infinity)
                : DecoratedBox(
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
                        const _ColumnHeaderRow(),
                        CcDivider(color: tokens.borderSecondary),
                        for (final group in groups) ...[
                          if (group.label != null)
                            _SubgroupHeaderRow(
                              label: group.label!,
                              user: group.user,
                              count: group.items.length,
                            ),
                          for (var i = 0; i < group.items.length; i++) ...[
                            if (i > 0) CcDivider(color: tokens.borderSoft),
                            InboxPrRow(item: group.items[i]),
                          ],
                        ],
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

/// The pinned accordion header of an inbox section. The extent is exact and
/// fixed: the body line-box ([CcTypography.body] at 20px) plus the 10px
/// vertical padding, framed by the card's 1px top border and a 1px bottom
/// hairline. That hairline is not conditional: at rest it is precisely where
/// the divider between the header and the column labels used to sit, and once
/// pinned it is the edge rows scroll beneath.
///
/// The height does not change with [InboxSectionCard]'s collapsed state, and
/// deliberately so: a collapsed header used to carry an extra 2px shim above
/// its closing border, inherited from the box card that once wrapped the whole
/// section. Nothing fills it — the hover highlight covers only the content row
/// — so it read as a stray pale stub under the title and made the label sit
/// visibly off-centre in its own box.
class _SectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _SectionHeaderDelegate({required this.child, this.anchorKey});

  /// The header row content (chevron, count chip, title).
  final Widget child;

  /// Attached to the header's box so a host rail can measure and reveal the
  /// section.
  final GlobalKey? anchorKey;

  /// The header content's height: 10px vertical padding around the 20px
  /// [CcTypography.body] line box.
  static const double _contentExtent = 40;

  @override
  // +2 for the 1px top border and 1px bottom hairline.
  double get minExtent => _contentExtent + 2;

  @override
  double get maxExtent => minExtent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    // ClipRect keeps the header's own content inside its box; the bleed guard
    // covers the partial device pixel above it that the viewport's hard-edge
    // clip admits but the antialiased top border only partly paints — see
    // [PinnedHeaderBleedGuard]. Without it, the tips of the row scrolling
    // beneath show as a dashed line above the border.
    return PinnedHeaderBleedGuard(
      child: ClipRect(
        child: SizedBox(
          key: anchorKey,
          height: minExtent,
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
  bool shouldRebuild(_SectionHeaderDelegate old) =>
      old.child != child || old.anchorKey != anchorKey;
}

/// A quiet subgroup header inside a section (the shared display Grouping's
/// author mode): the author (avatar + login) with the subgroup's count, on
/// the secondary surface so it reads as structure, not a row.
class _SubgroupHeaderRow extends StatelessWidget {
  const _SubgroupHeaderRow({
    required this.label,
    required this.count,
    this.user,
  });

  final String label;
  final int count;
  final PrUser? user;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return Container(
      color: tokens.bgSecondary,
      padding: const EdgeInsets.symmetric(
        horizontal: InboxRowMetrics.hPad,
        vertical: 4,
      ),
      child: Row(
        children: [
          if (user != null) ...[
            GitHubUserAvatar(
              login: user!.login,
              avatarUrl: user!.avatarUrl,
              size: 14,
              showHoverCard: false,
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CcTypography.caption.copyWith(
                color: tokens.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            l10n.prFilterMatchCount(count),
            style: CcTypography.caption.copyWith(color: tokens.muted),
          ),
        ],
      ),
    );
  }
}

class _SectionHeaderRow extends StatelessWidget {
  const _SectionHeaderRow({
    required this.section,
    required this.count,
    required this.collapsed,
    required this.onToggle,
  });

  final PrInboxSection section;
  final int count;
  final bool collapsed;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final label = inboxSectionLabel(l10n, section);

    return CcTappable(
      onPressed: onToggle,
      semanticLabel: '$label · $count',
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        return ColoredBox(
          color: hovered ? tokens.hover : const Color(0x00000000),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 10,
            ),
            child: Row(
              children: [
                AnimatedRotation(
                  turns: collapsed ? -0.25 : 0,
                  duration: CcMotion.resolve(context, CcMotion.fast),
                  child: Icon(
                    AppIcons.chevronDown,
                    size: 16,
                    color: tokens.muted,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _CountChip(count: count),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CcTypography.body.copyWith(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return Container(
      constraints: const BoxConstraints(minWidth: 22),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tokens.hoverStrong,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadii.pill)),
      ),
      child: Text(
        '$count',
        style: CcTypography.caption.copyWith(
          color: count > 0 ? tokens.textSecondary : tokens.idle,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// The sortable column header (title / changes / updated) aligned with
/// [InboxRowMetrics]. One global sort drives every section.
class _ColumnHeaderRow extends ConsumerWidget {
  const _ColumnHeaderRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final sort = ref.watch(inboxSortProvider);
    // Mirrors the row cells gated by the shared display properties, so the
    // header stays aligned with what the rows actually render.
    final props = ref.watch(
      prListDisplayPrefsProvider.select((p) => p.properties),
    );

    void toggle(InboxSortColumn column) =>
        ref.read(inboxSortProvider.notifier).toggle(column);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: InboxRowMetrics.hPad,
        vertical: 4,
      ),
      child: Row(
        children: [
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
