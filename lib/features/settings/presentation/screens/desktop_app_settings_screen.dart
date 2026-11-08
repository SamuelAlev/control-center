import 'package:control_center/features/settings/presentation/widgets/settings_body_host.dart';
import 'package:flutter/widgets.dart';

/// Settings → You → Desktop app.
///
/// Route and nav entry only: the tray icon, the close behavior and the login
/// launch belong to the `desktop_app` feature, which fills the page through
/// the settings registry.
class DesktopAppSettingsScreen extends StatelessWidget {
  /// Creates a [DesktopAppSettingsScreen].
  const DesktopAppSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const SettingsBodyHost(navItemId: 'you.desktop');
}
