import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:control_center/features/sandboxing/data/claude_relay/anthropic_proxy.dart';
import 'package:control_center/features/sandboxing/data/claude_relay/claude_pid_watcher.dart';
import 'package:control_center/features/sandboxing/data/claude_relay/claude_trust_prompt.dart';
import 'package:control_center/features/sandboxing/data/claude_relay/message_assembler.dart';
import 'package:control_center/features/sandboxing/data/claude_relay/sse.dart';
import 'package:flutter_pty/flutter_pty.dart';

/// A tool invocation surfaced by the relay (from a completed `tool_use` block).
class ClaudeToolUse {
  /// Creates a [ClaudeToolUse].
  const ClaudeToolUse({required this.id, required this.name, this.input});

  /// Anthropic tool_use id.
  final String id;

  /// Tool name (e.g. `Bash`, `Edit`).
  final String name;

  /// Decoded tool input.
  final Object? input;
}

/// A tool result extracted from a follow-up `/v1/messages` request body.
class ClaudeToolResult {
  /// Creates a [ClaudeToolResult].
  const ClaudeToolResult({
    required this.toolUseId,
    required this.content,
    required this.isError,
  });

  /// The id of the tool_use this result answers.
  final String toolUseId;

  /// Flattened textual content of the result.
  final String content;

  /// Whether the tool reported an error.
  final bool isError;
}

/// Callbacks invoked by [ClaudeRelay] as Claude works. All are optional.
class ClaudeRelayCallbacks {
  /// Creates [ClaudeRelayCallbacks].
  const ClaudeRelayCallbacks({
    this.onText,
    this.onThinking,
    this.onToolCall,
    this.onToolResult,
    this.onError,
    this.onDebug,
    this.onPid,
    this.onStatus,
  });

  /// Streamed assistant text delta.
  final void Function(String delta)? onText;

  /// Streamed extended-thinking delta.
  final void Function(String delta)? onThinking;

  /// A completed tool call.
  final void Function(ClaudeToolUse toolUse)? onToolCall;

  /// A tool result observed on a follow-up request.
  final void Function(ClaudeToolResult result)? onToolResult;

  /// A relay/forwarding error message.
  final void Function(String message)? onError;

  /// A diagnostic message.
  final void Function(String message)? onDebug;

  /// The Claude process id once spawned.
  final void Function(int pid)? onPid;

  /// Claude's busy/idle/waiting status changes.
  final void Function(String status, String? waitingFor)? onStatus;
}

/// Drives a real, interactive `claude` process through a hidden PTY plus a
/// loopback Anthropic proxy, and exposes the same structured events that
/// `claude -p` would — but on the developer's Claude Code **subscription**
/// instead of metered API pricing.
///
/// This is the in-app Dart port of an upstream "claude api relay proxy". It
/// exists specifically so the control
/// center NEVER invokes `claude -p` (which is separately metered). The relay:
///
///   1. starts an [AnthropicProxy] on `127.0.0.1`,
///   2. spawns `claude` in a PTY with `ANTHROPIC_BASE_URL` pointed at it
///      (interactive mode, with the prompt as the initial positional arg),
///   3. tees the upstream SSE stream into assistant text / thinking / tool
///      calls, and
///   4. watches Claude's PID status file to know when the turn is complete,
///      then tears Claude down.
///
/// One relay instance handles exactly one single-shot dispatch.
class ClaudeRelay {
  /// Creates a [ClaudeRelay].
  ///
  /// [proxyFactory] and [pidWatcherFactory] exist for testing; production code
  /// uses the defaults.
  ClaudeRelay({
    AnthropicProxy Function(ProxyCallbacks callbacks)? proxyFactory,
    ClaudePidWatcher Function(
      int pid,
      void Function(String status, String? waitingFor, PidFileData data)
          onStatusChange,
    )? pidWatcherFactory,
  })  : _proxyFactory = proxyFactory ?? AnthropicProxy.new,
        _pidWatcherFactory = pidWatcherFactory ?? ClaudePidWatcher.new;

  final AnthropicProxy Function(ProxyCallbacks callbacks) _proxyFactory;
  final ClaudePidWatcher Function(
    int pid,
    void Function(String status, String? waitingFor, PidFileData data)
        onStatusChange,
  ) _pidWatcherFactory;

  /// Grace period of upstream quiet after an end-of-turn stop reason before the
  /// relay completes the turn — a fallback for when the PID status file is
  /// unavailable. Generous enough not to fire mid-tool-execution.
  static const Duration _quietCompletionGrace = Duration(seconds: 8);

  AnthropicProxy? _proxy;
  Pty? _pty;
  ClaudePidWatcher? _pidWatcher;
  StreamSubscription<Uint8List>? _ptyOut;
  MessageAssembler? _assembler;
  ClaudeRelayCallbacks _callbacks = const ClaudeRelayCallbacks();
  WorkspaceTrustPromptDetector? _trustDetector;
  Timer? _quietTimer;

  final Completer<int> _completer = Completer<int>();
  final Set<String> _emittedToolResultIds = <String>{};

  bool _turnStarted = false;
  bool _sawAssistantContent = false;
  bool _sawTerminalStop = false;
  bool _finished = false;
  bool _autoTrust = false;

  /// Builds the `claude` argument list (excluding the positional prompt). The
  /// relay is always interactive — `claude -p` is intentionally never used.
  static List<String> buildClaudeArgs({
    String? modelId,
    String? permissionMode,
    bool skipPermissions = true,
  }) {
    final args = <String>[];
    if (modelId != null && modelId.isNotEmpty) {
      args.addAll(['--model', modelId]);
    }
    if (permissionMode != null && permissionMode.isNotEmpty) {
      args.addAll(['--permission-mode', permissionMode]);
    }
    if (skipPermissions) {
      args.add('--dangerously-skip-permissions');
    }
    return args;
  }

  /// Runs Claude for a single prompt and resolves with its exit code (0 on a
  /// normally-completed turn).
  Future<int> run({
    required String claudePath,
    required List<String> args,
    required String prompt,
    required Map<String, String> environment,
    required String workingDirectory,
    required ClaudeRelayCallbacks callbacks,
  }) async {
    _callbacks = callbacks;
    _autoTrust = shouldAutoConfirmWorkspaceTrust(args);
    _assembler = MessageAssembler(_onAssembledMessage);

    try {
      final proxy = _proxyFactory(_buildProxyCallbacks());
      _proxy = proxy;
      await proxy.start();
      callbacks.onDebug?.call('[claude-relay] relay proxy on ${proxy.baseUrl}');

      // node-pty (the upstream relay's host) inherits the full process environment; Dart's
      // Pty.start only copies a handful of vars, so seed it with the parent
      // environment (auth, proxies, node options, …) before our overrides.
      final env = <String, String>{
        ...Platform.environment,
        ...environment,
        'ANTHROPIC_BASE_URL': proxy.baseUrl,
      };

      final pty = Pty.start(
        claudePath,
        arguments: [...args, prompt],
        environment: env,
        workingDirectory: workingDirectory,
        rows: 40,
        columns: 120,
      );
      _pty = pty;
      callbacks.onPid?.call(pty.pid);
      callbacks.onDebug
          ?.call('[claude-relay] claude running in PTY (pid ${pty.pid})');

      _trustDetector = WorkspaceTrustPromptDetector(_onTrustPrompt);
      _ptyOut = pty.output.listen(
        (bytes) =>
            _trustDetector?.add(utf8.decode(bytes, allowMalformed: true)),
        onError: (Object e) => callbacks.onError?.call('[claude-relay] pty error: $e'),
      );

      unawaited(pty.exitCode.then(_onPtyExit));

      final watcher = _pidWatcherFactory(pty.pid, _onStatusChange);
      _pidWatcher = watcher;
      watcher.start();

      return await _completer.future;
    } catch (e) {
      callbacks.onError?.call('[claude-relay] relay failed to start: $e');
      await _teardown();
      if (!_completer.isCompleted) {
        _completer.complete(1);
      }
      return _completer.future;
    }
  }

  /// Requests immediate termination of Claude and the proxy.
  Future<void> shutdown() async {
    await _complete(143);
  }

  ProxyCallbacks _buildProxyCallbacks() {
    return ProxyCallbacks(
      onSseEvent: (event, path, {required bool observe}) {
        if (!observe) {
          return;
        }
        _onSse(event);
      },
      onRequestBody: (body, path, {required bool observe}) {
        if (!observe) {
          return;
        }
        _onRequestBody(body);
      },
      onProxyError: (error) =>
          _callbacks.onDebug?.call('[claude-relay] proxy error: $error'),
      onRateLimit: (statusCode, retryAfter, path) => _callbacks.onDebug
          ?.call('[claude-relay] rate limited ($statusCode)'),
    );
  }

  void _onSse(SseEvent event) {
    _assembler?.processSse(event);

    final parsed = event.parsed;
    if (parsed is! Map) {
      return;
    }
    final p = parsed.cast<String, Object?>();
    final type = p['type'];

    if (type == 'content_block_delta') {
      final delta = p['delta'];
      if (delta is Map) {
        final d = delta.cast<String, Object?>();
        if (d['type'] == 'text_delta') {
          final text = d['text'];
          if (text is String && text.isNotEmpty) {
            _sawAssistantContent = true;
            _callbacks.onText?.call(text);
          }
        } else if (d['type'] == 'thinking_delta') {
          final thinking = d['thinking'];
          if (thinking is String && thinking.isNotEmpty) {
            _sawAssistantContent = true;
            _callbacks.onThinking?.call(thinking);
          }
        }
      }
    } else if (type == 'message_delta') {
      final delta = p['delta'];
      if (delta is Map) {
        final stopReason = delta.cast<String, Object?>()['stop_reason'];
        if (stopReason is String) {
          _maybeArmQuietCompletion(stopReason);
        }
      }
    }
  }

  void _onAssembledMessage(AssembledMessage message) {
    for (final block in message.content) {
      if (block is ToolUseBlock) {
        _sawAssistantContent = true;
        _callbacks.onToolCall?.call(ClaudeToolUse(
          id: block.id,
          name: block.name,
          input: block.input,
        ));
      }
    }
  }

  void _onRequestBody(Map<String, Object?> body) {
    final results = extractToolResultsFromBody(body, _emittedToolResultIds);
    for (final result in results) {
      _callbacks.onToolResult?.call(result);
    }
  }

  void _onStatusChange(String status, String? waitingFor, PidFileData data) {
    if (_finished) {
      return;
    }
    _callbacks.onStatus?.call(status, waitingFor);

    if (status == 'busy') {
      _turnStarted = true;
      _cancelQuietTimer();
    } else if (status == 'waiting') {
      // With --dangerously-skip-permissions Claude should not block on
      // permission. If it does (and we cannot answer in single-shot), surface
      // it; the trust-prompt path handles workspace-trust separately.
      _callbacks.onDebug
          ?.call('[claude-relay] claude is waiting (${waitingFor ?? 'unknown'})');
    } else if (status == 'idle') {
      // Complete only on a genuine busy->idle edge (mirrors the upstream relay's
      // `turnActive` gate in session.ts), or when Claude has already emitted a
      // terminal stop_reason (end_turn/stop_sequence/max_tokens) — i.e. the
      // turn really ended even if the watcher missed the busy poll. We must NOT
      // complete merely because some assistant text streamed: a stray/startup
      // idle would otherwise kill Claude mid-turn. Intermediate tool turns use
      // stop_reason `tool_use`, so `_sawTerminalStop` cannot fire mid-tool.
      if (_turnStarted || _sawTerminalStop) {
        unawaited(_complete(0));
      }
    }
  }

  void _onTrustPrompt() {
    if (_autoTrust) {
      _callbacks.onDebug
          ?.call('[claude-relay] auto-confirming Claude workspace trust prompt');
      _pty?.write(Uint8List.fromList(utf8.encode('\r')));
      return;
    }
    _callbacks.onError?.call(
      '[claude-relay] Claude is asking to trust this workspace, but it runs in a '
      'hidden PTY. Open `claude` in this directory once and choose '
      '"Yes, I trust this folder", or enable --dangerously-skip-permissions.',
    );
    unawaited(_complete(1));
  }

  void _maybeArmQuietCompletion(String stopReason) {
    // 'tool_use' means more API calls are coming; only arm on terminal stops.
    const terminal = {'end_turn', 'stop_sequence', 'max_tokens'};
    if (!terminal.contains(stopReason)) {
      _cancelQuietTimer();
      return;
    }
    // The turn genuinely ended; the next idle (or this quiet window) completes.
    _sawTerminalStop = true;
    _cancelQuietTimer();
    _quietTimer = Timer(_quietCompletionGrace, () {
      if (!_finished && _sawAssistantContent) {
        unawaited(_complete(0));
      }
    });
  }

  void _cancelQuietTimer() {
    _quietTimer?.cancel();
    _quietTimer = null;
  }

  void _onPtyExit(int code) {
    if (_finished) {
      return;
    }
    // Claude exited on its own before the turn completed (auth failure, crash,
    // immediate error) — propagate its exit code.
    unawaited(_complete(code));
  }

  Future<int> _complete(int code) async {
    if (_finished) {
      return _completer.isCompleted ? _completer.future : Future.value(code);
    }
    _finished = true;
    await _teardown();
    if (!_completer.isCompleted) {
      _completer.complete(code);
    }
    return code;
  }

  Future<void> _teardown() async {
    _cancelQuietTimer();
    _pidWatcher?.stop();
    _pidWatcher = null;
    await _ptyOut?.cancel();
    _ptyOut = null;
    final pty = _pty;
    _pty = null;
    if (pty != null) {
      try {
        pty.kill();
      } catch (_) {}
    }
    final proxy = _proxy;
    _proxy = null;
    if (proxy != null) {
      try {
        await proxy.stop();
      } catch (_) {}
    }
  }

  /// Extracts not-yet-seen `tool_result` blocks from a `/v1/messages` request
  /// body. [seen] is mutated with the tool_use ids that were emitted so each
  /// result is surfaced exactly once across the many requests of a turn.
  static List<ClaudeToolResult> extractToolResultsFromBody(
    Map<String, Object?> body,
    Set<String> seen,
  ) {
    final results = <ClaudeToolResult>[];
    final messages = body['messages'];
    if (messages is! List) {
      return results;
    }
    for (final message in messages) {
      if (message is! Map) {
        continue;
      }
      final m = message.cast<String, Object?>();
      if (m['role'] != 'user') {
        continue;
      }
      final content = m['content'];
      if (content is! List) {
        continue;
      }
      for (final block in content) {
        if (block is! Map) {
          continue;
        }
        final b = block.cast<String, Object?>();
        if (b['type'] != 'tool_result') {
          continue;
        }
        final toolUseId = b['tool_use_id'];
        if (toolUseId is! String || seen.contains(toolUseId)) {
          continue;
        }
        seen.add(toolUseId);
        results.add(ClaudeToolResult(
          toolUseId: toolUseId,
          content: _flattenResultContent(b['content']),
          isError: b['is_error'] == true,
        ));
      }
    }
    return results;
  }

  static String _flattenResultContent(Object? content) {
    if (content is String) {
      return content;
    }
    if (content is List) {
      final buffer = StringBuffer();
      for (final block in content) {
        if (block is Map) {
          final b = block.cast<String, Object?>();
          if (b['type'] == 'text' && b['text'] is String) {
            buffer.write(b['text'] as String);
          }
        }
      }
      return buffer.toString();
    }
    return '';
  }
}
