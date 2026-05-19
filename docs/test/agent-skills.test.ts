import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { describe, it } from 'node:test';
import {
  AGENT_SKILLS_INDEX_PATH,
  AGENT_SKILLS_SCHEMA,
  SKILLS,
  SKILL_DIGEST_PATTERN,
  SKILL_NAME_PATTERN,
  buildAgentSkillsIndex,
  sha256Hex,
  skillDocument,
  skillNames,
  skillUrlPath,
} from '../src/agentic/agent-skills.ts';

const ORIGIN = 'https://usectrl.dev';

const index = await buildAgentSkillsIndex({ origin: ORIGIN });

/**
 * Hash the way a verifying CLIENT would, with a different implementation from
 * the one the module uses. The module hashes with `crypto.subtle`; this uses
 * node:crypto. If both agree, the digest is right rather than merely
 * self-consistent.
 */
const independentDigest = (text: string): string =>
  `sha256:${createHash('sha256').update(Buffer.from(text, 'utf8')).digest('hex')}`;

describe('agent skills index', () => {
  it('declares the v0.2.0 schema', () => {
    assert.equal(index.$schema, 'https://schemas.agentskills.io/discovery/0.2.0/schema.json');
    assert.equal(index.$schema, AGENT_SKILLS_SCHEMA);
  });

  it('is published at the well-known path the RFC fixes', () => {
    assert.equal(AGENT_SKILLS_INDEX_PATH, '/.well-known/agent-skills/index.json');
  });

  it('carries exactly the two top-level members v0.2.0 defines', () => {
    assert.deepEqual(Object.keys(index).sort(), ['$schema', 'skills']);
    assert.ok(Array.isArray(index.skills));
    assert.ok(index.skills.length > 0, 'an index with no skills is not worth serving');
  });

  it('gives every entry exactly the five required members', () => {
    for (const entry of index.skills) {
      assert.deepEqual(
        Object.keys(entry).sort(),
        ['description', 'digest', 'name', 'type', 'url'],
        `${entry.name} does not carry exactly the required members`,
      );
      for (const [key, value] of Object.entries(entry)) {
        assert.equal(typeof value, 'string', `${entry.name}.${key} must be a string`);
        assert.ok((value as string).length > 0, `${entry.name}.${key} is empty`);
      }
    }
  });

  it('uses names that satisfy the v0.2.0 grammar', () => {
    // 1-64 chars, lowercase alphanumeric and hyphens, no leading, trailing or
    // consecutive hyphens.
    for (const { name } of index.skills) {
      assert.match(name, /^[a-z0-9-]+$/, `${name} has characters outside the allowed set`);
      assert.match(name, SKILL_NAME_PATTERN, `${name} has a leading, trailing or doubled hyphen`);
      assert.ok(name.length >= 1 && name.length <= 64, `${name} is outside the 1-64 character range`);
    }
  });

  it('uses unique names', () => {
    const names = index.skills.map((s) => s.name);
    assert.equal(new Set(names).size, names.length, 'two entries share a name');
  });

  it('publishes only the artifact types v0.2.0 allows', () => {
    for (const { name, type } of index.skills) {
      assert.ok(type === 'skill-md' || type === 'archive', `${name} has an unknown type: ${type}`);
      // We serve markdown documents, never an archive: a .tar.gz entry would
      // need real archive bytes behind it to hash.
      assert.equal(type, 'skill-md', `${name} claims an archive we do not serve`);
    }
  });

  it('keeps descriptions inside the 1024-character cap', () => {
    for (const { name, description } of index.skills) {
      assert.ok(description.length <= 1024, `${name} description is ${description.length} chars`);
      // The same string is embedded in the SKILL.md frontmatter as a
      // double-quoted YAML scalar, so a quote would break the artifact.
      assert.ok(!description.includes('"'), `${name} description contains a double quote`);
    }
  });

  it('makes every url absolute on this origin, at the artifact path', () => {
    for (const { name, url } of index.skills) {
      assert.ok(url.startsWith(`${ORIGIN}/`), `url is not absolute on the origin: ${url}`);
      assert.equal(url, `${ORIGIN}${skillUrlPath(name)}`);
      assert.equal(new URL(url).pathname, `/.well-known/agent-skills/${name}/SKILL.md`);
    }
  });

  it('formats every digest as sha256 plus 64 lowercase hex characters', () => {
    for (const { name, digest } of index.skills) {
      assert.match(digest, /^sha256:[0-9a-f]{64}$/, `${name} digest is malformed: ${digest}`);
      assert.match(digest, SKILL_DIGEST_PATTERN);
    }
  });
});

describe('digest matches the bytes served at url', () => {
  // The whole point of the index. A client fetches `url`, hashes what it got
  // and compares. If these two ever disagree, every skill we publish is
  // unverifiable and a correct client rejects all of them.
  for (const entry of index.skills) {
    it(`${entry.name}: hashing the served document reproduces the published digest`, () => {
      // Resolve the published URL back to the document the route serves.
      const name = new URL(entry.url).pathname.split('/').at(-2)!;
      assert.equal(name, entry.name, 'url does not encode the entry name');
      const served = skillDocument(name);
      assert.equal(independentDigest(served), entry.digest);
    });
  }

  it('would notice a one-character edit to a skill body', () => {
    // Proves the assertion above is load-bearing rather than trivially true.
    const [first] = index.skills;
    const mutated = `${skillDocument(first.name)} `;
    assert.notEqual(independentDigest(mutated), first.digest);
  });

  it('does not depend on the origin the index was built for', () => {
    // The digest covers the artifact, not the URL that points at it, so a
    // preview deployment publishes the same hashes as production.
    return buildAgentSkillsIndex({ origin: 'https://preview.example' }).then((other) => {
      assert.deepEqual(
        other.skills.map((s) => s.digest),
        index.skills.map((s) => s.digest),
      );
      assert.ok(other.skills.every((s) => s.url.startsWith('https://preview.example/')));
    });
  });

  it('hardcodes no digest anywhere in the module', () => {
    // A written-down hex string is correct exactly once. This is the ratchet
    // that keeps the next editor from pasting one back in.
    const source = readFileSync(new URL('../src/agentic/agent-skills.ts', import.meta.url), 'utf8');
    const literal = source.match(/\b[0-9a-f]{64}\b/);
    assert.equal(literal, null, `found what looks like a hardcoded digest: ${literal?.[0]}`);
  });
});

describe('sha256Hex', () => {
  it('matches the published vector for the empty string', () => {
    // Pins the hex encoding itself: a missing zero-pad would pass a
    // self-comparison and fail here.
    return sha256Hex('').then((hex) => {
      assert.equal(hex, 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855');
    });
  });

  it('agrees with node:crypto on every published document', () => {
    return Promise.all(
      skillNames().map(async (name) => {
        const doc = skillDocument(name);
        assert.equal(`sha256:${await sha256Hex(doc)}`, independentDigest(doc));
      }),
    );
  });
});

describe('skill documents', () => {
  it('publishes every skill in SKILLS, in order', () => {
    // The artifact route's getStaticPaths reads skillNames(), so this is also
    // what guarantees each published url has a route behind it.
    assert.deepEqual(
      index.skills.map((s) => s.name),
      skillNames(),
    );
    assert.equal(SKILLS.length, index.skills.length);
  });

  it('opens with frontmatter naming the same skill the index does', () => {
    for (const entry of index.skills) {
      const doc = skillDocument(entry.name);
      assert.ok(
        doc.startsWith(`---\nname: ${entry.name}\ndescription: "${entry.description}"\n---\n\n`),
        `${entry.name} frontmatter does not match its index entry`,
      );
    }
  });

  it('carries a markdown heading and real content', () => {
    for (const entry of index.skills) {
      const body = skillDocument(entry.name).split('\n---\n\n')[1] ?? '';
      assert.match(body, /^# \S/, `${entry.name} body does not open with a heading`);
      assert.ok(body.length > 500, `${entry.name} body is too thin to be useful`);
    }
  });

  it('stays ASCII, so the bytes cannot depend on an encoding step', () => {
    for (const entry of index.skills) {
      const doc = skillDocument(entry.name);
      // eslint-disable-next-line no-control-regex
      const stray = doc.match(/[^\x09\x0a\x20-\x7e]/);
      assert.equal(stray, null, `${entry.name} contains a non-ASCII character: ${JSON.stringify(stray?.[0])}`);
    }
  });

  it('does not claim the product API answers on this origin', () => {
    // Scope honesty, the same rule openapi.ts and api-catalog.ts hold: the
    // 103-tool MCP server runs inside a self-hosted cc_server, not here.
    const productSkill = skillDocument('control-center-mcp-tools');
    assert.match(productSkill, /does not run on usectrl\.dev/i);
    assert.match(productSkill, /self-host/i);
  });

  it('refuses an unknown skill name', () => {
    assert.throws(() => skillDocument('no-such-skill'), /Unknown skill: no-such-skill/);
  });
});
