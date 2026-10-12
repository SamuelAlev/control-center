import 'package:cc_domain/cc_domain.dart';

/// Transport-agnostic JSON-RPC request handler.
///
/// `McpToolDispatcher` implements this so every transport — the MCP HTTP
/// server, authenticated client session and in-process channel —
/// routes uniformly through one seam without depending on the concrete
/// dispatcher. It is also the composition seam for richer dispatchers (the
/// repo-RPC router) that wrap or delegate to the tool dispatcher.
abstract interface class RpcDispatcher {
  /// Handles a JSON-RPC [request] and returns the full response envelope
  /// (`{jsonrpc, id, result|error}`). Returns an empty map for notifications
  /// (which have no response).
  Future<Map<String, dynamic>> handleRequest(JsonRpcRequest request);
}
