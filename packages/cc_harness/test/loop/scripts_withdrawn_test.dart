import 'package:cc_harness/loop.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness/tools.dart';
import 'package:test/test.dart';

const _deadline = Duration(seconds: 10);

/// A tool that answers with [result] (or `<name> ran.`) and counts its runs.
class _Tool extends HarnessTool {
  _Tool(this.name, {this.result, this.scriptCallable = true});

  @override
  final String name;
  final HarnessToolResult? result;
  @override
  final bool scriptCallable;
  int executions = 0;

  @override
  String get description => 'A controlled operation named $name.';
  @override
  Map<String, dynamic> get inputSchema => const {'type': 'object'};
  @override
  ToolApprovalTier get approvalTier => ToolApprovalTier.read;
  @override
  bool get parallelSafe => false;

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async {
    executions++;
    return result ?? HarnessToolResult.success('$name ran.');
  }
}

/// Calls [calls] one per turn, then answers in text; records each request's
/// tool schemas.
class _Provider extends LlmProviderPort {
  _Provider(this.calls, {this.native = false});

  final List<String> calls;
  final bool native;
  int turn = 0;
  final sent = <List<LlmToolSchema>>[];

  @override
  String get displayName => 'Scripted';
  @override
  String get defaultModel => 'controlled';
  @override
  Future<List<ProviderModel>> listModels() async => const [];
  @override
  bool supportsDeferredTools({String? model}) => native;

  @override
  Stream<LlmEvent> complete({
    required List<HarnessMessage> messages,
    List<LlmToolSchema> tools = const [],
    LlmCompleteConfig config = const LlmCompleteConfig(),
  }) async* {
    sent.add(List.of(tools));
    final i = turn++;
    if (i < calls.length) {
      yield LlmToolUseDelta(id: 'call_$i', name: calls[i], argumentsJson: '{}');
      yield const LlmDone(stopReason: LlmStopReason.toolUse);
    } else {
      yield const LlmTextDelta('Done.');
      yield const LlmDone(stopReason: LlmStopReason.endTurn);
    }
  }
}

Future<(List<AgentLoopEvent>, _Provider)> _run({
  required HarnessToolResult replAnswer,
  required List<String> calls,
  required List<HarnessTool> scriptTools,
  List<HarnessTool> deferredTools = const [],
  List<HarnessTool> resident = const [],
  bool native = false,
}) async {
  final provider = _Provider(calls, native: native);
  final events = <AgentLoopEvent>[];
  await const AgentLoopRunner()
      .run(
        history: <HarnessMessage>[],
        userMessage: 'Do the work.',
        tools: [
          _Tool('repl', result: replAnswer, scriptCallable: false),
          _Tool('read'),
          ...resident,
        ],
        deferredTools: deferredTools,
        scriptTools: scriptTools,
        provider: provider,
      )
      .forEach(events.add)
      .timeout(_deadline);
  return (events, provider);
}

List<HarnessToolResult> _results(List<AgentLoopEvent> events) => [
  for (final e in events.whereType<LoopToolCallResult>()) e.result,
];

void main() {
  const refused = HarnessToolResult(
    content: 'The script was not run: no runner was free.',
    isError: true,
    withdrawsScripts: true,
  );
  const scriptFailed = HarnessToolResult(
    content: 'SyntaxError: unexpected token',
    isError: true,
  );

  test('after a refusal that withdraws scripts, a script-only tool is called '
      'directly, loaded on first use, and returns its result', () async {
    final lookup = _Tool('lookup');
    final (events, provider) = await _run(
      replAnswer: refused,
      calls: ['lookup', 'repl', 'lookup'],
      scriptTools: [lookup],
    );
    final results = _results(events);
    // Before: redirected to a script, and the tool did not run.
    expect(results[0].isError, isTrue);
    expect(results[0].content, contains('await tools["lookup"](args)'));
    // After: called directly.
    expect(results[2].isError, isFalse);
    expect(results[2].content, 'lookup ran.');
    expect(lookup.executions, 1);
    expect(events.whereType<LoopToolsActivated>().single.names, ['lookup']);
    expect([for (final s in provider.sent.last) s.name], contains('lookup'));
    expect([for (final s in provider.sent.first) s.name], ['repl', 'read']);
  });

  test('with native deferral the withdrawn tools are declared deferred and '
      'a direct call runs', () async {
    final lookup = _Tool('lookup');
    final (events, provider) = await _run(
      replAnswer: refused,
      calls: ['repl', 'lookup'],
      scriptTools: [lookup],
      deferredTools: [_Tool('other', scriptCallable: false)],
      native: true,
    );
    expect(_results(events)[1].content, 'lookup ran.');
    final declared = {for (final s in provider.sent[1]) s.name: s};
    expect(declared['lookup']?.deferLoading, isTrue);
    expect(provider.sent.first.map((s) => s.name), isNot(contains('lookup')));
  });

  test('a script that fails on its own keeps the redirect', () async {
    final lookup = _Tool('lookup');
    final (events, _) = await _run(
      replAnswer: scriptFailed,
      calls: ['repl', 'lookup'],
      scriptTools: [lookup],
    );
    final results = _results(events);
    expect(results[1].isError, isTrue);
    expect(results[1].content, contains('await tools["lookup"](args)'));
    expect(lookup.executions, 0);
    expect(events.whereType<LoopToolsActivated>(), isEmpty);
  });

  test(
    'a tool the run never admitted stays unknown after the fallback',
    () async {
      final (events, _) = await _run(
        replAnswer: refused,
        calls: ['repl', 'write'],
        scriptTools: [_Tool('lookup')],
      );
      final results = _results(events);
      expect(results[1].isError, isTrue);
      expect(results[1].content, startsWith('Unknown tool: write.'));
    },
  );

  group('an unknown tool\'s message names only tools the run has', () {
    /// Every backticked tool name in [message] (`name`, not `fn(args)`).
    Set<String> named(String message) => {
      for (final m in RegExp(r'`([a-z][a-z0-9_]*)`').allMatches(message))
        m.group(1)!,
    };

    Future<String> unknown({
      List<HarnessTool> resident = const [],
      HarnessToolResult repl = scriptFailed,
      List<String> before = const [],
    }) async {
      final (events, provider) = await _run(
        replAnswer: repl,
        calls: [...before, 'write'],
        scriptTools: [_Tool('lookup')],
        deferredTools: [_Tool('other', scriptCallable: false)],
        resident: resident,
      );
      final message = _results(events).last.content;
      final has = {for (final s in provider.sent.last) s.name, 'other'};
      expect(named(message).difference(has), isEmpty, reason: message);
      return message;
    }

    test('a run with repl and search_tools: no list_my_tools', () async {
      final message = await unknown(resident: [_Tool('search_tools')]);
      expect(message, contains('`search_tools`'));
      expect(message, contains('searchTools(query)'));
      expect(message, isNot(contains('list_my_tools')));
    });

    test('a run that has list_my_tools is told about it', () async {
      final message = await unknown(
        resident: [_Tool('search_tools'), _Tool('list_my_tools')],
      );
      expect(message, contains('`list_my_tools`'));
    });

    test('a run without search_tools, scripts withdrawn: neither', () async {
      final message = await unknown(repl: refused, before: ['repl']);
      expect(message, isNot(contains('search_tools')));
      expect(message, isNot(contains('searchTools')));
      expect(message, isNot(contains('list_my_tools')));
    });
  });
}
