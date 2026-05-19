import 'package:control_center/features/settings/presentation/screens/settings_page.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/sync_health_card.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/branch_template_section.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/voice_profiles_section.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/workspace/meeting_templates_section.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/workspace/workspace_policy_section.dart';
import 'package:control_center/features/settings/settings_extensions.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:flutter/widgets.dart';

/// Settings → Workspace → General.
///
/// The page that did not exist. Workspace-scoped configuration used to be
/// scattered: `secretExcludeGlobs` and `reviewConcurrency` had no UI at all,
/// sync health and chat bridges were filed under a personal "Accounts" page,
/// voice profiles sat inside a server-scoped voice page and the branch
/// template lived at the bottom of the "Advanced" junk drawer.
///
/// Workspace name, logo and deletion stay on the `/workspaces` picker, which is
/// where they already work and where you need them when the workspace you are
/// managing is not the one you are in.
class WorkspaceGeneralSettingsScreen extends StatelessWidget {
  /// Creates a [WorkspaceGeneralSettingsScreen].
  const WorkspaceGeneralSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final workspaceId = context.currentWorkspaceId;
    if (workspaceId == null) {
      return const SizedBox.shrink();
    }
    return SettingsPage(
      title: l10n.settingsWorkspaceGeneral,
      subtitle: l10n.settingsWorkspaceGeneralDescription,
      // The chat-bridge setup card is `chat_bridges`' contribution to this
      // slot, not something this page names.
      slot: SettingsSlot.workspaceGeneral,
      sections: [
        WorkspacePolicySection(workspaceId: workspaceId),
        const BranchTemplateSection(),
        const MeetingTemplatesSection(),
        const VoiceProfilesSection(),
        const SyncHealthCard(),
      ],
    );
  }
}
