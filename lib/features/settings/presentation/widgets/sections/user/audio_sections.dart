// You → Audio: the machine's audio in and out — which microphone this machine
// uses and which output device carries every sound the app makes — plus how
// the composer's dictation behaves and whether meetings are detected
// automatically. The transcription/diarization MODELS are server-owned assets
// and live under Settings → Server → Voice models.
library;

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/infrastructure/speech/dictation_controller.dart';
import 'package:control_center/features/meetings/providers/meeting_auto_detect_provider.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/general/settings_shared.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/audio_input_row.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/audio_output_row.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The audio hardware this machine uses: the microphone it captures from
/// (with the live mic test) and the output device EVERY app sound plays
/// through — notification chimes, the soundscape, meeting playback and a
/// rig's audio lane alike.
///
/// Both choices are **device-scoped**: they name this machine's hardware
/// (device ids and labels do not exist on another computer), so they stay in
/// local storage despite living on a You page — the You group is where the
/// audio settings are filed, not a claim that the selections roam.
///
/// The output row is desktop-only by construction — the web player cannot
/// choose an output device (the browser routes audio), so it does not render
/// there at all rather than showing a picker that silently does nothing.
class AudioDevicesSection extends StatelessWidget {
  /// Creates an [AudioDevicesSection].
  const AudioDevicesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SectionCard(
      label: l10n.audioDevicesSection,
      child: Column(
        children: [
          const AudioInputRow(),
          if (AudioOutputRow.isSupported) ...[
            const SizedBox(height: 8),
            const AudioOutputRow(),
          ],
        ],
      ),
    );
  }
}

/// Voice behaviors that follow the user: the composer dictation's push-to-talk
/// mode, and whether meetings are detected automatically.
class VoiceBehaviorSection extends ConsumerWidget {
  /// Creates a [VoiceBehaviorSection].
  const VoiceBehaviorSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final holdToTalk = ref.watch(dictationHoldToTalkProvider);
    final autoDetect = ref.watch(meetingAutoDetectEnabledProvider);

    return SectionCard(
      label: l10n.voiceInputBehaviorSection,
      child: Column(
        children: [
          SettingsRow(
            icon: AppIcons.mic,
            title: l10n.dictationHoldToTalkTitle,
            subtitle: l10n.dictationHoldToTalkDescription,
            trailing: CcSwitch(
              value: holdToTalk,
              onChanged: (value) => ref
                  .read(dictationHoldToTalkProvider.notifier)
                  .setHoldToTalk(hold: value),
              semanticLabel: l10n.dictationHoldToTalkTitle,
            ),
          ),
          const SizedBox(height: 8),
          SettingsRow(
            icon: AppIcons.radio,
            title: l10n.meetingAutoDetect,
            subtitle: l10n.meetingAutoDetectDescription,
            trailing: CcSwitch(
              value: autoDetect,
              onChanged: (v) => ref
                  .read(meetingAutoDetectEnabledProvider.notifier)
                  .setEnabled(v),
              semanticLabel: l10n.meetingAutoDetect,
            ),
          ),
        ],
      ),
    );
  }
}
