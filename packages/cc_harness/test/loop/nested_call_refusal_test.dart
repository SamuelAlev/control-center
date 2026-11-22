import 'dart:async';
import 'dart:convert';

import 'package:cc_harness/loop.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness/tools.dart';
import 'package:test/test.dart';

const _deadline = Duration(seconds: 10);

/// A host's refusal of a nested call ([LoopToolConfig.nestedCallRefusal]) is
/// asked before the pre-tool hook, the approval callback and the tool, for a
/// script's call; a direct call is never asked, and its hook runs first as
/// before.
void main() {
  test('a refused nested call reaches no hook, no card and no tool; one the '
      'refusal lets through reaches all three', () async {
    final probe = _Probe();
    final run = _Run(
      probe,
      body: (reentry) async => [
        await reentry.call('exec', const {'command': 'long'}),
        await reentry.call('exec', const {'command': 'short'}),
      ],
    );
    final outcomes = await run.outcomes;

    final refused = outcomes[0];
    expect(refused.status, ToolReentryStatus.denied);
    expect(refused.gate?.verdict, ToolGateVerdict.denied);
    expect(refused.gate?.reason, 'Denied: too long');
    expect(refused.result.content, 'Denied: too long');
    expect(refused.result.outcome, ToolOutcome.denied);
    expect(outcomes[1].status, ToolReentryStatus.completed);

    expect(probe.asked, ['long', 'short'], reason: 'the refusal saw both');
    expect(probe.hooked, ['short'], reason: 'the hook saw only the second');
    expect(probe.carded, ['short']);
    expect(probe.ran, ['short']);
  });

  test(
    'a direct call is never asked: its hook and card run as before',
    () async {
      final probe = _Probe();
      final run = _Run(probe, direct: const {'command': 'long'});
      await run.done.timeout(_deadline);
      expect(probe.asked, isEmpty);
      expect(probe.hooked, ['long']);
      expect(probe.carded, ['long']);
      expect(probe.ran, ['long']);
    },
  );

  test('a refusal that throws refuses the call', () async {
    final probe = _Probe(throws: true);
    final run = _Run(
      probe,
      body: (reentry) async => [
        await reentry.call('exec', const {'command': 'short'}),
      ],
    );
    final outcome = (await run.outcomes).single;
    expect(outcome.status, ToolReentryStatus.denied);
    expect(outcome.gate?.reason, contains('the approval check failed'));
    expect(probe.hooked, isEmpty);
    expect(probe.ran, isEmpty);
  });

  test('a nested call the hook denies is recorded denied, with the hook\'s '
      'reason, and never reaches a card or the tool', () async {
    final probe = _Probe(hookDenies: true);
    final run = _Run(
      probe,
      body: (reentry) async => [
        await reentry.call('exec', const {'command': 'short'}),
      ],
    );
    final outcome = (await run.outcomes).single;
    expect(outcome.status, ToolReentryStatus.denied);
    expect(outcome.gate?.verdict, ToolGateVerdict.denied);
    expect(outcome.gate?.reason, 'Denied by policy hook.');
    expect(outcome.result.outcome, ToolOutcome.denied);
    expect(probe.hooked, ['short']);
    expect(probe.carded, isEmpty);
    expect(probe.ran, isEmpty);
  });
}

/// Records what each gate step saw, by the call's `command`.
class _Probe {
  _Probe({this.throws = false, this.hookDenies = false});

  final bool throws;
  final bool hookDenies;
  final asked = <String>[];
  final hooked = <String>[];
  final carded = <String>[];
  final ran = <String>[];

  String? refuse(HarnessTool tool, Map<String, dynamic> args) {
    final command = '${args['command']}';
    asked.add(command);
    if (throws) {
      throw StateError('no audit');
    }
    return command == 'long' ? 'too long' : null;
  }

  AgentLoopConfig config() => AgentLoopConfig(
    steering: LoopSteeringConfig(hooks: _Hooks(this)),
    tools: LoopToolConfig(
      autoApprove: false,
      nestedCallRefusal: refuse,
      approvalCallback: (request) async {
        carded.add('${request.args['command']}');
        return const ToolGateDecision.allow(askedPerson: true);
      },
    ),
  );
}

class _Hooks implements AgentLoopHooks {
  _Hooks(this.probe);

  final _Probe probe;

  @override
  bool get interceptsTools => true;
  @override
  Future<void> onSessionStart() async {}
  @override
  Future<bool> preToolUse(String toolName, Map<String, dynamic> args) async {
    if (toolName != 'exec') {
      return true;
    }
    probe.hooked.add('${args['command']}');
    return !probe.hookDenies;
  }

  @override
  Future<void> postToolUse(
    String toolName,
    String result, {
    required bool isError,
  }) async {}
}

/// An exec-tier tool that runs what it is handed.
class _Exec extends HarnessTool {
  _Exec(this.probe);

  final _Probe probe;

  @override
  String get name => 'exec';
  @override
  String get description => 'Runs a command.';
  @override
  Map<String, dynamic> get inputSchema => const {'type': 'object'};
  @override
  ToolApprovalTier get approvalTier => ToolApprovalTier.exec;
  @override
  String? executedContent(Map<String, dynamic> args) => '${args['command']}';

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async {
    probe.ran.add('${args['command']}');
    return HarnessToolResult.success('ran');
  }
}

/// The parent: read-tier and self-guarding (the shape `repl` has), running
/// [body] with its reentry.
class _Parent extends HarnessTool {
  _Parent(this.body);

  final Future<List<ToolReentryOutcome>> Function(ToolReentry reentry) body;
  final outcomes = Completer<List<ToolReentryOutcome>>();

  @override
  String get name => 'parent';
  @override
  String get description => 'Runs a script.';
  @override
  Map<String, dynamic> get inputSchema => const {'type': 'object'};
  @override
  ToolApprovalTier get approvalTier => ToolApprovalTier.read;
  @override
  bool get selfGuards => true;
  @override
  bool get parallelSafe => false;

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async {
    try {
      outcomes.complete(await body(context.reentry!));
    } on Object catch (e, st) {
      outcomes.completeError(e, st);
    }
    return HarnessToolResult.success('script finished');
  }
}

class _Run {
  _Run(
    _Probe probe, {
    Future<List<ToolReentryOutcome>> Function(ToolReentry reentry)? body,
    Map<String, dynamic>? direct,
  }) : parent = _Parent(body ?? (_) async => const []) {
    done = const AgentLoopRunner()
        .run(
          history: <HarnessMessage>[],
          userMessage: 'Run it.',
          tools: [parent, _Exec(probe)],
          provider: _Provider(direct == null ? 'parent' : 'exec', direct),
          config: probe.config(),
        )
        .drain<void>();
  }

  final _Parent parent;
  late final Future<void> done;

  Future<List<ToolReentryOutcome>> get outcomes async {
    final value = await parent.outcomes.future.timeout(_deadline);
    await done.timeout(_deadline);
    return value;
  }
}

/// Calls [name] with [args] on turn one, then answers in text.
class _Provider extends LlmProviderPort {
  _Provider(this.name, this.args);

  final String name;
  final Map<String, dynamic>? args;
  int calls = 0;

  @override
  String get displayName => 'Refusal scenario';
  @override
  String get defaultModel => 'controlled';
  @override
  Future<List<ProviderModel>> listModels() async => const [];

  @override
  Stream<LlmEvent> complete({
    required List<HarnessMessage> messages,
    List<LlmToolSchema> tools = const [],
    LlmCompleteConfig config = const LlmCompleteConfig(),
  }) async* {
    if (calls++ == 0) {
      yield LlmToolUseDelta(
        id: 'call_$name',
        name: name,
        argumentsJson: jsonEncode(args ?? const {}),
      );
      yield const LlmDone(stopReason: LlmStopReason.toolUse);
    } else {
      yield const LlmTextDelta('Done.');
      yield const LlmDone(stopReason: LlmStopReason.endTurn);
    }
  }
}
