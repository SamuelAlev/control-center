// /.well-known/agent-skills/<skill>/SKILL.md — one published skill artifact,
// prerendered as a static asset. Content lives in src/agentic/agent-skills.ts.
//
// Dynamic on purpose: getStaticPaths reads the same SKILLS list the index is
// built from, so a skill can never be published in the index with no artifact
// behind it — a dead URL makes the digest unverifiable, which defeats the point
// of publishing one.
//
// The body is `skillDocument(name)` and nothing else: no wrapping, no
// re-serialization. That exact string is what the index hashed.
import type { APIRoute, GetStaticPaths } from 'astro';
import { SKILL_MD_MEDIA_TYPE, skillDocument, skillNames } from '../../../../agentic/agent-skills';

export const prerender = true;

export const getStaticPaths: GetStaticPaths = () =>
  skillNames().map((skill) => ({
    params: { skill },
    props: { markdown: skillDocument(skill) },
  }));

export const GET: APIRoute<{ markdown: string }> = ({ props }) =>
  new Response(props.markdown, {
    headers: {
      'Content-Type': SKILL_MD_MEDIA_TYPE,
      'Access-Control-Allow-Origin': '*',
    },
  });
