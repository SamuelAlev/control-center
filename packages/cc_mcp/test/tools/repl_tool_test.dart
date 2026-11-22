// ignore_for_file: avoid_dynamic_calls

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/value_objects/script_call_origin.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_execution_port.dart';
import 'package:cc_domain/features/code_mode/domain/ports/script_past_port.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_tool_descriptor.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_call_scope.dart';
import 'package:cc_harness/tools.dart' show ToolApprovalTier;
import 'package:cc_mcp/src/mcp_tool_dispatcher.dart';
import 'package:cc_mcp/src/tools/repl_tool.dart';
import 'package:test/test.dart';

import '../code_mode_fakes.dart';

/// `repl` on the MCP surface: who may call it, what it hands the execution
/// service, and that its scripts' calls come back through the dispatcher.
void main() {
  late FakeExecutions executions;
  late FakeRecords records;
  late ReplMcpTool repl;
  late ProbeTool reader;
  late McpToolDispatcher dispatcher;

  setUp(() {
    records = FakeRecords();
    executions = FakeExecutions(records: records);
    repl = ReplMcpTool(
      executions: executions,
      limitsFor: (_) async => CodeModeLimits.defaults,
      records: records,
      past: null,
    );
    reader = ProbeTool('read_thing');
    dispatcher = McpToolDispatcher(
      registry: McpToolRegistry([reader, ProbeTool('todo_write'), repl]),
    );
    repl.bind(dispatcher);
  });

  Future<Map<String, dynamic>> call(
    McpCallScope? scope, {
    Map<String, dynamic> meta = const {},
  }) async {
    final response = await dispatcher.handleScopedRequest(
      JsonRpcRequest(
        method: 'tools/call',
        params: {
          'name': 'repl',
          'arguments': {
            'workspace_id': 'ws-other',
            'code': 'return 1',
            'description': 'Count things',
          },
          '_meta': meta,
        },
        id: 1,
      ),
      scope: scope,
    );
    return response['result'] as Map<String, dynamic>;
  }

  String text(Map<String, dynamic> result) =>
      result['content'][0]['text'] as String;

  test('is read tier, effect-free and needs a run grant', () {
    expect(repl.name, 'repl');
    expect(repl.requiresRunGrant, isTrue);
    expect(repl.actionClasses, isEmpty);
    expect(repl.isMutating, isFalse);
    expect(repl.toolApproval(const {}).tier.wire, 'read');
    expect(repl.inputSchema['required'], contains('workspace_id'));
    expect(repl.inputSchema['required'], contains('code'));
  });

  test('is refused without a run grant', () async {
    final result = await call(
      const McpCallScope(workspaceId: 'ws-own', agentId: 'agent-1'),
    );
    expect(result['isError'], isTrue);
    expect(text(result), contains('agent run'));
    expect(executions.requests, isEmpty);
  });

  test('is refused when the runner is unavailable', () async {
    executions.availability = const CodeRunnerAvailability.unavailable(
      'seccomp is not available',
    );
    final result = await call(runScope());
    expect(result['isError'], isTrue);
    expect(text(result), contains('seccomp is not available'));
    expect(executions.requests, isEmpty);
  });

  test('runs the script for the attested run, keyed by its run log', () async {
    final result = await call(
      runScope(),
      meta: {'claudecode/toolUseId': 'toolu_abc'},
    );
    expect(result['isError'], isFalse);
    expect(text(result), 'done');
    final request = executions.requests.single;
    expect(request.workspaceId, 'ws-own');
    expect(request.runId, 'log-1');
    expect(request.parentToolCallId, 'toolu_abc');
    expect(request.surface, CodeExecutionSurface.mcp);
    expect(request.conversationId, 'conv-1');
    expect(request.agentId, 'agent-1');
    expect(request.spaceId, 'sp-1');
    expect(request.code, 'return 1');
    expect(request.description, 'Count things');
    expect(
      request.tools.map((t) => t.name),
      unorderedEquals(['read_thing', 'todo_write']),
    );
    final probe = request.tools.firstWhere((t) => t.name == 'read_thing');
    expect(probe.namespace, ScriptToolNamespace.controlCenter);
    expect(probe.tier, ToolApprovalTier.read);
    // The workspace is the run's, so the script never passes it.
    expect(
      (probe.inputSchema['properties'] as Map).containsKey('workspace_id'),
      isFalse,
    );
  });

  test('without a run log no script runs: it could not be recorded', () async {
    final result = await call(runScope(runLogId: null));
    expect(result['isError'], isTrue);
    expect(text(result), contains('has no run log'));
    expect(executions.requests, isEmpty);
  });

  test('without an adapter id the server names the call', () async {
    await call(runScope());
    expect(executions.requests.single.parentToolCallId, startsWith('repl-'));
  });

  group('what a script reads of its past', () {
    late List<String> bound;
    late _Past port;

    setUp(() {
      bound = [];
      port = _Past();
      repl = ReplMcpTool(
        executions: executions,
        limitsFor: (_) async => CodeModeLimits.defaults,
        records: records,
        past:
            ({
              required String runLogId,
              required String workspaceId,
              required String? conversationId,
              required String? spaceId,
            }) {
              bound.add('$runLogId $workspaceId $conversationId $spaceId');
              return port;
            },
      );
      dispatcher = McpToolDispatcher(
        registry: McpToolRegistry([reader, ProbeTool('todo_write'), repl]),
      );
      repl.bind(dispatcher);
    });

    test('is bound from the attested scope, never the arguments', () async {
      // The call's arguments name `ws-other`; the scope names `ws-own`.
      await call(runScope());
      expect(bound, ['log-1 ws-own conv-1 sp-1']);
      expect(executions.requests.single.past, same(port));
    });

    test('names no conversation that is only the dispatch id', () async {
      await call(runScope(conversationId: 'dispatch-1'));
      expect(bound, ['log-1 ws-own null sp-1']);
    });

    test('a read-only run is bound the same way and runs read-only', () async {
      await call(
        const McpCallScope(
          workspaceId: 'ws-own',
          conversationId: 'conv-1',
          spaceId: 'sp-1',
          attested: true,
          runId: 'dispatch-1',
          runLogId: 'log-1',
          readOnly: true,
        ),
      );
      expect(bound, ['log-1 ws-own conv-1 sp-1']);
      expect(executions.requests.single.readOnly, isTrue);
    });
  });

  test('passes no conversation that is only the dispatch id', () async {
    await call(runScope(conversationId: 'dispatch-1', agentId: null));
    final request = executions.requests.single;
    expect(request.conversationId, isNull);
    expect(request.agentId, isNull);
  });

  test('its scripts\' calls go through the dispatcher, with the origin the '
      'execution service gave each', () async {
    NestedCallOutcome? seen;
    executions.script = (callNested, request) async {
      seen = await callNested(
        nestedRequest('read_thing', arguments: {'path': 'x'}),
      );
      final again = await callNested(nestedRequest('repl', sequence: 2));
      return '${seen!.value} ${again.status.wire}';
    };
    final approver = Approver();
    dispatcher = McpToolDispatcher(
      registry: McpToolRegistry([
        reader,
        ProbeTool('ask_thing', requiresApproval: true),
        repl,
      ]),
      confirmationPort: approver,
    );
    repl.bind(dispatcher);
    final result = await call(
      runScope(),
      meta: {'claudecode/toolUseId': 'toolu_abc'},
    );
    expect(text(result), 'ok unknown_tool');
    expect(reader.lastArgs, {'workspace_id': 'ws-own', 'path': 'x'});

    // The service names the execution: `toolu_def` ran before in this run,
    // so this one is `#2`. The card names exactly that, not an id `repl`
    // derived on its own.
    executions.script = (callNested, request) async {
      expect(request.parentToolCallId, 'toolu_def');
      await callNested(
        nestedRequest(
          'ask_thing',
          origin: ScriptCallOrigin(
            parentToolCallId: request.parentToolCallId,
            executionId: 'log-1/toolu_def#2',
          ),
        ),
      );
      return 'asked';
    };
    await call(runScope(), meta: {'claudecode/toolUseId': 'toolu_def'});
    final origin = approver.requests.single.origin!;
    expect(origin.parentToolCallId, 'toolu_def');
    expect(origin.executionId, 'log-1/toolu_def#2');
  });

  group('the caller\'s call id', () {
    for (final bad in [
      '',
      'toolu/1',
      'toolu#2',
      'log-1/toolu_abc',
      'tool use',
      'toolü',
      'x' * 129,
    ]) {
      test('"${bad.length > 20 ? '${bad.substring(0, 8)}…' : bad}" is not '
          'used: the server names the call', () async {
        final result = await call(
          runScope(),
          meta: {'claudecode/toolUseId': bad},
        );
        expect(result['isError'], isFalse);
        expect(
          executions.requests.single.parentToolCallId,
          matches(RegExp(r'^repl-[0-9a-f-]{36}$')),
        );
      });
    }

    test('of the longest allowed shape is used', () async {
      final id = 'a-_Z9' * 25 + 'abc';
      expect(id.length, 128);
      await call(runScope(), meta: {'claudecode/toolUseId': id});
      expect(executions.requests.single.parentToolCallId, id);
    });

    test('that already ran a script in this run is refused, and nothing '
        'runs', () async {
      await call(runScope(), meta: {'claudecode/toolUseId': 'toolu_abc'});
      final again = await call(
        runScope(),
        meta: {'claudecode/toolUseId': 'toolu_abc'},
      );
      expect(again['isError'], isTrue);
      expect(text(again), contains('already ran a script'));
      expect(executions.requests, hasLength(1));
      expect(records.probed, ['log-1/toolu_abc', 'log-1/toolu_abc']);
    });

    test('that ran in another run is used', () async {
      await call(runScope(), meta: {'claudecode/toolUseId': 'toolu_abc'});
      final other = await call(
        runScope(runLogId: 'log-2'),
        meta: {'claudecode/toolUseId': 'toolu_abc'},
      );
      expect(other['isError'], isFalse);
      expect(executions.requests.last.parentToolCallId, 'toolu_abc');
    });
  });

  test('each script has an approval budget of its own', () async {
    final approver = Approver(answer: false);
    final asker = ProbeTool('ask_thing', requiresApproval: true);
    dispatcher = McpToolDispatcher(
      registry: McpToolRegistry([reader, asker, repl]),
      confirmationPort: approver,
    );
    repl.bind(dispatcher);
    executions.script = (callNested, request) async {
      final first = await callNested(nestedRequest('ask_thing'));
      final second = await callNested(nestedRequest('ask_thing', sequence: 2));
      return '${first.status.wire} ${second.errorMessage}';
    };

    final one = await call(runScope());
    // The person declined the first card; the second call was not asked.
    expect(text(one), contains('already declined'));
    expect(approver.requests, hasLength(1));

    await call(runScope());
    // The next script asks again.
    expect(approver.requests, hasLength(2));
  });

  test('stops the script when the caller stops waiting', () async {
    executions.script = (callNested, request) async {
      await executions.lastCancel!.whenCancelled;
      return 'stopped';
    };
    final abandoned = Future<void>.delayed(const Duration(milliseconds: 10));
    final response = await dispatcher.handleScopedRequest(
      JsonRpcRequest(
        method: 'tools/call',
        params: {
          'name': 'repl',
          'arguments': {'code': 'while (true) {}', 'description': 'Spin'},
        },
        id: 1,
      ),
      scope: runScope(),
      abandoned: abandoned,
    );
    expect(response['result']['content'][0]['text'], 'stopped');
    expect(executions.lastCancel!.isCancelled, isTrue);
  });
}

/// A past port the tool only hands on.
class _Past implements ScriptPastPort {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
