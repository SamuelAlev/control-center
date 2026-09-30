import 'package:control_center/features/settings/presentation/widgets/settings_body_host.dart';
import 'package:flutter/widgets.dart';

/// Settings → You → Links.
///
/// Route and nav entry only: the page itself is the `repos` feature's, and
/// arrives through the settings registry.
class LinksSettingsScreen extends StatelessWidget {
  /// Creates a [LinksSettingsScreen].
  const LinksSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const SettingsBodyHost(navItemId: 'you.links');
}
