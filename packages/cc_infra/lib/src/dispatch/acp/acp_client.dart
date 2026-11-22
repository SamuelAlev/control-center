import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/core/domain/value_objects/usage_scope.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';

/// A minimal Agent Client Protocol (JSON-RPC 2.0 over newline-delimited
/// stdio) client.
///
/// One [AcpClient] drives one ACP agent turn: it sends `initialize` →
/// `session/new` → `session/prompt`, listens for `session/update`
/// notifications and translates each update's message parts into
/// [AgentProcessEvent]s. The protocol field names follow the ACP spec at
/// agentclientprotocol.com; the only spec-dependent code is
/// [_mapUpdate], isolated here.
///
/// Transport is abstracted behind a `send` sink and the public [feedLine]
/// entry point so the same client is driven by a real subprocess (the
/// backend pipes stdout bytes into [feedLine]) or a test fixture. This keeps
/// the client free of `dart:io` and therefore unit-testable.
class AcpClient {
  /// Creates an [AcpClient].
  ///
  /// [_send] writes one JSON-RPC line to the agent's stdin. [onDone] is
  /// invoked once the turn is over (the `session/prompt` result arrived),
  /// allowing the host to tear the process down. [onRequest] answers the
  /// agent's own requests (`session/request_permission`, `fs/*`); without it
  /// every agent request is refused as an unknown method.
  AcpClient({required this._send, this.onDone, this.onRequest});

  final void Function(String line) _send;

  /// Optional callback fired when the prompt turn completes.
  final void Function()? onDone;

  /// Answers one agent→client request: returns the JSON-RPC `result`, or
  /// throws [AcpRpcException] (with its code) to answer with an `error`.
  final Future<Object?> Function(String method, Map<String, dynamic> params)?
  onRequest;

  final _events = StreamController<AgentProcessEvent>.broadcast();
  int _nextId = 1;
  final _pending = <int, Completer<dynamic>>{};
  bool _closed = false;

  /// Stream of structured events translated from `session/update`.
  Stream<AgentProcessEvent> get events => _events.stream;

  /// Sends `initialize` and awaits the agent's result (its `protocolVersion`,
  /// `agentInfo` and capabilities). Per ACP, this is the required handshake
  /// before any session method.
  ///
  /// The client advertises the file-system methods only when it can answer
  /// them ([onRequest] is set) and never a terminal: an agent that believed
  /// it had one would route commands around its own sandbox.
  Future<Map<String, dynamic>> initialize({
    String protocolVersion = '2025-07-01',
    String clientName = 'control-center',
    String clientVersion = '0.1.0',
  }) async {
    final answers = onRequest != null;
    final result = await _request('initialize', {
      'protocolVersion': protocolVersion,
      'clientInfo': {'name': clientName, 'version': clientVersion},
      'clientCapabilities': {
        'fs': {'readTextFile': answers, 'writeTextFile': answers},
        'terminal': false,
      },
    });
    return result is Map ? result.cast<String, dynamic>() : {};
  }

  /// Sends `session/new`, returning the new session id. Passes [cwd], an
  /// optional [model] and (later) MCP servers when the agent negotiates them.
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
    final id = result is Map
        ? result['sessionId'] ?? result['session_id']
        : null;
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

  /// Sends the `session/cancel` notification: the agent stops the turn of
  /// [sessionId] and answers its pending `session/prompt` with the stop
  /// reason `cancelled`. A notification, so there is nothing to await.
  void sessionCancel(String sessionId) {
    if (_closed) {
      return;
    }
    _send(
      jsonEncode({
        'jsonrpc': '2.0',
        'method': 'session/cancel',
        'params': {'sessionId': sessionId},
      }),
    );
  }

  /// Feeds one decoded JSON-RPC line from the agent's stdout. Routes it as a
  /// request from the agent (answered through [onRequest]), a response
  /// (completing a pending request) or a notification (emitting events).
  /// Unrecognized lines are ignored so agent banner output does not break the
  /// protocol.
  ///
  /// A message is a response only when it carries no `method` and answers an
  /// id this client sent. Any line with a pending id used to be taken as the
  /// answer, so an agent REQUEST that happened to reuse an id (both sides
  /// count from 1) completed this client's call with the request's params —
  /// and the request itself was never answered, leaving the agent waiting.
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
    final method = json['method'];
    if (method is String && method.isNotEmpty) {
      if (id != null) {
        unawaited(_answer(id, method, json['params']));
        return;
      }
    } else {
      if (id is int &&
          (json.containsKey('result') || json.containsKey('error'))) {
        final completer = _pending.remove(id);
        if (completer == null) {
          // Not an id this client is waiting on: a duplicate or a forgery.
          return;
        }
        final error = json['error'];
        if (error is Map) {
          completer.completeError(
            AcpRpcException(
              error['message']?.toString() ?? 'ACP RPC error',
              code: error['code'] is int ? error['code'] as int : null,
            ),
          );
        } else {
          completer.complete(json['result']);
        }
      }
      return;
    }
    // Notification.
    if (method == 'session/update') {
      final params = json['params'];
      if (params is Map) {
        _mapUpdate(params.cast<String, dynamic>());
      }
    }
  }

  /// JSON-RPC's "method not found".
  static const int methodNotFound = -32601;

  /// JSON-RPC's "internal error".
  static const int internalError = -32603;

  Future<void> _answer(Object id, String method, Object? rawParams) async {
    final handler = onRequest;
    final params = rawParams is Map
        ? rawParams.cast<String, dynamic>()
        : <String, dynamic>{};
    Map<String, Object?> reply;
    if (handler == null) {
      reply = _error(id, methodNotFound, 'Method not supported: $method');
    } else {
      try {
        reply = {
          'jsonrpc': '2.0',
          'id': id,
          'result': await handler(method, params),
        };
      } on AcpRpcException catch (e) {
        reply = _error(id, e.code ?? internalError, e.message);
      } on Object catch (e) {
        reply = _error(id, internalError, 'Request failed: $e');
      }
    }
    if (!_closed) {
      _send(jsonEncode(reply));
    }
  }

  static Map<String, Object?> _error(Object id, int code, String message) => {
    'jsonrpc': '2.0',
    'id': id,
    'error': {'code': code, 'message': message},
  };

  Future<dynamic> _request(String method, Map<String, dynamic> params) {
    if (_closed) {
      return Future.error(StateError('ACP client closed'));
    }
    final id = _nextId++;
    final completer = Completer<dynamic>();
    _pending[id] = completer;
    _send(
      jsonEncode({
        'jsonrpc': '2.0',
        'id': id,
        'method': method,
        'params': params,
      }),
    );
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
  ///   - `usage_update` → the session's cost so far, when the agent reports
  ///     one in US dollars (`cost: {amount, currency}`), as an absolute
  ///     [UsageScope.runCumulative] snapshot
  void _mapUpdate(Map<String, dynamic> params) {
    final update = params['update'];
    if (update is! Map) {
      return;
    }
    final u = update.cast<String, dynamic>();
    final type = u['sessionUpdate']?.toString() ?? u['type']?.toString() ?? '';
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
        _events.add(
          ToolCallEvent(
            toolCallId: u['toolCallId']?.toString() ?? '',
            toolName: u['toolName']?.toString() ?? '',
            inputs: _asJsonObject(u['rawInput'] ?? u['input']),
          ),
        );
        break;
      case 'tool_call_update':
        _events.add(
          ToolResultEvent(
            toolCallId: u['toolCallId']?.toString() ?? '',
            outputs: _extractContentText(u['content']),
            toolName: u['toolName']?.toString() ?? '',
            isPartial: true,
          ),
        );
        break;
      case 'usage_update':
        final cost = u['cost'];
        if (cost is Map) {
          final amount = cost['amount'];
          final currency = cost['currency']?.toString().toUpperCase();
          if (amount is num && (currency == null || currency == 'USD')) {
            _events.add(
              UsageEvent(
                scope: UsageScope.runCumulative,
                usage: RunUsage(
                  costMicros: (amount * 1000000).round(),
                  costBasis: CostBasis.providerReported,
                ),
              ),
            );
          }
        }
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

/// A JSON-RPC `error`: thrown when an ACP request returns one, and thrown by
/// an [AcpClient.onRequest] handler to answer with one.
class AcpRpcException implements Exception {
  /// Creates an [AcpRpcException].
  AcpRpcException(this.message, {this.code});

  /// The error message.
  final String message;

  /// The JSON-RPC error code, when there is one.
  final int? code;

  @override
  String toString() => 'AcpRpcException: $message';
}
