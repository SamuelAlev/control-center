import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_start_refs.dart';
import 'package:test/test.dart';

void main() {
  final sha1 = 'a' * 40;
  final sha256 = 'b' * 64;

  test('a checkout maps to a full commit id or to no commit', () {
    final refs = GoalStartRefs({
      'app': sha1,
      'api': sha256,
      'docs': GoalStartRefs.noCommit,
    });
    expect(refs.refs['docs'], '');
    expect(() => refs.refs['x'] = sha1, throwsUnsupportedError);
  });

  test('a malformed entry is refused', () {
    for (final bad in <Map<String, String>>[
      {'': sha1},
      {'a/b': sha1},
      {'..': sha1},
      {'app': 'HEAD'},
      {'app': 'A' * 40},
      {'app': 'a' * 39},
      {'x' * 256: sha1},
    ]) {
      expect(() => GoalStartRefs(bad), throwsArgumentError, reason: '$bad');
    }
    expect(
      () => GoalStartRefs({for (var i = 0; i < 257; i++) 'r$i': sha1}),
      throwsArgumentError,
    );
  });

  test('the JSON and stored forms round-trip; anything else reads as null', () {
    final refs = GoalStartRefs({'app': sha1, 'docs': ''});
    expect(GoalStartRefs.tryFromJson(refs.toJson()), refs);
    expect(GoalStartRefs.tryParse(refs.encode()), refs);
    expect(GoalStartRefs.tryParse(null), isNull);
    expect(GoalStartRefs.tryParse('not json'), isNull);
    expect(GoalStartRefs.tryParse('[1]'), isNull);
    expect(GoalStartRefs.tryFromJson({'app': 3}), isNull);
    expect(GoalStartRefs.tryFromJson({'app': 'HEAD'}), isNull);
  });

  test('equality is by entries, in any order', () {
    final a = GoalStartRefs({'app': sha1, 'docs': ''});
    final b = GoalStartRefs({'docs': '', 'app': sha1});
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(GoalStartRefs({'app': sha1})));
  });

  test('a goal carries its start refs through copyWith and equality', () {
    final goal = AgentGoalRun(
      id: 'g-1',
      workspaceId: 'ws-1',
      spaceId: 'sp-1',
      conversationId: 'c-1',
      agentId: 'a-1',
      userText: 'ship it',
      costCapMicros: 1000000,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
    expect(goal.startRefs, isNull);
    final started = goal.copyWith(startRefs: GoalStartRefs({'app': sha1}));
    expect(started.startRefs!.refs['app'], sha1);
    expect(started, isNot(goal));
    expect(started.copyWith(summary: 'x').startRefs, started.startRefs);
  });
}
