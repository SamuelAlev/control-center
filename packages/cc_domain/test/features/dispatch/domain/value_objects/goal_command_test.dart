import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_checker_choice.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_command.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_contract.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_unattended_policy.dart';
import 'package:cc_domain/src/errors/app_exceptions.dart';
import 'package:test/test.dart';

Matcher _refused(String fragment, {String kind = goalCommandInvalidKind}) =>
    throwsA(
      isA<ValidationException>()
          .having((e) => e.code, 'code', kind)
          .having((e) => e.message, 'message', contains(fragment)),
    );

Agent _agent(String id, String name) => Agent(
  id: id,
  name: name,
  title: name,
  agentMdPath: '/agents/$id.md',
  workspaceId: 'ws-1',
  skills: AgentSkills(const []),
  createdAt: DateTime.utc(2026),
);

void main() {
  group('flags', () {
    test('no flags: the objective as typed, no contract', () {
      final command = GoalCommand.parse('  Ship the feature  ');
      expect(command.objective, 'Ship the feature');
      expect(command.contract, isNull);
      expect(command.maxRuns, isNull);
      expect(command.budgetMicros, isNull);
      expect(command.days, isNull);
      expect(command.checkerRef, isNull);
      expect(command.fresh, isFalse);
      expect(command.unattended, isNull);
    });

    test('flags after the objective (how the phone sends them)', () {
      final command = GoalCommand.parse(
        'Ship it --max 10 --budget 12.50 --days 3',
      );
      expect(command.objective, 'Ship it');
      expect(command.maxRuns, 10);
      expect(command.budgetMicros, 12500000);
      expect(command.days, 3);
    });

    test('every flag before the objective', () {
      final command = GoalCommand.parse(
        '--max 4 --budget \$20 --days 2 --check "fvm flutter test '
        '--concurrency=2" --check \'make lint\' --checker Mira --fresh '
        '--unattended assume Keep cc_domain green',
      );
      expect(command.objective, 'Keep cc_domain green');
      expect(command.maxRuns, 4);
      expect(command.budgetMicros, 20000000);
      expect(command.days, 2);
      expect(command.checkerRef, 'Mira');
      expect(command.fresh, isTrue);
      expect(command.unattended, GoalUnattendedPolicy.assume);
      expect(command.contract!.checks, [
        GoalCheck(run: 'fvm flutter test --concurrency=2'),
        GoalCheck(run: 'make lint'),
      ]);
      expect(
        command.contract!.checks.first.timeoutSeconds,
        GoalCheck.defaultTimeoutSeconds,
      );
      expect(command.contract!.criteria, isEmpty);
    });

    test('--unattended wait; a backticked check and checker name', () {
      final command = GoalCommand.parse(
        'Fix it --unattended wait --check `dart test -r expanded` '
        '--checker "Code Reviewer"',
      );
      expect(command.unattended, GoalUnattendedPolicy.wait);
      expect(command.contract!.checks.single.run, 'dart test -r expanded');
      expect(command.checkerRef, 'Code Reviewer');
      expect(command.objective, 'Fix it');
    });

    test('at most five checks', () {
      final five = List.filled(5, '--check "make t"').join(' ');
      expect(GoalCommand.parse('Go $five').contract!.checks, hasLength(5));
      expect(
        () => GoalCommand.parse('Go $five --check "one more"'),
        _refused('at most 5 checks'),
      );
    });

    test('an unknown flag is refused, naming the known ones', () {
      expect(
        () => GoalCommand.parse('Ship it --budjet 10'),
        _refused('Unknown flag --budjet. /goal knows --max, --budget'),
      );
      expect(
        () => GoalCommand.parse('--loud Ship it'),
        _refused('Unknown flag --loud'),
      );
    });

    test('a --word in backticks or code blocks stays in the objective', () {
      final command = GoalCommand.parse(
        'Make `fvm flutter analyze --fatal-infos` pass and keep '
        'a`b --verbose c` as it is\n```\nrun --all --max\n```',
      );
      expect(
        command.objective,
        'Make `fvm flutter analyze --fatal-infos` pass and keep '
        'a`b --verbose c` as it is\n```\nrun --all --max\n```',
      );
      expect(command.maxRuns, isNull);
      expect(command.contract, isNull);
    });

    test('a value that is not one is refused', () {
      expect(() => GoalCommand.parse('Go --max'), _refused('--max needs'));
      expect(() => GoalCommand.parse('Go --max abc'), _refused('--max needs'));
      expect(() => GoalCommand.parse('Go --max 0'), _refused('at least 1'));
      expect(() => GoalCommand.parse('Go --days -2'), _refused('--days needs'));
      expect(
        () => GoalCommand.parse('Go --budget free'),
        _refused('--budget needs an amount'),
      );
      expect(
        () => GoalCommand.parse('Go --unattended maybe'),
        _refused('--unattended takes wait or assume'),
      );
      expect(
        () => GoalCommand.parse('Go --check --fresh'),
        _refused('--check needs a command'),
      );
      expect(() => GoalCommand.parse('Go --checker'), _refused('--checker'));
      expect(
        () => GoalCommand.parse('Go --check "${'x' * 1001}"'),
        _refused('--check'),
      );
    });

    test('a flag given twice is refused; --check repeats', () {
      expect(
        () => GoalCommand.parse('Go --max 2 --max 3'),
        _refused('--max is given twice'),
      );
      expect(
        () => GoalCommand.parse('Go --fresh --fresh'),
        _refused('--fresh is given twice'),
      );
    });

    test('flags only: an empty objective, for the caller to refuse', () {
      expect(GoalCommand.parse('--max 3').objective, isEmpty);
    });

    test('a leading number is part of the objective', () {
      expect(
        GoalCommand.parse('10 fix the tests').objective,
        '10 fix the tests',
      );
    });

    test('an apostrophe does not swallow the flags after it', () {
      final command = GoalCommand.parse("Don't break the build --max 3");
      expect(command.objective, "Don't break the build");
      expect(command.maxRuns, 3);
    });
  });

  group("the guided dialog's sections", () {
    const guided = '''
## Objective
Make the importer accept v2 files.

## Success criteria
- All importer tests pass
- A v2 sample file imports
  without warnings
- [ ] No v1 behaviour changes

## Verification
Run `fvm dart test test/importer`.

## Boundaries
Only lib/importer.

## Stop conditions
A schema change is needed.''';

    test('criteria, boundaries and stop conditions become the contract; the '
        'objective and verification stay', () {
      final command = GoalCommand.parse(guided);
      expect(command.contract!.criteria, [
        'All importer tests pass',
        'A v2 sample file imports without warnings',
        'No v1 behaviour changes',
      ]);
      expect(command.contract!.boundaries, 'Only lib/importer.');
      expect(command.contract!.stopWhen, 'A schema change is needed.');
      expect(command.contract!.checks, isEmpty);
      expect(
        command.objective,
        '## Objective\nMake the importer accept v2 files.\n\n'
        '## Verification\nRun `fvm dart test test/importer`.',
      );
    });

    test('criteria without bullets: one per line', () {
      final command = GoalCommand.parse(
        'Do it\n## Success criteria\nTests pass\n\nLint is clean\n',
      );
      expect(command.contract!.criteria, ['Tests pass', 'Lint is clean']);
      expect(command.objective, 'Do it');
    });

    test('numbered criteria', () {
      final command = GoalCommand.parse(
        'Do it\n## Success criteria\n1. Tests pass\n2) Lint is clean',
      );
      expect(command.contract!.criteria, ['Tests pass', 'Lint is clean']);
    });

    test('limits are refused with the limit, never cut', () {
      final thirteen = [for (var i = 0; i < 13; i++) '- item $i'].join('\n');
      expect(
        () => GoalCommand.parse('Do it\n## Success criteria\n$thirteen'),
        _refused('at most 12 items; this has 13'),
      );
      expect(
        () => GoalCommand.parse('Do it\n## Success criteria\n- ${'x' * 301}'),
        _refused('at most 300 characters; item 1 has 301'),
      );
      expect(
        () => GoalCommand.parse('Do it\n## Boundaries\n${'x' * 1001}'),
        _refused('Boundaries: at most 1000 characters'),
      );
      expect(
        () => GoalCommand.parse('Do it\n## Stop conditions\n${'x' * 1001}'),
        _refused('Stop conditions: at most 1000 characters'),
      );
    });

    test('a section twice is refused', () {
      expect(
        () => GoalCommand.parse('Do it\n## Boundaries\na\n## Boundaries\nb'),
        _refused('there twice'),
      );
    });

    test('the checks section round-trips, and adds to --check', () {
      final checks = [
        GoalCheck(run: 'fvm flutter test --concurrency=2', timeoutSeconds: 900),
        GoalCheck(run: 'smoke', where: GoalCheckLocation.environment),
        GoalCheck(run: 'echo `date`'),
      ];
      final section = GoalCommand.checksSection(checks);
      expect(
        section,
        '## Checks\n'
        '- `fvm flutter test --concurrency=2` (900 s)\n'
        '- environment task `smoke` (300 s)\n'
        '- `` echo `date` `` (300 s)',
      );
      final command = GoalCommand.parse(
        'Do it\n\n$section\n\n--checker agent-2 --check "make lint"',
      );
      expect(command.contract!.checks, [
        ...checks,
        GoalCheck(run: 'make lint'),
      ]);
      expect(command.checkerRef, 'agent-2');
      expect(command.objective, 'Do it');
    });

    test('a checks line that is not a check is refused', () {
      expect(
        () => GoalCommand.parse('Do it\n## Checks\n- run the tests'),
        _refused('line 1 is not a check'),
      );
      expect(
        () => GoalCommand.parse('Do it\n## Checks\n- `make` (5000 s)'),
        _refused('## Checks: line 1'),
      );
    });

    test('six checks between the section and the flags are refused', () {
      final section = GoalCommand.checksSection([
        for (var i = 0; i < 5; i++) GoalCheck(run: 'c$i'),
      ]);
      expect(
        () => GoalCommand.parse('Do it\n$section\n--check "one more"'),
        _refused('at most 5 checks; this one has 6'),
      );
    });

    test('headings inside a code block are not sections', () {
      final command = GoalCommand.parse(
        'Write a README with\n```\n## Boundaries\nnone\n```',
      );
      expect(command.contract, isNull);
    });
  });

  group('choosing a checker', () {
    final agents = [
      _agent('agent-1', 'Ada'),
      _agent('agent-2', 'Mira'),
      _agent('agent-3', 'Bo'),
      _agent('agent-4', 'bo'),
    ];

    test('by id or by name, ignoring case', () {
      expect(
        chooseGoalChecker('agent-2', agents: agents, goalAgentId: 'agent-1').id,
        'agent-2',
      );
      expect(
        chooseGoalChecker(' mira ', agents: agents, goalAgentId: 'agent-1').id,
        'agent-2',
      );
      expect(
        chooseGoalChecker('agent-4', agents: agents, goalAgentId: 'agent-1').id,
        'agent-4',
      );
    });

    test('unknown lists the candidates, without the goal agent', () {
      expect(
        () => chooseGoalChecker('Zed', agents: agents, goalAgentId: 'agent-1'),
        _refused(
          'The checker can be: Bo, bo, Mira.',
          kind: goalCheckerUnknownKind,
        ),
      );
    });

    test('ambiguous lists the matches with their ids', () {
      expect(
        () => chooseGoalChecker('BO', agents: agents, goalAgentId: 'agent-1'),
        _refused('Bo (agent-3), bo (agent-4)', kind: goalCheckerAmbiguousKind),
      );
    });

    test("the goal's own agent is refused", () {
      expect(
        () => chooseGoalChecker('Ada', agents: agents, goalAgentId: 'agent-1'),
        _refused('pursuing this goal', kind: goalCheckerIsGoalAgentKind),
      );
    });
  });
}
