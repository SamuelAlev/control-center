import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/ports/credential_broker_port.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_result.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_body_registry.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_context.dart';
import 'package:cc_domain/features/pipelines/domain/services/step_process_registry.dart';
import 'package:cc_domain/features/pipelines/domain/services/template_renderer.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:cc_domain/features/sandboxing/domain/sandbox_config.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/process/child_process.dart';
import 'package:cc_infra/src/sandboxing/process_sandbox.dart';
import 'package:cc_infra/src/sandboxing/sandbox_config_builder.dart';
import 'package:cc_infra/src/sandboxing/sandbox_manager.dart';
import 'package:cc_natives/cc_natives.dart' show IsolatedGit;

/// Wraps an argv in the host's OS sandbox (`SandboxManager.wrap`).
typedef BashScriptSandboxWrap =
    Future<SandboxWrapResult> Function({
      required SandboxConfig config,
      required List<String> argv,
      String? workingDirectory,
    });

/// A GitHub repository linked to the running pipeline's workspace.
typedef LinkedGitHubRepo = ({String owner, String name});

/// The confinement a pipeline shell step runs under.
///
/// A shell step is operator-authored code executing on the server host, so it
/// gets what an agent gets and no more: the OS sandbox (with the server's
/// data directory and `.env` file unreadable), the child-environment
/// allowlist, a git and `gh` with no host configuration, and — only when the
/// pipeline targets a linked repository — a broker-minted one-repository
/// `read` token.
class BashScriptSandbox {
  /// Creates a [BashScriptSandbox].
  const BashScriptSandbox({
    required this.wrap,
    required this.broker,
    required this.linkedRepo,
  });

  /// The host's OS sandbox, or null when it has none (Windows, a Linux host
  /// without `bwrap`, `--sandbox off`). Null fails every shell step closed.
  ///
  /// The server's sandbox manager hides its data directory and `.env` from
  /// every config it wraps; the step's run directory, which lives under the
  /// data directory, stays reachable because the config names it.
  final BashScriptSandboxWrap? wrap;

  /// Mints the one-repository `read` token.
  final CredentialBrokerPort broker;

  /// The repo named `owner/name` when it is a GitHub repository linked to
  /// the workspace; null otherwise, and then no token is minted.
  final Future<LinkedGitHubRepo?> Function(
    String workspaceId,
    String repoFullName,
  )
  linkedRepo;
}

/// How long a shell step may run when its node sets no `timeoutMs`. A script
/// that hangs (waiting on stdin, a network call with no timeout) would
/// otherwise hold its run — and a step-concurrency slot — forever.
const Duration kBashScriptDefaultTimeout = Duration(minutes: 30);

/// How long to wait, after the process exits, for its stdout/stderr to reach
/// end-of-stream. The last lines a script prints are usually the ones that
/// explain it; a backgrounded grandchild that inherited the pipes can keep
/// them open indefinitely, so the wait is bounded.
const Duration _drainTimeout = Duration(seconds: 5);

/// Registers agentless `pipeline.bashScript`: render `config.script` against
/// state; run it under [sandbox] with cwd `<data>/pipelines/<pipelineRunId>/`;
/// stream stdout/stderr (throttled) into the step-run; exit 0 →
/// `config.outputKey`, else fail with stderr.
///
/// The script is the one in the graph the run is pinned to
/// (`PipelineContext.step`), not the live template: editing a pipeline never
/// changes what a run already in flight executes. [templateRepository] is only
/// the fallback for a body invoked outside an engine. The script is killed
/// after the node's `timeoutMs`, or [kBashScriptDefaultTimeout] when it sets
/// none.
void registerBashScriptBody(
  PipelineBodyRegistry registry, {
  required PipelineTemplateRepository templateRepository,
  required PipelineRunRepository runRepository,
  required StepProcessRegistry stepProcessRegistry,
  required Future<String> Function(String pipelineRunId) runDirPath,
  required BashScriptSandbox sandbox,
  // Fail-closed on a public demo: the body is still registered (an unknown
  // key would look like a wiring bug) but it never renders or spawns.
  bool execute = true,
}) {
  registry.registerBody(BuiltInBodyKeys.bashScript, (ctx) async {
    if (!execute) {
      return StepResult.failed(
        'bashScript: execution is disabled on this host',
      );
    }
    final stepConfig = await ctx.pinnedStepConfig(templateRepository);
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
      return StepResult.ok(
        mutatedState: {
          if (outputKey != null && outputKey.isNotEmpty)
            outputKey: '[dry-run] bash script skipped',
        },
      );
    }

    final wrap = sandbox.wrap;
    if (wrap == null) {
      return StepResult.failed(
        'bashScript: this host has no OS sandbox (sandbox-exec on macOS, '
        'bubblewrap on Linux), and shell steps never run unsandboxed. '
        'Install the sandbox or remove the shell step.',
      );
    }

    final runDir = Directory(await runDirPath(ctx.pipelineRunId));
    CcInfraLog.info('Running step "${ctx.stepId}" in ${runDir.path}');

    final ghConfig = Directory.systemTemp.createTempSync('cc-pipeline-gh-');
    ScopedCredentials? token;
    try {
      token = await _mintRepoToken(ctx, sandbox);
      final env = <String, String>{
        // No host git or gh configuration: no credential helper, no global
        // hooks or signing program, no stored `gh` login.
        ...IsolatedGit.isolationEnvironment,
        'GH_CONFIG_DIR': ghConfig.path,
        ...?token?.environment,
      };
      final config = await bashScriptSandboxConfig(
        sessionId: 'pipeline-${ctx.pipelineRunId}::${ctx.stepId}',
        workspaceId: ctx.workspaceId,
        runDir: runDir.path,
      );
      final wrapped = await wrap(
        config: config,
        argv: ['bash', '-c', rendered],
        workingDirectory: runDir.path,
      );

      final streamer = _OutputStreamer(
        workspaceId: ctx.workspaceId,
        stepRunId: ctx.stepRunId,
        stepId: ctx.stepId,
        script: rendered,
        runDir: runDir.path,
        repository: runRepository,
      );

      final process = await ChildProcess.start(
        wrapped.executable,
        wrapped.argv,
        workingDirectory: runDir.path,
        environment: {...wrapped.environment, ...env},
        toolchain: true,
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
      final drained = Future.wait([
        stdoutSub.asFuture<void>(),
        stderrSub.asFuture<void>(),
      ]);

      final limit = stepConfig.timeoutMs != null
          ? Duration(milliseconds: stepConfig.timeoutMs!)
          : kBashScriptDefaultTimeout;
      var timedOut = false;
      final exitCode = await process.exitCode.timeout(
        limit,
        onTimeout: () async {
          timedOut = true;
          process.kill(ProcessSignal.sigterm);
          return process.exitCode.timeout(
            const Duration(seconds: 2),
            onTimeout: () {
              process.kill(ProcessSignal.sigkill);
              return process.exitCode;
            },
          );
        },
      );
      // Read to end-of-stream before reporting: cancelling the moment the
      // process exits dropped whatever it printed last.
      try {
        await drained.timeout(_drainTimeout);
      } on TimeoutException {
        CcInfraLog.warning(
          'bashScript: step "${ctx.stepId}" output still open '
          '${_drainTimeout.inSeconds}s after exit; dropping the rest',
        );
      } on Object catch (e) {
        CcInfraLog.warning('bashScript: output stream failed: $e');
      }
      await stdoutSub.cancel();
      await stderrSub.cancel();
      stepProcessRegistry.unregister(ctx.stepRunId);
      await streamer.flush(exitCode: exitCode);

      if (timedOut) {
        return StepResult.failed(
          'bash timed out after ${_describe(limit)} and was stopped',
        );
      }
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
    } finally {
      final handle = token?.handle;
      if (handle != null) {
        unawaited(
          sandbox.broker.revoke(handle).catchError((Object e) {
            CcInfraLog.warning('bashScript: token revoke failed: $e');
          }),
        );
      }
      try {
        ghConfig.deleteSync(recursive: true);
      } on FileSystemException {
        // An empty temp directory left behind is harmless.
      }
    }
  });
}

String _describe(Duration d) => d.inMinutes >= 1 && d.inSeconds % 60 == 0
    ? '${d.inMinutes}m'
    : '${d.inSeconds}s';

/// The pipeline's target repository (`repo_full_name` in state or the trigger
/// payload), minted a `read` token only when it is linked to the workspace.
Future<ScopedCredentials?> _mintRepoToken(
  PipelineContext ctx,
  BashScriptSandbox sandbox,
) async {
  final target =
      ctx.optional<String>('repo_full_name') ??
      ctx.optional<String>('repoFullName');
  if (target == null || target.trim().isEmpty) {
    return null;
  }
  final repo = await sandbox.linkedRepo(ctx.workspaceId, target.trim());
  if (repo == null) {
    return null;
  }
  return sandbox.broker.mint(
    conversationId: 'pipeline:${ctx.pipelineRunId}:${ctx.stepId}',
    scope: ForgeTokenScope.read,
    repoOwner: repo.owner,
    repoName: repo.name,
    workspaceId: ctx.workspaceId,
  );
}

/// The sandbox a pipeline shell step runs in: the agent sandbox's policy
/// (secret paths in `$HOME` denied, the restricted egress allowlist, exec
/// denies) with [runDir] as its working directory and run directory. The
/// server's private paths are hidden by the sandbox manager that wraps it.
/// Visible for tests.
Future<SandboxConfig> bashScriptSandboxConfig({
  required String sessionId,
  required String workspaceId,
  required String runDir,
}) async {
  // Seatbelt matches the resolved path (`/var/folders` is
  // `/private/var/folders`), so the run directory is named by it.
  String real;
  try {
    real = Directory(runDir).resolveSymbolicLinksSync();
  } on FileSystemException {
    real = runDir;
  }
  // A shell step runs in its own run directory, not a repo checkout, so
  // there is no original to protect; network posture and mode are the
  // agent sandbox's chat defaults.
  final spec = processSandboxSpec(
    sessionId: sessionId,
    workspaceId: workspaceId,
    workdir: real,
    networkEnabled: true,
    mode: Mode.chat,
    protectedPaths: const [],
    execGrantRoots: const [],
    loopbackPorts: const [],
    environmentScope: null,
  );
  return buildSandboxConfigFromPolicy(processSandboxPolicy(spec, runDir: real));
}

/// Accumulates stdout/stderr from a bash subprocess and pushes throttled
/// snapshots into `pipeline_step_runs.outputJson` so the run-detail card
/// can render the output live.
class _OutputStreamer {
  _OutputStreamer({
    required this.workspaceId,
    required this.stepRunId,
    required this.stepId,
    required this.script,
    required this.runDir,
    required this.repository,
  });

  /// Minimum gap between successive DB writes. Without throttling a chatty
  /// `set -x` script would issue dozens of writes per second.
  static const Duration _minFlushInterval = Duration(milliseconds: 200);

  /// Workspace owning the step run — it selects the database the throttled
  /// output snapshots are written into.
  final String workspaceId;
  final String stepRunId;
  final String stepId;
  final String script;
  final String runDir;
  final PipelineRunRepository repository;

  /// Combined interleaved log — what the user actually wants to read. Bounded
  /// (tail-keeping): a chatty long-running script (`set -x`, verbose builds)
  /// would otherwise grow this without limit for the step's whole lifetime
  /// AND re-encode the ever-growing snapshot into `outputJson` on every
  /// flush.
  final _BoundedLineBuffer _combined = _BoundedLineBuffer(maxChars: 256 * 1024);

  /// Tail-only buffers so failure messages can quote a useful slice.
  final _BoundedLineBuffer _stdout = _BoundedLineBuffer(maxChars: 64 * 1024);
  final _BoundedLineBuffer _stderr = _BoundedLineBuffer(maxChars: 64 * 1024);

  Timer? _pendingFlush;
  bool _flushInFlight = false;
  bool _dirty = false;
  DateTime _lastFlushAt = DateTime.fromMillisecondsSinceEpoch(0);

  String get stdoutTrimmed => _stdout.toString().trimRight();
  String get stderrTrimmed => _stderr.toString().trimRight();

  void appendStdout(String line) {
    _stdout.addLine(line);
    _combined.addLine(line);
    _scheduleFlush();
  }

  void appendStderr(String line) {
    _stderr.addLine(line);
    // Tag stderr in the interleaved view so the user can tell them apart.
    _combined.addLine('[stderr] $line');
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
        workspaceId,
        stepRunId,
        outputJson: jsonEncode({
          'stepId': stepId,
          'runDir': runDir,
          'exitCode': ?exitCode,
          'output': _combined.toString(),
        }),
      );
    } on Object catch (e, st) {
      CcInfraLog.error(
        'Failed to persist stream snapshot for $stepRunId',
        e,
        st,
      );
    } finally {
      _flushInFlight = false;
    }
  }

  /// Final write. Cancels any pending throttle, waits for any in-flight
  /// write and persists the final snapshot.
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

/// A line buffer that keeps only the most recent lines up to [maxChars]
/// characters, prefixing the rendered text with a truncation notice once
/// older lines have been dropped. Keeps a chatty subprocess from growing an
/// in-memory log (and its per-flush JSON snapshot) without bound.
class _BoundedLineBuffer {
  _BoundedLineBuffer({required this.maxChars});

  /// Maximum retained characters (excluding the truncation notice).
  final int maxChars;

  final List<String> _lines = [];
  int _chars = 0;
  bool _truncated = false;

  /// Appends [line], evicting oldest lines while over budget.
  void addLine(String line) {
    _lines.add(line);
    _chars += line.length + 1;
    var start = 0;
    while (_chars > maxChars && start < _lines.length - 1) {
      _chars -= _lines[start].length + 1;
      start++;
      _truncated = true;
    }
    if (start > 0) {
      _lines.removeRange(0, start);
    }
  }

  @override
  String toString() {
    final body = _lines.join('\n');
    return _truncated ? '[…output truncated…]\n$body' : body;
  }
}

/// The bash quoting a placeholder sits in.
enum _ShellQuote { none, single, double }

/// The quoting at each offset of [script] that starts a placeholder, read
/// from the literal text before it: `'…'`, `"…"`, backslash escapes, and
/// `$(…)` / backticks, which start a fresh unquoted context even inside
/// double quotes.
Map<int, _ShellQuote> _quotingAt(String script, Iterable<int> offsets) {
  final wanted = offsets.toSet();
  final out = <int, _ShellQuote>{};
  // One frame per nesting level: its quoting, and the character that closes
  // it (`)` for `$(`, a backtick for a backtick, none for the script).
  final stack = <(_ShellQuote, String)>[(_ShellQuote.none, '')];
  bool wordStart(int i) =>
      i == 0 || RegExp(r'[\s;&|()]').hasMatch(script[i - 1]);
  for (var i = 0; i < script.length; i++) {
    final (quote, closer) = stack.last;
    if (wanted.contains(i)) {
      out[i] = quote;
    }
    final c = script[i];
    final next = i + 1 < script.length ? script[i + 1] : '';
    switch (quote) {
      case _ShellQuote.single:
        if (c == "'") {
          stack.removeLast();
        }
      case _ShellQuote.double:
        if (c == r'\') {
          i++;
        } else if (c == '"') {
          stack.removeLast();
        } else if (c == r'$' && next == '(') {
          stack.add((_ShellQuote.none, ')'));
          i++;
        } else if (c == '`') {
          stack.add((_ShellQuote.none, '`'));
        }
      case _ShellQuote.none:
        if (c == r'\') {
          i++;
        } else if (c == '#' && wordStart(i)) {
          // A comment: nothing in it quotes anything.
          while (i + 1 < script.length && script[i + 1] != '\n') {
            i++;
            if (wanted.contains(i)) {
              out[i] = quote;
            }
          }
        } else if (closer.isNotEmpty && c == closer) {
          stack.removeLast();
        } else if (c == "'") {
          stack.add((_ShellQuote.single, ''));
        } else if (c == '"') {
          stack.add((_ShellQuote.double, ''));
        } else if (c == r'$' && next == '(') {
          stack.add((_ShellQuote.none, ')'));
          i++;
        } else if (c == '`') {
          stack.add((_ShellQuote.none, '`'));
        }
    }
  }
  return out;
}

/// Escapes [v] for the bash quoting it is spliced into, so it is always one
/// literal word that cannot close its quotes, expand variables, run command
/// substitutions or separate commands (VULN-007):
/// - inside `"…"`: backslash-escape `"`, `\`, `$` and backtick;
/// - inside `'…'`: close, emit an escaped quote, reopen (`'\''`);
/// - unquoted: a single-quoted atom.
String _shellEscape(String v, _ShellQuote quote) => switch (quote) {
  _ShellQuote.double =>
    v
        .replaceAll('\\', r'\\')
        .replaceAll(r'"', r'\"')
        .replaceAll(r'$', r'\$')
        .replaceAll(r'`', r'\`'),
  _ShellQuote.single => v.replaceAll("'", r"'\''"),
  _ShellQuote.none => "'${v.replaceAll("'", r"'\''")}'",
};

/// Substitutes `{{key}}` placeholders, shell-escaping each value for the
/// quoting it sits in so an untrusted trigger payload cannot inject
/// commands wherever the author put the placeholder. State takes precedence
/// over the trigger payload. Missing keys render as empty strings.
const TemplateRenderer _renderer = TemplateRenderer();

String _render(
  String template,
  Map<String, dynamic> state,
  Map<String, dynamic>? triggerPayload,
) {
  final quoting = _quotingAt(template, _renderer.placeholderOffsets(template));
  return _renderer
      .render(
        template,
        state: state,
        trigger: triggerPayload,
        escape: (value, offset) =>
            _shellEscape(value, quoting[offset] ?? _ShellQuote.none),
      )
      .text;
}
