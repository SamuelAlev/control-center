import 'package:control_center/features/settings/presentation/widgets/settings_body_host.dart';
import 'package:flutter/widgets.dart';

/// Settings → You → Devices.
///
/// Route and nav entry only: the page itself is the `remote_control` feature's,
/// and arrives through the settings registry.
class RemoteControlSettingsScreen extends StatelessWidget {
  /// Creates a [RemoteControlSettingsScreen].
  const RemoteControlSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const SettingsBodyHost(navItemId: 'you.devices');
}
