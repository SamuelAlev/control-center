import 'package:cc_domain/features/meetings/domain/entities/meeting_segment.dart';
import 'package:cc_domain/features/meetings/domain/services/transcribed_window.dart';
import 'package:cc_infra/src/meetings/meeting_echo_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Small holds/band so the timer-driven commits fire within the test. The
  // invariant activeHoldMs >= matchWindowMs is preserved.
  const idleHoldMs = 40;
  const activeHoldMs = 160;
  const activeWindowMs = 100;
  const matchWindowMs = 160;

  late List<String> accepted; // "speaker:text" in commit order

  MeetingEchoFilter makeFilter() => MeetingEchoFilter(
        onAccepted: (speaker, window) async {
          accepted.add('${speaker.name}:${window.text}');
        },
        idleHoldMs: idleHoldMs,
        activeHoldMs: activeHoldMs,
        activeWindowMs: activeWindowMs,
        matchWindowMs: matchWindowMs,
        bufferMs: 2000,
      );

  EchoCandidate cand(MeetingSpeaker speaker, String text, int emitMs) =>
      EchoCandidate(
        speaker: speaker,
        window: TranscribedWindow(text: text, startMs: emitMs, endMs: emitMs),
        emitMs: emitMs,
      );

  // Past the longest hold so any held "me" has had a chance to commit.
  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: activeHoldMs * 2));

  // Between the idle and active holds — an idle "me" has committed by now, an
  // active (echo-possible) one has not.
  Future<void> betweenHolds() => Future<void>.delayed(
      const Duration(milliseconds: (idleHoldMs + activeHoldMs) ~/ 2));

  const themLine =
      "I've been looking into that too seems like a token management bug";
  const meEcho = "I've been looking into that";

  setUp(() => accepted = []);

  test('them is committed promptly, without waiting for the hold', () async {
    final f = makeFilter();
    f.add(cand(MeetingSpeaker.them, 'hello there everyone today', 1000));
    // Less than idleHoldMs — them must already be there, a held "me" would not.
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(accepted, ['them:hello there everyone today']);
  });

  test('me echo is dropped when them arrives first', () async {
    final f = makeFilter();
    f.add(cand(MeetingSpeaker.them, themLine, 1000));
    await Future<void>.delayed(const Duration(milliseconds: 5));
    f.add(cand(MeetingSpeaker.me, meEcho, 1020)); // within band
    await settle();
    expect(accepted, ['them:$themLine']); // me dropped
  });

  test(
      'me echo is dropped when me arrives first: the active hold keeps it alive '
      'until the late them cancels it', () async {
    final f = makeFilter();
    f.noteSystemActivity(1000); // remote is playing → echo-possible
    f.add(cand(MeetingSpeaker.me, meEcho, 1010)); // held for activeHoldMs
    // The matching "them" is long and late — it arrives after idleHoldMs would
    // have fired, proving the adaptive hold is what saved the cancellation.
    await betweenHolds();
    expect(accepted, isEmpty); // still held (not committed at idleHoldMs)
    f.add(cand(MeetingSpeaker.them, themLine, 1120)); // within band, cancels it
    await settle();
    expect(accepted, ['them:$themLine']); // me never committed
  });

  test('a "me" emitted while the remote is quiet commits promptly (idle hold)',
      () async {
    final f = makeFilter();
    // No recent system activity → not echo-possible → short idle hold.
    f.add(cand(MeetingSpeaker.me, 'let us discuss the budget now', 1000));
    await betweenHolds(); // > idleHoldMs but < activeHoldMs
    expect(accepted, ['me:let us discuss the budget now']);
  });

  test('stale system activity is treated as quiet (idle hold)', () async {
    final f = makeFilter();
    f.noteSystemActivity(500); // long before activeWindowMs of the "me"
    f.add(cand(MeetingSpeaker.me, 'another genuine line for us', 1000));
    await betweenHolds();
    expect(accepted, ['me:another genuine line for us']);
  });

  test('genuine me over the remote is kept (held long, then committed)',
      () async {
    final f = makeFilter();
    f.noteSystemActivity(1000); // remote playing → echo-possible → long hold
    f.add(cand(MeetingSpeaker.me, 'i strongly disagree with that plan', 1010));
    await betweenHolds();
    expect(accepted, isEmpty); // still held — no matching them yet
    await settle(); // hold elapses with no match
    expect(accepted, ['me:i strongly disagree with that plan']);
  });

  test('them is never dropped even when a matching me exists', () async {
    final f = makeFilter();
    f.add(cand(MeetingSpeaker.them, themLine, 1000));
    await Future<void>.delayed(const Duration(milliseconds: 5));
    f.add(cand(MeetingSpeaker.me, meEcho, 1020));
    await settle();
    expect(accepted.where((a) => a.startsWith('them:')), ['them:$themLine']);
  });

  test('no bleed: interleaved non-matching windows all commit exactly once',
      () async {
    final f = makeFilter();
    f.add(cand(MeetingSpeaker.them, 'how is the deployment going', 1000));
    f.add(cand(MeetingSpeaker.me, 'it finished about an hour ago', 1010));
    f.add(cand(MeetingSpeaker.them, 'great any blockers remaining', 1500));
    f.add(cand(MeetingSpeaker.me, 'none on my side right now', 1510));
    await settle();
    expect(accepted, containsAll([
      'them:how is the deployment going',
      'me:it finished about an hour ago',
      'them:great any blockers remaining',
      'me:none on my side right now',
    ]));
    expect(accepted, hasLength(4));
  });

  test('short me window (below minTokens) is never matched as an echo',
      () async {
    final f = makeFilter();
    f.add(cand(MeetingSpeaker.them, 'okay so where were we now', 1000));
    await Future<void>.delayed(const Duration(milliseconds: 5));
    f.add(cand(MeetingSpeaker.me, 'okay', 1010)); // 1 token < minTokens
    await settle();
    expect(accepted, contains('me:okay'));
  });

  test('drain commits the held tail immediately', () async {
    final f = makeFilter();
    f.noteSystemActivity(1000); // even an echo-possible (long-held) tail
    f.add(cand(MeetingSpeaker.me, 'one last thing before we wrap', 1010));
    await f.drain(); // no waiting for the hold
    expect(accepted, ['me:one last thing before we wrap']);
  });

  test('dispose drops the held tail', () async {
    final f = makeFilter();
    f.add(cand(MeetingSpeaker.me, 'this should be discarded entirely', 1000));
    f.dispose();
    await settle();
    expect(accepted, isEmpty);
  });

  test('a matching text outside the time band is kept (not an echo)', () async {
    final f = makeFilter();
    f.add(cand(
        MeetingSpeaker.them, 'the quarterly report is finally ready', 1000));
    await Future<void>.delayed(const Duration(milliseconds: 5));
    // Same words but emitted beyond matchWindowMs → not treated as an echo.
    f.add(cand(
      MeetingSpeaker.me,
      'the quarterly report is finally ready',
      1000 + matchWindowMs + 1,
    ));
    await settle();
    expect(accepted, contains('me:the quarterly report is finally ready'));
  });
}
