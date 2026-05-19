import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';

/// A minimal Agent Client Protocol (JSON-RPC 2.0 over newline-delimited
/// stdio) client.
///
/// One [AcpClient] drives one ACP agent turn: it sends `initialize` →
/// `session/new` → `session/prompt`, listens for `session/update`
/// notifications, and translates each update's message parts into
/// [AgentProcessEvent]s. The protocol field names follow the ACP spec at
/// agentclientprotocol.com; the only spec-dependent code is
/// [_mapUpdate], isolated here.
///
/// Transport is abstracted behind a [send] sink and the public [feedLine]
/// entry point so the same client is driven by a real subprocess (the
/// backend pipes stdout bytes into [feedLine]) or a test fixture. This keeps
/// the client free of `dart:io` and therefore unit-testable.
class AcpClient {
  /// Creates an [AcpClient].
  ///
  /// [send] writes one JSON-RPC line to the agent's stdin. [onDone] is
  /// invoked once the turn is over (the `session/prompt` result arrived),
  /// allowing the host to tear the process down.
  AcpClient({required void Function(String line) send, this.onDone})
      : _send = send;

  final void Function(String line) _send;

  /// Optional callback fired when the prompt turn completes.
  final void Function()? onDone;

  final _events = StreamController<AgentProcessEvent>.broadcast();
  int _nextId = 1;
  final _pending = <int, Completer<dynamic>>{};
  bool _closed = false;

  /// Stream of structured events translated from `session/update`.
  Stream<AgentProcessEvent> get events => _events.stream;

  /// Sends `initialize` and awaits the agent's result (its `protocolVersion`,
  /// `agentInfo`, and capabilities). Per ACP, this is the required handshake
  /// before any session method.
  Future<Map<String, dynamic>> initialize({
    String protocolVersion = '2025-07-01',
    String clientName = 'control-center',
    String clientVersion = '0.1.0',
  }) async {
    final result = await _request('initialize', {
      'protocolVersion': protocolVersion,
      'clientInfo': {'name': clientName, 'version': clientVersion},
    });
    return result is Map ? result.cast<String, dynamic>() : {};
  }

  /// Sends `session/new`, returning the new session id. Passes [cwd], an
  /// optional [model], and (later) MCP servers when the agent negotiates them.
  Future<String> sessionNew({
    required String cwd,
    String? model,
    String? mcpConfigPath,
  }) async {
    final params = <String, dynamic>{'cwd': cwd};
    if (model != null && model.isNotEmpty) {
      params['model'] = model;
    }
    if (mcpConfigPath != null && mcpConfigPath.isNotEmpty) {
      params['mcpConfigPath'] = mcpConfigPath;
    }
    final result = await _request('session/new', params);
    final id = result is Map ? result['sessionId'] ?? result['session_id'] : null;
    if (id is! String || id.isEmpty) {
      throw StateError('session/new returned no sessionId: $result');
    }
    return id;
  }

  /// Sends `session/prompt` and awaits the result (which arrives only after
  /// all `session/update` notifications for the turn have been sent). When the
  /// result arrives, the turn is over and [onDone] fires.
  Future<void> sessionPrompt({
    required String sessionId,
    required String prompt,
  }) async {
    await _request('session/prompt', {
      'sessionId': sessionId,
      'prompt': prompt,
    });
    // The prompt result signals turn completion.
    onDone?.call();
  }

  /// Cancels an in-progress turn.
  Future<void> sessionCancel(String sessionId) async {
    try {
      await _request('session/cancel', {'sessionId': sessionId});
    } catch (_) {
      // Best-effort: a failing cancel (process already gone) must not throw.
    }
  }

  // -- transport ---------------------------------------------------------------

  /// Feeds one decoded JSON-RPC line from the agent's stdout. Routes it as a
  /// response (completing a pending request) or a notification (emitting
  /// events). Unrecognized lines are ignored so agent banner output does not
  /// break the protocol.
  void feedLine(String line) {
    if (_closed || line.trim().isEmpty) {
      return;
    }
    Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(line);
      if (decoded is! Map) {
        return;
      }
      json = decoded.cast<String, dynamic>();
    } catch (_) {
      return;
    }
    final id = json['id'];
    if (id is int && _pending.containsKey(id)) {
      final completer = _pending.remove(id)!;
      final error = json['error'];
      if (error is Map) {
        completer.completeError(
          AcpRpcException(error['message']?.toString() ?? 'ACP RPC error'),
        );
      } else {
        completer.complete(json['result']);
      }
      return;
    }
    // Notification.
    final method = json['method']?.toString() ?? '';
    if (method == 'session/update') {
      final params = json['params'];
      if (params is Map) {
        _mapUpdate(params.cast<String, dynamic>());
      }
    }
  }

  Future<dynamic> _request(String method, Map<String, dynamic> params) {
    final id = _nextId++;
    final completer = Completer<dynamic>();
    _pending[id] = completer;
    _send(jsonEncode({
      'jsonrpc': '2.0',
      'id': id,
      'method': method,
      'params': params,
    }));
    return completer.future;
  }

  /// Translates a `session/update` params object into [AgentProcessEvent]s.
  ///
  /// ACP shapes the update as a discriminated union keyed by
  /// `update.sessionUpdate`:
  ///   - `agent_message_chunk` → assistant text (ContentBlocks)
  ///   - `agent_thought_chunk` → reasoning / thinking text
  ///   - `tool_call` → a tool invocation
  ///   - `tool_call_update` → a partial tool result
  void _mapUpdate(Map<String, dynamic> params) {
    final update = params['update'];
    if (update is! Map) {
      return;
    }
    final u = update.cast<String, dynamic>();
    final type = u['sessionUpdate']?.toString() ??
        u['type']?.toString() ??
        '';
    switch (type) {
      case 'agent_message_chunk':
        final text = _extractContentText(u['content']);
        if (text.isNotEmpty) {
          _events.add(TextEvent(content: text));
        }
        break;
      case 'agent_thought_chunk':
        final text = _extractContentText(u['content']);
        if (text.isNotEmpty) {
          _events.add(ThinkingEvent(content: text));
        }
        break;
      case 'tool_call':
        _events.add(ToolCallEvent(
          toolCallId: u['toolCallId']?.toString() ?? '',
          toolName: u['toolName']?.toString() ?? '',
          inputs: _asJsonObject(u['rawInput'] ?? u['input']),
        ));
        break;
      case 'tool_call_update':
        _events.add(ToolResultEvent(
          toolCallId: u['toolCallId']?.toString() ?? '',
          outputs: _extractContentText(u['content']),
          toolName: u['toolName']?.toString() ?? '',
          isPartial: true,
        ));
        break;
      default:
        break;
    }
  }

  /// Extracts text from an ACP `content` field, which may be a single
  /// ContentBlock (`{type:"text", text}`), an array of blocks, or a bare
  /// string.
  String _extractContentText(Object? content) {
    if (content is String) {
      return content;
    }
    if (content is Map) {
      final t = content['text'];
      if (t is String) {
        return t;
      }
    }
    if (content is List) {
      final buf = StringBuffer();
      for (final part in content) {
        if (part is Map) {
          final t = part['text'];
          if (t is String) {
            buf.write(t);
          }
        } else if (part is String) {
          buf.write(part);
        }
      }
      return buf.toString();
    }
    return '';
  }

  Map<String, dynamic>? _asJsonObject(Object? value) {
    if (value is Map) {
      return value.cast<String, dynamic>();
    }
    if (value is String && value.isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) {
          return decoded.cast<String, dynamic>();
        }
      } catch (_) {}
    }
    return null;
  }

  /// Releases the event stream. Pending requests are completed with an error.
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    for (final c in _pending.values) {
      c.completeError(StateError('ACP client closed'));
    }
    _pending.clear();
    await _events.close();
  }
}

/// Thrown when an ACP JSON-RPC request returns an `error` object.
class AcpRpcException implements Exception {
  /// Creates an [AcpRpcException].
  AcpRpcException(this.message);

  /// The error message from the agent.
  final String message;

  @override
  String toString() => 'AcpRpcException: $message';
}
