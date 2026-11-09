import 'package:control_center/features/connect/presentation/settings/connect_section.dart';
import 'package:control_center/features/settings/settings_extensions.dart';
import 'package:flutter/widgets.dart';

/// What `connect` puts into settings: the Control Center Connect card on
/// Server → Single sign-on, above this server's own provider apps — Connect
/// decides which lanes need an own app at all.
const List<SettingsSectionContribution> connectSettingsSections = [
  SettingsSectionContribution(
    id: 'connect.connect',
    slot: SettingsSlot.serverSignIn,
    order: 10,
    builder: _buildConnect,
  ),
];

Widget _buildConnect(BuildContext context) => const ConnectSection();
