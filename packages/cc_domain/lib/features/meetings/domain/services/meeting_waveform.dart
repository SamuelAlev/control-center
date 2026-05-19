import 'dart:typed_data';

/// Pure DSP helpers for the meeting playback waveform. No Flutter / dart:io deps
/// so they unit-test cleanly and can run inside an isolate (`compute`).

/// Mixes several mono tracks (each normalized to `[-1, 1]`) down to a single
/// mono track by summing sample-for-sample and hard-clipping to `[-1, 1]`.
///
/// The output length is the longest input track; shorter tracks contribute
/// silence past their end. Used to fold a meeting's `me.wav` (mic) and
/// `them.wav` (system audio) into one playable stream. Empty/absent tracks are
/// skipped; returns an empty list when there is nothing to mix.
Float32List mixTracksToMono(List<Float32List> tracks) {
  final present = tracks.where((t) => t.isNotEmpty).toList(growable: false);
  if (present.isEmpty) {
    return Float32List(0);
  }
  if (present.length == 1) {
    return present.first;
  }
  var length = 0;
  for (final t in present) {
    if (t.length > length) {
      length = t.length;
    }
  }
  final out = Float32List(length);
  for (final t in present) {
    final n = t.length;
    for (var i = 0; i < n; i++) {
      final v = out[i] + t[i];
      out[i] = v > 1.0
          ? 1.0
          : v < -1.0
              ? -1.0
              : v;
    }
  }
  return out;
}

/// Downsamples [samples] to [bucketCount] peak-amplitude buckets in `[0, 1]`,
/// suitable for drawing a waveform bar chart.
///
/// Each bucket holds the maximum absolute amplitude over its slice of the
/// signal; the whole set is then normalized so the loudest bucket is `1.0`
/// (a flat-but-quiet recording still renders visibly). Returns an empty list
/// for empty input or a non-positive [bucketCount].
List<double> peakBuckets(Float32List samples, int bucketCount) {
  if (samples.isEmpty || bucketCount <= 0) {
    return const [];
  }
  final n = samples.length;
  final buckets = List<double>.filled(bucketCount, 0);
  var maxPeak = 0.0;
  for (var b = 0; b < bucketCount; b++) {
    final start = (b * n) ~/ bucketCount;
    var end = ((b + 1) * n) ~/ bucketCount;
    if (end <= start) {
      end = start + 1; // guarantee at least one sample per bucket
    }
    var peak = 0.0;
    for (var i = start; i < end && i < n; i++) {
      final a = samples[i].abs();
      if (a > peak) {
        peak = a;
      }
    }
    buckets[b] = peak;
    if (peak > maxPeak) {
      maxPeak = peak;
    }
  }
  if (maxPeak > 0) {
    for (var b = 0; b < bucketCount; b++) {
      buckets[b] = buckets[b] / maxPeak;
    }
  }
  return buckets;
}
