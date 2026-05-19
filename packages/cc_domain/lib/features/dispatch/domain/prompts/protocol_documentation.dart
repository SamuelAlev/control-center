/// Documentation of the harness `read` tool and the specialized MCP tools that
/// replaced the old unified protocol-URL `read` MCP tool. Injected into every
/// agent's system prompt.
const String resourceProtocolDocumentation = '''
## Reading files and resources

### Workspace files — harness `read`

`read` is a built-in harness tool (not an MCP tool). It reads a file from your
working directory / workspace and returns line-numbered content.

  read(path: "lib/foo.dart")              — whole file (capped)
  read(path: "lib/foo.dart", offset: 50, limit: 100)
  read(path: "lib/foo.dart", sel: "50-200")   — line range
  read(path: "lib/foo.dart", sel: "50+150")   — 150 lines from line 50

If the path is missing, `read` fuzzy-searches the workspace and suggests
the closest matches. Use `search_files` when you only remember part of a name,
`find` for exact globs and `search` for content greps.

### Specialized MCP tools (by resource)

  list_artifacts(workspace_id: "…")              — artifacts published here
  get_artifact(workspace_id: "…", work_product_id: "…")
                                                 — one artifact: typed blocks
                                                   plus a readable text render
  list_pull_requests(workspace_id: "…")          — PR list / metadata
  list_skills(workspace_id: "…")                 — skill catalog
  search_memory(workspace_id: "…", query: "…")   — workspace memory
  list_policies(workspace_id: "…")               — memory policies
  list_memory_domains(workspace_id: "…")         — memory domains
  get_agent_run_logs(…)                          — agent run output
  get_channel_messages / get_channel_notes       — conversation state
  search_code / code_symbol / code_callers / …   — code index (prefer over grep)

For a PR that is checked out into a local worktree, read the files and run
`git diff` / `git show` via `bash` in that worktree.
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
  Prefer `search_files` (fuzzy name) / `find` (glob) / `search` (content) / `read`
  over shell `find`/`grep`/`cat`.
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
`0.6`-`0.9` for solid inference; below `0.6`, prefer `record_observation` (a
private note) over a shared fact. When reality contradicts an existing fact,
`supersede_fact` it — never add a conflicting duplicate.

Always call `list_memory_domains` first so you reuse an existing domain instead of
inventing one.

### When NOT to save

- Transient questions or chitchat
- Hypotheticals or "what if" scenarios
- Information already stored — search first with `search_memory`
''';
