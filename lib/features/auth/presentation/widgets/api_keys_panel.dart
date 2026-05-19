// ignore: unused_import — getters on ApiCredentials are visible via this import
import 'package:cc_domain/features/auth/domain/entities/api_credentials.dart';
import 'package:cc_domain/features/auth/domain/entities/github_cli_status.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/auth/providers/auth_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Renders the GitHub CLI status, GitHub PAT, and ticketing API key cards.
///
/// Reused by the standalone API keys settings screen and by the first
/// onboarding step.
class ApiKeysPanel extends ConsumerWidget {
  /// Creates an [ApiKeysPanel].
  const ApiKeysPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final credentialsAsync = ref.watch(credentialsProvider);
    final credentials =
        credentialsAsync.asData?.value ?? const ApiCredentials();
    final notifier = ref.read(credentialsProvider.notifier);
    final cliAsync = ref.watch(githubCliStatusProvider);
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _GitHubCliCard(
          statusAsync: cliAsync,
          onRefresh: () => ref.invalidate(githubCliStatusProvider),
          hasPatOverride: credentials.hasGitHubToken,
        ),
        const SizedBox(height: 24),
        SectionCard(
          title: Text(l10n.personalAccessTokenOptional),
          subtitle: Text(_patSubtitle(l10n, cliAsync, credentials.hasGitHubToken)),
          child: Row(
            children: [
              CcButton(
                onPressed: () => _showTokenDialog(
                  context,
                  'GitHub',
                  notifier.setGitHubToken,
                ),
                child: Text(
                  credentials.hasGitHubToken ? l10n.updateToken : l10n.addToken,
                ),
              ),
              if (credentials.hasGitHubToken) ...[
                const SizedBox(width: 12),
                CcButton(
                  onPressed: () async {
                    await notifier.clearGitHubToken();
                  },
                  variant: CcButtonVariant.ghost,
                  child: Text(l10n.clear),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        SectionCard(
          title: Text(l10n.ticketingProvider),
          child: DropdownButton<TicketProvider>(
            isExpanded: true,
            value: TicketProvider.fromStorage(credentials.ticketingProviderId),
            items: [
              for (final p in TicketProvider.values)
                DropdownMenuItem(
                  value: p,
                  enabled: p == TicketProvider.local || p == TicketProvider.linear,
                  child: Text(
                    p == TicketProvider.local || p == TicketProvider.linear
                        ? p.name
                        : '${p.name} (soon)',
                  ),
                ),
            ],
            onChanged: (p) {
              if (p != null) {
                notifier.setTicketingProvider(p.toStorageString());
              }
            },
          ),
        ),
        const SizedBox(height: 24),
        SectionCard(
          title: Text(l10n.ticketingApiKey),
          subtitle: Text(
            credentials.hasTicketingCredentials
                ? l10n.configuredLabel
                : l10n.notConfiguredLabel,
          ),
          child: Row(
            children: [
              CcButton(
                onPressed: () => _showTokenDialog(
                  context,
                  l10n.ticketingProvider,
                  notifier.setTicketingApiKey,
                ),
                child: Text(l10n.updateKey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _patSubtitle(AppLocalizations l10n, AsyncValue<GitHubCliStatus> cliAsync, bool hasPat) {
    if (hasPat) {
      return l10n.patOverridesGhCli;
    }

    final cli = cliAsync.value;
    if (cli != null && cli.isAuthenticated) {
      return l10n.patNotNeededGhCli;
    }
    return l10n.requiredIfGhCliUnavailable;
  }

  void _showTokenDialog(
    BuildContext context,
    String name,
    Future<void> Function(String) onSave,
  ) {
    final controller = TextEditingController();
    final l10n = AppLocalizations.of(context);
    showCcDialog<void>(
      context: context,
      builder: (dialogContext) => CcDialog(
        title: l10n.enterToken(name),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.tokenName(name)),
            const SizedBox(height: 6),
            CcTextField(
              controller: controller,
              hintText: l10n.pasteTokenHere,
              obscureText: true,
            ),
          ],
        ),
        actions: [
          CcButton(
            onPressed: () => Navigator.pop(dialogContext),
            variant: CcButtonVariant.ghost,
            child: Text(l10n.cancel),
          ),
          CcButton(
            onPressed: () async {
              try {
                await onSave(controller.text);
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  CcToastScope.of(dialogContext).show(
                    l10n.failedWithError('$e'),
                    variant: CcToastVariant.danger,
                  );
                }
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }
}

class _GitHubCliCard extends StatelessWidget {
  const _GitHubCliCard({
    required this.statusAsync,
    required this.onRefresh,
    required this.hasPatOverride,
  });

  final AsyncValue<GitHubCliStatus> statusAsync;
  final VoidCallback onRefresh;
  final bool hasPatOverride;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SectionCard(
      title: Text(l10n.githubCliIntegration),
      subtitle: Text(_subtitle(l10n)),
      child: Row(
        children: [
          Expanded(child: _body(context)),
          const SizedBox(width: 12),
          CcButton(
            onPressed: onRefresh,
            variant: CcButtonVariant.ghost,
            child: Text(l10n.refresh),
          ),
        ],
      ),
    );
  }

  String _subtitle(AppLocalizations l10n) {
    return statusAsync.when(
      data: (s) {
        if (!s.isInstalled) {
          return l10n.ghCliNotInstalledLabel;
        }

        if (!s.isAuthenticated) {
          return l10n.installedNotSignedIn;
        }

        return s.username.isEmpty ? l10n.signedIn : l10n.signedInAs(s.username);
      },
      loading: () => l10n.checkingEllipsis,
      error: (_, _) => l10n.couldNotCheckGhCli,
    );
  }

  Widget _body(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return statusAsync.when(
      loading: () => Text(l10n.detectingGhCli),
      error: (e, _) => Text(l10n.failedWithError('$e')),
      data: (s) {
        if (!s.isInstalled) {
          return Text(
            l10n.installGhCliBody,
          );
        }
        if (!s.isAuthenticated) {
          return Text(
            l10n.runGhAuthLoginBody,
          );
        }
        if (hasPatOverride) {
          return Text(
            l10n.ghCliAuthButPatOverrideBody,
          );
        }
        return Text(l10n.githubCliReady);
      },
    );
  }
}
