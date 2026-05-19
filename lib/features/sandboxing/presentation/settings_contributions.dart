import 'package:control_center/features/sandboxing/presentation/settings/sandbox_settings_view.dart';
import 'package:control_center/features/settings/settings_extensions.dart';
import 'package:flutter/widgets.dart';

/// What `sandboxing` puts into settings: the executable-grants page — which
/// working copies the operator has allowed agents to run programs from.
const List<SettingsBody> sandboxingSettingsBodies = [
  SettingsBody(navItemId: 'server.sandbox', builder: _buildSandbox),
];

Widget _buildSandbox(BuildContext context) => const SandboxSettingsView();
