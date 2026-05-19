import 'dart:async';

import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';

/// Persisted preference for the output device **every** app sound plays
/// through — notification chimes, the soundscape, meeting playback and a rig's
/// audio lane alike. It is one machine-level choice ("where does this computer
/// make noise"), not a per-surface one: a person who moved audio to their
/// headphones meant all of it, and a notification that stayed on the built-in
/// speakers is indistinguishable from a broken setting.
///
/// Holds the media_kit [AudioDevice.name] (libmpv's stable device id, e.g.
/// `coreaudio/12345`), or `null` for "system default" — which maps to mpv's
/// `auto` device. **Device-scoped** like the microphone choice: the id names
/// this machine's hardware and means nothing on another computer, so it stays
/// in local storage and never joins the synced user preferences.
class AudioOutputDeviceNotifier extends Notifier<String?> {
  late AppPreferences _prefs;

  @override
  String? build() {
    _prefs = ref.watch(appPreferencesProvider);
    final saved =
        _prefs.getString(audioOutputDeviceKey) ??
        // Widening the setting must not silently reset it: an install that
        // chose a device back when it only routed the soundscape keeps that
        // choice, now applied to everything.
        _prefs.getString(legacySoundscapeOutputDeviceKey);
    return (saved == null || saved.isEmpty) ? null : saved;
  }

  /// Pass `null` to fall back to the system default output.
  Future<void> setDeviceName(String? name) async {
    await _prefs.remove(legacySoundscapeOutputDeviceKey);
    if (name == null || name.isEmpty || name == _kAutoDeviceName) {
      await _prefs.remove(audioOutputDeviceKey);
      state = null;
    } else {
      await _prefs.setString(audioOutputDeviceKey, name);
      state = name;
    }
  }
}

/// Provider for the selected app-wide output device name (or null for the
/// system default).
final audioOutputDeviceProvider =
    NotifierProvider<AudioOutputDeviceNotifier, String?>(
      AudioOutputDeviceNotifier.new,
    );

/// libmpv's name for automatic (system default) device selection.
const String _kAutoDeviceName = 'auto';

/// The selected output device as a media_kit [AudioDevice], or
/// [AudioDevice.auto] for the system default. Playback code applies this
/// directly; only the settings UI needs the null-vs-'auto' distinction.
AudioDevice selectedAudioOutputDevice(String? name) =>
    name == null ? AudioDevice.auto() : AudioDevice(name, '');

/// Converts a 0..1 preference into media_kit's 0–100 volume scale.
///
/// Every volume the app persists is normalized 0..1 while libmpv's `volume`
/// property is a percentage, and mixing the two is SILENT in the worst way:
/// `setVolume(1.0)` is 1%, which plays but cannot be heard, so it reads as
/// "the sound is broken" rather than "the volume is wrong". One conversion,
/// used by every playback surface.
double mediaKitVolume(double normalized) => normalized.clamp(0.0, 1.0) * 100.0;

/// Routes [player] through the app's chosen output device [name].
///
/// The one place every sound-making surface calls, so "which device" is
/// decided once rather than re-derived per player. **No-op on web**: the
/// browser routes audio and mpv's device API is not there — calling it would
/// throw on a surface that can do nothing about it.
Future<void> applyAppAudioOutput(Player player, String? name) async {
  if (kIsWeb) {
    return;
  }
  await player.setAudioDevice(selectedAudioOutputDevice(name));
}

/// The output devices this machine can play through, via the libmpv backend.
///
/// The list arrives as an mpv property event shortly after the player forms,
/// so the provider awaits the first non-empty emission and falls back to the
/// player's (possibly still empty) snapshot on timeout. **Desktop-only**: the
/// web player cannot choose an output device (the browser routes audio), so
/// this yields an empty list on web and the settings section hides itself —
/// an honest absence rather than a picker that silently does nothing.
final audioOutputDevicesProvider = FutureProvider<List<AudioDevice>>((
  ref,
) async {
  if (kIsWeb) {
    return const <AudioDevice>[];
  }
  final player = Player();
  try {
    return await player.stream.audioDevices
        .firstWhere((devices) => devices.isNotEmpty)
        .timeout(
          const Duration(seconds: 5),
          onTimeout: () => player.state.audioDevices,
        );
  } on Object {
    return const <AudioDevice>[];
  } finally {
    await player.dispose();
  }
});
