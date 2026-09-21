import 'package:control_center/features/settings/presentation/widgets/settings_body_host.dart';
import 'package:flutter/widgets.dart';

/// Settings → Workspace → Meetings.
///
/// Route and nav entry only: the page itself is the `meetings` feature's, and
/// arrives through the settings registry.
class MeetingsSettingsScreen extends StatelessWidget {
  /// Creates a [MeetingsSettingsScreen].
  const MeetingsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const SettingsBodyHost(navItemId: 'workspace.meetings');
}
