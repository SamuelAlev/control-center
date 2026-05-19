import 'dart:io';
import 'dart:typed_data';

import 'package:cc_domain/features/meetings/domain/services/meeting_waveform.dart';
import 'package:cc_infra/src/util/wav_io.dart';
import 'package:path/path.dart' as p;

/// A playable, drawable rendering of a meeting's retained audio: a single mixed
/// mono WAV on disk plus a downsampled waveform and total duration for the
/// scrubber UI.
class MeetingAudioClip {
  /// Creates a [MeetingAudioClip].
  const MeetingAudioClip({
    required this.playablePath,
    required this.waveform,
    required this.durationMs,
  });

  /// On-disk path to the mixed mono WAV that the player should open.
  final String playablePath;

  /// Per-bucket peak amplitudes in `[0, 1]` (see [peakBuckets]).
  final List<double> waveform;

  /// Total duration in milliseconds.
  final int durationMs;
}

/// The argument to [loadMeetingAudioClip] (a single value so it can cross an
/// isolate boundary via `compute`).
class MeetingAudioRequest {
  /// Creates a [MeetingAudioRequest].
  const MeetingAudioRequest({required this.audioDirPath, this.buckets = 512});

  /// The meeting's `audioPath` directory (holds `me.wav` / `them.wav`).
  final String audioDirPath;

  /// Number of waveform buckets to produce.
  final int buckets;
}

/// Loads (and caches) a meeting's mixed playback clip from its retained
/// per-channel WAVs.
///
/// Folds `me.wav` (mic) and `them.wav` (system audio) into a single
/// `mixed.wav` in the same directory — reusing an existing mix when present —
/// then downsamples it for the waveform. Returns null when the directory has no
/// usable audio. Pure file IO + DSP, so it is safe to run via `compute`.
Future<MeetingAudioClip?> loadMeetingAudioClip(MeetingAudioRequest req) async {
  final dir = Directory(req.audioDirPath);
  if (!dir.existsSync()) {
    return null;
  }
  final mixedPath = p.join(req.audioDirPath, 'mixed.wav');
  final mePath = p.join(req.audioDirPath, 'me.wav');
  final themPath = p.join(req.audioDirPath, 'them.wav');

  // Reuse a previously-materialized mix if it is at least as new as its sources.
  final mixedFile = File(mixedPath);
  if (mixedFile.existsSync() && _isFresh(mixedFile, [mePath, themPath])) {
    final mixed = await readWavToFloat32(mixedPath);
    if (mixed.samples.isEmpty) {
      return null;
    }
    return MeetingAudioClip(
      playablePath: mixedPath,
      waveform: peakBuckets(mixed.samples, req.buckets),
      durationMs: _durationMs(mixed.samples.length, mixed.sampleRate),
    );
  }

  final me = await readWavToFloat32(mePath);
  final them = File(themPath).existsSync()
      ? await readWavToFloat32(themPath)
      : WavData(samples: Float32List(0), sampleRate: 16000);
  final mixedSamples = mixTracksToMono([me.samples, them.samples]);
  if (mixedSamples.isEmpty) {
    return null;
  }
  final sampleRate = me.samples.isNotEmpty ? me.sampleRate : them.sampleRate;
  await writeMonoWav(mixedPath, mixedSamples, sampleRate: sampleRate);
  return MeetingAudioClip(
    playablePath: mixedPath,
    waveform: peakBuckets(mixedSamples, req.buckets),
    durationMs: _durationMs(mixedSamples.length, sampleRate),
  );
}

int _durationMs(int sampleCount, int sampleRate) =>
    sampleRate <= 0 ? 0 : (sampleCount * 1000) ~/ sampleRate;

bool _isFresh(File mixed, List<String> sources) {
  final mixedAt = mixed.lastModifiedSync();
  for (final s in sources) {
    final f = File(s);
    if (f.existsSync() && f.lastModifiedSync().isAfter(mixedAt)) {
      return false;
    }
  }
  return true;
}
