import 'dart:convert';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/ports/schema_validator_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/output_contract_mode.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';

/// How many schema-violating `submit_output` calls are tolerated before the
/// run is failed (prevents an agent burning unbounded tokens re-trying).
const int _maxContractRejections = 3;

/// MCP tool that submits a pipeline-dispatched run's structured output.
///
/// Resolves the calling agent's **active run** server-side (the same active-run
/// resolution the conversation-mode guard uses), validates `output` against the
/// run's `expectedOutputSchema`, applies the strict/permissive enforcement
/// (ported from the old ticket `complete_ticket` path), stores `outputJson` on
/// the run, and lets the run end — the pipeline step resume listener then
/// harvests the payload and advances the step.
class SubmitOutputTool extends McpTool {
  /// Creates a [SubmitOutputTool].
  SubmitOutputTool({
    required AgentRunLogRepository runLogRepository,
    SchemaValidatorPort? schemaValidator,
  })  : _runLogs = runLogRepository,
        _schemaValidator = schemaValidator;

  final AgentRunLogRepository _runLogs;
  final SchemaValidatorPort? _schemaValidator;

  @override
  String get name => 'submit_output';

  @override
  String get description =>
      'Submit the structured output payload for your current pipeline run. '
      'Resolves your active run from agent_id. If the run declares an expected '
      'output schema, the payload MUST validate against it: a non-conforming '
      'payload is rejected with the exact list of violations — read them, fix '
      'the payload, and call submit_output again. After 3 rejections the run '
      'is failed.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'workspace_id': {'type': 'string', 'description': 'Workspace ID.'},
          'agent_id': {
            'type': 'string',
            'description': 'Your own agent id (resolves the active run).',
          },
          'output': {
            'type': 'object',
            'description': 'Output payload as a JSON object. Required (and '
                'schema-validated) when the run declares an expected output '
                'schema.',
          },
        },
        'required': ['workspace_id', 'agent_id'],
      };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'] as String?;
    final agentId = arguments['agent_id'] as String?;
    if (workspaceId == null || workspaceId.isEmpty) {
      return CallResult.error('Missing workspace_id.');
    }
    if (agentId == null || agentId.isEmpty) {
      return CallResult.error('Missing agent_id.');
    }

    final run = await _runLogs.activeRunForAgent(agentId);
    if (run == null) {
      return CallResult.error(
        'No active run found for agent $agentId. submit_output only applies '
        'to a pipeline-dispatched run that is still in progress.',
      );
    }
    // Workspace isolation: the resolved run must belong to this workspace.
    if (run.workspaceId != workspaceId) {
      return CallResult.error('The active run belongs to a different workspace.');
    }
    // Only pipeline-dispatched runs carry a submit contract.
    if (run.pipelineRunId == null || run.pipelineStepRunId == null) {
      return CallResult.error(
        'Your active run is not pipeline-tracked; there is no output contract '
        'to submit against.',
      );
    }

    final output = arguments['output'] as Map<String, dynamic>?;
    try {
      final outcome = await _enforceAndStore(run, output);
      if (!outcome.accepted) {
        return CallResult.error(outcome.message);
      }
      return CallResult.success(jsonEncode({
        'run_id': run.id,
        'status': 'submitted',
        if (outcome.message.isNotEmpty) 'note': outcome.message,
      }));
    } on OutputContractViolationException catch (e) {
      return CallResult.error(e.message);
    }
  }

  /// Validates [output] against the run's contract and persists it. Returns
  /// whether the payload was accepted, or a rejection message the agent reads
  /// to self-correct. Throws [OutputContractViolationException] when the
  /// rejection cap is hit (the run is then marked failed via its summary).
  Future<_Outcome> _enforceAndStore(
    AgentRunLog run,
    Map<String, dynamic>? output,
  ) async {
    final validator = _schemaValidator;
    final schema = run.expectedOutputSchema;
    final mode = run.outputContractMode;

    // No schema → accept anything (including null) as the output.
    if (schema == null) {
      await _runLogs.upsert(run.copyWith(outputJson: output));
      return _Outcome.ok();
    }

    final violations = output == null
        ? <String>['output is required: this run declares an expected output schema']
        : (validator?.validate(output, schema) ?? const <String>[]);

    if (violations.isEmpty) {
      await _runLogs.upsert(run.copyWith(outputJson: output));
      return _Outcome.ok();
    }

    final rejections = run.outputRejections + 1;
    final detail = violations.map((v) => '- $v').join('\n');

    // Persist the incremented rejection count.
    await _runLogs.upsert(run.copyWith(outputRejections: rejections));

    if (mode == OutputContractMode.permissive) {
      // Permissive: persist the output even with violations.
      await _runLogs.upsert(run.copyWith(outputJson: output));
      return _Outcome(
        accepted: true,
        message: 'Output accepted with $rejections schema warning(s):\n$detail',
      );
    }

    // Strict: reject. Fail the run once the cap is hit.
    if (rejections >= _maxContractRejections) {
      await _runLogs.upsert(
        run.copyWith(
          outputJson: null,
          summary: 'Output failed the expected schema $rejections times:\n$detail',
        ),
      );
      throw OutputContractViolationException(
        'Output does not match the expected output schema, and the rejection '
        'limit was reached. The run has been failed.\n$detail',
        violations: violations,
        terminal: true,
      );
    }

    return _Outcome(
      accepted: false,
      message: 'Output does not match the expected output schema:\n$detail\n'
          'Fix the payload and call submit_output again.',
    );
  }
}

class _Outcome {
  const _Outcome({this.accepted = false, this.message = ''});

  factory _Outcome.ok() => const _Outcome(accepted: true);

  final bool accepted;
  final String message;
}
