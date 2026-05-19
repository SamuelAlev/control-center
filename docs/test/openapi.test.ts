import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { buildOpenApi } from '../src/agentic/openapi.ts';
import { errorEnvelope } from '../src/agentic/negotiation.ts';

const INPUTS = {
  origin: 'https://usectrl.dev',
  version: 'v0.0.1-rc.1',
  compareToolIds: ['conductor', 'cursor'],
  docSlugs: ['manual', 'manual/guides/mcp-server'],
};

describe('buildOpenApi', () => {
  const doc = buildOpenApi(INPUTS) as {
    openapi: string;
    info: { title: string; version: string; license: { name: string } };
    paths: Record<string, Record<string, { operationId?: string; description?: string; responses?: object; parameters?: unknown[] }>>;
    components: { schemas: { Error: { properties: { error: { required: string[] } } } } };
  };

  it('is OpenAPI 3.1 with the release version', () => {
    assert.equal(doc.openapi, '3.1.0');
    assert.equal(doc.info.version, 'v0.0.1-rc.1');
    assert.equal(doc.info.license.name, 'MIT');
  });

  it('publishes every agent entrypoint as a path', () => {
    for (const path of ['/', '/llms.txt', '/llms-full.txt', '/openapi.json', '/.well-known/api-catalog', '/.well-known/agent-skills/index.json', '/.well-known/mcp/server-card.json', '/sitemap-index.xml', '/rss.xml', '/.well-known/mcp', '/developers', '/about', '/contact', '/{path}']) {
      assert.ok(doc.paths[path], `missing path ${path}`);
    }
  });

  it('gives every operation a unique operationId, a description and responses', () => {
    const ids = new Set<string>();
    for (const [path, methods] of Object.entries(doc.paths)) {
      for (const [method, op] of Object.entries(methods)) {
        assert.ok(op.operationId, `${method.toUpperCase()} ${path} missing operationId`);
        assert.ok(!ids.has(op.operationId), `duplicate operationId ${op.operationId}`);
        ids.add(op.operationId);
        assert.ok(op.description && op.description.length > 20, `${op.operationId} needs a real description`);
        assert.ok(op.responses && Object.keys(op.responses).length > 0, `${op.operationId} needs responses`);
      }
    }
  });

  it('documents the Accept negotiation on content pages', () => {
    const landing = doc.paths['/'].get;
    const accept = (landing.parameters as { name: string }[]).find((p) => p.name === 'Accept');
    assert.ok(accept, 'landing page must document the Accept parameter');
  });

  it('documents 404s as JSON + markdown + HTML', () => {
    const notFound = (doc.components as { responses: { NotFound: { content: Record<string, unknown> } } }).responses.NotFound;
    for (const type of ['application/json', 'text/markdown', 'text/html']) {
      assert.ok(notFound.content[type], `NotFound missing ${type}`);
    }
  });

  it('lands the dynamic enums', () => {
    const compare = doc.paths['/compare/{tool}'].get;
    const toolParam = (compare.parameters as { name: string; schema: { enum: string[] } }[]).find((p) => p.name === 'tool');
    assert.deepEqual(toolParam?.schema.enum, ['conductor', 'cursor']);
  });

  it('pins the Error schema to the envelope the worker actually emits', () => {
    // The worker's 404 JSON body (errorEnvelope) must satisfy the published
    // schema — otherwise the spec lies. Required keys are asserted both ways.
    const required = doc.components.schemas.Error.properties.error.required;
    const emitted = errorEnvelope(404, 'not_found', 'msg', 'hint', { origin: 'https://usectrl.dev' }).error;
    for (const key of required) {
      assert.ok(key in emitted, `schema requires ${key} but the worker does not emit it`);
    }
    for (const key of Object.keys(emitted)) {
      assert.ok(required.includes(key), `worker emits ${key} but the schema does not require it`);
    }
  });
});
