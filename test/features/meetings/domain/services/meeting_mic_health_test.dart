import 'dart:typed_data';

import 'package:cc_domain/features/meetings/domain/services/meeting_mic_health.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MeetingMicHealthTracker.health', () {
    test('is ok with no system activity to compare against', () {
      final t = MeetingMicHealthTracker();
      for (var ms = 0; ms <= 5000; ms += 100) {
        t.noteMic(0, ms); // mic silent, but nobody else is talking either
      }
      expect(t.health, MicHealth.ok);
      expect(t.micSilentWhileActive, isFalse);
    });

    test('flags a silent mic while the system is actively playing', () {
      final t = MeetingMicHealthTracker();
      for (var ms = 0; ms <= 4000; ms += 100) {
        t.noteSystem(0.3, ms); // remote clearly talking
        t.noteMic(0, ms); // mic dead
      }
      expect(t.health, MicHealth.silentWhileSystemActive);
      expect(t.micSilentWhileActive, isTrue);
    });

    test('stays ok when the mic is also carrying audio', () {
      final t = MeetingMicHealthTracker();
      for (var ms = 0; ms <= 4000; ms += 100) {
        t.noteSystem(0.3, ms);
        t.noteMic(0.2, ms); // the user is talking too
      }
      expect(t.health, MicHealth.ok);
    });

    test('does not flag a brief mic pause below the confirm window', () {
      final t = MeetingMicHealthTracker(confirmMs: 3000);
      // 1s of joint talk, then 1.5s where only the system is active.
      for (var ms = 0; ms <= 1000; ms += 100) {
        t.noteSystem(0.3, ms);
        t.noteMic(0.2, ms);
      }
      for (var ms = 1100; ms <= 2500; ms += 100) {
        t.noteSystem(0.3, ms);
        t.noteMic(0, ms);
      }
      expect(t.health, MicHealth.ok); // only ~1.5s of silence
    });

    test('clears once the remote stops talking (stale system activity)', () {
      final t = MeetingMicHealthTracker();
      for (var ms = 0; ms <= 4000; ms += 100) {
        t.noteSystem(0.3, ms);
        t.noteMic(0, ms);
      }
      expect(t.micSilentWhileActive, isTrue);
      // Remote goes quiet for >2s; the silent-mic warning should clear.
      for (var ms = 4100; ms <= 7000; ms += 100) {
        t.noteSystem(0, ms);
        t.noteMic(0, ms);
      }
      expect(t.health, MicHealth.ok);
    });
  });

  group('MeetingMicHealthTracker.level', () {
    test('rises toward the mic RMS and is reported in 0..1', () {
      final t = MeetingMicHealthTracker(levelSmoothing: 1);
      t.noteMic(0.5, 0);
      expect(t.level, closeTo(0.5, 1e-9));
      t.noteMic(0, 100);
      expect(t.level, closeTo(0, 1e-9));
    });
  });

  group('MeetingMicHealthTracker.rmsOfPcm16', () {
    test('computes RMS of a constant-amplitude PCM16 block', () {
      final bd = ByteData(160 * 2);
      for (var i = 0; i < 160; i++) {
        bd.setInt16(i * 2, 16384, Endian.little); // 0.5 of full scale
      }
      final rms = MeetingMicHealthTracker.rmsOfPcm16(bd.buffer.asUint8List());
      expect(rms, closeTo(0.5, 0.001));
    });
  });
}
