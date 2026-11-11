import 'package:control_center/features/chat_bridges/presentation/widgets/chat_account_status_line.dart';
import 'package:control_center/features/chat_bridges/presentation/widgets/sections/chat_bridges_section.dart';
import 'package:control_center/features/chat_bridges/presentation/widgets/sections/chat_ticket_drafts_section.dart';
import 'package:control_center/features/settings/settings_extensions.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What `chat_bridges` puts into settings: the SAME section twice, rendering
/// a different half of itself each time, plus the reader's ticket drafts
/// from chat.
///
/// Connecting the Slack app, running guided setup and customizing the bot is
/// workspace administration, so it is the Chat group on Workspace →
/// Integrations, after a line naming the reader's own linked account.
/// Linking *your* chat account to *your* user is yours, so it is among the
/// connected accounts on You → Profile, followed by your drafts: the bot
/// points people at that one page for both.
const List<SettingsSectionContribution> chatBridgesSettingsSections = [
  SettingsSectionContribution(
    id: 'chat_bridges.my-account-link',
    slot: SettingsSlot.userAccounts,
    order: 50,
    builder: _buildMyAccountLink,
    visible: _myAccountLinkApplies,
  ),
  SettingsSectionContribution(
    id: 'chat_bridges.ticket-drafts',
    slot: SettingsSlot.userAccounts,
    order: 51,
    builder: _buildTicketDrafts,
    visible: watchChatTicketDraftsApplies,
  ),
  SettingsSectionContribution(
    id: 'chat_bridges.account-status',
    slot: SettingsSlot.workspaceIntegrations,
    order: 50,
    builder: _buildAccountStatus,
    visible: watchChatAccountStatusApplies,
  ),
  SettingsSectionContribution(
    id: 'chat_bridges.workspace-setup',
    slot: SettingsSlot.workspaceIntegrations,
    order: 51,
    builder: _buildWorkspaceSetup,
    visible: _workspaceSetupApplies,
  ),
];

Widget _buildMyAccountLink(BuildContext context) =>
    const ChatBridgesSection(surface: ChatBridgeSurface.myAccountLink);

Widget _buildTicketDrafts(BuildContext context) =>
    const ChatTicketDraftsSection();

Widget _buildAccountStatus(BuildContext context) =>
    const ChatAccountStatusLine();

Widget _buildWorkspaceSetup(BuildContext context) => const ChatBridgesSection();

// Tear-offs, so the contribution list stays `const`.
bool _myAccountLinkApplies(WidgetRef ref) =>
    watchChatBridgesApplies(ref, ChatBridgeSurface.myAccountLink);

bool _workspaceSetupApplies(WidgetRef ref) =>
    watchChatBridgesApplies(ref, ChatBridgeSurface.workspaceSetup);
