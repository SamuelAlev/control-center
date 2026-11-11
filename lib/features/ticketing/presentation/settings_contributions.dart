import 'package:control_center/features/settings/settings_extensions.dart';
import 'package:control_center/features/ticketing/presentation/widgets/linear_account_card.dart';
import 'package:control_center/features/ticketing/presentation/widgets/linear_account_status_line.dart';
import 'package:control_center/features/ticketing/presentation/widgets/ticketing_connection_card.dart';
import 'package:flutter/widgets.dart';

/// What `ticketing` puts into settings.
///
/// The vendor is a workspace property (two members must look at the same
/// board), so where this workspace's tickets live, and the automation actor
/// it acts through, open the Tickets group on Workspace → Integrations,
/// after a line naming the reader's own Linear account.
///
/// The credential for that vendor is the signed-in person's own: everyone
/// authenticates as themself against the one vendor the workspace chose. It
/// is stored against the person, so it is managed on You → Connected
/// accounts.
const List<SettingsSectionContribution> ticketingSettingsSections = [
  SettingsSectionContribution(
    id: 'ticketing.account',
    slot: SettingsSlot.userAccounts,
    order: 30,
    builder: _buildLinearAccount,
    visible: watchLinearAccountApplies,
  ),
  SettingsSectionContribution(
    id: 'ticketing.account-status',
    slot: SettingsSlot.workspaceIntegrations,
    order: 30,
    builder: _buildLinearAccountStatus,
    visible: watchLinearAccountStatusApplies,
  ),
  SettingsSectionContribution(
    id: 'ticketing.connection',
    slot: SettingsSlot.workspaceIntegrations,
    order: 31,
    builder: _buildTicketingConnection,
  ),
];

Widget _buildLinearAccount(BuildContext context) => const LinearAccountCard();

Widget _buildLinearAccountStatus(BuildContext context) =>
    const LinearAccountStatusLine();

Widget _buildTicketingConnection(BuildContext context) =>
    const TicketingConnectionCard();
