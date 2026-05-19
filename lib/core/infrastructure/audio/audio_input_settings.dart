import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';

/// Persisted preference for the audio input device used by the mic button.
///
/// Holds the platform-specific [InputDevice.id] of the chosen device, or
/// `null` to indicate "use the system default" (`record` interprets a null
/// [RecordConfig.device] as the OS default mic).
class AudioInputDeviceNotifier extends Notifier<String?> {
  late AppPreferences _prefs;

  @override
  String? build() {
    _prefs = ref.watch(appPreferencesProvider);
    final saved = _prefs.getString(audioInputDeviceIdKey);
    return (saved == null || saved.isEmpty) ? null : saved;
  }

  /// Pass `null` to fall back to the system default.
  Future<void> setDeviceId(String? id) async {
    if (id == null || id.isEmpty) {
      await _prefs.remove(audioInputDeviceIdKey);
      state = null;
    } else {
      await _prefs.setString(audioInputDeviceIdKey, id);
      state = id;
    }
  }
}

/// Provider for the currently selected audio input device id (or null for default).
final audioInputDeviceProvider =
    NotifierProvider<AudioInputDeviceNotifier, String?>(
      AudioInputDeviceNotifier.new,
    );

/// Enumerates available input devices via the `record` plugin.
///
/// Each lookup spins up a short-lived [AudioRecorder] because the plugin
/// only exposes [AudioRecorder.listInputDevices] on an instance. Disposing
/// after the call avoids holding onto a recorder we are not using.
final audioInputDevicesProvider = FutureProvider<List<InputDevice>>((
  ref,
) async {
  final recorder = AudioRecorder();
  try {
    final all = await recorder.listInputDevices();
    return all.where((d) => !_isOutputDevice(d.label)).toList();
  } finally {
    await recorder.dispose();
  }
});

/// Resolves a persisted input-device id against the devices [recorder] reports.
///
/// Returns null when [selectedId] is unset/empty or the device is gone
/// (unplugged USB mic, renamed aggregate device) — both mean "use the OS
/// default", which is what a null [RecordConfig.device] asks for. Every
/// capture path (the mic test, dictation, the meeting recorder) resolves
/// through here so they can never disagree about what "the selected mic" is.
Future<InputDevice?> resolveSelectedInputDevice(
  AudioRecorder recorder,
  String? selectedId,
) async {
  if (selectedId == null || selectedId.isEmpty) {
    return null;
  }
  final devices = await recorder.listInputDevices();
  for (final d in devices) {
    if (d.id == selectedId) {
      return d;
    }
  }
  return null;
}

/// [config] with the persisted input device applied, for capture paths that
/// build their [RecordConfig] once at start (the meeting recorder).
Future<RecordConfig> withSelectedInputDevice(
  AudioRecorder recorder,
  String? selectedId,
  RecordConfig config,
) async {
  final device = await resolveSelectedInputDevice(recorder, selectedId);
  if (device == null) {
    return config;
  }
  // `device` is a sentinel-record parameter in record's copyWith, so a device
  // can be set explicitly (including back to null) — here it is always a
  // resolved, non-null device.
  return config.copyWith(device: (value: device));
}

const _outputKeywords = ['speaker', 'output', 'hdmi', 'display'];

bool _isOutputDevice(String label) {
  final lower = label.toLowerCase();
  return _outputKeywords.any(lower.contains);
}
