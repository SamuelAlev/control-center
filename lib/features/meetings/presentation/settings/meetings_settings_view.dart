import 'package:control_center/features/settings/presentation/screens/settings_page.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/voice_profiles_section.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/workspace/meeting_templates_section.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Settings → Workspace → Meetings: note templates and saved voice profiles
/// for meetings in this workspace.
///
/// Speech and diarization models stay under Server → Voice & meeting models;
/// they are host-owned assets, not workspace data.
class MeetingsSettingsView extends StatelessWidget {
  /// Creates a [MeetingsSettingsView].
  const MeetingsSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SettingsPage(
      title: l10n.navMeetings,
      subtitle: l10n.settingsWorkspaceMeetingsDescription,
      sections: const [MeetingTemplatesSection(), VoiceProfilesSection()],
    );
  }
}
