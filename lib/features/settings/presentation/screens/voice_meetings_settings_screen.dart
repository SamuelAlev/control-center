import 'package:control_center/features/settings/presentation/screens/settings_page.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/diarization_section.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/meeting_templates_section.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/voice_section.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Settings → Voice & meetings: transcription, diarization, voice profiles,
/// and meeting templates. The audio pillar of the product, lifted out of the
/// old catch-all "Advanced" page.
class VoiceMeetingsSettingsScreen extends StatelessWidget {
  /// Creates a [VoiceMeetingsSettingsScreen].
  const VoiceMeetingsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SettingsPage(
      title: l10n.settingsVoiceModels,
      subtitle: l10n.voiceAndMeetingsSettingsDescription,
      sections: const [
        VoiceSection(),
        MeetingTemplatesSection(),
        DiarizationSection(),
      ],
    );
  }
}
