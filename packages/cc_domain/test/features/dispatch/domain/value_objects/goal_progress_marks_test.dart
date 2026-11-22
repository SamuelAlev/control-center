import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_authority.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_progress_marks.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_start_refs.dart';
import 'package:test/test.dart';

AgentGoalRun _goal({String? requester, DateTime? at}) => AgentGoalRun(
  id: 'g-1',
  workspaceId: 'ws-1',
  spaceId: 'sp-1',
  conversationId: 'c-1',
  agentId: 'a-1',
  userText: 'ship it',
  costCapMicros: 1000000,
  requestedByUserId: requester,
  createdAt: at ?? DateTime.utc(2026, 11, 19, 10),
  updatedAt: at ?? DateTime.utc(2026, 11, 19, 10),
);

void main() {
  group('GoalProgressMarks', () {
    final t0 = DateTime.utc(2026, 11, 19, 10);
    String mark(String fp) => GoalProgressMarks.markOf(
      fingerprint: fp,
      checklist: 'c',
      activity: null,
    );

    test('remembers the last eight marks, a repeat moves to the end', () {
      var marks = GoalProgressMarks.empty;
      for (var i = 0; i < 10; i++) {
        marks = marks.remember(mark('fp$i'));
      }
      expect(marks.marks, hasLength(GoalProgressMarks.maxMarks));
      expect(marks.seen(mark('fp0')), isFalse);
      expect(marks.seen(mark('fp1')), isFalse);
      expect(marks.seen(mark('fp2')), isTrue);
      marks = marks.remember(mark('fp2'));
      expect(marks.marks.last, mark('fp2'));
      expect(marks.marks, hasLength(GoalProgressMarks.maxMarks));
    });

    test('a state changed and changed back is a mark seen before', () {
      final a = mark('a');
      final marks = GoalProgressMarks.empty.remember(a).remember(mark('b'));
      expect(marks.seen(a), isTrue);
    });

    test('the fallback doubles on the same owed work and caps at 4 h', () {
      var marks = GoalProgressMarks.empty;
      final fallbacks = <int>[];
      for (var i = 0; i < 6; i++) {
        marks = marks.waited(
          ids: const ['ask:a'],
          progressed: false,
          now: t0.add(Duration(minutes: i)),
        );
        fallbacks.add(marks.fallback.inMinutes);
      }
      expect(fallbacks, [20, 40, 80, 160, 240, 240]);
      expect(marks.waitSince, t0, reason: 'the stretch keeps its start');
      expect(marks.freshWaits, 1, reason: 'one ask, set up once');
    });

    test('new owed work goes on with the stretch, counted as a fresh '
        'wait; only progress starts it over', () {
      var marks = GoalProgressMarks.empty
          .waited(ids: const ['ask:a'], progressed: false, now: t0)
          .waited(
            ids: const ['ask:a'],
            progressed: false,
            now: t0.add(const Duration(hours: 1)),
          );
      expect(marks.waits, 2);
      expect(marks.freshWaits, 1);
      marks = marks.waited(
        ids: const ['ask:a', 'rule:b'],
        progressed: false,
        now: t0.add(const Duration(hours: 2)),
      );
      expect(marks.waits, 3);
      expect(marks.freshWaits, 2);
      expect(marks.waitSince, t0);
      expect(marks.fallback, const Duration(minutes: 80));
      final progressed = marks.waited(
        ids: const ['rule:b'],
        progressed: true,
        now: t0.add(const Duration(hours: 3)),
      );
      expect(progressed.waits, 0);
      expect(progressed.freshWaits, 0);
      expect(progressed.waitSince, isNull);
      expect(progressed.fallback, GoalProgressMarks.firstFallback);
      expect(progressed.owed, ['rule:b'], reason: 'the next baseline');
      expect(marks.endWait().owed, isEmpty);
    });

    test('work finishing is never fresh; one done and one new is fresh '
        'once', () {
      final seven = [for (var i = 1; i <= 7; i++) 'ticket:t$i'];
      var marks = GoalProgressMarks.empty.waited(
        ids: seven,
        progressed: true,
        now: t0,
      );
      for (var done = 1; done < 7; done++) {
        marks = marks.waited(
          ids: seven.sublist(done),
          progressed: false,
          now: t0.add(Duration(minutes: done)),
        );
      }
      expect(marks.waits, 6);
      expect(marks.freshWaits, 0);
      expect(marks.isFresh(const ['ticket:t7']), isFalse);
      expect(marks.isFresh(const ['ticket:t8']), isTrue);
      marks = marks.waited(
        ids: const ['ticket:t8'],
        progressed: false,
        now: t0.add(const Duration(hours: 1)),
      );
      expect(marks.freshWaits, 1);
    });

    test('24 hours of the stretch, or six fresh waits, stall the goal', () {
      final once = GoalProgressMarks.empty.waited(
        ids: const ['ask:a'],
        progressed: false,
        now: t0,
      );
      expect(once.stalled(t0.add(const Duration(hours: 23))), isFalse);
      expect(once.stalled(t0.add(const Duration(hours: 24))), isTrue);
      var fresh = GoalProgressMarks.empty;
      for (var i = 0; i < GoalProgressMarks.maxFreshWaits; i++) {
        expect(fresh.stalled(t0), isFalse);
        fresh = fresh.waited(ids: ['rule:r$i'], progressed: false, now: t0);
      }
      expect(fresh.stalled(t0), isTrue);
      expect(fresh.waitedFor(t0.add(const Duration(hours: 2))).inHours, 2);
    });

    test('round-trips its stored text and reads garbage as empty', () {
      final marks = GoalProgressMarks.empty
          .remember(mark('a'))
          .waited(ids: const ['ask:a'], progressed: false, now: t0.toLocal())
          .waited(ids: const ['rule:b', 'ask:a'], progressed: false, now: t0);
      final back = GoalProgressMarks.parse(marks.encode());
      expect(back, marks);
      expect(back.owed, ['ask:a', 'rule:b']);
      expect(back.waitSince!.isUtc, isTrue);
      expect(GoalProgressMarks.parse('not json'), GoalProgressMarks.empty);
      expect(GoalProgressMarks.parse('[1]'), GoalProgressMarks.empty);
    });

    test('the owed ids ignore order and repeats', () {
      expect(
        GoalProgressMarks(owed: const ['wake:a', 'ask:b', 'ask:b']),
        GoalProgressMarks(owed: const ['ask:b', 'wake:a']),
      );
    });
  });

  group('mayResumeGoal', () {
    test("a requester's goal is the requester's alone, not an admin's", () {
      final goal = _goal(requester: 'ada');
      expect(
        mayResumeGoal(goal, userId: 'ada', role: WorkspaceRole.member),
        isTrue,
      );
      expect(
        mayResumeGoal(goal, userId: 'ben', role: WorkspaceRole.owner),
        isFalse,
      );
    });

    test("a goal nobody requested is an admin's", () {
      final goal = _goal();
      expect(
        mayResumeGoal(goal, userId: 'ben', role: WorkspaceRole.admin),
        isTrue,
      );
      expect(
        mayResumeGoal(goal, userId: 'ben', role: WorkspaceRole.member),
        isFalse,
      );
      expect(mayResumeGoal(goal, userId: 'ben', role: null), isFalse);
    });
  });

  group('AgentGoalRun times', () {
    test('are UTC whole seconds, so a goal equals itself read back', () {
      final local = DateTime(2026, 11, 19, 10, 0, 0, 123, 456);
      final goal = _goal(at: local);
      expect(goal.createdAt.isUtc, isTrue);
      expect(goal.createdAt.millisecond, 0);
      expect(
        goal.createdAt.isAtSameMomentAs(
          local.subtract(const Duration(milliseconds: 123, microseconds: 456)),
        ),
        isTrue,
      );
      final readBack = _goal(
        at: DateTime.fromMillisecondsSinceEpoch(
          goal.createdAt.millisecondsSinceEpoch,
        ),
      );
      expect(readBack, goal);
    });
  });

  group('GoalStartRefs.merged', () {
    const a = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
    const b = 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
    test('adds checkouts it has no start for and never changes one', () {
      final kept = GoalStartRefs({'app': a});
      final merged = GoalStartRefs.merged(
        kept,
        GoalStartRefs({'app': b, 'lib': b}),
      );
      expect(merged!.refs, {'app': a, 'lib': b});
      expect(GoalStartRefs.merged(null, kept), kept);
      expect(GoalStartRefs.merged(kept, null), same(kept));
      expect(GoalStartRefs.merged(kept, GoalStartRefs({'app': b})), same(kept));
    });
  });
}
