import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_ui/cc_ui.dart' show CcToastScope, CcToastVariant;
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/repos/presentation/repo_link_workspace_dialog.dart';
import 'package:control_center/features/repos/presentation/unlinked_repo_dialog.dart';
import 'package:control_center/features/repos/presentation/widgets/show_add_repo_dialog.dart';
import 'package:control_center/features/repos/providers/repo_link_workspace_choices.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/workspaces/presentation/widgets/show_add_workspace_dialog.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where a repo-addressed deep link lands: the workspace (null to fall back to
/// the active one) and the repo when that workspace links it. `dismissed`
/// means the user backed out of a dialog, and the link does nothing.
typedef RepoLinkTarget = ({
  String? workspaceId,
  String? repoFullName,
  bool dismissed,
});

/// Whether [r] is the `<owner>/<repo>` checkout a deep link names.
bool _isLinkedRepo(Repo r, {required String owner, required String repo}) =>
    r.remoteOwner.toLowerCase() == owner.toLowerCase() &&
    r.remoteName.toLowerCase() == repo.toLowerCase();

/// Resolves the workspace and repo holding the `<owner>/<repo>` checkout a
/// repo-addressed deep link names, and picks that repo for the workspace.
///
/// The caller navigates into the returned workspace: the route makes it
/// active. The repo is chosen before that so the target screen's first frame
/// already has the right repo context rather than fetching the previously
/// active repo's data. When no workspace links the repo, [offerToLink] asks
/// the user where to add it first.
Future<RepoLinkTarget> activateLinkedRepo(
  ProviderContainer container, {
  required String owner,
  required String repo,
  bool offerToLink = true,
}) async {
  final repoRepo = container.read(repoRepositoryProvider);
  final wsRepo = container.read(workspaceRepositoryProvider);

  // Repos live inside a workspace, and one checkout can be linked into
  // several, so collect every workspace holding it in the operator's order.
  final holders = <(Workspace, Repo)>[];
  for (final ws in await wsRepo.getAll()) {
    final target = (await repoRepo.getAll(
      ws.id,
    )).where((r) => _isLinkedRepo(r, owner: owner, repo: repo)).firstOrNull;
    if (target != null) {
      holders.add((ws, target));
    }
  }
  if (holders.isEmpty) {
    final context = rootNavigatorKey.currentContext;
    if (!offerToLink || context == null || !context.mounted) {
      // Nothing to offer, or no window to ask in (the link arrived before the
      // app finished mounting): fall back to the active workspace.
      return (workspaceId: null, repoFullName: null, dismissed: false);
    }
    final workspaceId = await _linkUnlinkedRepo(
      container,
      context,
      owner: owner,
      repo: repo,
    );
    if (workspaceId == null) {
      return (workspaceId: null, repoFullName: null, dismissed: true);
    }
    final linked = await activateLinkedRepo(
      container,
      owner: owner,
      repo: repo,
      offerToLink: false,
    );
    if (linked.repoFullName != null) {
      return linked;
    }
    // The user put no checkout of this repo in the workspace they chose: land
    // there without it rather than back where the link found them.
    return (workspaceId: workspaceId, repoFullName: null, dismissed: false);
  }

  final workspaceId = await _chooseLinkWorkspace(
    container,
    repoFullName: holders.first.$2.fullName,
    workspaces: [for (final (ws, _) in holders) ws],
  );
  if (workspaceId == null) {
    return (workspaceId: null, repoFullName: null, dismissed: true);
  }
  final (_, target) = holders.firstWhere((h) => h.$1.id == workspaceId);
  await container
      .read(activeRepoIdProvider.notifier)
      .setActiveFor(workspaceId, target.id);
  return (
    workspaceId: workspaceId,
    repoFullName: target.fullName,
    dismissed: false,
  );
}

/// Asks what a link to `<owner>/<repo>`, which no workspace links, should do:
/// add its checkout to the active workspace, create a workspace and add it
/// there, or nothing.
///
/// Resolves to the workspace the user chose, even when the checkout they
/// picked turned out to be another repo or they backed out of picking one
/// after creating the workspace. Null when they backed out otherwise.
Future<String?> _linkUnlinkedRepo(
  ProviderContainer container,
  BuildContext context, {
  required String owner,
  required String repo,
}) async {
  final repoFullName = '$owner/$repo';
  final activeId = container.read(activeWorkspaceIdProvider);
  final active = activeId == null
      ? null
      : await container
            .read(workspaceRepositoryProvider)
            .getAll()
            .then((all) => all.where((w) => w.id == activeId).firstOrNull)
            // A repository that cannot answer still leaves creating one.
            .onError((_, _) => null);
  if (!context.mounted) {
    return null;
  }
  final action = await showUnlinkedRepoDialog(
    context: context,
    repoFullName: repoFullName,
    currentWorkspace: active,
  );
  if (action == null || !context.mounted) {
    return null;
  }
  final workspaceId = switch (action) {
    UnlinkedRepoAction.addToCurrentWorkspace => active?.id,
    UnlinkedRepoAction.createWorkspace => await showAddWorkspaceDialog(
      context,
      initialName: repo,
    ),
  };
  if (workspaceId == null || !context.mounted) {
    return null;
  }
  final created = action == UnlinkedRepoAction.createWorkspace;
  final l10n = AppLocalizations.of(context);
  final outcome = await showAddRepoDialog(
    context,
    browser: container.read(directoryBrowserProvider),
    register: container.read(addRepoFromServerPathProvider),
    workspaceId: workspaceId,
    intro: l10n.repoLinkChooseCheckout(repoFullName),
  );
  if (outcome == null) {
    // Backing out of the checkout still leaves a workspace just created to
    // land in; backing out of adding to the current one leaves nothing.
    return created ? workspaceId : null;
  }
  if (!context.mounted) {
    return workspaceId;
  }
  final toasts = CcToastScope.maybeOf(context);
  if (outcome.failed.isNotEmpty) {
    final first = outcome.failed.entries.first;
    toasts?.show(
      l10n.repositoriesAddFailed(
        outcome.failed.length,
        '${first.key}: ${first.value}',
      ),
      variant: CcToastVariant.danger,
    );
  }
  if (outcome.added.isNotEmpty) {
    final repos = await container
        .read(repoRepositoryProvider)
        .getAll(workspaceId)
        .onError((_, _) => const <Repo>[]);
    final addedIt = repos.any(
      (r) =>
          outcome.added.contains(r.id) &&
          _isLinkedRepo(r, owner: owner, repo: repo),
    );
    toasts?.show(
      addedIt
          ? l10n.repositoriesAdded(outcome.added.length)
          : l10n.repoLinkCheckoutMismatch(repoFullName),
      variant: addedIt ? CcToastVariant.success : CcToastVariant.warning,
    );
  }
  return workspaceId;
}

/// Picks which of [workspaces] (every one linking [repoFullName], in the
/// operator's order) a link opens in: the only one, the remembered one, or the
/// user's answer to the chooser. Null when the user dismissed the chooser.
Future<String?> _chooseLinkWorkspace(
  ProviderContainer container, {
  required String repoFullName,
  required List<Workspace> workspaces,
}) async {
  final candidates = [for (final ws in workspaces) ws.id];
  final settled = repoLinkWorkspaceWithoutAsking(
    candidates: candidates,
    remembered: container
        .read(repoLinkWorkspaceChoicesProvider)
        .workspaceFor(repoFullName),
  );
  if (settled != null) {
    return settled;
  }
  final context = rootNavigatorKey.currentContext;
  if (context == null) {
    // No window to ask in (the link arrived before the app finished
    // mounting): fall back to the operator's workspace order.
    return candidates.first;
  }
  final active = container.read(activeWorkspaceIdProvider);
  final decision = await showRepoLinkWorkspaceDialog(
    context: context,
    repoFullName: repoFullName,
    workspaces: workspaces,
    initialWorkspaceId: candidates.contains(active)
        ? active!
        : candidates.first,
  );
  if (decision == null) {
    return null;
  }
  if (decision.remember) {
    await container
        .read(repoLinkWorkspaceChoicesProvider.notifier)
        .remember(repoFullName, decision.workspaceId);
  }
  return decision.workspaceId;
}
