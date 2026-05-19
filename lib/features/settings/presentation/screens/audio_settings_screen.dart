import 'package:control_center/features/settings/presentation/screens/settings_page.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/user/audio_sections.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Settings → You → Audio: the microphone, dictation behavior, meeting
/// detection and the soundscape's output device — the machine's audio in and
/// out, which belongs to the user (and their hardware) rather than to the
/// server that runs the models.
class AudioSettingsScreen extends StatelessWidget {
  /// Creates an [AudioSettingsScreen].
  const AudioSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SettingsPage(
      title: l10n.settingsAudio,
      subtitle: l10n.settingsAudioDescription,
      sections: const [AudioDevicesSection(), VoiceBehaviorSection()],
    );
  }
}
