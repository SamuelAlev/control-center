import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_provisioning_status.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/messaging/presentation/ide/panels/pull_requests_section.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/messaging/providers/repo_changes_provider.dart';
import 'package:control_center/features/messaging/providers/space_stack_provider.dart';
import 'package:control_center/features/messaging/providers/space_worktrees_provider.dart';
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

/// The space's PR inventory and repository-scoped creation actions.
class ScmPullRequestsSection extends ConsumerStatefulWidget {
  /// Creates the top section of the Source Control sidebar.
  const ScmPullRequestsSection({
    super.key,
    required this.workspaceId,
    required this.spaceId,
  });

  /// Workspace owning the space and its repositories.
  final String workspaceId;

  /// Space whose linked PRs and checked-out branches are shown.
  final String spaceId;

  @override
  ConsumerState<ScmPullRequestsSection> createState() =>
      _ScmPullRequestsSectionState();
}

class _ScmPullRequestsSectionState
    extends ConsumerState<ScmPullRequestsSection> {
  final _menu = CcOverlayController();
  bool _busy = false;

  @override
  void dispose() {
    _menu.dispose();
    super.dispose();
  }

  Future<void> _createPullRequest(Repo repo) async {
    await ref.read(activeRepoIdProvider.notifier).setActive(repo.id);
    if (!mounted) {
      return;
    }
    // Compose from this space's isolated branch, including local-only commits.
    context.go(
      pullRequestsComposeRoute(widget.workspaceId, spaceId: widget.spaceId),
    );
  }

  Future<void> _publishStack(Repo repo) async {
    setState(() => _busy = true);
    final l10n = AppLocalizations.of(context);
    final result = await publishStack(
      ref.read(rpcClientProvider),
      workspaceId: widget.workspaceId,
      spaceId: widget.spaceId,
      repoId: repo.id,
    );
    if (!mounted) {
      return;
    }
    ref.invalidate(spaceStackProvider(widget.spaceId));
    setState(() => _busy = false);
    CcToastScope.maybeOf(context)?.show(
      result.ok
          ? l10n.stackPublished
          : result.dirty
          ? l10n.stackSwitchDirty
          : l10n.stackPublishFailed,
      variant: result.ok ? CcToastVariant.success : CcToastVariant.danger,
    );
  }

  @override
  Widget build(BuildContext context) {
    final prs = ref.watch(spacePullRequestsProvider(widget.spaceId));
    final l10n = AppLocalizations.of(context);
    final items = <CcMenuItem>[];
    final status = ref.watch(spaceProvisioningStatusProvider(widget.spaceId));
    if (status != SpaceProvisioningStatus.provisioning) {
      final repos = ref
          .watch(reposForWorkspaceProvider(widget.workspaceId))
          .value;
      final worktrees = ref
          .watch(
            spaceWorktreesProvider((
              workspaceId: widget.workspaceId,
              spaceId: widget.spaceId,
            )),
          )
          .value;
      final layers = ref.watch(spaceStackProvider(widget.spaceId)).value;
      if (repos != null && worktrees != null && layers != null) {
        final branchByRepo = {for (final w in worktrees) w.repoId: w.branch};
        for (final repo in repos) {
          final branch = branchByRepo[repo.id];
          if (branch == null || !repo.hasForgeRemote) {
            continue;
          }
          final repoLayers = [
            for (final layer in layers)
              if (layer.repoId == repo.id) layer,
          ];
          CcMenuItem? action;
          if (repoLayers.length >= 2) {
            final publishedBranches = {
              for (final pr in prs)
                if (pr.repoFullName == repo.fullName) pr.headRef,
              for (final layer in repoLayers)
                if (layer.prNumber != null) layer.branch,
            };
            // Recorded numbers cover freshly published PRs before snapshots
            // arrive. An incomplete lookup is not proof a part is unpublished.
            final complete =
                ref
                    .watch(spaceBranchPullRequestsProvider(widget.spaceId))
                    .value
                    ?.complete ==
                true;
            if (complete &&
                repoLayers.any(
                  (layer) => !publishedBranches.contains(layer.branch),
                )) {
              action = CcMenuItem(
                label: l10n.stackPublish,
                icon: AppIcons.layers,
                onSelected: () => _publishStack(repo),
              );
            }
          } else {
            final existingPr = ref.watch(
              spaceBranchPullRequestForRepoProvider((
                spaceId: widget.spaceId,
                repoId: repo.id,
                repoFullName: repo.fullName,
                branch: branch,
              )),
            );
            final changes = ref
                .watch(
                  repoChangesGroupedProvider((
                    workspaceId: widget.workspaceId,
                    spaceId: widget.spaceId,
                    repoId: repo.id,
                  )),
                )
                .value;
            if (existingPr == null &&
                changes != null &&
                scmCanOpenPullRequest(
                  hasForgeRemote: repo.hasForgeRemote,
                  hasExistingPr: false,
                  dirtyFiles: changes.staged.length + changes.unstaged.length,
                  statusKnown: changes.statusKnown,
                  hasUpstream: changes.hasUpstream,
                  ahead: changes.ahead,
                  aheadOfBase: changes.aheadOfBase,
                  aheadOfBaseKnown: changes.aheadOfBaseKnown,
                  branch: branch,
                )) {
              action = CcMenuItem(
                label: l10n.ideSourceControlCreatePr,
                icon: AppIcons.gitPullRequestCreate,
                onSelected: () => _createPullRequest(repo),
              );
            }
          }
          if (action != null) {
            items.add(CcMenuItem.section(repo.fullName));
            items.add(action);
          }
        }
      }
    }
    return PullRequestsSection(
      pullRequests: prs,
      onOpen: (pr) => context.push(
        pullRequestDetailRoute(widget.workspaceId, pr.repoFullName, pr.number),
      ),
      trailing: items.isEmpty
          ? null
          : CcMenu(
              controller: _menu,
              toggleOnTargetTap: false,
              maxWidth: 440,
              target: ScmIconAction(
                action: (
                  icon: AppIcons.plus,
                  tooltip: l10n.createPullRequest,
                  onPressed: _busy ? null : _menu.toggle,
                ),
              ),
              items: items,
            ),
    );
  }
}
