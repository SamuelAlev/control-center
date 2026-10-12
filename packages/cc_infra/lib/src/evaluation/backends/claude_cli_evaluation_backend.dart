import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/evals/domain/evaluation/evaluation_attempt.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_backend_port.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_plan.dart';
import 'package:cc_domain/features/evals/domain/value_objects/agent_config_hash.dart';

import 'package:cc_infra/src/dispatch/backends/cli_backends.dart';
import 'package:cc_infra/src/sandboxing/claude_mcp_discovery_cache.dart';
import 'package:cc_infra/src/sandboxing/claude_stream_json.dart';

/// Runs an attempt through the real `claude` CLI in `stream-json` mode.
///
/// The argv is assembled by the product's own [ClaudeCliBackend.buildClaudeArgs]
/// so the evaluation measures the launch path the product actually uses. Effort
/// travels through the product's own mapping, native resume uses an explicit
/// `--resume <session id>` (never `--continue`), and the MCP discovery-cache arm
/// really toggles Claude's cache through its environment recipe.
///
/// Accounting goes through the product's [ClaudeAccountingLedger] so cumulative
/// `total_cost_usd` is deltated against the previous snapshot exactly the way
/// the adapter does — with ONE ledger per SESSION: a fresh CLI invocation starts
/// a new cumulative total, so reusing a ledger across independent sessions would
/// silently drop the earlier session's spend.
class ClaudeCliEvaluationBackend implements EvaluationBackendPort {
  /// Creates a [ClaudeCliEvaluationBackend].
  ClaudeCliEvaluationBackend({
    this.claudePath = 'claude',
    this.permissionMode,
    this.mcpConfigPath,
    this.settingsJson,
    this.configDir,
    this.extraEnv = const {},
    this.capabilities = ClaudeCliCapabilities.baseline,
    this.skipPermissions = true,
    this.turnTimeout = const Duration(minutes: 30),
    this.maxAttemptCostUsd,
    this.systemPrompt = defaultSystemPrompt,
    this.onNotice,
  }) {
    final cap = maxAttemptCostUsd;
    if (cap != null && (!cap.isFinite || cap <= 0)) {
      throw ArgumentError.value(
        cap,
        'maxAttemptCostUsd',
        'must be finite and positive',
      );
    }
  }

  /// The default first-turn brief.
  static const String defaultSystemPrompt =
      "You are Control Center's coding agent, working alone in an isolated "
      'workspace. Use your tools to read, search, edit and run code to '
      'accomplish the task. Be concise and stop when the task is done.';

  /// The `claude` executable.
  final String claudePath;

  /// `--permission-mode`, when the product's mode maps to one.
  final String? permissionMode;

  /// `--mcp-config` path, when the campaign should measure the MCP surface.
  final String? mcpConfigPath;

  /// `--settings` JSON (action-policy hooks).
  final String? settingsJson;

  /// An account's Claude config directory (`CLAUDE_CONFIG_DIR`).
  final String? configDir;

  /// Extra environment variables layered over the parent environment.
  final Map<String, String> extraEnv;

  /// The CLI capabilities to launch with.
  final ClaudeCliCapabilities capabilities;

  /// Whether to pass `--dangerously-skip-permissions` (the workspace is
  /// isolated and disposable).
  final bool skipPermissions;

  /// Per-turn process timeout.
  final Duration turnTimeout;

  /// API-equivalent spending ceiling across all follow-ups in one attempt.
  /// The native CLI enforces its own cap; a single in-flight call can overshoot.
  final double? maxAttemptCostUsd;

  /// The first-turn brief.
  final String systemPrompt;

  /// Optional progress sink.
  final void Function(String message)? onNotice;

  @override
  String get id => 'claude-cli';

  @override
  bool get callsModel => true;

  /// The CLI's tool surface is native and only known once `system/init`
  /// arrives, so it is observed per attempt rather than pinned here.
  List<String> get toolNames => const [];

  @override
  String? unsupportedReason(EvaluationEffectiveConfig effective) {
    if (effective.skillExposure != null) {
      return 'Skill exposure requires the controlled skill executor; native '
          'CLI discovery cannot enforce an absent or pinned package.';
    }
    if (effective.memoryPolicy != MemoryPolicyMode.textCurrent) {
      return 'Claude Code owns its own context management (report 4D); the '
          'harness cannot install ${effective.memoryPolicy.wire} for this '
          'adapter';
    }
    if (effective.toolOverlap != ToolOverlapMode.serial) {
      return 'tool scheduling belongs to the harness loop; the Claude CLI runs '
          'its own tool loop, so ${effective.toolOverlap.wire} would be a '
          'no-op';
    }
    if (effective.sessionContinuity == SessionContinuityMode.nativeResume &&
        !capabilities.supportsResume) {
      return 'the pinned CLI cannot resume an explicit native session';
    }
    if (effective.mcpDiscoveryCache == McpDiscoveryCacheMode.enabled) {
      final path = mcpConfigPath;
      if (path == null || path.isEmpty) {
        return 'MCP discovery caching requires an explicit MCP configuration';
      }
      try {
        final config = jsonDecode(File(path).readAsStringSync());
        if (config is! Map ||
            config['mcpServers'] is! Map ||
            (config['mcpServers'] as Map).isEmpty) {
          return 'MCP discovery caching needs at least one configured server';
        }
      } on FileSystemException {
        return 'MCP discovery configuration cannot be read';
      } on FormatException {
        return 'MCP discovery configuration is not valid JSON';
      }
    }
    final effort = effective.effortLevel;
    if (effort != null &&
        effort.trim().isNotEmpty &&
        ClaudeCliBackend.claudeEffortValue(effort, capabilities) == null) {
      return 'the pinned CLI advertises no --effort value for "$effort", so '
          'the arm would run without the effort it claims';
    }
    return null;
  }

  @override
  Future<EvaluationAttempt> execute(EvaluationAttemptRequest request) async {
    final startedAtEpochMs = DateTime.now().millisecondsSinceEpoch;
    final stopwatch = Stopwatch()..start();
    final toolEvents = <EvaluationToolEvent>[];
    final openCalls = <String, EvaluationToolEvent>{};
    // Reconstructed-conversation material for the fresh arm: what the native
    // session would have carried forward, rebuilt from what the CLI printed.
    final traces = <_TurnTrace>[];

    var tokens = const EvaluationTokenBreakdown();
    var costMicros = 0;
    var costUnavailable = false;
    var requestCount = 0;
    var compactions = 0;
    var pendingCompactions = 0;
    var compactionContinuations = 0;
    var apiRetries = 0;
    var completed = false;
    String? error;
    String? sessionId;
    String? servedModel;
    String? observedCliVersion;
    String? observedToolSurfaceHash;
    int? firstModelEventMs;
    int? firstUsefulTextMs;
    int? firstCliOutputMs;
    int? initMetadataMs;
    var toolSurfaceSize = 0;
    var mcpNote = '';

    final turns = [request.task.prompt, ...request.task.followUps];
    // Every independently scored attempt starts a fresh native session. Only
    // follow-ups within this attempt may resume: carrying a solved session
    // between trials contaminates both quality evidence and cumulative cost.
    var resumedSession = false;

    // ONE ledger per session. A fresh invocation starts its cumulative total
    // from zero, so each fresh session gets its own ledger; a resumed session
    // keeps the accruing one.
    var ledger = ClaudeAccountingLedger();

    try {
      for (var index = 0; index < turns.length; index++) {
        final resume =
            request.effective.sessionContinuity ==
                SessionContinuityMode.nativeResume &&
            sessionId != null &&
            index > 0;
        final restoresTotals =
            ClaudeCliCapabilities.restoresSessionTotalsForVersion(
              observedCliVersion ?? capabilities.version,
            );
        if (!resume || !restoresTotals) {
          // Old CLIs restart their counters even when their history resumes.
          ledger = ClaudeAccountingLedger();
        }
        final prompt = resume
            ? turns[index]
            : _reconstructedPrompt(turns, index, traces);
        final args = buildTurnArgs(
          modelId: _bareModel(request.effective.modelId),
          effortLevel: request.effective.effortLevel,
          permissionMode: permissionMode,
          mcpConfigPath: mcpConfigPath,
          settingsJson: settingsJson,
          skipPermissions: skipPermissions,
          resumeSessionId: resume ? sessionId : null,
          capabilities: capabilities,
        );
        final cap = maxAttemptCostUsd;
        if (cap != null) {
          final remaining = cap - costMicros / 1000000;
          if (remaining <= 0 || costUnavailable) {
            error = 'attempt cost budget exhausted or remaining spend unknown';
            completed = false;
            break;
          }
          args.addAll([
            '--max-budget-usd',
            (remaining +
                    (resume && restoresTotals ? ledger.cumulativeCostUsd : 0))
                .toStringAsFixed(6),
          ]);
        }
        resumedSession = resumedSession || resume;
        var receivedFinalResult = false;
        final trace = _TurnTrace.empty();
        final turn = await _runTurn(
          args: args,
          prompt: prompt,
          workspaceRoot: request.workspaceRoot,
          environment: _environmentFor(request.effective),
          onToolCall: (toolUse) {
            firstModelEventMs ??= stopwatch.elapsedMilliseconds;
            firstUsefulTextMs ??= stopwatch.elapsedMilliseconds;
            openCalls[toolUse.id] = EvaluationToolEvent(
              name: toolUse.name,
              target: _targetOf(toolUse.name, toolUse.input),
            );
            trace.toolLines.add(
              'called ${toolUse.name}: ${jsonEncode(toolUse.input)}',
            );
          },
          onToolResult: (result) {
            final open = openCalls.remove(result.id);
            toolEvents.add(
              EvaluationToolEvent(
                name: open?.name ?? 'tool',
                isError: result.isError,
                target: open?.target,
              ),
            );
            trace.toolLines.add(
              '${open?.name ?? 'tool'} → '
              '${result.isError ? 'error' : 'ok'}: '
              '${result.outputs}',
            );
          },
          onText: (text) {
            firstModelEventMs ??= stopwatch.elapsedMilliseconds;
            trace.assistantText.write(text);
            if (firstUsefulTextMs == null && text.trim().isNotEmpty) {
              firstUsefulTextMs = stopwatch.elapsedMilliseconds;
            }
          },
          onFirstModelEvent: () =>
              firstModelEventMs ??= stopwatch.elapsedMilliseconds,
          onTransportByte: () =>
              firstCliOutputMs ??= stopwatch.elapsedMilliseconds,
          onInit: (init) {
            initMetadataMs ??= stopwatch.elapsedMilliseconds;
            // The CLI's OWN session id, as the resumed arm needs it.
            sessionId = init.sessionId ?? sessionId;
            servedModel ??= init.model;
            observedCliVersion ??= init.claudeCodeVersion;
            observedToolSurfaceHash ??= _surfaceHash(init.tools);
            toolSurfaceSize = init.tools.length;
            mcpNote = _describeMcp(init);
          },
          onUsage: (usage) {
            receivedFinalResult = true;
            if (usage.subtype == 'success') {
              compactionContinuations += pendingCompactions;
              pendingCompactions = 0;
            }
            final accounting = ledger.record(usage);
            // Round trips are the CLI's own per-invocation request/turn count,
            // not one per external user turn.
            requestCount += usage.numTurns ?? 1;
            tokens =
                tokens +
                EvaluationTokenBreakdown(
                  uncachedInput: accounting.tokenDelta.inputTokens,
                  cacheWrite: accounting.tokenDelta.cacheWriteTokens,
                  cacheRead: accounting.tokenDelta.cacheReadTokens,
                  // Reasoning is included in output by the native CLI.
                  output: accounting.tokenDelta.outputTokens,
                  reasoningSeparatelyReported: false,
                );
            costMicros += accounting.costDeltaMicros;
            costUnavailable = costUnavailable || accounting.costUnavailable;
            sessionId = usage.sessionId ?? sessionId;
            if (accounting.subtype != null &&
                accounting.subtype!.startsWith('error')) {
              error = 'claude result subtype: ${accounting.subtype}';
            }
          },
          onCompact: () {
            compactions++;
            pendingCompactions++;
          },
          onApiRetry: () => apiRetries++,
          onError: (message) {
            error ??= message;
          },
          onSdkError: (message) {
            error ??= message;
          },
        );
        traces.add(trace);
        if (!receivedFinalResult) {
          costUnavailable = true;
        }
        if (turn.timedOut) {
          error = 'turn timed out after ${turnTimeout.inSeconds}s';
          completed = false;
          break;
        }
        if (turn.exitCode != 0) {
          error = turn.exitCode == 127
              ? '"$claudePath" not found on PATH'
              : 'claude exited with code ${turn.exitCode}: '
                    '${_excerpt(turn.stderr)}';
          completed = false;
          break;
        }
        if (!receivedFinalResult) {
          error ??= 'Claude exited without a final accounting result';
          costUnavailable = true;
          completed = false;
          break;
        }
        if (error != null) {
          completed = false;
          break;
        }
        completed = true;
      }
    } on Object catch (exception) {
      error = '$exception';
      completed = false;
    }
    stopwatch.stop();

    final metrics = EvaluationAttemptMetrics.fromToolEvents(
      toolEvents,
      modelRoundTrips: requestCount,
      userTurns: turns.length,
      providerRetries: apiRetries,
      compactions: compactions,
      compactionRecoveries: compactionContinuations,
      initMetadataMs: initMetadataMs,
    );

    return EvaluationAttempt(
      attemptId: request.attemptId,
      taskId: request.task.id,
      taskKind: request.task.kind,
      armId: request.arm.id,
      effective: request.effective,
      stratum: request.stratum,
      repetition: request.repetition,
      seed: request.seed,
      ordinal: request.ordinal,
      startedAtEpochMs: startedAtEpochMs,
      executionMode: request.executionMode,
      resumedSession: resumedSession,
      sessionId: sessionId,
      servedModel: servedModel,
      servedEffort: ClaudeCliBackend.claudeEffortValue(
        request.effective.effortLevel,
        capabilities,
      ),
      observedCliVersion: observedCliVersion,
      observedToolSurfaceHash: observedToolSurfaceHash,
      completed: completed,
      error: error,
      tokens: tokens,
      cost: costUnavailable
          ? const EvaluationCostRoles()
          : EvaluationCostRoles(estimatedApiMicros: costMicros),
      latency: EvaluationLatency(
        firstModelEventMs: firstModelEventMs,
        firstUsefulTextMs: firstUsefulTextMs,
        totalMs: stopwatch.elapsedMilliseconds,
      ),
      metrics: metrics,
      toolEvents: toolEvents,
      verification: const [],
      filesTouched: const [],
      notes: [
        'claude-cli',
        if (firstCliOutputMs != null) 'first CLI output ${firstCliOutputMs}ms',
        if (servedModel != null) 'served model $servedModel',
        if (toolSurfaceSize > 0) 'tool surface $toolSurfaceSize tool(s)',
        if (mcpNote.isNotEmpty) mcpNote,
        'CLI compaction recovery counts successful post-fold continuations, '
            'not inferred rereads or provider overflow retries',
        if (costUnavailable) 'cost unavailable for at least one turn',
        if (resumedSession) 'native resume used for follow-up turns',
      ].join('; '),
    );
  }

  /// The environment for one arm: the MCP discovery-cache arm really toggles
  /// Claude's cache, and the CONTROL arm explicitly disables it so an inherited
  /// `MCP_DISCOVERY_CACHE=1` cannot silently erase the intervention.
  Map<String, String> _environmentFor(EvaluationEffectiveConfig effective) {
    final enabled =
        effective.mcpDiscoveryCache == McpDiscoveryCacheMode.enabled;
    if (!enabled) {
      return const {'MCP_DISCOVERY_CACHE': '0'};
    }
    return const ClaudeMcpDiscoveryCachePolicy(
      enabled: true,
    ).envFor(trustCache: true);
  }

  /// The argv for one turn.
  static List<String> buildTurnArgs({
    required String? modelId,
    String? effortLevel,
    String? permissionMode,
    String? mcpConfigPath,
    String? settingsJson,
    bool skipPermissions = true,
    String? resumeSessionId,
    ClaudeCliCapabilities capabilities = ClaudeCliCapabilities.baseline,
  }) => ClaudeCliBackend.buildClaudeArgs(
    modelId: modelId,
    permissionMode: permissionMode,
    mcpConfigPath: mcpConfigPath,
    settingsJson: settingsJson,
    skipPermissions: skipPermissions,
    effortLevel: effortLevel,
    resumeSessionId: resumeSessionId,
    capabilities: capabilities,
  );

  /// The prompt for a non-resumed turn: the standing brief plus the COMPLETE
  /// conversation so far — user turns, assistant text and tool activity — so the
  /// baseline reconstructs the same conversation the resumed arm inherits
  /// natively.
  String _reconstructedPrompt(
    List<String> turns,
    int index,
    List<_TurnTrace> traces,
  ) {
    final buffer = StringBuffer()
      ..writeln('<cc-eval-brief>')
      ..writeln(systemPrompt)
      ..writeln('</cc-eval-brief>')
      ..writeln();
    for (var i = 0; i <= index; i++) {
      buffer.writeln('user: ${turns[i]}');
      final trace = i < traces.length ? traces[i] : null;
      if (trace == null) {
        continue;
      }
      final assistant = trace.assistantText.toString().trim();
      if (assistant.isNotEmpty) {
        buffer.writeln('assistant: $assistant');
      }
      for (final line in trace.toolLines) {
        buffer.writeln('tool: $line');
      }
    }
    return buffer.toString();
  }

  Future<_TurnOutcome> _runTurn({
    required List<String> args,
    required String prompt,
    required String workspaceRoot,
    required Map<String, String> environment,
    required void Function(ClaudeToolUse toolUse) onToolCall,
    required void Function(ClaudeToolResult result) onToolResult,
    required void Function(String text) onText,
    required void Function() onFirstModelEvent,
    required void Function() onTransportByte,
    required void Function(ClaudeInitMetadata init) onInit,
    required void Function(ClaudeUsage usage) onUsage,
    required void Function() onCompact,
    required void Function() onApiRetry,
    required void Function(String message) onError,
    required void Function(String message) onSdkError,
  }) async {
    Process process;
    try {
      process = await Process.start(
        claudePath,
        args,
        workingDirectory: workspaceRoot,
        environment: {
          ...Platform.environment,
          if (configDir != null && configDir!.isNotEmpty)
            'CLAUDE_CONFIG_DIR': configDir!,
          ...extraEnv,
          ...environment,
        },
      );
    } on ProcessException catch (exception) {
      return _TurnOutcome(
        exitCode: 127,
        timedOut: false,
        stderr: exception.message,
      );
    }

    var sawFirstLine = false;
    final parser = ClaudeStreamJsonParser(
      ClaudeStreamJsonCallbacks(
        onText: (delta) {
          onText(delta);
          onFirstModelEvent();
        },
        onThinking: (_) => onFirstModelEvent(),
        onToolCall: onToolCall,
        onToolResult: onToolResult,
        onUsage: onUsage,
        onCompactBoundary: (_) => onCompact(),
        onInit: onInit,
        onApiRetry: (_) => onApiRetry(),
        onError: onError,
        onTerminalError: (terminal) => onSdkError(terminal.message),
      ),
    );

    final stderrBuffer = StringBuffer();
    final stderrDone = process.stderr
        .transform(utf8.decoder)
        .listen(stderrBuffer.write)
        .asFuture<void>();
    final linesDone = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          if (line.trim().isEmpty) {
            return;
          }
          // CLI stdout is process output, not the provider's transport byte.
          if (!sawFirstLine) {
            sawFirstLine = true;
            onTransportByte();
          }
          try {
            final decoded = jsonDecode(line);
            if (decoded is Map<String, dynamic>) {
              parser.process(decoded);
            }
          } on FormatException {
            // A non-JSON line is CLI noise, not a protocol event.
          }
        })
        .asFuture<void>();

    process.stdin.write(_userLine(prompt));
    await process.stdin.flush();
    await process.stdin.close();

    var timedOut = false;
    int exitCode;
    try {
      exitCode = await process.exitCode.timeout(
        turnTimeout,
        onTimeout: () {
          timedOut = true;
          process.kill(ProcessSignal.sigkill);
          return process.exitCode;
        },
      );
    } finally {
      await linesDone.catchError((_) {});
      await stderrDone.catchError((_) {});
    }
    return _TurnOutcome(
      exitCode: exitCode,
      timedOut: timedOut,
      stderr: stderrBuffer.toString(),
    );
  }

  /// One stream-json user message, the shape `claude -p --input-format
  /// stream-json` reads from stdin.
  static String _userLine(String text) =>
      '${jsonEncode({
        'type': 'user',
        'message': {'role': 'user', 'content': text},
      })}\n';

  /// Drops a provider prefix (`anthropic/claude-opus-4-8` →
  /// `claude-opus-4-8`): the CLI resolves model ALIASES, not qualified ids.
  static String? _bareModel(String modelId) {
    final slash = modelId.indexOf('/');
    if (slash == -1) {
      return modelId.isEmpty ? null : modelId;
    }
    final bare = modelId.substring(slash + 1);
    return bare.isEmpty ? null : bare;
  }

  static String _surfaceHash(List<String> tools) {
    final sorted = [...tools]..sort();
    return canonicalHash(sorted);
  }

  static String _describeMcp(ClaudeInitMetadata init) {
    if (init.mcpServers.isEmpty && init.mcpServerErrors.isEmpty) {
      return 'no MCP servers configured';
    }
    final connected = [
      for (final server in init.mcpServers)
        if (server.isConnected) server.name,
    ];
    return 'MCP servers: ${init.mcpServers.length} '
        '(${connected.length} connected)'
        '${init.mcpServerErrors.isEmpty ? '' : ', '
                  '${init.mcpServerErrors.length} skipped: '
                  '${init.mcpServerErrors.map((e) => e.name).join(', ')}'}';
  }

  static String? _targetOf(String toolName, Object? input) {
    if (input is! Map) {
      return null;
    }
    final kind = EvaluationToolKind.of(toolName);
    switch (kind) {
      case EvaluationToolKind.read:
      case EvaluationToolKind.edit:
      case EvaluationToolKind.patch:
      case EvaluationToolKind.find:
        final path = input['file_path'] ?? input['path'] ?? input['pattern'];
        return path is String ? path : null;
      case EvaluationToolKind.search:
        final pattern = input['pattern'] ?? input['query'];
        return pattern is String ? pattern : null;
      case EvaluationToolKind.exec:
        final command = input['command'];
        if (command is! String) {
          return null;
        }
        return command.trim().split(RegExp(r'\s+')).first;
      case EvaluationToolKind.other:
        return null;
    }
  }

  static String _excerpt(String value, {int max = 300}) {
    final trimmed = value.trim().replaceAll('\n', ' ');
    if (trimmed.length <= max) {
      return trimmed;
    }
    return '…${trimmed.substring(trimmed.length - max)}';
  }
}

/// What one turn produced, for the fresh arm's conversation reconstruction.
class _TurnTrace {
  _TurnTrace.empty();

  /// User-visible assistant text.
  final StringBuffer assistantText = StringBuffer();

  /// Tool activity lines (`read → ok: …`, `called bash`).
  final List<String> toolLines = [];
}

class _TurnOutcome {
  const _TurnOutcome({
    required this.exitCode,
    required this.timedOut,
    required this.stderr,
  });

  final int exitCode;
  final bool timedOut;
  final String stderr;
}
