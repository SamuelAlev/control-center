import 'dart:convert';

import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/code_mode/domain/entities/code_execution.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_execution_port.dart';
import 'package:cc_domain/features/code_mode/domain/services/repl_tool_description.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_result_formatter.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_tool_descriptor.dart';
import 'package:cc_domain/features/dispatch/domain/modes/mode_capability_profile.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_harness/loop.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_infra/src/harness/harness_tool_registry_builder.dart';
import 'package:cc_infra/src/harness/harness_tool_search_tool.dart';
import 'package:cc_infra/src/harness/harness_tool_surface.dart';
import 'package:cc_infra/src/harness/mcp_tool_bridge.dart';
import 'package:cc_infra/src/harness/repl_tool.dart';
import 'package:test/test.dart';

const _deadline = Duration(seconds: 10);

class _Tool extends HarnessTool {
  _Tool(
    this.name, {
    this.approvalTier = ToolApprovalTier.read,
    this.scriptCallable = true,
  });

  @override
  final String name;
  @override
  final ToolApprovalTier approvalTier;
  @override
  final bool scriptCallable;
  int executions = 0;

  @override
  String get description => 'The $name operation.';
  @override
  Map<String, dynamic> get inputSchema => const {'type': 'object'};

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async {
    executions++;
    return HarnessToolResult.success('$name ran');
  }
}

/// Ends every script with [kind]: a refusal, or how a script ended.
class _Port implements CodeExecutionPort {
  _Port(this.kind);

  String? kind;
  int scripts = 0;

  @override
  CodeRunnerAvailability get availability =>
      const CodeRunnerAvailability.available();

  @override
  Future<CodeExecutionResult> execute(
    CodeExecutionRequest request, {
    required ScriptNestedCall callNested,
    CancellationToken cancel = CancellationToken.none,
  }) async {
    scripts++;
    final ended = kind;
    final refused =
        ended != null &&
        CodeExecutionErrorKind.withdrawsScripts.contains(ended);
    return CodeExecutionResult(
      result: ScriptResult(
        text: ended == null ? 'done' : 'The script ended: $ended.',
        isError: ended != null,
        truncated: false,
        outputChars: 4,
      ),
      execution: CodeExecution(
        id: 'exec-$scripts',
        runId: request.runId,
        toolCallId: request.parentToolCallId,
        surface: request.surface,
        startedAt: DateTime.utc(2026),
        durationMs: 1,
        status: ended == null
            ? CodeExecutionStatus.completed
            : refused
            ? CodeExecutionStatus.refused
            : CodeExecutionStatus.failed,
        errorKind: ended,
        sourceHash: '0' * 64,
        sourceBytes: 1,
        limits: request.limits,
      ),
      calls: const [],
    );
  }
}

final Map<String, _Tool> _tools = {};

HarnessToolRegistry _registry() {
  _tools
    ..clear()
    ..addAll({
      for (final t in [
        _Tool('read'),
        _Tool('write', approvalTier: ToolApprovalTier.write),
        _Tool('bash', approvalTier: ToolApprovalTier.exec),
        _Tool('search'),
        _Tool('ask_user'),
        _Tool('lsp'),
        _Tool('repl', scriptCallable: false),
        _Tool('get_ticket'),
        _Tool('list_tickets'),
        _Tool('ask_agent', scriptCallable: false),
        _Tool('list_my_tools', scriptCallable: false),
        _Tool(
          'submit_plan',
          approvalTier: ToolApprovalTier.write,
          scriptCallable: false,
        ),
      ])
        t.name: t,
    });
  return HarnessToolRegistry.of(_tools.values.toList());
}

/// A run in [mode] whose scripts end with [kind]: its resident tools (with
/// the run's own `repl`), deferred and script-only tools.
({List<HarnessTool> resident, HarnessToolSurface surface, _Port port}) _run(
  Mode mode,
  String? kind,
) {
  final profile = profileFor(mode);
  final surface = materializeHarnessToolSurface(
    registry: _registry(),
    surface: profile.toToolSurfaceSpec(),
    residency: profile.toToolResidencySpec(enabled: true),
  );
  final port = _Port(kind);
  final resident = bindReplTool(
    resident: surface.resident,
    scriptOnly: surface.scriptOnly,
    binding: ReplBinding(
      executions: port,
      run: ReplRunIdentity(
        workspaceId: 'ws-1',
        runId: 'run-1',
        readOnly: false,
        past: null,
      ),
      limits: CodeModeLimits.defaults,
    ),
  );
  return (resident: resident, surface: surface, port: port);
}

/// Calls [calls] one per turn (a `repl` call with a script), then answers.
class _Provider extends LlmProviderPort {
  _Provider(this.calls);

  final List<(String, Map<String, dynamic>)> calls;
  int turn = 0;

  @override
  String get displayName => 'Scripted';
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
    final i = turn++;
    if (i < calls.length) {
      final (name, args) = calls[i];
      yield LlmToolUseDelta(
        id: 'call_$i',
        name: name,
        argumentsJson: jsonEncode(args),
      );
      yield const LlmDone(stopReason: LlmStopReason.toolUse);
    } else {
      yield const LlmTextDelta('Done.');
      yield const LlmDone(stopReason: LlmStopReason.endTurn);
    }
  }
}

const _script = ('repl', {'code': 'return 1', 'description': 'try'});

Future<List<HarnessToolResult>> _loop(
  ({List<HarnessTool> resident, HarnessToolSurface surface, _Port port}) run,
  List<(String, Map<String, dynamic>)> calls,
) async {
  final events = <AgentLoopEvent>[];
  await const AgentLoopRunner()
      .run(
        history: <HarnessMessage>[],
        userMessage: 'Do the work.',
        tools: run.resident,
        deferredTools: run.surface.deferred,
        scriptTools: run.surface.scriptOnly,
        provider: _Provider(calls),
      )
      .forEach(events.add)
      .timeout(_deadline);
  return [for (final e in events.whereType<LoopToolCallResult>()) e.result];
}

void main() {
  test('after server_busy a script-only tool is called directly and returns '
      'its result', () async {
    final run = _run(Mode.chat, CodeExecutionErrorKind.serverBusy);
    expect(_names(run.surface.scriptOnly), contains('get_ticket'));
    final results = await _loop(run, [
      ('get_ticket', const {}),
      _script,
      ('get_ticket', const {}),
    ]);
    expect(results[0].content, contains('await tools["get_ticket"](args)'));
    expect(results[1].isError, isTrue);
    expect(results[1].withdrawsScripts, isTrue);
    expect(
      results[1].content,
      endsWith('\n\n${ReplToolDescription.scriptsWithdrawnSearch}'),
    );
    expect(results[2].isError, isFalse);
    expect(results[2].content, 'get_ticket ran');
    expect(_tools['get_ticket']!.executions, 1);
  });

  test('after the fallback search_tools loads a formerly script-only tool; '
      'before it, it points at a script', () async {
    final run = _run(Mode.chat, CodeExecutionErrorKind.auditUnavailable);
    final search = run.resident.whereType<HarnessToolSearchTool>().single;
    final repl = run.resident.whereType<ReplTool>().single;
    Future<HarnessToolResult> find() => search.execute({
      'query': 'get ticket',
    }, const HarnessToolContext(workingDirectory: '.'));

    final before = await find();
    expect(before.activateTools, isNot(contains('get_ticket')));
    expect(before.content, contains('"script_only":true'));

    final results = await _loop(run, [_script]);
    expect(results.single.withdrawsScripts, isTrue);
    expect(repl.lane.withdrawn, isTrue);

    final after = await find();
    expect(after.activateTools, contains('get_ticket'));
    expect(after.content, isNot(contains('script_only')));
  });

  test('a run whose scripts work is still redirected', () async {
    final run = _run(Mode.chat, null);
    final results = await _loop(run, [_script, ('get_ticket', const {})]);
    expect(results[0].isError, isFalse);
    expect(results[0].withdrawsScripts, isFalse);
    expect(results[1].isError, isTrue);
    expect(results[1].content, contains('await tools["get_ticket"](args)'));
    expect(_tools['get_ticket']!.executions, 0);
  });

  for (final kind in [
    CodeExecutionErrorKind.scriptError,
    CodeExecutionErrorKind.sourceTooLarge,
    CodeExecutionErrorKind.deadline,
    CodeExecutionErrorKind.heap,
    CodeExecutionErrorKind.callCap,
    CodeExecutionErrorKind.runBusy,
    CodeExecutionErrorKind.invalidToolCallId,
    CodeExecutionErrorKind.cancelled,
    CodeExecutionErrorKind.exited,
  ]) {
    test(
      '$kind, which the script or its call decides, keeps the redirect',
      () async {
        final run = _run(Mode.chat, kind);
        final results = await _loop(run, [_script, ('get_ticket', const {})]);
        expect(results[0].withdrawsScripts, isFalse);
        expect(
          results[0].content,
          isNot(contains(ReplToolDescription.scriptsWithdrawnSearch)),
        );
        expect(results[1].content, contains('await tools["get_ticket"](args)'));
        expect(_tools['get_ticket']!.executions, 0);
      },
    );
  }

  test('plan mode still forbids the write after the fallback', () async {
    final run = _run(Mode.plan, CodeExecutionErrorKind.serverBusy);
    final results = await _loop(run, [
      _script,
      ('get_ticket', const {}),
      ('write', const {}),
    ]);
    expect(results[0].withdrawsScripts, isTrue);
    expect(results[1].content, 'get_ticket ran');
    expect(results[2].isError, isTrue);
    expect(results[2].content, startsWith('Unknown tool: write.'));
    expect(_tools['write']!.executions, 0);
  });

  test('each binding has its own state: a subagent binds its own repl', () {
    final parent = _run(Mode.chat, null).resident.whereType<ReplTool>().single;
    final child = _run(Mode.chat, null).resident.whereType<ReplTool>().single;
    parent.lane.withdraw();
    expect(child.lane.withdrawn, isFalse);
  });

  group('namespaces', () {
    test('an external server named like a reserved namespace is never '
        'first-party nor script, on either lane', () {
      for (final server in ['builtin', 'control-center', 'script']) {
        final ns = scriptNamespaceFor(
          McpToolBridge(_Mcp('mcp__${server}__thing', server: server)),
        );
        expect(ns, 'external-$server');
        expect(ScriptToolNamespace.isExternal(ns), isTrue);
        expect(
          scriptNamespaceFor(_Tool('mcp__${server}__thing')),
          'external-$server',
        );
      }
      expect(
        ScriptToolNamespace.external('external-builtin'),
        'external-external-builtin',
      );
      expect(ScriptToolNamespace.external('github'), 'github');
    });
  });
}

List<String> _names(List<HarnessTool> tools) => [for (final t in tools) t.name];

class _Mcp extends McpTool {
  _Mcp(this.name, {this.server});

  @override
  final String name;
  final String? server;

  @override
  String? get serverName => server;
  @override
  String get description => 'mcp';
  @override
  Map<String, dynamic> get inputSchema => const {'type': 'object'};

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async =>
      CallResult.success('ok');
}
