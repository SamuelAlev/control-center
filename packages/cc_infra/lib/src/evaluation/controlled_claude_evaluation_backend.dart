import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/evals/domain/evaluation/evaluation_attempt.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_backend_port.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_plan.dart';
import 'package:cc_domain/features/evals/domain/value_objects/agent_config_hash.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_infra/src/dispatch/backends/cli_backends.dart';
import 'package:cc_infra/src/evaluation/controlled_claude_mcp_bridge.dart';
import 'package:cc_infra/src/sandboxing/claude_stream_json.dart';
import 'package:path/path.dart' as p;

/// Uses Claude Code's own model/tool loop, but delegates every tool to the
/// controlled guest boundary. Claude and its account stay on the trusted host.
class ControlledClaudeEvaluationBackend implements EvaluationBackendPort {
  ControlledClaudeEvaluationBackend({
    required this.executable,
    required this.configDir,
    required this.cancellation,
    required this.budgetMicros,
    required this.systemPrompt,
    required this.visibleSkillHashes,
    this.visibleSkillFiles = const {},
    required this.commandGuard,
    this.capabilities = ClaudeCliCapabilities.baseline,
    this.localApiEndpointForTesting,
  }) {
    final endpoint = localApiEndpointForTesting;
    if (endpoint != null &&
        (endpoint.scheme != 'http' ||
            (endpoint.host != '127.0.0.1' && endpoint.host != '::1') ||
            endpoint.port == 0 ||
            endpoint.userInfo.isNotEmpty)) {
      throw ArgumentError.value(
        endpoint,
        'localApiEndpointForTesting',
        'must be a local HTTP mock API endpoint',
      );
    }
  }

  final String executable;
  final String configDir;
  final CancellationToken cancellation;
  final int budgetMicros;
  final String systemPrompt;
  final Map<String, String> visibleSkillHashes;
  final Map<String, Set<String>> visibleSkillFiles;
  final Future<String?> Function(String command)? commandGuard;
  final ClaudeCliCapabilities capabilities;

  /// Explicit offline development seam, never wired by production campaigns.
  /// Uses a literal fake API key and ONLY a loopback endpoint.
  final Uri? localApiEndpointForTesting;

  @override
  String get id => 'claude-cli';
  @override
  bool get callsModel => true;
  @override
  String? unsupportedReason(EvaluationEffectiveConfig effective) =>
      effective.adapter != id || effective.skillExposure == null
      ? 'controlled Claude skill exposure is required'
      : effective.memoryPolicy != MemoryPolicyMode.textCurrent ||
            effective.toolOverlap != ToolOverlapMode.serial
      ? 'native Claude does not implement harness memory or overlapping tools'
      : null;

  static String _pathFor(String executable) => [
    p.dirname(executable),
    '/opt/homebrew/bin',
    '/usr/local/bin',
    '/usr/bin',
    '/bin',
  ].toSet().join(':');

  static Future<({int code, String text})> _probe(
    String executable,
    String configDir,
    String flag,
  ) async {
    final process = await Process.start(
      executable,
      [flag],
      environment: {
        'PATH': _pathFor(executable),
        'CLAUDE_CONFIG_DIR': configDir,
      },
      includeParentEnvironment: false,
    );
    final text = StringBuffer();
    var length = 0;
    var overflow = false;
    final output = process.stdout.listen((chunk) {
      length += chunk.length;
      if (length > 64 * 1024) {
        overflow = true;
        process.kill(ProcessSignal.sigkill);
      } else {
        text.write(utf8.decode(chunk, allowMalformed: true));
      }
    }).asFuture<void>();
    final errors = process.stderr.drain<void>();
    final deadline = Timer(
      const Duration(seconds: 8),
      () => process.kill(ProcessSignal.sigkill),
    );
    try {
      await process.stdin.close();
      final code = await process.exitCode;
      await output;
      await errors;
      return (code: overflow ? -1 : code, text: text.toString());
    } finally {
      deadline.cancel();
      process.kill(ProcessSignal.sigkill);
    }
  }

  /// Resolves the actual native build for a reproducibility pin, without a call.
  static Future<String?> probeVersion({
    required String executable,
    required String configDir,
  }) async {
    final result = await _probe(executable, configDir, '--version');
    return result.code == 0
        ? ClaudeCliCapabilities.versionOf(result.text)
        : null;
  }

  /// Offline CLI flag probe; no model call or credential contents are read.
  static Future<String?> capabilityReason({
    required String executable,
    required String configDir,
  }) async {
    if (!p.isAbsolute(executable) || !File(executable).existsSync()) {
      return 'a server-owned absolute Claude executable is required';
    }
    if (!p.isAbsolute(configDir) || !Directory(configDir).existsSync()) {
      return 'an active server-owned Claude account directory is required';
    }
    try {
      if (await probeVersion(executable: executable, configDir: configDir) ==
          null) {
        return 'Claude version could not be verified';
      }
      final help = await _probe(executable, configDir, '--help');
      if (help.code != 0) return 'Claude help could not be verified';
      final text = help.text;
      for (final flag in [
        '--tools',
        '--strict-mcp-config',
        '--setting-sources',
        '--disable-slash-commands',
        '--system-prompt',
        '--permission-mode',
        '--no-session-persistence',
        '--max-budget-usd',
        '--mcp-config',
        '--input-format',
        '--output-format',
        '--model',
        '--allowedTools',
      ]) {
        if (!text.contains(flag)) return 'Claude lacks required $flag';
      }
      return null;
    } on Object catch (error) {
      return 'Claude capability probe failed: $error';
    }
  }

  static bool _isolatedInit(Map<String, dynamic> init) {
    final plugins = init['plugins'];
    final skills = init['skills'];
    final commands = init['slash_commands'];
    if (plugins is! List ||
        skills is! List ||
        skills.isNotEmpty ||
        commands is! List ||
        commands.isNotEmpty) {
      return false;
    }
    const allowed = {'cc-plugin-agents-md', 'cc-plugin-plugin-authoring'};
    final names = <String>{};
    for (final plugin in plugins) {
      if (plugin is! Map ||
          plugin['name'] is! String ||
          !allowed.contains(plugin['name']) ||
          plugin['path'] != 'builtin' ||
          plugin['source'] != '${plugin['name']}@builtin' ||
          !names.add(plugin['name'] as String)) {
        return false;
      }
    }
    return true;
  }

  @override
  Future<EvaluationAttempt> execute(EvaluationAttemptRequest request) async {
    final started = DateTime.now().millisecondsSinceEpoch;
    final timer = Stopwatch()..start();
    final attemptSource = CancellationTokenSource();
    final attemptCancellation = CancellationToken.any([
      cancellation,
      attemptSource.token,
    ]);
    final bridge = ControlledClaudeMcpBridge(
      root: request.workspaceRoot,
      cancellation: attemptCancellation,
      visibleSkillHashes: visibleSkillHashes,
      visibleSkillFiles: visibleSkillFiles,
      commandGuard: commandGuard,
    );
    Directory? controller;
    var tokens = const EvaluationTokenBreakdown();
    var costMicros = 0;
    var costUnknown = false;
    var requests = 0;
    var completed = false;
    var compactions = 0;
    var retries = 0;
    String? error;
    String? servedModel;
    String? cliVersion;
    String? toolSurfaceHash;
    int? initMs;
    int? firstModelMs;
    int? firstTextMs;
    try {
      controller = await Directory.systemTemp.createTemp(
        'cc-claude-controller-',
      );
      final home = await Directory(p.join(controller.path, 'home')).create();
      await bridge.start();
      final config = File(p.join(controller.path, 'mcp.json'));
      await config.writeAsString(
        jsonEncode({
          'mcpServers': {
            'cc_controlled': {
              'type': 'http',
              'url': bridge.url,
              'headers': {'Authorization': 'Bearer ${bridge.token}'},
            },
          },
        }),
      );
      final turns = [request.task.prompt, ...request.task.followUps];
      final history = StringBuffer();
      for (final turn in turns) {
        if (cancellation.isCancelled ||
            costUnknown ||
            costMicros >= budgetMicros) {
          error =
              'Evaluation cancelled, budget spent or accounting unavailable';
          break;
        }
        // A new native session per turn prevents native history from crossing
        // independent attempts and removes resume-baseline ambiguity.
        final ledger = ClaudeAccountingLedger();
        final trace = StringBuffer();
        final budget = (budgetMicros - costMicros) / 1000000;
        final args = <String>[
          '-p',
          '--input-format',
          'stream-json',
          '--output-format',
          'stream-json',
          '--verbose',
          '--include-partial-messages',
          '--model',
          request.effective.modelId.startsWith(
                '${request.effective.providerId}/',
              )
              ? request.effective.modelId.substring(
                  request.effective.providerId.length + 1,
                )
              : request.effective.modelId,
          '--tools',
          '',
          '--mcp-config',
          config.path,
          '--strict-mcp-config',
          '--allowedTools',
          bridge.toolCatalog.map((e) => e.first).join(','),
          '--setting-sources',
          '',
          '--disable-slash-commands',
          '--system-prompt',
          systemPrompt,
          '--permission-mode',
          'dontAsk',
          '--no-session-persistence',
          '--max-budget-usd',
          budget.toStringAsFixed(6),
          '--max-turns',
          '${(request.task.maxTurns ?? 100).clamp(1, 100)}',
        ];
        final effort = ClaudeCliBackend.claudeEffortValue(
          request.effective.effortLevel,
          capabilities,
        );
        if (effort != null) args.addAll(['--effort', effort]);
        var receivedResult = false;
        var receivedInit = false;
        var unsafeSurface = false;
        final parser = ClaudeStreamJsonParser(
          ClaudeStreamJsonCallbacks(
            onInit: (init) {
              receivedInit = true;
              initMs ??= timer.elapsedMilliseconds;
              servedModel = init.model;
              cliVersion = init.claudeCodeVersion;
              toolSurfaceHash = canonicalHash([...init.tools]..sort());
              final expected = {
                for (final item in bridge.toolCatalog) item.first,
              };
              if (init.model == null ||
                  init.model!.isEmpty ||
                  init.claudeCodeVersion == null ||
                  (request.manifest.cliVersion != null &&
                      init.claudeCodeVersion != request.manifest.cliVersion) ||
                  (init.cwd != null &&
                      p.normalize(init.cwd!) !=
                          p.normalize(
                            controller!.resolveSymbolicLinksSync(),
                          )) ||
                  (init.permissionMode != null &&
                      init.permissionMode != 'dontAsk') ||
                  init.mcpServerErrors.isNotEmpty ||
                  !init.mcpServers.any(
                    (s) => s.name == 'cc_controlled' && s.isConnected,
                  ) ||
                  init.tools.toSet().length != expected.length ||
                  !init.tools.toSet().containsAll(expected) ||
                  init.pluginErrors.isNotEmpty) {
                unsafeSurface = true;
              }
            },
            onText: (text) {
              firstModelMs ??= timer.elapsedMilliseconds;
              if (text.trim().isNotEmpty)
                firstTextMs ??= timer.elapsedMilliseconds;
              if (trace.length < 128 * 1024) trace.write(text);
            },
            onThinking: (_) => firstModelMs ??= timer.elapsedMilliseconds,
            onToolCall: (_) => firstModelMs ??= timer.elapsedMilliseconds,
            onUsage: (usage) {
              receivedResult = true;
              final accounted = ledger.record(usage);
              requests += usage.numTurns ?? 1;
              costMicros += accounted.costDeltaMicros;
              // A model turn with zero API-equivalent charge cannot establish
              // trustworthy positive list pricing; never call it free.
              costUnknown =
                  costUnknown ||
                  accounted.costUnavailable ||
                  accounted.costDeltaMicros <= 0;
              tokens =
                  tokens +
                  EvaluationTokenBreakdown(
                    uncachedInput: accounted.tokenDelta.inputTokens,
                    cacheWrite: accounted.tokenDelta.cacheWriteTokens,
                    cacheRead: accounted.tokenDelta.cacheReadTokens,
                    output: accounted.tokenDelta.outputTokens,
                  );
              if (usage.subtype != 'success')
                error ??= 'Claude result ${usage.subtype}';
            },
            onCompactBoundary: (_) => compactions++,
            onApiRetry: (_) => retries++,
            onError: (message) => error ??= message,
            onTerminalError: (terminal) => error ??= terminal.message,
          ),
        );
        final prompt = '$history\nuser: $turn';
        final outcome = await _runTurn(
          args: args,
          prompt: prompt,
          cwd: controller.path,
          home: home.path,
          parser: parser,
          shouldStop: () => unsafeSurface,
          attemptCancellation: attemptCancellation,
          stopAttempt: attemptSource.cancel,
          onInitEvent: (raw) {
            if (!_isolatedInit(raw)) unsafeSurface = true;
          },
        );
        if (!receivedResult) costUnknown = true;
        if (!receivedInit ||
            unsafeSurface ||
            outcome != null ||
            !receivedResult ||
            costUnknown ||
            error != null) {
          error ??= unsafeSurface
              ? 'Claude tool surface/model or MCP differs from controlled pin'
              : outcome ?? 'Claude did not provide verifiable final accounting';
          break;
        }
        history
          ..writeln('user: $turn')
          ..writeln('assistant: ${trace.toString()}');
        completed = true;
      }
    } on Object catch (exception) {
      error = '$exception';
      costUnknown = true;
    } finally {
      attemptSource.cancel();
      await bridge.close();
      if (controller != null) await controller.delete(recursive: true);
      timer.stop();
    }
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
      startedAtEpochMs: started,
      executionMode: request.executionMode,
      servedModel: servedModel,
      observedCliVersion: cliVersion,
      observedToolSurfaceHash: toolSurfaceHash,
      completed: completed && error == null && !cancellation.isCancelled,
      error: error,
      tokens: tokens,
      cost: costUnknown
          ? const EvaluationCostRoles()
          : EvaluationCostRoles(estimatedApiMicros: costMicros),
      latency: EvaluationLatency(
        firstModelEventMs: firstModelMs,
        firstUsefulTextMs: firstTextMs,
        totalMs: timer.elapsedMilliseconds,
      ),
      metrics: EvaluationAttemptMetrics.fromToolEvents(
        bridge.toolEvents,
        modelRoundTrips: requests,
        userTurns: request.task.followUps.length + 1,
        providerRetries: retries,
        compactions: compactions,
        initMetadataMs: initMs,
      ),
      toolEvents: bridge.toolEvents,
      skillEvents: bridge.skillEvents,
      verification: const [],
      filesTouched: const [],
      notes:
          'claude-cli; server account; native max-budget-usd stops after a '
          'completed call, so one in-flight call can overshoot; API-equivalent '
          'estimated cost, not billed spend; no host native tools',
    );
  }

  Future<String?> _runTurn({
    required List<String> args,
    required String prompt,
    required String cwd,
    required String home,
    required ClaudeStreamJsonParser parser,
    required bool Function() shouldStop,
    required CancellationToken attemptCancellation,
    required void Function() stopAttempt,
    required void Function(Map<String, dynamic>) onInitEvent,
  }) async {
    final process = await Process.start(
      executable,
      args,
      workingDirectory: cwd,
      environment: {
        'PATH': _pathFor(executable),
        'HOME': home,
        'CLAUDE_CONFIG_DIR': configDir,
        'MCP_DISCOVERY_CACHE': '0',
        if (localApiEndpointForTesting != null)
          'ANTHROPIC_BASE_URL': localApiEndpointForTesting!.toString(),
        if (localApiEndpointForTesting != null)
          'ANTHROPIC_API_KEY': 'cc-offline-test-not-a-real-key',
        if (localApiEndpointForTesting != null)
          'CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC': '1',
      },
      includeParentEnvironment: false,
    );
    final stderr = StringBuffer();
    var bytes = 0;
    var stopped = false;
    var finished = false;
    void stop() {
      if (finished || stopped) return;
      stopped = true;
      stopAttempt();
      process.kill(ProcessSignal.sigkill);
    }

    final deadline = Timer(const Duration(minutes: 15), stop);
    unawaited(attemptCancellation.whenCancelled.then((_) => stop()));
    final stdoutDone = process.stdout
        .transform(
          StreamTransformer<List<int>, List<int>>.fromHandlers(
            handleData: (chunk, sink) {
              bytes += chunk.length;
              if (bytes > 4 * 1024 * 1024) {
                stop();
              } else {
                sink.add(chunk);
              }
            },
          ),
        )
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          if (shouldStop()) {
            stop();
            return;
          }
          try {
            final event = jsonDecode(line);
            if (event is Map<String, dynamic>) {
              if (event['type'] == 'system' && event['subtype'] == 'init') {
                onInitEvent(event);
              }
              parser.process(event);
            }
          } on FormatException {
            stop();
          }
        })
        .asFuture<void>();
    final stderrDone = process.stderr.transform(utf8.decoder).listen((data) {
      if (stderr.length < 8192)
        stderr.write(
          data.substring(0, (8192 - stderr.length).clamp(0, data.length)),
        );
    }).asFuture<void>();
    try {
      process.stdin.write(
        '${jsonEncode({
          'type': 'user',
          'message': {'role': 'user', 'content': prompt},
        })}\n',
      );
      await process.stdin.flush();
      await process.stdin.close();
      final exit = await process.exitCode;
      if (stopped)
        return 'Claude cancelled, exceeded time/output limit or invalid stream';
      if (exit != 0) return 'Claude exited $exit: ${stderr.toString()}';
      return null;
    } finally {
      finished = true;
      deadline.cancel();
      await process.exitCode;
      await stdoutDone.catchError((_) {});
      await stderrDone.catchError((_) {});
    }
  }
}
