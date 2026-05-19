import 'package:control_center/features/settings/settings_extensions.dart';
import 'package:control_center/features/teams/presentation/widgets/teams_management_view.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// What `teams` puts into settings: the teams manager, as a view of the agent
/// registry.
///
/// A team's members and its leader are agents, so it belongs beside the roster
/// rather than on the workspace-membership page, which is about humans. It
/// carries its own list, so it takes the whole body rather than sitting next to
/// a second roster.
const List<AgentRegistryView> teamsRegistryViews = [
  AgentRegistryView(
    id: 'teams.management',
    label: _teamsLabel,
    icon: AppIcons.users,
    order: 10,
    replacesRoster: true,
    builder: _buildTeams,
  ),
];

Widget _buildTeams(BuildContext context, String workspaceId) =>
    TeamsManagementView(workspaceId: workspaceId);

// Tear-off, so the contribution list stays `const`.
String _teamsLabel(AppLocalizations l) => l.teamsNav;
