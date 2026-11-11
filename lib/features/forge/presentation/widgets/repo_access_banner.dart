import 'dart:async';

import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/core/domain/value_objects/repo_access.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/auth/providers/provider_sign_in_controller.dart'
    show externalUrlOpenerProvider;
import 'package:control_center/features/forge/presentation/widgets/automation_token_dialog.dart';
import 'package:control_center/features/forge/presentation/widgets/repo_replaced_notice.dart';
import 'package:control_center/features/forge/providers/automation_token_providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Inline notices naming the linked repositories automation cannot reach,
/// one per cause, each with the fix.
///
/// * The GitHub App is not installed on an owner: admins get "Install GitHub
///   App" (the install page the server named); members are told who to ask.
/// * A repository is not selected in the installation: admins get "Choose
///   repositories".
/// * The installation is suspended: an explanation; only the account's owner
///   can resume it on GitHub.
/// * The workspace's accountable person cannot see a repository, or is not
///   signed in: automation that acts for them is paused.
/// * A GitLab or Bitbucket repository has no automation token that can read
///   it: automation there is paused; admins get "Add token" (the
///   repository's own token for one repository, else the workspace's for
///   that forge).
/// * A repository's path now names a different repository on its forge:
///   nothing is sent to it; admins get "Relink" ([RepoReplacedNotice]).
/// * A check did not get an answer: a muted "retrying" line, nothing to do.
///
/// Renders nothing while every repository is reachable (presence reports
/// trouble, never its absence) and carries its own bottom margin so callers
/// can drop it into a column unconditionally.
class RepoAccessBanner extends ConsumerWidget {
  /// Creates a [RepoAccessBanner] over [issues].
  const RepoAccessBanner({required this.issues, super.key});

  /// The repositories automation cannot reach; empty renders nothing.
  final List<RepoAccessIssue> issues;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (issues.isEmpty) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final isAdmin =
        workspaceId != null &&
        (ref.watch(myWorkspaceRoleProvider(workspaceId))?.isAdmin ?? false);
    final admins = workspaceId == null || isAdmin
        ? const <String>[]
        : ref.watch(workspaceAdminNamesProvider(workspaceId));
    final askAdmin = admins.isEmpty
        ? l10n.repoAccessAskAnAdmin
        : l10n.repoAccessAskAdmins(admins.join(', '));
    final open = ref.watch(externalUrlOpenerProvider);

    String names(Iterable<RepoAccessIssue> group) =>
        group.map((i) => i.repoFullName).join(', ');

    Widget? fixButton(String? url, String label) => isAdmin && url != null
        ? CcButton(
            size: CcButtonSize.sm,
            variant: CcButtonVariant.secondary,
            icon: AppIcons.externalLink,
            onPressed: () => open(url),
            child: Text(label),
          )
        : null;

    final notices = <Widget>[];
    // Not installed: one notice per owner, since installing is per account.
    final byOwner = <String, List<RepoAccessIssue>>{};
    for (final i in issues) {
      if (i.state == RepoAccessState.appNotInstalled) {
        (byOwner['${i.forge.wire}/${i.owner}'] ??= []).add(i);
      }
    }
    for (final group in byOwner.values) {
      notices.add(
        _Notice(
          icon: AppIcons.plug,
          title: l10n.repoAccessInstallTitle(group.first.owner),
          body: [
            l10n.repoAccessInstallBody(names(group)),
            if (!isAdmin) askAdmin,
          ].join(' '),
          action: fixButton(
            group
                .firstWhere(
                  (i) => i.installUrl != null,
                  orElse: () => group.first,
                )
                .installUrl,
            l10n.githubInstallApp,
          ),
        ),
      );
    }
    // Not selected: one notice per installation page.
    final byInstall = <String?, List<RepoAccessIssue>>{};
    for (final i in issues) {
      if (i.state == RepoAccessState.repoNotSelected) {
        (byInstall[i.installUrl] ??= []).add(i);
      }
    }
    for (final MapEntry(key: url, value: group) in byInstall.entries) {
      notices.add(
        _Notice(
          icon: AppIcons.lock,
          title: l10n.repoAccessSelectTitle(names(group)),
          body: [l10n.repoAccessSelectBody, if (!isAdmin) askAdmin].join(' '),
          action: fixButton(url, l10n.repoAccessChooseRepos),
        ),
      );
    }
    final suspended = _of(RepoAccessState.installationSuspended);
    if (suspended.isNotEmpty) {
      notices.add(
        _Notice(
          icon: AppIcons.alertTriangle,
          title: l10n.repoAccessSuspendedTitle,
          body: l10n.repoAccessSuspendedBody(names(suspended)),
        ),
      );
    }
    final cannotSee = _of(RepoAccessState.ownerCannotSee);
    if (cannotSee.isNotEmpty) {
      notices.add(
        _Notice(
          icon: AppIcons.pause,
          title: l10n.repoAccessAutomationPausedTitle,
          body: l10n.repoAccessOwnerCannotSeeBody(names(cannotSee)),
        ),
      );
    }
    final notSignedIn = _of(RepoAccessState.ownerNotSignedIn);
    if (notSignedIn.isNotEmpty) {
      notices.add(
        _Notice(
          icon: AppIcons.pause,
          title: l10n.repoAccessAutomationPausedTitle,
          body: l10n.repoAccessOwnerNotSignedInBody(names(notSignedIn)),
        ),
      );
    }
    final canAddToken =
        workspaceId != null &&
        ref.watch(canManageAutomationTokensProvider(workspaceId));
    final tokenMissing = <ForgeHost, List<RepoAccessIssue>>{};
    for (final i in _of(RepoAccessState.automationTokenMissing)) {
      (tokenMissing[i.forge] ??= []).add(i);
    }
    for (final MapEntry(key: forge, value: group) in tokenMissing.entries) {
      final single = group.length == 1 && group.first.repoId != null;
      notices.add(
        _Notice(
          icon: AppIcons.pause,
          title: l10n.repoAccessAutomationPausedTitle,
          body: [
            l10n.repoAccessAutomationTokenMissingBody(names(group)),
            if (!isAdmin) askAdmin,
          ].join(' '),
          action: canAddToken
              ? CcButton(
                  size: CcButtonSize.sm,
                  variant: CcButtonVariant.secondary,
                  icon: AppIcons.keyRound,
                  onPressed: () => unawaited(
                    showAutomationTokenDialog(
                      context,
                      workspaceId: workspaceId,
                      forge: forge,
                      target: single
                          ? group.first.repoFullName
                          : l10n.automationTokenWorkspaceTarget(
                              forge.displayName,
                            ),
                      repoId: single ? group.first.repoId : null,
                    ),
                  ),
                  child: Text(l10n.addToken),
                )
              : null,
        ),
      );
    }
    if (workspaceId != null) {
      for (final issue in _of(RepoAccessState.repoReplaced)) {
        notices.add(
          RepoReplacedNotice(
            issue: issue,
            workspaceId: workspaceId,
            isAdmin: isAdmin,
            askAdmin: askAdmin,
          ),
        );
      }
    }
    final transient = _of(RepoAccessState.transient);
    if (transient.isNotEmpty) {
      notices.add(
        _RetryingLine(text: l10n.repoAccessTransient(names(transient))),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: notices,
    );
  }

  List<RepoAccessIssue> _of(RepoAccessState state) => [
    for (final i in issues)
      if (i.state == state) i,
  ];
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.md),
    child: CcAlert(
      variant: CcAlertVariant.warning,
      icon: icon,
      title: title,
      description: Text(body),
      trailing: action,
    ),
  );
}

/// A check that will be repeated on its own: said quietly, in one line.
class _RetryingLine extends StatelessWidget {
  const _RetryingLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Icon(AppIcons.refreshCw, size: 14, color: t.textTertiary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: CcTypography.caption.copyWith(color: t.textTertiary),
            ),
          ),
        ],
      ),
    );
  }
}
