import 'dart:async';

import 'package:cc_data/cc_data.dart' show GitHubInstallationView;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/auth/providers/provider_sign_in_controller.dart';
import 'package:control_center/features/forge/providers/workspace_github_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where this workspace's GitHub App is installed, and the two actions that
/// change it: installing it on another account, and authorizing this server
/// for an organization installation that is bound elsewhere.
///
/// An organization installation of Control Center's shared App only works
/// for the servers its owners authorized, so an org admin sees "Authorize
/// this server" on the rows that need it. Nobody else does: the server would
/// refuse them.
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
  String? _authorizing;

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

  Future<void> _authorize(GitHubInstallationView installation) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _authorizing = installation.installationId);
    try {
      await ref
          .read(githubAppSetupProvider)
          .authorizeServer(
            workspaceId: widget.workspaceId,
            installationId: installation.installationId,
          );
      ref.invalidate(githubInstallationsProvider(widget.workspaceId));
      if (mounted) {
        CcToastScope.maybeOf(context)?.show(
          l10n.githubServerAuthorized(installation.accountLogin),
          variant: CcToastVariant.success,
        );
      }
    } on Object catch (e) {
      if (mounted) {
        CcToastScope.maybeOf(
          context,
        )?.show(l10n.failedWithError('$e'), variant: CcToastVariant.danger);
      }
    } finally {
      if (mounted) {
        setState(() => _authorizing = null);
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
          _InstallationRow(
            installation: installation,
            authorizing: _authorizing == installation.installationId,
            onAuthorize: () => unawaited(_authorize(installation)),
          ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: CcButton(
            loading: _installing,
            onPressed: _installing ? null : () => unawaited(_install()),
            variant: CcButtonVariant.secondary,
            size: CcButtonSize.sm,
            icon: AppIcons.externalLink,
            child: Text(l10n.githubInstallApp),
          ),
        ),
      ],
    );
  }
}

class _InstallationRow extends StatelessWidget {
  const _InstallationRow({
    required this.installation,
    required this.authorizing,
    required this.onAuthorize,
  });

  final GitHubInstallationView installation;
  final bool authorizing;
  final VoidCallback onAuthorize;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final (label, tone) = installation.suspended
        ? (l10n.githubInstallationSuspended, CcStatusTone.negative)
        : installation.boundHere
        ? (l10n.githubInstallationAuthorized, CcStatusTone.positive)
        : (l10n.githubInstallationNotAuthorized, CcStatusTone.caution);
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
        CcStatusTag(label: label, tone: tone),
        if (installation.canAuthorizeHere) ...[
          const SizedBox(width: AppSpacing.md),
          CcButton(
            loading: authorizing,
            onPressed: authorizing ? null : onAuthorize,
            size: CcButtonSize.sm,
            child: Text(l10n.githubAuthorizeServer),
          ),
        ],
      ],
    );
  }
}
