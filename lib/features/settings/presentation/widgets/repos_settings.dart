import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/domain/entities/repo.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/repos/presentation/widgets/add_repo_form.dart';
import 'package:control_center/features/repos/presentation/widgets/repo_index_button.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/settings_shortcuts.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/github_user_avatar.dart';
import 'package:control_center/shared/widgets/page_wrapper.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Settings → Repositories: lists, adds, and removes the repositories targeted
/// by the active workspace.
class ReposSettings extends ConsumerWidget {
  /// Creates a new [ReposSettings].
  const ReposSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final workspaceId = ref.watch(activeWorkspaceIdProvider);

    return SettingsShortcuts(
      extraBindings: {
        if (workspaceId != null)
          'settings.repos-add': () => _addRepo(context, ref, workspaceId),
      },
      child: PageWrapper(
      title: l10n.repositories,
      subtitle: l10n.reposDescription,
      actions: [
        if (workspaceId != null)
          CcButton(
            onPressed: () => _addRepo(context, ref, workspaceId),
            icon: LucideIcons.plus,
            child: Text(l10n.addRepository),
          ),
      ],
      child: workspaceId == null
          ? const _NoWorkspaceState()
          : _ReposList(workspaceId: workspaceId),
      ),
    );
  }
}

class _ReposList extends ConsumerWidget {
  const _ReposList({required this.workspaceId});
  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reposAsync = ref.watch(reposForWorkspaceProvider(workspaceId));
    final l10n = AppLocalizations.of(context);

    return reposAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CcSpinner()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          l10n.failedToLoadRepos,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
      data: (repos) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            SectionCard(
              label: l10n.reposCount(repos.length),
              padding: const EdgeInsets.fromLTRB(0, 14, 0, 0),
              headerPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: repos.isEmpty
                  ? const _EmptyState()
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: repos.length,
                      separatorBuilder: (_, _) => const CcDivider(),
                      itemBuilder: (_, i) => _RepoRow(
                        repo: repos[i],
                        workspaceId: workspaceId,
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

Future<void> _addRepo(
  BuildContext context,
  WidgetRef ref,
  String workspaceId,
) async {
  final repoId = await showAddRepoDialog(context);
  if (repoId == null) {
    return;
  }
  await ref
      .read(workspaceRepositoryProvider)
      .linkRepoToWorkspace(workspaceId, repoId);
}

class _RepoRow extends ConsumerWidget {
  const _RepoRow({required this.repo, required this.workspaceId});

  final Repo repo;
  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = context.designSystem;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          if (repo.hasGitHubRemote)
            GitHubUserAvatar(
              login: repo.githubOwner,
              avatarUrl: 'https://github.com/${repo.githubOwner}.png',
              size: 32,
            )
          else
            const CcAvatar(
              size: 32,
              icon: LucideIcons.folder,
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  repo.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: tokens?.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  repo.path,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: tokens?.textTertiary,
                    height: 1.4,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          RepoIndexButton(repo: repo, workspaceId: workspaceId),
          CcButton(
            variant: CcButtonVariant.ghost,
            size: CcButtonSize.sm,
            onPressed: () => _editGitHubLink(context, ref),
            child: Icon(
              LucideIcons.link,
              size: 16,
              color: repo.hasGitHubRemote
                  ? tokens?.textPrimary
                  : tokens?.fgTertiary,
            ),
          ),
          CcButton(
            variant: CcButtonVariant.ghost,
            size: CcButtonSize.sm,
            onPressed: () => _confirmRemove(context, ref),
            child: Icon(
              LucideIcons.trash2,
              size: 16,
              color: tokens?.fgTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRemove(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showCcDialog<bool>(
      context: context,
      builder: (ctx) => CcDialog(
        title: l10n.removeRepoFromWorkspace,
        content: Text(
          l10n.repoRemovedFromWorkspace(repo.name),
        ),
        actions: [
          CcButton(
            onPressed: () => Navigator.pop(ctx, false),
            variant: CcButtonVariant.secondary,
            child: Text(AppLocalizations.of(context).cancel),
          ),
          CcButton(
            onPressed: () => Navigator.pop(ctx, true),
            variant: CcButtonVariant.destructive,
            child: Text(AppLocalizations.of(context).remove),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    await ref
        .read(workspaceRepositoryProvider)
        .unlinkRepoFromWorkspace(workspaceId, repo.id);
    await ref.read(repoRepositoryProvider).delete(repo.id);
  }

  Future<void> _editGitHubLink(BuildContext context, WidgetRef ref) async {
    final result = await showEditGitHubLinkDialog(context, repo: repo);
    if (result == null) {
      return;
    }

    await ref.read(repoRepositoryProvider).upsert(
      repo.copyWith(
        githubOwner: result.$1,
        githubRepoName: result.$2,
        name: result.$1.isNotEmpty && result.$2.isNotEmpty
            ? '${result.$1}/${result.$2}'
            : repo.name,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.designSystem;
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.gitBranch, size: 32, color: tokens?.fgTertiary),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context).noReposInWorkspaceYet,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context).addLocalCheckoutDescription,
              style: theme.textTheme.bodySmall?.copyWith(
                color: tokens?.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _NoWorkspaceState extends StatelessWidget {
  const _NoWorkspaceState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.designSystem;
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.layoutGrid,
              size: 32,
              color: tokens?.fgTertiary,
            ),
            const SizedBox(height: 12),
            Text(l10n.noActiveWorkspaceCreate, style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              l10n.createOrSelectWorkspace,
              style: theme.textTheme.bodySmall?.copyWith(
                color: tokens?.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows a dialog for editing a repository's GitHub owner and name.
Future<(String, String)?> showEditGitHubLinkDialog(
  BuildContext context, {
  required Repo repo,
}) {
  final ownerCtrl = TextEditingController(text: repo.githubOwner);
  final repoNameCtrl = TextEditingController(text: repo.githubRepoName);
  final l10n = AppLocalizations.of(context);

  return showCcDialog<(String, String)?>(
    context: context,
    builder: (dialogContext) => CcDialog(
      title: l10n.githubLink,
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.setGithubLinkDescription(repo.name),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.designSystem?.textTertiary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ownerCtrl,
              decoration: InputDecoration(
                labelText: l10n.ownerOrganization,
                hintText: l10n.egSamuelAlev,
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: repoNameCtrl,
              decoration: InputDecoration(
                labelText: l10n.repositoryName,
                hintText: l10n.egControlCenter,
                isDense: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        CcButton(
          onPressed: () => Navigator.pop(dialogContext),
          variant: CcButtonVariant.ghost,
          child: Text(AppLocalizations.of(context).cancel),
        ),
        CcButton(
          onPressed: () => Navigator.pop(
            dialogContext,
            (ownerCtrl.text.trim(), repoNameCtrl.text.trim()),
          ),
          child: Text(AppLocalizations.of(context).save),
        ),
      ],
    ),
  );
}

