import 'package:control_center/features/desktop_app/presentation/settings/desktop_app_settings_view.dart';
import 'package:control_center/features/settings/settings_extensions.dart';
import 'package:flutter/widgets.dart';

/// What `desktop_app` puts into settings: the tray, closing and login page.
const List<SettingsBody> desktopAppSettingsBodies = [
  SettingsBody(navItemId: 'you.desktop', builder: _buildDesktopApp),
];

Widget _buildDesktopApp(BuildContext context) => const DesktopAppSettingsView();
