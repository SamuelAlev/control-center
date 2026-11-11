import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/core/domain/value_objects/repo_access.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/external_link.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/operation_scope.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// No forge credential reached the server, so the poller has nothing to poll.
/// Says so instead of rendering a convincing "no open pull requests".
class NoForgeNotice extends StatelessWidget {
  /// Creates a [NoForgeNotice].
  const NoForgeNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return _WarnNotice(
      icon: AppIcons.cloudOff,
      message: AppLocalizations.of(context).noForgeConnected,
    );
  }
}

/// Repositories automation cannot reach, one line per cause, with the fix
/// where there is one: installing the GitHub App on an owner or adding a
/// repository to it opens the page the server named (admins only; members
/// are told to ask one), a suspended installation or an accountable person
/// without access is explained, a repository whose path now names a
/// different repository is flagged for relinking (done on the desktop or the
/// web; the phone cannot edit links), and a check that is only retrying says
/// so.
///
/// Renders nothing while every repository is reachable so callers can drop
/// it in unconditionally.
class RepoAccessNotice extends ConsumerWidget {
  /// Creates a [RepoAccessNotice] over [issues].
  const RepoAccessNotice({super.key, required this.issues});

  /// What automation cannot reach; empty renders nothing.
  final List<RepoAccessIssue> issues;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (issues.isEmpty) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final admin = ref.watch(workspaceRoleProvider).value?.isAdmin ?? false;
    String names(Iterable<RepoAccessIssue> group) =>
        group.map((i) => i.repoFullName).join(', ');
    List<RepoAccessIssue> of(RepoAccessState state) => [
      for (final i in issues)
        if (i.state == state) i,
    ];
    final byOwner = <String, List<RepoAccessIssue>>{};
    for (final i in of(RepoAccessState.appNotInstalled)) {
      (byOwner['${i.forge.wire}/${i.owner}'] ??= []).add(i);
    }
    final notSelected = of(RepoAccessState.repoNotSelected);
    final suspended = of(RepoAccessState.installationSuspended);
    final cannotSee = of(RepoAccessState.ownerCannotSee);
    final notSignedIn = of(RepoAccessState.ownerNotSignedIn);
    final noAutomationToken = of(RepoAccessState.automationTokenMissing);
    final replaced = <ForgeHost, List<RepoAccessIssue>>{};
    for (final i in of(RepoAccessState.repoReplaced)) {
      (replaced[i.forge] ??= []).add(i);
    }
    final transient = of(RepoAccessState.transient);
    String? urlOf(List<RepoAccessIssue> group) =>
        group.map((i) => i.installUrl).nonNulls.firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final group in byOwner.values)
          _WarnNotice(
            icon: AppIcons.triangleAlert,
            message: admin
                ? l10n.repoAccessInstallApp(group.first.owner, names(group))
                : l10n.repoAccessAskAdminInstall(
                    group.first.owner,
                    names(group),
                  ),
            onTap: admin && urlOf(group) != null
                ? () => openExternal(urlOf(group))
                : null,
          ),
        if (notSelected.isNotEmpty)
          _WarnNotice(
            icon: AppIcons.triangleAlert,
            message: admin
                ? l10n.repoAccessAddToApp(names(notSelected))
                : l10n.repoAccessAskAdminAdd(names(notSelected)),
            onTap: admin && urlOf(notSelected) != null
                ? () => openExternal(urlOf(notSelected))
                : null,
          ),
        if (suspended.isNotEmpty)
          _WarnNotice(
            icon: AppIcons.triangleAlert,
            message: l10n.repoAccessSuspended(names(suspended)),
          ),
        if (cannotSee.isNotEmpty)
          _WarnNotice(
            icon: AppIcons.triangleAlert,
            message: l10n.repoAccessOwnerCannotSee(names(cannotSee)),
          ),
        if (notSignedIn.isNotEmpty)
          _WarnNotice(
            icon: AppIcons.triangleAlert,
            message: l10n.repoAccessOwnerNotSignedIn(names(notSignedIn)),
          ),
        if (noAutomationToken.isNotEmpty)
          _WarnNotice(
            icon: AppIcons.triangleAlert,
            message: l10n.repoAccessAutomationTokenMissing(
              names(noAutomationToken),
            ),
          ),
        for (final MapEntry(key: forge, value: group) in replaced.entries)
          _WarnNotice(
            icon: AppIcons.triangleAlert,
            message: admin
                ? l10n.repoAccessReplaced(names(group), forge.displayName)
                : l10n.repoAccessAskAdminRelink(
                    names(group),
                    forge.displayName,
                  ),
          ),
        if (transient.isNotEmpty)
          _MutedNotice(message: l10n.repoAccessRetrying(names(transient))),
      ],
    );
  }
}

/// What the PR views leave out for the reader, as counts per forge and
/// reason. Not being signed in to a forge is theirs to fix, so that line
/// opens the credentials screen; a check still running is said quietly.
class HiddenReposNotice extends ConsumerWidget {
  /// Creates a [HiddenReposNotice] over [hidden].
  const HiddenReposNotice({super.key, required this.hidden});

  /// What is hidden; empty renders nothing.
  final List<HiddenRepos> hidden;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (hidden.isEmpty) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final workspaceId = ref.watch(activeWorkspaceIdProvider).value;
    final checking = hidden
        .where((h) => h.reason == HiddenRepoReason.checking)
        .fold(0, (sum, h) => sum + h.count);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final h in hidden)
          ?switch (h.reason) {
            HiddenRepoReason.signInRequired => _WarnNotice(
              icon: CcIcons.keyRound,
              message: l10n.hiddenReposSignIn(h.count, h.forge.displayName),
              onTap: workspaceId == null
                  ? null
                  : () => context.push(
                      remoteWorkspaceLocation('/credentials', workspaceId),
                    ),
            ),
            HiddenRepoReason.noForgeAccess => _MutedNotice(
              message: l10n.hiddenReposNoForgeAccess(
                h.count,
                h.forge.displayName,
              ),
            ),
            HiddenRepoReason.noGrant => _MutedNotice(
              message: l10n.hiddenReposNoGrant(h.count),
            ),
            HiddenRepoReason.checking => null,
          },
        if (checking > 0)
          _MutedNotice(message: l10n.hiddenReposChecking(checking)),
      ],
    );
  }
}

/// Information with nothing to do: no tint, secondary text.
class _MutedNotice extends StatelessWidget {
  const _MutedNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 0),
      child: Text(
        message,
        style: TextStyle(fontSize: 12, height: 1.4, color: t.textSecondary),
      ),
    );
  }
}

class _WarnNotice extends StatelessWidget {
  const _WarnNotice({required this.icon, required this.message, this.onTap});

  final IconData icon;
  final String message;

  /// The fix, when tapping the notice performs it.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final body = DecoratedBox(
      decoration: BoxDecoration(
        color: t.warnSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, size: 16, color: t.textWarningPrimary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: t.textPrimary,
                ),
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 8),
              Icon(AppIcons.externalLink, size: 16, color: t.textSecondary),
            ],
          ],
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 0),
      child: onTap == null
          ? body
          : CcTappable(
              onPressed: onTap,
              semanticLabel: message,
              builder: (context, _) => body,
            ),
    );
  }
}
