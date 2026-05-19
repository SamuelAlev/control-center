import 'package:control_center/features/messaging/presentation/settings/conversation_titles_section.dart';
import 'package:control_center/features/settings/settings_extensions.dart';
import 'package:control_center/router/routes.dart';
import 'package:flutter/widgets.dart';

/// What `messaging` puts into settings: the conversation-titles card on the
/// workspace's General page. The title model is the WORKSPACE's choice (an
/// admin-gated `workspace_settings` row the server reads per send), because
/// the title it writes is read by every member — so the card belongs under the
/// `Workspace` scope, not `You`.
const List<SettingsSectionContribution> messagingSettingsSections = [
  SettingsSectionContribution(
    id: 'messaging.conversation-titles',
    slot: SettingsSlot.workspaceGeneral,
    order: 20,
    builder: _buildConversationTitles,
  ),
];

Widget _buildConversationTitles(BuildContext context) {
  final workspaceId = context.currentWorkspaceId;
  if (workspaceId == null) {
    return const SizedBox.shrink();
  }
  return ConversationTitlesSection(workspaceId: workspaceId);
}
