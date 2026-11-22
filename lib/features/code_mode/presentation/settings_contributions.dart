import 'package:control_center/features/code_mode/presentation/settings/code_mode_settings_view.dart';
import 'package:control_center/features/settings/settings_extensions.dart';
import 'package:flutter/widgets.dart';

/// What `code_mode` puts into settings: the workspace's code mode page (its
/// status on this server, the mode, and the limits a script runs under).
const List<SettingsBody> codeModeSettingsBodies = [
  SettingsBody(navItemId: 'workspace.code_mode', builder: _buildCodeMode),
];

Widget _buildCodeMode(BuildContext context) => const CodeModeSettingsView();
