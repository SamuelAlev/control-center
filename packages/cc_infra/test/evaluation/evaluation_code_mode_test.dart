import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/value_objects/script_call_origin.dart';
import 'package:cc_domain/features/code_mode/domain/entities/code_execution.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_execution_port.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_result_formatter.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_backend_port.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_manifest.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_plan.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_task.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:cc_infra/src/evaluation/backends/builtin_evaluation_backend.dart';
import 'package:cc_infra/src/evaluation/evaluation_code_runner.dart';
import 'package:test/test.dart';

class _Factory extends HarnessProviderFactory {
  _Factory(this.provider);

  final LlmProviderPort provider;

  @override
  LlmProviderPort create({
    required String providerId,
    String? model,
    ProviderCredential? credential,
    ProviderTokenResolver? tokenResolver,
  }) => provider;
}

/// Plays [turns] in order and records the tool names each request offered.
class _Provider extends LlmProviderPort {
  _Provider(this.turns);

  final List<List<LlmEvent>> turns;
  final offered = <List<String>>[];

  @override
  String get displayName => 'scripted';
  @override
  String get defaultModel => 'scripted';
  @override
  Future<List<ProviderModel>> listModels() async => const [];

  @override
  Stream<LlmEvent> complete({
    required List<HarnessMessage> messages,
    List<LlmToolSchema> tools = const [],
    LlmCompleteConfig config = const LlmCompleteConfig(),
  }) async* {
    offered.add([for (final t in tools) t.name]);
    for (final event in turns[offered.length - 1]) {
      yield event;
    }
  }
}

/// A script that reads two files at once.
class _Executions implements CodeExecutionPort {
  _Executions({this.availability = const CodeRunnerAvailability.available()});

  final requests = <CodeExecutionRequest>[];

  @override
  final CodeRunnerAvailability availability;

  @override
  Future<CodeExecutionResult> execute(
    CodeExecutionRequest request, {
    required ScriptNestedCall callNested,
    CancellationToken cancel = CancellationToken.none,
  }) async {
    requests.add(request);
    final id = CodeExecution.idFor(
      runId: request.runId,
      toolCallId: request.parentToolCallId,
    );
    NestedCallRequest read(int n) => NestedCallRequest(
      sequence: n,
      toolCallId: '${request.parentToolCallId}/$n',
      name: 'read',
      arguments: {'path': 'missing-$n.txt'},
      origin: ScriptCallOrigin(
        parentToolCallId: request.parentToolCallId,
        executionId: id,
      ),
      deadline: const Duration(seconds: 30),
      site: null,
      cancel: cancel,
    );
    await Future.wait([callNested(read(1)), callNested(read(2))]);
    return CodeExecutionResult(
      result: const ScriptResult(
        text: 'Script completed in 0.0 s · 2 tool calls',
        isError: false,
        truncated: false,
        outputChars: 0,
      ),
      execution: CodeExecution(
        id: id,
        runId: request.runId,
        toolCallId: request.parentToolCallId,
        surface: request.surface,
        startedAt: DateTime.utc(2026),
        durationMs: 1,
        status: CodeExecutionStatus.completed,
        sourceHash: '0' * 64,
        sourceBytes: request.code.length,
        limits: request.limits,
      ),
      calls: const [],
    );
  }
}

const _done = [LlmTextDelta('ok'), LlmDone(stopReason: LlmStopReason.endTurn)];

const _effective = EvaluationEffectiveConfig(
  adapter: 'builtin',
  providerId: 'anthropic',
  modelId: 'scripted',
);

void main() {
  late Directory workspace;
  setUp(() => workspace = Directory.systemTemp.createTempSync('eval_code_'));
  tearDown(() => workspace.deleteSync(recursive: true));

  EvaluationAttemptRequest request() => EvaluationAttemptRequest(
    task: const EvaluationTask(
      id: 'code',
      kind: EvaluationTaskKind.exploration,
      prompt: 'read two files',
      verifiers: [],
    ),
    arm: const EvaluationArm(id: 'baseline', axis: EvaluationAxis.baseline),
    effective: _effective,
    manifest: const EvaluationManifest(
      corpusId: 'code',
      corpusHash: 'scripted',
      adapter: 'builtin',
      providerId: 'anthropic',
      modelId: 'scripted',
    ),
    workspaceRoot: workspace.path,
    stratum: CacheStratum.cold,
    repetition: 0,
    seed: 7,
    ordinal: 0,
    attemptId: 'code-0',
  );

  test(
    'a script\'s parallel calls are tool events but no parallel wave; '
    'an attempt gets repl whenever the runner passed its self-test',
    () async {
      final executions = _Executions();
      final provider = _Provider([
        [
          LlmToolUseDelta(
            id: 'call_repl',
            name: 'repl',
            argumentsJson: jsonEncode({
              'code': 'await Promise.all([...]);',
              'description': 'read two',
            }),
          ),
          const LlmDone(stopReason: LlmStopReason.toolUse),
        ],
        _done,
      ]);
      final attempt = await BuiltinEvaluationBackend(
        factory: _Factory(provider),
        codeExecutions: executions,
      ).execute(request());

      expect(attempt.completed, isTrue, reason: attempt.error);
      expect(provider.offered.first.first, 'repl');
      expect(attempt.toolEvents.map((e) => e.name), ['read', 'read', 'repl']);
      expect(attempt.metrics.parallelWaves, 0);
      final script = executions.requests.single;
      expect(
        (script.workspaceId, script.runId, script.storeEnabled),
        ('cc-eval', 'code-0', true),
      );
    },
  );

  test(
    'two calls the model issues at once are still a parallel wave',
    () async {
      final provider = _Provider([
        const [
          LlmToolUseDelta(
            id: 'r1',
            name: 'read',
            argumentsJson: '{"path":"a.txt"}',
          ),
          LlmToolUseDelta(
            id: 'r2',
            name: 'read',
            argumentsJson: '{"path":"b.txt"}',
          ),
          LlmDone(stopReason: LlmStopReason.toolUse),
        ],
        _done,
      ]);
      final attempt = await BuiltinEvaluationBackend(
        factory: _Factory(provider),
      ).execute(request());
      expect(attempt.toolEvents, hasLength(2));
      expect(attempt.metrics.parallelWaves, 1);
      expect(provider.offered.first, isNot(contains('repl')));
    },
  );

  test(
    'a runner that failed its self-test gives the attempt no repl',
    () async {
      final executions = _Executions(
        availability: const CodeRunnerAvailability.unavailable(
          'seccomp refused',
        ),
      );
      final provider = _Provider([_done]);
      final attempt = await BuiltinEvaluationBackend(
        factory: _Factory(provider),
        codeExecutions: executions,
      ).execute(request());
      expect(attempt.completed, isTrue, reason: attempt.error);
      expect(provider.offered.single, isNot(contains('repl')));
      expect(executions.requests, isEmpty);
    },
  );

  test(
    'the campaign runner is unavailable without CC_CODEMODE_RUNNER',
    () async {
      final unset = await EvaluationCodeRunner.open(environment: const {});
      expect(unset.executions, isNull);
      expect(unset.availability.isAvailable, isFalse);
      final relative = await EvaluationCodeRunner.open(
        environment: const {'CC_CODEMODE_RUNNER': 'build/cc_codemode'},
      );
      expect(relative.executions, isNull);
    },
  );
}
