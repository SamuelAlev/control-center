// /mcp — the conventional MCP path; same docs MCP server as /.well-known/mcp.
// Logic lives in src/agentic/mcp-http.ts.
import { mcpGet, mcpOptions, mcpPost } from '../agentic/mcp-http';

export const prerender = false;

export const GET = mcpGet;
export const POST = mcpPost;
export const OPTIONS = mcpOptions;
