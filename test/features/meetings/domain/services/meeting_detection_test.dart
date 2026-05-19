import 'package:cc_domain/features/meetings/domain/services/meeting_detection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t0 = DateTime.utc(2026, 1, 1, 12);
  MeetingSignal sig(MeetingSignalKind k, {bool active = true, int agoSec = 0, String? label}) =>
      MeetingSignal(
        kind: k,
        active: active,
        at: t0.subtract(Duration(seconds: agoSec)),
        label: label,
      );

  group('resolveMeetingCandidate', () {
    test('a single strong signal (conferencing app) is enough', () {
      final c = resolveMeetingCandidate(
        [sig(MeetingSignalKind.conferencingApp, label: 'zoom.us')],
        now: t0,
      );
      expect(c, isNotNull);
      expect(c!.primary, MeetingSignalKind.conferencingApp);
      expect(c.label, 'zoom.us');
      expect(c.confidence, greaterThanOrEqualTo(0.6));
    });

    test('weak signals need enough corroboration to cross the threshold', () {
      // 0.4 (camera) + 0.15 corroboration = 0.55 — under 0.6.
      expect(
        resolveMeetingCandidate(
          [
            sig(MeetingSignalKind.camera),
            sig(MeetingSignalKind.systemAudioActive),
          ],
          now: t0,
        ),
        isNull,
      );
      // A third corroborating weak signal pushes it over (0.4 + 0.30 = 0.70).
      final c = resolveMeetingCandidate(
        [
          sig(MeetingSignalKind.camera),
          sig(MeetingSignalKind.systemAudioActive),
          sig(MeetingSignalKind.microphoneInUse),
        ],
        now: t0,
      );
      expect(c, isNotNull);
      expect(c!.confidence, greaterThanOrEqualTo(0.6));
    });

    test('a lone weak signal stays below the threshold', () {
      expect(
        resolveMeetingCandidate([sig(MeetingSignalKind.camera)], now: t0),
        isNull,
      );
    });

    test('active recording alone is a sufficient signal', () {
      final c = resolveMeetingCandidate(
        [sig(MeetingSignalKind.activeRecording)],
        now: t0,
      );
      expect(c, isNotNull);
      expect(c!.primary, MeetingSignalKind.activeRecording);
      expect(c.confidence, greaterThanOrEqualTo(0.6));
    });

    test('stale signals are ignored', () {
      expect(
        resolveMeetingCandidate(
          [sig(MeetingSignalKind.conferencingApp, agoSec: 60)],
          now: t0,
        ),
        isNull,
      );
    });

    test('inactive signals do not count', () {
      expect(
        resolveMeetingCandidate(
          [sig(MeetingSignalKind.conferencingApp, active: false)],
          now: t0,
        ),
        isNull,
      );
    });
  });

  group('MeetingDetectionStateMachine', () {
    MeetingCandidate cand({String? label, int sinceSec = 0}) => MeetingCandidate(
          confidence: 0.9,
          primary: MeetingSignalKind.conferencingApp,
          label: label,
          since: t0.subtract(Duration(seconds: sinceSec)),
        );

    test('debounces: prompts only after minPresence', () {
      final m = MeetingDetectionStateMachine(
        policy: const MeetingDetectionPolicy(minPresence: Duration(seconds: 8)),
      );
      // Candidate just appeared → watching, no prompt.
      expect(
        m.update(candidate: cand(label: 'a'), now: t0),
        MeetingDetectionAction.none,
      );
      expect(m.state, MeetingDetectionState.watching);
      // 9s later, persisted → prompt once.
      final later = t0.add(const Duration(seconds: 9));
      expect(
        m.update(candidate: cand(label: 'a', sinceSec: 9), now: later),
        MeetingDetectionAction.showPrompt,
      );
      expect(m.state, MeetingDetectionState.prompting);
      // Still present → no repeat prompt.
      expect(
        m.update(candidate: cand(label: 'a', sinceSec: 10), now: later),
        MeetingDetectionAction.none,
      );
    });

    test('hides the prompt when the candidate vanishes', () {
      final m = MeetingDetectionStateMachine(
        policy: const MeetingDetectionPolicy(minPresence: Duration.zero),
      );
      expect(
        m.update(candidate: cand(label: 'a'), now: t0),
        MeetingDetectionAction.showPrompt,
      );
      expect(
        m.update(candidate: null, now: t0.add(const Duration(seconds: 1))),
        MeetingDetectionAction.hidePrompt,
      );
      expect(m.state, MeetingDetectionState.idle);
    });

    test('a dismissed label is suppressed until it clears', () {
      final m = MeetingDetectionStateMachine(
        policy: const MeetingDetectionPolicy(minPresence: Duration.zero),
      );
      m.update(candidate: cand(label: 'a'), now: t0);
      m.dismiss('a');
      // Same label keeps coming → no prompt.
      expect(
        m.update(candidate: cand(label: 'a'), now: t0.add(const Duration(seconds: 5))),
        MeetingDetectionAction.none,
      );
      // A different meeting (label 'b') prompts again.
      expect(
        m.update(candidate: cand(label: 'b'), now: t0.add(const Duration(seconds: 6))),
        MeetingDetectionAction.showPrompt,
      );
    });

    test('suggests auto-stop after a sustained no-signal gap while recording', () {
      final m = MeetingDetectionStateMachine(
        policy: const MeetingDetectionPolicy(
          minPresence: Duration.zero,
          autoStopAfter: Duration(seconds: 90),
        ),
      );
      m.update(candidate: cand(label: 'a'), now: t0);
      m.accept();
      expect(m.state, MeetingDetectionState.recording);
      // 30s gap — not yet.
      expect(
        m.update(candidate: null, now: t0.add(const Duration(seconds: 30))),
        MeetingDetectionAction.none,
      );
      // 95s gap — suggest stop.
      expect(
        m.update(candidate: null, now: t0.add(const Duration(seconds: 95))),
        MeetingDetectionAction.suggestAutoStop,
      );
    });

    test('ongoing recording activity holds off auto-stop until speech stops', () {
      final m = MeetingDetectionStateMachine(
        policy: const MeetingDetectionPolicy(
          minPresence: Duration.zero,
          autoStopAfter: Duration(seconds: 90),
        ),
      );
      m.update(candidate: cand(label: 'a'), now: t0);
      m.accept();

      // A fresh "active recording" candidate keeps arriving (someone is still
      // talking) every 30s for 5 minutes — well past autoStopAfter. The meeting
      // is never declared over while transcription continues.
      var now = t0;
      MeetingCandidate recording() => MeetingCandidate(
            confidence: 0.9,
            primary: MeetingSignalKind.activeRecording,
            since: now,
          );
      for (var i = 0; i < 10; i++) {
        now = now.add(const Duration(seconds: 30));
        expect(
          m.update(candidate: recording(), now: now),
          MeetingDetectionAction.none,
        );
      }

      // Speech stops — only now does the no-signal gap open, and auto-stop fires
      // a full autoStopAfter later (not immediately).
      expect(
        m.update(candidate: null, now: now.add(const Duration(seconds: 30))),
        MeetingDetectionAction.none,
      );
      expect(
        m.update(candidate: null, now: now.add(const Duration(seconds: 95))),
        MeetingDetectionAction.suggestAutoStop,
      );
    });
  });
}
