import 'package:control_center/features/settings/presentation/widgets/settings_body_host.dart';
import 'package:flutter/widgets.dart';

/// Settings → Server → Enclosures.
///
/// Route and nav entry only: whether a rig can boot is a host property, so the
/// page belongs to the `rigs` feature and arrives through the settings
/// registry.
class RigsSettingsScreen extends StatelessWidget {
  /// Creates a [RigsSettingsScreen].
  const RigsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const SettingsBodyHost(navItemId: 'server.rigs');
}
