import 'package:cc_data/cc_data.dart' show RpcCodeModeRepository;
import 'package:cc_domain/cc_domain.dart' show CodeModeStatusDto;
import 'package:cc_domain/features/code_mode/domain/entities/code_execution.dart';
import 'package:cc_domain/features/code_mode/domain/entities/code_execution_call.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_execution_repository.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';

/// The status [CodeModeStatusDto] the server reports for these facts.
CodeModeStatusDto codeModeStatus({
  bool available = true,
  String? reason,
  CodeModeLimits? limits,
  int? maxHeapBytes,
}) {
  final applied = limits ?? CodeModeLimits.defaults;
  return CodeModeStatusDto(
    available: available,
    reason: reason,
    limits: applied,
    limitOverrides: applied.overridesToJson(),
    maxProcesses: 4,
    maxParkedProcesses: 16,
    maxWorkspaceProcesses: 3,
    maxHeapBytes: maxHeapBytes ?? CodeModeLimits.heap.ceiling,
    runnerVersion: available ? '0.4.1' : null,
  );
}

const _hash =
    'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';

/// One execution record with plausible values.
CodeExecution codeExecution({
  String id = 'run-1/call-1',
  String runId = 'run-1',
  String toolCallId = 'call-1',
  CodeExecutionStatus status = CodeExecutionStatus.completed,
  String description = 'Collect open review threads',
  DateTime? startedAt,
  int durationMs = 1840,
  String? agentId = 'agent-1',
  String? conversationId = 'conv-1',
  String? spaceId = 'space-1',
  String? errorKind,
  NestedCallCounts? callCounts,
}) => CodeExecution(
  id: id,
  runId: runId,
  toolCallId: toolCallId,
  surface: CodeExecutionSurface.harness,
  startedAt: startedAt ?? DateTime.utc(2026, 11, 17, 9, 30),
  durationMs: durationMs,
  status: status,
  sourceHash: _hash,
  sourceBytes: 120,
  limits: CodeModeLimits.defaults,
  agentId: agentId,
  conversationId: conversationId,
  spaceId: spaceId,
  description: description,
  errorKind: errorKind,
  cpuMs: 210,
  peakHeapBytes: 12 * 1024 * 1024,
  callCounts: callCounts ?? NestedCallCounts(completed: 3, denied: 1),
  engineVersion: '0.4.1',
);

/// The [n]th call (1-based) of [executionId].
CodeExecutionCall codeExecutionCall(
  String executionId,
  int n, {
  NestedCallStatus status = NestedCallStatus.completed,
  NestedCallGateDecision? gate = NestedCallGateDecision.allowed,
  int approvalWaitMs = 0,
  String? error,
}) => CodeExecutionCall(
  executionId: executionId,
  sequence: n,
  toolCallId: '$executionId#$n',
  toolName: 'github_list_pull_requests',
  startOffsetMs: n * 10,
  durationMs: 120 + n,
  status: status,
  gateDecision: gate,
  approvalWaitMs: approvalWaitMs,
  argumentBytes: 24,
  resultBytes: 2048,
  argumentsJson: '{"repo":"shop-ui","state":"open"}',
  error: error,
);

/// A code mode repository answering from memory and recording every call.
class FakeCodeModeRepository implements RpcCodeModeRepository {
  /// Creates a fake reporting [status].
  FakeCodeModeRepository({CodeModeStatusDto? status})
    : status_ = status ?? codeModeStatus();

  /// What [status] answers.
  CodeModeStatusDto status_;

  /// Thrown by the next write, then cleared.
  Object? writeError;

  /// Every limits object written, in order.
  final limitWrites = <Map<String, int>?>[];

  /// Every list query, in order.
  final queries = <CodeExecutionQuery>[];

  /// Answers a list query; by default an empty page.
  Future<CodeExecutionPage> Function(CodeExecutionQuery query) onList =
      (_) async => const CodeExecutionPage(items: []);

  /// The records [getExecution] knows.
  final details = <String, CodeExecutionDetail>{};

  /// Thrown by [getExecution] when set.
  Object? detailError;

  /// Every id [getExecution] was asked for, in order.
  final detailReads = <String>[];

  @override
  Future<CodeModeStatusDto> status(String workspaceId) async => status_;

  @override
  Future<void> setWorkspaceLimits(
    String workspaceId,
    Map<String, int>? overrides,
  ) async {
    if (writeError case final e?) {
      writeError = null;
      throw e;
    }
    limitWrites.add(overrides);
    status_ = codeModeStatus(
      available: status_.available,
      reason: status_.reason,
      limits: CodeModeLimits.defaults.withOverridesJson(overrides ?? const {}),
      maxHeapBytes: status_.maxHeapBytes,
    );
  }

  @override
  Future<CodeExecutionPage> listExecutions(
    String workspaceId,
    CodeExecutionQuery query,
  ) {
    queries.add(query);
    return onList(query);
  }

  @override
  Future<CodeExecutionDetail?> getExecution(
    String workspaceId,
    String executionId,
  ) async {
    detailReads.add(executionId);
    if (detailError case final e?) {
      throw e;
    }
    return details[executionId];
  }
}
