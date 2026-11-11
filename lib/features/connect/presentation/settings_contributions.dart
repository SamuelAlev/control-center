import 'package:control_center/features/connect/presentation/settings/connect_section.dart';
import 'package:control_center/features/connect/presentation/settings/workspace_connect_section.dart';
import 'package:control_center/features/settings/settings_extensions.dart';
import 'package:flutter/widgets.dart';

/// What `connect` puts into settings: the server's Control Center Connect
/// card on Server → Single sign-on, above this server's own provider apps
/// (Connect decides which lanes need an own app at all), and the workspace's
/// own Connect choice at the top of Workspace → Integrations, where it
/// decides whose apps every provider card below uses.
const List<SettingsSectionContribution> connectSettingsSections = [
  SettingsSectionContribution(
    id: 'connect.connect',
    slot: SettingsSlot.serverSignIn,
    order: 10,
    builder: _buildConnect,
    visible: watchConnectSectionApplies,
  ),
  SettingsSectionContribution(
    id: 'connect.workspace',
    slot: SettingsSlot.workspaceIntegrations,
    order: 10,
    builder: _buildWorkspaceConnect,
    visible: watchWorkspaceConnectApplies,
  ),
];

Widget _buildConnect(BuildContext context) => const ConnectSection();

Widget _buildWorkspaceConnect(BuildContext context) =>
    const WorkspaceConnectSection();
