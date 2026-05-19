import 'package:control_center/features/settings/presentation/screens/settings_page.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/diarization_section.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/voice_section.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Settings → Server → Voice models: the speech and diarization models the
/// connected `cc_server` hosts. Strictly server-scoped — the models are
/// host-owned assets, downloaded to and run on the server. The input-side
/// settings (microphone, dictation, meeting detection) live under You → Voice
/// input; meeting-note templates live under Workspace → General.
class VoiceMeetingsSettingsScreen extends StatelessWidget {
  /// Creates a [VoiceMeetingsSettingsScreen].
  const VoiceMeetingsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SettingsPage(
      title: l10n.settingsVoiceModels,
      subtitle: l10n.voiceAndMeetingsSettingsDescription,
      sections: const [VoiceSection(), DiarizationSection()],
    );
  }
}
