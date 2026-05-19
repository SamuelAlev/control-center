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

/// The org chart, offered as an alternate reading of the whole roster.
///
/// It takes the entire body rather than sitting in the detail pane beside the
/// list: a hierarchy is laid out across the full width of its widest
/// generation, so squeezed into a ~600px pane next to a rail it had to scroll
/// sideways to show a five-agent org. It is a view OF the roster, so having
/// the roster next to it was showing the same five agents twice anyway.
const List<AgentRegistryView> agentsRegistryViews = [
  AgentRegistryView(
    id: 'agents.org-chart',
    label: _orgChartLabel,
    icon: AppIcons.network,
    replacesRoster: true,
    builder: _buildOrgChart,
  ),
];

Widget _buildRegistry(BuildContext context) => const AgentRegistryScreen();

// The chart owns its own (two-axis) scrolling — a hierarchy is wider than its
// pane more often than not — so it is handed the pane whole.
Widget _buildOrgChart(BuildContext context, String workspaceId) =>
    OrgChartView(workspaceId: workspaceId);

// Tear-offs, so the contribution lists stay `const`.
String _orgChartLabel(AppLocalizations l) => l.orgChart;
