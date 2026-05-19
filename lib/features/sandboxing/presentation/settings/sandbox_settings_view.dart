import 'package:control_center/features/sandboxing/presentation/settings/sandbox_exec_grants_section.dart';
import 'package:control_center/features/settings/presentation/screens/settings_page.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Settings → Server → Sandbox.
///
/// A server-capability page for the same reason Enclosures is one: what the
/// sandbox blocks is a property of the host running `cc_server`, not of a
/// workspace destination. This file is the composition and nothing else.
class SandboxSettingsView extends StatelessWidget {
  /// Creates a [SandboxSettingsView].
  const SandboxSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SettingsPage(
      title: l10n.settingsSandboxLabel,
      subtitle: l10n.sandboxExecGrantsSubtitle,
      sections: const [SandboxExecGrantsSection()],
    );
  }
}
