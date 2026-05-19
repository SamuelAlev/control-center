import 'dart:async';

import 'package:cc_domain/features/soundscape/domain/entities/soundscape_context.dart';
import 'package:cc_domain/features/soundscape/domain/value_objects/soundscape_tune.dart';
import 'package:cc_domain/features/weather/domain/entities/weather_snapshot.dart';
import 'package:cc_domain/features/weather/domain/repositories/weather_repository.dart';
import 'package:cc_infra/src/soundscape/soundscape_context_builder.dart';
import 'package:cc_infra/src/soundscape/soundscape_session.dart';
import 'package:cc_natives/cc_natives.dart' show Mp3Encoder;

/// Owns the server-side generative soundscape sessions and streams their audio
/// to clients.
///
/// Sessions are keyed by `(workspaceId, mood)` and SHARED: any number of
/// listeners on the same key hear one generative session (per-listener volume is
/// a client concern), so the server renders each distinct scene once. Weather is
/// per-workspace (the server's location), so mood is the only per-listener
/// dimension — which is exactly why weather/daypart adapt *within* a session
/// (via [SoundscapeSession.updateContext] ramps) rather than by re-keying it.
///
/// `liblame_ffi` is a REQUIRED native on every platform — `cc_server`'s boot
/// preflight refuses to start without it — so there is no "audio unavailable"
/// mode: [streamFor] lets `LameUnavailable` propagate rather than quietly 404ing
/// a feature the host is supposed to have. It still returns null for the genuine
/// behavioural cases (the hub is disposed, or the [maxSessions] cap is reached),
/// which the routes render as 404.
class SoundscapeHub {
  /// Creates a hub reading location/weather from [weather].
  ///
  /// [encoderLibraryPaths] are the caller-resolved candidate paths for the
  /// libmp3lame FFI dylib (dev app-support / release bundle); pass
  /// `CcPaths(dataDir).lameFfiDylibCandidatePaths()`. Without them the encoder
  /// only finds a release-bundled dylib, so audio is unavailable in dev.
  SoundscapeHub({
    required WeatherRepository weather,
    this.sampleRate = 48000,
    this.maxSessions = 4,
    List<String> encoderLibraryPaths = const [],
    SoundscapeContextBuilder contextBuilder = const SoundscapeContextBuilder(),
  }) : _weather = weather,
       _encoderLibraryPaths = encoderLibraryPaths,
       _contextBuilder = contextBuilder;

  /// Render sample rate in Hz.
  final int sampleRate;

  /// Cap on concurrent distinct `(workspaceId, mood)` render sessions (each is a
  /// synth + MP3 encoder). Listeners beyond this share existing sessions; a new
  /// distinct scene past the cap is refused (the stream route 404s → "busy").
  final int maxSessions;

  final WeatherRepository _weather;
  final SoundscapeContextBuilder _contextBuilder;
  final List<String> _encoderLibraryPaths;

  final Map<String, SoundscapeSession> _sessions = {};
  final Map<String, StreamSubscription<WeatherSnapshot?>> _weatherSubs = {};
  final Map<String, WeatherSnapshot?> _latestWeather = {};

  /// The listener tune per `(workspaceId, mood)` key. Kept across session
  /// restarts (server lifetime) so re-opening a stream keeps the last puck
  /// position.
  final Map<String, SoundscapeTune> _tunes = {};
  Timer? _daypartTimer;
  bool _disposed = false;

  String _key(String workspaceId, String mood) => '$workspaceId|$mood';

  SoundscapeMood _parseMood(String mood) => SoundscapeMood.values.firstWhere(
    (m) => m.name == mood,
    orElse: () => SoundscapeMood.focus,
  );

  /// Opens the continuous MP3 byte stream for `(workspaceId, mood)`, joining or
  /// lazily creating the shared session.
  ///
  /// Returns null when the hub is disposed or the [maxSessions] cap is reached
  /// (→ the route 404s). Throws `LameUnavailable` when the required MP3 encoder
  /// native cannot be loaded — a broken install, not a 404.
  Stream<List<int>>? streamFor({
    required String workspaceId,
    required String mood,
  }) {
    if (_disposed) {
      return null;
    }
    final key = _key(workspaceId, mood);
    var session = _sessions[key];
    if (session == null) {
      if (_sessions.length >= maxSessions) {
        return null;
      }
      final encoder = Mp3Encoder.create(
        sampleRate: sampleRate,
        explicitPaths: _encoderLibraryPaths,
      );
      final context = _contextBuilder.build(
        mood: _parseMood(mood),
        weather: _latestWeather[workspaceId],
        now: DateTime.now(),
      );
      session = SoundscapeSession(
        key: key,
        context: context,
        sampleRate: sampleRate,
        encoder: encoder,
        onEmpty: () => _reap(key, workspaceId),
      );
      final tune = _tunes[key];
      if (tune != null) {
        session.updateTune(tune);
      }
      _sessions[key] = session;
      _ensureWeatherPush(workspaceId);
      _ensureDaypartTimer();
    }
    return session.attach();
  }

  /// The live HLS playlist for an already-running `(workspaceId, mood)` session,
  /// or null when none is running. (HLS piggybacks on a session created by a
  /// progressive-stream listener; standalone HLS-only sessions are a follow-up.)
  String? playlistFor({
    required String workspaceId,
    required String mood,
    required String segmentQuery,
  }) => _sessions[_key(workspaceId, mood)]?.playlist(segmentQuery);

  /// The bytes of HLS segment [index] for a running session, or null.
  List<int>? segmentFor({
    required String workspaceId,
    required String mood,
    required int index,
  }) => _sessions[_key(workspaceId, mood)]?.segment(index);

  /// Sets the listener's tune-pad position for `(workspaceId, mood)`: stored
  /// for future sessions and glided live into a running one.
  void setTune({
    required String workspaceId,
    required String mood,
    required SoundscapeTune tune,
  }) {
    final key = _key(workspaceId, mood);
    _tunes[key] = tune;
    _sessions[key]?.updateTune(tune);
  }

  /// Streams display-only scene metadata (mood + resolved weather/daypart + a
  /// human label) for the mini-player. Re-emits as the weather refreshes; the
  /// audio adapts independently within its session.
  Stream<Map<String, dynamic>> watchScene({
    required String workspaceId,
    required String mood,
  }) async* {
    final moodEnum = _parseMood(mood);
    unawaited(_safeRefresh(workspaceId));
    await for (final snapshot in _weather.watchCurrent(workspaceId)) {
      _latestWeather[workspaceId] = snapshot;
      final context = _contextBuilder.build(
        mood: moodEnum,
        weather: snapshot,
        now: DateTime.now(),
      );
      yield _sceneMap(workspaceId, mood, context, snapshot);
    }
  }

  Map<String, dynamic> _sceneMap(
    String workspaceId,
    String mood,
    SoundscapeContext context,
    WeatherSnapshot? snapshot,
  ) {
    final tune = _tunes[_key(workspaceId, mood)] ?? SoundscapeTune.neutral;
    return {
      'mood': mood,
      'weather': context.weather.name,
      'daypart': context.daypart.name,
      'is_day': context.isDay,
      'temperature_celsius': context.temperatureCelsius,
      'location_label': snapshot?.locationLabel,
      'name': _sceneName(context),
      'tune_energy': tune.energy,
      'tune_brightness': tune.brightness,
    };
  }

  String _sceneName(SoundscapeContext c) {
    final weather = switch (c.weather) {
      SoundscapeWeather.clear => 'Clear',
      SoundscapeWeather.clouds => 'Cloudy',
      SoundscapeWeather.rain => 'Rainy',
      SoundscapeWeather.snow => 'Snowy',
      SoundscapeWeather.fog => 'Foggy',
      SoundscapeWeather.storm => 'Stormy',
      SoundscapeWeather.wind => 'Windy',
    };
    final daypart = switch (c.daypart) {
      SoundscapeDaypart.dawn => 'dawn',
      SoundscapeDaypart.morning => 'morning',
      SoundscapeDaypart.day => 'day',
      SoundscapeDaypart.dusk => 'dusk',
      SoundscapeDaypart.night => 'night',
    };
    return '$weather $daypart';
  }

  void _ensureWeatherPush(String workspaceId) {
    if (_weatherSubs.containsKey(workspaceId)) {
      return;
    }
    _weatherSubs[workspaceId] = _weather.watchCurrent(workspaceId).listen((
      snapshot,
    ) {
      _latestWeather[workspaceId] = snapshot;
      _retargetWorkspace(workspaceId, snapshot);
    });
    unawaited(_safeRefresh(workspaceId));
  }

  void _ensureDaypartTimer() {
    _daypartTimer ??= Timer.periodic(const Duration(minutes: 5), (_) {
      final now = DateTime.now();
      for (final entry in _sessions.entries) {
        final sep = entry.key.indexOf('|');
        if (sep < 0) {
          continue;
        }
        final workspaceId = entry.key.substring(0, sep);
        final mood = _parseMood(entry.key.substring(sep + 1));
        entry.value.updateContext(
          _contextBuilder.build(
            mood: mood,
            weather: _latestWeather[workspaceId],
            now: now,
          ),
        );
      }
    });
  }

  void _retargetWorkspace(String workspaceId, WeatherSnapshot? snapshot) {
    final now = DateTime.now();
    final prefix = '$workspaceId|';
    for (final entry in _sessions.entries) {
      if (!entry.key.startsWith(prefix)) {
        continue;
      }
      final mood = _parseMood(entry.key.substring(prefix.length));
      entry.value.updateContext(
        _contextBuilder.build(mood: mood, weather: snapshot, now: now),
      );
    }
  }

  Future<void> _safeRefresh(String workspaceId) async {
    try {
      await _weather.refreshNow(workspaceId);
    } catch (_) {
      // Best-effort; the sweep will retry.
    }
  }

  void _reap(String key, String workspaceId) {
    final session = _sessions.remove(key);
    unawaited(session?.dispose());
    // Drop the weather subscription when the workspace has no sessions left.
    final prefix = '$workspaceId|';
    final stillActive = _sessions.keys.any((k) => k.startsWith(prefix));
    if (!stillActive) {
      _weatherSubs.remove(workspaceId)?.cancel();
    }
    if (_sessions.isEmpty) {
      _daypartTimer?.cancel();
      _daypartTimer = null;
    }
  }

  /// Tears down every session, subscription and timer.
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _daypartTimer?.cancel();
    _daypartTimer = null;
    for (final sub in _weatherSubs.values) {
      await sub.cancel();
    }
    _weatherSubs.clear();
    for (final session in _sessions.values.toList()) {
      await session.dispose();
    }
    _sessions.clear();
    _tunes.clear();
  }
}
