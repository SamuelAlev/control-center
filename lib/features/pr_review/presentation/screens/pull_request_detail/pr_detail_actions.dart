import 'dart:async';

import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/widgets/merge_flyout_button.dart';
import 'package:control_center/features/pr_review/presentation/widgets/open_in_ide_button.dart'
    if (dart.library.js_interop) 'package:control_center/features/pr_review/presentation/widgets/open_in_ide_button_web.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_draft_actions.dart';
import 'package:control_center/features/pr_review/presentation/widgets/review_overlay.dart';
import 'package:control_center/features/pr_review/providers/pr_detail_polling_provider.dart';
import 'package:control_center/features/pr_review/providers/pr_filter_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_review_run_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/providers/last_checked_provider.dart';
import 'package:control_center/shared/utils/open_url.dart';
import 'package:control_center/shared/widgets/refresh_control.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The PR-level action cluster — freshness label, Review / Merge / Open-in-IDE,
/// and the overflow menu (Ask AI / refresh / open on GitHub / close). It used to
/// live in the page's breadcrumb row; it now sits at the top of the Overview
/// tab.
class PrDetailActions extends ConsumerWidget {
  /// Creates a [PrDetailActions].
  const PrDetailActions({
    super.key,
    required this.pr,
    required this.prRef,
    required this.onOpenReview,
  });

  /// The pull request.
  final PullRequest pr;

  /// The PR's identity key (repo coords + number) for PR-keyed providers.
  final PrRef prRef;

  /// Focuses the PR review artifact tab, opening it if it was closed. Starting
  /// a review takes you to what it produces — the run's progress, then its
  /// artifact — rather than to the generic pipeline-run screen, which shows the
  /// same steps with none of the review around them.
  final VoidCallback onOpenReview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(prRepoRowProvider(prRef));
    final owner = repo?.remoteOwner ?? '';
    final repoName = repo?.remoteName ?? '';
    final workspaceId = ref.watch(activeWorkspaceIdProvider);

    final currentLogin = ref.watch(currentUserLoginForPrProvider(prRef));
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

    final checksAsync = ref.watch(prCheckRunsProvider(prRef));
    final reviewsAsync = ref.watch(prReviewsProvider(prRef));
    final checks = checksAsync.value ?? [];
    final reviews = reviewsAsync.value ?? [];

    final canClose = isAuthor || hasWriteAccess;
    final canToggleDraftState = canToggleDraft(ref, pr, prRef);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Refresh + freshness indicator: re-fetches all PR data (detail,
        // comments, reviews, checks, diff) and spins while the fetch is in
        // flight; its hover card reports "Checked {time}".
        _PrRefreshButton(prRef: prRef),
        const SizedBox(width: 8),
        // Primary action(s): Ready for review on a draft, Review for
        // non-authors, Merge when mergeable. Secondary actions (Ask AI review,
        // Convert to draft, Close PR) live in the overflow menu to keep this
        // row scannable. Review/Merge only make sense while the PR is open — a
        // merged/closed PR shows neither.
        //
        // A draft takes the Review slot rather than adding a button beside it:
        // on a draft the next step is publishing it, not reviewing it, and the
        // two together would put two primary actions in one cluster.
        if (pr.isDraft && canToggleDraftState) ...[
          MarkReadyForReviewButton(pr: pr, prRef: prRef),
          const SizedBox(width: 8),
        ] else if (pr.isOpen && !isAuthor) ...[
          ReviewOverlayButton(
            pr: pr,
            prRef: prRef,
            owner: owner,
            repo: repoName,
          ),
          const SizedBox(width: 8),
        ],
        if (hasWriteAccess && pr.canMerge) ...[
          MergeFlyoutButton(
            pr: pr,
            prRef: prRef,
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
        _PrMoreActionsMenu(
          pr: pr,
          prRef: prRef,
          canClose: canClose,
          canToggleDraft: canToggleDraftState,
          onOpenReview: onOpenReview,
        ),
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
  const _PrRefreshButton({required this.prRef});

  final PrRef prRef;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastChecked = ref.watch(
      lastCheckedProvider.select(
        (m) => m['pr-detail:${prRef.repoFullName}#${prRef.number}'],
      ),
    );
    final refreshing = ref.watch(
      prDetailPollingProvider(prRef).select((s) => s.refreshing),
    );
    return RefreshControl(
      lastChecked: lastChecked,
      isLoading: refreshing,
      // refreshAll never throws and guards its own re-entrancy.
      onRefresh: () => unawaited(
        ref.read(prDetailPollingProvider(prRef).notifier).refreshAll(),
      ),
    );
  }
}

class _PrMoreActionsMenu extends ConsumerStatefulWidget {
  const _PrMoreActionsMenu({
    required this.pr,
    required this.prRef,
    required this.canClose,
    required this.canToggleDraft,
    required this.onOpenReview,
  });

  final PullRequest pr;
  final PrRef prRef;
  final bool canClose;
  final bool canToggleDraft;
  final VoidCallback onOpenReview;

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
    final workspace = ref.read(activeWorkspaceProvider);
    final repo = ref.read(prRepoRowProvider(widget.prRef));

    _controller.hide();
    if (!mounted) {
      return;
    }

    if (workspace == null || repo == null) {
      toaster.show(l10n.noActiveWorkspace, variant: CcToastVariant.danger);
      return;
    }

    // Open the review tab NOW, not when the call comes back. `startPrReview`
    // creates the run first and only then waits for the PR's worktree to
    // finish provisioning, so its reply can be a minute or two behind a review
    // that is already under way — and if that wait times out it throws, which
    // used to leave the operator with an error toast, a running pipeline and
    // no tab showing it. The tab renders the wait itself (see
    // [prReviewStarterProvider]) and flips to the live pipeline the moment the
    // run reaches the stream.
    widget.onOpenReview();

    setState(() => _aiLoading = true);
    try {
      // The same server op the "Ask AI" button calls. The trigger payload is
      // built SERVER-side: it needs the workspace-scoped repo id and the PR's
      // forge id, and a client assembling its own copy is how the two entry
      // points came to start two different reviews.
      final result = await ref
          .read(prReviewStarterProvider.notifier)
          .start(pr: widget.pr);
      // Either way the review tab is where the answer shows up: it renders the
      // run's live progress and then the artifact the review published. An
      // already-running review has the same destination. The toast handle
      // lives at the app shell, so the outcome is reported even if this menu
      // went away while the call was out.
      if (result['status'] == 'already_running') {
        toaster.show(
          l10n.reviewHubAlreadyRunning,
          variant: CcToastVariant.warning,
        );
      }
    } on Exception catch (e) {
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

  Future<void> _convertToDraft() async {
    _controller.hide();
    if (!mounted) {
      return;
    }
    await confirmAndConvertToDraft(context, ref, widget.pr, widget.prRef);
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
    // The inverse of the Ready-for-review button in the action row: an open PR
    // that is NOT a draft can go back to one. It lives here rather than in the
    // row because sending work back to draft is a correction, not the next
    // step on an open PR.
    final showConvertToDraft = widget.canToggleDraft && !widget.pr.isDraft;
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
              if (showConvertToDraft)
                CcTile(
                  leading: const Icon(AppIcons.gitPullRequestDraft, size: 16),
                  title: Text(l10n.convertToDraft),
                  onTap: _convertToDraft,
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
