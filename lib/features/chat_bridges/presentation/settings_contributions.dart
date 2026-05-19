import 'package:control_center/features/chat_bridges/presentation/widgets/sections/chat_bridges_section.dart';
import 'package:control_center/features/settings/settings_extensions.dart';
import 'package:flutter/widgets.dart';

/// What `chat_bridges` puts into settings — the SAME section on two pages,
/// rendering a different half of itself on each.
///
/// Connecting the Slack app, running guided setup and customizing the bot is
/// workspace administration; linking *your* chat account to *your* user is
/// identity. They are different scopes with different audiences, so they are
/// two contributions rather than one card filed under whichever scope wins.
const List<SettingsSectionContribution> chatBridgesSettingsSections = [
  SettingsSectionContribution(
    id: 'chat_bridges.my-account-link',
    slot: SettingsSlot.userProfile,
    order: 40,
    builder: _buildMyAccountLink,
  ),
  SettingsSectionContribution(
    id: 'chat_bridges.workspace-setup',
    slot: SettingsSlot.workspaceGeneral,
    order: 40,
    builder: _buildWorkspaceSetup,
  ),
];

Widget _buildMyAccountLink(BuildContext context) =>
    const ChatBridgesSection(surface: ChatBridgeSurface.myAccountLink);

Widget _buildWorkspaceSetup(BuildContext context) => const ChatBridgesSection();
