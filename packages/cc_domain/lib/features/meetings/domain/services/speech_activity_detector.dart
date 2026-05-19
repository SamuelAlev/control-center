import 'dart:math' as math;
import 'dart:typed_data';

/// Decides whether a chunk of 16 kHz mono PCM16 audio contains speech. Used by
/// the transcription service to gate decodes (silent windows are never sent to
/// the ASR model) and to drive chunk rotation on speech-end.
///
/// Two implementations: the always-available [RmsSpeechActivityDetector] (an
/// energy threshold) and a learned Silero-VAD adapter in the data layer. The
/// service takes one of these so the gate is swappable and unit-testable.
abstract interface class SpeechActivityDetector {
  /// Whether [pcm16] (little-endian 16-bit mono) currently contains speech.
  bool isSpeech(Uint8List pcm16);

  /// Resets any streaming state (called at the start of a recording).
  void reset();

  /// Releases native resources, if any.
  void dispose();
}

/// Energy-threshold speech gate: speech iff the chunk's RMS amplitude is at or
/// above [threshold] (normalized 0–1). The portable fallback used whenever the
/// Silero VAD model is not installed; equivalent to the old inline RMS check.
class RmsSpeechActivityDetector implements SpeechActivityDetector {
  /// Creates an [RmsSpeechActivityDetector].
  const RmsSpeechActivityDetector({this.threshold = 0.012});

  /// RMS at or above this (normalized 0–1) counts as speech.
  final double threshold;

  @override
  bool isSpeech(Uint8List pcm16) => rmsOfPcm16(pcm16) >= threshold;

  @override
  void reset() {}

  @override
  void dispose() {}
}

/// A speech gate that fires only when EVERY wrapped detector agrees. Used to
/// pair a learned VAD with the `RmsSpeechActivityDetector` energy floor: Silero
/// answers "is this speech?" (energy-agnostic — it flags quiet residual echo
/// bleed too), the RMS floor answers "is it loud enough to be the near party?"
/// (vs. the far-end echo AEC3 attenuated but did not fully remove). Requiring
/// both keeps the learned VAD's anti-hallucination benefit without re-decoding
/// the residual the energy gate used to drop.
class AndSpeechActivityDetector implements SpeechActivityDetector {
  /// Creates an [AndSpeechActivityDetector] over `detectors` (all must agree).
  const AndSpeechActivityDetector(this._detectors);

  final List<SpeechActivityDetector> _detectors;

  @override
  bool isSpeech(Uint8List pcm16) {
    // Evaluate every detector (Silero is stateful and must see each chunk),
    // then require unanimity.
    var speech = true;
    for (final d in _detectors) {
      if (!d.isSpeech(pcm16)) {
        speech = false;
      }
    }
    return speech;
  }

  @override
  void reset() {
    for (final d in _detectors) {
      d.reset();
    }
  }

  @override
  void dispose() {
    for (final d in _detectors) {
      d.dispose();
    }
  }
}

/// Root-mean-square amplitude of a little-endian PCM16 buffer, normalized 0–1.
double rmsOfPcm16(Uint8List pcm16) {
  if (pcm16.length < 2) {
    return 0;
  }
  final view = ByteData.sublistView(pcm16);
  final n = pcm16.length ~/ 2;
  var sumSq = 0.0;
  for (var i = 0; i < n; i++) {
    final s = view.getInt16(i * 2, Endian.little) / 32768.0;
    sumSq += s * s;
  }
  final mean = sumSq / n;
  return mean <= 0 ? 0 : math.sqrt(mean);
}
