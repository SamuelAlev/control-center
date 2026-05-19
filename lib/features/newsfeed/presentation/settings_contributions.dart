import 'package:control_center/features/newsfeed/presentation/settings/newsfeed_settings_view.dart';
import 'package:control_center/features/settings/settings_extensions.dart';
import 'package:flutter/widgets.dart';

/// What `newsfeed` puts into settings: the feed registry and reader
/// preferences page.
const List<SettingsBody> newsfeedSettingsBodies = [
  SettingsBody(navItemId: 'you.newsfeed', builder: _buildNewsfeed),
];

Widget _buildNewsfeed(BuildContext context) => const NewsfeedSettingsView();
