import 'package:control_center/features/rigs/presentation/settings/rigs_settings_view.dart';
import 'package:control_center/features/settings/settings_extensions.dart';
import 'package:flutter/widgets.dart';

/// What `rigs` puts into settings: the enclosure capabilities, base images and
/// running-machine page.
const List<SettingsBody> rigsSettingsBodies = [
  SettingsBody(navItemId: 'server.rigs', builder: _buildRigs),
];

Widget _buildRigs(BuildContext context) => const RigsSettingsView();
