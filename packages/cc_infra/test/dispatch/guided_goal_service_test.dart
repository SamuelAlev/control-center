import 'package:cc_harness/loop.dart';
import 'package:cc_infra/src/dispatch/adapter_one_shot_runner.dart';
import 'package:cc_infra/src/dispatch/guided_goal_service.dart';
import 'package:cc_infra/src/messaging/content_synthesizer_resolver.dart';
import 'package:test/test.dart';

import '../helpers/fake_agent_roster.dart';

class _ScriptedRunner implements AdapterOneShotRunner {
  _ScriptedRunner(this.replies);

  final List<String?> replies;
  final List<String> prompts = [];
  final List<String> systemPrompts = [];
  final List<({String adapterId, String? modelId})> runners = [];
  var _index = 0;

  @override
  Future<String?> complete({
    required String adapterId,
    String? modelId,
    required String systemPrompt,
    required String prompt,
    Duration timeout = const Duration(minutes: 2),
    int maxTokens = 1024,
  }) async {
    prompts.add(prompt);
    systemPrompts.add(systemPrompt);
    runners.add((adapterId: adapterId, modelId: modelId));
    return _index < replies.length ? replies[_index++] : null;
  }
}

/// A draft that covers all five requirements, so the review accepts it.
const _completeObjective = '''
## Objective
Make the auth tests pass.

## Success criteria
`fvm flutter test test/auth` exits 0.

## Verification
Run `fvm flutter test test/auth --concurrency=2`.

## Attempt cap
At most 5 attempts.

## Boundaries
Only modify lib/features/auth. Do not touch lib/core.

## Stop conditions
Stop and ask me if the fix needs a schema change.
''';

void main() {
  ContentSynthesizerResolver configured({String? persona}) =>
      ContentSynthesizerResolver(
        FakeAgentRoster()..put(
          contentSynthesizerAgent(
            workspaceId: 'ws',
            adapterId: 'claude-code',
            modelId: 'claude-sonnet-5',
            persona: persona,
          ),
        ),
      );

  GuidedGoalService build(
    _ScriptedRunner runner, {
    ContentSynthesizerResolver? synthesizer,
  }) => GuidedGoalService(
    runner: runner,
    synthesizer: synthesizer ?? configured(),
  );

  test('reports unavailable without a content synthesizer', () async {
    final service = build(
      _ScriptedRunner([]),
      synthesizer: ContentSynthesizerResolver(FakeAgentRoster()),
    );
    final step = await service.step(workspaceId: 'ws', roughObjective: 'fix the tests');
    expect(step.unavailable, isTrue);
    expect(step.question, isNull);
  });

  test('runs on the synthesizer agent, persona before the contract', () async {
    final runner = _ScriptedRunner([_completeObjective]);
    await build(
      runner,
      synthesizer: configured(persona: 'Keep questions under ten words.'),
    ).step(workspaceId: 'ws', roughObjective: 'fix auth');
    expect(runner.runners.single, (
      adapterId: 'claude-code',
      modelId: 'claude-sonnet-5',
    ));
    expect(
      runner.systemPrompts.single,
      startsWith('Keep questions under ten words.'),
    );
    expect(runner.systemPrompts.single, endsWith(guidedGoalSystemPrompt));
  });

  test('accepts a draft that covers all five requirements', () async {
    final service = build(_ScriptedRunner([_completeObjective]));
    final step = await service.step(workspaceId: 'ws', roughObjective: 'fix auth');
    expect(step.isReady, isTrue);
    expect(step.objective, contains('## Verification'));
    expect(step.missing, isEmpty);
  });

  test('refuses a draft the model CALLED complete but is not', () async {
    // The model announcing it is done is not the test. A model that decides
    // the objective "looks complete" is exactly what ends an interview early.
    final service = build(
      _ScriptedRunner(['''
## Objective
Make it work well.
'''],
      ),
    );
    final step = await service.step(workspaceId: 'ws', roughObjective: 'fix auth');
    expect(step.isReady, isFalse);
    expect(step.question, isNotNull);
    expect(
      step.missing,
      contains(GoalObjectiveRequirement.verification),
    );
  });

  test('surfaces the anti-pattern, not just the missing section', () async {
    final service = build(
      _ScriptedRunner(['''
## Objective
Keep going until it works.

## Success criteria
It works well.

## Verification
Run the tests.

## Attempt cap
At most 3.

## Boundaries
Only lib/.

## Stop conditions
Ask me if stuck.
'''],
      ),
    );
    final step = await service.step(workspaceId: 'ws', roughObjective: 'fix auth');
    expect(step.isReady, isFalse);
    expect(step.weaknesses, isNotEmpty);
    expect(step.weaknesses.join(' '), contains('works well'));
  });

  test('carries the transcript into the next prompt', () async {
    final runner = _ScriptedRunner(['What command proves it?']);
    await build(runner).step(
      workspaceId: 'ws',
      roughObjective: 'fix auth',
      transcript: ['Q: When is it done?', 'A: when the tests pass'],
    );
    expect(runner.prompts.single, contains('when the tests pass'));
    expect(runner.prompts.single, contains('fix auth'));
  });

  test('asks the model\'s own question when it asked one', () async {
    final runner = _ScriptedRunner([
      'Which command proves the auth tests pass?',
    ]);
    final step = await build(runner).step(workspaceId: 'ws', roughObjective: 'fix auth');
    expect(step.question, 'Which command proves the auth tests pass?');
  });

  test('emits the draft WITH its gaps once the turn cap is reached', () async {
    // Past the cap, naming what is still missing beats asking a seventh
    // question nobody will answer.
    final service = GuidedGoalService(
      runner: _ScriptedRunner(['## Objective\nMake it work well.\n']),
      synthesizer: configured(),
      maxTurns: 1,
    );
    final step = await service.step(
      workspaceId: 'ws',
      roughObjective: 'fix auth',
      transcript: ['Q: a', 'A: b'],
    );
    expect(step.isReady, isTrue);
    expect(step.missing, isNotEmpty);
  });

  test('a failed model call is not an objective', () async {
    final step = await build(_ScriptedRunner([null])).step(
      workspaceId: 'ws',
      roughObjective: 'fix auth',
    );
    expect(step.isReady, isFalse);
    expect(step.question, isNull);
    expect(step.unavailable, isFalse);
  });
}
