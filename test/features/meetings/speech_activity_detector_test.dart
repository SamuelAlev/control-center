import 'dart:typed_data';

import 'package:cc_domain/features/meetings/domain/services/speech_activity_detector.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List _pcm(int samples, int amplitude) {
  final out = Uint8List(samples * 2);
  final view = ByteData.sublistView(out);
  for (var i = 0; i < samples; i++) {
    view.setInt16(i * 2, amplitude, Endian.little);
  }
  return out;
}

void main() {
  group('rmsOfPcm16', () {
    test('is zero for silence and an empty buffer', () {
      expect(rmsOfPcm16(_pcm(100, 0)), 0);
      expect(rmsOfPcm16(Uint8List(0)), 0);
      expect(rmsOfPcm16(Uint8List(1)), 0); // < 2 bytes
    });

    test('is ~1.0 for a full-scale constant signal', () {
      expect(rmsOfPcm16(_pcm(100, 32767)), closeTo(1.0, 0.001));
    });

    test('scales with amplitude', () {
      final quiet = rmsOfPcm16(_pcm(100, 1000));
      final loud = rmsOfPcm16(_pcm(100, 8000));
      expect(loud, greaterThan(quiet));
    });
  });

  group('RmsSpeechActivityDetector', () {
    test('flags speech at/above the threshold and silence below it', () {
      const detector = RmsSpeechActivityDetector(threshold: 0.05);
      expect(detector.isSpeech(_pcm(100, 0)), isFalse);
      expect(detector.isSpeech(_pcm(100, 100)), isFalse); // ~0.003
      expect(detector.isSpeech(_pcm(100, 12000)), isTrue); // ~0.366
    });

    test('reset and dispose are no-ops (no throw)', () {
      const detector = RmsSpeechActivityDetector();
      expect(detector.reset, returnsNormally);
      expect(detector.dispose, returnsNormally);
    });
  });

  group('AndSpeechActivityDetector', () {
    test('fires only when every wrapped detector agrees', () {
      final yes = _StubDetector(true);
      final no = _StubDetector(false);
      expect(AndSpeechActivityDetector([yes, yes]).isSpeech(_pcm(1, 0)), isTrue);
      expect(AndSpeechActivityDetector([yes, no]).isSpeech(_pcm(1, 0)), isFalse);
      expect(AndSpeechActivityDetector([no, no]).isSpeech(_pcm(1, 0)), isFalse);
    });

    test('evaluates every detector each chunk (stateful VADs must see audio)',
        () {
      final a = _StubDetector(false);
      final b = _StubDetector(true);
      AndSpeechActivityDetector([a, b]).isSpeech(_pcm(1, 0));
      // Even though `a` already returned false, `b` must still be fed.
      expect(a.calls, 1);
      expect(b.calls, 1);
    });

    test('Silero(true) AND RMS-floor gates out quiet residual echo', () {
      // Simulates the bug: a learned VAD flags quiet residual echo as speech,
      // but the energy floor (the AEC-era gate) drops it.
      final silero = _StubDetector(true);
      const floor = RmsSpeechActivityDetector(threshold: 0.05);
      final gate = AndSpeechActivityDetector([silero, floor]);
      expect(gate.isSpeech(_pcm(100, 200)), isFalse); // ~0.006 < 0.05 → dropped
      expect(gate.isSpeech(_pcm(100, 12000)), isTrue); // loud near speech → kept
    });

    test('reset and dispose fan out to all detectors', () {
      final a = _StubDetector(true);
      final b = _StubDetector(true);
      AndSpeechActivityDetector([a, b])
        ..reset()
        ..dispose();
      expect(a.resets, 1);
      expect(a.disposes, 1);
      expect(b.resets, 1);
      expect(b.disposes, 1);
    });
  });
}

/// A detector returning a fixed verdict; records how often it is called.
class _StubDetector implements SpeechActivityDetector {
  // ignore: avoid_positional_boolean_parameters
  _StubDetector(this._verdict);
  final bool _verdict;
  int calls = 0;
  int resets = 0;
  int disposes = 0;

  @override
  bool isSpeech(Uint8List pcm16) {
    calls++;
    return _verdict;
  }

  @override
  void reset() => resets++;

  @override
  void dispose() => disposes++;
}
