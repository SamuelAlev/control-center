import 'dart:async';

import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';

/// Persisted preference for the output device the soundscape plays through.
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
    final saved = _prefs.getString(soundscapeOutputDeviceKey);
    return (saved == null || saved.isEmpty) ? null : saved;
  }

  /// Pass `null` to fall back to the system default output.
  Future<void> setDeviceName(String? name) async {
    if (name == null || name.isEmpty || name == _kAutoDeviceName) {
      await _prefs.remove(soundscapeOutputDeviceKey);
      state = null;
    } else {
      await _prefs.setString(soundscapeOutputDeviceKey, name);
      state = name;
    }
  }
}

/// Provider for the selected soundscape output device name (or null for the
/// system default).
final audioOutputDeviceProvider =
    NotifierProvider<AudioOutputDeviceNotifier, String?>(
      AudioOutputDeviceNotifier.new,
    );

/// libmpv's name for automatic (system default) device selection.
const String _kAutoDeviceName = 'auto';

/// The selected soundscape output device as a media_kit [AudioDevice], or
/// [AudioDevice.auto] for the system default. Playback code applies this
/// directly; only the settings UI needs the null-vs-'auto' distinction.
AudioDevice selectedAudioOutputDevice(String? name) =>
    name == null ? AudioDevice.auto() : AudioDevice(name, '');

/// The output devices this machine can play through, via the libmpv backend.
///
/// The list arrives as an mpv property event shortly after the player forms,
/// so the provider awaits the first non-empty emission and falls back to the
/// player's (possibly still empty) snapshot on timeout. **Desktop-only**: the
/// web player cannot choose an output device (the browser routes audio), so
/// this yields an empty list on web and the settings section hides itself —
/// an honest absence rather than a picker that silently does nothing.
final audioOutputDevicesProvider =
    FutureProvider<List<AudioDevice>>((ref) async {
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
