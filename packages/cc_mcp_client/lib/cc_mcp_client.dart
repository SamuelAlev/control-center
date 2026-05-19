/// The Control Center MCP CLIENT and tool ecosystem.
///
/// CC has always been an MCP *server* (it exposes ~55 typed tools). This
/// package adds the other half: a multi-transport MCP *client* that connects to
/// EXTERNAL MCP servers (stdio / Streamable HTTP / SSE), bridges their remote
/// tools into CC's local `McpToolRegistry`, and layers on the cross-cutting
/// tool ecosystem the agent loop needs at scale:
///
/// * connection lifecycle with a crash-storm circuit breaker + hot-reload
/// * OAuth 2.1 (dynamic client registration, PKCE, loopback callback)
/// * multi-format config discovery (Claude / Codex / Cursor / Gemini / VS Code
///   / Windsurf / OpenCode / standalone `.mcp.json`)
/// * BM25 tool discovery (context savings once tool count crosses a threshold)
/// * per-args capability-tier approval (read / write / exec)
/// * worktree-aware semantic code search
/// * background-process management
/// * the advisor/watchdog secondary reviewer
///
/// Pure Dart (cc_domain + `dart:io`), no Flutter, so it links into both the
/// desktop app and the Flutter-free `dart build cli` server binary, exactly
/// like `cc_mcp`.
library;

export 'src/advisor/advisor.dart';
export 'src/approval/capability_tier.dart';
export 'src/background_process/background_process.dart';
export 'src/bridged_resource_prompt.dart';
export 'src/config/mcp_client_models.dart';
export 'src/config/mcp_server_config.dart';
export 'src/connection_manager.dart';
export 'src/discovery/config_discovery.dart';
export 'src/mcp_client.dart';
export 'src/mcp_client_service.dart';
export 'src/oauth/oauth.dart';
export 'src/protocol.dart';
export 'src/search_tool_bm25.dart';
export 'src/semantic/semantic.dart';
export 'src/tool_bridge.dart';
export 'src/tool_index.dart';
export 'src/transport_factory.dart';
export 'src/transports/http_transport.dart';
export 'src/transports/mcp_transport.dart';
export 'src/transports/sse_parser.dart';
export 'src/transports/stdio_transport.dart';
