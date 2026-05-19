import 'dart:math' as math;
import 'dart:typed_data';

/// Result of an [AecDelayEstimator] measurement.
class AecDelayEstimate {
  /// Creates an estimate with the measured [lagMs] and its [confidence].
  const AecDelayEstimate({required this.lagMs, required this.confidence});

  /// How far the far-end (loopback) LEADS the near-end (mic) on the shared
  /// submission timeline, in milliseconds.
  ///
  /// - **Positive** → the loopback reference arrives before the mic echo it
  ///   should cancel (good for AEC3; this is the lead we can feed straight to
  ///   `set_stream_delay_ms`).
  /// - **Negative** → the mic echo arrives before its reference (the Core Audio
  ///   process tap is delivering late). AEC3 cannot use a negative delay, so the
  ///   mic must be buffered by `|lagMs|` + margin to restore a positive lead.
  final int lagMs;

  /// Peak normalized cross-correlation at [lagMs] (0..1). Higher means a more
  /// trustworthy alignment; callers gate locking on a minimum.
  final double confidence;
}

/// Estimates the time offset between the system-loopback ("far") and the
/// microphone ("near") capture streams by cross-correlating their short-time
/// energy envelopes on a single shared clock.
///
/// This is the heart of the AEC's **per-session, per-hardware auto-calibration**:
/// the mic and loopback are two independent OS captures with different,
/// drifting clocks and an unknown delivery offset that depends entirely on the
/// user's audio devices. Rather than hardcode a delay (which would be correct
/// for exactly one machine), we measure the real offset live from the audio
/// itself — the remote's speech bleeds into the mic a fixed delay after it plays
/// out the loopback, and that delay is exactly the lag where the two energy
/// envelopes correlate. The result feeds AEC3's `set_stream_delay_ms` and sizes
/// the mic delay buffer so the reference reliably leads the capture.
///
/// Envelope (not raw-sample) correlation is deliberate: the acoustic echo is an
/// attenuated, distorted, room-colored copy of the loopback, so the *waveforms*
/// correlate poorly, but their *loudness over time* aligns tightly. Pearson
/// correlation makes it level- and gain-invariant.
class AecDelayEstimator {
  /// Creates an estimator. Defaults: 10 ms envelope bins, a 2.5 s analysis
  /// window, ±400 ms search range, and a near-silence floor of [minNearStd].
  AecDelayEstimator({
    this.binMs = 10,
    this.windowMs = 2500,
    this.maxLagMs = 400,
    this.minNearStd = 1.0,
  })  : assert(binMs > 0),
        assert(windowMs > 0),
        assert(maxLagMs > 0),
        _binCount = windowMs ~/ binMs,
        _maxLagBins = maxLagMs ~/ binMs;

  /// Envelope sampling resolution. One ~10 ms PCM block ≈ one bin.
  final int binMs;

  /// Correlation analysis window (how much recent audio is compared).
  final int windowMs;

  /// Maximum |lag| searched, each direction (the delay-estimation range).
  final int maxLagMs;

  /// Minimum near-channel envelope standard deviation to attempt an estimate —
  /// below this the mic is effectively silent and there is nothing to align.
  final double minNearStd;

  final int _binCount;
  final int _maxLagBins;

  // Sparse envelopes keyed by absolute bin index (tMs ~/ binMs). Pruned to the
  // window + lag headroom on each write so memory stays bounded over a meeting.
  final Map<int, double> _far = {};
  final Map<int, double> _near = {};
  int _latestBin = -1;
  int _firstBin = -1;

  /// Records far-end (loopback) energy [rms] stamped at shared-clock time [tMs].
  void addFar(int tMs, double rms) => _put(_far, tMs, rms);

  /// Records near-end (mic) energy [rms] stamped at shared-clock time [tMs].
  void addNear(int tMs, double rms) => _put(_near, tMs, rms);

  void _put(Map<int, double> m, int tMs, double rms) {
    if (tMs < 0) {
      return;
    }
    final bin = tMs ~/ binMs;
    // Keep the loudest sample seen in a bin (the envelope peak).
    final prev = m[bin];
    if (prev == null || rms > prev) {
      m[bin] = rms;
    }
    if (_firstBin < 0) {
      _firstBin = bin;
    }
    if (bin > _latestBin) {
      _latestBin = bin;
      _prune();
    }
  }

  void _prune() {
    final keep = _binCount + 2 * _maxLagBins + 5;
    final cutoff = _latestBin - keep;
    if (cutoff <= 0) {
      return;
    }
    _far.removeWhere((k, _) => k < cutoff);
    _near.removeWhere((k, _) => k < cutoff);
  }

  /// RMS of one mono PCM16 [block] (envelope sample for [addFar]/[addNear]).
  static double rms(Uint8List block) {
    final bd = ByteData.sublistView(block);
    final n = block.length ~/ 2;
    if (n == 0) {
      return 0;
    }
    var sumSq = 0.0;
    for (var i = 0; i < n; i++) {
      final s = bd.getInt16(i * 2, Endian.little).toDouble();
      sumSq += s * s;
    }
    return math.sqrt(sumSq / n);
  }

  /// Cross-correlates the two envelopes and returns the best lag + confidence,
  /// or `null` when there isn't yet enough history, or the mic is silent.
  AecDelayEstimate? estimate() {
    if (_latestBin < 0 || _firstBin < 0) {
      return null;
    }
    // Need far headroom of maxLag on BOTH sides of the analysis window so every
    // candidate lag indexes into real far data (no future / pre-history bins).
    final hi = _latestBin - _maxLagBins;
    final lo = hi - _binCount + 1;
    if (lo - _maxLagBins < _firstBin) {
      return null; // still warming up
    }

    // Materialize and mean-center the near window.
    final near = Float64List(_binCount);
    var nearMean = 0.0;
    for (var i = 0; i < _binCount; i++) {
      final e = _near[lo + i] ?? 0.0;
      near[i] = e;
      nearMean += e;
    }
    nearMean /= _binCount;
    var nearNormSq = 0.0;
    for (var i = 0; i < _binCount; i++) {
      near[i] -= nearMean;
      nearNormSq += near[i] * near[i];
    }
    final nearStd = math.sqrt(nearNormSq / _binCount);
    if (nearStd < minNearStd) {
      return null; // mic effectively silent — nothing to align
    }

    var bestCorr = -2.0;
    var bestLag = 0;
    for (var lag = -_maxLagBins; lag <= _maxLagBins; lag++) {
      // far slice aligned to near: far[lo + i - lag] vs near[i].
      var farMean = 0.0;
      for (var i = 0; i < _binCount; i++) {
        farMean += _far[lo + i - lag] ?? 0.0;
      }
      farMean /= _binCount;
      var dot = 0.0;
      var farNormSq = 0.0;
      for (var i = 0; i < _binCount; i++) {
        final f = (_far[lo + i - lag] ?? 0.0) - farMean;
        dot += near[i] * f;
        farNormSq += f * f;
      }
      if (farNormSq <= 0) {
        continue;
      }
      final corr = dot / math.sqrt(nearNormSq * farNormSq);
      if (corr > bestCorr) {
        bestCorr = corr;
        bestLag = lag;
      }
    }
    if (bestCorr <= -2.0) {
      return null; // far channel had no variance anywhere
    }
    return AecDelayEstimate(
      lagMs: bestLag * binMs,
      confidence: bestCorr.clamp(0.0, 1.0),
    );
  }
}
