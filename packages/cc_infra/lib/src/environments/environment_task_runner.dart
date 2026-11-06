import 'dart:async';

import 'package:cc_domain/features/environments/domain/entities/environment_run.dart';
import 'package:cc_domain/features/environments/domain/repositories/environment_repositories.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_component.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_status.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_template.dart';
import 'package:cc_infra/src/environments/environment_command_runner.dart';
import 'package:cc_infra/src/environments/environment_contract.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:uuid/uuid.dart';

/// How a task went.
class EnvironmentTaskOutcome {
  /// Creates an [EnvironmentTaskOutcome].
  const EnvironmentTaskOutcome({required this.run, this.error});

  /// The finished record.
  final EnvironmentRun run;

  /// The structured failure, null on success.
  final EnvironmentError? error;

  /// Whether it exited 0.
  bool get succeeded => run.status == EnvironmentRunStatus.succeeded;
}

/// Runs one-shot tasks and records them in [EnvironmentRunRepository].
///
/// The record exists before anything runs and is always finished, whatever
/// happens, so a run can't stay `running` until the next boot sweeps it up.
class EnvironmentTaskRunner {
  /// Creates an [EnvironmentTaskRunner].
  EnvironmentTaskRunner({
    required this._runs,
    EnvironmentCommandRunner? runner,
    this._uuid = const Uuid(),
    this._now = DateTime.now,
    this.flushInterval = const Duration(milliseconds: 500),
    this.maxOutputChars = 64 * 1024,
  }) : _runner = runner ?? EnvironmentCommandRunner();

  final EnvironmentRunRepository _runs;
  final EnvironmentCommandRunner _runner;
  final Uuid _uuid;
  final DateTime Function() _now;

  /// Minimum gap between tail writes.
  final Duration flushInterval;

  /// Retained characters of output per run.
  final int maxOutputChars;

  /// Runs [task] in an environment, with the full contract.
  Future<EnvironmentTaskOutcome> runInEnvironment({
    required TaskEnvironmentComponent task,
    required EnvironmentContract contract,
    required String workspaceId,
    required String definitionId,
    required String environmentId,
    List<String> arguments = const [],
    EnvironmentRunKind kind = EnvironmentRunKind.task,
    void Function(EnvironmentCommandEvent event)? onEvent,
  }) => _record(
    task: task,
    workspaceId: workspaceId,
    spaceId: contract.input.spaceId,
    environmentId: environmentId,
    definitionId: definitionId,
    kind: kind,
    onEvent: onEvent,
    arguments: arguments,
    prepare: () => (
      values: contract.values,
      environment: contract.forComponent(task),
      workingDirectory: contract.workingDirectory(task.cwd),
    ),
  );

  /// Runs a `provision` or `archive` [task] against a worktree, with no
  /// environment: only [variables], and the placeholders in [values].
  Future<EnvironmentTaskOutcome> runInWorktree({
    required TaskEnvironmentComponent task,
    required String workspaceId,
    required String workingDirectory,
    required Map<String, String> variables,
    EnvironmentValues values = EnvironmentValues.empty,
    String? spaceId,
    String? definitionId,
    String? repoId,
    EnvironmentRunKind kind = EnvironmentRunKind.task,
    void Function(EnvironmentCommandEvent event)? onEvent,
  }) => _record(
    task: task,
    workspaceId: workspaceId,
    spaceId: spaceId,
    definitionId: definitionId,
    repoId: repoId,
    kind: kind,
    onEvent: onEvent,
    prepare: () => (
      values: values,
      environment: {
        ...variables,
        for (final entry in task.env.entries)
          entry.key: values.expand(entry.value),
      },
      workingDirectory: workingDirectory,
    ),
  );

  Future<EnvironmentTaskOutcome> _record({
    required TaskEnvironmentComponent task,
    required String workspaceId,
    required EnvironmentRunKind kind,
    required ({
      EnvironmentValues values,
      Map<String, String> environment,
      String workingDirectory,
    })
    Function()
    prepare,
    String? spaceId,
    String? environmentId,
    String? definitionId,
    String? repoId,
    List<String> arguments = const [],
    void Function(EnvironmentCommandEvent event)? onEvent,
  }) async {
    final id = _uuid.v4();
    final startedAt = _now();
    await _runs.start(
      EnvironmentRun(
        id: id,
        workspaceId: workspaceId,
        spaceId: spaceId,
        environmentId: environmentId,
        definitionId: definitionId,
        repoId: repoId,
        kind: kind,
        label: task.id,
        status: EnvironmentRunStatus.running,
        startedAt: startedAt,
      ),
    );

    final tail = EnvironmentOutputTail(maxChars: maxOutputChars);
    Timer? pendingFlush;
    void scheduleFlush() {
      pendingFlush ??= Timer(flushInterval, () {
        pendingFlush = null;
        _runs
            .updateOutput(workspaceId, id, tail.toString())
            .catchError(
              (Object e) => CcInfraLog.warning(
                'environment run output write failed for $id: $e',
              ),
            );
      });
    }

    void onCommandEvent(EnvironmentCommandEvent event) {
      switch (event) {
        case EnvironmentCommandOutput(:final line, :final isStderr):
          tail.addLine(isStderr ? '[stderr] $line' : line);
        case EnvironmentCommandProgress(:final progress):
          tail.addLine('[${progress.type}] ${progress.label ?? ''}');
      }
      scheduleFlush();
      onEvent?.call(event);
    }

    EnvironmentRunStatus status;
    EnvironmentError? error;
    int? exitCode;
    try {
      final prepared = prepare();
      final result = await _runner.run(
        task.command,
        values: prepared.values,
        arguments: arguments,
        workingDirectory: prepared.workingDirectory,
        environment: prepared.environment,
        timeout: Duration(seconds: task.timeoutSeconds),
        onEvent: onCommandEvent,
      );
      exitCode = result.exitCode;
      error = result.error;
      status = result.timedOut
          ? EnvironmentRunStatus.timedOut
          : result.succeeded
          ? EnvironmentRunStatus.succeeded
          : EnvironmentRunStatus.failed;
    } on EnvironmentTemplateException catch (e) {
      status = EnvironmentRunStatus.failed;
      error = EnvironmentError(code: 'template', message: e.message);
    } on Object catch (e, st) {
      CcInfraLog.error('environment task ${task.id} failed to run', e, st);
      status = EnvironmentRunStatus.failed;
      error = EnvironmentError(code: 'task-failed', message: '$e');
    } finally {
      pendingFlush?.cancel();
    }

    final completedAt = _now();
    await _runs.finish(
      workspaceId,
      id,
      status: status,
      completedAt: completedAt,
      exitCode: exitCode,
      error: error?.message,
      output: tail.toString(),
    );
    return EnvironmentTaskOutcome(
      run: EnvironmentRun(
        id: id,
        workspaceId: workspaceId,
        spaceId: spaceId,
        environmentId: environmentId,
        definitionId: definitionId,
        repoId: repoId,
        kind: kind,
        label: task.id,
        status: status,
        startedAt: startedAt,
        completedAt: completedAt,
        exitCode: exitCode,
        error: error?.message,
        output: tail.toString(),
      ),
      error: error,
    );
  }
}
