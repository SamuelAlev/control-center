import 'package:control_center/features/auth/domain/entities/api_credentials.dart';
import 'package:control_center/features/auth/domain/entities/github_cli_status.dart';
import 'package:control_center/features/auth/providers/auth_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/settings_shared.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Settings section for GitHub and ticketing integrations.
class IntegrationsSection extends ConsumerWidget {
  /// Creates an [IntegrationsSection].
  const IntegrationsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final credentials =
        ref.watch(credentialsProvider).asData?.value ?? const ApiCredentials();
    final notifier = ref.read(credentialsProvider.notifier);
    final cliAsync = ref.watch(githubCliStatusProvider);
    final cli = cliAsync.value;
    final l10n = AppLocalizations.of(context);

    return SectionCard(
      label: l10n.integrations,
      child: Column(
        children: [
          SettingsRow(
            icon: LucideIcons.gitBranch,
            title: l10n.githubCli,
            subtitle: _ghCliSubtitle(context, cliAsync),
            subtitleWidget: cliAsync.isLoading
                ? const SkeletonBar(width: 140)
                : null,
            trailing: FButton(
              onPress: () => ref.invalidate(githubCliStatusProvider),
              variant: FButtonVariant.outline,
              mainAxisSize: MainAxisSize.min,
              prefix: const Icon(LucideIcons.refreshCw, size: 14),
              child: Text(l10n.refresh),
            ),
          ),
          const SizedBox(height: 8),
          SettingsRow(
            icon: LucideIcons.keyRound,
            title: l10n.githubPersonalAccessToken,
            subtitle: _patSubtitle(context, cli, credentials.hasGitHubToken),
            trailing: _TokenActions(
              hasValue: credentials.hasGitHubToken,
              onEdit: () => showTokenDialog(
                context,
                title: l10n.githubToken,
                save: notifier.setGitHubToken,
              ),
              onClear: notifier.clearGitHubToken,
            ),
          ),
          const SizedBox(height: 8),
          SettingsRow(
            icon: LucideIcons.zap,
            title: l10n.ticketingApiKey,
            subtitle: credentials.hasTicketingCredentials
                ? l10n.configuredLabel
                : l10n.notConfiguredLabel,
            trailing: _TokenActions(
              hasValue: credentials.hasTicketingCredentials,
              onEdit: () => showTokenDialog(
                context,
                title: l10n.ticketingApiKey,
                save: notifier.setTicketingApiKey,
              ),
              onClear: () => notifier.setTicketingApiKey(''),
            ),
          ),
        ],
      ),
    );
  }

  String _ghCliSubtitle(BuildContext context, AsyncValue<GitHubCliStatus> async) {
    final l10n = AppLocalizations.of(context);
    return async.when(
        data: (s) {
          if (!s.isInstalled) {
            return l10n.ghCliNotInstalled;
          }
          if (!s.isAuthenticated) {
            return l10n.ghCliInstalledAuth;
          }
          return s.username.isEmpty
              ? l10n.signedIn
              : l10n.signedInAs(s.username);
        },
        loading: () => l10n.checkingGhCli,
        error: (_, _) => l10n.couldNotCheckGhCli,
      );
  }

  String _patSubtitle(BuildContext context, GitHubCliStatus? cli, bool hasPat) {
    final l10n = AppLocalizations.of(context);
    if (hasPat) {
      return l10n.patOverridesGhCli;
    }
    if (cli != null && cli.isAuthenticated) {
      return l10n.patNotNeededGhCli;
    }
    return l10n.requiredIfGhCliUnavailable;
  }
}
class _TokenActions extends StatelessWidget {
  const _TokenActions({
    required this.hasValue,
    required this.onEdit,
    required this.onClear,
  });

  final bool hasValue;
  final VoidCallback onEdit;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasValue) ...[
          FButton(
            onPress: onClear,
            variant: FButtonVariant.ghost,
            mainAxisSize: MainAxisSize.min,
            child: Text(l10n.clear),
          ),
          const SizedBox(width: 8),
        ],
        FButton(
          onPress: onEdit,
          variant: FButtonVariant.outline,
          mainAxisSize: MainAxisSize.min,
          child: Text(hasValue ? l10n.updateLabel : l10n.setLabel),
        ),
      ],
    );
  }
}
