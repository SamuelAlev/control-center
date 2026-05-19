import 'dart:async';

import 'package:cc_domain/features/messaging/domain/value_objects/channel_provisioning_status.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/messaging/presentation/utils/provisioning_step_label.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/messaging/providers/repo_changes_provider.dart';
import 'package:control_center/features/messaging/providers/worktree_file_ops_provider.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view.dart';
import 'package:control_center/features/pr_review/providers/pr_channel_provider.dart';
import 'package:control_center/features/pr_review/providers/pr_detail_polling_provider.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/source_control/scm_view.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The commit variants the commit box offers, mirroring VS Code's split-button
/// dropdown. Each maps to one `worktree.commitAndPush` call.
enum _CommitAction {
  /// Commit the staged index locally — no push.
  commit,

  /// Commit then push to the PR head branch (the default primary action).
  commitAndPush,

  /// Amend the previous commit (keeps its message when the box is empty).
  amend,

  /// Commit, integrate the remote branch (fetch + rebase), then push.
  commitAndSync,
}

/// One dropdown row: a [_CommitAction] with its label, icon, and resolved
/// enablement.
typedef _CommitMenuItem = ({
  _CommitAction action,
  String label,
  IconData icon,
  bool enabled,
});

/// A VS Code-style source-control surface for the PR workbench: a commit
/// message + "commit & push" split button pinned at the TOP of the left
/// column, the PR channel worktree's changes split into **Staged changes** (the
/// git index) and **Changes** (working tree + untracked) below it, and the
/// focused file's diff on the right. The commit UX lives HERE, not in chat; the
/// split button's dropdown offers commit-only, amend, and commit & sync.
///
/// Staging is REAL git (`repos.stage` / `repos.unstage` → `git add` /
/// `git reset`), so a commit ships exactly the staged index — no client-side
/// selection fiction. The commit footer commits the index as-is.
class PrSourceControlTab extends ConsumerStatefulWidget {
  /// Creates a [PrSourceControlTab].
  const PrSourceControlTab({
    super.key,
    required this.pr,
    required this.onOpenInEditor,
  });

  /// The pull request whose worktree changes are shown.
  final PullRequest pr;

  /// Opens the given path in an editable file tab (the quick-edit surface).
  final void Function(String path) onOpenInEditor;

  @override
  ConsumerState<PrSourceControlTab> createState() => _PrSourceControlTabState();
}

class _PrSourceControlTabState extends ConsumerState<PrSourceControlTab> {
  final _message = TextEditingController();

  /// The combined-list index (staged then unstaged) the user last jumped to.
  int _focusedIndex = 0;
  bool _busy = false;
  bool _stagedCollapsed = false;
  bool _changesCollapsed = false;

  /// The multi-file diff renders ALL changed files in one continuous scroll;
  /// clicking a file scrolls its section into view via
  /// [PrDiffViewState.jumpToFile]. The [PrimaryScrollController] is required —
  /// `jumpToFile` resolves the scroll target through it.
  final _diffKey = GlobalKey<PrDiffViewState>();
  final _diffScrollController = ScrollController();

  /// Working-tree changes come from the SERVER's isolated worktree; the client
  /// gets no push when code-server / an agent writes a file. So we re-fetch
  /// whenever the tab becomes visible and poll lightly while it stays on screen.
  bool _wasVisible = false;
  Timer? _poll;
  RepoChangesArgs? _lastArgs;

  static const _pollInterval = Duration(seconds: 3);

  @override
  void dispose() {
    _poll?.cancel();
    _message.dispose();
    _diffScrollController.dispose();
    super.dispose();
  }

  void _refreshChanges() {
    final args = _lastArgs;
    if (args != null && mounted) {
      ref.invalidate(repoChangesGroupedProvider(args));
    }
  }

  void _handleVisibility({required bool visible}) {
    if (visible == _wasVisible) {
      return;
    }
    _wasVisible = visible;
    if (visible) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _refreshChanges());
      _poll ??= Timer.periodic(_pollInterval, (_) {
        if (_wasVisible) {
          _refreshChanges();
        }
      });
    } else {
      _poll?.cancel();
      _poll = null;
    }
  }

  Future<void> _stage(
    String channelId,
    String repoId,
    List<String> paths,
  ) async {
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return;
    }
    await stageWorktreeFiles(
      ref.read(rpcClientProvider),
      workspaceId: workspaceId,
      channelId: channelId,
      repoId: repoId,
      paths: paths,
    );
    _refreshChanges();
  }

  Future<void> _unstage(
    String channelId,
    String repoId,
    List<String> paths,
  ) async {
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return;
    }
    await unstageWorktreeFiles(
      ref.read(rpcClientProvider),
      workspaceId: workspaceId,
      channelId: channelId,
      repoId: repoId,
      paths: paths,
    );
    _refreshChanges();
  }

  /// Pulls the latest PR commits into the worktree (`worktree.syncToPrHead`).
  /// Skips with a warning when the tree has uncommitted edits.
  Future<void> _syncToPrHead(String channelId, String repoId) async {
    final l10n = AppLocalizations.of(context);
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return;
    }
    final res = await syncWorktreeToPrHead(
      ref.read(rpcClientProvider),
      workspaceId: workspaceId,
      channelId: channelId,
      repoId: repoId,
    );
    if (!mounted) {
      return;
    }
    final toast = CcToastScope.maybeOf(context);
    if (res == null) {
      toast?.show(l10n.syncPrHeadFailed, variant: CcToastVariant.danger);
      return;
    }
    if (res.dirty) {
      toast?.show(l10n.syncPrHeadDirty, variant: CcToastVariant.warning);
      return;
    }
    if (res.synced) {
      _refreshChanges();
      ref
          .read(prDetailPollingProvider(widget.pr.number).notifier)
          .notifyDiffStale();
      toast?.show(l10n.syncedToPrHead, variant: CcToastVariant.success);
    } else {
      toast?.show(
        res.error ?? l10n.syncPrHeadFailed,
        variant: CcToastVariant.danger,
      );
    }
  }

  /// Runs the chosen commit [action] against the PR worktree. `paths: []`
  /// commits the STAGED index as-is (the server no longer `git add -A`s on an
  /// empty path list); the commit is attributed to the acting human.
  Future<void> _runCommit(
    String channelId,
    String repoId,
    _CommitAction action,
  ) async {
    final l10n = AppLocalizations.of(context);
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    final message = _message.text.trim();
    // Every action but an amend (which can rewrite just the message) needs one.
    if (workspaceId == null ||
        (message.isEmpty && action != _CommitAction.amend)) {
      return;
    }
    final push =
        action == _CommitAction.commitAndPush ||
        action == _CommitAction.commitAndSync;
    setState(() => _busy = true);
    final me = ref.read(currentIdentityProvider).value?.user;
    final res = await commitAndPushWorktree(
      ref.read(rpcClientProvider),
      workspaceId: workspaceId,
      channelId: channelId,
      repoId: repoId,
      message: message,
      paths: const [],
      push: push,
      amend: action == _CommitAction.amend,
      sync: action == _CommitAction.commitAndSync,
      pushBranch: widget.pr.headRef,
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
    // The commit landed: clear the box, refresh the tree, mark the diff stale.
    _message.clear();
    _refreshChanges();
    ref
        .read(prDetailPollingProvider(widget.pr.number).notifier)
        .notifyDiffStale();
    if (push) {
      toast?.show(
        res.pushed ? l10n.pushedToPr : (res.error ?? l10n.pushFailed),
        variant: res.pushed ? CcToastVariant.success : CcToastVariant.danger,
      );
    } else {
      toast?.show(
        action == _CommitAction.amend ? l10n.commitAmended : l10n.committed,
        variant: CcToastVariant.success,
      );
    }
  }

  /// Confirms then discards (reverts to HEAD) the given worktree files. Tracked
  /// files are restored; untracked/new files are skipped server-side.
  Future<void> _discard(
    String channelId,
    String repoId,
    List<String> paths,
  ) async {
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
    if (confirmed != true || !mounted) {
      return;
    }
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return;
    }
    final res = await revertWorktreeFiles(
      ref.read(rpcClientProvider),
      workspaceId: workspaceId,
      channelId: channelId,
      repoId: repoId,
      paths: paths,
    );
    if (!mounted) {
      return;
    }
    _refreshChanges();
    final toast = CcToastScope.maybeOf(context);
    if (res == null) {
      toast?.show(l10n.discardFailed, variant: CcToastVariant.danger);
      return;
    }
    if (res.skipped.isNotEmpty) {
      toast?.show(
        l10n.discardedWithSkipped(res.reverted, res.skipped.length),
        variant: CcToastVariant.warning,
      );
    } else {
      toast?.show(
        l10n.discardedFiles(res.reverted),
        variant: CcToastVariant.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    _handleVisibility(visible: TickerMode.valuesOf(context).enabled);
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final repoId = prRepoIdFor(ref, widget.pr);
    final channelAsync = ref.watch(prChannelProvider(widget.pr));

    if (workspaceId == null || repoId == null) {
      return Center(child: Text(l10n.ideFileLoading));
    }
    return channelAsync.when(
      loading: () => const Center(child: CcSpinner()),
      error: (e, _) => Center(child: Text('$e')),
      data: (channelId) {
        final status = ref.watch(channelProvisioningStatusProvider(channelId));
        if (status == ChannelProvisioningStatus.provisioning) {
          final step = ref.watch(channelProvisioningStepProvider(channelId));
          return _preparing(t, provisioningStepLabel(l10n, step));
        }
        if (status == ChannelProvisioningStatus.failed) {
          return _failed(t, l10n);
        }
        final args = (
          workspaceId: workspaceId,
          repoId: repoId,
          channelId: channelId,
        );
        _lastArgs = args;
        final async = ref.watch(repoChangesGroupedProvider(args));
        return async.when(
          loading: () => const Center(child: CcSpinner()),
          error: (_, _) => _empty(t, l10n),
          data: (changes) {
            final staged = changes.staged;
            final unstaged = changes.unstaged;
            if (staged.isEmpty && unstaged.isEmpty) {
              return _empty(t, l10n);
            }
            // The diff pane renders the combined list (staged then unstaged);
            // rows jump by their combined index.
            final combined = [...staged, ...unstaged];
            final focused = _focusedIndex.clamp(0, combined.length - 1);
            // The commit box sits at the TOP of the changes column (VS Code
            // layout): message + a "Commit & push" split button whose dropdown
            // offers the other commit variants.
            final commitBox = _CommitBox(
              controller: _message,
              busy: _busy,
              stagedCount: staged.length,
              canPush: widget.pr.headRef.isNotEmpty,
              onAction: (action) => _runCommit(channelId, repoId, action),
            );
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 300,
                  child: _ChangesList(
                    commitBox: commitBox,
                    staged: staged,
                    unstaged: unstaged,
                    focusedIndex: focused,
                    stagedCollapsed: _stagedCollapsed,
                    changesCollapsed: _changesCollapsed,
                    onToggleStaged: () =>
                        setState(() => _stagedCollapsed = !_stagedCollapsed),
                    onToggleChanges: () =>
                        setState(() => _changesCollapsed = !_changesCollapsed),
                    onFocus: (i) {
                      setState(() => _focusedIndex = i);
                      _diffKey.currentState?.jumpToFile(i);
                    },
                    onRefresh: _refreshChanges,
                    onSyncToPrHead: () => _syncToPrHead(channelId, repoId),
                    onStage: (p) => _stage(channelId, repoId, [p]),
                    onUnstage: (p) => _unstage(channelId, repoId, [p]),
                    onDiscard: (p) => _discard(channelId, repoId, [p]),
                    onEdit: widget.onOpenInEditor,
                    onStageAll: () => _stage(
                      channelId,
                      repoId,
                      unstaged.map((f) => f.filename).toList(),
                    ),
                    onUnstageAll: () => _unstage(
                      channelId,
                      repoId,
                      staged.map((f) => f.filename).toList(),
                    ),
                    onDiscardAll: () => _discard(
                      channelId,
                      repoId,
                      unstaged.map((f) => f.filename).toList(),
                    ),
                  ),
                ),
                Container(width: 1, color: t.lineStrong),
                Expanded(
                  child: ColoredBox(
                    color: t.bgPrimary,
                    child: PrimaryScrollController(
                      controller: _diffScrollController,
                      child: CcScrollbar(
                        controller: _diffScrollController,
                        thumbVisibility: true,
                        child: CustomScrollView(
                          controller: _diffScrollController,
                          slivers: [
                            PrDiffView(
                              key: _diffKey,
                              files: combined,
                              comments: const [],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _empty(DesignSystemTokens t, AppLocalizations l10n) => ColoredBox(
    color: t.bgPrimary,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.gitBranch, size: 22, color: t.textTertiary),
          const SizedBox(height: 10),
          Text(
            l10n.ideSourceControlNoChanges,
            style: TextStyle(fontSize: 12, color: t.textTertiary),
          ),
        ],
      ),
    ),
  );

  Widget _preparing(DesignSystemTokens t, String label) => ColoredBox(
    color: t.bgPrimary,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CcSpinner(),
          const SizedBox(height: AppSpacing.sm),
          Text(label, style: TextStyle(fontSize: 12, color: t.textTertiary)),
        ],
      ),
    ),
  );

  Widget _failed(DesignSystemTokens t, AppLocalizations l10n) => ColoredBox(
    color: t.bgPrimary,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.triangleAlert, size: 22, color: t.textTertiary),
            const SizedBox(height: 10),
            Text(
              l10n.prWorktreeUnavailable,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: t.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              l10n.prWorktreeUnavailableHint,
              style: TextStyle(fontSize: 12, color: t.textTertiary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}

/// The two-group changed-files list (Staged changes / Changes), VS Code style,
/// with the [commitBox] pinned above the groups.
class _ChangesList extends StatelessWidget {
  const _ChangesList({
    required this.commitBox,
    required this.staged,
    required this.unstaged,
    required this.focusedIndex,
    required this.stagedCollapsed,
    required this.changesCollapsed,
    required this.onToggleStaged,
    required this.onToggleChanges,
    required this.onFocus,
    required this.onRefresh,
    required this.onSyncToPrHead,
    required this.onStage,
    required this.onUnstage,
    required this.onDiscard,
    required this.onEdit,
    required this.onStageAll,
    required this.onUnstageAll,
    required this.onDiscardAll,
  });

  /// The message input + commit split-button, pinned above the file groups.
  final Widget commitBox;

  final List<PrFile> staged;
  final List<PrFile> unstaged;
  final int focusedIndex;
  final bool stagedCollapsed;
  final bool changesCollapsed;
  final VoidCallback onToggleStaged;
  final VoidCallback onToggleChanges;
  final ValueChanged<int> onFocus;
  final VoidCallback onRefresh;
  final VoidCallback onSyncToPrHead;
  final ValueChanged<String> onStage;
  final ValueChanged<String> onUnstage;
  final ValueChanged<String> onDiscard;
  final ValueChanged<String> onEdit;
  final VoidCallback onStageAll;
  final VoidCallback onUnstageAll;
  final VoidCallback onDiscardAll;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return ColoredBox(
      color: t.bgSecondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.xs,
              AppSpacing.xs,
              AppSpacing.xs,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.ideSourceControl,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                      color: t.textSecondary,
                    ),
                  ),
                ),
                CcIconButton(
                  icon: AppIcons.download,
                  size: CcButtonSize.sm,
                  tooltip: l10n.syncToPrHead,
                  onPressed: onSyncToPrHead,
                ),
                CcIconButton(
                  icon: AppIcons.refreshCw,
                  size: CcButtonSize.sm,
                  tooltip: l10n.refresh,
                  onPressed: onRefresh,
                ),
              ],
            ),
          ),
          commitBox,
          Container(height: 1, color: t.borderSecondary),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 2),
              children: [
                if (staged.isNotEmpty)
                  ScmGroup(
                    title: l10n.stagedChanges,
                    count: staged.length,
                    collapsed: stagedCollapsed,
                    onToggleCollapse: onToggleStaged,
                    actions: [
                      (
                        icon: AppIcons.minus,
                        tooltip: l10n.unstageAll,
                        onPressed: onUnstageAll,
                      ),
                    ],
                    children: [
                      for (var i = 0; i < staged.length; i++)
                        ScmFileRow(
                          file: staged[i],
                          selected: focusedIndex == i,
                          onTap: () => onFocus(i),
                          actions: [
                            (
                              icon: AppIcons.fileCode,
                              tooltip: l10n.openInEditor,
                              onPressed: () => onEdit(staged[i].filename),
                            ),
                            (
                              icon: AppIcons.minus,
                              tooltip: l10n.unstageFile,
                              onPressed: () => onUnstage(staged[i].filename),
                            ),
                          ],
                        ),
                    ],
                  ),
                if (unstaged.isNotEmpty)
                  ScmGroup(
                    title: l10n.changes,
                    count: unstaged.length,
                    collapsed: changesCollapsed,
                    onToggleCollapse: onToggleChanges,
                    actions: [
                      (
                        icon: AppIcons.rotateCcw,
                        tooltip: l10n.discardAll,
                        onPressed: onDiscardAll,
                      ),
                      (
                        icon: AppIcons.plus,
                        tooltip: l10n.stageAll,
                        onPressed: onStageAll,
                      ),
                    ],
                    children: [
                      for (var j = 0; j < unstaged.length; j++)
                        ScmFileRow(
                          file: unstaged[j],
                          selected: focusedIndex == staged.length + j,
                          onTap: () => onFocus(staged.length + j),
                          actions: [
                            (
                              icon: AppIcons.fileCode,
                              tooltip: l10n.openInEditor,
                              onPressed: () => onEdit(unstaged[j].filename),
                            ),
                            (
                              icon: AppIcons.rotateCcw,
                              tooltip: l10n.discard,
                              onPressed: () => onDiscard(unstaged[j].filename),
                            ),
                            (
                              icon: AppIcons.plus,
                              tooltip: l10n.stageFile,
                              onPressed: () => onStage(unstaged[j].filename),
                            ),
                          ],
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The commit message field + "Commit & push" split button, pinned at the top
/// of the changes column. The primary button pushes; the chevron opens a
/// [CcMenu] of the other commit variants (commit-only, amend, commit & sync).
/// Enablement is re-derived on every keystroke so an empty message greys the
/// commit actions out.
class _CommitBox extends StatelessWidget {
  const _CommitBox({
    required this.controller,
    required this.busy,
    required this.stagedCount,
    required this.canPush,
    required this.onAction,
  });

  final TextEditingController controller;
  final bool busy;
  final int stagedCount;
  final bool canPush;
  final ValueChanged<_CommitAction> onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      // The controller is a Listenable — rebuild the button enablement as the
      // message text changes.
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final hasStaged = stagedCount > 0;
          final hasMessage = controller.text.trim().isNotEmpty;
          bool enabled(_CommitAction action) {
            if (busy) {
              return false;
            }
            return switch (action) {
              _CommitAction.commit => hasStaged && hasMessage,
              _CommitAction.commitAndPush => hasStaged && hasMessage && canPush,
              _CommitAction.commitAndSync => hasStaged && hasMessage && canPush,
              // An amend can rewrite just the message, so staged changes are
              // not required — but there must be something to do.
              _CommitAction.amend => hasStaged || hasMessage,
            };
          }

          final primaryEnabled = enabled(_CommitAction.commitAndPush);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CcTextField(
                controller: controller,
                hintText: hasStaged
                    ? l10n.commitMessageHint
                    : l10n.stageChangesToCommit,
                enabled: !busy,
                onSubmitted: (_) {
                  if (primaryEnabled) {
                    onAction(_CommitAction.commitAndPush);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              _CommitSplitButton(
                label: busy ? l10n.saving : l10n.commitAndPush,
                busy: busy,
                primaryEnabled: primaryEnabled,
                onPrimary: () => onAction(_CommitAction.commitAndPush),
                items: [
                  (
                    action: _CommitAction.commit,
                    label: l10n.commit,
                    icon: AppIcons.gitCommitHorizontal,
                    enabled: enabled(_CommitAction.commit),
                  ),
                  (
                    action: _CommitAction.amend,
                    label: l10n.commitAmend,
                    icon: AppIcons.squarePen,
                    enabled: enabled(_CommitAction.amend),
                  ),
                  (
                    action: _CommitAction.commitAndSync,
                    label: l10n.commitAndSync,
                    icon: AppIcons.repeat,
                    enabled: enabled(_CommitAction.commitAndSync),
                  ),
                ],
                onSelected: onAction,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A VS Code-style split button: a full-width primary [CcButton] joined to a
/// chevron segment that opens a [CcMenu] of alternative commit [items].
class _CommitSplitButton extends StatelessWidget {
  const _CommitSplitButton({
    required this.label,
    required this.busy,
    required this.primaryEnabled,
    required this.onPrimary,
    required this.items,
    required this.onSelected,
  });

  final String label;
  final bool busy;
  final bool primaryEnabled;
  final VoidCallback onPrimary;
  final List<_CommitMenuItem> items;
  final ValueChanged<_CommitAction> onSelected;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final primary = CcButtonTokens.primary(t);
    return Row(
      children: [
        Expanded(
          child: CcButton(
            variant: CcButtonVariant.primary,
            icon: AppIcons.gitCommitHorizontal,
            loading: busy,
            fullWidth: true,
            onPressed: primaryEnabled ? onPrimary : null,
            child: Text(label),
          ),
        ),
        const SizedBox(width: 2),
        CcMenu(
          semanticLabel: l10n.moreCommitActions,
          targetAnchor: Alignment.bottomRight,
          followerAnchor: Alignment.topRight,
          minWidth: 200,
          items: [
            for (final item in items)
              CcMenuItem(
                label: item.label,
                icon: item.icon,
                enabled: item.enabled,
                onSelected: () => onSelected(item.action),
              ),
          ],
          target: _ChevronSegment(tokens: primary, enabled: !busy, t: t),
        ),
      ],
    );
  }
}

/// The chevron half of the split button — an inert visual matched to the
/// primary button's resting fill (the enclosing [CcMenu] owns the tap).
class _ChevronSegment extends StatelessWidget {
  const _ChevronSegment({
    required this.tokens,
    required this.enabled,
    required this.t,
  });

  final CcButtonTokens tokens;
  final bool enabled;
  final DesignSystemTokens t;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      // Matches the 40px CcButtonSize.md primary button height.
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: enabled ? tokens.bg : t.bgDisabled,
        borderRadius: AppRadii.brSm,
      ),
      child: Icon(
        AppIcons.chevronDown,
        size: 16,
        color: enabled ? tokens.fg : t.textDisabled,
      ),
    );
  }
}
