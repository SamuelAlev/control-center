import 'package:control_center/features/remote_control/presentation/settings/remote_control_settings_view.dart';
import 'package:control_center/features/settings/settings_extensions.dart';
import 'package:flutter/widgets.dart';

/// What `remote_control` puts into settings: the pairing + devices page.
const List<SettingsBody> remoteControlSettingsBodies = [
  SettingsBody(navItemId: 'you.devices', builder: _buildDevices),
];

Widget _buildDevices(BuildContext context) => const RemoteControlSettingsView();
