import 'dart:async';

import 'package:cc_data/cc_data.dart' show GitHubInstallationView;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/auth/providers/provider_sign_in_controller.dart';
import 'package:control_center/features/forge/providers/workspace_github_providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where this workspace's GitHub App is installed, and installing it on
/// another account.
///
/// An installation needs nothing more: any server a member of the account
/// signs in on can use it, with that member's own access. A row is tagged
/// only when GitHub has suspended it.
///
/// The listing is the App's cached one; an admin's Refresh asks GitHub
/// afresh, for an installation made a moment ago.
class GitHubInstallationsGroup extends ConsumerStatefulWidget {
  /// Creates a [GitHubInstallationsGroup].
  const GitHubInstallationsGroup({super.key, required this.workspaceId});

  /// The workspace whose GitHub lane is listed.
  final String workspaceId;

  @override
  ConsumerState<GitHubInstallationsGroup> createState() =>
      _GitHubInstallationsGroupState();
}

class _GitHubInstallationsGroupState
    extends ConsumerState<GitHubInstallationsGroup> {
  bool _installing = false;
  bool _refreshing = false;

  Future<void> _refresh() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _refreshing = true);
    try {
      await ref
          .read(githubInstallationsProvider(widget.workspaceId).notifier)
          .refresh();
    } on Object catch (e) {
      if (mounted) {
        CcToastScope.maybeOf(
          context,
        )?.show(l10n.failedWithError('$e'), variant: CcToastVariant.danger);
      }
    } finally {
      if (mounted) {
        setState(() => _refreshing = false);
      }
    }
  }

  Future<void> _install() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _installing = true);
    try {
      final url = await ref
          .read(githubAppSetupProvider)
          .beginInstall(workspaceId: widget.workspaceId);
      final opened = url.isNotEmpty && ref.read(externalUrlOpenerProvider)(url);
      if (!opened && mounted) {
        CcToastScope.maybeOf(
          context,
        )?.show(l10n.couldNotOpenBrowser, variant: CcToastVariant.danger);
      }
    } on Object catch (e) {
      if (mounted) {
        CcToastScope.maybeOf(
          context,
        )?.show(l10n.failedWithError('$e'), variant: CcToastVariant.danger);
      }
    } finally {
      if (mounted) {
        setState(() => _installing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final installations =
        ref.watch(githubInstallationsProvider(widget.workspaceId)).value ??
        const <GitHubInstallationView>[];
    final isAdmin =
        ref.watch(myWorkspaceRoleProvider(widget.workspaceId))?.isAdmin ??
        false;
    return SettingsGroup(
      title: l10n.githubInstallations,
      description: l10n.githubInstallationsDescription,
      gap: AppSpacing.md,
      children: [
        if (installations.isEmpty)
          Text(
            l10n.githubInstallationsEmpty,
            style: CcTypography.caption.copyWith(color: t.textTertiary),
          ),
        for (final installation in installations)
          _InstallationRow(installation: installation),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            CcButton(
              loading: _installing,
              onPressed: _installing ? null : () => unawaited(_install()),
              variant: CcButtonVariant.secondary,
              size: CcButtonSize.sm,
              icon: AppIcons.externalLink,
              // Once it is installed somewhere, the same action adds another
              // account; say so rather than offering to install it again.
              child: Text(
                installations.isEmpty
                    ? l10n.githubInstallApp
                    : l10n.githubInstallOnAnotherOrganization,
              ),
            ),
            // The server asks GitHub afresh only for an admin.
            if (isAdmin)
              CcButton(
                loading: _refreshing,
                onPressed: _refreshing ? null : () => unawaited(_refresh()),
                variant: CcButtonVariant.ghost,
                size: CcButtonSize.sm,
                icon: AppIcons.refreshCw,
                child: Text(l10n.refresh),
              ),
          ],
        ),
      ],
    );
  }
}

class _InstallationRow extends StatelessWidget {
  const _InstallationRow({required this.installation});

  final GitHubInstallationView installation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Row(
      children: [
        Icon(
          installation.isOrganization ? AppIcons.users : AppIcons.user,
          size: 14,
          color: t.textTertiary,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            installation.accountLogin,
            overflow: TextOverflow.ellipsis,
            style: CcTypography.bodySm.copyWith(color: t.textPrimary),
          ),
        ),
        if (installation.suspended)
          CcStatusTag(
            label: l10n.githubInstallationSuspended,
            tone: CcStatusTone.negative,
          ),
      ],
    );
  }
}
