/// The Control Center MCP tool surface — the agent-facing API.
///
/// Ref-free `McpTool` implementations + the `McpToolDispatcher` (an
/// `RpcDispatcher`), consumed by two hosts: the desktop's local MCP HTTP server
/// and the headless `cc_server`'s RPC/MCP endpoint. Pure Dart (cc_domain +
/// cc_rpc + cc_infra), so it links into the Flutter-free `dart build cli`
/// server binary. Tools log through `CcMcpLog`; the app installs its sink.
library;

export 'src/log/cc_mcp_log.dart';
export 'src/mcp_http_server.dart';
export 'src/mcp_protocol.dart';
export 'src/mcp_tool_dispatcher.dart';
export 'src/tools/tools.dart';
