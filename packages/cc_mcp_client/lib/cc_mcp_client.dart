/// MCP client: connect to external MCP servers (stdio / HTTP / SSE), bridge
/// tools into `McpToolRegistry`, plus OAuth, BM25 tool
/// search, capability-tier approval, and process lifecycle. Pure Dart
/// (no Flutter) for desktop and `cc_server`.
library;

export 'src/config/mcp_client_models.dart';
export 'src/config/mcp_server_config.dart';
export 'src/connection_manager.dart';
export 'src/list_my_tools_tool.dart';
export 'src/mcp_client.dart';
export 'src/mcp_client_service.dart';
export 'src/oauth/oauth.dart';
export 'src/protocol.dart';
export 'src/search_tool_bm25.dart';
export 'src/tool_bridge.dart';
export 'src/tool_list_cache.dart';
export 'src/transport_factory.dart';
export 'src/transports/http_transport.dart';
export 'src/transports/mcp_transport.dart';
export 'src/transports/sse_parser.dart';
export 'src/transports/stdio_transport.dart';
