import 'package:control_center/features/agents/presentation/screens/agent_registry_screen.dart';
import 'package:control_center/features/agents/presentation/widgets/org_chart_view.dart';
import 'package:control_center/features/settings/settings_extensions.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// What `agents` puts into settings.
///
/// The registry page itself, plus the org chart as one of its views — the same
/// mechanism other features use, so the feature that owns the screen has no
/// privileged path into it and the toolbar renders one uniform list.
const List<SettingsBody> agentsSettingsBodies = [
  SettingsBody(navItemId: 'workspace.agents', builder: _buildRegistry),
];

/// The org chart, offered as an alternate view of the roster.
const List<AgentRegistryView> agentsRegistryViews = [
  AgentRegistryView(
    id: 'agents.org-chart',
    label: _orgChartLabel,
    icon: AppIcons.network,
    builder: _buildOrgChart,
  ),
];

Widget _buildRegistry(BuildContext context) => const AgentRegistryScreen();

Widget _buildOrgChart(BuildContext context, String workspaceId) =>
    SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: OrgChartView(workspaceId: workspaceId),
    );

// Tear-offs, so the contribution lists stay `const`.
String _orgChartLabel(AppLocalizations l) => l.orgChart;
