import 'package:cc_domain/core/domain/value_objects/forge_automation_token.dart';
import 'package:control_center/features/forge/presentation/widgets/automation_token_row.dart';
import 'package:control_center/features/forge/providers/automation_token_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings → Workspace → Integrations → Code hosting: the workspace's
/// GitLab and Bitbucket automation tokens, for admins.
///
/// A workspace token covers every repository on that forge without a token
/// of its own (Settings → Repositories); a repository's own token wins.
/// Shown while [watchWorkspaceAutomationTokensApplies] holds.
class WorkspaceAutomationTokensCard extends ConsumerWidget {
  /// Creates a [WorkspaceAutomationTokensCard].
  const WorkspaceAutomationTokensCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final tokens =
        ref.watch(automationTokensProvider(workspaceId)).value ??
        const <ForgeAutomationToken>[];
    return SectionCard(
      label: l10n.automationTokensTitle,
      subtitle: Text(l10n.automationTokensWorkspaceHint),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final forge in automationTokenForges)
            AutomationTokenRow(
              workspaceId: workspaceId,
              forge: forge,
              title: forge.displayName,
              token: tokens
                  .where(
                    (t) =>
                        t.forge == forge &&
                        t.scope == ForgeAutomationTokenScope.workspace,
                  )
                  .firstOrNull,
            ),
        ],
      ),
    );
  }
}

/// Whether [WorkspaceAutomationTokensCard] applies: inside a workspace whose
/// tokens the reader may manage, so never for members or on a demo.
bool watchWorkspaceAutomationTokensApplies(WidgetRef ref) {
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  return workspaceId != null &&
      ref.watch(canManageAutomationTokensProvider(workspaceId));
}
