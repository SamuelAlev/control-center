import 'package:control_center/features/environments/presentation/settings/environments_settings_view.dart';
import 'package:control_center/features/settings/settings_extensions.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// What `environments` puts into settings: the workspace's definitions.
const List<SettingsBody> environmentsSettingsBodies = [
  SettingsBody(
    navItemId: 'workspace.environments',
    builder: _buildEnvironments,
  ),
];

Widget _buildEnvironments(BuildContext context) => EnvironmentsSettingsView(
  definitionId: GoRouterState.of(context).pathParameters['definitionId'],
);
