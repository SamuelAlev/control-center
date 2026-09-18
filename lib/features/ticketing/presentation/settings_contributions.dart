import 'package:control_center/features/settings/settings_extensions.dart';
import 'package:control_center/features/ticketing/presentation/widgets/ticketing_connection_card.dart';
import 'package:flutter/widgets.dart';

/// What `ticketing` puts into settings: where this workspace's tickets live,
/// on Workspace → General.
///
/// The vendor is a workspace property (two members must look at the same
/// board). The credential for that vendor is still the signed-in user's —
/// everyone authenticates as themself against the one vendor the workspace
/// chose — so it stays on the same card rather than splitting the decision
/// across two pages. The card used to sit on Profile & identity, which made
/// a shared board look like a personal preference.
const List<SettingsSectionContribution> ticketingSettingsSections = [
  SettingsSectionContribution(
    id: 'ticketing.connection',
    slot: SettingsSlot.workspaceGeneral,
    order: 10,
    builder: _buildTicketingConnection,
  ),
];

Widget _buildTicketingConnection(BuildContext context) =>
    const TicketingConnectionCard();
