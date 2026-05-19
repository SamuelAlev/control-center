import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cc_natives/cc_natives.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// End-to-end FFI tests for the native AEC library. Loads libaec_ffi from the
/// repo's dev locations and exercises the full create → reverse → capture →
/// destroy cycle, INCLUDING proving that AEC3 actually cancels a synthetic echo
/// — the strongest validation possible without real acoustic hardware. Skips
/// (does not fail) when the library hasn't been built, matching the app's
/// graceful-degradation contract.
void main() {
  // Resolve via the shared policy: the dev dylib is installed in the
  // app-support root by scripts/natives/build_aec.sh.
  final home = Platform.environment['HOME'] ?? '';
  final candidates = nativeLibraryCandidates(
    'aec_ffi',
    appSupportRoot: p.join(
      home,
      'Library',
      'Application Support',
      'com.alev.control-center',
    ),
    envVar: 'AEC_FFI_DYLIB',
  );

  AecProcessor? open() => AecProcessor.tryCreate(explicitPaths: candidates);

  test('loads the native lib and processes one block (skipped if absent)', () {
    final proc = open();
    if (proc == null) {
      markTestSkipped('libaec_ffi not built — run scripts/build_aec.sh');
      return;
    }
    try {
      expect(proc.version, isNotNull);
      expect(proc.version, contains('aec3'));

      final far = Uint8List(AecProcessor.blockBytes); // silence
      final near = Uint8List(AecProcessor.blockBytes)
        ..fillRange(0, AecProcessor.blockBytes, 0x10);
      proc.processReverse(far);
      final cleaned = proc.processCapture(near, 0);
      expect(cleaned, hasLength(AecProcessor.blockBytes));

      // metrics() must round-trip without crashing.
      final m = proc.metrics();
      expect(m, isNotNull);
    } finally {
      proc.dispose();
      proc.dispose(); // idempotent
    }
  });

  test('cancels a synthetic delayed echo (ERLE proof, skipped if absent)', () {
    final proc = open();
    if (proc == null) {
      markTestSkipped('libaec_ffi not built — run scripts/build_aec.sh');
      return;
    }
    const frames = AecProcessor.blockFrames; // 160
    const delayBlocks = 8; // echo arrives 80 ms after the reference
    const streamDelayMs = delayBlocks * 10;
    const totalBlocks = 600; // ~6 s — ample for AEC3 to converge
    const measureFrom = 400; // assess only the converged tail
    final rnd = math.Random(7);

    // Far-end reference blocks: white noise (persistent excitation → fast
    // adaptive-filter convergence).
    final far = List<Int16List>.generate(totalBlocks, (_) {
      final b = Int16List(frames);
      for (var i = 0; i < frames; i++) {
        b[i] = (rnd.nextDouble() * 12000 - 6000).round();
      }
      return b;
    });

    Uint8List bytesOf(Int16List samples) {
      final out = Uint8List(samples.length * 2);
      final bd = ByteData.sublistView(out);
      for (var i = 0; i < samples.length; i++) {
        bd.setInt16(i * 2, samples[i], Endian.little);
      }
      return out;
    }

    double rmsOf(Uint8List block) {
      final bd = ByteData.sublistView(block);
      final n = block.length ~/ 2;
      var sumSq = 0.0;
      for (var i = 0; i < n; i++) {
        final s = bd.getInt16(i * 2, Endian.little).toDouble();
        sumSq += s * s;
      }
      return math.sqrt(sumSq / n);
    }

    try {
      var nearEnergy = 0.0;
      var cleanedEnergy = 0.0;
      var measured = 0;
      for (var k = 0; k < totalBlocks; k++) {
        proc.processReverse(bytesOf(far[k]));

        // near = pure echo: 0.6 × the reference from `delayBlocks` ago.
        final near = Int16List(frames);
        if (k >= delayBlocks) {
          final src = far[k - delayBlocks];
          for (var i = 0; i < frames; i++) {
            near[i] = (src[i] * 0.6).round();
          }
        }
        final nearBytes = bytesOf(near);
        final cleaned = proc.processCapture(nearBytes, streamDelayMs);

        if (k >= measureFrom && k >= delayBlocks) {
          nearEnergy += rmsOf(nearBytes);
          cleanedEnergy += rmsOf(cleaned);
          measured++;
        }
      }

      expect(measured, greaterThan(0));
      final nearAvg = nearEnergy / measured;
      final cleanedAvg = cleanedEnergy / measured;
      // AEC3 should remove most of a clean linear echo. Require at least a 2×
      // energy reduction — conservative vs. the >10× it typically achieves, so
      // the assertion is robust, not flaky.
      expect(nearAvg, greaterThan(100),
          reason: 'sanity: the synthetic echo should be loud');
      expect(cleanedAvg, lessThan(nearAvg * 0.5),
          reason: 'AEC3 did not attenuate the echo (near=$nearAvg '
              'cleaned=$cleanedAvg)');

      // The metrics plumbing should surface real AEC3 data after convergence.
      final m = proc.metrics();
      final anyMetric =
          m.erle != null || m.delayMs != null || m.residual != null;
      expect(anyMetric, isTrue,
          reason: 'GetStatistics returned no populated fields');
      if (m.erle != null) {
        expect(m.erle, greaterThan(0),
            reason: 'positive ERLE means AEC3 is removing echo');
      }
    } finally {
      proc.dispose();
    }
  });
}
