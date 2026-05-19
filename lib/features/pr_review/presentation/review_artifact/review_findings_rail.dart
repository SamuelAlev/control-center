import 'package:cc_domain/features/pr_review/domain/value_objects/review_node_payload.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/utils/review_item_palette.dart';
import 'package:control_center/features/pr_review/providers/review_artifact_providers.dart';
import 'package:control_center/features/pr_review/providers/review_filter_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/collapsible_sidebar_section.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The review's findings as a navigation rail, grouped by priority.
///
/// The same shape as the inbox rail and the PR sidebar — a quiet
/// `bgSecondary` column of collapsible groups, each with a live count — because
/// this is the same job: pick one item out of many and read it beside its
/// context. The findings used to be a flat accordion below the report, where
/// "54 open findings" was a wall you scrolled and the priority that decides
/// what to read first was a chip on row 40.
///
/// Priority leads the grouping rather than file or reviewer: P0 blocks the
/// merge, P3 is a nit, and that ordering is the only one that answers "what do
/// I do next".
class ReviewFindingsRail extends ConsumerWidget {
  /// Creates a [ReviewFindingsRail].
  const ReviewFindingsRail({
    super.key,
    required this.spaceId,
    required this.findings,
    required this.selectedId,
    required this.onSelect,
  });

  /// The review space whose filters this rail edits.
  final String spaceId;

  /// Every finding of the review, already sorted.
  final List<ReviewFinding> findings;

  /// The message id of the open finding, or null when the report is showing.
  final String? selectedId;

  /// Invoked with a finding's message id; null clears back to the report.
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final kinds = ref.watch(reviewKindFilterProvider(spaceId));
    final statuses = ref.watch(reviewStatusFilterProvider(spaceId));
    // The rail lists what the scroll shows. Filtering here and rendering the
    // unfiltered set there (or the reverse) is how a rail comes to point at a
    // row that is not on screen.
    final shown = applyReviewFilters(
      findings,
      kindOf: (f) => f.payload.kind,
      statusOf: (f) => f.payload.status,
      kinds: kinds,
      statuses: statuses,
      showDismissed: ref.watch(reviewShowDismissedProvider(spaceId)),
    );
    // What the review's own level set aside. Read from the finalized summary
    // rather than recomputed from the current workspace setting, so an old
    // review keeps the grouping it was finalized with.
    final nitpickIds =
        ref.watch(reviewArtifactProvider(spaceId))?.nitpickMessageIds ??
        const <String>{};
    final byPriority = <ReviewNodePriority, List<ReviewFinding>>{
      for (final p in ReviewNodePriority.values) p: [],
    };
    final nitpicks = <ReviewFinding>[];
    for (final f in shown) {
      if (nitpickIds.contains(f.message.id)) {
        nitpicks.add(f);
      } else {
        byPriority[f.payload.priority]!.add(f);
      }
    }

    return ColoredBox(
      color: tokens.bgSecondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ReportRow(
            selected: selectedId == null,
            label: l10n.reviewRailReport,
            onPressed: () => onSelect(null),
          ),
          const CcDivider(),
          // The filters live here, beside the counts they change, rather than
          // in the scroll beside the findings: a filter bar inside the reading
          // column scrolls away exactly when a long list makes you want it.
          _FilterSection(spaceId: spaceId, kinds: kinds, statuses: statuses),
          const CcDivider(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final priority in ReviewNodePriority.values)
                    // An empty priority is dropped rather than shown at zero:
                    // "P0 · 0" is a row that can never be opened, and four of
                    // them push the findings that exist below the fold.
                    if (byPriority[priority]!.isNotEmpty)
                      CollapsibleSidebarSection(
                        icon: _priorityIcon(priority),
                        label: priority.wireName.toUpperCase(),
                        count: '${byPriority[priority]!.length}',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final f in byPriority[priority]!)
                              _FindingRow(
                                finding: f,
                                selected: f.message.id == selectedId,
                                onPressed: () => onSelect(f.message.id),
                              ),
                          ],
                        ),
                      ),
                  // Last and collapsed: the level decided these are not worth
                  // interrupting the read for, but they are still here and
                  // still counted — the group is a demotion, not a filter.
                  if (nitpicks.isNotEmpty)
                    CollapsibleSidebarSection(
                      icon: AppIcons.dot,
                      label: l10n.reviewNitpicksGroup(nitpicks.length),
                      count: '${nitpicks.length}',
                      initiallyExpanded: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final f in nitpicks)
                            _FindingRow(
                              finding: f,
                              selected: f.message.id == selectedId,
                              onPressed: () => onSelect(f.message.id),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Shape as well as color, so priority survives a colorblind reader and a
  /// grayscale screenshot (the accessibility floor: never status by color
  /// alone).
  IconData _priorityIcon(ReviewNodePriority priority) => switch (priority) {
    ReviewNodePriority.p0 => AppIcons.octagonAlert,
    ReviewNodePriority.p1 => AppIcons.triangleAlert,
    ReviewNodePriority.p2 => AppIcons.info,
    ReviewNodePriority.p3 => AppIcons.circleDot,
  };
}

/// The rail's first row: back to the review report.
class _ReportRow extends StatelessWidget {
  const _ReportRow({
    required this.selected,
    required this.label,
    required this.onPressed,
  });

  final bool selected;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return Semantics(
      selected: selected,
      child: CcTappable(
        onPressed: onPressed,
        semanticLabel: label,
        builder: (context, states) => ColoredBox(
          color: _rowFill(
            tokens,
            selected: selected,
            hovered: states.contains(WidgetState.hovered),
          ),
          child: SizedBox(
            height: kCcSidebarItemExtent,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  Icon(
                    AppIcons.fileText,
                    size: 14,
                    color: selected ? tokens.textPrimary : tokens.textTertiary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CcTypography.caption.copyWith(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.w500,
                        height: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One finding in the rail: kind icon, `file:line`, confidence.
///
/// The body is deliberately NOT here. A row that tries to preview the finding
/// wraps to four lines, and fifty of those are the wall this rail replaced.
/// The path is what a reader scans by; the detail pane holds the rest.
class _FindingRow extends StatelessWidget {
  const _FindingRow({
    required this.finding,
    required this.selected,
    required this.onPressed,
  });

  final ReviewFinding finding;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final payload = finding.payload;
    final decor = reviewItemDecor(context, payload.kind, payload.priority);
    final path = payload.anchor.filePath;
    final line = payload.anchor.lineNumber;
    final label = path == null
        ? finding.message.content
        : '${path.split('/').last}${line == null ? '' : ':$line'}';
    // A dismissed or resolved finding stays listed but recedes: it is part of
    // the review's record, and hiding it makes the counts disagree with the
    // list.
    final settled =
        payload.status == ReviewNodeStatus.dismissed ||
        payload.status == ReviewNodeStatus.resolved;

    return Semantics(
      selected: selected,
      child: CcTappable(
        onPressed: onPressed,
        semanticLabel: '${decor.label} · $label',
        builder: (context, states) => ColoredBox(
          color: _rowFill(
            tokens,
            selected: selected,
            hovered: states.contains(WidgetState.hovered),
          ),
          child: Opacity(
            opacity: settled ? 0.55 : 1,
            child: SizedBox(
              height: kCcSidebarItemExtent,
              child: Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.lg,
                  right: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Icon(decor.icon, size: 13, color: decor.accent),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CcTypography.caption.copyWith(
                          color: tokens.textPrimary,
                          height: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '${(payload.confidence * 100).round()}%',
                      style: CcTypography.monoNum.copyWith(
                        fontSize: 11,
                        color: tokens.textTertiary,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The rail's one selection language, shared by both row kinds.
///
/// Pre-blended onto the rail's own fill rather than layered as a translucent
/// box: SkWasm double-paints glyphs under a translucent fill, and an idle row
/// holds alpha-0 of the hover token so the first hover does not flash through
/// transparent black. Same reasoning as the inbox rail's row, same result.
Color _rowFill(
  DesignSystemTokens tokens, {
  required bool selected,
  required bool hovered,
}) {
  if (selected) {
    return Color.alphaBlend(tokens.hoverStrong, tokens.bgSecondary);
  }
  if (hovered) {
    return Color.alphaBlend(tokens.hover, tokens.bgSecondary);
  }
  return tokens.hover.withValues(alpha: 0);
}

/// The rail's filter block: finding kind and status, as toggles.
class _FilterSection extends ConsumerWidget {
  const _FilterSection({
    required this.spaceId,
    required this.kinds,
    required this.statuses,
  });

  final String spaceId;
  final Set<ReviewNodeKind> kinds;
  final Set<ReviewNodeStatus> statuses;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FilterLabel(text: l10n.reviewFilterKind, tokens: tokens),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final kind in ReviewNodeKind.values)
                // `ticket` is a card spawned FROM a review, not a finding in
                // it; offering it as a filter would offer an always-empty set.
                if (kind != ReviewNodeKind.ticket)
                  _Toggle(
                    label: _kindLabel(l10n, kind),
                    active: kinds.contains(kind),
                    onTap: () => ref
                        .read(reviewKindFilterProvider(spaceId).notifier)
                        .update((s) => _toggled(s, kind)),
                  ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _FilterLabel(text: l10n.reviewFilterStatus, tokens: tokens),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final status in [
                ReviewNodeStatus.open,
                ReviewNodeStatus.consensusReady,
                ReviewNodeStatus.resolved,
              ])
                _Toggle(
                  label: _statusLabel(l10n, status),
                  active: statuses.contains(status),
                  onTap: () => ref
                      .read(reviewStatusFilterProvider(spaceId).notifier)
                      .update((s) => _toggled(s, status)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Set<T> _toggled<T>(Set<T> current, T value) => current.contains(value)
      ? ({...current}..remove(value))
      : {...current, value};

  String _kindLabel(AppLocalizations l10n, ReviewNodeKind kind) =>
      switch (kind) {
        ReviewNodeKind.bug => l10n.reviewKindBug,
        ReviewNodeKind.suggestion => l10n.reviewKindSuggestion,
        ReviewNodeKind.recommendation => l10n.reviewKindRecommendation,
        ReviewNodeKind.question => l10n.reviewKindQuestion,
        ReviewNodeKind.ticket => l10n.reviewKindTicket,
      };

  String _statusLabel(AppLocalizations l10n, ReviewNodeStatus status) =>
      switch (status) {
        ReviewNodeStatus.open => l10n.openStatus,
        ReviewNodeStatus.consensusReady => l10n.consensus,
        ReviewNodeStatus.resolved => l10n.resolved,
        ReviewNodeStatus.dismissed => l10n.dismissed,
      };
}

class _FilterLabel extends StatelessWidget {
  const _FilterLabel({required this.text, required this.tokens});

  final String text;
  final DesignSystemTokens tokens;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: CcTypography.label.copyWith(color: tokens.textTertiary),
  );
}

/// One filter toggle. Square, hairline, accent-on-active: the design system's
/// chip, not a Material one.
class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return Semantics(
      selected: active,
      child: CcTappable(
        onPressed: onTap,
        semanticLabel: label,
        builder: (context, states) => DecoratedBox(
          decoration: BoxDecoration(
            color: active
                ? Color.alphaBlend(tokens.hoverStrong, tokens.bgSecondary)
                : (states.contains(WidgetState.hovered)
                      ? Color.alphaBlend(tokens.hover, tokens.bgSecondary)
                      : tokens.bgPrimary),
            border: Border.all(
              color: active ? tokens.fgBrandPrimary : tokens.borderSecondary,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 3,
            ),
            child: Text(
              label,
              style: CcTypography.caption.copyWith(
                color: active ? tokens.fgBrandPrimary : tokens.textSecondary,
                height: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
