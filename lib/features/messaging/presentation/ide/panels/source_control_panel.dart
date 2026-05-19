import 'dart:async';

import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_provisioning_status.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/messaging/presentation/utils/provisioning_step_label.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/messaging/providers/repo_changes_provider.dart';
import 'package:control_center/features/messaging/providers/space_worktrees_provider.dart';
import 'package:control_center/features/messaging/providers/worktree_file_ops_provider.dart';
import 'package:control_center/features/pr_review/providers/pr_space_provider.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/source_control/scm_commit_box.dart';
import 'package:control_center/shared/widgets/source_control/scm_view.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Source Control panel: VS Code's source-control view for the conversation —
/// one collapsible section per repo, each with a commit message + split button
/// and the repo's changes split into **Staged changes** (the git index) and
/// **Changes** (working tree + untracked).
///
/// The panel is scoped to the repos the space actually CLONED
/// ([spaceWorktreesProvider]): a workspace can link a dozen repos while a space
/// checks out one, and a repo with no worktree here has no working tree to
/// diff, stage or commit — listing it would offer actions that cannot run.
/// The header's second line is that worktree's branch.
///
/// Staging is REAL git (`repos.stage` / `repos.unstage` → `git add` /
/// `git reset`), so a commit ships exactly the staged index. "Commit & push"
/// pushes the conversation's own branch to `origin`, which is what makes it
/// available to open a pull request from. Clicking a changed file opens a
/// multi-file "Review code" tab anchored to it; "Open in editor" opens it in
/// the conversation's editor; "Discard" restores it to HEAD.
class SourceControlPanel extends ConsumerWidget {
  /// Creates a [SourceControlPanel].
  const SourceControlPanel({
    super.key,
    required this.workspaceId,
    this.spaceId,
    required this.onOpenReview,
    required this.onViewSource,
    required this.onRevertFiles,
  });

  /// The workspace whose linked repos the changes are scoped to.
  final String workspaceId;

  /// The active conversation, whose isolated CoW worktrees the panel shows.
  /// Null when no conversation is open → there is no working tree to report on.
  final String? spaceId;

  /// Called with `(repoId, file)` when a changed file is opened for review.
  final ValueChanged<({String repoId, PrFile file})> onOpenReview;

  /// Called with `(repoId, path)` to open a file in the conversation's editor.
  final ValueChanged<({String repoId, String path})> onViewSource;

  /// Called with `(repoId, paths)` to revert one or more files to HEAD.
  final ValueChanged<({String repoId, List<String> paths})> onRevertFiles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final spaceId = this.spaceId;
    if (spaceId == null) {
      return CcEmptyState(
        icon: AppIcons.gitBranch,
        message: l10n.ideSourceControlNoSpace,
      );
    }

    // While the space is still checking repos out there are no worktrees yet;
    // saying "no repositories" then would be a lie about a tree still being
    // created. Report the provisioning step instead.
    final status = ref.watch(spaceProvisioningStatusProvider(spaceId));
    if (status == SpaceProvisioningStatus.provisioning) {
      return _Preparing(
        label: provisioningStepLabel(
          l10n,
          ref.watch(spaceProvisioningStepProvider(spaceId)),
        ),
      );
    }

    final reposAsync = ref.watch(reposForWorkspaceProvider(workspaceId));
    final worktreesAsync = ref.watch(
      spaceWorktreesProvider((workspaceId: workspaceId, spaceId: spaceId)),
    );
    final repos = reposAsync.value;
    final worktrees = worktreesAsync.value;
    if (repos == null || worktrees == null) {
      return const Center(child: CcSpinner());
    }

    // The workspace's repo order is the one the operator arranged, so the
    // sections follow it; the worktree rows only decide membership + branch.
    final branchByRepo = {for (final w in worktrees) w.repoId: w.branch};
    final cloned = [
      for (final repo in repos)
        if (branchByRepo.containsKey(repo.id)) repo,
    ];
    if (cloned.isEmpty) {
      return CcEmptyState(
        icon: AppIcons.gitBranch,
        message: l10n.noReposInConversation,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      itemCount: cloned.length,
      itemBuilder: (context, i) => _RepoSection(
        // Keyed by repo so a re-order (or a repo leaving the space) moves the
        // section's own state — its commit draft above all — with it.
        key: ValueKey(cloned[i].id),
        workspaceId: workspaceId,
        spaceId: spaceId,
        repo: cloned[i],
        branch: branchByRepo[cloned[i].id] ?? '',
        onOpenReview: onOpenReview,
        onViewSource: onViewSource,
        onRevertFiles: onRevertFiles,
      ),
    );
  }
}

/// The "still checking out" state — the space owns no worktree to diff yet.
class _Preparing extends StatelessWidget {
  const _Preparing({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CcSpinner(),
          const SizedBox(height: AppSpacing.sm),
          Text(label, style: TextStyle(fontSize: 12, color: t.textTertiary)),
        ],
      ),
    );
  }
}

/// One repo's source-control section: header (name + branch + count), commit
/// box, the staged/unstaged groups and the pull-request footer.
class _RepoSection extends ConsumerStatefulWidget {
  const _RepoSection({
    super.key,
    required this.workspaceId,
    required this.spaceId,
    required this.repo,
    required this.branch,
    required this.onOpenReview,
    required this.onViewSource,
    required this.onRevertFiles,
  });

  final String workspaceId;
  final String spaceId;
  final Repo repo;

  /// The conversation worktree's branch — the ref "commit & push" publishes.
  final String branch;

  final ValueChanged<({String repoId, PrFile file})> onOpenReview;
  final ValueChanged<({String repoId, String path})> onViewSource;
  final ValueChanged<({String repoId, List<String> paths})> onRevertFiles;

  @override
  ConsumerState<_RepoSection> createState() => _RepoSectionState();
}

class _RepoSectionState extends ConsumerState<_RepoSection>
    with AutomaticKeepAliveClientMixin {
  final _message = TextEditingController();

  // The sections are virtualized (a repo with a big refactor in it can hold
  // hundreds of rows), and a disposed section would take the operator's
  // half-typed commit message with it. Staying alive costs a few widgets per
  // repo and keeps the draft, the collapse state and the focused row.
  @override
  bool get wantKeepAlive => true;

  bool _collapsed = false;
  bool _stagedCollapsed = false;
  bool _changesCollapsed = false;
  bool _busy = false;
  String? _focused;

  /// The working tree lives on the SERVER and nothing pushes an edit to the
  /// client, so an agent (or code-server) writing a file would leave this list
  /// stale. Poll lightly while the section is visible and expanded.
  Timer? _poll;
  bool _polling = false;

  static const _pollInterval = Duration(seconds: 4);

  RepoChangesArgs get _args => (
    workspaceId: widget.workspaceId,
    repoId: widget.repo.id,
    spaceId: widget.spaceId,
  );

  @override
  void dispose() {
    _poll?.cancel();
    _message.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) {
      ref.invalidate(repoChangesGroupedProvider(_args));
    }
  }

  void _syncPolling({required bool active}) {
    if (active == _polling) {
      return;
    }
    _polling = active;
    if (active) {
      _poll = Timer.periodic(_pollInterval, (_) => _refresh());
    } else {
      _poll?.cancel();
      _poll = null;
    }
  }

  Future<void> _stage(List<String> paths) async {
    await stageWorktreeFiles(
      ref.read(rpcClientProvider),
      workspaceId: widget.workspaceId,
      spaceId: widget.spaceId,
      repoId: widget.repo.id,
      paths: paths,
    );
    _refresh();
  }

  Future<void> _unstage(List<String> paths) async {
    await unstageWorktreeFiles(
      ref.read(rpcClientProvider),
      workspaceId: widget.workspaceId,
      spaceId: widget.spaceId,
      repoId: widget.repo.id,
      paths: paths,
    );
    _refresh();
  }

  /// Runs the chosen commit [action] against the conversation's worktree.
  /// `paths: []` commits the STAGED index as-is, and the push (when asked for)
  /// goes to the worktree's OWN branch — the server resolves it, which is what
  /// publishes a conversation branch GitHub has never seen.
  Future<void> _runCommit(ScmCommitAction action) async {
    final l10n = AppLocalizations.of(context);
    final message = _message.text.trim();
    // Every action but an amend (which can rewrite just the message) needs one.
    if (message.isEmpty && action != ScmCommitAction.amend) {
      return;
    }
    final push =
        action == ScmCommitAction.commitAndPush ||
        action == ScmCommitAction.commitAndSync;
    setState(() => _busy = true);
    final me = ref.read(currentIdentityProvider).value?.user;
    final res = await commitAndPushWorktree(
      ref.read(rpcClientProvider),
      workspaceId: widget.workspaceId,
      spaceId: widget.spaceId,
      repoId: widget.repo.id,
      message: message,
      push: push,
      amend: action == ScmCommitAction.amend,
      sync: action == ScmCommitAction.commitAndSync,
      authorName: me?.gitAuthorName ?? me?.displayName,
      authorEmail: me?.gitAuthorEmail ?? me?.email,
    );
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    final toast = CcToastScope.maybeOf(context);
    if (res == null || !res.committed) {
      toast?.show(
        res?.error ?? l10n.commitFailed,
        variant: CcToastVariant.danger,
      );
      return;
    }
    _message.clear();
    _refresh();
    if (!push) {
      toast?.show(
        action == ScmCommitAction.amend ? l10n.commitAmended : l10n.committed,
        variant: CcToastVariant.success,
      );
      return;
    }
    if (res.pushed) {
      // The branch now exists on the forge, so the "create pull request"
      // affordance can resolve against it — re-check what this space's branches
      // point at (the match is a one-shot read, not a subscription).
      ref.invalidate(spaceBranchPullRequestsProvider(widget.spaceId));
      toast?.show(
        l10n.branchPublished(widget.branch),
        variant: CcToastVariant.success,
      );
    } else {
      toast?.show(res.error ?? l10n.pushFailed, variant: CcToastVariant.danger);
    }
  }

  Future<void> _createPullRequest(BuildContext context) async {
    await ref.read(activeRepoIdProvider.notifier).setActive(widget.repo.id);
    if (!context.mounted) {
      return;
    }
    // Carry the conversation through: its isolated worktree holds the branch the
    // user means to open the PR from and that branch is local-only until it is
    // published, so the compose screen cannot rediscover it from GitHub.
    context.go(
      pullRequestsComposeRoute(widget.workspaceId, spaceId: widget.spaceId),
    );
  }

  /// Confirmation dialog for discarding [paths] (restoring them to HEAD).
  Future<void> _confirmDiscard(List<String> paths) async {
    if (paths.isEmpty) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final confirmed = await showCcDialog<bool>(
      context: context,
      builder: (context) {
        final t = context.designSystem ?? DesignSystemTokens.light();
        return CcDialog(
          title: l10n.discardChangesTitle,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.discardChangesMessage(paths.length),
                style: TextStyle(fontSize: 13, color: t.textPrimary),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CcButton(
                    variant: CcButtonVariant.line,
                    size: CcButtonSize.sm,
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(l10n.cancel),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  CcButton(
                    variant: CcButtonVariant.destructive,
                    size: CcButtonSize.sm,
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(l10n.discard),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
    if (confirmed == true) {
      // The layout owns the revert (and its toasts); it invalidates both the
      // flat and the grouped changes providers when it lands.
      widget.onRevertFiles((repoId: widget.repo.id, paths: paths));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();

    final async = ref.watch(repoChangesGroupedProvider(_args));
    final changes =
        async.value ?? (staged: const <PrFile>[], unstaged: const <PrFile>[]);
    final staged = changes.staged;
    final unstaged = changes.unstaged;
    final total = staged.length + unstaged.length;
    final loading = async.isLoading && async.value == null;

    _syncPolling(active: !_collapsed && TickerMode.valuesOf(context).enabled);

    // The PR this conversation already opened from this repo's worktree branch,
    // if any. Offering "create" for a branch that has one sends the operator to
    // a compose screen GitHub will refuse.
    final existingPr = ref.watch(
      spaceBranchPullRequestForRepoProvider((
        spaceId: widget.spaceId,
        repoId: widget.repo.id,
      )),
    );

    // Untracked files have no HEAD version to restore, so they are not part of
    // a "discard all" — with nothing else dirty the action has no work to do.
    final revertible = [
      for (final f in unstaged)
        if (f.status != PrFileStatus.added) f.filename,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ScmGroup(
          title: widget.repo.fullName,
          subtitle: widget.branch,
          count: total,
          collapsed: _collapsed,
          onToggleCollapse: () {
            setState(() => _collapsed = !_collapsed);
            // Expanding is a "show me what's there" gesture, and the poll is
            // off while collapsed — what's cached can be minutes old.
            if (!_collapsed) {
              _refresh();
            }
          },
          actions: [
            (
              icon: AppIcons.refreshCw,
              tooltip: l10n.refresh,
              onPressed: loading ? null : _refresh,
            ),
          ],
          children: [
            if (loading)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Center(child: CcSpinner(size: 14)),
              )
            else ...[
              // The commit box only appears where there is something to commit:
              // a repo the conversation has not touched keeps one quiet line.
              if (total == 0)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  child: Text(
                    l10n.ideSourceControlNoChanges,
                    style: TextStyle(fontSize: 12, color: t.textTertiary),
                  ),
                )
              else ...[
                ScmCommitBox(
                  controller: _message,
                  busy: _busy,
                  dense: true,
                  stagedCount: staged.length,
                  canPush: widget.repo.hasForgeRemote,
                  onAction: _runCommit,
                ),
                if (staged.isNotEmpty)
                  ScmGroup(
                    title: l10n.stagedChanges,
                    count: staged.length,
                    collapsed: _stagedCollapsed,
                    onToggleCollapse: () =>
                        setState(() => _stagedCollapsed = !_stagedCollapsed),
                    actions: [
                      (
                        icon: AppIcons.minus,
                        tooltip: l10n.unstageAll,
                        onPressed: () =>
                            _unstage([for (final f in staged) f.filename]),
                      ),
                    ],
                    children: [
                      for (final file in staged)
                        _fileRow(l10n, file, staged: true),
                    ],
                  ),
                if (unstaged.isNotEmpty)
                  ScmGroup(
                    title: l10n.changes,
                    count: unstaged.length,
                    collapsed: _changesCollapsed,
                    onToggleCollapse: () =>
                        setState(() => _changesCollapsed = !_changesCollapsed),
                    actions: [
                      (
                        icon: AppIcons.rotateCcw,
                        tooltip: l10n.discardAll,
                        onPressed: revertible.isEmpty
                            ? null
                            : () => _confirmDiscard(revertible),
                      ),
                      (
                        icon: AppIcons.plus,
                        tooltip: l10n.stageAll,
                        onPressed: () =>
                            _stage([for (final f in unstaged) f.filename]),
                      ),
                    ],
                    children: [
                      for (final file in unstaged)
                        _fileRow(l10n, file, staged: false),
                    ],
                  ),
              ],
              if (widget.repo.hasForgeRemote)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.sm,
                    AppSpacing.xs,
                    AppSpacing.sm,
                    AppSpacing.sm,
                  ),
                  child: existingPr == null
                      ? CcButton(
                          onPressed: () => _createPullRequest(context),
                          icon: AppIcons.gitPullRequestCreate,
                          size: CcButtonSize.sm,
                          variant: CcButtonVariant.line,
                          fullWidth: true,
                          child: Text(l10n.ideSourceControlCreatePr),
                        )
                      : CcButton(
                          onPressed: () => context.go(
                            pullRequestDetailRoute(
                              widget.workspaceId,
                              widget.repo.fullName,
                              existingPr.number,
                            ),
                          ),
                          icon: AppIcons.gitPullRequest,
                          size: CcButtonSize.sm,
                          variant: CcButtonVariant.line,
                          fullWidth: true,
                          child: Text(
                            l10n.ideSourceControlViewPr(existingPr.number),
                          ),
                        ),
                ),
            ],
          ],
        ),
        // Outside the group so a collapsed repo keeps its separator.
        Container(height: 1, color: t.borderSecondary),
      ],
    );
  }

  /// One changed-file row. Staged rows offer "unstage"; unstaged rows offer
  /// "discard" (never for an untracked file — there is no HEAD version to
  /// restore) and "stage".
  Widget _fileRow(AppLocalizations l10n, PrFile file, {required bool staged}) {
    return ScmFileRow(
      file: file,
      selected: _focused == file.filename,
      onTap: () {
        setState(() => _focused = file.filename);
        widget.onOpenReview((repoId: widget.repo.id, file: file));
      },
      actions: [
        (
          icon: AppIcons.fileCode,
          tooltip: l10n.openInEditor,
          onPressed: () => widget.onViewSource((
            repoId: widget.repo.id,
            path: file.filename,
          )),
        ),
        if (staged)
          (
            icon: AppIcons.minus,
            tooltip: l10n.unstageFile,
            onPressed: () => _unstage([file.filename]),
          )
        else ...[
          (
            icon: AppIcons.rotateCcw,
            tooltip: file.status == PrFileStatus.added
                ? l10n.ideRevertUntracked
                : l10n.discard,
            onPressed: file.status == PrFileStatus.added
                ? null
                : () => _confirmDiscard([file.filename]),
          ),
          (
            icon: AppIcons.plus,
            tooltip: l10n.stageFile,
            onPressed: () => _stage([file.filename]),
          ),
        ],
      ],
    );
  }
}
