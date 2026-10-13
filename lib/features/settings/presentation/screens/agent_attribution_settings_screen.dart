import 'package:control_center/features/settings/presentation/screens/settings_page.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/general/agent_attribution_section.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Settings → You → Commit attribution.
class AgentAttributionSettingsScreen extends StatelessWidget {
  /// Creates an [AgentAttributionSettingsScreen].
  const AgentAttributionSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SettingsPage(
      title: l10n.settingsAgentAttributionTitle,
      subtitle: l10n.settingsAgentAttributionDescription,
      sections: const [AgentAttributionSection()],
    );
  }
}
