import 'dart:async';

import 'package:cc_harness/cancellation.dart';
import 'package:cc_harness/loop.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness/tools.dart';
import 'package:test/test.dart';

const _deadline = Duration(seconds: 10);

/// A tool whose result is its body's.
class _Tool extends HarnessTool {
  _Tool(this.name, {this.approvalTier = ToolApprovalTier.read, this._body});

  @override
  final String name;
  @override
  final ToolApprovalTier approvalTier;
  final Future<HarnessToolResult> Function(HarnessToolContext context)? _body;
  int executions = 0;

  @override
  bool get selfGuards => name == 'parent';
  @override
  bool get parallelSafe => false;
  @override
  String get description => 'A controlled operation.';
  @override
  Map<String, dynamic> get inputSchema => const {'type': 'object'};

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) {
    executions++;
    final body = _body;
    return body == null
        ? Future.value(HarnessToolResult.success('$name ran.'))
        : body(context);
  }
}

/// Calls [name] once, then answers in text.
class _Provider extends LlmProviderPort {
  _Provider(this.name);

  final String name;
  int _calls = 0;

  @override
  String get displayName => 'Outcome scenario';
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
    if (_calls++ == 0) {
      yield LlmToolUseDelta(id: 'call_$name', name: name, argumentsJson: '{}');
      yield const LlmDone(stopReason: LlmStopReason.toolUse);
    } else {
      yield const LlmTextDelta('Done.');
      yield const LlmDone(stopReason: LlmStopReason.endTurn);
    }
  }
}

class _DenyingHooks implements AgentLoopHooks {
  @override
  bool get interceptsTools => true;
  @override
  Future<void> onSessionStart() async {}
  @override
  Future<bool> preToolUse(String toolName, Map<String, dynamic> args) async =>
      false;
  @override
  Future<void> postToolUse(
    String toolName,
    String result, {
    required bool isError,
  }) async {}
}

/// Runs one direct call of [tool] and returns the result the loop reported.
Future<HarnessToolResult> _direct(
  _Tool tool, {
  AgentLoopConfig config = const AgentLoopConfig(),
}) async {
  final events = await const AgentLoopRunner()
      .run(
        history: <HarnessMessage>[],
        userMessage: 'Go.',
        tools: [tool],
        provider: _Provider(tool.name),
        config: config,
      )
      .toList()
      .timeout(_deadline);
  return events
      .whereType<LoopToolCallResult>()
      .singleWhere((e) => e.toolName == tool.name)
      .result;
}

AgentLoopConfig _approver(ToolGateDecision decision) => AgentLoopConfig(
  tools: LoopToolConfig(
    autoApprove: false,
    approvalCallback: (_) async => decision,
  ),
);

void main() {
  group('the gate names its refusals', () {
    test('an approver declining is denied', () async {
      final write = _Tool('write', approvalTier: ToolApprovalTier.write);
      final result = await _direct(
        write,
        config: _approver(const ToolGateDecision.deny(reason: 'not now')),
      );
      expect(result.isError, isTrue);
      expect(result.outcome, ToolOutcome.denied);
      expect(write.executions, 0);
    });

    test('no approver is denied', () async {
      final write = _Tool('write', approvalTier: ToolApprovalTier.write);
      final result = await _direct(
        write,
        config: const AgentLoopConfig(
          tools: LoopToolConfig(autoApprove: false),
        ),
      );
      expect(result.outcome, ToolOutcome.denied);
      expect(write.executions, 0);
    });

    test('a policy hook refusing is denied', () async {
      final read = _Tool('read');
      final result = await _direct(
        read,
        config: AgentLoopConfig(
          steering: LoopSteeringConfig(hooks: _DenyingHooks()),
        ),
      );
      expect(result.outcome, ToolOutcome.denied);
      expect(read.executions, 0);
    });
  });

  group('the loop names how it ended a call', () {
    test('a call past its time limit is timed_out', () async {
      final hang = _Tool(
        'hang',
        body: (_) => Completer<HarnessToolResult>().future,
      );
      final result = await _direct(
        hang,
        config: const AgentLoopConfig(
          tools: LoopToolConfig(toolTimeout: Duration(milliseconds: 50)),
        ),
      );
      expect(result.isError, isTrue);
      expect(result.outcome, ToolOutcome.timedOut);
    });

    test('a nested call its caller stops waiting for is cancelled', () async {
      final hang = _Tool(
        'hang',
        body: (_) => Completer<HarnessToolResult>().future,
      );
      final seen = Completer<ToolReentryOutcome>();
      final parent = _Tool(
        'parent',
        body: (context) async {
          final source = CancellationTokenSource();
          final pending = context.reentry!.call(
            'hang',
            const {},
            cancel: source.token,
          );
          source.cancel();
          seen.complete(await pending);
          return HarnessToolResult.success('script finished');
        },
      );
      final events = <AgentLoopEvent>[];
      await const AgentLoopRunner()
          .run(
            history: <HarnessMessage>[],
            userMessage: 'Go.',
            tools: [parent, hang],
            provider: _Provider('parent'),
          )
          .forEach(events.add)
          .timeout(_deadline);
      final outcome = await seen.future;
      expect(outcome.status, ToolReentryStatus.cancelled);
      expect(outcome.result.outcome, ToolOutcome.cancelled);
      final nested = events.whereType<LoopToolCallResult>().singleWhere(
        (e) => e.parentToolUseId == 'call_parent',
      );
      expect(nested.result.outcome, ToolOutcome.cancelled);
    });
  });

  group('nothing finer to say', () {
    test('a completed call and a plain failure carry no outcome', () async {
      expect((await _direct(_Tool('read'))).outcome, isNull);
      final failing = await _direct(
        _Tool('fail', body: (_) async => HarnessToolResult.error('broke')),
      );
      expect(failing.isError, isTrue);
      expect(failing.outcome, isNull);
    });

    test('a tool\'s own outcome reaches the loop unchanged', () async {
      final script = _Tool(
        'script',
        body: (_) async => const HarnessToolResult(
          content: 'Script ran out of memory.',
          isError: true,
          outcome: 'memory_exceeded',
        ),
      );
      expect((await _direct(script)).outcome, 'memory_exceeded');
    });

    test('withOutcome keeps every other field', () {
      const original = HarnessToolResult(
        content: 'text',
        isError: true,
        activateTools: {'a'},
        refusal: {'kind': 'k'},
        structured: {'n': 1},
      );
      final copy = original.withOutcome(ToolOutcome.denied);
      expect(copy.content, 'text');
      expect(copy.isError, isTrue);
      expect(copy.activateTools, {'a'});
      expect(copy.refusal, {'kind': 'k'});
      expect(copy.structured, {'n': 1});
      expect(copy.outcome, ToolOutcome.denied);
    });
  });
}
