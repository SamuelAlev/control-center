import 'package:control_center/features/forge/presentation/widgets/forge_connections_card.dart';
import 'package:control_center/features/forge/presentation/widgets/workspace_github_identity_card.dart';
import 'package:control_center/features/settings/settings_extensions.dart';
import 'package:flutter/widgets.dart';

/// What `forge` puts into settings: the code-hosting connections card on
/// Workspace → Profile & identity, and this workspace's GitHub identity on
/// Workspace → General.
///
/// A forge credential on Profile is the signed-in user's in this workspace.
/// The identity card is how the workspace itself talks to GitHub (its App or
/// PAT) — that is workspace policy, not a personal preference.
const List<SettingsSectionContribution> forgeSettingsSections = [
  SettingsSectionContribution(
    id: 'forge.connections',
    slot: SettingsSlot.workspaceProfile,
    order: 10,
    builder: _buildForgeConnections,
  ),
  SettingsSectionContribution(
    id: 'forge.github-identity',
    slot: SettingsSlot.workspaceGeneral,
    order: 5,
    builder: _buildWorkspaceGitHubIdentity,
  ),
];

Widget _buildForgeConnections(BuildContext context) =>
    const ForgeConnectionsCard();

Widget _buildWorkspaceGitHubIdentity(BuildContext context) =>
    const WorkspaceGitHubIdentityCard();
