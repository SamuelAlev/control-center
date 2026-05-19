// /.well-known/mcp — the well-known entry to this site's docs MCP server
// (Streamable HTTP). Logic lives in src/agentic/mcp-http.ts.
import { mcpGet, mcpOptions, mcpPost } from '../../agentic/mcp-http';

export const prerender = false;

export const GET = mcpGet;
export const POST = mcpPost;
export const OPTIONS = mcpOptions;
