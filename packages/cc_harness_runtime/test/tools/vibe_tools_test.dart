import 'dart:async';

import 'package:cc_harness/tools.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:test/test.dart';

/// A runner the test drives by hand, so a worker's lifetime is deterministic.
class _FakeRunner implements VibeWorkerRunner {
  final Map<String, Completer<SubagentResult>> pending = {};

  @override
  Future<SubagentResult> run({
    required VibeWorker worker,
    required String brief,
    required HarnessToolContext context,
    required SubagentType type,
    String? modelOverride,
  }) {
    return (pending[worker.id] ??= Completer<SubagentResult>()).future;
  }

  void finish(String id, String text, {bool isError = false}) {
    pending[id]!.complete(SubagentResult(text: text, isError: isError));
  }
}

void main() {
  late VibeRoster roster;
  late _FakeRunner runner;
  late Map<String, HarnessTool> tools;
  var clock = DateTime.utc(2026, 1, 1);

  setUp(() {
    roster = VibeRoster();
    runner = _FakeRunner();
    clock = DateTime.utc(2026, 1, 1);
    tools = {
      for (final tool in buildVibeTools(
        roster: roster,
        runner: runner,
        now: () => clock,
      ))
        tool.name: tool,
    };
  });

  HarnessToolContext ctx() =>
      const HarnessToolContext(workingDirectory: '/repo');

  Future<HarnessToolResult> call(
    String name, [
    Map<String, dynamic> args = const {},
  ]) => tools[name]!.execute(args, ctx());

  group('vibe_spawn', () {
    test('returns immediately rather than blocking on the worker', () async {
      // Async by default is the ergonomic difference from `task`: a director
      // that blocks on every spawn runs workers one at a time.
      final result = await call('vibe_spawn', {
        'brief': 'migrate the auth module',
        'label': 'auth',
      });
      expect(result.isError, isFalse);
      expect(result.content, contains('w1'));
      expect(roster.running, hasLength(1));
      expect(runner.pending.containsKey('w1'), isTrue);
    });

    test('refuses past the concurrency cap', () async {
      final small = VibeRoster(maxWorkers: 2);
      final capped = {
        for (final t in buildVibeTools(
          roster: small,
          runner: runner,
          now: () => clock,
        ))
          t.name: t,
      };
      await capped['vibe_spawn']!.execute({'brief': 'a', 'label': 'a'}, ctx());
      await capped['vibe_spawn']!.execute({'brief': 'b', 'label': 'b'}, ctx());
      final third = await capped['vibe_spawn']!.execute({
        'brief': 'c',
        'label': 'c',
      }, ctx());
      expect(third.isError, isTrue);
      expect(third.content, contains('cap'));
    });

    test(
      'rejects an empty brief rather than starting a blind worker',
      () async {
        final result = await call('vibe_spawn', {'brief': '  ', 'label': 'a'});
        expect(result.isError, isTrue);
        expect(roster.workers, isEmpty);
      },
    );
  });

  group('vibe_wait', () {
    test('times out without failing the worker', () async {
      await call('vibe_spawn', {'brief': 'x', 'label': 'a'});
      final result = await call('vibe_wait', {
        'worker_id': 'w1',
        'timeout_seconds': 1,
      });
      expect(result.isError, isFalse);
      expect(result.content, contains('still running'));
      expect(roster['w1']!.isRunning, isTrue);
    });

    test('names what is actually running when the id is wrong', () async {
      await call('vibe_spawn', {'brief': 'x', 'label': 'a'});
      final result = await call('vibe_wait', {'worker_id': 'w9'});
      expect(result.isError, isTrue);
      expect(result.content, contains('w1'));
    });
  });

  group('vibe_send', () {
    test('refuses while the worker is still busy', () async {
      await call('vibe_spawn', {'brief': 'x', 'label': 'a'});
      final result = await call('vibe_send', {
        'worker_id': 'w1',
        'message': 'also this',
      });
      expect(result.isError, isTrue);
    });
  });

  group('vibe_kill', () {
    test('cancels execution and a late result cannot resurrect it', () async {
      await call('vibe_spawn', {'brief': 'x', 'label': 'a'});
      final worker = roster['w1']!;
      final cancelled = worker.cancel.whenCancelled;
      final result = await call('vibe_kill', {'worker_id': 'w1'});
      await cancelled.timeout(const Duration(seconds: 1));
      expect(result.isError, isFalse);
      expect(worker.status, VibeWorkerStatus.killed);
      expect(roster.running, isEmpty);

      runner.finish(worker.id, 'late completion');
      await pumpEventQueue();
      expect(worker.status, VibeWorkerStatus.killed);
      final followUp = await call('vibe_send', {
        'worker_id': worker.id,
        'message': 'Continue writing',
      });
      expect(followUp.isError, isTrue);
      expect(worker.status, VibeWorkerStatus.killed);
    });

    test('a second kill is not an error', () async {
      await call('vibe_spawn', {'brief': 'x', 'label': 'a'});
      await call('vibe_kill', {'worker_id': 'w1'});
      final again = await call('vibe_kill', {'worker_id': 'w1'});
      expect(again.isError, isFalse);
    });

    test('releases anything waiting on it', () async {
      await call('vibe_spawn', {'brief': 'x', 'label': 'a'});
      final waiting = call('vibe_wait', {'worker_id': 'w1'});
      await call('vibe_kill', {'worker_id': 'w1'});
      expect((await waiting).content, contains('killed'));
    });
  });

  group('roster teardown', () {
    test('killAll stops every running worker', () async {
      await call('vibe_spawn', {'brief': 'a', 'label': 'a'});
      await call('vibe_spawn', {'brief': 'b', 'label': 'b'});
      runner.finish('w1', 'done');
      await pumpEventQueue();

      expect(roster.killAll(), 1, reason: 'only the live one is killed');
      await roster['w2']!.cancel.whenCancelled.timeout(
        const Duration(seconds: 1),
      );
      expect(roster['w1']!.status, VibeWorkerStatus.done);
      expect(roster['w2']!.status, VibeWorkerStatus.killed);
      expect(roster.running, isEmpty);
    });
  });
}
