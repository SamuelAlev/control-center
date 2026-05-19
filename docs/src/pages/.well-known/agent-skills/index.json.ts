// /.well-known/agent-skills/index.json — the Agent Skills Discovery index
// (RFC v0.2.0). Logic lives in src/agentic/agent-skills.ts.
//
// Prerendered, unlike the neighbouring /.well-known/api-catalog: this route's
// path carries a real `.json` extension, so the static-asset layer types the
// response `application/json` from the file name, which is what the RFC
// requires. The catalog next door has to be server-rendered precisely because
// its path has no extension.
import type { APIRoute } from 'astro';
import { buildAgentSkillsIndex } from '../../../agentic/agent-skills';

export const prerender = true;

export const GET: APIRoute = async ({ site }) => {
  const origin = (site ?? new URL('https://usectrl.dev/')).toString().replace(/\/$/, '');
  const index = await buildAgentSkillsIndex({ origin });
  return new Response(JSON.stringify(index, null, 2), {
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
      'Access-Control-Allow-Origin': '*',
    },
  });
};
