import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/entities/wake.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_detail.dart';
import 'package:cc_harness/context.dart' show serializeHarnessHistory;
import 'package:cc_harness/messages.dart';
import 'package:cc_infra/src/dispatch/dispatch_session.dart'
    show harnessRequestOrigin;
import 'package:test/test.dart';

/// The end of the pinned block (`evidencePinEnd` in cc_harness).
const _pinEnd = '<!--omp:end-authoritative-->';

final _t0 = DateTime.utc(2026, 11, 19, 12);

Wake _wake(WakeReason reason) => Wake(
  id: 'w-1',
  workspaceId: 'ws-1',
  spaceId: 'sp-1',
  conversationId: 'conv-1',
  agentId: 'agent-1',
  reason: reason,
  payload: 'p',
  detail: WakeDetail(goalId: 'goal-1'),
  dedupKey: 'w-1',
  notBefore: _t0,
  createdAt: _t0,
);

/// The pinned block of [history] compacted: what survives every compaction
/// verbatim.
String _pinned(List<HarnessMessage> history) {
  final text = serializeHarnessHistory(history);
  final end = text.indexOf(_pinEnd);
  return end < 0 ? '' : text.substring(0, end);
}

void main() {
  test('the run\'s first message: a person\'s, a wake\'s or a peer\'s', () {
    final goalWake = WakeContext.fromWakes([
      _wake(WakeReason.goalContinuation),
    ], nonce: 'nonce1');
    expect(harnessRequestOrigin('fix it', null), HarnessMessageOrigin.person);
    expect(
      harnessRequestOrigin('fix it', goalWake),
      HarnessMessageOrigin.person,
    );
    expect(harnessRequestOrigin(null, goalWake), HarnessMessageOrigin.wake);
    for (final reason in [
      WakeReason.peerMessage,
      WakeReason.peerReply,
      WakeReason.childCompleted,
    ]) {
      expect(
        harnessRequestOrigin(
          null,
          WakeContext(wakeReason: reason, startedByRunId: null),
        ),
        HarnessMessageOrigin.peer,
      );
    }
    for (final reason in [WakeReason.pipelineStep, WakeReason.assignment]) {
      expect(
        harnessRequestOrigin(
          null,
          WakeContext(wakeReason: reason, startedByRunId: null),
        ),
        HarnessMessageOrigin.person,
      );
    }
    expect(harnessRequestOrigin(null, null), HarnessMessageOrigin.person);
  });

  test('a compacted wake-started run (a goal segment) does not pin its wake '
      'frame; a person\'s run still pins the request', () {
    final goalWake = WakeContext.fromWakes([
      _wake(WakeReason.goalContinuation),
    ], nonce: 'nonce1');
    const frame = '[goal continuation] segment 4 of the goal';
    final segment = [
      HarnessMessage.user(frame, origin: harnessRequestOrigin(null, goalWake)),
      HarnessMessage.assistant('working on it'),
    ];
    expect(_pinned(segment), isNot(contains(frame)));
    expect(serializeHarnessHistory(segment), contains(frame));

    const request = 'Ship the parser and keep the API';
    final person = [
      HarnessMessage.user(request, origin: harnessRequestOrigin(request, null)),
      HarnessMessage.assistant('working on it'),
    ];
    expect(_pinned(person), contains(request));
  });
}
