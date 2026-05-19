// Site-wide constants and the canonical product overview. Single source for
// the landing markdown twin, llms.txt, llms-full.txt and the MCP page index,
// so every agent-facing surface describes the product identically.

export const SITE_NAME = 'Control Center';
export const REPO_URL = 'https://github.com/SamuelAlev/control-center';
export const ISSUES_URL = `${REPO_URL}/issues`;

export const OVERVIEW = `Control Center is a free and open-source (MIT) developer operations deck, self-hosted first.

- Platforms: native desktop apps for macOS (Apple Silicon, signed/notarized), Windows and Linux with auto-updates; web app; installable phone companion (remote.usectrl.dev). Every client is a thin renderer over one headless cc_server binary you run (macOS/Linux/Windows, plus Docker images on GHCR) — the server owns the database, external APIs and execution.
- Agents: a built-in pure-Dart agent runtime (streaming, tool calls, compaction, steering, subagents) plus adapters for Claude Code, Codex, Pi, OpenCode, Gemini CLI, Goose and Cursor. Any OpenAI- or Anthropic-compatible endpoint joins as a custom provider; runners can be mixed in one fleet.
- Isolation and safety: every channel runs in its own copy-on-write Git worktree inside an OS-native sandbox (macOS Seatbelt, Linux bubblewrap); credentials are minted per launch, capability-gated and revoked on teardown. A unified guardrail store covers ~12 action classes with a per-channel autonomy dial (propose-only / act-with-approval / act-freely); unattended approval prompts fail closed.
- The operation around the fleet: PR review cockpit with AI reviewers (P0-P3 findings, ship/hold/block verdicts) across GitHub, GitLab and Bitbucket, merged into one inbox; vendor-agnostic tickets with bidirectional Linear sync (Jira and ClickUp scaffolded); DAG pipelines with manual, cron and domain-event triggers, resumable runs and approval gates; on-device meeting transcription with diarization and summaries; Google Calendar; per-user RSS/Atom newsfeed with ad blocking.
- Knowledge: long-term memory with role-gated access policies, and a tree-sitter code graph (symbols, callers/callees, impact radius) with hybrid BM25 + vector semantic search computed by an on-device embedding model.
- Multiplayer: humans and agents are co-equal members with workspace roles (owner/admin/member/viewer/guest), per-repo grants, presence, follow mode, steer/take-over/hand-back and live revocation. Agents collaborate over durable channels (send_to_agent, ask_agent, delegate_task with budget inheritance and autonomy ceilings).
- Tool surface: 100+ typed MCP tools over JSON-RPC, every workspace-scoped tool requiring its workspace_id; an MCP client bridges external MCP servers into the same registry.
- Source: https://github.com/SamuelAlev/control-center`;
