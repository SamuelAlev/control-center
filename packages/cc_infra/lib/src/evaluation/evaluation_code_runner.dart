import 'dart:io';

import 'package:cc_domain/features/code_mode/domain/entities/code_execution.dart';
import 'package:cc_domain/features/code_mode/domain/entities/code_execution_call.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_execution_port.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_execution_repository.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_mode_store_repository.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_store_write.dart';
import 'package:cc_infra/src/code_mode/bundled_code_runner.dart';
import 'package:cc_infra/src/code_mode/code_execution_service.dart';
import 'package:cc_infra/src/code_mode/code_sandbox_process.dart';
import 'package:path/path.dart' as p;

/// The code runner an evaluation's code mode arms use: the built runner,
/// named by `CC_CODEMODE_RUNNER`, behind the same execution service a
/// server runs, with nothing persisted.
///
/// An evaluation has no workspace database, so executions are not kept (the
/// attempt's transcript and tool events are its record) and `store()`
/// values live for the campaign only.
class EvaluationCodeRunner {
  EvaluationCodeRunner._(this.executions, this.availability, this._dispose);

  /// No runner: every arm whose code mode is not off is refused, with
  /// [reason].
  EvaluationCodeRunner.unavailable(String reason)
    : executions = null,
      availability = CodeRunnerAvailability.unavailable(reason),
      _dispose = null;

  /// Finds the runner named by `CC_CODEMODE_RUNNER` in [environment] (the
  /// process environment by default) and runs its self-test. Never throws:
  /// a missing, relative or failing runner yields no [executions].
  static Future<EvaluationCodeRunner> open({
    Map<String, String>? environment,
  }) async {
    final env = environment ?? Platform.environment;
    final path = env[BundledCodeRunner.environmentOverride];
    if (path == null || path.isEmpty) {
      return EvaluationCodeRunner.unavailable(
        '${BundledCodeRunner.environmentOverride} is not set',
      );
    }
    if (!p.isAbsolute(path) || !File(path).existsSync()) {
      return EvaluationCodeRunner.unavailable(
        '${BundledCodeRunner.environmentOverride} names no runner: $path',
      );
    }
    final process = CodeSandboxProcess(executable: path);
    final availability = await process.selfTest();
    if (!availability.isAvailable) {
      await process.dispose();
      return EvaluationCodeRunner._(null, availability, null);
    }
    final service = CodeExecutionService(
      sandbox: process,
      executions: _NoExecutionRecords(),
      store: _CampaignStore(),
    );
    return EvaluationCodeRunner._(service, availability, service.dispose);
  }

  /// The execution service, or null when the runner is unavailable.
  final CodeExecutionPort? executions;

  /// The runner's self-test result.
  final CodeRunnerAvailability availability;

  final Future<void> Function()? _dispose;

  /// Ends every running script and the runner processes.
  Future<void> dispose() async => _dispose?.call();
}

/// Keeps no execution: an evaluation campaign's runs are throwaway runs in
/// a scratch workspace, scored by the campaign itself, so their scripts
/// leave no audit record. Every write is accepted and dropped, and a lookup
/// finds nothing.
class _NoExecutionRecords implements CodeExecutionRepository {
  @override
  Future<void> begin(
    String workspaceId,
    CodeExecution execution, {
    required String source,
  }) async {}

  @override
  Future<CodeExecutionAppendOutcome> appendCall(
    String workspaceId,
    CodeExecutionCall call,
  ) async => CodeExecutionAppendOutcome.appended;

  @override
  Future<bool> close(
    String workspaceId,
    String executionId, {
    required CodeExecutionStatus status,
    required String errorKind,
    required int durationMs,
  }) async => true;

  @override
  Future<CodeExecutionFinishResult> finish(
    String workspaceId,
    CodeExecution execution, {
    required CodeExecutionPayload payload,
    required List<CodeExecutionCall> calls,
  }) async => CodeExecutionFinishResult.finished;

  @override
  Future<int> highestIdSuffix(
    String workspaceId, {
    required String runId,
    required String toolCallId,
  }) async => 0;

  @override
  Future<CodeExecutionPage> list(
    String workspaceId,
    CodeExecutionQuery query,
  ) async => const CodeExecutionPage(items: []);

  @override
  Future<CodeExecutionDetail?> get(
    String workspaceId,
    String executionId,
  ) async => null;
}

/// `store()` values for the campaign's lifetime, under the same rules the
/// workspace database applies.
class _CampaignStore implements CodeModeStoreRepository {
  final Map<String, Map<String, String>> _values = {};

  String _key(String workspaceId, String conversationId, String agentId) =>
      '$workspaceId\u0000$conversationId\u0000$agentId';

  @override
  Future<Map<String, String>> readAll(
    String workspaceId, {
    required String conversationId,
    required String agentId,
  }) async =>
      Map.of(_values[_key(workspaceId, conversationId, agentId)] ?? const {});

  @override
  Future<void> commit(
    String workspaceId, {
    required String conversationId,
    required String agentId,
    required List<CodeModeStoreWrite> writes,
  }) async {
    final key = _key(workspaceId, conversationId, agentId);
    _values[key] = CodeModeStoreRules.apply(_values[key] ?? const {}, writes);
  }
}
