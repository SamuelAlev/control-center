import 'package:control_center/features/dispatch/presentation/settings/dispatch_settings_view.dart';
import 'package:control_center/features/settings/settings_extensions.dart';
import 'package:flutter/widgets.dart';

/// What `dispatch` puts into settings: the workspace's Schedules page (the
/// limits on schedules and watches, and what happens to requests nobody
/// answers).
const List<SettingsBody> dispatchSettingsBodies = [
  SettingsBody(navItemId: 'workspace.schedules', builder: _buildSchedules),
];

Widget _buildSchedules(BuildContext context) => const DispatchSettingsView();
