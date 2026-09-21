import 'package:control_center/features/meetings/presentation/settings/meetings_settings_view.dart';
import 'package:control_center/features/settings/settings_extensions.dart';
import 'package:flutter/widgets.dart';

/// What `meetings` puts into settings: the workspace page for note templates
/// and saved voice profiles.
const List<SettingsBody> meetingsSettingsBodies = [
  SettingsBody(navItemId: 'workspace.meetings', builder: _buildMeetings),
];

Widget _buildMeetings(BuildContext context) => const MeetingsSettingsView();
