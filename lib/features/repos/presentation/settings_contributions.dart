import 'package:control_center/features/repos/presentation/settings/repo_link_settings_view.dart';
import 'package:control_center/features/repos/presentation/settings/repos_settings_view.dart';
import 'package:control_center/features/settings/settings_extensions.dart';
import 'package:flutter/widgets.dart';

/// What `repos` puts into settings: the repository registry page, and the
/// remembered workspaces that a repository's external links open in.
const List<SettingsBody> reposSettingsBodies = [
  SettingsBody(navItemId: 'workspace.repositories', builder: _buildRepos),
  SettingsBody(navItemId: 'you.links', builder: _buildLinks),
];

Widget _buildRepos(BuildContext context) => const ReposSettingsView();

Widget _buildLinks(BuildContext context) => const RepoLinkSettingsView();
