import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/auth/domain/repositories/credentials_repository.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_result.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_body_registry.dart';
import 'package:cc_domain/features/pipelines/domain/services/step_process_registry.dart';
import 'package:cc_domain/features/pipelines/domain/services/template_renderer.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';

/// Registers the agentless `pipeline.bashScript` body.
///
/// Use it for steps that don't need an LLM — cloning a branch, running a
/// build, kicking off `gh` commands, etc. The body:
///
///  - Renders the `config.script` template, substituting `{{key}}` against
///    pipeline state + trigger payload.
///  - Resolves the cwd to `<cc_root>/pipelines/<pipelineRunId>/` so all
///    bash steps in a run share a workspace.
///  - Exposes `GITHUB_TOKEN` (from the credentials repo) so `gh` and
///    `git clone https://x-access-token:$GITHUB_TOKEN@…` work out of the
///    box.
///  - Spawns the script with `Process.start` and streams stdout/stderr
///    into the step-run row in real time so the run-detail card shows
///    output as it happens. Output is throttled to keep DB write load
///    sane on chatty scripts.
///  - On exit 0, writes the trimmed stdout to `config.outputKey` for
///    downstream nodes. On non-zero, fails the step with stderr.
void registerBashScriptBody(
  PipelineBodyRegistry registry, {
  required PipelineTemplateRepository templateRepository,
  required PipelineRunRepository runRepository,
  required CredentialsRepository credentialsRepository,
  required StepProcessRegistry stepProcessRegistry,
  required Future<String> Function(String pipelineRunId) runDirPath,
}) {
  registry.registerBody(BuiltInBodyKeys.bashScript, (ctx) async {
    final def = await templateRepository.getById(
      ctx.workspaceId,
      ctx.templateId,
    );
    final stepConfig = def?.step(ctx.stepId)?.config;
    if (stepConfig == null) {
      return StepResult.failed(
        'bashScript: step "${ctx.stepId}" missing config',
      );
    }
    final script = stepConfig.script;
    if (script == null || script.trim().isEmpty) {
      return StepResult.failed(
        'bashScript: step "${ctx.stepId}" missing script',
      );
    }

    final rendered = _render(script, ctx.renderState, ctx.triggerPayload);

    // Dry run: don't execute side-effecting shell; echo what would run.
    if (ctx.dryRun) {
      final outputKey = stepConfig.outputKey;
      return StepResult.ok(mutatedState: {
        if (outputKey != null && outputKey.isNotEmpty)
          outputKey: '[dry-run] bash script skipped',
      });
    }

    final runDir = Directory(await runDirPath(ctx.pipelineRunId));
    final creds = await credentialsRepository.loadCredentials();
    final env = <String, String>{
      ...Platform.environment,
      if (creds.githubToken.isNotEmpty) 'GITHUB_TOKEN': creds.githubToken,
    };

    CcInfraLog.info('Running step "${ctx.stepId}" in ${runDir.path}',);

    final streamer = _OutputStreamer(
      stepRunId: ctx.stepRunId,
      stepId: ctx.stepId,
      script: rendered,
      runDir: runDir.path,
      repository: runRepository,
    );

    final process = await Process.start(
      'bash',
      ['-c', rendered],
      workingDirectory: runDir.path,
      environment: env,
      runInShell: false,
    );

    // Expose a kill hook so the UI's Stop button can interrupt the process.
    stepProcessRegistry.register(ctx.stepRunId, () {
      try {
        process.kill(ProcessSignal.sigterm);
        Timer(const Duration(seconds: 2), () {
          try {
            process.kill(ProcessSignal.sigkill);
          } on Object catch (_) {}
        });
      } on Object catch (e, st) {
        CcInfraLog.error('kill failed', e, st);
      }
    });

    // Pipe both streams through the streamer. Lines are tagged so the
    // run-detail card can show interleaved stdout/stderr in order.
    final stdoutSub = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(streamer.appendStdout);
    final stderrSub = process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(streamer.appendStderr);

    final exitCode = await process.exitCode;
    await stdoutSub.cancel();
    await stderrSub.cancel();
    stepProcessRegistry.unregister(ctx.stepRunId);
    await streamer.flush(exitCode: exitCode);

    if (exitCode != 0) {
      final tail = streamer.stderrTrimmed.isNotEmpty
          ? streamer.stderrTrimmed
          : streamer.stdoutTrimmed;
      return StepResult.failed('bash exited $exitCode: $tail');
    }

    final outputKey = stepConfig.outputKey;
    final mutated = <String, dynamic>{
      '${ctx.stepId}_runDir': runDir.path,
      if (outputKey != null && outputKey.isNotEmpty)
        outputKey: streamer.stdoutTrimmed,
    };

    return StepResult.ok(mutatedState: mutated);
  });
}

/// Accumulates stdout/stderr from a bash subprocess and pushes throttled
/// snapshots into `pipeline_step_runs.outputJson` so the run-detail card
/// can render the output live.
class _OutputStreamer {
  _OutputStreamer({
    required this.stepRunId,
    required this.stepId,
    required this.script,
    required this.runDir,
    required this.repository,
  });

  /// Minimum gap between successive DB writes. Without throttling a chatty
  /// `set -x` script would issue dozens of writes per second.
  static const Duration _minFlushInterval = Duration(milliseconds: 200);

  final String stepRunId;
  final String stepId;
  final String script;
  final String runDir;
  final PipelineRunRepository repository;

  /// Combined interleaved log — what the user actually wants to read.
  final StringBuffer _combined = StringBuffer();

  /// Tail-only buffers so failure messages can quote a useful slice.
  final StringBuffer _stdout = StringBuffer();
  final StringBuffer _stderr = StringBuffer();

  Timer? _pendingFlush;
  bool _flushInFlight = false;
  bool _dirty = false;
  DateTime _lastFlushAt = DateTime.fromMillisecondsSinceEpoch(0);

  String get stdoutTrimmed => _stdout.toString().trimRight();
  String get stderrTrimmed => _stderr.toString().trimRight();

  void appendStdout(String line) {
    _stdout
      ..write(line)
      ..writeln();
    _combined
      ..write(line)
      ..writeln();
    _scheduleFlush();
  }

  void appendStderr(String line) {
    _stderr
      ..write(line)
      ..writeln();
    // Tag stderr in the interleaved view so the user can tell them apart.
    _combined
      ..write('[stderr] ')
      ..write(line)
      ..writeln();
    _scheduleFlush();
  }

  void _scheduleFlush() {
    _dirty = true;
    if (_pendingFlush != null) {
      return;
    }
    final elapsed = DateTime.now().difference(_lastFlushAt);
    final wait = elapsed >= _minFlushInterval
        ? Duration.zero
        : _minFlushInterval - elapsed;
    _pendingFlush = Timer(wait, () {
      _pendingFlush = null;
      _writeSnapshot();
    });
  }

  Future<void> _writeSnapshot({int? exitCode, bool finished = false}) async {
    if (_flushInFlight) {
      return;
    }
    if (!_dirty && !finished) {
      return;
    }
    _flushInFlight = true;
    _dirty = false;
    _lastFlushAt = DateTime.now();
    try {
      await repository.updateStepRun(
        stepRunId,
        outputJson: jsonEncode({
          'stepId': stepId,
          'runDir': runDir,
          'exitCode': ?exitCode,
          'output': _combined.toString(),
        }),
      );
    } on Object catch (e, st) {
      CcInfraLog.error('Failed to persist stream snapshot for $stepRunId',
        e,
        st,);
    } finally {
      _flushInFlight = false;
    }
  }

  /// Final write. Cancels any pending throttle, waits for any in-flight
  /// write, and persists the final snapshot.
  Future<void> flush({int? exitCode}) async {
    _pendingFlush?.cancel();
    _pendingFlush = null;
    // If a write is still mid-flight, give it a moment to settle so our
    // final write isn't dropped by the `_flushInFlight` guard.
    while (_flushInFlight) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    await _writeSnapshot(exitCode: exitCode, finished: true);
  }
}

/// Escapes a value for safe interpolation into a bash DOUBLE-QUOTED context:
/// backslash-escapes the four characters special inside `"..."` (`"`, `\`, `$`,
/// backtick). A value escaped this way cannot close the surrounding quotes,
/// expand variables, or run command substitutions — so an untrusted trigger
/// value (e.g. an external ticket title) spliced into `"{{key}}"` in a bash
/// script body cannot inject commands (VULN-007).
String _shellEscape(String v) => v
    .replaceAll('\\', r'\\')
    .replaceAll(r'"', r'\"')
    .replaceAll(r'$', r'\$')
    .replaceAll(r'`', r'\`');

/// Substitutes `{{key}}` placeholders, shell-escaping each value so an
/// untrusted trigger payload cannot inject commands. State takes precedence
/// over the trigger payload. Missing keys render as empty strings.
const TemplateRenderer _renderer = TemplateRenderer();

String _render(
  String template,
  Map<String, dynamic> state,
  Map<String, dynamic>? triggerPayload,
) {
  return _renderer
      .render(
        template,
        state: state,
        trigger: triggerPayload,
        escape: _shellEscape,
      )
      .text;
}
