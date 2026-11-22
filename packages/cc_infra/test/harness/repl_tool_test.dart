import 'dart:convert';

import 'package:cc_domain/core/domain/value_objects/script_call_origin.dart';
import 'package:cc_domain/features/code_mode/domain/entities/code_execution.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_execution_port.dart';
import 'package:cc_domain/features/code_mode/domain/services/json_weight.dart';
import 'package:cc_domain/features/code_mode/domain/services/repl_tool_description.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_result_formatter.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_outcome.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_tool_descriptor.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_harness/context.dart' show ToolOutputReference;
import 'package:cc_harness/tools.dart';
import 'package:cc_infra/src/harness/mcp_tool_bridge.dart';
import 'package:cc_infra/src/harness/repl_tool.dart';
import 'package:test/test.dart';

class _Tool extends HarnessTool {
  _Tool(
    this.name, {
    this.approvalTier = ToolApprovalTier.read,
    this.scriptCallable = true,
    this.outputSchema,
    this.resultNote,
  });

  @override
  final String name;
  @override
  final String? resultNote;
  @override
  final ToolApprovalTier approvalTier;
  @override
  final bool scriptCallable;
  @override
  final Map<String, dynamic>? outputSchema;

  @override
  String get description => 'The $name tool.';

  @override
  Map<String, dynamic> get inputSchema => const {
    'type': 'object',
    'properties': {
      'path': {'type': 'string'},
    },
  };

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async => HarnessToolResult.success('ok');
}

class _Mcp extends McpTool {
  _Mcp(this.name, {this.server, this.resultNote});

  @override
  final String name;
  final String? server;
  @override
  final String? resultNote;

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

class _Reentry implements ToolReentry {
  _Reentry(this.answer);

  final ToolReentryOutcome Function(String name, Object? args) answer;
  String? name;
  Object? args;
  CancellationToken? cancel;
  Duration? timeout;
  PersonWaitListener? onPersonWait;

  @override
  Map<String, HarnessTool> get callable => const {};

  @override
  Future<ToolReentryOutcome> call(
    String name,
    Object? args, {
    CancellationToken? cancel,
    Duration? timeout,
    PersonWaitListener? onPersonWait,
    void Function(ToolGateVerdict verdict)? onToolStarted,
    ({int line, int column})? site,
  }) async {
    this.name = name;
    this.args = args;
    this.cancel = cancel;
    this.timeout = timeout;
    this.onPersonWait = onPersonWait;
    onPersonWait?.call(true);
    onPersonWait?.call(false);
    onToolStarted?.call(ToolGateVerdict.approved);
    return answer(name, args);
  }
}

class _Port implements CodeExecutionPort {
  CodeExecutionRequest? request;
  ScriptNestedCall? callNested;
  CancellationToken? cancel;
  NestedCallOutcome? nested;

  @override
  CodeRunnerAvailability get availability =>
      const CodeRunnerAvailability.available();

  @override
  Future<CodeExecutionResult> execute(
    CodeExecutionRequest request, {
    required ScriptNestedCall callNested,
    CancellationToken cancel = CancellationToken.none,
  }) async {
    this.request = request;
    this.callNested = callNested;
    this.cancel = cancel;
    nested = await callNested(
      NestedCallRequest(
        sequence: 1,
        toolCallId: '${request.parentToolCallId}/1',
        name: 'read',
        arguments: const {'path': 'a'},
        origin: ScriptCallOrigin(
          parentToolCallId: request.parentToolCallId,
          executionId: 'exec',
        ),
        deadline: const Duration(seconds: 7),
        site: null,
      ),
    );
    return CodeExecutionResult(
      result: ScriptResult(
        text: 'Script failed after 0.1 s',
        isError: true,
        truncated: false,
        outputChars: 0,
        images: [
          for (var i = 0; i < 6; i++)
            ScriptImageOutput(mediaType: 'image/png', data: 'AAAA$i'),
        ],
      ),
      execution: CodeExecution(
        id: 'exec',
        runId: request.runId,
        toolCallId: request.parentToolCallId,
        surface: request.surface,
        startedAt: DateTime.utc(2026),
        durationMs: 1,
        status: CodeExecutionStatus.failed,
        errorKind: CodeExecutionErrorKind.scriptError,
        sourceHash: '0' * 64,
        sourceBytes: 1,
        limits: request.limits,
      ),
      calls: const [],
    );
  }
}

ToolReentryOutcome _outcome(
  HarnessToolResult result, {
  ToolReentryStatus status = ToolReentryStatus.completed,
  ToolGateRecord? gate = const ToolGateRecord(ToolGateVerdict.allowed),
}) => ToolReentryOutcome(
  toolName: 'read',
  toolCallId: 'p/1',
  parentToolUseId: 'p',
  result: result,
  status: status,
  duration: const Duration(milliseconds: 40),
  gate: gate,
  personWait: const Duration(milliseconds: 15),
);

/// What a script receives for [value]: the service encodes it as JSON.
Object? _received(Object? value) => jsonDecode(jsonEncode(value));

void main() {
  final run = ReplRunIdentity(
    readOnly: false,
    past: null,
    workspaceId: 'ws',
    runId: 'run-log-1',
    conversationId: 'conv',
    agentId: 'agent',
    spaceId: 'space',
    storeEnabled: false,
  );

  ReplTool tool(
    _Port port, {
    Future<ToolOutputReference?> Function(String)? sink,
  }) => ReplTool(
    executor: port,
    run: run,
    callableTools: [
      _Tool('read'),
      _Tool(
        'write',
        approvalTier: ToolApprovalTier.write,
        resultNote: 'Text: `Created <path>.`',
      ),
      _Tool('checkpoint', scriptCallable: false),
      _Tool('repl'),
    ],
    directToolNames: const {'write'},
    limits: CodeModeLimits(),
    fullOutputSink: sink,
  );

  group('ReplTool', () {
    test('is read tier, self-guarding, serial and never script-callable', () {
      final t = tool(_Port());
      expect(t.name, 'repl');
      expect(t.approvalTier, ToolApprovalTier.read);
      expect(t.selfGuards, isTrue);
      expect(t.actionClasses, isEmpty);
      expect(t.parallelSafe, isFalse);
      expect(t.scriptCallable, isFalse);
      expect(t.inputSchema, ReplToolDescription.inputSchema());
      expect(t.inputSchema['required'], contains('description'));
      expect([for (final d in t.scriptTools) d.name], ['read', 'write']);
      // The direct tool's own note, from the descriptor it carries; no
      // declarations.
      expect(t.description, contains('- write: Text: `Created <path>.`\n'));
      expect(
        t.scriptTools.firstWhere((d) => d.name == 'write').resultNote,
        'Text: `Created <path>.`',
      );
      expect(t.description, isNot(contains('declare const')));
      expect(t.description, contains('- builtin (2 tools): '));
      expect(t.description, same(t.description));
      expect(tool(_Port()).description, t.description);
    });

    test('refuses without a reentry: a script cannot start a script', () async {
      final port = _Port();
      final result = await tool(port).execute(const {
        'code': 'return 1',
        'description': 'x',
      }, const HarnessToolContext(workingDirectory: '/', toolCallId: 't1'));
      expect(result.isError, isTrue);
      expect(result.content, contains('a script cannot start a script'));
      expect(port.request, isNull);
    });

    test('refuses bad arguments before running anything', () async {
      final port = _Port();
      final result = await tool(port).execute(
        const {'code': 'return 1'},
        HarnessToolContext(
          workingDirectory: '/',
          toolCallId: 't1',
          reentry: _Reentry((_, _) => _outcome(HarnessToolResult.success(''))),
        ),
      );
      expect(result.isError, isTrue);
      expect(port.request, isNull);
    });

    test('runs through the port and returns text, error flag and at most '
        'four images', () async {
      final port = _Port();
      final reentry = _Reentry(
        (_, _) => _outcome(HarnessToolResult.success('{"a": 1}')),
      );
      Future<ToolOutputReference?> sink(String _) async => null;
      final cancel = CancellationTokenSource();
      final result = await tool(port, sink: sink).execute(
        const {
          'code': 'return 1',
          'description': 'count things',
          'timeout_ms': 5000,
          'max_output_tokens': 200,
        },
        HarnessToolContext(
          workingDirectory: '/',
          toolCallId: 'call_9',
          reentry: reentry,
          cancel: cancel.token,
        ),
      );
      final request = port.request!;
      expect(request.workspaceId, 'ws');
      expect(request.runId, 'run-log-1');
      expect(request.parentToolCallId, 'call_9');
      expect(request.surface, CodeExecutionSurface.harness);
      expect(request.description, 'count things');
      expect(request.timeoutMs, 5000);
      expect(request.maxOutputTokens, 200);
      expect(request.conversationId, 'conv');
      expect(request.spaceId, 'space');
      expect(request.storeEnabled, isFalse);
      expect(request.fullOutputSink, same(sink));
      expect(port.cancel, same(cancel.token));
      expect(reentry.name, 'read');
      expect(reentry.timeout, const Duration(seconds: 7));
      expect(_received(port.nested!.value), {'a': 1});
      expect(result.isError, isTrue);
      expect(result.content, 'Script failed after 0.1 s');
      expect(result.images, hasLength(4));
    });
  });

  group('nestedOutcomeOf', () {
    test('a structured result wins over the text', () {
      final o = nestedOutcomeOf(
        _outcome(HarnessToolResult.success('3 things', structured: {'n': 3})),
      );
      expect(o.status, NestedCallStatus.completed);
      expect(o.value, {'n': 3});
      expect(o.gateDecision, NestedCallGateDecision.allowed);
      expect(o.durationMs, 40);
      expect(o.approvalWaitMs, 15);
      expect(o.resultBytes, 7);
    });

    test('text that is one JSON object or array is parsed', () {
      expect(
        _received(
          nestedOutcomeOf(
            _outcome(HarnessToolResult.success(' [1, 2] ')),
          ).value,
        ),
        [1, 2],
      );
      expect(
        _received(
          nestedOutcomeOf(
            _outcome(HarnessToolResult.success('{"a": 1} trailing')),
          ).value,
        ),
        '{"a": 1} trailing',
      );
    });

    // The text is kept and decoded only while the service encodes it for
    // the script, so a result just under the limit arrives parsed and one at
    // the limit (the array counts too) arrives as its text.
    test('a JSON text is decoded only when encoded, up to the item limit', () {
      final under =
          '[${List.filled(CodeModeLimits.maxNestedResultItems - 2, '{}').join(',')}]';
      final at =
          '[${List.filled(CodeModeLimits.maxNestedResultItems, '{}').join(',')}]';
      final kept = nestedOutcomeOf(
        _outcome(HarnessToolResult.success(under)),
      ).value;
      expect(kept, isA<ScriptJsonText>());
      expect(
        _received(kept),
        hasLength(CodeModeLimits.maxNestedResultItems - 2),
      );
      expect(
        _received(
          nestedOutcomeOf(_outcome(HarnessToolResult.success(at))).value,
        ),
        at,
      );
    });

    test('plain text stays text', () {
      expect(
        nestedOutcomeOf(_outcome(HarnessToolResult.success('hello'))).value,
        'hello',
      );
    });

    test('an image result becomes an image block', () {
      final o = nestedOutcomeOf(
        _outcome(
          HarnessToolResult.success(
            'a screenshot',
            images: const [
              HarnessImageBlock(data: 'AAAA', mediaType: 'image/png'),
            ],
          ),
        ),
      );
      expect(o.value, {
        'type': 'image',
        'mediaType': 'image/png',
        'data': 'AAAA',
      });
    });

    test('a result over 4 MiB fails and states its size', () {
      final big = 'x' * (CodeModeLimits.maxNestedResultBytes + 10);
      final o = nestedOutcomeOf(_outcome(HarnessToolResult.success(big)));
      expect(o.status, NestedCallStatus.failed);
      final bytes = utf8.encode(jsonEncode(big)).length;
      expect(o.errorMessage, contains('$bytes bytes'));
      expect(o.resultBytes, bytes);
    });

    test('every reentry status maps, with the tool or gate message', () {
      final expected = {
        ToolReentryStatus.failed: NestedCallStatus.failed,
        ToolReentryStatus.denied: NestedCallStatus.denied,
        ToolReentryStatus.cancelled: NestedCallStatus.cancelled,
        ToolReentryStatus.timedOut: NestedCallStatus.timedOut,
        ToolReentryStatus.unknownTool: NestedCallStatus.unknownTool,
        ToolReentryStatus.invalidArgs: NestedCallStatus.invalidArgs,
      };
      for (final MapEntry(key: from, value: to) in expected.entries) {
        final o = nestedOutcomeOf(
          _outcome(
            HarnessToolResult.error('it went wrong: ${from.name}'),
            status: from,
            gate: null,
          ),
        );
        expect(o.status, to);
        expect(o.value, isNull);
        expect(o.errorMessage, 'it went wrong: ${from.name}');
        expect(o.gateDecision, isNull);
      }
      final denied = nestedOutcomeOf(
        _outcome(
          const HarnessToolResult(content: '', isError: true),
          status: ToolReentryStatus.denied,
          gate: const ToolGateRecord(
            ToolGateVerdict.denied,
            reason: 'blocked by policy',
          ),
        ),
      );
      expect(denied.errorMessage, 'blocked by policy');
      expect(denied.gateDecision, NestedCallGateDecision.denied);
      final approved = nestedOutcomeOf(
        _outcome(
          HarnessToolResult.success('ok'),
          gate: const ToolGateRecord(ToolGateVerdict.approved),
        ),
      );
      expect(approved.gateDecision, NestedCallGateDecision.approved);
    });

    test('callThroughReentry forwards the deadline, cancel and person '
        'waits', () async {
      final reentry = _Reentry(
        (_, _) => _outcome(HarnessToolResult.success('ok')),
      );
      final waits = <bool>[];
      final started = <NestedCallGateDecision>[];
      final cancel = CancellationTokenSource();
      final o = await callThroughReentry(
        reentry,
        NestedCallRequest(
          sequence: 2,
          toolCallId: 'p/2',
          name: 'ask_user',
          arguments: const {'question': 'q'},
          origin: ScriptCallOrigin(parentToolCallId: 'p', executionId: 'e'),
          deadline: const Duration(seconds: 3),
          site: null,
          cancel: cancel.token,
          onPersonWait: waits.add,
          onToolStarted: started.add,
        ),
      );
      expect(o.status, NestedCallStatus.completed);
      // The gate's verdict reaches the record when the tool starts.
      expect(started, [NestedCallGateDecision.approved]);
      expect(reentry.name, 'ask_user');
      expect(reentry.args, {'question': 'q'});
      expect(reentry.timeout, const Duration(seconds: 3));
      expect(reentry.cancel, same(cancel.token));
      expect(waits, [true, false]);
    });
  });

  group('scriptToolDescriptorFor', () {
    test('maps tier, effects, schemas and namespaces', () {
      final write = scriptToolDescriptorFor(
        _Tool(
          'write',
          approvalTier: ToolApprovalTier.write,
          outputSchema: const {'type': 'object'},
        ),
      );
      expect(write.namespace, ScriptToolNamespace.builtin);
      expect(write.tier, ToolApprovalTier.write);
      expect(write.effects, {ActionClass.fileWriteOutsideWorktree});
      expect(write.outputSchema, {'type': 'object'});
      expect(write.inputSchema['properties'], contains('path'));

      expect(
        scriptToolDescriptorFor(McpToolBridge(_Mcp('create_ticket'))).namespace,
        ScriptToolNamespace.controlCenter,
      );
      // The bridged tool's own result note reaches the descriptor.
      expect(
        scriptToolDescriptorFor(
          McpToolBridge(_Mcp('todo_write', resultNote: 'Text: a list.')),
        ).resultNote,
        'Text: a list.',
      );
      expect(
        scriptToolDescriptorFor(
          McpToolBridge(_Mcp('mcp__github__list_issues', server: 'github')),
        ).namespace,
        'github',
      );
      expect(
        scriptToolDescriptorFor(
          McpToolBridge(_Mcp('mcp__linear__search')),
        ).namespace,
        'linear',
      );
      expect(
        scriptToolDescriptorFor(_Tool('mcp__shop-ui__render')).namespace,
        'shop-ui',
      );
    });
  });
}
