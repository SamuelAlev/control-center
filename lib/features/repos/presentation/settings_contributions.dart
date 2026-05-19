import 'package:control_center/features/repos/presentation/settings/repos_settings_view.dart';
import 'package:control_center/features/settings/settings_extensions.dart';
import 'package:flutter/widgets.dart';

/// What `repos` puts into settings: the repository registry page.
const List<SettingsBody> reposSettingsBodies = [
  SettingsBody(navItemId: 'workspace.repositories', builder: _buildRepos),
];

Widget _buildRepos(BuildContext context) => const ReposSettingsView();
