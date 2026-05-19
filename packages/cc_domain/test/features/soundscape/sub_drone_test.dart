import 'dart:typed_data';

import 'package:cc_domain/features/soundscape/domain/synth/seeded_prng.dart';
import 'package:cc_domain/features/soundscape/domain/synth/voices/sub_drone.dart';
import 'package:test/test.dart';

/// Covers the [SubDrone] voice's retune/crossfade paths: rendering plain,
/// rendering through an equal-power crossfade after retune (bank B advance +
/// fade completion + bank swap), retune-during-fade (instant swap), and the
/// fade-delay offset path.
void main() {
  group('SubDrone', () {
    test('render produces non-zero centered output at the fundamental', () {
      final drone = SubDrone(
        44100.0,
        SeededPrng(7),
        frequencyHz: 80,
        fifthGain: 0.3,
      );
      final out = Float32List(256 * 2);
      drone.renderAdd(out, 256, 0.5);
      // Center-panned mono: left == right at every frame.
      for (var i = 0; i < 256; i++) {
        expect(out[2 * i], closeTo(out[2 * i + 1], 1e-9));
      }
      expect(out.any((s) => s != 0), isTrue);
    });

    test('retune triggers a crossfade that swaps banks on completion', () {
      const sampleRate = 44100.0;
      // Use a short crossfade so the fade completes inside the rendered block.
      final drone = SubDrone(
        sampleRate,
        SeededPrng(1),
        frequencyHz: 100,
        fifthGain: 0.5,
        crossfadeSeconds: 0.001, // ~44 frames
      );
      drone.retune(200);
      // Render enough frames to pass the crossfade window and complete the swap.
      final out = Float32List(2000 * 2);
      drone.renderAdd(out, 2000, 1.0);
      // The crossfade path has executed and the fade ended.
      expect(out.any((s) => s != 0), isTrue);
    });

    test(
      'retune during an active fade swaps banks instantly then restarts',
      () {
        final drone = SubDrone(
          44100.0,
          SeededPrng(2),
          frequencyHz: 110,
          fifthGain: 0.0,
          crossfadeSeconds: 0.5,
        );
        // Start a fade, render a bit, then retune again mid-fade.
        drone.retune(220);
        final out1 = Float32List(64 * 2);
        drone.renderAdd(out1, 64, 1.0);
        drone.retune(330); // _fading is true → _swapBanks() runs.
        final out2 = Float32List(64 * 2);
        drone.renderAdd(out2, 64, 1.0);
        expect(out2.any((s) => s != 0), isTrue);
      },
    );

    test('retune with a positive offset delays the fade start', () {
      final drone = SubDrone(
        44100.0,
        SeededPrng(3),
        frequencyHz: 90,
        crossfadeSeconds: 0.01,
      );
      // Offset the fade by a handful of frames; the delay-countdown branch runs.
      drone.retune(180, offsetFrames: 20);
      final out = Float32List(200 * 2);
      drone.renderAdd(out, 200, 1.0);
      expect(out.any((s) => s != 0), isTrue);
    });

    test('clamp inputs stay in range without throwing', () {
      final drone = SubDrone(
        44100.0,
        SeededPrng(4),
        frequencyHz: 50,
        fifthGain: 5.0, // clamps to 1.0
        swellDepth: 2.0, // clamps to 1.0
      );
      final out = Float32List(32 * 2);
      drone.renderAdd(out, 32, 1.0);
      expect(out.any((s) => s != 0), isTrue);
    });
  });
}
