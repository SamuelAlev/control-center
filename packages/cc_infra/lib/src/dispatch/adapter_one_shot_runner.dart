/// @docImport 'package:cc_infra/src/dispatch/dispatch_session.dart';
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/ports/run_credential_gate_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/features/agents/domain/services/content_synthesizer.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/run_end_reason.dart';
import 'package:cc_domain/features/settings/domain/entities/adapter.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:cc_infra/src/dispatch/acp/acp_client.dart';
import 'package:cc_infra/src/dispatch/agent_dispatch_service.dart';
import 'package:cc_infra/src/dispatch/backends/cli_backends.dart';
import 'package:cc_infra/src/dispatch/claude_refusal_message.dart';
import 'package:cc_infra/src/dispatch/one_shot_confinement.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/process/binary_resolver.dart';
import 'package:cc_infra/src/process/child_process.dart';
import 'package:cc_infra/src/sandboxing/claude_stream_json.dart';
import 'package:cc_infra/src/sandboxing/run_log_writer.dart';
import 'package:cc_infra/src/util/command_redaction.dart';
import 'package:uuid/uuid.dart';

/// One spawned adapter process, abstracted away from `dart:io` so the runner
/// is unit-testable without any CLI installed on the host.
abstract interface class OneShotProcess {
  /// The process's stdout, already decoded and split into lines.
  Stream<String> get stdoutLines;

  /// The process's bounded stderr output once the stream closes or is killed.
  Future<String> get stderrOutput;

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
/// Not a [DispatchSession]: no worktree, sandbox, MCP, or path locks — those
/// would put provisioning on the chat send path for a tiny naming completion.
/// Still honours the workspace/agent account pools and writes an [AgentRunLog]
/// (+ NDJSON transcript under `<agentDir>/runs/`) when wired, so runs are
/// observable under Agents → Logs without cluttering space/conversation trees.
/// - [AdapterTransport.harness]: in-process [LlmProviderPort]; supports
///   `maxTokens`, credential rotation, and token accounting.
/// - [AdapterTransport.claudeCli]: `claude -p --output-format text` with no
///   tools, no MCP servers and the caller's system prompt replacing Claude Code's
///   own, using the resolved Claude account pool (`CLAUDE_CONFIG_DIR`).
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
    this._resolveClaudeConfigDir,
    this._resolveHarnessRotation,
    this._onHarnessCredentialExhausted,
    this._runLogRepo,
    this._agentDir,
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

  /// Resolves the Claude Code account plan for an agent/workspace.
  final Future<ClaudeAccountPlan?> Function({
    String? workspaceId,
    String? conversationId,
    String? agentId,
    String? accountId,
    String? workingDirectory,
  })?
  _resolveClaudeConfigDir;

  /// Orders a harness provider's stored credentials according to the
  /// agent/workspace account pool.
  final Future<AccountPoolOrder> Function({
    String? workspaceId,
    String? agentId,
    required String providerId,
    required List<String> credentialIds,
  })?
  _resolveHarnessRotation;

  /// Records a harness credential that hit a capacity limit.
  final Future<void> Function({
    required String providerId,
    required String credentialId,
  })?
  _onHarnessCredentialExhausted;

  /// Persists [AgentRunLog] rows for completed/failed one-shot runs when wired.
  final AgentRunLogRepository? _runLogRepo;

  /// Resolves the agent directory where NDJSON run transcripts are written.
  final Future<String> Function(String workspaceId, String agentSlug)? _agentDir;

  /// Runs [prompt] under [systemPrompt] on [adapterId] with [modelId] and
  /// returns the reply text, or null when the adapter cannot run.
  ///
  /// [requestedByUserId] is the person whose message or action asked for it
  /// in [workspaceId]; null is nobody, which is never the server owner.
  ///
  /// [agentId], [agentSlug], and [taskFamily] identify the synthesizing agent
  /// for per-agent account pool selection and [AgentRunLog] attribution.
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
    String? agentId,
    String? agentSlug,
    String? taskFamily,
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

    final runLog =
        (_runLogRepo != null &&
            workspaceId != null &&
            workspaceId.isNotEmpty &&
            agentId != null &&
            agentId.isNotEmpty)
        ? _OneShotRunLog(
            repo: _runLogRepo,
            agentDir: _agentDir,
            workspaceId: workspaceId,
            agentId: agentId,
            agentSlug: agentSlug ?? kContentSynthesizerSlug,
            adapter: adapter,
            modelId: modelId,
            requestedByUserId: requestedByUserId,
            taskFamily: taskFamily ?? 'one_shot',
          )
        : null;

    return switch (adapter.transport) {
      AdapterTransport.harness => _runHarness(
        workspaceId: workspaceId,
        agentId: agentId,
        modelId: modelId,
        systemPrompt: systemPrompt,
        prompt: prompt,
        timeout: timeout,
        maxTokens: maxTokens,
        runLog: runLog,
      ),
      AdapterTransport.claudeCli => _runClaudeCli(
        workspaceId: workspaceId,
        agentId: agentId,
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
        systemPrompt: systemPrompt,
        prompt: prompt,
        timeout: timeout,
        runLog: runLog,
      ),
      AdapterTransport.acp => _runAcp(
        workspaceId: workspaceId,
        requestedByUserId: requestedByUserId,
        adapter: adapter,
        modelId: modelId,
        systemPrompt: systemPrompt,
        prompt: prompt,
        timeout: timeout,
        runLog: runLog,
      ),
    };
  }

  Future<String?> _runHarness({
    required String? workspaceId,
    required String? agentId,
    required String? modelId,
    required String systemPrompt,
    required String prompt,
    required Duration timeout,
    required int maxTokens,
    required _OneShotRunLog? runLog,
  }) async {
    final modelSpecs = (modelId ?? '')
        .split('|')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final parsed = _factory.parseModel(
      modelSpecs.isEmpty ? modelId : modelSpecs.first,
    );
    final providerId = parsed.providerId;
    final extraSpecs = modelSpecs.length > 1
        ? modelSpecs.sublist(1)
        : const <String>[];

    final LlmProviderPort provider;
    final rotate = _resolveHarnessRotation;
    if (rotate == null) {
      // Server-owned credential resolution (UI-saved key/OAuth + refresh). No
      // credential for the provider → nothing to call; skip quietly rather than
      // guessing another provider.
      final cred = await _creds.activeCredential(providerId);
      if (cred == null) {
        CcInfraLog.debug('one-shot: no credential for $providerId; skipped');
        return null;
      }
      await runLog?.start(prompt: prompt, systemPrompt: systemPrompt);
      try {
        final resolved = _refresher != null
            ? await _refresher.refreshIfNeeded(cred)
            : cred;
        provider = _factory.create(
          providerId: providerId,
          model: parsed.model,
          credential: resolved,
          tokenResolver: _tokenResolverFor(resolved),
        );
      } on Object catch (e) {
        await runLog?.fail(e);
        rethrow;
      }
    } else {
      final stored = await _creds.credentialsFor(providerId);
      var usable = [
        for (final cred in stored)
          if (cred.method != HarnessAuthMethod.none || cred.dialect != null)
            cred,
      ];
      final active = await _creds.activeCredential(providerId);
      if (usable.isEmpty && active != null) {
        usable = [active];
      }
      if (usable.isEmpty) {
        CcInfraLog.debug('one-shot: no credential for $providerId; skipped');
        return null;
      }

      await runLog?.start(prompt: prompt, systemPrompt: systemPrompt);
      try {
        final answer = await rotate(
          workspaceId: workspaceId,
          agentId: agentId,
          providerId: providerId,
          credentialIds: [for (final c in usable) c.credentialId],
        );
        if (answer.refusal case final refusal?) {
          final err = StateError(harnessPoolRefusalDetail(providerId, refusal));
          await runLog?.fail(
            err,
            endReason: refusal.reason == RunCredentialReason.planSpent
                ? RunEndReason.usageLimit
                : RunEndReason.error,
          );
          throw err;
        }

        final ordered = _orderCredentials(
          usable: usable,
          order: answer.order,
          active: active,
        );

        final entries = <FallbackEntry>[];
        for (var i = 0; i < ordered.length; i++) {
          var cred = ordered[i];
          if (i == 0 && _refresher != null) {
            cred = await _refresher.refreshIfNeeded(cred);
          }
          final resolver = _tokenResolverFor(cred);
          entries.add(
            FallbackEntry(
              providerId: providerId,
              model: parsed.model ?? '',
              credentialId: cred.credentialId,
              build: () => _factory.create(
                providerId: providerId,
                model: parsed.model,
                credential: cred,
                tokenResolver: resolver,
              ),
            ),
          );
        }

        for (final spec in extraSpecs) {
          final extra = _factory.parseModel(spec);
          final cred = await _creds.activeCredential(extra.providerId);
          if (cred == null) {
            continue;
          }
          final resolver = _tokenResolverFor(cred);
          entries.add(
            FallbackEntry(
              providerId: extra.providerId,
              model: extra.model ?? '',
              credentialId: cred.credentialId,
              build: () => _factory.create(
                providerId: extra.providerId,
                model: extra.model,
                credential: cred,
                tokenResolver: resolver,
              ),
            ),
          );
        }

        if (entries.length == 1) {
          provider = entries.single.build();
        } else {
          provider = FallbackProvider(
            entries,
            onFallback:
                (from, to, reason, {fromCredentialId, capacity = false}) {
                  if (capacity && fromCredentialId != null) {
                    unawaited(
                      _onHarnessCredentialExhausted?.call(
                            providerId: from,
                            credentialId: fromCredentialId,
                          ) ??
                          Future<void>.value(),
                    );
                  }
                  runLog?.logDebug(
                    '[harness] provider fallback $from → $to ($reason)',
                  );
                },
          );
        }
      } on Object catch (e) {
        await runLog?.fail(e);
        rethrow;
      }
    }

    final buf = StringBuffer();
    LlmUsage? usage;
    try {
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
          } else if (e is LlmUsage) {
            usage = (usage ?? const LlmUsage()).reconcile(e);
          } else if (e is LlmDone && e.usage != null) {
            usage = (usage ?? const LlmUsage()).reconcile(e.usage);
          } else if (e is LlmError) {
            final err = StateError('one-shot provider error: ${e.message}');
            await runLog?.fail(
              err,
              endReason: e.kind.isCapacity
                  ? RunEndReason.usageLimit
                  : RunEndReason.error,
            );
            throw err;
          }
        }
      })().timeout(
        timeout,
        onTimeout: () => throw TimeoutException('one-shot completion', timeout),
      );
      final out = buf.toString();
      final u = usage;
      final cost = u == null
          ? null
          : RunCost(
              inputTokens: u.inputTokens,
              outputTokens: u.outputTokens,
              thoughtTokens: u.thoughtTokens,
              cachedReadTokens: u.cacheReadTokens,
              cachedWriteTokens: u.cacheWriteTokens,
            );
      await runLog?.succeed(out, cost: cost);
      return out;
    } on Object catch (e) {
      await runLog?.fail(e);
      rethrow;
    }
  }

  ProviderTokenResolver? _tokenResolverFor(ProviderCredential? credential) {
    final refresher = _refresher;
    if (credential == null ||
        refresher == null ||
        credential.method != HarnessAuthMethod.oauth) {
      return null;
    }
    return RefreshingCredential(refresher, credential).resolve;
  }

  static List<ProviderCredential> _orderCredentials({
    required List<ProviderCredential> usable,
    required List<String>? order,
    required ProviderCredential? active,
  }) {
    if (order != null && order.isNotEmpty) {
      final byId = {for (final c in usable) c.credentialId: c};
      final resolved = [
        for (final id in order)
          if (byId[id] != null) byId[id]!,
      ];
      if (resolved.isNotEmpty) {
        return resolved;
      }
    }
    if (active != null) {
      return [
        active,
        for (final c in usable)
          if (c.credentialId != active.credentialId) c,
      ];
    }
    return usable;
  }

  Future<String?> _runClaudeCli({
    required String? workspaceId,
    required String? agentId,
    required Adapter adapter,
    required List<String> args,
    required String systemPrompt,
    required String prompt,
    required Duration timeout,
    required _OneShotRunLog? runLog,
  }) async {
    final cliPath = await _resolveBinary(adapter.cliName);
    if (cliPath == null) {
      CcInfraLog.debug('one-shot: "${adapter.cliName}" not installed; skipped');
      return null;
    }

    await runLog?.start(prompt: prompt, systemPrompt: systemPrompt);
    final tmp = await Directory.systemTemp.createTemp('cc-one-shot-');
    try {
      final resolvePlan = _resolveClaudeConfigDir;
      final plan = resolvePlan == null
          ? null
          : await resolvePlan(workspaceId: workspaceId, agentId: agentId);

      if (plan?.refusal case final refusal?) {
        final msg = claudeRefusalDetail(refusal);
        await runLog?.fail(
          msg,
          endReason: refusal.reason == RunCredentialReason.planSpent
              ? RunEndReason.usageLimit
              : RunEndReason.error,
        );
        throw StateError(msg);
      }

      final attempts = (plan == null || plan.accounts.isEmpty)
          ? const <({String accountId, String configDir})>[
              (accountId: '', configDir: ''),
            ]
          : plan.accounts;

      final deadline = DateTime.now().add(timeout);
      for (var i = 0; i < attempts.length; i++) {
        final remaining = deadline.difference(DateTime.now());
        if (remaining <= Duration.zero) {
          throw TimeoutException('one-shot completion', timeout);
        }
        final attempt = attempts[i];
        if (attempt.accountId.isNotEmpty) {
          runLog?.logDebug('[claude] trying account ${attempt.accountId}');
        }
        final env = <String, String>{
          ...ClaudeCliBackend.autoMemoryOffEnv,
          if (attempt.configDir.isNotEmpty)
            'CLAUDE_CONFIG_DIR': attempt.configDir,
        };

        OneShotProcess? proc;
        final String outText;
        final String stderrText;
        final int exitCode;
        try {
          proc = await _launch(
            cliPath,
            args,
            workingDirectory: tmp.path,
            environment: env,
          );
          final out = StringBuffer();
          final drained = proc.stdoutLines
              .forEach(out.writeln)
              .then((_) => proc!.exitCode);

          proc.writeStdin(prompt);
          await proc.closeStdin();

          exitCode = await drained.timeout(remaining);
          stderrText = await proc.stderrOutput.timeout(
            const Duration(seconds: 2),
            onTimeout: () => '',
          );
          outText = out.toString();
        } finally {
          proc?.kill();
        }

        final trimmedOut = outText.trim();
        final loggedOutZero =
            exitCode == 0 &&
            trimmedOut.isNotEmpty &&
            trimmedOut.length < 200 &&
            ClaudeTerminalError(message: trimmedOut).isAuth;

        if (exitCode == 0 && !loggedOutZero) {
          await runLog?.succeed(outText);
          return outText;
        }

        final detail = _cliFailureDetail(stderrText, outText);
        final failure = ClaudeTerminalError(
          message: detail,
          resetsAt: ClaudeTerminalError.parseResetEpoch(detail),
        );
        final accountFailure = failure.isCapacity || failure.isAuth;

        if (accountFailure && attempt.accountId.isNotEmpty) {
          await _reportClaudeFailure(plan, attempt.accountId, failure);
        }
        if (accountFailure && i + 1 < attempts.length) {
          final next = attempts[i + 1];
          runLog?.logDebug(
            '[claude] account fallback ${attempt.accountId} → '
            '${next.accountId} '
            '(${failure.isCapacity ? 'out of plan headroom' : 'credential expired'})',
          );
          continue;
        }

        final err = StateError(
          'one-shot: ${adapter.cliName} exited with code $exitCode'
          '${detail.isEmpty ? '' : ': $detail'}',
        );
        await runLog?.fail(
          err,
          endReason: failure.isCapacity
              ? RunEndReason.usageLimit
              : RunEndReason.error,
        );
        throw err;
      }

      throw StateError('one-shot: ${adapter.cliName} exhausted all attempts');
    } on Object catch (e) {
      await runLog?.fail(e);
      rethrow;
    } finally {
      unawaited(tmp.delete(recursive: true).catchError((_) => tmp));
    }
  }

  static Future<void> _reportClaudeFailure(
    ClaudeAccountPlan? plan,
    String accountId,
    ClaudeTerminalError failure,
  ) async {
    try {
      if (failure.isCapacity) {
        await plan?.onExhausted?.call(
          accountId: accountId,
          resetsAt: failure.resetsAt,
        );
      } else if (failure.isAuth) {
        await plan?.onAuthFailed?.call(
          accountId: accountId,
          reason: redactSecrets(failure.message),
        );
      }
    } on Object catch (e) {
      CcInfraLog.warning('one-shot: failed to record Claude failure: $e');
    }
  }

  static String _cliFailureDetail(String stderrText, String stdoutText) {
    final parts = [
      if (stderrText.trim().isNotEmpty) stderrText.trim(),
      if (stdoutText.trim().isNotEmpty) stdoutText.trim(),
    ];
    if (parts.isEmpty) {
      return '';
    }
    final combined = redactSecrets(parts.join(' | ')).replaceAll('\n', ' ');
    return combined.length <= 500
        ? combined
        : '${combined.substring(0, 500).trimRight()}…';
  }

  Future<String?> _runAcp({
    required String? workspaceId,
    required String? requestedByUserId,
    required Adapter adapter,
    required String? modelId,
    required String systemPrompt,
    required String prompt,
    required Duration timeout,
    required _OneShotRunLog? runLog,
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

    await runLog?.start(prompt: prompt, systemPrompt: systemPrompt);
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
      final text = out.toString();
      await runLog?.succeed(text);
      return text;
    } on Object catch (e) {
      await runLog?.fail(e);
      rethrow;
    } finally {
      await stdoutSub?.cancel();
      await eventsSub?.cancel();
      proc?.kill();
      await spawn.release();
      unawaited(tmp.delete(recursive: true).catchError((_) => tmp));
    }
  }
}

/// Records one-shot execution in `agent_run_logs` and `<agentDir>/runs/`.
final class _OneShotRunLog {
  _OneShotRunLog({
    required this.repo,
    required this.agentDir,
    required this.workspaceId,
    required this.agentId,
    required this.agentSlug,
    required this.adapter,
    required this.modelId,
    required this.requestedByUserId,
    required this.taskFamily,
  });

  final AgentRunLogRepository repo;
  final Future<String> Function(String workspaceId, String agentSlug)? agentDir;
  final String workspaceId;
  final String agentId;
  final String agentSlug;
  final Adapter adapter;
  final String? modelId;
  final String? requestedByUserId;
  final String taskFamily;

  final String _runId = const Uuid().v4();
  final DateTime _startedAt = DateTime.now();
  RunLogWriter? _writer;
  AgentRunLog? _row;
  bool _started = false;
  bool _settled = false;

  Future<void> start({
    required String prompt,
    required String systemPrompt,
  }) async {
    if (_started) {
      return;
    }
    _started = true;
    try {
      final resolveDir = agentDir;
      if (resolveDir != null) {
        final dir = await resolveDir(workspaceId, agentSlug);
        final writer = RunLogWriter();
        await writer.open(
          agentDirHostPath: dir,
          agentId: agentId,
          workspaceId: workspaceId,
          cliName: adapter.cliName,
          modelId: modelId,
        );
        _writer = writer;
        writer.logEvent(
          DebugEvent(
            content:
                '[one-shot] task=$taskFamily adapter=${adapter.id}'
                '${modelId != null && modelId!.isNotEmpty ? ' model=$modelId' : ''}',
          ),
        );
        final preview = prompt.length <= 4000
            ? prompt
            : '${prompt.substring(0, 4000)}\n…[truncated]';
        writer.logEvent(DebugEvent(content: '[one-shot] prompt:\n$preview'));
      }
      final row = AgentRunLog(
        id: _runId,
        agentId: agentId,
        workspaceId: workspaceId,
        startedAt: _startedAt,
        status: RunStatus.running,
        adapter: adapter.id,
        modelId: modelId,
        taskFamily: taskFamily,
        logPath: _writer?.logPath,
        requestedByUserId: (requestedByUserId?.isEmpty ?? true)
            ? null
            : requestedByUserId,
      );
      _row = row;
      await repo.upsert(row);
    } on Object catch (e) {
      CcInfraLog.warning('one-shot: failed to open run log: $e');
    }
  }

  void logDebug(String message) {
    _writer?.logEvent(DebugEvent(content: message));
  }

  Future<void> succeed(String text, {RunCost? cost}) async {
    if (!_started || _settled) {
      return;
    }
    _settled = true;
    final completedAt = DateTime.now();
    final elapsedMs = completedAt.difference(_startedAt).inMilliseconds;
    try {
      final writer = _writer;
      if (writer != null) {
        writer.logEvent(TextEvent(content: text));
        writer.logEvent(DoneEvent());
        await writer.close(exitCode: 0);
      }
      final row = _row;
      if (row != null) {
        final effectiveCost = (cost ?? RunCost.zero).copyWith(
          durationMs: elapsedMs,
        );
        await repo.completeIfActive(
          row.copyWith(
            status: RunStatus.completed,
            completedAt: completedAt,
            summary: _summarize(text, 120),
            endReason: RunEndReason.completed,
            cost: effectiveCost,
          ),
          writeCost: cost != null,
        );
      }
    } on Object catch (e) {
      CcInfraLog.warning('one-shot: failed to complete run log: $e');
    }
  }

  Future<void> fail(
    Object error, {
    RunEndReason endReason = RunEndReason.error,
  }) async {
    if (!_started || _settled) {
      return;
    }
    _settled = true;
    final completedAt = DateTime.now();
    final elapsedMs = completedAt.difference(_startedAt).inMilliseconds;
    final redacted = redactSecrets('$error');
    try {
      final writer = _writer;
      if (writer != null) {
        writer.logEvent(ErrorEvent(content: redacted));
        await writer.close(exitCode: 1, error: redacted);
      }
      final row = _row;
      if (row != null) {
        await repo.completeIfActive(
          row.copyWith(
            status: RunStatus.error,
            completedAt: completedAt,
            summary: _summarize(redacted, 300),
            endReason: endReason,
            cost: RunCost(durationMs: elapsedMs),
          ),
          writeCost: false,
        );
      }
    } on Object catch (e) {
      CcInfraLog.warning('one-shot: failed to record run log error: $e');
    }
  }

  static String? _summarize(String raw, int maxChars) {
    final cleaned = redactSecrets(raw).replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.isEmpty) {
      return null;
    }
    return cleaned.length <= maxChars
        ? cleaned
        : '${cleaned.substring(0, maxChars).trimRight()}…';
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
    // Drain stderr into a bounded buffer so a chatty CLI cannot deadlock on a
    // full pipe while still preserving error details for diagnostics.
    _stderrSub = _process.stderr
        .transform(const Utf8Decoder(allowMalformed: true))
        .listen(
          (chunk) {
            if (_stderrBuf.length >= _maxStderrChars) {
              _stderrTruncated = true;
              return;
            }
            final remaining = _maxStderrChars - _stderrBuf.length;
            if (chunk.length <= remaining) {
              _stderrBuf.write(chunk);
            } else {
              _stderrBuf.write(chunk.substring(0, remaining));
              _stderrTruncated = true;
            }
          },
          onDone: _completeStderr,
          onError: (Object _) => _completeStderr(),
        );
  }

  static const int _maxStderrChars = 16384;

  final Process _process;
  late final StreamSubscription<String> _stderrSub;
  final StringBuffer _stderrBuf = StringBuffer();
  final Completer<String> _stderrDone = Completer<String>();
  bool _stderrTruncated = false;
  bool _dead = false;

  void _completeStderr() {
    if (_stderrDone.isCompleted) {
      return;
    }
    final text = _stderrBuf.toString();
    _stderrDone.complete(_stderrTruncated ? '$text\n…[truncated]' : text);
  }

  @override
  Stream<String> get stdoutLines => _process.stdout
      .transform(const Utf8Decoder(allowMalformed: true))
      .transform(const LineSplitter());

  @override
  Future<String> get stderrOutput => _stderrDone.future;

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
    _completeStderr();
    unawaited(_stderrSub.cancel());
    _process.kill(ProcessSignal.sigkill);
  }
}
