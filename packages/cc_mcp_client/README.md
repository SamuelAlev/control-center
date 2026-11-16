# cc_mcp_client

The **MCP client**: Control Center as a _consumer_ of external MCP servers. It
connects to third-party servers over stdio / HTTP / SSE (with OAuth), discovers
their tools and bridges them into Control Center's own tool registry so agents
can call them alongside the native tools.

> Direction matters: `cc_mcp` is the tool surface CC _exposes_; `cc_mcp_client`
> (this package) is CC _connecting out_ to other servers.

## Responsibilities

- **Transports** (`src/transports/`, `transport_factory.dart`) — stdio, HTTP,
  and SSE, plus reconnect handling.
- **Connection lifecycle** (`connection_manager.dart`) — connect, reconnect,
  retry and the invoker that `tools/call`s a remote tool.
- **OAuth** (`src/oauth/`) — auth flow + token storage for servers that require
  it.
- **Tool bridging** (`tool_bridge.dart`) — wraps each remote tool as a
  `BridgedMcpTool` namespaced `mcp__<server>__<tool>`, so two servers can't
  collide. Names are capped at 43 characters (a hash keeps long ones distinct)
  so Claude Code's `mcp__control-center__` prefix stays within 64.
- **Audiences** — an `McpClientService` publishes to an `McpToolSink`; the host
  runs one for the owner's personal servers and one per workspace for its
  configured servers, each feeding its own registry layer.

## Invariants (security)

- External servers are **untrusted**. Every bridged tool defaults to the most
  cautious approval tier (`ToolApproval.exec`, `requiresApproval`).
- Tool descriptions and results are sanitised before reaching an agent's
  context: `BridgedMcpTool.sanitizeExternalText` strips ANSI/OSC/control chars
  and caps length (desc 2 KB, result 256 KB) so a malicious server can't inject
  terminal escapes or flood the context window.

- A config marked `publicOnly` (a workspace's http/sse server its server owner
  has not approved) is dialled only through the injected
  `publicOnlyConnection` factory; with none, every connection is refused.

## Extending

New external server type → add a transport + factory case. New sanitisation
rule → extend `sanitizeExternalText` (and its tests in
`test/transport_and_bridge_test.dart`).
