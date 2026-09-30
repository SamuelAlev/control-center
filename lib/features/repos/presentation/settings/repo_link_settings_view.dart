import 'dart:async';

import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/repos/providers/repo_link_workspace_choices.dart';
import 'package:control_center/features/settings/presentation/screens/settings_page.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:control_center/shared/widgets/workspace_avatar.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings → You → Links: the workspaces the user asked Control Center to
/// remember for repositories linked in several workspaces.
///
/// User-scoped because the choices follow the user across devices (see
/// [repoLinkWorkspaceChoicesKey]), whichever workspace is open here.
class RepoLinkSettingsView extends ConsumerWidget {
  /// Creates a [RepoLinkSettingsView].
  const RepoLinkSettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final choices = ref.watch(repoLinkWorkspaceChoicesProvider).byRepo;
    final workspaces = {
      for (final w
          in ref.watch(workspacesProvider).value ?? const <Workspace>[])
        w.id: w,
    };
    final repos = choices.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return SettingsPage(
      title: l10n.settingsLinks,
      subtitle: l10n.linksSettingsDescription,
      sections: [
        SectionCard(
          label: l10n.repoLinkRememberedTitle,
          count: repos.isEmpty ? null : repos.length,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.repoLinkRememberedHint,
                style: CcTypography.caption.copyWith(
                  color: tokens.textTertiary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (repos.isEmpty)
                Text(
                  l10n.repoLinkRememberedEmpty,
                  style: CcTypography.bodySm.copyWith(
                    color: tokens.textSecondary,
                  ),
                )
              else
                for (final repo in repos)
                  _RememberedChoiceRow(
                    repoFullName: repo,
                    workspace: workspaces[choices[repo]],
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One remembered repository → workspace pair and its "Forget" action.
class _RememberedChoiceRow extends ConsumerWidget {
  const _RememberedChoiceRow({
    required this.repoFullName,
    required this.workspace,
  });

  final String repoFullName;

  /// Null when the remembered workspace no longer exists or isn't visible to
  /// this user; the row stays so the choice can still be forgotten.
  final Workspace? workspace;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final workspace = this.workspace;

    return CcTile(
      leading: WorkspaceAvatar(
        workspaceId: workspace?.id,
        // No name for a missing workspace: the neutral placeholder, rather
        // than an initial that reads like some other workspace's mark.
        name: workspace?.name,
        hasLogo: workspace?.logoPath?.isNotEmpty ?? false,
        size: 24,
      ),
      title: repoFullName,
      subtitle: Text(workspace?.name ?? l10n.repoLinkWorkspaceUnavailable),
      trailing: CcButton(
        variant: CcButtonVariant.secondary,
        size: CcButtonSize.sm,
        onPressed: () => unawaited(
          ref
              .read(repoLinkWorkspaceChoicesProvider.notifier)
              .forget(repoFullName),
        ),
        child: Text(l10n.repoLinkForget),
      ),
    );
  }
}
