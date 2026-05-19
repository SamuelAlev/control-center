import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/providers/repo_changes_provider.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/source_control/scm_view.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Source Control panel: the working-tree changes for each linked repo, with a
/// per-repo "Create pull request" action.
///
/// For each repo it watches [repoChangesProvider] (server-side `git diff HEAD`
/// + untracked). Rows follow the VS Code layout (two-line name + dimmed dir,
/// status letter on the right, hover actions). Clicking a changed file opens a
/// multi-file "Review code" tab anchored to it; "View source" opens the file in
/// the conversation's editor; "Revert" restores it to HEAD.
class SourceControlPanel extends ConsumerWidget {
  /// Creates a [SourceControlPanel].
  const SourceControlPanel({
    super.key,
    required this.workspaceId,
    this.channelId,
    required this.onOpenReview,
    required this.onViewSource,
    required this.onRevertFiles,
  });

  /// The workspace whose linked repos the changes are scoped to.
  final String workspaceId;

  /// The active conversation, whose isolated CoW worktree the diff reflects.
  /// Null when no conversation is open → falls back to the linked-repo checkout.
  final String? channelId;

  /// Called with `(repoId, file)` when a changed file is opened for review.
  final ValueChanged<({String repoId, PrFile file})> onOpenReview;

  /// Called with `(repoId, path)` to open a file in the conversation's editor.
  final ValueChanged<({String repoId, String path})> onViewSource;

  /// Called with `(repoId, paths)` to revert one or more files to HEAD.
  final ValueChanged<({String repoId, List<String> paths})> onRevertFiles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final reposAsync = ref.watch(reposForWorkspaceProvider(workspaceId));

    return reposAsync.when(
      loading: () => const Center(child: CcSpinner()),
      error: (_, _) => CcEmptyState(
        icon: AppIcons.gitBranch,
        message: l10n.ideSourceControlNoChanges,
      ),
      data: (repos) {
        if (repos.isEmpty) {
          return CcEmptyState(
            icon: AppIcons.gitBranch,
            message: l10n.ideSourceControlNoChanges,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          itemCount: repos.length,
          itemBuilder: (context, i) => _RepoChangesSection(
            workspaceId: workspaceId,
            channelId: channelId,
            repo: repos[i],
            onOpenReview: onOpenReview,
            onViewSource: onViewSource,
            onRevertFiles: onRevertFiles,
          ),
        );
      },
    );
  }
}

class _RepoChangesSection extends ConsumerStatefulWidget {
  const _RepoChangesSection({
    required this.workspaceId,
    required this.channelId,
    required this.repo,
    required this.onOpenReview,
    required this.onViewSource,
    required this.onRevertFiles,
  });

  final String workspaceId;
  final String? channelId;
  final Repo repo;
  final ValueChanged<({String repoId, PrFile file})> onOpenReview;
  final ValueChanged<({String repoId, String path})> onViewSource;
  final ValueChanged<({String repoId, List<String> paths})> onRevertFiles;

  @override
  ConsumerState<_RepoChangesSection> createState() =>
      _RepoChangesSectionState();
}

class _RepoChangesSectionState extends ConsumerState<_RepoChangesSection> {
  bool _collapsed = false;
  String? _focused;

  RepoChangesArgs get _args => (
    workspaceId: widget.workspaceId,
    repoId: widget.repo.id,
    channelId: widget.channelId,
  );

  Future<void> _createPullRequest(BuildContext context) async {
    await ref.read(activeRepoIdProvider.notifier).setActive(widget.repo.id);
    if (!context.mounted) {
      return;
    }
    // Carry the conversation through: its isolated worktree holds the branch the
    // user means to open the PR from and that branch is local-only until it is
    // published, so the compose screen cannot rediscover it from GitHub.
    context.go(
      pullRequestsComposeRoute(widget.workspaceId, channelId: widget.channelId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();

    final filesAsync = ref.watch(repoChangesProvider(_args));
    final files = filesAsync.value ?? const <PrFile>[];
    final loading = filesAsync.isLoading && files.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ScmGroup(
          title: widget.repo.fullName,
          count: files.length,
          collapsed: _collapsed,
          onToggleCollapse: () => setState(() => _collapsed = !_collapsed),
          actions: [
            (
              icon: AppIcons.refreshCw,
              tooltip: l10n.refresh,
              onPressed: loading
                  ? null
                  : () => ref.invalidate(repoChangesProvider(_args)),
            ),
          ],
          children: [
            if (loading)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Center(child: CcSpinner(size: 14)),
              )
            else if (files.isEmpty)
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
            else
              for (final file in files)
                ScmFileRow(
                  file: file,
                  selected: _focused == file.filename,
                  onTap: () {
                    setState(() => _focused = file.filename);
                    widget.onOpenReview((repoId: widget.repo.id, file: file));
                  },
                  actions: [
                    (
                      icon: AppIcons.code,
                      tooltip: l10n.ideViewSource,
                      onPressed: () => widget.onViewSource((
                        repoId: widget.repo.id,
                        path: file.filename,
                      )),
                    ),
                    (
                      icon: AppIcons.undo2,
                      tooltip: file.status == PrFileStatus.added
                          ? l10n.ideRevertUntracked
                          : l10n.ideRevert,
                      onPressed: file.status == PrFileStatus.added
                          ? null
                          : () => _confirmRevert([file.filename]),
                    ),
                  ],
                ),
            if (widget.repo.hasForgeRemote)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  AppSpacing.xs,
                  AppSpacing.sm,
                  AppSpacing.sm,
                ),
                child: CcButton(
                  onPressed: () => _createPullRequest(context),
                  icon: AppIcons.gitPullRequestCreate,
                  size: CcButtonSize.sm,
                  variant: CcButtonVariant.line,
                  fullWidth: true,
                  child: Text(l10n.ideSourceControlCreatePr),
                ),
              ),
            Container(height: 1, color: t.borderSecondary),
          ],
        ),
      ],
    );
  }

  /// Confirmation dialog for reverting [paths] to HEAD.
  Future<void> _confirmRevert(List<String> paths) async {
    if (paths.isEmpty) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final confirmed = await showCcDialog<bool>(
      context: context,
      builder: (context) {
        final t = context.designSystem ?? DesignSystemTokens.light();
        return CcDialog(
          title: l10n.ideRevertConfirmTitle,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.ideRevertConfirmMessage(paths.length),
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
                    child: Text(l10n.ideRevertConfirmCancel),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  CcButton(
                    variant: CcButtonVariant.primary,
                    size: CcButtonSize.sm,
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(l10n.ideRevertConfirmAction),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
    if (confirmed == true) {
      widget.onRevertFiles((repoId: widget.repo.id, paths: paths));
    }
  }
}
