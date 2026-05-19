import 'package:control_center/features/settings/presentation/screens/settings_page.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/adapter_honesty_matrix_section.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/agent_permissions_section.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/what_if_probe_section.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Settings → Agent permissions (PRD 24): the guardrail policy matrix, a
/// what-if resolver probe, and the honest per-adapter enforcement reference.
class AgentPermissionsSettingsScreen extends StatelessWidget {
  /// Creates an [AgentPermissionsSettingsScreen].
  const AgentPermissionsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SettingsPage(
      title: l10n.agentPermissions,
      subtitle: l10n.agentPermissionsSettingsDescription,
      sections: const [
        AgentPermissionsSection(),
        WhatIfProbeSection(),
        AdapterHonestyMatrixSection(),
      ],
    );
  }
}
