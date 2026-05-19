import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:control_center/core/domain/entities/agent_run_log.dart';
import 'package:control_center/core/domain/events/agent_events.dart';
import 'package:control_center/core/domain/events/domain_event_bus.dart';
import 'package:control_center/core/domain/ports/credential_broker_port.dart';
import 'package:control_center/core/domain/ports/sandbox_port.dart';
import 'package:control_center/core/domain/repositories/agent_repository.dart';
import 'package:control_center/core/domain/repositories/agent_run_log_repository.dart';
import 'package:control_center/core/domain/value_objects/agent_capabilities.dart';
import 'package:control_center/core/domain/value_objects/conversation_mode.dart';
import 'package:control_center/core/domain/value_objects/sandbox_event.dart';
import 'package:control_center/core/domain/value_objects/sandbox_handle.dart';
import 'package:control_center/core/domain/value_objects/sandbox_spec.dart';
import 'package:control_center/core/domain/value_objects/wake_context.dart';
import 'package:control_center/core/infrastructure/process/binary_resolver.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:control_center/features/sandboxing/data/claude_relay/claude_relay.dart';
import 'package:control_center/features/sandboxing/data/services/run_log_writer.dart';

/// Shared dependencies for a [DispatchSession].
class SandboxDispatchDeps {
  /// Creates [SandboxDispatchDeps].
  SandboxDispatchDeps({
    required this.sandbox,
    required this.broker,
    required this.agentRepo,
    required this.runLogRepo,
    required this.defaultCaps,
    required this.eventBus,
    this.claudeRelayFactory = ClaudeRelay.new,
  });

  /// OS-level sandbox used to run sandboxed CLI adapters (e.g. Pi).
  final SandboxPort sandbox;

  /// Credential broker that mints per-run scoped tokens.
  final CredentialBrokerPort broker;

  /// Agent repository (capability lookup).
  final AgentRepository agentRepo;

  /// Optional run-log repository.
  final AgentRunLogRepository? runLogRepo;

  /// Default capabilities when an agent has none.
  final AgentCapabilities defaultCaps;

  /// Optional domain event bus.
  final DomainEventBus? eventBus;

  /// Factory for the Claude Code subscription relay (the claude-relay port). Used
  /// when the resolved adapter's CLI is `claude` — that path NEVER uses
  /// metered `claude -p`. Overridable for tests.
  final ClaudeRelay Function() claudeRelayFactory;
}

/// A session that dispatches and manages a single sandboxed agent run.
class DispatchSession {
  /// Creates a [DispatchSession] for launching and monitoring a sandboxed
  /// agent process.
  DispatchSession({
    required this.deps,
    required this.onResolveHandle,
    required this.onScheduleCooldown,
    required this.dispatchId,
    required this.cliName,
    required this.prompt,
    required this.agentDirHostPath,
    required this.modelId,
    required this.callerEnv,
    required this.agentId,
    required this.workspaceId,
    required this.conversationId,
    required this.runLogId,
    required this.mode,
    this.ticketId,
    this.wakeContext,
  });

  /// Shared sandbox and credential dependencies.
  final SandboxDispatchDeps deps;

  /// Resolves a sandbox handle for the session.
  final Future<SandboxHandle> Function({
    required String sessionId,
    required SandboxSpec spec,
    required void Function(AgentProcessEvent) emit,
  }) onResolveHandle;

  /// Called to schedule a cooldown period after the session ends.
  final void Function(String sessionId) onScheduleCooldown;

  /// Unique identifier for this dispatch.
  final String dispatchId;
  /// CLI binary name (e.g. `pi` or `claude`).
  final String cliName;
  /// Prompt text sent to the agent.
  final String prompt;
  /// Host-side path to the agent's working directory.
  final String agentDirHostPath;
  /// Optional model identifier to pass to the CLI.
  final String? modelId;
  /// Environment variables from the calling context.
  final Map<String, String> callerEnv;
  /// Optional agent identifier for capability lookup.
  final String? agentId;
  /// Optional workspace identifier.
  final String? workspaceId;
  /// Optional conversation identifier for scoped credential minting.
  final String? conversationId;
  /// Optional run-log identifier for persistent logging.
  final String? runLogId;
  /// Conversation mode (e.g. `plan` or `execute`).
  final ConversationMode mode;
  /// Optional ticketing system ticket identifier.
  final String? ticketId;
  /// Optional wake context for agent resumption.
  final WakeContext? wakeContext;

  /// Stream controller for [AgentProcessEvent]s emitted by this session.
  final StreamController<AgentProcessEvent> controller =
      StreamController<AgentProcessEvent>();
  /// Handle to the scoped credential minted for this run.
  String? credHandle;
  /// Subscription to sandbox events from the underlying process.
  StreamSubscription<SandboxEvent>? eventsSub;
  /// Whether a [DoneEvent] has been emitted.
  bool emittedDone = false;
  /// PID of the forked sandbox process, set once available.
  int? pid;

  /// Active Claude subscription relay, when [cliName] is `claude`. Held so the
  /// session can tear it down on terminate / silence timeout.
  ClaudeRelay? _claudeRelay;

  /// Timestamp of the most recent output from the agent.
  DateTime? lastOutputAt;
  /// Periodic timer that checks for silence and terminates if exceeded.
  Timer? silenceTimer;
  /// Interval between silence checks.
  static const Duration silenceCheckInterval = Duration(seconds: 30);
  /// Duration of silence after which the session is terminated.
  static const Duration defaultSilenceThreshold = Duration(minutes: 15);

  final RunLogWriter _logWriter = RunLogWriter();

  /// Prefix used when constructing sandbox session identifiers.
  static const String agentSessionPrefix = 'agent-';

  static const String _jsonModeConstraint =
      'Output structured JSON events. Each line must be a valid JSON object.';

  /// Builds the argv for the Pi CLI. [executablePath] is argv[0] — the
  /// absolute path resolved via [resolveBinaryPath], NOT the bare `pi` name.
  /// A bundled `.app` / `.desktop` launch inherits a minimal PATH (no
  /// Homebrew/Nix), so the bare name fails with "pi: command not found"
  /// (exit 127) once `sandbox-exec`'s inner `/bin/bash -c` tries to resolve it.
  static List<String> buildArgv(
    String cliName,
    String executablePath,
    String? modelId,
  ) {
    if (cliName != 'pi') {
      throw ArgumentError(
        'Unsupported CLI "$cliName" — only "pi" is supported.',
      );
    }
    final args = <String>[executablePath, '--mode', 'json'];
    if (modelId != null && modelId.isNotEmpty) {
      args.addAll(['--model', modelId]);
    }
    args.addAll(['--append-system-prompt', _jsonModeConstraint]);
    return args;
  }

  /// Translates capabilities into environment variables for the sandboxed
  /// process (e.g. disabling git push when not permitted).
  static Map<String, String> capabilityEnv(AgentCapabilities caps) {
    final env = <String, String>{};
    if (!caps.canPushToRepo) {
      env['GIT_ASKPASS'] = '/usr/bin/false';
      env['GIT_TERMINAL_PROMPT'] = '0';
    }
    return env;
  }

  /// Starts the sandboxed agent process and manages its lifecycle.

  Future<void> run() async {
    try {
      final caps = await _capabilitiesFor(agentId);

      final scoped = await deps.broker.mint(
        conversationId: conversationId ?? 'unknown',
        capabilities: caps,
      );
      credHandle = scoped.handle;

      final wsId = workspaceId ?? '';
      final agentKey =
          (agentId != null && agentId!.isNotEmpty) ? agentId! : 'oneshot';
      final convKey = conversationId ?? 'no-conv';
      final sandboxSessionId =
          '$agentSessionPrefix$agentKey::$convKey::${mode.name}';

      if (mode == ConversationMode.plan) {
        try {
          Directory('$agentDirHostPath/plans').createSync(recursive: true);
        } catch (_) {
          AppLog.w('DispatchSession', 'Failed to create plans directory');
        }
      }

      await _openRunLog(caps: caps);

      // Claude Code runs through the in-app claude-relay (PTY +
      // loopback Anthropic proxy) instead of the OS sandbox — it must NEVER use
      // metered `claude -p`. See features/sandboxing/data/claude_relay/.
      if (cliName == 'claude') {
        await _runClaudeRelay(
          caps: caps,
          scopedEnv: scoped.environment,
          scopedNotes: scoped.notes,
        );
        return;
      }

      // Resolve the CLI to its absolute path on the host. A bundled `.app` /
      // `.desktop` launch inherits a minimal PATH (no Homebrew/Nix/user
      // prefixes), so the bare name would fail with exit 127 once
      // `sandbox-exec`'s inner `/bin/bash -c` tried to resolve it. This is the
      // same probe Settings → Adapters uses to display the path.
      final cliPath = await resolveBinaryPath(cliName);
      if (cliPath == null) {
        addEvent(ErrorEvent(
          content: '[sandbox] "$cliName" not found. Install it on your host '
              'or check Settings → Adapters for the detected path.',
        ));
        unawaited(_closeRunLog(exitCode: 127));
        addEvent(DoneEvent());
        _completeRun();
        return;
      }

      final handle = await onResolveHandle(
        sessionId: sandboxSessionId,
        spec: SandboxSpec(
          sessionId: sandboxSessionId,
          workspaceId: wsId,
          agentId: agentId,
          bindMounts: [
            SandboxBindMount(
              hostPath: agentDirHostPath,
              guestPath: agentDirHostPath,
            ),
          ],
          guestWorkdir: agentDirHostPath,
          networkEnabled: caps.canAccessNetwork,
          mode: mode,
        ),
        emit: addEvent,
      );

      if (handle.state == SandboxState.error) {
        throw StateError('sandbox launch failed: ${handle.error}');
      }

      for (final note in scoped.notes) {
        addEvent(DebugEvent(
          content: '[sandbox] $note',
        ));
      }

      eventsSub = deps.sandbox.events(handle).listen(_forwardSandboxEvent);

      final argv = buildArgv(cliName, cliPath, modelId);
      final mergedEnv = <String, String>{
        ...callerEnv,
        ...scoped.environment,
        ...capabilityEnv(caps),
        if (wakeContext != null) ...wakeContext!.toEnvironment(),
        'CC_DISABLE_PROJECT_CONFIG': 'true',
        'OPENCODE_DISABLE_PROJECT_CONFIG': 'true',
      };

      addEvent(DebugEvent(
        content: '[sandbox] launching $cliName…',
      ));
      final exitCode = await deps.sandbox.exec(
        handle,
        argv,
        env: mergedEnv,
        onPid: (forkedPid) {
          _onPidAvailable(forkedPid);
          addEvent(DebugEvent(
            content: '[sandbox] $cliName running (pid $forkedPid)',
          ));
        },
        stdinInput: prompt,
      );
      unawaited(_closeRunLog(exitCode: exitCode));

      if (exitCode == 127) {
        addEvent(ErrorEvent(
          content:
              '[sandbox] "$cliName" not found on PATH. Install it on your '
              'host or disable sandboxing in Settings → Sandboxing.',
        ));
      } else if (exitCode != 0) {
        addEvent(ErrorEvent(
          content: '[sandbox] $cliName exited with code $exitCode',
        ));
      } else {
        addEvent(DebugEvent(
          content: '[sandbox] $cliName exited cleanly (code 0)',
        ));
      }
      _completeRun();
      onScheduleCooldown(sandboxSessionId);
    } on Object catch (e) {
      unawaited(_closeRunLog(error: e));
      addEvent(ErrorEvent(
        content: '[sandbox] dispatch failed: $e',
      ));
      _closeController();
    }
  }

  /// Maps a [ConversationMode] to Claude Code's `--permission-mode`. `plan`
  /// keeps Claude in read-only/plan mode; `review` borrows it (Claude has no
  /// pure read-only flag, and plan mode blocks edits); `chat` uses the default.
  static String? _claudePermissionMode(ConversationMode mode) {
    switch (mode) {
      case ConversationMode.plan:
      case ConversationMode.review:
        return 'plan';
      case ConversationMode.chat:
        return null;
    }
  }

  /// Runs Claude Code through the claude-relay, translating its
  /// structured events into [AgentProcessEvent]s. Never uses `claude -p`.
  Future<void> _runClaudeRelay({
    required AgentCapabilities caps,
    required Map<String, String> scopedEnv,
    required List<String> scopedNotes,
  }) async {
    for (final note in scopedNotes) {
      addEvent(DebugEvent(
        content: '[claude-relay] $note',
      ));
    }

    final claudePath = await resolveBinaryPath('claude');
    if (claudePath == null) {
      addEvent(ErrorEvent(
        content: '[claude-relay] "claude" not found on PATH. Install Claude Code: '
            'https://docs.anthropic.com/en/docs/claude-code',
      ));
      unawaited(_closeRunLog(exitCode: 127));
      addEvent(DoneEvent());
      _completeRun();
      return;
    }

    final args = ClaudeRelay.buildClaudeArgs(
      modelId: modelId,
      permissionMode: _claudePermissionMode(mode),
    );
    final env = <String, String>{
      ...callerEnv,
      ...scopedEnv,
      ...capabilityEnv(caps),
      if (wakeContext != null) ...wakeContext!.toEnvironment(),
      'CC_DISABLE_PROJECT_CONFIG': 'true',
    };

    addEvent(DebugEvent(
      content: '[claude-relay] launching claude via subscription relay…',
    ));

    final relay = deps.claudeRelayFactory();
    _claudeRelay = relay;
    final exitCode = await relay.run(
      claudePath: claudePath,
      args: args,
      prompt: prompt,
      environment: env,
      workingDirectory: agentDirHostPath,
      callbacks: ClaudeRelayCallbacks(
        onText: (delta) => addEvent(TextEvent(
          content: delta,
        )),
        onThinking: (delta) => addEvent(ThinkingEvent(
          content: delta,
        )),
        onToolCall: (tu) => addEvent(ToolCallEvent(
          toolName: tu.name,
          toolCallId: tu.id,
          inputs: tu.input as Map<String, dynamic>?,
        )),
        onToolResult: (tr) => addEvent(ToolResultEvent(
          toolCallId: tr.toolUseId,
          outputs: tr.content,
          isError: tr.isError,
        )),
        onError: (m) => addEvent(ErrorEvent(
          content: m,
        )),
        onDebug: (m) => addEvent(DebugEvent(
          content: m,
        )),
        onPid: _onPidAvailable,
        onStatus: (status, waitingFor) {},
      ),
    );
    _claudeRelay = null;
    unawaited(_closeRunLog(exitCode: exitCode));

    // 143 = relay torn down by user request / silence watchdog; not an error.
    if (exitCode != 0 && exitCode != 143) {
      addEvent(ErrorEvent(
        content: '[claude-relay] claude relay exited with code $exitCode',
      ));
    } else {
      addEvent(DebugEvent(
        content: '[claude-relay] claude relay finished (code $exitCode)',
      ));
    }
    addEvent(DoneEvent());
    _completeRun();
  }

  /// Gracefully stops the session by shutting down the relay, revoking
  /// credentials, and closing the event controller.
  Future<void> stop() async {
    _cancelSilenceWatchdog();
    unawaited(_claudeRelay?.shutdown());
    _claudeRelay = null;
    final cred = credHandle;
    if (cred != null) {
      await deps.broker.revoke(cred);
      credHandle = null;
    }
    _closeController();
  }

  /// Forcefully terminates the session by stopping the relay, marking the
  /// run as failed, revoking credentials, cancelling event subscriptions,
  /// and closing the controller.
  Future<void> terminate() async {
    _cancelSilenceWatchdog();
    unawaited(_claudeRelay?.shutdown());
    _claudeRelay = null;
    addEvent(DebugEvent(
      content: '[sandbox] dispatch $dispatchId terminated by request',
    ));
    _failRun('Terminated by user request');
    final cred = credHandle;
    if (cred != null) {
      await deps.broker.revoke(cred);
      credHandle = null;
    }
    unawaited(eventsSub?.cancel());
    eventsSub = null;
    _closeController();
  }

  void _cancelSilenceWatchdog() {
    silenceTimer?.cancel();
    silenceTimer = null;
  }

  void _startSilenceWatchdog() {
    _cancelSilenceWatchdog();
    silenceTimer = Timer.periodic(silenceCheckInterval, (_) {
      final last = lastOutputAt;
      if (last != null &&
          DateTime.now().difference(last) >= defaultSilenceThreshold) {
        _cancelSilenceWatchdog();
        addEvent(ErrorEvent(
          content: '[sandbox] Agent silent for '
              '${defaultSilenceThreshold.inMinutes} min — terminating',
        ));
        unawaited(_claudeRelay?.shutdown());
        _claudeRelay = null;
        _failRun('Silent run (no output for '
            '${defaultSilenceThreshold.inMinutes} min)');
      }
    });
  }

  void _forwardSandboxEvent(SandboxEvent event) {
    switch (event.type) {
      case SandboxEventType.stdout:
        _tryParseStructuredOutput(event.content);
        break;
      case SandboxEventType.stderr:
        addEvent(ErrorEvent(
          content: event.content,
        ));
        break;
      case SandboxEventType.exit:
        _completeRun();
        break;
      case SandboxEventType.killed:
        addEvent(ErrorEvent(
          content: event.content.isNotEmpty
              ? event.content
              : '[sandbox] killed',
        ));
        _completeRun();
        break;
      case SandboxEventType.starting:
        addEvent(DebugEvent(
          content: '[sandbox] booting sandbox session…',
        ));
        break;
      case SandboxEventType.ready:
        break;
      case SandboxEventType.violation:
        final v = event.violation;
        final summary = v == null
            ? '[sandbox] denied operation'
            : '[sandbox] denied ${v.action} on ${v.target}'
                '${v.suggestedCapability == null ? '' : ' '
                    '(grant ${v.suggestedCapability} to allow)'}';
        addEvent(SandboxViolationEvent(
          content: summary,
          action: v?.action,
          target: v?.target,
          suggestedCapability: v?.suggestedCapability,
        ));
        break;
    }
  }

  void _tryParseStructuredOutput(String line) {
    if (line.isEmpty) {
      return;
    }
    Map<String, dynamic>? json;
    try {
      final decoded = jsonDecode(line);
      if (decoded is Map<String, dynamic>) {
        json = decoded;
      }
    } catch (_) {
      addEvent(TextEvent(content: line));
      return;
    }
    if (json == null) {
      return;
    }
    _handlePiEvent(json);
  }

  void _handlePiEvent(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? '';
    switch (type) {
      case 'message_update':
        final assistantEvent =
            json['assistantMessageEvent'] as Map<String, dynamic>?;
        if (assistantEvent == null) {
          return;
        }
        final subType = assistantEvent['type'] as String? ?? '';
        final delta = assistantEvent['delta'] as String? ?? '';
        if (delta.isEmpty) {
          return;
        }
        if (subType == 'text_delta') {
          addEvent(TextEvent(
            content: delta,
          ));
        } else if (subType == 'thinking_delta') {
          addEvent(ThinkingEvent(
            content: delta,
          ));
        }
        break;
      case 'tool_execution_start':
        addEvent(ToolCallEvent(
          toolName: json['toolName'] as String? ?? '',
          toolCallId: json['toolCallId'] as String? ?? '',
          inputs: json['args'] as Map<String, dynamic>?,
        ));
        break;
      case 'tool_execution_update':
        final partialResult = json['partialResult'];
        if (partialResult is Map<String, dynamic>) {
          final contentList = partialResult['content'];
          if (contentList is List) {
            final text = contentList
                .whereType<Map<String, dynamic>>()
                .where((b) => b['type'] == 'text')
                .map((b) => b['text'] as String? ?? '')
                .join();
            if (text.isNotEmpty) {
              addEvent(ToolResultEvent(
                toolCallId: json['toolCallId'] as String? ?? '',
                outputs: text,
                toolName: json['toolName'] as String? ?? '',
                isPartial: true,
              ));
            }
          }
        }
        break;
      case 'tool_execution_end':
        final isError = json['isError'] as bool? ?? false;
        addEvent(ToolResultEvent(
          toolCallId: json['toolCallId'] as String? ?? '',
          outputs: json['result'] != null
              ? jsonEncode(json['result'])
              : json['toolName'] as String? ?? '',
          toolName: json['toolName'] as String? ?? '',
          isError: isError,
        ));
        break;
      case 'agent_end':
        addEvent(DoneEvent());
        break;
      default:
        break;
    }
  }

  void _completeRun() {
    if (emittedDone) {
      return;
    }
    emittedDone = true;
    _cancelSilenceWatchdog();
    if (agentId != null) {
      deps.eventBus?.publish(
        AgentRunCompleted(
          agentId: agentId!,
          workspaceId: workspaceId,
          conversationId: conversationId,
          occurredAt: DateTime.now(),
        ),
      );
    }
    final cred = credHandle;
    if (cred != null) {
      unawaited(deps.broker.revoke(cred));
      credHandle = null;
    }
    unawaited(eventsSub?.cancel());
    eventsSub = null;
    _closeController();
  }

  void _onPidAvailable(int forkedPid) {
    pid = forkedPid;
    _startSilenceWatchdog();
    _updateRunLogPidAndStart(forkedPid);
  }

  void _updateRunLogPidAndStart(int forkedPid) {
    final id = runLogId;
    final repo = deps.runLogRepo;
    if (id == null || repo == null) {
      return;
    }
    unawaited(() async {
      try {
        final existing = await repo.getById(id);
        if (existing == null) {
          _failRun('Run log $id missing when PID $forkedPid arrived');
          return;
        }
        await repo.upsert(
          existing.copyWith(
            pid: forkedPid,
            status: RunStatus.running,
          ),
        );
      } on Object catch (e, st) {
        AppLog.e(
          'DispatchSession',
          'Failed to persist PID $forkedPid for $id',
          e,
          st,
        );
        _failRun('Failed to persist PID: $e');
      }
    }());
  }

  void _updateRunLogPath(String path) {
    final id = runLogId;
    final repo = deps.runLogRepo;
    if (id == null || repo == null) {
      return;
    }
    unawaited(() async {
      try {
        final existing = await repo.getById(id);
        if (existing == null) {
          _failRun('Run log $id missing when log path arrived');
          return;
        }
        await repo.upsert(existing.copyWith(logPath: path));
      } on Object catch (e, st) {
        AppLog.e(
          'DispatchSession',
          'Failed to persist log path $path for $id',
          e,
          st,
        );
        _failRun('Failed to persist log path: $e');
      }
    }());
  }

  void _failRun(String message) {
    final id = runLogId;
    final repo = deps.runLogRepo;
    if (id != null && repo != null) {
      unawaited(() async {
        try {
          final existing = await repo.getById(id);
          if (existing != null && existing.completedAt == null) {
            await repo.upsert(
              existing.copyWith(
                status: RunStatus.error,
                summary: message,
                completedAt: DateTime.now(),
              ),
            );
          }
        } on Object catch (e, st) {
          AppLog.e(
            'DispatchSession',
            'Failed to mark run log $id as error',
            e,
            st,
          );
        }
      }());
    }
    addEvent(ErrorEvent(
      content: message,
    ));
  }

  /// Emits an [AgentProcessEvent] to the session stream, updates the last
  /// output timestamp, and logs the event for persistence.
  void addEvent(AgentProcessEvent event) {
    if (!controller.isClosed) {
      controller.add(event);
    }
    lastOutputAt = DateTime.now();
    _updateRunLogLastOutput();
    _logWriter.logEvent(event);
  }

  void _updateRunLogLastOutput() {
    final id = runLogId;
    final repo = deps.runLogRepo;
    if (id == null || repo == null) {
      return;
    }
    unawaited(() async {
      try {
        final existing = await repo.getById(id);
        if (existing == null) {
          return;
        }
        await repo.upsert(
          existing.copyWith(lastOutputAt: lastOutputAt),
        );
      } catch (_) {}
    }());
  }

  Future<void> _openRunLog({required AgentCapabilities caps}) async {
    await _logWriter.open(
      agentDirHostPath: agentDirHostPath,
      agentId: agentId,
      workspaceId: workspaceId,
      conversationId: conversationId,
      ticketId: ticketId,
      cliName: cliName,
      modelId: modelId,
      capabilities: caps,
    );
    final path = _logWriter.logPath;
    if (path != null) {
      _updateRunLogPath(path);
    }
  }

  Future<void> _closeRunLog({int? exitCode, Object? error}) async {
    await _logWriter.close(exitCode: exitCode, error: error);
  }

  void _closeController() {
    if (!controller.isClosed) {
      controller.close();
    }
  }

  Future<AgentCapabilities> _capabilitiesFor(String? agentId) async {
    if (agentId != null) {
      try {
        final agent = await deps.agentRepo.getById(agentId);
        if (agent?.capabilities != null) {
          return agent!.capabilities!;
        }
      } catch (_) {
        AppLog.w('DispatchSession', 'Failed to fetch agent capabilities: $agentId');
      }
    }
    return deps.defaultCaps;
  }
}
