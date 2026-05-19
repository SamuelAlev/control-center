import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/domain/entities/repo.dart';
import 'package:control_center/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/features/pr_review/presentation/utils/decision_lane.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_status_badge.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pull_request_list/pr_list_merge_button.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pull_request_list/pr_list_shared.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pull_request_list/pr_peek_panel.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pull_request_list/pr_signal_line.dart';
import 'package:control_center/features/pr_review/providers/pr_filter_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_lane_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/pr_title_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Maximum content width for the PR list. Beyond this the list centres in the
/// viewport instead of stretching edge-to-edge, so dense rows stay scannable
/// and metadata sits a comfortable distance from the title.
const double kPrListMaxWidth = 1120;

/// A bordered, hairline-divided container that holds [rows]. The PR queue reads
/// as one flat instrument table (a single 1px border, internal dividers)
/// rather than a stack of separate cards — denser, and on-brand for the cockpit.
class PrGroupCard extends StatelessWidget {
  /// Creates a [PrGroupCard] wrapping [rows].
  const PrGroupCard({super.key, required this.rows});

  /// The row widgets, rendered top-to-bottom with dividers between them.
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final border = tokens.borderSecondary;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.panel,
        borderRadius: AppRadii.brLg,
        border: Border.all(color: border),
      ),
      child: ClipRRect(
        borderRadius: AppRadii.brLg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) Divider(height: 1, thickness: 1, color: border),
              rows[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// A dense, agent-native pull-request row. A leading selection checkbox + PR
/// status icon precede a three-line body — title (+ status badges), the
/// metadata line, and the signal line (author, checks, diff, conversation) —
/// and a trailing action cluster whose primary button adapts to the PR's
/// [DecisionLane]. The peek chevron expands an inline [PrPeekPanel] beneath.
class PrListRow extends ConsumerStatefulWidget {
  /// Creates a [PrListRow].
  const PrListRow({
    super.key,
    required this.pr,
    required this.repo,
    required this.lane,
    required this.rowKey,
    required this.focusNode,
    this.showRepo = false,
    this.showReviewBadge = true,
    this.browseOnly = false,
  });

  /// The pull request to render.
  final PullRequest pr;

  /// The repo the PR belongs to (drives navigation, merge, and the repo label).
  final Repo repo;

  /// The decision lane this PR falls into (drives the primary action).
  final DecisionLane lane;

  /// Stable key for scroll-into-view from keyboard navigation.
  final GlobalKey rowKey;

  /// Focus node so list-cursor shortcuts can drive focus.
  final FocusNode focusNode;

  /// Whether to show the repo full name in the meta line.
  final bool showRepo;

  /// Whether to show the amber "Review requested" badge beside the title.
  final bool showReviewBadge;

  /// Browse-only mode (the user-profile list): hides the selection checkbox,
  /// always opens the PR on tap, and replaces the lane-adaptive primary action
  /// with a plain "Open" button (a merged/closed PR has no merge/review
  /// action). Keyboard peek + open and the row's design are unchanged.
  final bool browseOnly;

  @override
  ConsumerState<PrListRow> createState() => _PrListRowState();
}

class _PrListRowState extends ConsumerState<PrListRow> {
  bool _hovered = false;

  void _setHovered(bool v) {
    if (_hovered == v) {
      return;
    }
    setState(() => _hovered = v);
  }

  void _openPr() {
    ref.read(selectedPrNumberProvider.notifier).select(widget.pr.number);
    openPrInRepo(ref, context, widget.repo, widget.pr.number);
  }

  @override
  Widget build(BuildContext context) {
    final pr = widget.pr;
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final me = ref.watch(currentUserLoginProvider);
    final peeked = ref.watch(
      peekedPrsProvider.select((s) => s.contains(pr.number)),
    );
    // Selection/batch machinery is suppressed in browse-only mode (profiles),
    // so the row never enters selection mode and never shows a checkbox.
    final (selecting, selected) = widget.browseOnly
        ? (false, false)
        : ref.watch(
            prSelectionProvider.select(
              (s) => (s.selecting, s.contains(pr.number)),
            ),
          );
    final reviewRequired =
        widget.showReviewBadge &&
        me.isNotEmpty &&
        pr.requestedReviewers.any((r) => r.login.toLowerCase() == me);

    final showCheckbox =
        !widget.browseOnly && (selecting || selected || _hovered);

    final rowContent = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.browseOnly) ...[
            _SelectCheckbox(
              visible: showCheckbox,
              selected: selected,
              onTap: () =>
                  ref.read(prSelectionProvider.notifier).toggle(pr.number),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: PrStatusIcon(pr: pr, size: 16),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
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
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: tokens.textPrimary,
                          height: 1.3,
                        ),
                      ),
                    ),
                    if (pr.isDraft) ...[
                      const SizedBox(width: AppSpacing.sm),
                      const PrDraftBadge(),
                    ],
                    if (reviewRequired) ...[
                      const SizedBox(width: AppSpacing.sm),
                      AttentionBadge(
                        icon: LucideIcons.eye,
                        label: l10n.reviewRequested,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                PrMetaLine(
                  pr: pr,
                  repo: widget.repo,
                  showRepo: widget.showRepo,
                ),
                const SizedBox(height: AppSpacing.sm),
                PrSignalLine(pr: pr, currentLogin: me),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          _RowActionCluster(
            pr: pr,
            repo: widget.repo,
            lane: widget.lane,
            peeked: peeked,
            browseOnly: widget.browseOnly,
            onOpen: _openPr,
            onTogglePeek: () =>
                ref.read(peekedPrsProvider.notifier).toggle(pr.number),
          ),
        ],
      ),
    );

    return KeyedSubtree(
      key: widget.rowKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label:
                'PR #${pr.number}: ${stripInlineCode(pr.title)}. '
                '${prStatusIconData(pr, context).label}. ${widget.repo.fullName}.',
            button: true,
            selected: selected,
            child: _RowTappable(
              focusNode: widget.focusNode,
              hoverColor: tokens.hover,
              selectedColor: tokens.accentSoft,
              selected: selected,
              onHoverChange: _setHovered,
              onTap: selecting
                  ? () =>
                        ref.read(prSelectionProvider.notifier).toggle(pr.number)
                  : _openPr,
              child: rowContent,
            ),
          ),
          if (peeked) PrPeekPanel(pr: pr, onOpen: _openPr),
        ],
      ),
    );
  }
}

/// Keyboard activation map for a focused PR row: Enter activates (opens the
/// PR); Space is mapped to [DoNothingAndStopPropagationIntent] so the focused
/// row no longer consumes it via the app-wide Space→[ActivateIntent] shortcut,
/// leaving Space free for the keybinding dispatcher's inline-peek command.
const Map<ShortcutActivator, Intent> _rowActivationShortcuts = {
  SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
  SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
  SingleActivator(LogicalKeyboardKey.space):
      DoNothingAndStopPropagationIntent(),
};

/// Hover/focus/selection-aware wrapper for a row. A background tint reports
/// hover and selection; the focus ring is the only focus indicator.
class _RowTappable extends StatelessWidget {
  const _RowTappable({
    required this.child,
    required this.onTap,
    required this.focusNode,
    required this.onHoverChange,
    required this.hoverColor,
    required this.selectedColor,
    required this.selected,
  });

  final Widget child;
  final VoidCallback onTap;
  final FocusNode focusNode;
  final ValueChanged<bool> onHoverChange;
  final Color hoverColor;
  final Color selectedColor;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return CcTappable(
      onPressed: onTap,
      focusNode: focusNode,
      // Enter opens the PR; Space is deliberately suppressed here so the focused
      // row doesn't swallow it via the global Space→ActivateIntent shortcut.
      // That frees Space for the central keybinding dispatcher's `pr.list-peek`,
      // which toggles the inline peek panel. `DoNothingAndStopPropagationIntent`
      // stops the event bubbling to the app-level Shortcuts (which would
      // otherwise activate the row), while the dispatcher's separate
      // HardwareKeyboard handler still fires.
      shortcuts: _rowActivationShortcuts,
      builder: (context, states) => MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => onHoverChange(true),
        onExit: (_) => onHoverChange(false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          color: selected ? selectedColor : hoverColor.withAlpha(0),
          child: child,
        ),
      ),
    );
  }
}

/// The leading 16px checkbox, faded in on hover / in selection mode.
class _SelectCheckbox extends StatelessWidget {
  const _SelectCheckbox({
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
        child: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: selected ? accent : tokens.panel,
                borderRadius: AppRadii.brSm,
                border: Border.all(
                  color: selected ? accent : tokens.lineStrong,
                ),
              ),
              child: selected
                  ? Icon(
                      LucideIcons.check,
                      size: 11,
                      color: tokens.accentOn,
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

/// The trailing action cluster: a lane-adaptive primary button and the peek
/// chevron. Ready PRs get an inline [PrListMergeButton]; everything else opens
/// the PR (with the label tuned to the lane).
class _RowActionCluster extends StatelessWidget {
  const _RowActionCluster({
    required this.pr,
    required this.repo,
    required this.lane,
    required this.peeked,
    required this.onOpen,
    required this.onTogglePeek,
    this.browseOnly = false,
  });

  final PullRequest pr;
  final Repo repo;
  final DecisionLane lane;
  final bool peeked;
  final VoidCallback onOpen;
  final VoidCallback onTogglePeek;
  final bool browseOnly;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);

    // Browse-only rows (profiles) never merge/review inline — a ghost "Open"
    // is the single action regardless of lane (and works for merged/closed PRs
    // that have no live lane).
    final Widget action = browseOnly
        ? CcButton(
            onPressed: onOpen,
            variant: CcButtonVariant.ghost,
            size: CcButtonSize.sm,
            child: Text(l10n.openAction),
          )
        : switch (lane) {
            DecisionLane.ready => PrListMergeButton(pr: pr, repo: repo),
            DecisionLane.review => CcButton(
              onPressed: onOpen,
              variant: CcButtonVariant.secondary,
              size: CcButtonSize.sm,
              child: Text(l10n.review),
            ),
            DecisionLane.attention ||
            DecisionLane.inProgress ||
            DecisionLane.draft => CcButton(
              onPressed: onOpen,
              variant: CcButtonVariant.ghost,
              size: CcButtonSize.sm,
              child: Text(l10n.openAction),
            ),
          };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        action,
        const SizedBox(width: AppSpacing.xs),
        Semantics(
          button: true,
          expanded: peeked,
          label: l10n.summary,
          child: CcTappable(
            onPressed: onTogglePeek,
            builder: (context, states) => Padding(
              padding: const EdgeInsets.all(6),
              child: AnimatedRotation(
                turns: peeked ? 0.5 : 0,
                duration: const Duration(milliseconds: 150),
                child: Icon(
                  LucideIcons.chevronDown,
                  size: 16,
                  color: tokens.muted,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
