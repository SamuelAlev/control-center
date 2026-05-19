/// Documentation of the `read` MCP tool's protocol URLs (pr://, issue://,
/// skill://, memory://, …) injected into every agent's system prompt.
const String resourceProtocolDocumentation = '''
## Resource Reading

The `read` MCP tool is your single interface to all resources. It is NOT a shell
command like `cat` — you call it as an MCP tool passing a protocol URL as `path`.
NEVER construct raw GitHub API URLs (api.github.com), raw filesystem paths, or
HTTP requests for resources that have a protocol scheme.

### GitHub resources (no workspace_id needed)

  read(path: "pr://owner/repo/N")                — full PR: metadata, description, check runs, reviews, comments
  read(path: "pr://owner/repo/N?comments=0")     — PR without comments (faster — use when you only need metadata)
  read(path: "pr://owner/repo/N/diff")           — numbered file list only (compact)
  read(path: "pr://owner/repo/N/diff/all")       — full unified diff of all files
  read(path: "pr://owner/repo/N/diff/N")         — diff of the Nth file only (1-indexed)
  read(path: "issue://owner/repo/N")             — GitHub issue with all comments
  read(path: "gh://owner/repo/blob/<ref>/<path>") — raw file content at a branch, tag, or commit SHA

### Workspace-scoped resources (REQUIRE workspace_id)

  read(path: "skill://<name>", workspace_id: "<ws-id>")    — read a skill's SKILL.md
  read(path: "rule://<name>", workspace_id: "<ws-id>")     — read memory policies by domain
  read(path: "local://<name>.md", workspace_id: "<ws-id>") — read a plan artifact from this workspace
  read(path: "memory://root", workspace_id: "<ws-id>")     — compact summary (fact/policy counts, topics, domains)
  read(path: "memory://root/MEMORY.md", workspace_id: "<ws-id>") — full curated memory index
  read(path: "memory://root/skills/<slug>/SKILL.md", workspace_id: "<ws-id>") — a specific skill file
  read(path: "memory://root/policies/<domain>", workspace_id: "<ws-id>") — policies for a domain
  read(path: "memory://root/agents/<agentId>", workspace_id: "<ws-id>") — agent's private working memory

### Agent artifacts (no workspace_id needed)

  read(path: "agent://<id>")                     — full agent output (run log ID or agent ID; agent ID returns latest completed run)
  read(path: "agent://<id>/<json-path>")         — JSON field extraction (e.g. "agent://reviewer_0/findings/0/path")
  read(path: "artifact://<id>")                  — raw captured artifact by numeric ID (log, trace)
  read(path: "mcp://<uri>")                      — list MCP tools matching the URI (empty or * returns all)

### Common mistakes — NEVER do these

  - NEVER forget workspace_id on skill://, rule://, local://, memory:// — they will error without it.
  - NEVER use issue:// for PRs — use pr:// for PRs and issue:// for issues.
  - NEVER use pr:// without owner/repo (e.g. "pr://42") — always include owner/repo/N.
  - NEVER omit /blob/ in gh:// URLs — the format is gh://owner/repo/blob/<ref>/<path>.
  - NEVER construct raw GitHub API URLs (api.github.com) — use pr://, issue://, gh:// instead.
  - Use ?comments=0 on pr:// URLs when you only need metadata or diffs (skips slow API calls).
  - Use /diff for a quick file list, /diff/all for the full diff, /diff/N for a single file.
  - file:// is not yet implemented — use local:// instead for workspace files.
''';

/// Standing instruction telling agents to prefer the indexed code graph and
/// workspace memory over grepping/reading files by hand. Injected in every mode.
const String searchDisciplineInstructions = '''
## Search discipline — consult the index before brute force

This workspace keeps a live **code index** and a curated **memory**. They are almost
always faster and more complete than reading or grepping files by hand. Reach for
them FIRST; fall back to manual file exploration only when they come up empty.

- **Code questions** ("where is X defined?", "what calls Y?", "what breaks if I
  change Z?"): use the code tools instead of grep/glob. Call `list_repos` (filtered by
  your workspace_id) to get the `repo_id`, then `search_code` for ranked symbol hits,
  `code_symbol` for an exact name, `code_callers`/`code_callees` to walk the call
  graph, and `code_impact` to gauge blast radius before an edit. These return file:line
  and the dependency graph in one call — grep misses callers and semantic matches.
- **Project / domain / decision questions** ("how does auth work here?", "what did we
  decide about X?", "what are the conventions?"): call `search_memory` first. The
  answer is often already recorded, which saves re-deriving it from source.
- **Fall back to raw file reads or grep only** when the index has no answer — e.g.
  brand-new code not yet indexed, or content outside tracked symbols (config, docs).
''';

/// Behavioural guidance pushing agents to contribute durable knowledge to
/// shared memory proactively. Injected only in chat mode, where the memory-write
/// tools are available (review/plan modes are read-only).
const String memoryManagementInstructions = '''
### Memory Management

You have persistent, shared workspace memory — treat it as your team's long-term
brain. Using it well is not optional: it is how knowledge survives across runs and
agents. Consult it before you start, and feed it as you learn.

### Contribute proactively — do not wait to be asked

The moment you learn something durable, save it:

- **A fact about the project, domain, team, tools, or a user preference** —
  `propose_fact`. Save it whether or not anyone asked you to remember it.
- **A recurring constraint, coding standard, or decision** — save it as a fact and,
  when it is normative, promote it to a policy with `propose_policy`.
- **Something you worked out mid-task** — `record_observation` for private notes;
  promote the important ones to shared facts once confirmed.

### Fact vs policy

- A **fact** is descriptive — it states what is true now and may change later
  (e.g. "CI runs on Node 20", "the auth service lives in `services/auth`").
- A **policy** is normative — a rule that constrains future behaviour. Rule of
  thumb: *if violating it should fail a review, it is a policy.* Save it with
  `propose_policy` and cite the `source_fact_ids` it was distilled from
  (e.g. "every new endpoint MUST validate workspace_id").
- When `search_memory` shows a domain with several facts and no policy and a
  normative rule has emerged, write the policy — do not leave it implicit.

### Confidence

Pass a `confidence` with each fact: `1.0` only for things you directly verified;
`0.6`–`0.9` for solid inference; below `0.6`, prefer `record_observation` (a
private note) over a shared fact. When reality contradicts an existing fact,
`supersede_fact` it — never add a conflicting duplicate.

Always call `list_memory_domains` first so you reuse an existing domain instead of
inventing one.

### When NOT to save

- Transient questions or chitchat
- Hypotheticals or "what if" scenarios
- Information already stored — search first with `search_memory` or `read(path: "memory://root", workspace_id: "<ws-id>")`
''';
