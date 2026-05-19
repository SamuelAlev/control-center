// Single source of truth for the changelog. Consumed by the changelog page
// (src/pages/changelog.astro) and the RSS feed (src/pages/rss.xml.ts), so the
// two never drift. `isoDate` drives RSS <pubDate>; `date` is the display string.

export interface ChangeGroup {
  type: "new" | "improved" | "fixed";
  /** HTML strings (rendered with set:html) — may contain <b>/<code>. */
  items: string[];
}

export interface Release {
  id: string;
  version: string;
  /** Human-readable date shown on the page. */
  date: string;
  /** ISO-8601 date used for RSS <pubDate> and sorting. */
  isoDate: string;
  tag: string;
  title: string;
  lead: string;
  latest?: boolean;
  showViz?: boolean;
  vizBranch?: string;
  changes: ChangeGroup[];
  note?: string;
}

// Newest first.
export const releases: Release[] = [
  {
    id: "v0-0-1-rc-1",
    version: "v0.0.1-rc.1",
    date: "Sep 10, 2026",
    isoDate: "2026-09-10",
    tag: "Release candidate",
    title: "Control Center takes off",
    lead: "The first release candidate ships the whole product at once: a native desktop app for running a fleet of AI coding agents across isolated Git worktrees, reviewing and merging their PRs and orchestrating the work as pipelines and tickets, with OS-native sandboxing, code-graph and hybrid semantic memory search, on-device meeting transcription, multiplayer for humans and agents and 100+ MCP tools, in 7 languages — on macOS, Windows and Linux, with web and phone companions over one self-hosted cc_server.",
    latest: true,
    showViz: true,
    vizBranch: "feature/onboarding",
    changes: [
      {
        type: "new",
        items: [
          "<b>Agent orchestration.</b> Hire, configure and fire AI agents with custom roles, personas, skills, effort and monthly budgets; group them into teams; and run many concurrently in isolated sessions across <code>chat</code>, <code>review</code> and <code>plan</code> modes. One agent loop, eight runners: a built-in pure-Dart runtime (streaming, tool calls, compaction, steering, subagents) that needs no external CLI, plus adapters for Claude Code, Codex, Pi, OpenCode, Gemini CLI, Goose and Cursor; any OpenAI- or Anthropic-compatible endpoint joins as a custom provider. Claude routes through an in-app relay rather than metered <code>claude -p</code>.",
          "<b>Enclosures (rigs).</b> Agents can open a disposable VM to actually test in — a headless browser, a Linux desktop or an Android device — and drive it with <code>computer_use</code>, <code>browser_use</code> and <code>mobile_use</code>. You watch the machine live at full resolution sized to your panel while the agent works from its own cheap downscaled frames, and you can take the controls at any moment: the agent keeps observing but cannot type or click until you hand back, and every input event is recorded against whoever sent it. The space and PR terminals run inside one too, so shell work stops happening on your machine. A rig has a deny-by-default network, no stored credentials (<code>git push</code> asks the host for a short-lived token per operation), a disk that is discarded when it closes and a lifetime it cannot extend. The browser and terminal machines boot digest-pinned images fetched on first use and cached as pre-extracted packs, so repeat boots take seconds with the tooling already installed; a workspace can point either at its own image. The Android surface drives Google&rsquo;s emulator, so it asks you to install their SDK and tells you which step is missing rather than offering a download that cannot exist.",
          "<b>Ports out of the VM.</b> Start a dev server inside an enclosed terminal and the plug icon lights up: every listening port is discovered with its process name and forwarded automatically — to <code>localhost</code> on your machine, to <code>localhost</code> inside the conversation&rsquo;s Browser (VM) so an agent can test what you just started, optionally to your network at a deliberate random port, and optionally under a dev domain where <code>https://myapp.test</code> opens in the enclosed browser with a valid padlock, served by a certificate authority minted on your own server whose keys never enter any guest.",
          "<b>OS-native sandboxing.</b> Agents run under macOS Seatbelt or Linux bubblewrap with filesystem allow-lists and network egress controls and per-space capabilities (git push, GitHub API, ticketing, network) gate credential injection so a token is minted only when you explicitly enable it. Where neither sandbox backend is available, agents run unsandboxed.",
          "<b>Workspace isolation.</b> Workspaces are hard-boundary tenants that auto-seed a CEO agent plus specialists; registered repos provision copy-on-write worktrees per space via rift FFI (with git-worktree fallback) and every workspace-scoped query is filtered so one tenant's data never surfaces in another.",
          "<b>Code graph and memory.</b> Tree-sitter indexing extracts symbols and edges (calls, imports, extends, implements) incrementally by content hash, with ranked search and dependency traversal across callers, callees and transitive impact radius. Role-gated long-term memory stores facts (confidence, supersession, attribution) and governance policies across domains, with a read/write/none access matrix per role. Semantic search runs live: on-device ONNX embeddings (384-dim, nothing leaves the machine) drive hybrid BM25 + vector RRF over memory facts and code symbols alike.",
          "<b>GitHub, GitLab and Bitbucket.</b> A repo carries the forge it lives on, read from its <code>origin</code> remote, so one workspace can mix all three. The inbox and PR queue fan out across every connected host and merge the results into one stream, resolving your identity per forge — you are a different account on each. A host that is down or unconnected contributes nothing and leaves the others untouched. Where forges genuinely differ (stacked PRs, synced viewed-state, batched reviews) the app hides what a host cannot do rather than offering a control that silently fails.",
          "<b>PR review cockpit.</b> A dense diff viewer with syntax highlighting, commit-range selection, file-tree navigation and keyboard shortcuts, paired with a decision-lane PR list (ready / review / in-progress / attention / draft). Edit PR metadata in place, post forge-synced inline comments with suggestion blocks and merge via a squash / merge / rebase flyout, or open any PR straight into your editor of choice (Cursor, VS Code, Zed and more) on its worktree.",
          "<b>AI review and reviewer swarms.</b> Reviews produce P0-P3 findings with priority, confidence and ship / hold / block verdicts, filterable in accordions with batch dismiss and resolve and publish back to the forge as a single comment, request-changes or approve with anchored inline comments. Non-trivial PRs (≥200 LOC or ≥5 files) fan out specialist reviewers in parallel via the Swarm Protocol.",
          "<b>Pipelines.</b> A drag-and-drop canvas builds DAG templates from trigger, listen, join, router, forEach and terminal nodes with per-node retry, timeout and validation. Conditional routing uses predicate trees (fileExists, comparisons and/OR/NOT, switch), sub-pipelines nest with parent tracking and runs persist and resume across restarts. Triggers fire manually, on cron, or on domain events; approval gates, dry-run mode and per-run cost and token rollups round it out.",
          "<b>Ticketing.</b> Vendor-agnostic tickets with full local CRUD and bidirectional Linear sync, organized into color-coded projects with lifecycle status. Tickets carry hierarchy, relations (blocks / relates-to / duplicate-of), collaborators and a single-owner execution lock with stale recovery; assigning an agent auto-creates a space and dispatches. Jira and ClickUp providers are scaffolded for a future release.",
          "<b>Messaging and focus mode.</b> Spaces with @-mentions, threads and agent dispatch; agent-posed questions render inline as single-select, multi-select, or free-text forms whose answers route back to the blocked agent. Focus mode adds a standalone timer window with pause/resume and session goals, plus a floating compact pill.",
          "<b>Meetings and calendar.</b> Record meetings with on-device microphone and system-audio capture, live Whisper transcription with silence filtering and hallucination rejection, sherpa-onnx speaker diarization and echo cancellation (signal-level where the platform supports it, text-level everywhere); an AI summary pipeline produces enhanced notes, decisions and owner-assigned action items. Google Calendar sync adds multi-account support, RSVP to invitations, month/week/day/agenda views, meeting-starting-soon alerts and record-and-link. These features are desktop-only and not exposed over MCP.",
          "<b>Dashboard, analytics and notifications.</b> A live fleet dashboard matches real OS processes to running / blocked / failed state, while analytics surface scorecards, XP and levels, tiered achievements, streaks, leaderboards and workspace health across activity, throughput and review quality. Cost tracking enforces soft and hard budget thresholds at agent and workspace scope and desktop notifications add per-category controls, quiet hours, custom sounds and an in-app activity feed.",
          "<b>Platform and MCP.</b> 100+ typed MCP tools expose the agent, review, pipeline and ticketing surface to any external client over a JSON-RPC server, with <code>workspace_id</code> required on every workspace-scoped tool; an MCP client bridges external MCP servers into the same registry. A keyboard-centric shell adds customizable keybindings, a command palette and VS Code-style when-clauses; secure credentials live in the OS keychain; and a per-user newsfeed reads RSS/Atom with EasyList and uBlock Origin ad-blocking, with feeds, read state and bookmarks following you across workspaces and devices.",
          "<b>Multiplayer identity and presence.</b> Every actor is a Principal — a user or an agent — with workspace membership at owner, admin, member, viewer or guest, per-repo grants and invite-based onboarding. Presence is a separate ephemeral lane (status, locus, cursor, typing) that is never persisted. Follow mode — including watching an agent work from your seat — plus steer, interrupt, take over and hand back. Revocation is live: a removed member's sessions drop within seconds.",
          "<b>Autonomy dial and unified guardrails.</b> Every space carries a named autonomy profile — propose-only, act-with-approval or act-freely — over one policy store covering ~12 action classes (git push, PR create, network egress, secret access, package install, …). Resolution is most-specific-scope-wins (space > agent > workspace > mode preset) and a prompt with no approver connected is denied, fail-closed.",
          "<b>Agent-to-agent collaboration.</b> Agents talk over the same durable spaces you do — never a separate bus — with <code>send_to_agent</code>, <code>ask_agent</code> (request/reply with a mandatory timeout and pairwise cycle detection), <code>delegate_task</code> (child tickets guarded by depth cap, cycle detection, budget-envelope inheritance and an autonomy ceiling) and <code>todo_read</code>. Agent-to-agent spaces are muted by default and never bump your unread badge.",
          "<b>Unified inbox and ⌘K omnibox.</b> One inbox across every pillar — tickets waiting, PRs to review, agent questions, approvals, pipeline failures — with a command palette over it all. Nothing essential lives a level deep.",
          "<b>Plan Studio.</b> Editable DAG plans replace static proposals: orchestration graphs and plan documents carry revisions, approvals and execution state, and a plan node can delegate straight into a ticket.",
          "<b>Headless server, thin clients.</b> All state, database access, external APIs and execution live in one pure-Dart <code>cc_server</code> binary; desktop, web and phone are renderers. Each workspace's rows live in its own SQLite file (isolation is structural, not a WHERE clause), a workspace exports and imports as a single file, and backups run on a schedule.",
          "<b>Fleet workers.</b> A headless <code>cc_worker</code> binary pairs with your server, declares capabilities, heartbeats, pulls leased jobs and streams process events back — holding no durable state of its own. One authoritative server, N dumb limbs; a solo desktop stays byte-identical.",
          "<b>Phone companion.</b> <code>cc_remote</code> is an installable PWA at remote.usectrl.dev that remote-controls your operation over a sealed relay: check the fleet, answer an agent, approve a pipeline step — from anywhere.",
          "<b>Skills with supply-chain scanning.</b> Skills pass a fail-closed gate between fetch and write: no content reaches disk or an agent prompt without a verdict (pass / warn / quarantine). Static rules and the capability manifest are the mandatory layers, LLM review is additive, and trust tiers are provenance metadata — never a scan substitute. Bytes scanned are the bytes written, hash-locked.",
          "<b>Evals and session review.</b> Golden sessions, eval suites and eval runs put an agent's changes on rails: replay a session, score it against goldens and pin regressions before they ship. Session recordings capture what actually happened.",
          "<b>Mermaid, natively.</b> The in-repo markdown engine draws flowcharts, state, class, ER, sequence, pie and timeline diagrams itself — pure Dart layout and paint, no WebView, no JS. Unsupported dialects degrade to a code block; the engine never throws.",
          "<b>Look and reach.</b> Light and dark themes built on 80+ semantic design tokens, reduced-motion alternatives throughout and full localization in 7 languages: English, German, Spanish, French, Italian, Dutch and Portuguese. Signed and notarized desktop apps ship together for macOS, Windows and Linux with auto-updates, plus a web app and a phone companion over the same server.",
        ],
      },
    ],
    note:
      "macOS 13+ · Windows 10+ · Linux x86_64 · web and phone companions · headless cc_server on all three platforms plus Docker images on GHCR.",
  },
];
