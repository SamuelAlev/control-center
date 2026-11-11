import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/auth/presentation/widgets/sign_in_prompts.dart';
import 'package:control_center/features/auth/providers/oauth_providers.dart'
    show SignInNeed;
import 'package:control_center/features/pr_review/providers/pr_list_providers.dart'
    show repoAccessForWorkspaceProvider;
import 'package:control_center/features/repos/presentation/settings/repo_remove.dart';
import 'package:control_center/features/repos/presentation/widgets/edit_github_link_dialog.dart';
import 'package:control_center/features/repos/presentation/widgets/repo_access_warnings_dialog.dart';
import 'package:control_center/features/repos/presentation/widgets/repo_index_button.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_hover_reveal.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_scope.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/github_user_avatar.dart';
import 'package:control_center/shared/widgets/workspace_avatar.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One repository row in Settings → Repositories: the repo, its forge and
/// access badges, its index control, and hover-revealed link and remove
/// actions. Tapping the row edits its forge link.
class RepoSettingsRow extends ConsumerWidget {
  /// Creates a [RepoSettingsRow].
  const RepoSettingsRow({
    required this.repo,
    required this.workspaceId,
    this.dragIndex,
    super.key,
  });

  /// The repository this row shows.
  final Repo repo;

  /// The workspace the repository is linked to.
  final String workspaceId;

  /// This row's index in the reorderable list; when non-null a leading drag
  /// handle appears that starts a reorder for this row.
  final int? dragIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final access =
        ref.watch(repoAccessForWorkspaceProvider(workspaceId)).value ??
        const [];
    final noAccess = access.any(
      (i) =>
          i.state.blocksAutomation &&
          (i.repoId == repo.id ||
              (i.forge == repo.forge &&
                  i.owner.toLowerCase() == repo.remoteOwner.toLowerCase() &&
                  i.name.toLowerCase() == repo.remoteName.toLowerCase())),
    );
    final demo = ref.watch(isDemoServerProvider);
    final workspace = demo ? ref.watch(activeWorkspaceDisplayProvider) : null;

    // The whole row edits the link. Demo rows are a fixture, so they neither
    // open it nor report hover, and their disabled actions stay in view to
    // carry the reason in a tooltip.
    return CcTappable(
      onPressed: demo ? null : () => _editGitHubLink(context, ref),
      semanticLabel: repo.name,
      semanticButton: !demo,
      builder: (context, states) {
        final active =
            demo ||
            states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused);
        return AnimatedContainer(
          duration: CcMotion.fast,
          color: states.contains(WidgetState.hovered)
              ? tokens.hover
              : const Color(0x00000000),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              if (dragIndex != null) ...[
                ReorderableDragStartListener(
                  index: dragIndex!,
                  // Claims the tap, so a click on the handle that never
                  // becomes a drag does not fall through and open the row.
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {},
                    child: MouseRegion(
                      cursor: SystemMouseCursors.grab,
                      child: Icon(
                        AppIcons.gripVertical,
                        size: 16,
                        color: tokens.fgTertiary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              // The demo org is named `helix`, which is also a real GitHub account.
              // `github.com/helix.png` is that person's photo, so the demo shows
              // the workspace mark (the Helix logo) instead of fetching it.
              if (demo && repo.hasForgeRemote)
                WorkspaceAvatar(
                  name: workspace?.name ?? repo.remoteOwner,
                  workspaceId: workspace?.workspaceId ?? workspaceId,
                  hasLogo: workspace?.hasLogo ?? false,
                  size: 32,
                )
              // `github.com/<owner>.png` is a GitHub-only convention; the other
              // forges have no equivalent guessable owner avatar, so they fall back
              // to initials rather than requesting a URL that 404s.
              else if (repo.hasForgeRemote)
                GitHubUserAvatar(
                  login: repo.remoteOwner,
                  avatarUrl: repo.forge == ForgeHost.github
                      ? 'https://github.com/${repo.remoteOwner}.png'
                      : '',
                  size: 32,
                )
              else
                const CcAvatar(size: 32, icon: AppIcons.folder),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            repo.name,
                            style: CcTypography.body.copyWith(
                              fontWeight: FontWeight.w600,
                              color: tokens.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Which forge this repo lives on. A workspace may mix
                        // them, and the name alone cannot say — two repos can be
                        // `acme/web` on different forges and behave differently
                        // (what a review can do, where a link goes).
                        if (repo.hasForgeRemote) ...[
                          const SizedBox(width: 8),
                          CcBadge(label: repo.forge.displayName),
                        ],
                        // The server's credential cannot see this repo (see the
                        // banner above the list for the fix).
                        if (noAccess) ...[
                          const SizedBox(width: 8),
                          CcBadge(
                            label: l10n.repoNoAccessBadge,
                            variant: CcBadgeVariant.warning,
                            icon: AppIcons.lock,
                          ),
                        ],
                      ],
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
              RepoIndexButton(
                repo: repo,
                workspaceId: workspaceId,
                rowActive: active,
              ),
              const SizedBox(width: AppSpacing.xs),
              SettingsHoverReveal(
                active: active,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: AppSpacing.xs,
                  children: [
                    CcIconButton(
                      icon: AppIcons.link,
                      color: tokens.fgTertiary,
                      size: CcButtonSize.sm,
                      tooltip: demo
                          ? l10n.demoUnavailableRepos
                          : l10n.githubLink,
                      semanticLabel: l10n.githubLink,
                      // demo: the repository list is a fixture — read-only.
                      onPressed: demo
                          ? null
                          : () => _editGitHubLink(context, ref),
                    ),
                    CcIconButton(
                      icon: AppIcons.trash2,
                      variant: CcButtonVariant.destructive,
                      size: CcButtonSize.sm,
                      tooltip: demo ? l10n.demoUnavailableRepos : l10n.remove,
                      semanticLabel: l10n.remove,
                      // demo: the repository list is a fixture — read-only.
                      onPressed: demo
                          ? null
                          : () => confirmRemoveRepo(
                              context,
                              ref,
                              repo: repo,
                              workspaceId: workspaceId,
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editGitHubLink(BuildContext context, WidgetRef ref) async {
    final result = await showEditGitHubLinkDialog(context, repo: repo);
    if (result == null) {
      return;
    }

    final workspaceId = ref.requireWorkspaceId();
    try {
      final linked = await ref.read(linkRepoProvider)(
        workspaceId,
        repo.copyWith(
          remoteOwner: result.$1,
          remoteName: result.$2,
          name: result.$1.isNotEmpty && result.$2.isNotEmpty
              ? '${result.$1}/${result.$2}'
              : repo.name,
        ),
      );
      if (context.mounted) {
        await showRepoAccessWarnings(context, linked.issues);
      }
    } on Object catch (e) {
      if (!context.mounted ||
          offerSignInForRefusal(
            context,
            e,
            fallback: SignInNeed.forForge(repo.forge),
            workspaceId: workspaceId,
          )) {
        return;
      }
      final l10n = AppLocalizations.of(context);
      CcToastScope.maybeOf(context)?.show(
        l10n.failedWithError(describeRepoLinkError(l10n, e)),
        variant: CcToastVariant.danger,
      );
    }
  }
}
