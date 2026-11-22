// The runner slot bookkeeping under every interleaving of admissions, person
// waits, cancels and ends: nothing a script does can leave a slot, a parked
// place or a workspace count behind.
import 'dart:async';
import 'dart:math' as math;

import 'package:cc_harness/cancellation.dart';
import 'package:cc_infra/src/code_mode/code_runner_slots.dart';
import 'package:test/test.dart';

/// One simulated script: its hold and whether it waits on a person now.
class _Script {
  _Script(this.slot);

  final ScriptSlot slot;
  final CancellationTokenSource cancel = CancellationTokenSource();
  bool admitted = false;
  bool admitting = false;
  bool ended = false;
  int waits = 0;
}

Future<void> _settle() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  test('a grant that lands after a new wait began, or after the end, is '
      'given straight back', () async {
    final slots = CodeRunnerSlots(1);
    final a = ScriptSlot(slots, 'ws-1', 'run-1');
    final b = ScriptSlot(slots, 'ws-2', 'run-2');
    expect(await a.admit(), isTrue);
    a.waitBegan();
    expect(a.parked, isTrue);
    expect(await b.admit(), isTrue);
    a.waitEnded();
    expect(a.reacquiring, isTrue);
    // A second wait begins before the slot comes back, then ends again.
    a
      ..waitBegan()
      ..waitEnded();
    await _settle();
    expect(slots.waiting, 1, reason: 'one re-acquire, never two');
    b.end();
    await a.back;
    expect(a.holding, isTrue);
    expect(slots.used, 1);
    a.end();
    expect(slots.isIdle, isTrue);
  });

  test('a script that ends while its re-acquire waits gives back its parked '
      'place, and the grant never lands', () async {
    final slots = CodeRunnerSlots(1);
    final a = ScriptSlot(slots, 'ws-1', 'run-1');
    final b = ScriptSlot(slots, 'ws-2', 'run-2');
    await a.admit();
    a.waitBegan();
    await b.admit();
    a.waitEnded();
    final back = a.back;
    a.end();
    await back;
    await _settle();
    expect(slots.parked, 0);
    expect(slots.waiting, 0);
    b.end();
    await _settle();
    expect(slots.isIdle, isTrue);
  });

  test(
    'random interleavings of many scripts leave every count at zero',
    () async {
      for (var round = 0; round < 40; round++) {
        final seed = DateTime.now().microsecondsSinceEpoch + round;
        final random = math.Random(seed);
        final cap = 1 + random.nextInt(4);
        final slots = CodeRunnerSlots(cap);
        final workspaces = ['ws-1', 'ws-2', 'ws-3'];
        const trees = ['run-a', 'run-b'];
        final scripts = <_Script>[];
        final reason = 'seed $seed, cap $cap';

        void checkBounds() {
          expect(slots.used, lessThanOrEqualTo(cap), reason: reason);
          expect(
            slots.parked,
            lessThanOrEqualTo(slots.parkedCap),
            reason: reason,
          );
          for (final ws in workspaces) {
            expect(
              slots.heldBy(ws),
              lessThanOrEqualTo(slots.workspaceShare),
              reason: reason,
            );
            expect(
              slots.parkedBy(ws),
              lessThanOrEqualTo(slots.parkedShare),
              reason: reason,
            );
            for (final tree in trees) {
              expect(
                slots.heldByTree('$ws/$tree'),
                lessThanOrEqualTo(slots.treeShare),
                reason: reason,
              );
            }
          }
        }

        for (var step = 0; step < 400; step++) {
          final live = [
            for (final s in scripts)
              if (!s.ended) s,
          ];
          final pick = random.nextInt(10);
          if (pick < 2 || live.isEmpty) {
            final ws = workspaces[random.nextInt(workspaces.length)];
            final script = _Script(
              ScriptSlot(slots, ws, '$ws/${trees[random.nextInt(2)]}'),
            );
            scripts.add(script);
            script.admitting = true;
            unawaited(
              script.slot
                  .admit(
                    timeout: random.nextBool()
                        ? Duration(milliseconds: random.nextInt(3))
                        : null,
                    cancel: script.cancel.token,
                  )
                  .then((got) {
                    script
                      ..admitting = false
                      ..admitted = got;
                    if (!got) {
                      script.ended = true;
                      script.slot.end();
                    }
                  }),
            );
          } else {
            final script = live[random.nextInt(live.length)];
            switch (pick) {
              case 2 || 3 || 4 when script.admitted:
                if (script.waits++ == 0) {
                  script.slot.waitBegan();
                }
              case 5 || 6 when script.admitted && script.waits > 0:
                if (--script.waits == 0) {
                  script.slot.waitEnded();
                }
              case 7 when script.admitting:
                script.cancel.cancel();
              case 8 || 9 when script.admitted:
                script
                  ..ended = true
                  ..waits = 0;
                script.slot.end();
              default:
                break;
            }
          }
          if (random.nextInt(3) == 0) {
            await Future<void>.delayed(Duration.zero);
          }
          checkBounds();
        }
        // Quiet: every grant in flight has landed. What the scripts hold is
        // exactly what the slots count.
        await Future<void>.delayed(const Duration(milliseconds: 5));
        await _settle();
        checkBounds();
        final holding = scripts.where((s) => s.slot.holding).length;
        final parked = scripts.where((s) => s.slot.parked).length;
        expect(slots.used, holding, reason: reason);
        expect(slots.parked, parked, reason: reason);
        for (final script in scripts) {
          script.cancel.cancel();
          script.slot.end();
        }
        await _settle();
        expect(slots.used, 0, reason: reason);
        expect(slots.parked, 0, reason: reason);
        expect(slots.waiting, 0, reason: reason);
        for (final ws in workspaces) {
          expect(slots.heldBy(ws), 0, reason: reason);
          expect(slots.parkedBy(ws), 0, reason: reason);
          for (final tree in trees) {
            expect(slots.heldByTree('$ws/$tree'), 0, reason: reason);
          }
        }
        expect(slots.isIdle, isTrue, reason: reason);
      }
    },
  );

  test('the parked pool and the slots have a per-workspace share by one '
      'rule', () {
    expect(CodeRunnerSlots.shareOf(1), 1);
    expect(CodeRunnerSlots.shareOf(4), 3);
    expect(CodeRunnerSlots(1).parkedShare, 3);
    expect(CodeRunnerSlots(16).parkedCap, 64);
    expect(CodeRunnerSlots(16).parkedShare, 48);
    final slots = CodeRunnerSlots(1);
    expect(slots.tryPark('ws-1'), isTrue);
    expect(slots.tryPark('ws-1'), isTrue);
    expect(slots.tryPark('ws-1'), isTrue);
    expect(slots.tryPark('ws-1'), isFalse, reason: 'its share is three');
    expect(slots.tryPark('ws-2'), isTrue);
    expect(slots.tryPark('ws-2'), isFalse, reason: 'the pool is four');
  });

  test('one run tree holds at most half its workspace share, and its waiting '
      'scripts let later scripts of other runs pass', () async {
    // Cap 16: a workspace holds 12, a run with its subagents 6.
    final slots = CodeRunnerSlots(16);
    expect(slots.workspaceShare, 12);
    expect(slots.treeShare, 6);
    expect(CodeRunnerSlots(1).treeShare, 1);
    expect(CodeRunnerSlots(2).treeShare, 1);
    expect(CodeRunnerSlots(4).treeShare, 1);
    expect(CodeRunnerSlots(8).treeShare, 3);

    final squatter = [
      for (var i = 0; i < 12; i++) ScriptSlot(slots, 'ws-1', 'squatter'),
    ];
    final admitted = [for (final s in squatter) s.admit()];
    await _settle();
    expect(slots.heldByTree('squatter'), 6);
    expect(slots.heldBy('ws-1'), 6);
    expect(slots.waiting, 6, reason: 'the rest of the tree waits');

    // Another run of the same workspace, queued behind the squatter's six
    // waiting scripts, is admitted at once: the slots are free for it.
    final victim = ScriptSlot(slots, 'ws-1', 'victim');
    expect(await victim.admit(timeout: const Duration(seconds: 1)), isTrue);
    expect(slots.heldBy('ws-1'), 7);

    // A slot the tree gives back goes to its own oldest waiter.
    squatter.first.end();
    await _settle();
    expect(slots.heldByTree('squatter'), 6);
    expect(slots.waiting, 5);

    for (final s in [...squatter, victim]) {
      s.end();
    }
    await Future.wait(admitted);
    await _settle();
    expect(slots.isIdle, isTrue);
  });
}
