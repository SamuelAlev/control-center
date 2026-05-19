import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/providers/repo_changes_provider.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Source Control panel: the working-tree changes for each linked repo, with a
/// per-repo "Create pull request" action.
///
/// For each repo it watches [repoChangesProvider] (server-side
/// `git diff HEAD` + untracked). Clicking a changed file opens its working-tree
/// diff in the editor; "Create pull request" activates the repo and navigates
/// to the tested compose-PR flow.
class SourceControlPanel extends ConsumerWidget {
  /// Creates a [SourceControlPanel].
  const SourceControlPanel({
    super.key,
    required this.workspaceId,
    required this.onOpenFileDiff,
  });

  /// The workspace whose linked repos the changes are scoped to.
  final String workspaceId;

  /// Called with `(repoId, file)` when a changed file is opened.
  final ValueChanged<({String repoId, PrFile file})> onOpenFileDiff;

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
            repo: repos[i],
            onOpenFileDiff: onOpenFileDiff,
          ),
        );
      },
    );
  }
}

class _RepoChangesSection extends ConsumerStatefulWidget {
  const _RepoChangesSection({
    required this.workspaceId,
    required this.repo,
    required this.onOpenFileDiff,
  });

  final String workspaceId;
  final Repo repo;
  final ValueChanged<({String repoId, PrFile file})> onOpenFileDiff;

  @override
  ConsumerState<_RepoChangesSection> createState() =>
      _RepoChangesSectionState();
}

class _RepoChangesSectionState extends ConsumerState<_RepoChangesSection> {
  bool _collapsed = false;

  ({String workspaceId, String repoId}) get _args => (
        workspaceId: widget.workspaceId,
        repoId: widget.repo.id,
      );

  Future<void> _createPullRequest(BuildContext context) async {
    await ref.read(activeRepoIdProvider.notifier).setActive(widget.repo.id);
    if (!context.mounted) {
      return;
    }
    context.go(pullRequestsComposeRoute(widget.workspaceId));
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
        _SectionHeader(
          repo: widget.repo,
          count: files.length,
          countLabel: files.isEmpty ? null : l10n.ideSourceControlChangedFiles(files.length),
          collapsed: _collapsed,
          canRefresh: !loading,
          onToggle: () => setState(() => _collapsed = !_collapsed),
          onRefresh: () => ref.invalidate(repoChangesProvider(_args)),
        ),
        if (!_collapsed) ...[
          if (loading)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Center(child: CcSpinner(size: 14)),
            )
          else if (files.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: Text(
                l10n.ideSourceControlNoChanges,
                style: TextStyle(fontSize: 12, color: t.textTertiary),
              ),
            )
          else
            for (final file in files)
              _ChangedFileRow(
                file: file,
                onTap: () => widget.onOpenFileDiff(
                  (repoId: widget.repo.id, file: file),
                ),
              ),
          if (widget.repo.hasGitHubRemote)
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
          Divider(height: 1, thickness: 1, color: t.borderSecondary),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.repo,
    required this.count,
    required this.countLabel,
    required this.collapsed,
    required this.canRefresh,
    required this.onToggle,
    required this.onRefresh,
  });

  final Repo repo;
  final int count;
  final String? countLabel;
  final bool collapsed;
  final bool canRefresh;
  final VoidCallback onToggle;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);

    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 6,
        ),
        child: Row(
          children: [
            Icon(
              collapsed ? AppIcons.chevronRight : AppIcons.chevronDown,
              size: 14,
              color: t.textTertiary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(AppIcons.folderGit, size: 14, color: t.textSecondary),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                repo.fullName,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: t.textPrimary,
                ),
              ),
            ),
            if (countLabel != null) ...[
              const SizedBox(width: AppSpacing.xs),
              _CountBadge(label: countLabel!),
            ],
            const SizedBox(width: AppSpacing.xs),
            CcIconButton(
              icon: AppIcons.refreshCw,
              size: CcButtonSize.sm,
              tooltip: l10n.ideSourceControlChangedFiles(count),
              onPressed: canRefresh ? onRefresh : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: t.hoverStrong,
        borderRadius: AppRadii.brSm,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: t.textSecondary,
        ),
      ),
    );
  }
}

class _ChangedFileRow extends StatelessWidget {
  const _ChangedFileRow({required this.file, required this.onTap});

  final PrFile file;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final (letter, color) = _statusGlyph(file.status, t);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 4,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 14,
              child: Text(
                letter,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                file.filename,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(fontSize: 12, color: t.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static (String, Color) _statusGlyph(
    PrFileStatus status,
    DesignSystemTokens t,
  ) {
    return switch (status) {
      PrFileStatus.added => ('A', t.success),
      PrFileStatus.modified => ('M', t.accent),
      PrFileStatus.removed => ('D', t.danger),
      PrFileStatus.renamed => ('R', t.textSecondary),
      PrFileStatus.unchanged => (' ', t.textTertiary),
    };
  }
}
