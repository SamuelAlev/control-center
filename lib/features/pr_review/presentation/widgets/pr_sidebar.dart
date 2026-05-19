import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/pr_review/domain/entities/check_run.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_review_submission.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_reviewer.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_user.dart';
import 'package:control_center/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/features/pr_review/presentation/notifiers/pr_checks_ui_notifier.dart';
import 'package:control_center/features/pr_review/presentation/notifiers/pr_edit_notifier.dart';
import 'package:control_center/features/pr_review/presentation/utils/review_status_palette.dart';
import 'package:control_center/features/pr_review/presentation/widgets/assignee_picker_flyout.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_complexity_badge.dart';
import 'package:control_center/features/pr_review/presentation/widgets/reviewer_picker_flyout.dart';
import 'package:control_center/features/pr_review/presentation/widgets/ship_show_ask_badge.dart';
import 'package:control_center/features/pr_review/providers/pr_filter_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/pr_review/providers/ship_show_ask_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/github_user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Tab index of the Actions tab inside the PR detail body. Kept here so the
/// sidebar can request a switch via the [prChecksUiProvider] without taking
/// a direct dependency on the tab strip.
const int kPrActionsTabIndex = 2;

/// Pr sidebar.
class PrSidebar extends ConsumerWidget {
  const PrSidebar({
    super.key,
    required this.pr,
    this.checks = const [],
    this.canEdit = false,
    this.optimisticMyState,
  });

  final PullRequest pr;
  final List<CheckRun> checks;

  /// Whether the current user may edit reviewers/assignees (shows the `+`
  /// affordances and inline remove buttons).
  final bool canEdit;

  final PrReviewSubmissionState? optimisticMyState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final reviewers = ref.watch(prReviewersProvider(pr.number)).value ??
        const <PrReviewer>[];
    final login = ref.read(currentUserLoginProvider);
    final displayReviewers =
        _sortByReviewState(_applyOptimistic(reviewers, login));

    // Pending optimistic sets (only watched when editable).
    final editState = canEdit ? ref.watch(prEditProvider(pr.number)) : null;

    final workflows = groupChecksByWorkflow(checks);
    final failingWorkflowCount = workflows
        .where((w) => w.status == WorkflowStatus.failure)
        .length;

    final filesAsync = ref.watch(prFilesProvider(pr.number));
    final files = filesAsync.value;
    final hasComplexity = files != null && files.isNotEmpty;
    final hasShipShowAsk =
        ref.watch(shipShowAskProvider(pr.number)).value != null;
    final showOverview = hasComplexity || hasShipShowAsk;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showOverview) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (hasShipShowAsk) ShipShowAskBadge(prNumber: pr.number),
              if (hasComplexity) PrComplexityBadge.fromFiles(files),
            ],
          ),
          const SizedBox(height: 24),
        ],
        ReviewerPickerHeader(
          prNumber: pr.number,
          current: displayReviewers,
          enabled: canEdit,
        ),
        const SizedBox(height: 12),
        if (displayReviewers.isEmpty)
          _SidebarEmpty(label: l10n.noReviewersAssigned)
        else
          ...displayReviewers.map(
            (r) => _ReviewerRow(
              reviewer: r,
              pending: editState?.pendingReviewers.contains(r.identity) ?? false,
              onRemove: (canEdit && !r.isCodeOwner)
                  ? () => _removeReviewer(ref, r)
                  : null,
            ),
          ),
        const SizedBox(height: 24),
        AssigneePickerHeader(
          prNumber: pr.number,
          current: pr.assignees,
          enabled: canEdit,
        ),
        const SizedBox(height: 12),
        if (pr.assignees.isEmpty)
          _SidebarEmpty(label: l10n.noAssignees)
        else
          ...pr.assignees.map(
            (u) => _AssigneeRow(
              user: u,
              pending:
                  editState?.pendingAssignees.contains(u.login.toLowerCase()) ??
                      false,
              onRemove: canEdit
                  ? () => ref
                      .read(prEditProvider(pr.number).notifier)
                      .removeAssignee(u.login)
                  : null,
            ),
          ),
        const SizedBox(height: 24),
        _SidebarHeader(icon: LucideIcons.shieldCheck, label: l10n.checks),
        const SizedBox(height: 12),
        if (workflows.isEmpty)
          _SidebarEmpty(label: l10n.noChecksYet)
        else
          _ChecksSummaryRow(
            workflows: workflows,
            failingWorkflowCount: failingWorkflowCount,
            onTap: () {
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
                  firstFailing.name,
                  actionsTabIndex: kPrActionsTabIndex,
                );
              } else {
                notifier.requestTab(kPrActionsTabIndex);
              }
            },
          ),
      ],
    );
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
  List<PrReviewer> _applyOptimistic(
    List<PrReviewer> reviewers,
    String login,
  ) {
    if (optimisticMyState == null || login.isEmpty) {
      return reviewers;
    }
    final idx = reviewers.indexWhere(
      (r) =>
          r is PrUserReviewer && r.user.login.toLowerCase() == login.toLowerCase(),
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

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: context.theme.colors.mutedForeground),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: context.theme.colors.mutedForeground,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// A muted one-line placeholder for an empty sidebar section.
class _SidebarEmpty extends StatelessWidget {
  const _SidebarEmpty({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: context.theme.colors.mutedForeground,
      ),
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
    final colors = context.theme.colors;
    final reviewedBy = r is PrTeamReviewer ? r.reviewedBy : null;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            if (r.isCodeOwner) ...[
              FTooltip(
                tipBuilder: (_, _) => Text(l10n.requiredByCodeOwners),
                child: Icon(
                  LucideIcons.shield,
                  size: 14,
                  color: t.fgBrandPrimary,
                ),
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
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.foreground,
                    ),
                  ),
                  if (reviewedBy != null)
                    Text(
                      l10n.reviewedOnBehalfOf(reviewedBy.login),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.mutedForeground,
                      ),
                    ),
                ],
              ),
            ),
            if (widget.pending)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (_hovered && widget.onRemove != null)
              FTappable(
                onPress: widget.onRemove,
                child: Icon(
                  LucideIcons.x,
                  size: 14,
                  color: t.fgQuaternary,
                ),
              )
            else
              _ReviewerStateDot(state: r.state),
          ],
        ),
      ),
    );
  }

  String _label(PrReviewer r) => switch (r) {
        PrUserReviewer() => r.user.login,
        PrTeamReviewer() => r.name,
      };
}

/// Avatar for a reviewer row: a user avatar, a team glyph, or — for a merged
/// team — the team glyph with the member's avatar badged on it.
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
    final teamGlyph = _TeamGlyph();
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
                  color: context.theme.colors.background,
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

class _TeamGlyph extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: t.bgSecondary,
        shape: BoxShape.circle,
        border: Border.all(color: t.borderSecondary),
      ),
      child: Icon(LucideIcons.users, size: 13, color: t.fgQuaternary),
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
    return MouseRegion(
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
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.theme.colors.foreground,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.pending)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (_hovered && widget.onRemove != null)
                FTappable(
                  onPress: widget.onRemove,
                  child: Icon(LucideIcons.x, size: 14, color: t.fgQuaternary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact rolled-up checks verdict shown in the rail.
class _ChecksSummaryRow extends StatelessWidget {
  const _ChecksSummaryRow({
    required this.workflows,
    required this.failingWorkflowCount,
    required this.onTap,
  });

  final List<WorkflowGroup> workflows;
  final int failingWorkflowCount;
  final VoidCallback onTap;

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
    final status = _rollup;
    final style = workflowStatusStyle(status, context);
    final verdict = switch (status) {
      WorkflowStatus.failure => l10n.checksFailingCount(failingWorkflowCount),
      WorkflowStatus.running => l10n.running,
      WorkflowStatus.success => l10n.passed,
      WorkflowStatus.neutral => l10n.neutral,
    };
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            WorkflowStatusIcon(status: status, size: 14),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                verdict,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: style.color,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              size: 14,
              color: context.theme.colors.mutedForeground,
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable status glyph used by both the sidebar and the Actions tab.
class WorkflowStatusIcon extends StatelessWidget {
  /// WorkflowStatusIcon({super.key,.
  const WorkflowStatusIcon({super.key, required this.status, this.size = 16});

  /// Aggregated workflow status to render.
  final WorkflowStatus status;

  /// Icon size in logical pixels.
  final double size;

  @override
  Widget build(BuildContext context) {
    final style = workflowStatusStyle(status, context);
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
        icon: LucideIcons.loader,
        color: ReviewStatusColors.running,
        label: AppLocalizations.of(context).running,
      );
    case WorkflowStatus.success:
      return (
        icon: LucideIcons.checkCircle2,
        color: ReviewStatusColors.success,
        label: AppLocalizations.of(context).passed,
      );
    case WorkflowStatus.failure:
      return (
        icon: LucideIcons.xCircle,
        color: ReviewStatusColors.failure,
        label: AppLocalizations.of(context).failed,
      );
    case WorkflowStatus.neutral:
      return (
        icon: LucideIcons.minusCircle,
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
    return FTooltip(
      tipBuilder: (_, _) => Text(tooltip),
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
          LucideIcons.checkCircle2,
          AppLocalizations.of(context).approved,
        );
      case PrReviewSubmissionState.changesRequested:
        return (
          ReviewStatusColors.failure,
          LucideIcons.xCircle,
          AppLocalizations.of(context).changesRequested,
        );
      case PrReviewSubmissionState.commented:
        return (
          context.theme.colors.mutedForeground,
          LucideIcons.messageCircle,
          AppLocalizations.of(context).commented,
        );
      case PrReviewSubmissionState.pending:
        return (
          context.theme.colors.mutedForeground,
          LucideIcons.clock,
          AppLocalizations.of(context).awaitingYourReview,
        );
    }
  }
}
