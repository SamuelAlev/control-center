import 'package:control_center/features/settings/presentation/widgets/settings_body_host.dart';
import 'package:flutter/widgets.dart';

/// Settings → Workspace → Repositories.
///
/// Route and nav entry only: the page itself is the `repos` feature's, and
/// arrives through the settings registry.
class ReposSettingsScreen extends StatelessWidget {
  /// Creates a [ReposSettingsScreen].
  const ReposSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const SettingsBodyHost(navItemId: 'workspace.repositories');
}
