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

/// One collapsible section card: a header row (chevron, count, title) and —
/// when expanded and non-empty — a sortable column-header row over the PR
/// rows. An empty section keeps its header with an inline muted "no pull
/// requests" so the fixed section list stays scannable.
class InboxSectionCard extends ConsumerWidget {
  /// Creates an [InboxSectionCard].
  const InboxSectionCard({
    super.key,
    required this.section,
    required this.items,
  });

  /// Which section this card renders.
  final PrInboxSection section;

  /// The section's classified items (unsorted display order comes from the
  /// global [inboxSortProvider]).
  final List<PrInboxItem> items;

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

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.panel,
        borderRadius: AppRadii.brMd,
        border: Border.all(color: tokens.borderSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeaderRow(
            section: section,
            count: items.length,
            collapsed: collapsed,
            onToggle: () => ref
                .read(collapsedInboxSectionsProvider.notifier)
                .toggle(section),
          ),
          AnimatedSize(
            duration: CcMotion.resolve(context, CcMotion.normal),
            curve: CcMotion.standard,
            alignment: Alignment.topCenter,
            child: !expanded
                ? const SizedBox(width: double.infinity)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CcDivider(color: tokens.borderSecondary),
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
          if (collapsed || sorted.isEmpty) const SizedBox(height: 2),
        ],
      ),
    );
  }
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
