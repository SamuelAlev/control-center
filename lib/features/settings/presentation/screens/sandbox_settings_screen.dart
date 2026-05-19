import 'package:control_center/features/settings/presentation/widgets/settings_body_host.dart';
import 'package:flutter/widgets.dart';

/// Settings → Server → Sandbox.
///
/// Route and nav entry only: what the sandbox blocks is a host property, so the
/// page belongs to the `sandboxing` feature and arrives through the settings
/// registry.
class SandboxSettingsScreen extends StatelessWidget {
  /// Creates a [SandboxSettingsScreen].
  const SandboxSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const SettingsBodyHost(navItemId: 'server.sandbox');
}
