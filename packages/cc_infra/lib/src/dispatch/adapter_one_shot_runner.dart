/// @docImport 'package:cc_infra/src/dispatch/dispatch_session.dart';
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/settings/domain/entities/adapter.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:cc_infra/src/dispatch/acp/acp_client.dart';
import 'package:cc_infra/src/dispatch/one_shot_confinement.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/process/binary_resolver.dart';

import 'package:cc_infra/src/process/child_process.dart';

/// One spawned adapter process, abstracted away from `dart:io` so the runner
/// is unit-testable without any CLI installed on the host.
abstract interface class OneShotProcess {
  /// The process's stdout, already decoded and split into lines.
  Stream<String> get stdoutLines;

  /// Writes [data] to the process's stdin (no trailing newline is added).
  void writeStdin(String data);

  /// Closes stdin, signalling end-of-input to a CLI that reads a piped prompt.
  Future<void> closeStdin();

  /// The process's exit code.
  Future<int> get exitCode;

  /// Terminates the process. Safe to call after it has already exited.
  void kill();
}

/// Spawns one adapter CLI. Injected so tests never touch a real binary.
typedef OneShotLauncher =
    Future<OneShotProcess> Function(
      String executable,
      List<String> arguments, {
      String? workingDirectory,
      Map<String, String>? environment,
    });

/// Runs one tool-less prompt on any adapter and returns its text.
///
/// Not a [DispatchSession]: no worktree, run log, sandbox, MCP, or cost
/// accounting — those would put provisioning on the chat send path for a
/// tiny naming completion. Spawns the adapter (or calls the harness), pipes
/// the prompt, reads the answer; no MCP, no tools, throwaway cwd.
/// - [AdapterTransport.harness]: in-process [LlmProviderPort]; only transport
///   with `maxTokens` and credential resolution we control.
/// - [AdapterTransport.claudeCli]: `claude -p --output-format text` with no
///   tools, no MCP servers and the caller's system prompt replacing Claude Code's own.
/// - [AdapterTransport.acp]: full ACP handshake via [AcpClient], collect
///   [TextEvent]s.
///
/// Only the ACP transport is confined ([OneShotConfinement]): an ACP CLI
/// brings its own tools and its own config decides whether it asks before
/// using them, so refusing its permission requests is no boundary. The
/// harness transport runs in process with no tools at all, and `claude -p`
/// runs with `--tools ''`, `--strict-mcp-config` and slash commands off in a
/// throwaway cwd, so neither can act on the host whatever the prompt says.
///
/// Returns null on cannot-run (unknown id / missing CLI / no credential / an
/// ACP one-shot this host may not run for the requester) — quiet skip.
/// Failures mid-run throw.
class AdapterOneShotRunner {
  /// Creates an [AdapterOneShotRunner].
  AdapterOneShotRunner({
    required ProviderCredentialStore credentials,
    required this._confinement,
    this._factory = const HarnessProviderFactory(),
    this._refresher,
    Future<String?> Function(String cliName)? resolveBinary,
    OneShotLauncher? launcher,
    Iterable<Adapter>? adapters,
  }) : _creds = credentials,
       _resolveBinary = resolveBinary ?? resolveBinaryPath,
       _launch = launcher ?? _spawnIoProcess,
       _adapters = adapters ?? predefinedAdapters;

  final ProviderCredentialStore _creds;
  final OneShotConfinement _confinement;
  final HarnessProviderFactory _factory;
  final ProviderCredentialRefresher? _refresher;
  final Future<String?> Function(String cliName) _resolveBinary;
  final OneShotLauncher _launch;
  final Iterable<Adapter> _adapters;

  /// Runs [prompt] under [systemPrompt] on [adapterId] with [modelId] and
  /// returns the reply text, or null when the adapter cannot run.
  ///
  /// [requestedByUserId] is the person whose message or action asked for it
  /// in [workspaceId]; null is nobody, which is never the server owner.
  ///
  /// [timeout] is a hard wall-clock ceiling on the whole attempt including
  /// process spawn; the process is killed when it expires. [maxTokens] bounds
  /// the reply on the harness transport only — an external CLI owns its own
  /// output budget and there is no flag we can portably set.
  Future<String?> complete({
    required String? workspaceId,
    required String? requestedByUserId,
    required String adapterId,
    String? modelId,
    required String systemPrompt,
    required String prompt,
    required Duration timeout,
    int maxTokens = 128,
  }) async {
    final adapter = _adapters.where((a) => a.id == adapterId).firstOrNull;
    if (adapter == null) {
      CcInfraLog.debug('one-shot: unknown adapter "$adapterId"; skipped');
      return null;
    }

    return switch (adapter.transport) {
      AdapterTransport.harness => _runHarness(
        modelId: modelId,
        systemPrompt: systemPrompt,
        prompt: prompt,
        timeout: timeout,
        maxTokens: maxTokens,
      ),
      AdapterTransport.claudeCli => _runPipedCli(
        adapter: adapter,
        // A plain completion, not an agent session. Without `--tools ''`
        // Claude Code keeps its built-in tools and its agentic system
        // prompt, so a titling prompt over "rebase my branch" was answered
        // as a task ("I couldn't start the rebase because there's no
        // repository here") and that answer became the title.
        // `--system-prompt` replaces Claude Code's own prompt instead of
        // folding ours into the user turn.
        args: [
          '-p',
          '--output-format',
          'text',
          '--tools',
          '',
          '--strict-mcp-config',
          '--disable-slash-commands',
          '--no-session-persistence',
          '--system-prompt',
          systemPrompt,
          if (modelId != null && modelId.isNotEmpty) ...['--model', modelId],
        ],
        input: prompt,
        timeout: timeout,
      ),
      AdapterTransport.acp => _runAcp(
        workspaceId: workspaceId,
        requestedByUserId: requestedByUserId,
        adapter: adapter,
        modelId: modelId,
        systemPrompt: systemPrompt,
        prompt: prompt,
        timeout: timeout,
      ),
    };
  }

  Future<String?> _runHarness({
    required String? modelId,
    required String systemPrompt,
    required String prompt,
    required Duration timeout,
    required int maxTokens,
  }) async {
    final parsed = _factory.parseModel(modelId);
    // Server-owned credential resolution (UI-saved key/OAuth + refresh). No
    // credential for the provider → nothing to call; skip quietly rather than
    // guessing another provider.
    final cred = await _creds.activeCredential(parsed.providerId);
    if (cred == null) {
      CcInfraLog.debug(
        'one-shot: no credential for ${parsed.providerId}; skipped',
      );
      return null;
    }
    final resolved = _refresher != null
        ? await _refresher.refreshIfNeeded(cred)
        : cred;

    final provider = _factory.create(
      providerId: parsed.providerId,
      model: parsed.model,
      credential: resolved,
    );

    final buf = StringBuffer();
    await (() async {
      await for (final e in provider.complete(
        messages: [HarnessMessage.user(prompt)],
        // No `tools:` → inert; the model has no way to act.
        config: LlmCompleteConfig(
          systemPrompt: systemPrompt,
          maxTokens: maxTokens,
          cacheEnabled: false,
        ),
      )) {
        if (e is LlmTextDelta) {
          buf.write(e.text);
        } else if (e is LlmError) {
          throw StateError('one-shot provider error: ${e.message}');
        }
      }
    })().timeout(
      timeout,
      onTimeout: () => throw TimeoutException('one-shot completion', timeout),
    );
    return buf.toString();
  }

  Future<String?> _runPipedCli({
    required Adapter adapter,
    required List<String> args,
    required String input,
    required Duration timeout,
  }) async {
    final cliPath = await _resolveBinary(adapter.cliName);
    if (cliPath == null) {
      CcInfraLog.debug('one-shot: "${adapter.cliName}" not installed; skipped');
      return null;
    }

    final tmp = await Directory.systemTemp.createTemp('cc-one-shot-');
    OneShotProcess? proc;
    try {
      proc = await _launch(cliPath, args, workingDirectory: tmp.path);
      final out = StringBuffer();
      final drained = proc.stdoutLines
          .forEach(out.writeln)
          .then((_) => proc!.exitCode);

      proc.writeStdin(input);
      await proc.closeStdin();

      final exitCode = await drained.timeout(timeout);
      if (exitCode != 0) {
        throw StateError(
          'one-shot: ${adapter.cliName} exited with code $exitCode',
        );
      }
      return out.toString();
    } finally {
      proc?.kill();
      unawaited(tmp.delete(recursive: true).catchError((_) => tmp));
    }
  }

  Future<String?> _runAcp({
    required String? workspaceId,
    required String? requestedByUserId,
    required Adapter adapter,
    required String? modelId,
    required String systemPrompt,
    required String prompt,
    required Duration timeout,
  }) async {
    final cliPath = await _resolveBinary(adapter.cliName);
    if (cliPath == null) {
      CcInfraLog.debug('one-shot: "${adapter.cliName}" not installed; skipped');
      return null;
    }

    final acpArgs = adapter.acpArgs;
    final tmp = await Directory.systemTemp.createTemp('cc-one-shot-');
    final OneShotSpawn? spawn;
    try {
      spawn = await _confinement.spawnFor(
        workspaceId: workspaceId,
        requestedByUserId: requestedByUserId,
        workdir: tmp.path,
      );
    } on Object {
      unawaited(tmp.delete(recursive: true).catchError((_) => tmp));
      rethrow;
    }
    if (spawn == null) {
      unawaited(tmp.delete(recursive: true).catchError((_) => tmp));
      CcInfraLog.debug(
        'one-shot: no sandbox here and the requester is not the server '
        'owner; ${adapter.cliName} not started',
      );
      return null;
    }
    OneShotProcess? proc;
    StreamSubscription<String>? stdoutSub;
    StreamSubscription<AgentProcessEvent>? eventsSub;
    try {
      final command = await spawn.prepare([
        cliPath,
        if (acpArgs != null && acpArgs.isNotEmpty) acpArgs,
      ]);
      proc = await _launch(
        command.executable,
        command.argv,
        workingDirectory: tmp.path,
        environment: command.environment.isEmpty ? null : command.environment,
      );
      final spawned = proc;

      final client = AcpClient(send: spawned.writeStdin);
      stdoutSub = spawned.stdoutLines.listen(client.feedLine);

      final out = StringBuffer();
      eventsSub = client.events.listen((e) {
        if (e is TextEvent) {
          out.write(e.content);
        }
      });

      await (() async {
        await client.initialize();
        final sessionId = await client.sessionNew(
          cwd: tmp.path,
          model: modelId,
        );
        // ACP has no separate system-prompt channel on `session/prompt`, so
        // the instruction leads the turn's only message.
        await client.sessionPrompt(
          sessionId: sessionId,
          prompt: '$systemPrompt\n\n$prompt',
        );
      })().timeout(timeout);

      // The turn's updates arrive before the prompt result, so the buffer is
      // complete once sessionPrompt returns. Yield once so the last
      // notification queued on the events stream lands.
      await Future<void>.delayed(Duration.zero);
      return out.toString();
    } finally {
      await stdoutSub?.cancel();
      await eventsSub?.cancel();
      proc?.kill();
      await spawn.release();
      unawaited(tmp.delete(recursive: true).catchError((_) => tmp));
    }
  }
}

/// Spawns a real subprocess. The production [OneShotLauncher].
Future<OneShotProcess> _spawnIoProcess(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
  Map<String, String>? environment,
}) async {
  final process = await ChildProcess.start(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    environment: environment,
    toolchain: true,
  );
  return _IoOneShotProcess(process);
}

class _IoOneShotProcess implements OneShotProcess {
  _IoOneShotProcess(this._process) {
    // Drain stderr so a chatty CLI cannot fill its pipe buffer and deadlock
    // waiting for a reader that never comes.
    _stderrSub = _process.stderr.listen((_) {});
  }

  final Process _process;
  late final StreamSubscription<List<int>> _stderrSub;
  bool _dead = false;

  @override
  Stream<String> get stdoutLines =>
      _process.stdout.transform(utf8.decoder).transform(const LineSplitter());

  @override
  void writeStdin(String data) => _process.stdin.write(data);

  @override
  Future<void> closeStdin() => _process.stdin.close();

  @override
  Future<int> get exitCode => _process.exitCode;

  @override
  void kill() {
    if (_dead) {
      return;
    }
    _dead = true;
    unawaited(_stderrSub.cancel());
    _process.kill(ProcessSignal.sigkill);
  }
}
