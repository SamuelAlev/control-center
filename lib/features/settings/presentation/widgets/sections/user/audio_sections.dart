// You → Audio: the machine's audio in and out — which microphone this machine
// uses, how the composer's dictation behaves, whether meetings are detected
// automatically, and which output device carries the soundscape. The
// transcription/diarization MODELS are server-owned assets and live under
// Settings → Server → Voice models.
library;

import 'dart:async';

import 'package:cc_domain/core/domain/notifications/notification_sound.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/infrastructure/audio/audio_output_settings.dart';
import 'package:control_center/core/infrastructure/speech/dictation_controller.dart';
import 'package:control_center/features/meetings/providers/meeting_auto_detect_provider.dart';
import 'package:control_center/features/settings/presentation/widgets/scope_badge.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/general/settings_shared.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/audio_input_row.dart';
import 'package:control_center/features/settings/settings_nav.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';

/// The microphone this machine captures from, plus the live mic test.
///
/// **Device-scoped**: the choice names this machine's hardware (device ids and
/// labels do not exist on another computer), so it stays in local storage and
/// carries a "this device" badge despite living on a You page — the You group
/// is where the input-side settings are filed, not a claim that the mic
/// selection roams.
class AudioInputSection extends StatelessWidget {
  /// Creates an [AudioInputSection].
  const AudioInputSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SectionCard(
      label: l10n.voiceInputMicrophoneSection,
      trailing: const ScopeBadge(SettingScope.device),
      child: const AudioInputRow(),
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
      trailing: const ScopeBadge(SettingScope.user),
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

/// The output device the soundscape plays through.
///
/// **Device-scoped** like the microphone: the selection names this machine's
/// hardware. Desktop-only by construction — the web player cannot choose an
/// output device (the browser routes audio), so the section does not render
/// there at all rather than showing a picker that silently does nothing.
class SoundscapeOutputSection extends ConsumerStatefulWidget {
  /// Creates a [SoundscapeOutputSection].
  const SoundscapeOutputSection({super.key});

  @override
  ConsumerState<SoundscapeOutputSection> createState() =>
      _SoundscapeOutputSectionState();
}

class _SoundscapeOutputSectionState
    extends ConsumerState<SoundscapeOutputSection> {
  /// Sentinel for "use the system default" — the select needs a real value,
  /// while the stored preference uses null for the default (same trick as the
  /// input-device picker).
  static const _systemDefaultId = '__system_default__';

  /// The test-sound player, created lazily on the first Test press so that
  /// merely rendering the section (in the app or in tests) never requires a
  /// native audio backend.
  Player? _testPlayer;

  /// Plays a short chime through the CURRENTLY selected output device — the
  /// point of the button is to verify the choice, so the device is applied to
  /// the test player, not inherited from anything else. Re-pressing restarts
  /// the chime (`open` stops whatever it was playing).
  Future<void> _playTest() async {
    try {
      final player = _testPlayer ??= Player();
      await player.setAudioDevice(
        selectedAudioOutputDevice(ref.read(audioOutputDeviceProvider)),
      );
      await player.open(
        Media('asset:///assets/${NotificationSound.chime.assetPath!}'),
      );
    } on Object catch (e) {
      if (mounted) {
        CcToastScope.of(context).show('$e', variant: CcToastVariant.danger);
      }
    }
  }

  @override
  void dispose() {
    final player = _testPlayer;
    if (player != null) {
      // `dispose()` cannot await; release the native player detached.
      unawaited(() async {
        try {
          await player.dispose();
        } on Object {
          // Already disposed — nothing to do.
        }
      }());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final devicesAsync = ref.watch(audioOutputDevicesProvider);
    final selected = ref.watch(audioOutputDeviceProvider);

    final devices = devicesAsync.asData?.value ?? const <AudioDevice>[];
    final selectable = devices
        .where((d) => d.name.isNotEmpty && d.name != 'auto')
        .toList();
    final selectedKnown =
        selectable.any((d) => d.name == selected) || selected == null;

    final String subtitle;
    if (devicesAsync.isLoading) {
      subtitle = l10n.checkingEllipsis;
    } else if (!selectedKnown) {
      // The stored device is gone (unplugged): say so, and that the default is
      // playing until a new choice is made — never silently pretend it applied.
      subtitle = l10n.soundscapeOutputGone;
    } else if (selected == null) {
      subtitle = l10n.soundscapeOutputDefaultHint;
    } else {
      subtitle = selectable
          .firstWhere((d) => d.name == selected)
          .description;
    }

    return SectionCard(
      label: l10n.soundscapeOutputSection,
      trailing: const ScopeBadge(SettingScope.device),
      child: SettingsRow(
        icon: AppIcons.volume2,
        title: l10n.soundscapeOutputDevice,
        subtitle: subtitle,
        trailing: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: CcSelect<String>(
                  value: selectedKnown && selected != null
                      ? selected
                      : _systemDefaultId,
                  options: [
                    CcSelectOption(
                      value: _systemDefaultId,
                      label: l10n.systemDefault,
                    ),
                    for (final d in selectable)
                      CcSelectOption(value: d.name, label: d.description),
                  ],
                  enabled: !devicesAsync.isLoading,
                  onChanged: (v) => ref
                      .read(audioOutputDeviceProvider.notifier)
                      .setDeviceName(v == _systemDefaultId ? null : v),
                ),
              ),
              const SizedBox(width: 8),
              CcButton(
                onPressed: devicesAsync.isLoading
                    ? null
                    : () => ref.invalidate(audioOutputDevicesProvider),
                variant: CcButtonVariant.secondary,
                icon: AppIcons.refreshCw,
                child: Text(l10n.refresh),
              ),
              const SizedBox(width: 8),
              CcButton(
                onPressed: _playTest,
                variant: CcButtonVariant.secondary,
                icon: AppIcons.play,
                child: Text(l10n.testLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
