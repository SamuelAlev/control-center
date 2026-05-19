import 'package:control_center/features/forge/presentation/widgets/forge_connections_card.dart';
import 'package:control_center/features/settings/settings_extensions.dart';
import 'package:flutter/widgets.dart';

/// What `forge` puts into settings: the code-hosting connections card on the
/// profile page.
///
/// It belongs under the `You` scope because a forge credential is now the
/// signed-in user's, not the server's — the same card in onboarding, settings
/// and (once they sign in) every other member's account.
const List<SettingsSectionContribution> forgeSettingsSections = [
  SettingsSectionContribution(
    id: 'forge.connections',
    slot: SettingsSlot.userProfile,
    order: 10,
    builder: _buildForgeConnections,
  ),
];

Widget _buildForgeConnections(BuildContext context) =>
    const ForgeConnectionsCard();
