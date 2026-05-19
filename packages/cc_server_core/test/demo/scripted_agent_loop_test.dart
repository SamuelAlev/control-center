import 'dart:math';

import 'package:cc_harness/cancellation.dart';
import 'package:cc_harness/loop.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_server_core/src/demo/demo_script.dart';
import 'package:cc_server_core/src/demo/scripted_agent_loop.dart';
import 'package:test/test.dart';

/// A provider that fails loudly if anything tries to complete against it.
///
/// The demo must never dial a model. Throwing here makes a wiring regression a
/// test failure instead of silent egress from a public server.
class _ExplodingProvider implements LlmProviderPort {
  @override
  String get displayName => 'Demo (exploding)';

  @override
  String get defaultModel => 'demo/scripted';

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('the demo provider must never be called');
}

DemoRunScript _script({String id = 's1', List<String> triggers = const []}) =>
    DemoRunScript(
      id: id,
      triggers: triggers,
      steps: const [
        DemoThinkingStep('Let me look at the diff.'),
        DemoSayStep('Reading the changed files now.'),
        DemoToolStep(
          tool: 'read',
          args: {'path': 'lib/auth.dart'},
          result: 'class Auth {}',
        ),
        DemoSayStep('That looks right.'),
        DemoUsageStep(inputTokens: 1200, outputTokens: 64, cacheReadTokens: 800),
      ],
    );

Future<List<AgentLoopEvent>> _drain(
  ScriptedAgentLoop loop, {
  String message = 'review the pr',
  List<HarnessMessage>? history,
  CancellationToken? cancel,
}) => loop
    .run(
      history: history ?? <HarnessMessage>[],
      userMessage: message,
      tools: const [],
      provider: _ExplodingProvider(),
      cancel: cancel,
    )
    .toList();

void main() {
  ScriptedAgentLoop build(List<DemoRunScript> scripts) => ScriptedAgentLoop(
    scripts: scripts,
    pacing: DemoPacing.instant,
    random: Random(7),
  );

  test('emits exactly one LoopDone and never touches the provider', () async {
    final events = await _drain(build([_script()]));
    expect(events.whereType<LoopDone>(), hasLength(1));
    expect(events.last, isA<LoopDone>());
    expect(
      (events.last as LoopDone).reason,
      LoopDoneReason.completed,
    );
  });

  test('replays the script beats in order', () async {
    final events = await _drain(build([_script()]));
    expect(events.whereType<LoopThinkingDelta>(), isNotEmpty);
    expect(events.whereType<LoopTextDelta>(), isNotEmpty);

    final start = events.whereType<LoopToolCallStart>().single;
    final result = events.whereType<LoopToolCallResult>().single;
    expect(start.toolName, 'read');
    expect(start.args['path'], 'lib/auth.dart');
    expect(result.toolUseId, start.toolUseId);
    expect(result.result.content, 'class Auth {}');
    expect(result.result.isError, isFalse);

    // The tool-call start must precede its result, and both must precede done.
    expect(
      events.indexOf(start) < events.indexOf(result),
      isTrue,
      reason: 'a tool result cannot precede its start',
    );
  });

  test('streamed text reassembles to the authored prose', () async {
    final events = await _drain(build([_script()]));
    final text = events
        .whereType<LoopTextDelta>()
        .map((e) => e.text)
        .join();
    expect(text, 'Reading the changed files now.That looks right.');
  });

  test('carries the authored usage through verbatim', () async {
    final events = await _drain(build([_script()]));
    final usage = events.whereType<LoopUsage>().single.usage;
    expect(usage.inputTokens, 1200);
    expect(usage.outputTokens, 64);
    expect(usage.cacheReadTokens, 800);
  });

  test('synthesizes usage for a script that declares none', () async {
    final loop = build([
      const DemoRunScript(
        id: 'bare',
        triggers: [],
        steps: [DemoSayStep('hello there friend')],
      ),
    ]);
    final usage = (await _drain(loop)).whereType<LoopUsage>().single.usage;
    // A run that reports zero tokens reads as broken, not cheap.
    expect(usage.outputTokens, greaterThan(0));
    expect(usage.inputTokens, greaterThan(0));
  });

  test('cancellation ends the run early, still with one LoopDone', () async {
    final source = CancellationTokenSource();
    source.cancel();
    final events = await _drain(
      build([_script()]),
      cancel: source.token,
    );
    expect(events.whereType<LoopDone>(), hasLength(1));
    expect((events.last as LoopDone).reason, LoopDoneReason.cancelled);
    // Nothing streamed: the token was already cancelled at the first beat.
    expect(events.whereType<LoopToolCallStart>(), isEmpty);
  });

  test('an explicit marker outranks keyword matching', () async {
    final loop = build([
      _script(id: 'alpha', triggers: ['review']),
      _script(id: 'beta', triggers: ['deploy']),
    ]);
    final events = await _drain(
      loop,
      message: 'review this [[demo:script=beta]]',
    );
    expect(
      events.whereType<LoopToolCallStart>().single.toolUseId,
      startsWith('beta-'),
    );
  });

  test('picks the best keyword match, longest trigger winning', () async {
    final loop = build([
      _script(id: 'short', triggers: ['pr']),
      _script(id: 'long', triggers: ['pull request']),
    ]);
    final events = await _drain(loop, message: 'look at this pull request pr');
    expect(
      events.whereType<LoopToolCallStart>().single.toolUseId,
      startsWith('long-'),
    );
  });

  test('falls back to the first script when nothing matches', () async {
    final loop = build([
      _script(id: 'first', triggers: ['nope']),
      _script(id: 'second', triggers: ['also-nope']),
    ]);
    final events = await _drain(loop, message: 'something unrelated entirely');
    expect(
      events.whereType<LoopToolCallStart>().single.toolUseId,
      startsWith('first-'),
    );
  });

  test('appends the user turn and the spoken reply to history', () async {
    final history = <HarnessMessage>[];
    await _drain(build([_script()]), history: history);
    expect(history, hasLength(2));
    expect(history.first.role, HarnessRole.user);
    expect(history.last.role, HarnessRole.assistant);
  });

  test('an empty catalogue errors rather than hanging', () async {
    final events = await _drain(build([]));
    expect(events.whereType<LoopError>(), hasLength(1));
    expect(events.whereType<LoopDone>(), hasLength(1));
  });

  test('decodes an authored fixture, rejecting an unknown step kind', () {
    final script = DemoRunScript.fromJson({
      'id': 'x',
      'triggers': ['Deploy'],
      'steps': [
        {'kind': 'say', 'text': 'hi'},
        {
          'kind': 'tool',
          'tool': 'grep',
          'args': {'q': 'TODO'},
          'result': 'none',
          'is_error': true,
        },
      ],
    });
    expect(script.triggers, ['deploy'], reason: 'triggers normalize to lower');
    expect((script.steps[1] as DemoToolStep).isError, isTrue);

    expect(
      () => DemoRunScript.fromJson({
        'id': 'y',
        'steps': [
          {'kind': 'wat'},
        ],
      }),
      throwsFormatException,
    );
  });
}
