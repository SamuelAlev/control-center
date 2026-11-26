import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/forge/presentation/widgets/repo_access_banner.dart';
import 'package:control_center/features/forge/presentation/widgets/repo_automation_tokens_card.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_list_providers.dart'
    show repoAccessForWorkspaceProvider;
import 'package:control_center/features/repos/presentation/settings/repo_path_issue_notice.dart';
import 'package:control_center/features/repos/presentation/settings/repo_settings_row.dart';
import 'package:control_center/features/repos/presentation/settings/repos_empty_states.dart';
import 'package:control_center/features/repos/presentation/widgets/show_add_repo_dialog.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/settings/settings_shortcuts.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/page_wrapper.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Settings → Repositories: lists, adds and removes the repositories targeted
/// by the active workspace.
class ReposSettingsView extends ConsumerWidget {
  /// Creates a new [ReposSettingsView].
  const ReposSettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // Route-driven provider (kept in sync with the URL's `:workspaceId` by
    // `workspaceUrlSyncProvider`). Reading the provider instead of
    // `GoRouterState.of` keeps this null-safe outside a router and consistent
    // with the sibling settings panes (agents/skills).
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    // Adding a repository browses the server's folders, which only the
    // server owner may do (`can_use_host`): nobody else is offered it.
    final canAdd = ref.watch(canUseHostProvider);

    return SettingsShortcuts(
      extraBindings: {
        if (workspaceId != null && canAdd && !ref.read(isDemoServerProvider))
          'settings.repos-add': () =>
              addReposAndReport(context, ref, workspaceId),
      },
      child: PageWrapper(
        title: l10n.repositories,
        subtitle: l10n.reposDescription,
        actions: [
          if (workspaceId != null && canAdd)
            Builder(
              builder: (context) {
                final isDemo = ref.watch(isDemoServerProvider);
                return CcTooltip(
                  message: isDemo ? l10n.demoUnavailableRepos : '',
                  child: CcButton(
                    // demo: the repository list is a fixture — read-only.
                    onPressed: isDemo
                        ? null
                        : () => addReposAndReport(context, ref, workspaceId),
                    size: CcButtonSize.sm,
                    icon: AppIcons.plus,
                    child: Text(l10n.addRepository),
                  ),
                );
              },
            ),
        ],
        child: workspaceId == null
            ? const ReposNoWorkspaceState()
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
        // Repos automation cannot reach (typically the GitHub App not
        // installed on the repo's owner). The fix is an action on the forge,
        // so it surfaces here — where repos are managed — not just on the PR
        // list.
        final access =
            ref.watch(repoAccessForWorkspaceProvider(workspaceId)).value ??
            const [];
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            RepoAccessBanner(issues: access),
            RepoPathConfirmAllBar(workspaceId: workspaceId, repos: repos),
            SectionCard(
              label: l10n.reposCount(repos.length),
              padding: const EdgeInsets.only(top: AppSpacing.md),
              headerPadding: const EdgeInsets.symmetric(horizontal: 16),
              child: repos.isEmpty
                  ? ReposEmptyState(canAdd: ref.watch(canUseHostProvider))
                  : _ReorderableRepoList(
                      workspaceId: workspaceId,
                      repos: repos,
                    ),
            ),
            RepoAutomationTokensCard(workspaceId: workspaceId, repos: repos),
          ],
        );
      },
    );
  }
}

/// The drag-to-reorder repo list. Reordering persists the new sequence via
/// `WorkspaceRepository.setReposForWorkspace` (which writes each link's
/// position by index) and that order is what every repo list in the app reads
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

  /// Alt+↑/↓ on a focused row: the keyboard's drag, one place at a time. The
  /// row keeps its key, so focus moves with it.
  void _move(int index, int delta) {
    final to = index + delta;
    if (to >= 0 && to < _repos.length) {
      _onReorder(index, to);
    }
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
          CallbackShortcuts(
            bindings: {
              const SingleActivator(
                LogicalKeyboardKey.arrowUp,
                alt: true,
              ): () =>
                  _move(i, -1),
              const SingleActivator(
                LogicalKeyboardKey.arrowDown,
                alt: true,
              ): () =>
                  _move(i, 1),
            },
            child: RepoSettingsRow(
              repo: _repos[i],
              workspaceId: widget.workspaceId,
              dragIndex: i,
            ),
          ),
          RepoPathIssueNotice(repo: _repos[i], workspaceId: widget.workspaceId),
        ],
      ),
    );
  }
}
