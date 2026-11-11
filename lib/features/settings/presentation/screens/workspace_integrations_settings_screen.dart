import 'package:control_center/features/settings/presentation/screens/settings_page.dart';
import 'package:control_center/features/settings/settings_extensions.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:flutter/widgets.dart';

/// Settings → Workspace → Integrations.
///
/// What this workspace decides about every provider it talks to, on one page
/// and grouped by provider: whose apps it signs people in through (its
/// Connect choice), then code hosting, tickets, calendar, chat and GIFs.
/// A person's own sign-ins are theirs, not the workspace's, and live on
/// You → Profile; a group that has one opens with a line naming the
/// reader's account there and linking to it.
///
/// Settings owns the page, not the integrations on it: every card is
/// contributed to [SettingsSlot.workspaceIntegrations] by the feature behind
/// it, in the order bands that slot documents.
class WorkspaceIntegrationsSettingsScreen extends StatelessWidget {
  /// Creates a [WorkspaceIntegrationsSettingsScreen].
  const WorkspaceIntegrationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (context.currentWorkspaceId == null) {
      return const SizedBox.shrink();
    }
    return SettingsPage(
      title: l10n.settingsWorkspaceIntegrations,
      subtitle: l10n.settingsWorkspaceIntegrationsDescription,
      slot: SettingsSlot.workspaceIntegrations,
      sections: const [],
    );
  }
}
