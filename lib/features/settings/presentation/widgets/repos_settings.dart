import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/repos/presentation/widgets/add_repo_dialog.dart';
import 'package:control_center/features/repos/presentation/widgets/repo_index_button.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/settings_shortcuts.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_scope.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/github_user_avatar.dart';
import 'package:control_center/shared/widgets/page_wrapper.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings → Repositories: lists, adds, and removes the repositories targeted
/// by the active workspace.
class ReposSettings extends ConsumerWidget {
  /// Creates a new [ReposSettings].
  const ReposSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // Route-driven provider (kept in sync with the URL's `:workspaceId` by
    // `workspaceUrlSyncProvider`). Reading the provider instead of
    // `GoRouterState.of` keeps this null-safe outside a router and consistent
    // with the sibling settings panes (agents/skills).
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
              size: CcButtonSize.sm,
              icon: AppIcons.plus,
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
                  : _ReorderableRepoList(
                      workspaceId: workspaceId,
                      repos: repos,
                    ),
            ),
          ],
        );
      },
    );
  }
}

/// The drag-to-reorder repo list. Reordering persists the new sequence via
/// `WorkspaceRepository.setReposForWorkspace` (which writes each link's
/// position by index), and that order is what every repo list in the app reads
/// back. A local optimistic copy keeps the drag smooth; it re-syncs whenever
/// the provider emits a different set/order (e.g. a repo added or removed).
class _ReorderableRepoList extends ConsumerStatefulWidget {
  const _ReorderableRepoList({required this.workspaceId, required this.repos});

  final String workspaceId;
  final List<Repo> repos;

  @override
  ConsumerState<_ReorderableRepoList> createState() =>
      _ReorderableRepoListState();
}

class _ReorderableRepoListState extends ConsumerState<_ReorderableRepoList> {
  late List<Repo> _repos = List.of(widget.repos);

  @override
  void didUpdateWidget(_ReorderableRepoList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Adopt the server-confirmed order (also covers a repo added/removed
    // elsewhere). After a local reorder the provider re-emits the same order,
    // so this is a no-op then.
    if (!_sameOrder(widget.repos, _repos)) {
      _repos = List.of(widget.repos);
    }
  }

  bool _sameOrder(List<Repo> a, List<Repo> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) {
        return false;
      }
    }
    return true;
  }

  // Uses [ReorderableListView]'s `onReorderItem`, whose [newIndex] is already
  // adjusted for the item removed at [oldIndex] — so no `newIndex -= 1` dance.
  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      final moved = _repos.removeAt(oldIndex);
      _repos.insert(newIndex, moved);
    });
    ref.read(workspaceRepositoryProvider).setReposForWorkspace(
      widget.workspaceId,
      [for (final r in _repos) r.id],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: _repos.length,
      onReorderItem: _onReorder,
      itemBuilder: (context, i) => Column(
        key: ValueKey(_repos[i].id),
        mainAxisSize: MainAxisSize.min,
        children: [
          if (i > 0) const CcDivider(),
          _RepoRow(
            repo: _repos[i],
            workspaceId: widget.workspaceId,
            dragIndex: i,
          ),
        ],
      ),
    );
  }
}

Future<void> _addRepo(
  BuildContext context,
  WidgetRef ref,
  String workspaceId,
) async {
  // One dialog on every platform: it browses the SERVER's filesystem (the
  // desktop is a thin client — the checkout lives wherever cc_server runs),
  // registers the selected checkouts directly into this workspace, and
  // returns the batch outcome to report here.
  final outcome = await addRepos(context, ref, workspaceId);
  if (outcome == null || !context.mounted) {
    return;
  }
  final toasts = CcToastScope.maybeOf(context);
  if (toasts == null) {
    return;
  }
  final l10n = AppLocalizations.of(context);
  if (outcome.added.isNotEmpty) {
    toasts.show(
      l10n.repositoriesAdded(outcome.added.length),
      variant: CcToastVariant.success,
    );
  }
  if (outcome.failed.isNotEmpty) {
    final first = outcome.failed.entries.first;
    toasts.show(
      l10n.repositoriesAddFailed(
        outcome.failed.length,
        '${first.key}: ${first.value}',
      ),
      variant: CcToastVariant.danger,
    );
  }
}

class _RepoRow extends ConsumerWidget {
  const _RepoRow({
    required this.repo,
    required this.workspaceId,
    this.dragIndex,
  });

  final Repo repo;
  final String workspaceId;

  /// This row's index in the reorderable list; when non-null a leading drag
  /// handle appears that starts a reorder for this row.
  final int? dragIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          if (dragIndex != null) ...[
            ReorderableDragStartListener(
              index: dragIndex!,
              child: MouseRegion(
                cursor: SystemMouseCursors.grab,
                child: Icon(
                  AppIcons.gripVertical,
                  size: 16,
                  color: tokens.fgTertiary,
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          if (repo.hasGitHubRemote)
            GitHubUserAvatar(
              login: repo.githubOwner,
              avatarUrl: 'https://github.com/${repo.githubOwner}.png',
              size: 32,
            )
          else
            const CcAvatar(size: 32, icon: AppIcons.folder),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  repo.name,
                  style: CcTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  repo.path,
                  style: CcTypography.caption.copyWith(
                    color: tokens.textTertiary,
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
              AppIcons.link,
              size: 16,
              color: repo.hasGitHubRemote
                  ? tokens.textPrimary
                  : tokens.fgTertiary,
            ),
          ),
          CcButton(
            variant: CcButtonVariant.ghost,
            size: CcButtonSize.sm,
            onPressed: () => _confirmRemove(context, ref),
            child: Icon(AppIcons.trash2, size: 16, color: tokens.fgTertiary),
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
        content: Text(l10n.repoRemovedFromWorkspace(repo.name)),
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
    await ref
        .read(repoRepositoryProvider)
        .delete(workspaceId, repo.id);
  }

  Future<void> _editGitHubLink(BuildContext context, WidgetRef ref) async {
    final result = await showEditGitHubLinkDialog(context, repo: repo);
    if (result == null) {
      return;
    }

    await ref
        .read(repoRepositoryProvider)
        .upsert(
          ref.requireWorkspaceId(),
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
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.gitBranch, size: 32, color: tokens.fgTertiary),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context).noReposInWorkspaceYet,
              style: CcTypography.body.copyWith(color: tokens.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context).addLocalCheckoutDescription,
              style: CcTypography.caption.copyWith(color: tokens.textTertiary),
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
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.layoutGrid, size: 32, color: tokens.fgTertiary),
            const SizedBox(height: 12),
            Text(
              l10n.noActiveWorkspaceCreate,
              style: CcTypography.body.copyWith(color: tokens.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.createOrSelectWorkspace,
              style: CcTypography.caption.copyWith(color: tokens.textTertiary),
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
              style: CcTypography.caption.copyWith(
                color: context.designSystem?.textTertiary,
              ),
            ),
            const SizedBox(height: 16),
            CcTextField(
              controller: ownerCtrl,
              label: l10n.ownerOrganization,
              hintText: l10n.egSamuelAlev,
            ),
            const SizedBox(height: 12),
            CcTextField(
              controller: repoNameCtrl,
              label: l10n.repositoryName,
              hintText: l10n.egControlCenter,
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
          onPressed: () => Navigator.pop(dialogContext, (
            ownerCtrl.text.trim(),
            repoNameCtrl.text.trim(),
          )),
          child: Text(AppLocalizations.of(context).save),
        ),
      ],
    ),
  );
}
