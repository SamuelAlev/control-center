import 'package:control_center/features/settings/presentation/widgets/settings_body_host.dart';
import 'package:flutter/widgets.dart';

/// Settings → Workspace → Environments.
///
/// Route and nav entry only: the page itself is the `environments` feature's,
/// and arrives through the settings registry.
class EnvironmentsSettingsScreen extends StatelessWidget {
  /// Creates an [EnvironmentsSettingsScreen].
  const EnvironmentsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const SettingsBodyHost(navItemId: 'workspace.environments');
}
