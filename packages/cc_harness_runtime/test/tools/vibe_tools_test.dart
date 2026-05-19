import 'dart:async';

import 'package:cc_harness/tools.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:test/test.dart';

/// A runner the test drives by hand, so a worker's lifetime is deterministic.
class _FakeRunner implements VibeWorkerRunner {
  final Map<String, Completer<SubagentResult>> pending = {};
  final List<String> briefs = [];
  final List<SubagentType> types = [];

  @override
  Future<SubagentResult> run({
    required VibeWorker worker,
    required String brief,
    required HarnessToolContext context,
    required SubagentType type,
    String? modelOverride,
  }) {
    briefs.add(brief);
    types.add(type);
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

    test('the brief tells the worker it has no other context', () async {
      await call('vibe_spawn', {'brief': 'do the thing', 'label': 'a'});
      expect(runner.briefs.single, contains('have NOT seen the conversation'));
      expect(runner.briefs.single, contains('do the thing'));
      expect(runner.briefs.single, contains('naming every file you changed'));
    });

    test('a worker is an ordinary writing subagent underneath', () async {
      // Vibe changes who drives a subagent, not what it is allowed to do.
      await call('vibe_spawn', {'brief': 'x', 'label': 'a'});
      expect(runner.types.single, SubagentType.general);
    });

    test('records the tier the director chose', () async {
      await call('vibe_spawn', {
        'brief': 'design the API',
        'label': 'api',
        'tier': 'good',
      });
      expect(roster['w1']!.tier, VibeTier.good);
    });

    test('defaults to the cheap tier', () async {
      await call('vibe_spawn', {'brief': 'rename things', 'label': 'r'});
      expect(roster['w1']!.tier, VibeTier.fast);
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

    test('rejects an empty brief rather than starting a blind worker', () async {
      final result = await call('vibe_spawn', {'brief': '  ', 'label': 'a'});
      expect(result.isError, isTrue);
      expect(roster.workers, isEmpty);
    });
  });

  group('vibe_list', () {
    test('shows status and elapsed time', () async {
      await call('vibe_spawn', {'brief': 'x', 'label': 'auth'});
      clock = clock.add(const Duration(seconds: 42));

      final listed = await call('vibe_list');
      expect(listed.content, contains('w1 [fast] auth — running (42s)'));
    });

    test('shows a finished worker\'s result inline', () async {
      await call('vibe_spawn', {'brief': 'x', 'label': 'auth'});
      runner.finish('w1', 'Edited lib/auth.dart and lib/session.dart.');
      await pumpEventQueue();

      final listed = await call('vibe_list');
      expect(listed.content, contains('done'));
      expect(listed.content, contains('lib/auth.dart'));
    });

    test('is empty before anything starts', () async {
      expect((await call('vibe_list')).content, 'No workers.');
    });
  });

  group('vibe_wait', () {
    test('returns the result once the worker settles', () async {
      await call('vibe_spawn', {'brief': 'x', 'label': 'a'});
      final waiting = call('vibe_wait', {'worker_id': 'w1'});
      runner.finish('w1', 'Changed lib/a.dart');

      final result = await waiting;
      expect(result.content, contains('Changed lib/a.dart'));
      expect(
        result.content,
        contains('claim, not'),
        reason: 'a report is not evidence — the director must read the files',
      );
    });

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
    test('appends to the brief and re-runs', () async {
      await call('vibe_spawn', {'brief': 'migrate auth', 'label': 'a'});
      runner.finish('w1', 'done part one');
      await pumpEventQueue();
      runner.pending.remove('w1');

      final sent = await call('vibe_send', {
        'worker_id': 'w1',
        'message': 'now the tests too',
      });
      expect(sent.isError, isFalse);
      expect(roster['w1']!.isRunning, isTrue);
      expect(runner.briefs.last, contains('migrate auth'));
      expect(runner.briefs.last, contains('now the tests too'));
    });

    test('refuses while the worker is still busy', () async {
      await call('vibe_spawn', {'brief': 'x', 'label': 'a'});
      final result = await call('vibe_send', {
        'worker_id': 'w1',
        'message': 'also this',
      });
      expect(result.isError, isTrue);
      expect(result.content, contains('still working'));
    });
  });

  group('vibe_kill', () {
    test('stops a running worker', () async {
      await call('vibe_spawn', {'brief': 'x', 'label': 'a'});
      final result = await call('vibe_kill', {'worker_id': 'w1'});
      expect(result.isError, isFalse);
      expect(roster['w1']!.status, VibeWorkerStatus.killed);
      expect(roster.running, isEmpty);
    });

    test('a second kill is not an error', () async {
      await call('vibe_spawn', {'brief': 'x', 'label': 'a'});
      await call('vibe_kill', {'worker_id': 'w1'});
      final again = await call('vibe_kill', {'worker_id': 'w1'});
      expect(again.isError, isFalse);
      expect(again.content, contains('already'));
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
      expect(roster.running, isEmpty);
    });
  });

  group('tool contract', () {
    test('every verb is read tier', () {
      // The gate belongs on the WORKER's tools, where the edit happens and the
      // guardrail policy already applies — prompting here too would ask the
      // same question twice.
      for (final tool in tools.values) {
        expect(tool.approvalTier, ToolApprovalTier.read, reason: tool.name);
      }
    });

    test('the ids are deterministic, so a replay reproduces them', () async {
      await call('vibe_spawn', {'brief': 'a', 'label': 'a'});
      await call('vibe_spawn', {'brief': 'b', 'label': 'b'});
      expect(roster.workers.map((w) => w.id), ['w1', 'w2']);
    });
  });
}
