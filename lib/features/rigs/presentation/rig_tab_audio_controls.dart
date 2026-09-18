import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/infrastructure/audio/audio_input_settings.dart';
import 'package:control_center/core/infrastructure/audio/audio_output_settings.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:record/record.dart';

/// Ephemeral media choices and live state for one editor-tab instance.
///
/// The provider family is keyed by the tab object itself. [Object] keeps this
/// feature independent of the editor implementation while preserving identity
/// semantics: two tabs watching the same machine still own separate devices and
/// mute state.
class RigTabAudioState {
  /// Creates per-tab audio state.
  const RigTabAudioState({
    this.outputEnabled = true,
    this.outputPlaying = false,
    this.microphoneEnabled = false,
    this.outputDeviceName,
    this.inputDeviceId,
  });

  /// Whether the tab has requested guest audio playback.
  final bool outputEnabled;

  /// Whether the output player is currently rendering audio.
  final bool outputPlaying;

  /// Whether this tab is requesting microphone capture.
  final bool microphoneEnabled;

  /// Selected output device, or null for the system default.
  final String? outputDeviceName;

  /// Selected input device, or null for the system default.
  final String? inputDeviceId;
}

/// Mutates the audio state owned by one tab identity.
class RigTabAudioNotifier extends Notifier<RigTabAudioState> {
  /// Creates a notifier for [tabKey].
  RigTabAudioNotifier(this.tabKey);

  /// Identity key of the tab that owns this state.
  final Object tabKey;

  @override
  RigTabAudioState build() {
    return RigTabAudioState(
      outputDeviceName: ref.read(audioOutputDeviceProvider),
      inputDeviceId: ref.read(audioInputDeviceProvider),
    );
  }

  /// Enables or mutes guest audio for this tab.
  void setOutputEnabled(bool value) {
    state = RigTabAudioState(
      outputEnabled: value,
      outputPlaying: value && state.outputPlaying,
      microphoneEnabled: state.microphoneEnabled,
      outputDeviceName: state.outputDeviceName,
      inputDeviceId: state.inputDeviceId,
    );
  }

  /// Records whether the output player is actively rendering audio.
  void setOutputPlaying(bool value) {
    if (state.outputPlaying == value) {
      return;
    }
    state = RigTabAudioState(
      outputEnabled: state.outputEnabled,
      outputPlaying: value,
      microphoneEnabled: state.microphoneEnabled,
      outputDeviceName: state.outputDeviceName,
      inputDeviceId: state.inputDeviceId,
    );
  }

  /// Enables or suppresses microphone capture for this tab.
  void setMicrophoneEnabled(bool value) {
    state = RigTabAudioState(
      outputEnabled: state.outputEnabled,
      outputPlaying: state.outputPlaying,
      microphoneEnabled: value,
      outputDeviceName: state.outputDeviceName,
      inputDeviceId: state.inputDeviceId,
    );
  }

  /// Selects the output device; null uses the system default.
  void setOutputDeviceName(String? value) {
    state = RigTabAudioState(
      outputEnabled: state.outputEnabled,
      outputPlaying: state.outputPlaying,
      microphoneEnabled: state.microphoneEnabled,
      outputDeviceName: value,
      inputDeviceId: state.inputDeviceId,
    );
  }

  /// Selects the input device; null uses the system default.
  void setInputDeviceId(String? value) {
    state = RigTabAudioState(
      outputEnabled: state.outputEnabled,
      outputPlaying: state.outputPlaying,
      microphoneEnabled: state.microphoneEnabled,
      outputDeviceName: state.outputDeviceName,
      inputDeviceId: value,
    );
  }
}

/// Ephemeral audio state keyed by an editor tab's identity.

final rigTabAudioProvider = NotifierProvider.family
    .autoDispose<RigTabAudioNotifier, RigTabAudioState, Object>(
      RigTabAudioNotifier.new,
    );

/// Right-click rows shared by Messaging and PR rig tabs.
List<CcMenuItem> rigTabAudioMenuItems({
  required BuildContext context,
  required WidgetRef ref,
  required Object tabKey,
  required bool supportsOutput,
  required bool supportsMicrophone,
}) {
  final l10n = AppLocalizations.of(context);
  final state = ref.read(rigTabAudioProvider(tabKey));
  final notifier = ref.read(rigTabAudioProvider(tabKey).notifier);
  final outputs =
      ref.read(audioOutputDevicesProvider).asData?.value ??
      const <AudioDevice>[];
  final inputs =
      ref.read(audioInputDevicesProvider).asData?.value ??
      const <InputDevice>[];
  final selectableOutputs = outputs
      .where((device) => device.name.isNotEmpty && device.name != 'auto')
      .toList();

  return [
    CcMenuItem(
      label: state.outputEnabled ? l10n.rigAudioMute : l10n.rigAudioListen,
      icon: state.outputEnabled ? AppIcons.volumeOff : AppIcons.volume2,
      selected: state.outputEnabled,
      enabled: supportsOutput,
      onSelected: () => notifier.setOutputEnabled(!state.outputEnabled),
    ),
    CcMenuItem(
      label: l10n.meetingRecordMic,
      icon: state.microphoneEnabled ? AppIcons.micOff : AppIcons.mic,
      selected: state.microphoneEnabled,
      enabled: supportsMicrophone,
      onSelected: () => notifier.setMicrophoneEnabled(!state.microphoneEnabled),
    ),
    const CcMenuItem.divider(),
    CcMenuItem.submenu(
      label: l10n.audioOutput,
      icon: AppIcons.volume2,
      children: [
        CcMenuItem(
          label: l10n.systemDefault,
          selected: state.outputDeviceName == null,
          onSelected: () => notifier.setOutputDeviceName(null),
        ),
        for (final device in selectableOutputs)
          CcMenuItem(
            label: device.description,
            selected: state.outputDeviceName == device.name,
            onSelected: () => notifier.setOutputDeviceName(device.name),
          ),
      ],
    ),
    CcMenuItem.submenu(
      label: l10n.audioInput,
      icon: AppIcons.mic,
      children: [
        CcMenuItem(
          label: l10n.systemDefault,
          selected: state.inputDeviceId == null,
          onSelected: () => notifier.setInputDeviceId(null),
        ),
        for (final device in inputs)
          CcMenuItem(
            label: device.label,
            selected: state.inputDeviceId == device.id,
            onSelected: () => notifier.setInputDeviceId(device.id),
          ),
      ],
    ),
  ];
}

/// Live speaker/microphone controls rendered beside a rig tab's label.
class RigTabAudioIndicators extends ConsumerWidget {
  /// Creates live media indicators for [tabKey].
  const RigTabAudioIndicators({
    super.key,
    required this.tabKey,
    required this.color,
    required this.supportsOutput,
    required this.supportsMicrophone,
  });

  /// Identity key of the tab whose state is displayed.
  final Object tabKey;

  /// Resolved tab-label color.
  final Color color;

  /// Whether this rig surface exposes guest audio output.
  final bool supportsOutput;

  /// Whether this rig surface accepts viewer microphone input.
  final bool supportsMicrophone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(rigTabAudioProvider(tabKey));
    // Prime both lists while the rig tab is mounted so its first context-menu
    // open has real device choices rather than a system-default-only snapshot.
    ref.watch(audioOutputDevicesProvider);
    ref.watch(audioInputDevicesProvider);
    final notifier = ref.read(rigTabAudioProvider(tabKey).notifier);
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (supportsOutput)
          _TabMediaButton(
            icon: state.outputEnabled ? AppIcons.volume2 : AppIcons.volumeOff,
            color: color,
            tooltip: state.outputEnabled
                ? l10n.rigAudioMute
                : l10n.rigAudioListen,
            onPressed: () => notifier.setOutputEnabled(!state.outputEnabled),
          ),
        if (supportsOutput && supportsMicrophone) const SizedBox(width: 2),
        if (supportsMicrophone)
          _TabMediaButton(
            icon: state.microphoneEnabled ? AppIcons.mic : AppIcons.micOff,
            color: color,
            tooltip: l10n.meetingRecordMic,
            onPressed: () =>
                notifier.setMicrophoneEnabled(!state.microphoneEnabled),
          ),
      ],
    );
  }
}

class _TabMediaButton extends StatelessWidget {
  const _TabMediaButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return CcTooltip(
      message: tooltip,
      child: SizedBox(
        width: 18,
        height: 18,
        child: CcTappable(
          onPressed: onPressed,
          semanticLabel: tooltip,
          borderRadius: BorderRadius.circular(3),
          builder: (context, states) => DecoratedBox(
            decoration: BoxDecoration(
              color: states.contains(WidgetState.hovered)
                  ? t.hover
                  : const Color(0x00000000),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Center(child: Icon(icon, size: 13, color: color)),
          ),
        ),
      ),
    );
  }
}
