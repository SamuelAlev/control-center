import 'dart:async';

import 'package:cc_domain/features/soundscape/domain/entities/soundscape_context.dart';
import 'package:cc_domain/features/weather/domain/entities/weather_snapshot.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _moodKey = 'soundscape_mood';
const _volumeKey = 'soundscape_volume';
const _autoStartKey = 'soundscape_autostart';
const _tuneEnergyKeyPrefix = 'soundscape_tune_energy_';
const _tuneBrightnessKeyPrefix = 'soundscape_tune_brightness_';

/// The client-side, UI-owned soundscape playback state.
///
/// The server owns generation (weather, daypart, and the running mix); the
/// client only decides *whether* it is playing, at *what* mood/volume, and
/// whether a focus session should auto-start it. [playing] is deliberately
/// ephemeral to a single app run — only [mood], [volume], and
/// [autoStartWithFocus] carry over between runs.
class SoundscapeState {
  /// Creates a [SoundscapeState].
  const SoundscapeState({
    required this.playing,
    required this.mood,
    required this.volume,
    required this.autoStartWithFocus,
    required this.tuneEnergy,
    required this.tuneBrightness,
  });

  /// Whether the always-on audio host should currently be streaming.
  final bool playing;

  /// The mood to generate (drives the stream URL + the scene watch).
  final SoundscapeMood mood;

  /// Master volume, 0..1.
  final double volume;

  /// Whether entering focus mode should start playback (and leaving it stop).
  final bool autoStartWithFocus;

  /// Tune-pad X: mellow (0) to energetic (1). Per-mood, persisted.
  final double tuneEnergy;

  /// Tune-pad Y: spacy (0) to bright (1). Per-mood, persisted.
  final double tuneBrightness;

  /// Returns a copy with the given fields replaced.
  SoundscapeState copyWith({
    bool? playing,
    SoundscapeMood? mood,
    double? volume,
    bool? autoStartWithFocus,
    double? tuneEnergy,
    double? tuneBrightness,
  }) {
    return SoundscapeState(
      playing: playing ?? this.playing,
      mood: mood ?? this.mood,
      volume: volume ?? this.volume,
      autoStartWithFocus: autoStartWithFocus ?? this.autoStartWithFocus,
      tuneEnergy: tuneEnergy ?? this.tuneEnergy,
      tuneBrightness: tuneBrightness ?? this.tuneBrightness,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SoundscapeState &&
          runtimeType == other.runtimeType &&
          playing == other.playing &&
          mood == other.mood &&
          volume == other.volume &&
          autoStartWithFocus == other.autoStartWithFocus &&
          tuneEnergy == other.tuneEnergy &&
          tuneBrightness == other.tuneBrightness;

  @override
  int get hashCode => Object.hash(
    playing,
    mood,
    volume,
    autoStartWithFocus,
    tuneEnergy,
    tuneBrightness,
  );
}

/// Persists the user's soundscape *preferences* (mood, volume, auto-start) —
/// never the live `playing` flag, which lives for exactly one app run.
class _SoundscapeStorage {
  const _SoundscapeStorage(this._prefs);
  final AppPreferences _prefs;

  SoundscapeMood get mood {
    final raw = _prefs.getString(_moodKey);
    for (final m in SoundscapeMood.values) {
      if (m.name == raw) {
        return m;
      }
    }
    return SoundscapeMood.focus;
  }

  double get volume => (_prefs.getDouble(_volumeKey) ?? 0.6).clamp(0.0, 1.0);

  bool get autoStartWithFocus => _prefs.getBool(_autoStartKey) ?? true;

  double tuneEnergy(SoundscapeMood mood) =>
      (_prefs.getDouble('$_tuneEnergyKeyPrefix${mood.name}') ?? 0.5).clamp(
        0.0,
        1.0,
      );

  double tuneBrightness(SoundscapeMood mood) =>
      (_prefs.getDouble('$_tuneBrightnessKeyPrefix${mood.name}') ?? 0.5).clamp(
        0.0,
        1.0,
      );

  Future<void> saveMood(SoundscapeMood mood) =>
      _prefs.setString(_moodKey, mood.name);

  Future<void> saveVolume(double volume) =>
      _prefs.setDouble(_volumeKey, volume);

  Future<void> saveAutoStart({required bool value}) =>
      _prefs.setBool(_autoStartKey, value: value);

  Future<void> saveTune(
    SoundscapeMood mood, {
    required double energy,
    required double brightness,
  }) async {
    await _prefs.setDouble('$_tuneEnergyKeyPrefix${mood.name}', energy);
    await _prefs.setDouble('$_tuneBrightnessKeyPrefix${mood.name}', brightness);
  }
}

/// Owns the soundscape playback state. The always-on audio host
/// (`SoundscapeAudioHost`) watches this and re-points its player whenever
/// [SoundscapeState.playing], [SoundscapeState.mood], or
/// [SoundscapeState.volume] change.
class SoundscapeController extends Notifier<SoundscapeState> {
  late _SoundscapeStorage _storage;
  Timer? _tuneDebounce;

  @override
  SoundscapeState build() {
    _storage = _SoundscapeStorage(ref.watch(appPreferencesProvider));
    ref.onDispose(() => _tuneDebounce?.cancel());
    final mood = _storage.mood;
    // Playback never persists across runs — every launch starts stopped.
    return SoundscapeState(
      playing: false,
      mood: mood,
      volume: _storage.volume,
      autoStartWithFocus: _storage.autoStartWithFocus,
      tuneEnergy: _storage.tuneEnergy(mood),
      tuneBrightness: _storage.tuneBrightness(mood),
    );
  }

  /// Starts playback (idempotent).
  void play() {
    if (state.playing) {
      return;
    }
    state = state.copyWith(playing: true);
    // A fresh server session starts at the neutral tune; re-assert ours.
    unawaited(_pushTune());
  }

  /// Stops playback (idempotent).
  void stop() {
    if (!state.playing) {
      return;
    }
    state = state.copyWith(playing: false);
  }

  /// Toggles playback.
  void toggle() {
    if (state.playing) {
      stop();
    } else {
      play();
    }
  }

  /// Switches the mood (persisted). Playback keeps running if it was on — the
  /// audio host re-points to the new mood's stream. The new mood's persisted
  /// tune replaces the old one (tunes are per mood) and is re-asserted on the
  /// server.
  Future<void> setMood(SoundscapeMood mood) async {
    if (mood == state.mood) {
      return;
    }
    state = state.copyWith(
      mood: mood,
      tuneEnergy: _storage.tuneEnergy(mood),
      tuneBrightness: _storage.tuneBrightness(mood),
    );
    unawaited(_pushTune());
    await _storage.saveMood(mood);
  }

  /// Moves the tune-pad puck. State updates immediately (the puck follows the
  /// finger); persistence and the server push are debounced so a drag doesn't
  /// flood the RPC channel — the composer glides anyway.
  void setTune({required double energy, required double brightness}) {
    final e = energy.clamp(0.0, 1.0);
    final b = brightness.clamp(0.0, 1.0);
    if (e == state.tuneEnergy && b == state.tuneBrightness) {
      return;
    }
    state = state.copyWith(tuneEnergy: e, tuneBrightness: b);
    _tuneDebounce?.cancel();
    _tuneDebounce = Timer(const Duration(milliseconds: 150), () {
      unawaited(
        _storage.saveTune(
          state.mood,
          energy: state.tuneEnergy,
          brightness: state.tuneBrightness,
        ),
      );
      unawaited(_pushTune());
    });
  }

  /// Best-effort push of the current tune to the server (no-op when offline —
  /// the tune is re-asserted on the next play/mood change anyway).
  Future<void> _pushTune() async {
    try {
      await ref.read(rpcClientProvider).call('soundscape.setTune', {
        'mood': state.mood.name,
        'energy': state.tuneEnergy,
        'brightness': state.tuneBrightness,
      });
    } on Object {
      // Disconnected or the server predates the op — the audio simply keeps
      // its current tune.
    }
  }

  /// Sets the master volume, clamped to 0..1 (persisted).
  Future<void> setVolume(double volume) async {
    final clamped = volume.clamp(0.0, 1.0);
    if (clamped == state.volume) {
      return;
    }
    state = state.copyWith(volume: clamped);
    await _storage.saveVolume(clamped);
  }

  /// Sets whether focus mode auto-starts playback (persisted).
  Future<void> setAutoStartWithFocus({required bool value}) async {
    if (value == state.autoStartWithFocus) {
      return;
    }
    state = state.copyWith(autoStartWithFocus: value);
    await _storage.saveAutoStart(value: value);
  }
}

/// Provides the current [SoundscapeState] and its [SoundscapeController].
final soundscapeProvider =
    NotifierProvider<SoundscapeController, SoundscapeState>(
      SoundscapeController.new,
    );

/// Live display metadata for the current mood's scene (`soundscape.watchScene`).
///
/// Each emission is the raw server map — `{mood, weather, daypart, is_day,
/// temperature_celsius, location_label?, name}`. The transport auto-injects the
/// workspace id, so only `mood` is passed. Re-subscribes when the mood changes.
final soundscapeSceneProvider =
    StreamProvider.autoDispose<Map<String, dynamic>>((ref) {
      final mood = ref.watch(soundscapeProvider.select((s) => s.mood));
      final client = ref.watch(rpcClientProvider);
      return client.subscribe('soundscape.watchScene', {'mood': mood.name});
    });

/// Live weather snapshot for the active workspace, or null when there is no
/// active workspace / none has been fetched yet.
final weatherProvider = StreamProvider.autoDispose<WeatherSnapshot?>((ref) {
  final ws = ref.watch(activeWorkspaceIdProvider);
  if (ws == null) {
    return Stream<WeatherSnapshot?>.value(null);
  }
  return ref.watch(weatherRepositoryProvider).watchCurrent(ws);
});
