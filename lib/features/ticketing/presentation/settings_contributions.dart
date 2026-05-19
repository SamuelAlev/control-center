import 'package:control_center/features/settings/settings_extensions.dart';
import 'package:control_center/features/ticketing/presentation/widgets/ticketing_connection_card.dart';
import 'package:flutter/widgets.dart';

/// What `ticketing` puts into settings: where tickets live and the credential
/// for that vendor, on the profile page.
///
/// One card, not two: choosing the vendor and authenticating to it are the
/// same decision, and the credential is the signed-in user's.
const List<SettingsSectionContribution> ticketingSettingsSections = [
  SettingsSectionContribution(
    id: 'ticketing.connection',
    slot: SettingsSlot.userProfile,
    order: 20,
    builder: _buildTicketingConnection,
  ),
];

Widget _buildTicketingConnection(BuildContext context) =>
    const TicketingConnectionCard();
