import 'package:control_center/features/settings/presentation/widgets/settings_body_host.dart';
import 'package:flutter/widgets.dart';

/// Settings → Workspace → Agents.
///
/// The route and the nav entry are settings'; the screen behind them belongs to
/// the `agents` feature and arrives through the settings registry, so this file
/// does not name it.
class AgentsSettingsScreen extends StatelessWidget {
  /// Creates an [AgentsSettingsScreen].
  const AgentsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const SettingsBodyHost(navItemId: 'workspace.agents');
}
