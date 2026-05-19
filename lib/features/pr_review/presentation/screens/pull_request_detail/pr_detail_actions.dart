import 'dart:async';

import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pipelines/providers/pipeline_providers.dart';
import 'package:control_center/features/pr_review/presentation/widgets/merge_flyout_button.dart';
import 'package:control_center/features/pr_review/presentation/widgets/open_in_ide_button.dart'
    if (dart.library.js_interop) 'package:control_center/features/pr_review/presentation/widgets/open_in_ide_button_web.dart';
import 'package:control_center/features/pr_review/presentation/widgets/review_overlay.dart';
import 'package:control_center/features/pr_review/providers/pr_detail_polling_provider.dart';
import 'package:control_center/features/pr_review/providers/pr_filter_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/providers/last_checked_provider.dart';
import 'package:control_center/shared/utils/open_url.dart';
import 'package:control_center/shared/widgets/refresh_control.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The PR-level action cluster — freshness label, Review / Merge / Open-in-IDE,
/// and the overflow menu (Ask AI / refresh / open on GitHub / close). It used to
/// live in the page's breadcrumb row; it now sits at the top of the Overview
/// tab.
class PrDetailActions extends ConsumerWidget {
  /// Creates a [PrDetailActions].
  const PrDetailActions({super.key, required this.pr, required this.prNumber});

  /// The pull request.
  final PullRequest pr;

  /// The PR number (data lookups).
  final int prNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(currentPrRepoProvider);
    final owner = repo?.githubOwner ?? '';
    final repoName = repo?.githubRepoName ?? '';
    final workspaceId = ref.watch(activeWorkspaceIdProvider);

    final currentLogin = ref.watch(currentUserLoginProvider);
    final isAuthor =
        currentLogin.isNotEmpty &&
        pr.author?.login.toLowerCase() == currentLogin;

    final permissionAsync = ref.watch(
      repoPermissionProvider((owner: owner, repo: repoName)),
    );
    final hasWriteAccess =
        permissionAsync.whenOrNull(
          data: (perm) => perm == 'admin' || perm == 'write',
        ) ??
        false;

    final checksAsync = ref.watch(prCheckRunsProvider(prNumber));
    final reviewsAsync = ref.watch(prReviewsProvider(prNumber));
    final checks = checksAsync.value ?? [];
    final reviews = reviewsAsync.value ?? [];

    final canClose = isAuthor || hasWriteAccess;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Refresh + freshness indicator: re-fetches all PR data (detail,
        // comments, reviews, checks, diff) and spins while the fetch is in
        // flight; its hover card reports "Checked {time}".
        _PrRefreshButton(prNumber: prNumber),
        const SizedBox(width: 8),
        // Primary action(s): Review for non-authors, Merge when mergeable.
        // Secondary actions (Ask AI review, Close PR) live in the overflow
        // menu to keep this row scannable. Review/Merge only make sense while
        // the PR is open — a merged/closed PR shows neither.
        if (pr.isOpen && !isAuthor) ...[
          ReviewOverlayButton(pr: pr, owner: owner, repo: repoName),
          const SizedBox(width: 8),
        ],
        if (hasWriteAccess && pr.canMerge) ...[
          MergeFlyoutButton(
            pr: pr,
            owner: owner,
            repo: repoName,
            checks: checks,
            reviews: reviews,
          ),
          const SizedBox(width: 8),
        ],
        // Open the PR's branch in an editor/IDE — its branch is lazily checked
        // out into a CoW worktree on click. Needs the repo checked out locally
        // (the CoW source) and an active workspace to own the worktree.
        if (repo != null &&
            repo.path.trim().isNotEmpty &&
            workspaceId != null) ...[
          OpenInIdeButton(pr: pr, repo: repo, workspaceId: workspaceId),
          const SizedBox(width: 8),
        ],
        _PrMoreActionsMenu(pr: pr, canClose: canClose),
      ],
    );
  }
}

/// The toolbar refresh control for a PR detail view: re-fetches all PR data via
/// [PrDetailPollingNotifier.refreshAll] and spins the icon until every fetch
/// settles (the detail streams are live, so a forced re-fetch never re-enters a
/// loading state on its own). The in-flight state lives in the notifier, so a
/// refresh triggered by the `pr.detail-refresh` shortcut spins this icon too.
/// Its hover card reports data freshness.
class _PrRefreshButton extends ConsumerWidget {
  const _PrRefreshButton({required this.prNumber});

  final int prNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastChecked = ref.watch(
      lastCheckedProvider.select((m) => m['pr-detail:$prNumber']),
    );
    final refreshing = ref.watch(
      prDetailPollingProvider(prNumber).select((s) => s.refreshing),
    );
    return RefreshControl(
      lastChecked: lastChecked,
      isLoading: refreshing,
      // refreshAll never throws and guards its own re-entrancy.
      onRefresh: () => unawaited(
        ref.read(prDetailPollingProvider(prNumber).notifier).refreshAll(),
      ),
    );
  }
}

class _PrMoreActionsMenu extends ConsumerStatefulWidget {
  const _PrMoreActionsMenu({required this.pr, required this.canClose});

  final PullRequest pr;
  final bool canClose;

  @override
  ConsumerState<_PrMoreActionsMenu> createState() => _PrMoreActionsMenuState();
}

class _PrMoreActionsMenuState extends ConsumerState<_PrMoreActionsMenu> {
  final CcOverlayController _controller = CcOverlayController();
  bool _aiLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startAiReview() async {
    if (_aiLoading) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final toaster = CcToastScope.of(context);
    final ws = context.currentWorkspaceId!;
    final workspace = ref.read(activeWorkspaceProvider);
    final repo = ref.read(currentPrRepoProvider);

    _controller.hide();
    if (!mounted) {
      return;
    }

    if (workspace == null || repo == null) {
      toaster.show(l10n.noActiveWorkspace, variant: CcToastVariant.danger);
      return;
    }

    setState(() => _aiLoading = true);
    try {
      final engine = ref.read(pipelineEngineProvider);
      final run = await engine.start(
        'pr_review',
        workspaceId: workspace.id,
        triggerEventType: 'manual',
        triggerPayload: {
          'workspaceId': workspace.id,
          'repoOwner': repo.githubOwner,
          'repoName': repo.githubRepoName,
          'repoFullName': repo.fullName,
          'prNumber': widget.pr.number,
          'prNodeId': widget.pr.nodeId,
          'prTitle': widget.pr.title,
          'author': widget.pr.author?.login ?? '',
        },
      );
      if (!mounted) {
        return;
      }
      if (run == null) {
        toaster.show(
          l10n.failedToStartAiReview('duplicate run'),
          variant: CcToastVariant.danger,
        );
        return;
      }
      context.go(pipelineRunRoute(ws, run.id));
    } on Exception catch (e) {
      if (!mounted) {
        return;
      }
      toaster.show(
        l10n.failedToStartAiReview('$e'),
        variant: CcToastVariant.danger,
      );
    } finally {
      if (mounted) {
        setState(() => _aiLoading = false);
      }
    }
  }

  Future<void> _closePr() async {
    final l10n = AppLocalizations.of(context);
    final toaster = CcToastScope.of(context);
    _controller.hide();
    if (!mounted) {
      return;
    }

    final confirmed = await showCcDialog<bool>(
      context: context,
      builder: (ctx) => CcDialog(
        title: l10n.closePullRequest,
        content: Text(l10n.closePullRequestConfirm),
        actions: [
          CcButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            variant: CcButtonVariant.secondary,
            child: Text(l10n.cancel),
          ),
          CcButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            variant: CcButtonVariant.destructive,
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      await ref
          .read(prReviewRepositoryProvider)
          .closePullRequest(prNumber: widget.pr.number);
      toaster.show(l10n.pullRequestClosed, variant: CcToastVariant.success);
    } on Exception catch (e) {
      if (!mounted) {
        return;
      }
      toaster.show(l10n.failedToClosePr('$e'), variant: CcToastVariant.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final showClose = widget.canClose && widget.pr.isOpen;
    final destructive =
        context.designSystem?.textErrorPrimary ??
        DesignSystemTokens.light().textErrorPrimary;

    return CcPopover(
      controller: _controller,
      toggleOnTargetTap: false,
      followerAnchor: Alignment.topRight,
      targetAnchor: Alignment.bottomRight,
      overlayBuilder: (context, _) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 220),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Ask AI review is a pre-merge action — hide it once the PR is
              // merged or closed.
              if (widget.pr.isOpen)
                CcTile(
                  leading: _aiLoading
                      ? const CcSpinner(size: 16)
                      : const Icon(AppIcons.sparkles, size: 16),
                  title: Text(l10n.askAi),
                  onTap: _aiLoading ? null : _startAiReview,
                ),
              CcTile(
                leading: const Icon(AppIcons.externalLink, size: 16),
                title: Text(l10n.openOnGithub),
                onTap: () {
                  _controller.hide();
                  openExternalUrl(widget.pr.htmlUrl);
                },
              ),
              if (showClose) ...[
                const CcDivider(),
                CcTile(
                  leading: Icon(AppIcons.x, size: 16, color: destructive),
                  title: Text(l10n.close, style: TextStyle(color: destructive)),
                  onTap: _closePr,
                ),
              ],
            ],
          ),
        ),
      ),
      target: CcIconButton(
        onPressed: _controller.toggle,
        icon: AppIcons.moreHorizontal,
        tooltip: l10n.prMoreActions,
      ),
    );
  }
}
