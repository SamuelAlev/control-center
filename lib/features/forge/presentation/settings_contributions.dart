import 'package:control_center/features/forge/presentation/widgets/forge_account_status_line.dart';
import 'package:control_center/features/forge/presentation/widgets/forge_connections_card.dart';
import 'package:control_center/features/forge/presentation/widgets/workspace_automation_tokens_card.dart';
import 'package:control_center/features/forge/presentation/widgets/workspace_github_app_card.dart';
import 'package:control_center/features/settings/settings_extensions.dart';
import 'package:flutter/widgets.dart';

/// What `forge` puts into settings.
///
/// On You → Profile, under Connected accounts: the person's own forge accounts
/// (their GitHub sign-in, their GitLab and Bitbucket tokens).
///
/// On Workspace → Integrations, the Code hosting group: a line naming the
/// reader's own forge accounts (linking to the page above), the GitHub App
/// the workspace runs on (where it is installed, and its credentials while
/// the workspace uses its own apps), then the GitLab and Bitbucket
/// automation tokens (admins).
const List<SettingsSectionContribution> forgeSettingsSections = [
  SettingsSectionContribution(
    id: 'forge.connections',
    slot: SettingsSlot.userAccounts,
    order: 20,
    builder: _buildForgeConnections,
  ),
  SettingsSectionContribution(
    id: 'forge.account-status',
    slot: SettingsSlot.workspaceIntegrations,
    order: 20,
    builder: _buildForgeAccountStatus,
    visible: watchForgeAccountStatusApplies,
  ),
  SettingsSectionContribution(
    id: 'forge.github-app',
    slot: SettingsSlot.workspaceIntegrations,
    order: 21,
    builder: _buildWorkspaceGitHubApp,
    visible: watchWorkspaceGitHubAppApplies,
  ),
  SettingsSectionContribution(
    id: 'forge.automation-tokens',
    slot: SettingsSlot.workspaceIntegrations,
    order: 22,
    builder: _buildWorkspaceAutomationTokens,
    visible: watchWorkspaceAutomationTokensApplies,
  ),
];

Widget _buildForgeConnections(BuildContext context) =>
    const ForgeConnectionsCard();

Widget _buildForgeAccountStatus(BuildContext context) =>
    const ForgeAccountStatusLine();

Widget _buildWorkspaceGitHubApp(BuildContext context) =>
    const WorkspaceGitHubAppCard();

Widget _buildWorkspaceAutomationTokens(BuildContext context) =>
    const WorkspaceAutomationTokensCard();
