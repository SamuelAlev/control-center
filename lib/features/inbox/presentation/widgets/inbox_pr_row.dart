import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/usecases/classify_pr_inbox_use_case.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pull_request_list/age_text.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pull_request_list/pr_list_shared.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pull_request_list/pr_signal_line.dart'
    show PrDraftBadge;
import 'package:control_center/features/pr_review/providers/pr_list_display_prefs_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:control_center/shared/widgets/pr_title_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fixed column widths shared by [InboxPrRow] and the section card's column
/// header, so the state / changes / updated cells align down the table.
abstract final class InboxRowMetrics {
  /// The leading selection checkbox slot (present only in selectable surfaces
  /// like the PR queue / user profile; the inbox never selects). Column headers
  /// on those surfaces reserve `select + AppSpacing.sm` so the title column
  /// still lines up with the rows.
  static const double select = 16;

  /// The leading author-avatar slot. Rows render the avatar at this size; the
  /// column headers reserve the same width for their (smaller) person icon so
  /// the title column lines up with the row titles rather than sitting ~11px
  /// left of them.
  static const double avatar = 24;

  /// The status-glyph cluster (PR state + checks).
  static const double status = 52;

  /// The `+adds −dels` cell (wide enough for its sortable header label).
  static const double changes = 108;

  /// The age cell (wide enough for its sortable header label).
  static const double updated = 100;

  /// Horizontal row padding.
  static const double hPad = 16;
}

/// One table-like inbox row: avatar, title over `author · repo #number`, then
/// aligned status / diff-churn / age columns. Clicking opens the PR detail.
/// The shared display properties gate what renders: `author` (avatar +
/// subtitle prefix), `id`, `checks`, `diff`, and `updated`. The repo name is
/// always shown (the inbox has no repo sections, so the row meta is the only
/// repo context); `branch`/`comments` have no inbox element and only affect
/// the PR queue.
class InboxPrRow extends ConsumerWidget {
  /// Creates an [InboxPrRow].
  const InboxPrRow({
    super.key,
    required this.item,
    this.showRepo = true,
    this.selecting = false,
    this.selected = false,
    this.onToggleSelect,
  });

  /// The classified item to render.
  final PrInboxItem item;

  /// Whether to include the `owner/repo` name in the row's meta subtitle.
  /// True for the inbox (no repo sections, so the row carries the only repo
  /// context); false inside a repo section card where the section header
  /// already names the repo and repeating it in every row is noise.
  final bool showRepo;

  /// Whether selection mode is active on this surface (any row selected). Keeps
  /// the checkbox visible across every row while selecting. Ignored when
  /// [onToggleSelect] is null.
  final bool selecting;

  /// Whether this row is currently selected.
  final bool selected;

  /// When non-null, the row is selectable: a leading checkbox fades in (on
  /// hover or while [selecting]) and, while [selecting], a row tap toggles
  /// selection instead of opening the PR. Null on the (non-selectable) inbox.
  final VoidCallback? onToggleSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final pr = item.pr;
    final props = ref.watch(
      prListDisplayPrefsProvider.select((p) => p.properties),
    );
    final selectable = onToggleSelect != null;

    return CcTappable(
      onPressed: (selectable && selecting)
          ? onToggleSelect
          : () => openPrInRepo(ref, context, item.repo, pr.number),
      semanticLabel:
          '${stripInlineCode(pr.title)} · ${pr.repoFullName} #${pr.number}',
      builder: (context, states) {
        final hovered =
            states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused);
        final showCheckbox = selectable && (selecting || selected || hovered);
        return ColoredBox(
          color: selected
              ? tokens.accentSoft
              : hovered
              ? tokens.hover
              : const Color(0x00000000),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: InboxRowMetrics.hPad,
              vertical: 9,
            ),
            child: Row(
              children: [
                if (selectable) ...[
                  _InboxSelectCheckbox(
                    visible: showCheckbox,
                    selected: selected,
                    onTap: onToggleSelect!,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                if (props.contains(PrRowProperty.author)) ...[
                  buildAvatar(
                    pr.author,
                    pr.author?.login ?? '',
                    size: InboxRowMetrics.avatar,
                  ),
                  const SizedBox(width: AppSpacing.md),
                ],
                Expanded(
                  child: _TitleCell(pr: pr, props: props, showRepo: showRepo),
                ),
                const SizedBox(width: AppSpacing.md),
                SizedBox(
                  width: InboxRowMetrics.status,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _ReviewStateGlyph(pr: pr),
                      if (props.contains(PrRowProperty.checks)) ...[
                        const SizedBox(width: AppSpacing.sm),
                        _ChecksGlyph(status: pr.checksStatus),
                      ],
                    ],
                  ),
                ),
                if (props.contains(PrRowProperty.diff))
                  SizedBox(
                    width: InboxRowMetrics.changes,
                    child: _ChangesCell(
                      additions: pr.additions,
                      deletions: pr.deletions,
                    ),
                  ),
                if (props.contains(PrRowProperty.updated))
                  SizedBox(
                    width: InboxRowMetrics.updated,
                    child: _UpdatedCell(pr: pr),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TitleCell extends StatelessWidget {
  const _TitleCell({
    required this.pr,
    required this.props,
    this.showRepo = true,
  });

  final PullRequest pr;
  final Set<PrRowProperty> props;

  /// Whether to include the `owner/repo` name in the subtitle (dropped inside
  /// a repo section card, where the header already names the repo).
  final bool showRepo;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final author = pr.author?.login ?? '—';

    // The subtitle assembles the enabled properties (`author · repo #number`
    // down to title-only). On the inbox the repo name is forced on (there are
    // no repo sections, so the row meta is the only repo context); inside a
    // repo section card [showRepo] is false and only `#number` remains.
    final repoPart = [
      if (showRepo) pr.repoFullName,
      if (props.contains(PrRowProperty.id)) '#${pr.number}',
    ].join(' ');
    final subtitle = [
      if (props.contains(PrRowProperty.author)) author,
      if (repoPart.isNotEmpty) repoPart,
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Flexible(
              child: PrTitleText(
                pr.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CcTypography.body.copyWith(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (pr.isDraft) ...[
              const SizedBox(width: AppSpacing.sm),
              const PrDraftBadge(),
            ],
          ],
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 1),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CcTypography.caption.copyWith(color: tokens.muted),
          ),
        ],
      ],
    );
  }
}

/// The PR's review-decision glyph. Shape + tooltip carry the state (never
/// colour alone); renders nothing when there is no decision yet.
class _ReviewStateGlyph extends StatelessWidget {
  const _ReviewStateGlyph({required this.pr});

  final PullRequest pr;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final (IconData, Color, String)? glyph = switch (pr.reviewDecision) {
      PrReviewDecision.approved => (
        AppIcons.checkCircle2,
        tokens.success,
        l10n.inboxReviewApproved,
      ),
      PrReviewDecision.changesRequested => (
        AppIcons.circleDot,
        tokens.warn,
        l10n.inboxReviewChangesRequested,
      ),
      PrReviewDecision.reviewRequired || PrReviewDecision.none => null,
    };
    if (glyph == null) {
      return const SizedBox(width: 16);
    }
    return CcTooltip(
      message: glyph.$3,
      child: Icon(glyph.$1, size: 16, color: glyph.$2),
    );
  }
}

/// The rolled-up CI glyph: distinct shapes per state + tooltip, so the state
/// survives grayscale. Renders a placeholder gap when no checks exist.
class _ChecksGlyph extends StatelessWidget {
  const _ChecksGlyph({required this.status});

  final PrChecksStatus status;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final (IconData, Color, String)? glyph = switch (status) {
      PrChecksStatus.passing => (
        AppIcons.checkCircle,
        tokens.success,
        l10n.checksPassing,
      ),
      PrChecksStatus.failing => (
        AppIcons.xCircle,
        tokens.danger,
        l10n.checksFailing,
      ),
      PrChecksStatus.pending => (
        AppIcons.clock3,
        tokens.warn,
        l10n.checksRunning,
      ),
      PrChecksStatus.none => null,
    };
    if (glyph == null) {
      return const SizedBox(width: 16);
    }
    return CcTooltip(
      message: glyph.$3,
      child: Icon(glyph.$1, size: 16, color: glyph.$2),
    );
  }
}

class _ChangesCell extends StatelessWidget {
  const _ChangesCell({required this.additions, required this.deletions});

  final int additions;
  final int deletions;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final base = CcTypography.caption.copyWith(
      fontFamily: CcFonts.codeFamily,
      fontFeatures: const [FontFeature.tabularFigures()],
      fontWeight: FontWeight.w500,
      color: tokens.textTertiary,
    );
    if (additions == 0 && deletions == 0) {
      return Text(
        '—',
        textAlign: TextAlign.right,
        style: base.copyWith(color: tokens.idle),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('+$additions', style: base.copyWith(color: tokens.success)),
        const SizedBox(width: 4),
        Text('−$deletions', style: base.copyWith(color: tokens.danger)),
      ],
    );
  }
}

class _UpdatedCell extends StatelessWidget {
  const _UpdatedCell({required this.pr});

  final PullRequest pr;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final style = CcTypography.caption.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
      color: tokens.textTertiary,
    );
    final date = pr.isMerged ? (pr.mergedAt ?? pr.updatedAt) : pr.updatedAt;
    final age = AgeText(
      ageText: formatRelativeCompact(date),
      date: date,
      neutral: tokens.muted,
      style: style,
    );
    final aligned = Align(alignment: Alignment.centerRight, child: age);
    if (date == null) {
      return aligned;
    }
    return Align(
      alignment: Alignment.centerRight,
      child: AppTimestamp(dateTime: date, child: age),
    );
  }
}

/// The leading selection checkbox on selectable PR-table surfaces (the queue
/// and user-profile repo sections), faded in on hover / while selecting. A
/// fixed [InboxRowMetrics.select] slot so the title column stays aligned with
/// the section's column header. Mirrors the queue row's checkbox treatment.
class _InboxSelectCheckbox extends StatelessWidget {
  const _InboxSelectCheckbox({
    required this.visible,
    required this.selected,
    required this.onTap,
  });

  final bool visible;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final accent = tokens.accent;
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: const Duration(milliseconds: 120),
      child: IgnorePointer(
        ignoring: !visible,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: InboxRowMetrics.select,
            height: InboxRowMetrics.select,
            decoration: BoxDecoration(
              color: selected ? accent : tokens.panel,
              borderRadius: AppRadii.brSm,
              border: Border.all(color: selected ? accent : tokens.lineStrong),
            ),
            child: selected
                ? Icon(AppIcons.check, size: 11, color: tokens.accentOn)
                : null,
          ),
        ),
      ),
    );
  }
}

/// Formats [dt] as the inbox's compact age ("22m", "4d", "2mo") — the table
/// column is too narrow for the prose form.
String formatRelativeCompact(DateTime? dt, {DateTime? now}) {
  if (dt == null) {
    return '';
  }
  final reference = now ?? DateTime.now();
  final diff = reference.difference(dt);
  if (diff.isNegative || diff.inMinutes < 1) {
    return 'now';
  }
  if (diff.inMinutes < 60) {
    return '${diff.inMinutes}m';
  }
  if (diff.inHours < 24) {
    return '${diff.inHours}h';
  }
  if (diff.inDays < 30) {
    return '${diff.inDays}d';
  }
  if (diff.inDays < 365) {
    return '${(diff.inDays / 30).floor()}mo';
  }
  return '${(diff.inDays / 365).floor()}y';
}
