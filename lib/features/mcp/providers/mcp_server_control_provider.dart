// Seam for the MCP-server control surface the settings section reads.
//
// Desktop owns its own in-process MCP HTTP server, so it controls it directly
// through the existing config/server/running providers (`mcp_server_control_io.dart`).
// Web/thin clients host no MCP server; they drive the SERVER's MCP server over
// the `mcp.*` RPC ops (`mcp_server_control_web.dart`). Both expose the SAME two
// providers — `mcpServerControlProvider` (an `McpServerControl`) and
// `mcpServerStatusProvider` (`FutureProvider<McpServerStatus?>`) — so the single
// `McpSection` watches them identically on both platforms. On web the status is
// `null` when the connected server exposes no MCP control (the section then
// renders an honest "not available on this server" placeholder).
export 'mcp_server_control_io.dart'
    if (dart.library.js_interop) 'mcp_server_control_web.dart';
