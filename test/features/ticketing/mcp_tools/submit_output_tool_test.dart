import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/ports/schema_validator_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_output_port.dart';
import 'package:cc_domain/core/domain/value_objects/output_contract_mode.dart';
import 'package:cc_mcp/src/tools/submit_output_tool.dart';
import 'package:flutter_test/flutter_test.dart';

/// Serves the active run and records the one run-log write the tool may make
/// (the failure summary). Any other call, `upsert` included, throws: the tool
/// must never write back the run it read.
class _FakeRunLogRepo implements AgentRunLogRepository {
  AgentRunLog? activeRun;
  String? summary;

  @override
  Future<AgentRunLog?> activeRunForAgent(
    String workspaceId,
    String agentId,
  ) async => activeRun;

  @override
  Future<bool> updateRuntime(
    String workspaceId,
    String runId, {
    int? pid,
    bool markRunning = false,
    String? logPath,
    String? contextSnapshotJson,
    DateTime? lastOutputAt,
    RunLiveness? liveness,
    RunErrorFamily? errorFamily,
    String? summary,
    String? modelId,
    String? effort,
    String? taskFamily,
  }) async {
    this.summary = summary;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

/// Records the output and rejection writes.
class _FakeOutputs implements AgentRunOutputPort {
  _FakeOutputs(this.rejections);

  Map<String, dynamic>? output;
  int rejections;

  @override
  Future<void> recordOutput(
    String workspaceId,
    String runId,
    Map<String, dynamic> output,
  ) async => this.output = output;

  @override
  Future<int?> addOutputRejection(String workspaceId, String runId) async =>
      ++rejections;
}

/// A validator that rejects any output missing a `result` field when the schema
/// requires it, otherwise accepts.
class _FakeValidator implements SchemaValidatorPort {
  @override
  List<String> validate(Object? value, Map<String, dynamic> schema) {
    final valueMap = value;
    if (valueMap is Map && valueMap.containsKey('result')) {
      return const [];
    }
    return const ['missing required field: result'];
  }

  @override
  List<String> validateSchema(Map<String, dynamic> schema) => const [];
}

AgentRunLog _run({
  Map<String, dynamic>? schema,
  OutputContractMode mode = OutputContractMode.strict,
  Map<String, dynamic>? outputJson,
  int rejections = 0,
}) => AgentRunLog(
  id: 'run-1',
  agentId: 'agent-1',
  workspaceId: 'ws-1',
  conversationId: 'chan-1',
  pipelineRunId: 'pr-1',
  pipelineStepId: 'step-1',
  expectedOutputSchema: schema,
  outputContractMode: mode,
  outputJson: outputJson,
  outputRejections: rejections,
  startedAt: DateTime(2026, 1, 1),
  status: RunStatus.running,
);

void main() {
  late _FakeRunLogRepo repo;
  late _FakeOutputs outputs;
  late SubmitOutputTool tool;

  /// Serves [run] as the active run, with the stored rejection count it has.
  void serve(AgentRunLog run) {
    repo.activeRun = run;
    outputs.rejections = run.outputRejections;
  }

  setUp(() {
    repo = _FakeRunLogRepo();
    outputs = _FakeOutputs(0);
    tool = SubmitOutputTool(
      runLogRepository: repo,
      runOutputs: outputs,
      schemaValidator: _FakeValidator(),
    );
  });

  test('missing workspace_id → error', () async {
    final res = await tool.run({'agent_id': 'agent-1'});
    expect(res.isError, isTrue);
  });

  test('no active run → error', () async {
    repo.activeRun = null;
    final res = await tool.run({'workspace_id': 'ws-1', 'agent_id': 'agent-1'});
    expect(res.isError, isTrue);
  });

  test('run from a different workspace → rejected', () async {
    serve(_run());
    final res = await tool.run({
      'workspace_id': 'other-ws',
      'agent_id': 'agent-1',
    });
    expect(res.isError, isTrue);
  });

  test('non-pipeline run → rejected', () async {
    repo.activeRun = AgentRunLog(
      id: 'run-1',
      agentId: 'agent-1',
      workspaceId: 'ws-1',
      conversationId: 'chan-1',
      startedAt: DateTime(2026, 1, 1),
      status: RunStatus.running,
    );
    final res = await tool.run({'workspace_id': 'ws-1', 'agent_id': 'agent-1'});
    expect(res.isError, isTrue);
  });

  test('no schema → accepts any output (including null)', () async {
    serve(_run(schema: null));
    final res = await tool.run({
      'workspace_id': 'ws-1',
      'agent_id': 'agent-1',
      'output': {'freeform': true},
    });
    expect(res.isError, isFalse);
    expect(outputs.output, {'freeform': true});
  });

  test('strict schema — valid payload → stored, succeeds', () async {
    serve(_run(schema: {'type': 'object'}));
    final res = await tool.run({
      'workspace_id': 'ws-1',
      'agent_id': 'agent-1',
      'output': {'result': 'done'},
    });
    expect(res.isError, isFalse);
    expect(outputs.output, {'result': 'done'});
    expect(outputs.rejections, 0);
  });

  test(
    'strict schema — invalid payload → rejected, rejection count bumped',
    () async {
      serve(_run(schema: {'type': 'object'}));
      final res = await tool.run({
        'workspace_id': 'ws-1',
        'agent_id': 'agent-1',
        'output': {'wrong': true},
      });
      expect(res.isError, isTrue);
      // The run's rejection count is persisted.
      expect(outputs.rejections, 1);
      // Output was NOT stored (strict rejection).
      expect(outputs.output, isNull);
    },
  );

  test('strict schema — 3rd rejection fails the run (terminal)', () async {
    serve(_run(schema: {'type': 'object'}, rejections: 2));
    final res = await tool.run({
      'workspace_id': 'ws-1',
      'agent_id': 'agent-1',
      'output': {'wrong': true},
    });
    expect(res.isError, isTrue);
    // The summary records the terminal failure.
    expect(repo.summary, contains('failed the expected schema 3 times'));
  });

  test('permissive schema — invalid payload accepted with a warning', () async {
    serve(
      _run(schema: {'type': 'object'}, mode: OutputContractMode.permissive),
    );
    final res = await tool.run({
      'workspace_id': 'ws-1',
      'agent_id': 'agent-1',
      'output': {'wrong': true},
    });
    // Permissive accepts (non-error) but the note carries the warnings.
    expect(res.isError, isFalse);
    expect(outputs.output, {'wrong': true});
  });
}
