import 'package:control_center/features/dispatch/presentation/settings/dispatch_settings_view.dart';
import 'package:control_center/features/settings/settings_extensions.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// What `dispatch` puts into settings: the workspace's Schedules page (its
/// schedules and watches, one schedule's page, the limits on them, and what
/// happens to requests nobody answers).
const List<SettingsBody> dispatchSettingsBodies = [
  SettingsBody(navItemId: 'workspace.schedules', builder: _buildSchedules),
];

Widget _buildSchedules(BuildContext context) => DispatchSettingsView(
  ruleId: GoRouterState.of(context).pathParameters['recordId'],
);
