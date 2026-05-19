import 'package:cc_domain/features/pr_review/domain/entities/check_run.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_review_submission.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_reviewer.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/notifiers/pr_checks_ui_notifier.dart';
import 'package:control_center/features/pr_review/presentation/notifiers/pr_edit_notifier.dart';
import 'package:control_center/features/pr_review/presentation/utils/diff_file_tree.dart';
import 'package:control_center/features/pr_review/presentation/utils/review_status_palette.dart';
import 'package:control_center/features/pr_review/presentation/widgets/assignee_picker_flyout.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_complexity_badge.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_status_badge.dart';
import 'package:control_center/features/pr_review/presentation/widgets/reviewer_picker_flyout.dart';
import 'package:control_center/features/pr_review/presentation/widgets/ship_show_ask_badge.dart';
import 'package:control_center/features/pr_review/providers/pr_filter_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/pr_review/providers/ship_show_ask_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/collapsible_sidebar_section.dart';
import 'package:control_center/shared/widgets/github_team_avatar.dart';
import 'package:control_center/shared/widgets/github_user_avatar.dart';
import 'package:control_center/shared/widgets/github_user_hover_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tab index of the Actions tab inside the PR detail body. Kept here so the
/// sidebar can request a switch via the [prChecksUiProvider] without taking
/// a direct dependency on the tab strip.
const int kPrActionsTabIndex = 2;

/// Pr sidebar.
class PrSidebar extends ConsumerWidget {
  /// Creates a [PrSidebar].
  const PrSidebar({
    super.key,
    required this.pr,
    this.checks = const [],
    this.canEdit = false,
    this.optimisticMyState,
    this.onOpenFileInDiff,
  });

  /// The pull request displayed in this sidebar.
  final PullRequest pr;

  /// Checks associated with this PR.
  final List<CheckRun> checks;

  /// Whether the current user may edit reviewers/assignees (shows the `+`
  /// affordances and inline remove buttons).
  final bool canEdit;

  /// Optimistic review state for the current user, if a review was just submitted.
  final PrReviewSubmissionState? optimisticMyState;

  /// Called when a changed-file row is tapped, with its index into the
  /// tree-sorted file list — the Overview tab uses it to switch to the Diff tab
  /// and jump to that file. Null disables the file-tap affordance.
  final ValueChanged<int>? onOpenFileInDiff;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final reviewers =
        ref.watch(prReviewersProvider(pr.number)).value ?? const <PrReviewer>[];
    final login = ref.read(currentUserLoginProvider);
    final displayReviewers = _sortByReviewState(
      _applyOptimistic(reviewers, login),
    );

    // Pending optimistic sets (only watched when editable).
    final editState = canEdit ? ref.watch(prEditProvider(pr.number)) : null;

    final workflows = groupChecksByWorkflow(checks);
    final failingWorkflowCount = workflows
        .where((w) => w.status == WorkflowStatus.failure)
        .length;

    final files =
        ref.watch(prFilesProvider(pr.number)).value ?? const <PrFile>[];
    final sortedFiles = sortFilesByTreeOrder(files);
    final hasComplexity = files.isNotEmpty;
    final hasShipShowAsk =
        ref.watch(shipShowAskProvider(pr.number)).value != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        CollapsibleSidebarSection(
          icon: AppIcons.gitPullRequest,
          label: l10n.status,
          child: _sectionBody(
            // One tag per fact, in a single row that wraps only when the
            // sidebar is too narrow to hold them.
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                PrStatusBadge(pr: pr),
                if (hasShipShowAsk) ShipShowAskBadge(prNumber: pr.number),
                if (hasComplexity) PrComplexityBadge.fromFiles(files),
              ],
            ),
          ),
        ),
        _ChecksRailRow(
          workflows: workflows,
          failingWorkflowCount: failingWorkflowCount,
          onOpenActions: workflows.isEmpty
              ? null
              : () => _openChecks(ref, workflows),
        ),
        CollapsibleSidebarSection(
          icon: AppIcons.users,
          label: l10n.reviewers,
          count: displayReviewers.isEmpty ? null : '${displayReviewers.length}',
          trailing: ReviewerPickerHeader(
            prNumber: pr.number,
            current: displayReviewers,
            enabled: canEdit,
            compact: true,
          ),
          child: _sectionBody(
            child: displayReviewers.isEmpty
                ? _SidebarEmpty(label: l10n.noReviewersAssigned)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final r in displayReviewers)
                        _ReviewerRow(
                          reviewer: r,
                          pending:
                              editState?.pendingReviewers.contains(
                                r.identity,
                              ) ??
                              false,
                          onRemove: (canEdit && !r.isCodeOwner)
                              ? () => _removeReviewer(ref, r)
                              : null,
                        ),
                    ],
                  ),
          ),
        ),
        CollapsibleSidebarSection(
          icon: AppIcons.userCheck,
          label: l10n.assignees,
          count: pr.assignees.isEmpty ? null : '${pr.assignees.length}',
          trailing: AssigneePickerHeader(
            prNumber: pr.number,
            current: pr.assignees,
            enabled: canEdit,
            compact: true,
          ),
          child: _sectionBody(
            child: pr.assignees.isEmpty
                ? _SidebarEmpty(label: l10n.noAssignees)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final u in pr.assignees)
                        _AssigneeRow(
                          user: u,
                          pending:
                              editState?.pendingAssignees.contains(
                                u.login.toLowerCase(),
                              ) ??
                              false,
                          onRemove: canEdit
                              ? () => ref
                                    .read(prEditProvider(pr.number).notifier)
                                    .removeAssignee(u.login)
                              : null,
                        ),
                    ],
                  ),
          ),
        ),
        CollapsibleSidebarSection(
          icon: AppIcons.fileText,
          label: l10n.filesChanged,
          count: sortedFiles.isEmpty ? null : '${sortedFiles.length}',
          child: _sectionBody(
            child: sortedFiles.isEmpty
                ? _SidebarEmpty(label: l10n.noFilesChanged)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < sortedFiles.length; i++)
                        _FileSummaryRow(
                          file: sortedFiles[i],
                          onTap: onOpenFileInDiff == null
                              ? null
                              : () => onOpenFileInDiff!(i),
                        ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  /// Consistent inset for a section's body so rows align under the eyebrow.
  Widget _sectionBody({required Widget child}) =>
      Padding(padding: const EdgeInsets.fromLTRB(12, 4, 12, 12), child: child);

  void _openChecks(WidgetRef ref, List<WorkflowGroup> workflows) {
    final notifier = ref.read(prChecksUiProvider.notifier);
    WorkflowGroup? firstFailing;
    for (final w in workflows) {
      if (w.status == WorkflowStatus.failure) {
        firstFailing = w;
        break;
      }
    }
    if (firstFailing != null) {
      notifier.openWorkflow(
        firstFailing.key,
        actionsTabIndex: kPrActionsTabIndex,
      );
    } else {
      notifier.requestTab(kPrActionsTabIndex);
    }
  }

  void _removeReviewer(WidgetRef ref, PrReviewer r) {
    final notifier = ref.read(prEditProvider(pr.number).notifier);
    switch (r) {
      case PrUserReviewer():
        notifier.removeReviewer(userLogin: r.user.login);
      case PrTeamReviewer():
        notifier.removeReviewer(teamSlug: r.slug);
    }
  }

  /// Overlays the viewer's just-submitted (optimistic) review state onto the
  /// resolved reviewer list so the rail reflects the action before the server
  /// round-trip lands.
  List<PrReviewer> _applyOptimistic(List<PrReviewer> reviewers, String login) {
    if (optimisticMyState == null || login.isEmpty) {
      return reviewers;
    }
    final idx = reviewers.indexWhere(
      (r) =>
          r is PrUserReviewer &&
          r.user.login.toLowerCase() == login.toLowerCase(),
    );
    final updated = [...reviewers];
    if (idx >= 0) {
      final existing = updated[idx] as PrUserReviewer;
      updated[idx] = PrUserReviewer(
        user: existing.user,
        isCodeOwner: existing.isCodeOwner,
        state: optimisticMyState!,
      );
    } else {
      updated.add(
        PrUserReviewer(
          user: PrUser(login: login, avatarUrl: ''),
          isCodeOwner: false,
          state: optimisticMyState!,
        ),
      );
    }
    return updated;
  }

  /// Orders reviewers so approvals surface first, then change requests, then
  /// everyone else (commented/pending). Order within each group is preserved.
  List<PrReviewer> _sortByReviewState(List<PrReviewer> reviewers) {
    int rank(PrReviewSubmissionState state) => switch (state) {
      PrReviewSubmissionState.approved => 0,
      PrReviewSubmissionState.changesRequested => 1,
      _ => 2,
    };
    final indexed = [
      for (var i = 0; i < reviewers.length; i++) (i, reviewers[i]),
    ];
    indexed.sort((a, b) {
      final byRank = rank(a.$2.state).compareTo(rank(b.$2.state));
      return byRank != 0 ? byRank : a.$1.compareTo(b.$1);
    });
    return [for (final entry in indexed) entry.$2];
  }
}

/// A muted one-line placeholder for an empty sidebar section.
class _SidebarEmpty extends StatelessWidget {
  const _SidebarEmpty({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return Text(
      label,
      style: CcTypography.caption.copyWith(color: tokens.textTertiary),
    );
  }
}

/// A compact changed-file row for the Overview sidebar: the file's basename
/// over its (muted) directory, with per-file `+`/`−` counts. Tapping it hands
/// the file's index back so the Overview tab can open it in the Diff tab.
class _FileSummaryRow extends StatelessWidget {
  const _FileSummaryRow({required this.file, this.onTap});

  final PrFile file;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final slash = file.filename.lastIndexOf('/');
    final name = slash < 0 ? file.filename : file.filename.substring(slash + 1);
    final dir = slash < 0 ? '' : file.filename.substring(0, slash);

    return CcTappable(
      onPressed: onTap,
      borderRadius: AppRadii.brSm,
      semanticLabel: file.filename,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
          decoration: BoxDecoration(
            color: hovered ? t.hover : t.hover.withValues(alpha: 0),
            borderRadius: AppRadii.brSm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CcTypography.caption.copyWith(
                        color: t.textPrimary,
                      ),
                    ),
                    if (dir.isNotEmpty)
                      Text(
                        dir,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CcTypography.caption.copyWith(
                          color: t.textTertiary,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (file.additions > 0)
                Text(
                  '+${file.additions}',
                  style: CcTypography.caption.copyWith(
                    color: ReviewStatusColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (file.additions > 0 && file.deletions > 0)
                const SizedBox(width: 4),
              if (file.deletions > 0)
                Text(
                  '−${file.deletions}',
                  style: CcTypography.caption.copyWith(
                    color: ReviewStatusColors.failure,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// A reviewer rail row. Renders three shapes from one [PrReviewer]: an
/// individual user, a pending team, or a team merged with the member who
/// reviewed on its behalf. Code owners carry a shield and no remove affordance.
class _ReviewerRow extends StatefulWidget {
  const _ReviewerRow({
    required this.reviewer,
    required this.pending,
    this.onRemove,
  });

  final PrReviewer reviewer;
  final bool pending;
  final VoidCallback? onRemove;

  @override
  State<_ReviewerRow> createState() => _ReviewerRowState();
}

class _ReviewerRowState extends State<_ReviewerRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.reviewer;
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final reviewedBy = r is PrTeamReviewer ? r.reviewedBy : null;

    final Widget content = MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            if (r.isCodeOwner) ...[
              CcTooltip(
                message: l10n.requiredByCodeOwners,
                child: Icon(AppIcons.shield, size: 14, color: t.fgBrandPrimary),
              ),
              const SizedBox(width: 6),
            ],
            _ReviewerAvatar(reviewer: r),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _label(r),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CcTypography.caption.copyWith(color: t.textPrimary),
                  ),
                  if (reviewedBy != null)
                    Text(
                      l10n.reviewedOnBehalfOf(reviewedBy.login),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CcTypography.caption.copyWith(
                        color: t.textTertiary,
                      ),
                    ),
                ],
              ),
            ),
            if (widget.pending)
              const CcSpinner(size: 14)
            else if (_hovered && widget.onRemove != null)
              CcTappable(
                onPressed: widget.onRemove,
                builder: (context, states) =>
                    Icon(AppIcons.x, size: 14, color: t.fgQuaternary),
              )
            else
              _ReviewerStateDot(state: r.state),
          ],
        ),
      ),
    );

    if (r is PrUserReviewer) {
      return GitHubUserHoverTarget(login: r.user.login, child: content);
    }
    return content;
  }

  String _label(PrReviewer r) => switch (r) {
    PrUserReviewer() => r.user.login,
    PrTeamReviewer() => r.name,
  };
}

/// Avatar for a reviewer row: a user avatar, a team logo, or — for a merged
/// team — the team logo with the member's avatar badged on it.
class _ReviewerAvatar extends StatelessWidget {
  const _ReviewerAvatar({required this.reviewer});

  final PrReviewer reviewer;

  @override
  Widget build(BuildContext context) {
    final r = reviewer;
    if (r is PrUserReviewer) {
      return GitHubUserAvatar(
        login: r.user.login,
        avatarUrl: r.user.avatarUrl,
        size: 24,
      );
    }
    final team = r as PrTeamReviewer;
    final teamGlyph = GitHubTeamAvatar(
      name: team.name,
      avatarUrl: team.avatarUrl,
      size: 24,
    );
    if (team.reviewedBy == null) {
      return teamGlyph;
    }
    return SizedBox(
      width: 28,
      height: 28,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          teamGlyph,
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      context.designSystem?.bgPrimary ??
                      DesignSystemTokens.light().bgPrimary,
                  width: 1.5,
                ),
              ),
              child: GitHubUserAvatar(
                login: team.reviewedBy!.login,
                avatarUrl: team.reviewedBy!.avatarUrl,
                size: 16,
                showHoverCard: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// An assignee rail row: avatar + login, with a hover-revealed remove when
/// editable. Assignees are never code-owners and are always freely removable.
class _AssigneeRow extends StatefulWidget {
  const _AssigneeRow({
    required this.user,
    required this.pending,
    this.onRemove,
  });

  final PrUser user;
  final bool pending;
  final VoidCallback? onRemove;

  @override
  State<_AssigneeRow> createState() => _AssigneeRowState();
}

class _AssigneeRowState extends State<_AssigneeRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return GitHubUserHoverTarget(
      login: widget.user.login,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Opacity(
          opacity: widget.pending ? 0.5 : 1,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                GitHubUserAvatar(
                  login: widget.user.login,
                  avatarUrl: widget.user.avatarUrl,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.user.login,
                    style: CcTypography.caption.copyWith(color: t.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.pending)
                  const CcSpinner(size: 14)
                else if (_hovered && widget.onRemove != null)
                  CcTappable(
                    onPressed: widget.onRemove,
                    builder: (context, states) =>
                        Icon(AppIcons.x, size: 14, color: t.fgQuaternary),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Single-row checks summary in the Overview rail.
///
/// Checks don't expand in place: the Actions tab is the detail surface, so
/// this is a section-header-shaped link (eyebrow + rolled-up verdict) rather
/// than a [CollapsibleSidebarSection]. The shield sits in the expand-caret
/// column of the sections above/below so the row's leading edge lines up.
class _ChecksRailRow extends StatelessWidget {
  const _ChecksRailRow({
    required this.workflows,
    required this.failingWorkflowCount,
    this.onOpenActions,
  });

  final List<WorkflowGroup> workflows;
  final int failingWorkflowCount;
  final VoidCallback? onOpenActions;

  WorkflowStatus get _rollup {
    var hasRunning = false;
    var hasFailure = false;
    var hasSuccess = false;
    for (final w in workflows) {
      switch (w.status) {
        case WorkflowStatus.running:
          hasRunning = true;
        case WorkflowStatus.failure:
          hasFailure = true;
        case WorkflowStatus.success:
          hasSuccess = true;
        case WorkflowStatus.neutral:
          break;
      }
    }
    if (hasFailure) {
      return WorkflowStatus.failure;
    }
    if (hasRunning) {
      return WorkflowStatus.running;
    }
    if (hasSuccess) {
      return WorkflowStatus.success;
    }
    return WorkflowStatus.neutral;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final empty = workflows.isEmpty;
    final status = empty ? null : _rollup;
    final verdict = switch (status) {
      null => l10n.noChecksYet,
      WorkflowStatus.failure => l10n.checksFailingCount(failingWorkflowCount),
      WorkflowStatus.running => l10n.running,
      WorkflowStatus.success => l10n.passed,
      WorkflowStatus.neutral => l10n.neutral,
    };
    final style = status == null ? null : workflowStatusStyle(status, context);

    final row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      child: Row(
        children: [
          Icon(AppIcons.shieldCheck, size: 14, color: t.textTertiary),
          const SizedBox(width: AppSpacing.xs),
          Text(
            l10n.checks.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: t.textTertiary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (status != null) ...[
                  WorkflowStatusIcon(status: status, size: 14),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Flexible(
                  child: Text(
                    verdict,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: CcTypography.caption.copyWith(
                      color: style?.color ?? t.textTertiary,
                      fontWeight: status == null
                          ? FontWeight.w400
                          : FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (onOpenActions != null) ...[
            const SizedBox(width: AppSpacing.xs),
            Icon(AppIcons.chevronRight, size: 14, color: t.textTertiary),
          ],
        ],
      ),
    );

    if (onOpenActions == null) {
      return Semantics(
        container: true,
        label: '${l10n.checks}, $verdict',
        child: ExcludeSemantics(child: row),
      );
    }

    return CcTappable(
      onPressed: onOpenActions,
      semanticLabel: '${l10n.checks}, $verdict',
      borderRadius: AppRadii.brSm,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        return DecoratedBox(
          decoration: BoxDecoration(
            color: hovered ? t.hover : t.hover.withValues(alpha: 0),
            borderRadius: AppRadii.brSm,
          ),
          child: ExcludeSemantics(child: row),
        );
      },
    );
  }
}

/// Reusable status glyph used by both the sidebar and the Actions tab.
class WorkflowStatusIcon extends StatelessWidget {
  /// Creates a [WorkflowStatusIcon].
  const WorkflowStatusIcon({super.key, required this.status, this.size = 16});

  /// Aggregated workflow status to render.
  final WorkflowStatus status;

  /// Icon size in logical pixels.
  final double size;

  @override
  Widget build(BuildContext context) {
    final style = workflowStatusStyle(status, context);
    if (status == WorkflowStatus.running) {
      return CcSpinner(size: size, color: style.color);
    }
    return Icon(style.icon, size: size, color: style.color);
  }
}

/// Visual style descriptor for a [WorkflowStatus].
({IconData icon, Color color, String label}) workflowStatusStyle(
  WorkflowStatus status,
  BuildContext context,
) {
  switch (status) {
    case WorkflowStatus.running:
      return (
        icon: AppIcons.loader,
        color: ReviewStatusColors.running,
        label: AppLocalizations.of(context).running,
      );
    case WorkflowStatus.success:
      return (
        icon: AppIcons.checkCircle2,
        color: ReviewStatusColors.success,
        label: AppLocalizations.of(context).passed,
      );
    case WorkflowStatus.failure:
      return (
        icon: AppIcons.xCircle,
        color: ReviewStatusColors.failure,
        label: AppLocalizations.of(context).failed,
      );
    case WorkflowStatus.neutral:
      return (
        icon: AppIcons.minusCircle,
        color: ReviewStatusColors.neutral,
        label: AppLocalizations.of(context).neutral,
      );
  }
}

class _ReviewerStateDot extends StatelessWidget {
  const _ReviewerStateDot({required this.state});

  final PrReviewSubmissionState state;

  @override
  Widget build(BuildContext context) {
    final (color, icon, tooltip) = _styleFor(state, context);
    return CcTooltip(
      message: tooltip,
      child: Icon(icon, size: 14, color: color),
    );
  }

  (Color, IconData, String) _styleFor(
    PrReviewSubmissionState state,
    BuildContext context,
  ) {
    switch (state) {
      case PrReviewSubmissionState.approved:
        return (
          ReviewStatusColors.success,
          AppIcons.checkCircle2,
          AppLocalizations.of(context).approved,
        );
      case PrReviewSubmissionState.changesRequested:
        return (
          ReviewStatusColors.failure,
          AppIcons.xCircle,
          AppLocalizations.of(context).changesRequested,
        );
      case PrReviewSubmissionState.commented:
        return (
          context.designSystem?.textTertiary ??
              DesignSystemTokens.light().textTertiary,
          AppIcons.messageCircle,
          AppLocalizations.of(context).commented,
        );
      case PrReviewSubmissionState.pending:
        return (
          context.designSystem?.textTertiary ??
              DesignSystemTokens.light().textTertiary,
          AppIcons.clock,
          AppLocalizations.of(context).awaitingYourReview,
        );
    }
  }
}
