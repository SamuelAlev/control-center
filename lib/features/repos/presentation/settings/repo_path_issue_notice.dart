import 'dart:async';

import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/value_objects/repo_path_issue.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/auth/presentation/widgets/sign_in_prompts.dart';
import 'package:control_center/features/auth/providers/oauth_providers.dart'
    show SignInNeed;
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/repos/presentation/settings/repo_remove.dart';
import 'package:control_center/features/repos/presentation/widgets/repo_access_warnings_dialog.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Confirmations of repositories whose folder is outside the workspace's
/// storage, in flight or refused, for one workspace.
typedef RepoPathConfirmState = ({Set<String> busy, Map<String, String> failed});

/// Runs "Confirm" for one repository or all of them, and remembers what is in
/// flight and what the server refused, so each row shows its own outcome.
///
/// Confirming re-saves the same link through `repos.upsert`: the server runs
/// the full link checks as the person confirming and records them as its
/// linker. The notice itself clears when the repository watch re-sends the
/// repository without its issue.
class RepoPathConfirmNotifier extends Notifier<RepoPathConfirmState> {
  /// Creates the notifier for [workspaceId].
  RepoPathConfirmNotifier(this.workspaceId);

  /// The workspace the repositories are linked to.
  final String workspaceId;

  @override
  RepoPathConfirmState build() => (busy: const {}, failed: const {});

  /// Confirms [repos] one after another; a refusal is kept against its
  /// repository and the rest carry on. A missing forge sign-in is offered
  /// once, through [context].
  Future<void> confirm(BuildContext context, List<Repo> repos) async {
    final l10n = AppLocalizations.of(context);
    var offeredSignIn = false;
    for (final repo in repos) {
      state = (
        busy: {...state.busy, repo.id},
        failed: {...state.failed}..remove(repo.id),
      );
      String? failure;
      try {
        await ref.read(linkRepoProvider)(workspaceId, repo);
      } on Object catch (e) {
        failure = describeRepoLinkError(l10n, e);
        if (!offeredSignIn && context.mounted) {
          offeredSignIn = offerSignInForRefusal(
            context,
            e,
            fallback: SignInNeed.forForge(repo.forge),
            workspaceId: workspaceId,
          );
        }
      }
      if (!ref.mounted) {
        return;
      }
      state = (
        busy: {...state.busy}..remove(repo.id),
        failed: {...state.failed, repo.id: ?failure},
      );
    }
  }
}

/// [RepoPathConfirmNotifier] per workspace.
final repoPathConfirmProvider = NotifierProvider.autoDispose
    .family<RepoPathConfirmNotifier, RepoPathConfirmState, String>(
      RepoPathConfirmNotifier.new,
    );

/// What a path issue means, in words, for someone who [canConfirm] (the
/// server's owner, who alone may let the server use a folder outside the
/// workspace's storage) or not.
String repoPathIssueMessage(
  AppLocalizations l10n,
  RepoPathIssue issue, {
  required bool canConfirm,
}) => switch (issue) {
  RepoPathIssue.hostPath =>
    canConfirm
        ? l10n.repoPathIssueHostPath
        : l10n.repoPathIssueHostPathAskOwner,
  RepoPathIssue.missing => l10n.repoPathIssueMissing,
  RepoPathIssue.dataDir ||
  RepoPathIssue.workspaceRoot => l10n.repoPathIssueUnusable,
};

/// The line under a repository row whose checkout the server does not serve
/// until it is linked again, worded by its `path_issue` code. Nothing when the
/// repository has none.
///
/// Calm by design: every desktop checkout linked before the rule arrived
/// carries `repo_path.host_path`, so on first launch after the update the
/// owner sees it on every repository. One click ("Confirm") settles it.
class RepoPathIssueNotice extends ConsumerWidget {
  /// Creates the notice for [repo].
  const RepoPathIssueNotice({
    super.key,
    required this.repo,
    required this.workspaceId,
  });

  /// The repository.
  final Repo repo;

  /// The workspace it is linked to.
  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final issue = ref
        .watch(repoPathIssuesProvider(workspaceId))
        .value?[repo.id];
    if (issue == null) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final owner = ref.watch(canUseHostProvider);
    final admin =
        ref.watch(myWorkspaceRoleProvider(workspaceId))?.isAdmin ?? false;
    final confirm = ref.watch(repoPathConfirmProvider(workspaceId));
    final busy = confirm.busy.contains(repo.id);
    final failure = confirm.failed[repo.id];
    const caption = CcTypography.caption;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 1),
            child: Icon(AppIcons.info, size: 14, color: t.fgWarningPrimary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  repoPathIssueMessage(l10n, issue, canConfirm: owner),
                  style: caption.copyWith(color: t.textSecondary),
                ),
                if (failure != null)
                  Text(
                    failure,
                    style: caption.copyWith(color: t.textErrorPrimary),
                  ),
              ],
            ),
          ),
          if (issue == RepoPathIssue.hostPath && owner) ...[
            const SizedBox(width: AppSpacing.sm),
            CcButton(
              size: CcButtonSize.sm,
              variant: CcButtonVariant.secondary,
              loading: busy,
              onPressed: busy
                  ? null
                  : () => unawaited(
                      ref
                          .read(repoPathConfirmProvider(workspaceId).notifier)
                          .confirm(context, [repo]),
                    ),
              child: Text(l10n.repoPathConfirm),
            ),
          ],
          // No action re-points a repository's folder: the fix is removing it
          // and adding it again from the right folder, a workspace admin's.
          if (issue != RepoPathIssue.hostPath && admin) ...[
            const SizedBox(width: AppSpacing.sm),
            CcButton(
              size: CcButtonSize.sm,
              variant: CcButtonVariant.secondary,
              onPressed: () => unawaited(
                confirmRemoveRepo(
                  context,
                  ref,
                  repo: repo,
                  workspaceId: workspaceId,
                ),
              ),
              child: Text(l10n.remove),
            ),
          ],
        ],
      ),
    );
  }
}

/// One action above the list when the server's owner has more than one
/// repository to confirm: "Confirm all", in sequence, each refusal shown on
/// its own row. Nothing otherwise.
class RepoPathConfirmAllBar extends ConsumerWidget {
  /// Creates the bar for [repos] in [workspaceId].
  const RepoPathConfirmAllBar({
    super.key,
    required this.workspaceId,
    required this.repos,
  });

  /// The workspace.
  final String workspaceId;

  /// The workspace's repositories, in list order.
  final List<Repo> repos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(canUseHostProvider)) {
      return const SizedBox.shrink();
    }
    final issues =
        ref.watch(repoPathIssuesProvider(workspaceId)).value ?? const {};
    final pending = [
      for (final repo in repos)
        if (issues[repo.id] == RepoPathIssue.hostPath) repo,
    ];
    if (pending.length < 2) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final busy = ref
        .watch(repoPathConfirmProvider(workspaceId))
        .busy
        .isNotEmpty;
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.md),
      child: CcAlert(
        variant: CcAlertVariant.info,
        icon: AppIcons.folder,
        title: l10n.repoPathConfirmAllTitle(pending.length),
        description: Text(l10n.repoPathConfirmAllBody),
        trailing: CcButton(
          size: CcButtonSize.sm,
          variant: CcButtonVariant.secondary,
          loading: busy,
          onPressed: busy
              ? null
              : () => unawaited(
                  ref
                      .read(repoPathConfirmProvider(workspaceId).notifier)
                      .confirm(context, pending),
                ),
          child: Text(l10n.repoPathConfirmAll),
        ),
      ),
    );
  }
}
