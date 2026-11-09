import 'package:control_center/features/chat_bridges/presentation/widgets/sections/chat_bridges_section.dart';
import 'package:control_center/features/chat_bridges/presentation/widgets/sections/chat_ticket_drafts_section.dart';
import 'package:control_center/features/settings/settings_extensions.dart';
import 'package:flutter/widgets.dart';

/// What `chat_bridges` puts into settings — the SAME section on two pages,
/// rendering a different half of itself on each, plus the reader's ticket
/// drafts from chat beside their link.
///
/// Connecting the Slack app, running guided setup and customizing the bot is
/// workspace administration; linking *your* chat account to *your* user is
/// identity in this workspace. They are different surfaces with different
/// audiences, so they are two contributions rather than one card. Drafts are
/// the reader's own too, and the bot points them at the same page.
const List<SettingsSectionContribution> chatBridgesSettingsSections = [
  SettingsSectionContribution(
    id: 'chat_bridges.my-account-link',
    slot: SettingsSlot.workspaceProfile,
    order: 40,
    builder: _buildMyAccountLink,
  ),
  SettingsSectionContribution(
    id: 'chat_bridges.ticket-drafts',
    slot: SettingsSlot.workspaceProfile,
    order: 41,
    builder: _buildTicketDrafts,
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

Widget _buildTicketDrafts(BuildContext context) =>
    const ChatTicketDraftsSection();

Widget _buildWorkspaceSetup(BuildContext context) => const ChatBridgesSection();
