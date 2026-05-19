import 'dart:async';

import 'package:cc_mcp_client/src/config/mcp_client_models.dart';
import 'package:cc_mcp_client/src/protocol.dart';
import 'package:cc_mcp_client/src/transports/mcp_transport.dart';

/// A JSON-RPC error returned by an MCP server.
class McpRpcException implements Exception {
  /// Creates an [McpRpcException].
  const McpRpcException(this.code, this.message, {this.data});

  /// JSON-RPC error code.
  final int code;

  /// Error message.
  final String message;

  /// Optional structured error data.
  final Object? data;

  @override
  String toString() => 'McpRpcException($code): $message';
}

/// The protocol layer over a [McpTransport]: request/response correlation,
/// the `initialize` handshake, capability negotiation, and the typed
/// list/call/read RPCs. One [McpClient] wraps one server connection.
///
/// This is transport-agnostic: it is handed an already-constructed transport
/// and never knows whether bytes flow over stdio, HTTP, or SSE.
class McpClient {
  /// Creates an [McpClient] over [transport].
  McpClient(this.transport);

  /// The underlying frame pipe.
  final McpTransport transport;

  var _nextId = 0;
  final _pending = <int, Completer<Map<String, dynamic>>>{};
  StreamSubscription<Map<String, dynamic>>? _sub;

  final _notifications = StreamController<McpNotification>.broadcast();
  McpServerCapabilities _capabilities = const McpServerCapabilities();
  String? _serverName;
  String? _instructions;
  bool _closed = false;

  /// Server→client notifications (tool/resource/prompt list-changed, etc.).
  Stream<McpNotification> get notifications => _notifications.stream;

  /// Capabilities the server advertised on `initialize`.
  McpServerCapabilities get capabilities => _capabilities;

  /// The server's self-reported name, if any.
  String? get serverName => _serverName;

  /// The server's `instructions` string, if any.
  String? get instructions => _instructions;

  /// Completes when the underlying transport closes.
  Future<void> get done => transport.done;

  /// Opens the transport, wires up frame routing, performs the `initialize`
  /// handshake, and sends `notifications/initialized`. Returns the negotiated
  /// capabilities.
  Future<McpServerCapabilities> initialize({Duration? timeout}) async {
    await transport.start();
    _sub = transport.incoming.listen(_onFrame, onError: (_) {});
    unawaited(transport.done.then((_) => _onTransportClosed()));

    final result = await _request(McpProtocol.initialize, {
      'protocolVersion': McpProtocol.version,
      'capabilities': {
        'tools': <String, dynamic>{},
        'resources': <String, dynamic>{},
        'prompts': <String, dynamic>{},
      },
      'clientInfo': {
        'name': McpProtocol.clientName,
        'version': McpProtocol.clientVersion,
      },
    }, timeout: timeout);

    _capabilities = McpServerCapabilities.fromJson(
      (result['capabilities'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
    _serverName =
        (result['serverInfo'] as Map?)?['name'] as String? ?? _serverName;
    _instructions = result['instructions'] as String?;

    // Fire-and-forget the initialized notification.
    await _notify(McpProtocol.initialized, const {});
    return _capabilities;
  }

  /// Lists the server's tools, following `nextCursor` pagination to exhaustion.
  Future<List<McpRemoteTool>> listTools({Duration? timeout}) async {
    if (!_capabilities.tools) {
      return const [];
    }
    final tools = <McpRemoteTool>[];
    String? cursor;
    do {
      final result = await _request(
        McpProtocol.toolsList,
        cursor == null ? const {} : {'cursor': cursor},
        timeout: timeout,
      );
      final page = (result['tools'] as List?) ?? const [];
      for (final entry in page) {
        if (entry is Map) {
          tools.add(McpRemoteTool.fromJson(entry.cast<String, dynamic>()));
        }
      }
      cursor = result['nextCursor'] as String?;
    } while (cursor != null && cursor.isNotEmpty);
    return tools;
  }

  /// Calls a tool by its server-local [name] with [arguments]. Returns the raw
  /// MCP `tools/call` result (`{content: [...], isError?}`).
  Future<Map<String, dynamic>> callTool(
    String name,
    Map<String, dynamic> arguments, {
    Duration? timeout,
  }) {
    return _request(McpProtocol.toolsCall, {
      'name': name,
      'arguments': arguments,
    }, timeout: timeout);
  }

  /// Lists the server's resources (paginated).
  Future<List<McpRemoteResource>> listResources({Duration? timeout}) async {
    if (!_capabilities.resources) {
      return const [];
    }
    final resources = <McpRemoteResource>[];
    String? cursor;
    do {
      final result = await _request(
        McpProtocol.resourcesList,
        cursor == null ? const {} : {'cursor': cursor},
        timeout: timeout,
      );
      final page = (result['resources'] as List?) ?? const [];
      for (final entry in page) {
        if (entry is Map) {
          resources.add(
            McpRemoteResource.fromJson(entry.cast<String, dynamic>()),
          );
        }
      }
      cursor = result['nextCursor'] as String?;
    } while (cursor != null && cursor.isNotEmpty);
    return resources;
  }

  /// Reads a resource by [uri]. Returns the raw `resources/read` result.
  Future<Map<String, dynamic>> readResource(String uri, {Duration? timeout}) {
    return _request(McpProtocol.resourcesRead, {'uri': uri}, timeout: timeout);
  }

  /// Lists the server's prompts (paginated).
  Future<List<McpRemotePrompt>> listPrompts({Duration? timeout}) async {
    if (!_capabilities.prompts) {
      return const [];
    }
    final prompts = <McpRemotePrompt>[];
    String? cursor;
    do {
      final result = await _request(
        McpProtocol.promptsList,
        cursor == null ? const {} : {'cursor': cursor},
        timeout: timeout,
      );
      final page = (result['prompts'] as List?) ?? const [];
      for (final entry in page) {
        if (entry is Map) {
          prompts.add(McpRemotePrompt.fromJson(entry.cast<String, dynamic>()));
        }
      }
      cursor = result['nextCursor'] as String?;
    } while (cursor != null && cursor.isNotEmpty);
    return prompts;
  }

  /// Gets a prompt by [name] with optional [arguments]. Returns the raw
  /// `prompts/get` result (`{messages: [...]}`).
  Future<Map<String, dynamic>> getPrompt(
    String name, {
    Map<String, String> arguments = const {},
    Duration? timeout,
  }) {
    return _request(McpProtocol.promptsGet, {
      'name': name,
      if (arguments.isNotEmpty) 'arguments': arguments,
    }, timeout: timeout);
  }

  Future<Map<String, dynamic>> _request(
    String method,
    Map<String, dynamic> params, {
    Duration? timeout,
  }) async {
    if (_closed) {
      throw const McpTransportException('client is closed');
    }
    final id = _nextId++;
    final completer = Completer<Map<String, dynamic>>();
    _pending[id] = completer;
    await transport.send({
      'jsonrpc': '2.0',
      'id': id,
      'method': method,
      'params': params,
    });
    final effective = timeout ?? const Duration(seconds: 30);
    final future = effective.inMilliseconds <= 0
        ? completer.future
        : completer.future.timeout(
            effective,
            onTimeout: () {
              _pending.remove(id);
              throw McpRpcException(-32000, 'request "$method" timed out');
            },
          );
    return future;
  }

  Future<void> _notify(String method, Map<String, dynamic> params) {
    return transport.send({
      'jsonrpc': '2.0',
      'method': method,
      'params': params,
    });
  }

  void _onFrame(Map<String, dynamic> frame) {
    final id = frame['id'];
    if (frame.containsKey('method')) {
      // Server → client request or notification.
      final method = frame['method'] as String? ?? '';
      if (id == null) {
        _notifications.add(
          McpNotification(
            method,
            (frame['params'] as Map?)?.cast<String, dynamic>() ?? const {},
          ),
        );
      }
      // Server→client *requests* (sampling/elicitation) are not yet supported;
      // a compliant server treats a missing response as "capability absent".
      return;
    }
    // Response to one of our requests.
    if (id is! int) {
      return;
    }
    final completer = _pending.remove(id);
    if (completer == null || completer.isCompleted) {
      return;
    }
    final error = frame['error'];
    if (error is Map) {
      completer.completeError(
        McpRpcException(
          (error['code'] as num?)?.toInt() ?? -32000,
          error['message'] as String? ?? 'unknown error',
          data: error['data'],
        ),
      );
      return;
    }
    completer.complete(
      (frame['result'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }

  void _onTransportClosed() {
    if (_closed) {
      return;
    }
    for (final completer in _pending.values) {
      if (!completer.isCompleted) {
        completer.completeError(
          const McpTransportException('transport closed before response'),
        );
      }
    }
    _pending.clear();
  }

  /// Closes the client and its transport. Idempotent.
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    await _sub?.cancel();
    _sub = null;
    _onTransportClosed();
    await transport.close();
    if (!_notifications.isClosed) {
      await _notifications.close();
    }
  }
}

/// A server→client notification (method + params).
class McpNotification {
  /// Creates an [McpNotification].
  const McpNotification(this.method, this.params);

  /// Notification method (e.g. `notifications/tools/list_changed`).
  final String method;

  /// Notification parameters.
  final Map<String, dynamic> params;
}
