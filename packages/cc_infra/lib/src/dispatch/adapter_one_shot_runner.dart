import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/settings/domain/entities/adapter.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:cc_infra/src/dispatch/acp/acp_client.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/process/binary_resolver.dart';

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

/// Runs **one tool-less prompt** on any adapter and returns its text.
///
/// This is deliberately NOT `DispatchSession`. A dispatch is an agent run: it
/// resolves an agent, provisions a worktree, opens a run log, enters the OS
/// sandbox, wires MCP and accounts for cost. None of that has any meaning for
/// a single 128-token completion that names a conversation, and paying for it
/// per first message would put worktree provisioning on the chat send path.
///
/// So this runner spawns the adapter directly, hands it the prompt on stdin,
/// reads its answer and kills it. Nothing it runs can touch the filesystem: no
/// MCP config is passed, no tools are declared and the process is given a
/// throwaway working directory.
///
/// Four transports, four mechanisms — the differences are stated rather than
/// smoothed over, because they are not equivalent:
///
///  * [AdapterTransport.harness] — no process at all. Builds an
///    [LlmProviderPort] from the qualified `provider/model` id and streams one
///    completion. The only transport with a token budget we control
///    (`maxTokens`) and the only one whose credential we resolve.
///  * [AdapterTransport.claudeCli] — `claude -p --output-format text`. The
///    system prompt is folded into the piped prompt rather than passed as a
///    flag, so the invocation stays on the three flags this repo already
///    drives Claude Code with.
///  * [AdapterTransport.structuredCli] — the bare CLI with a piped prompt,
///    deliberately WITHOUT `--mode json`: the NDJSON event schema is parsed by
///    the sandbox port, and reaching for it here would drag the sandbox onto
///    this path for output we want as plain text anyway.
///  * [AdapterTransport.acp] — the full `initialize` → `session/new` →
///    `session/prompt` handshake over stdio via [AcpClient], collecting the
///    turn's [TextEvent]s.
///
/// Returns **null** when the adapter cannot run at all (unknown id, CLI not
/// installed, no credential for the harness provider). That is a quiet skip,
/// not an error: the caller keeps whatever it had. A failure *during* the run
/// throws, so a caller that wants fail-open has to say so.
class AdapterOneShotRunner {
  /// Creates an [AdapterOneShotRunner].
  AdapterOneShotRunner({
    required ProviderCredentialStore credentials,
    HarnessProviderFactory factory = const HarnessProviderFactory(),
    ProviderCredentialRefresher? refresher,
    Future<String?> Function(String cliName)? resolveBinary,
    OneShotLauncher? launcher,
    Iterable<Adapter>? adapters,
  }) : _creds = credentials,
       _factory = factory,
       _refresher = refresher,
       _resolveBinary = resolveBinary ?? resolveBinaryPath,
       _launch = launcher ?? _spawnIoProcess,
       _adapters = adapters ?? predefinedAdapters;

  final ProviderCredentialStore _creds;
  final HarnessProviderFactory _factory;
  final ProviderCredentialRefresher? _refresher;
  final Future<String?> Function(String cliName) _resolveBinary;
  final OneShotLauncher _launch;
  final Iterable<Adapter> _adapters;

  /// Runs [prompt] under [systemPrompt] on [adapterId] with [modelId] and
  /// returns the reply text, or null when the adapter cannot run.
  ///
  /// [timeout] is a hard wall-clock ceiling on the whole attempt including
  /// process spawn; the process is killed when it expires. [maxTokens] bounds
  /// the reply on the harness transport only — an external CLI owns its own
  /// output budget and there is no flag we can portably set.
  Future<String?> complete({
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
        args: [
          '-p',
          '--output-format',
          'text',
          if (modelId != null && modelId.isNotEmpty) ...['--model', modelId],
        ],
        // Claude Code takes `--append-system-prompt`, but this repo has never
        // driven it, so the instruction rides in the piped prompt where every
        // CLI honours it identically.
        input: '$systemPrompt\n\n$prompt',
        timeout: timeout,
      ),
      AdapterTransport.structuredCli => _runPipedCli(
        adapter: adapter,
        args: [
          if (modelId != null && modelId.isNotEmpty) ...['--model', modelId],
        ],
        input: '$systemPrompt\n\n$prompt',
        timeout: timeout,
      ),
      AdapterTransport.acp => _runAcp(
        adapter: adapter,
        modelId: modelId,
        systemPrompt: systemPrompt,
        prompt: prompt,
        timeout: timeout,
      ),
    };
  }

  // -- harness -----------------------------------------------------------

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

  // -- piped CLIs (claude -p, structured CLI) ------------------------------

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

  // -- ACP -----------------------------------------------------------------

  Future<String?> _runAcp({
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
    OneShotProcess? proc;
    StreamSubscription<String>? stdoutSub;
    StreamSubscription<AgentProcessEvent>? eventsSub;
    try {
      proc = await _launch(cliPath, [
        if (acpArgs != null && acpArgs.isNotEmpty) acpArgs,
      ], workingDirectory: tmp.path);
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
  final process = await Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    environment: environment,
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
