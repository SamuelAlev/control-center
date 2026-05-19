// Single source of truth for the changelog. Consumed by the changelog page
// (src/pages/changelog.astro) and the RSS feed (src/pages/rss.xml.ts), so the
// two never drift. `isoDate` drives RSS <pubDate>; `date` is the display string.

export interface ChangeGroup {
  type: 'new' | 'improved' | 'fixed';
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
    id: 'v0-0-1-rc-1',
    version: 'v0.0.1-rc.1',
    date: 'Jun 12, 2026',
    isoDate: '2026-06-12',
    tag: 'Release candidate',
    title: 'Control Center takes off',
    lead: 'The first release candidate ships the whole product at once: a native desktop app for running a fleet of AI coding agents across isolated Git worktrees, reviewing and merging their PRs, and orchestrating the work as pipelines and tickets — with OS-native sandboxing, code-graph and memory search, on-device meeting transcription, and 71 MCP tools, in 7 languages, macOS-first.',
    latest: true,
    showViz: true,
    vizBranch: 'feature/onboarding',
    changes: [
      {
        type: 'new',
        items: [
          "<b>Agent orchestration.</b> Hire, configure, and fire AI agents with custom roles, personas, skills, effort, and monthly budgets; group them into teams; and run many concurrently in isolated sessions across <code>chat</code>, <code>review</code>, and <code>plan</code> conversation modes. Ships built-in role templates (coder, reviewer, QA, security, CEO, and more) and auto-detects installed agent CLIs (Claude Code, Codex, Pi), routing Claude through an in-app relay rather than metered <code>claude -p</code>.",
          "<b>OS-native sandboxing.</b> Agents run under macOS Seatbelt or Linux bubblewrap with filesystem allow-lists and network egress controls, and per-conversation capabilities (git push, GitHub API, ticketing, network) gate credential injection so a token is minted only when you explicitly enable it. Where neither sandbox backend is available, agents run unsandboxed.",
          "<b>Workspace isolation.</b> Workspaces are hard-boundary tenants that auto-seed a CEO agent plus specialists; GitHub repos provision copy-on-write worktrees per conversation via rift FFI (with git-worktree fallback), and every workspace-scoped query is filtered so one tenant's data never surfaces in another.",
          "<b>Code graph and memory.</b> Tree-sitter indexing extracts symbols and edges (calls, imports, extends, implements) incrementally by content hash, with ranked search and dependency traversal across callers, callees, and transitive impact radius. Role-gated long-term memory stores facts (confidence, supersession, attribution) and governance policies across domains, with a read/write/none access matrix per role. Search runs on FTS5 today; the BM25 + vector RRF hybrid is modeled and ready for when embeddings come online.",
          "<b>PR review cockpit.</b> A dense diff viewer with syntax highlighting, commit-range selection, file-tree navigation, and keyboard shortcuts, paired with a decision-lane PR list (ready / review / in-progress / attention / draft). Edit PR metadata in place, post GitHub-synced inline comments with suggestion blocks, and merge via a squash / merge / rebase flyout — or open any PR straight into your editor of choice (Cursor, VS Code, Zed, and more) on its worktree.",
          "<b>AI review and reviewer swarms.</b> Reviews produce P0–P3 findings with priority, confidence, and ship / hold / block verdicts, filterable in accordions with batch dismiss and resolve, and publish to GitHub as a single COMMENT, REQUEST_CHANGES, or APPROVE with anchored inline comments. Non-trivial PRs (≥200 LOC or ≥5 files) fan out specialist reviewers in parallel via the Swarm Protocol.",
          "<b>Pipelines.</b> A drag-and-drop canvas builds DAG templates from trigger, listen, join, router, forEach, and terminal nodes with per-node retry, timeout, and validation. Conditional routing uses predicate trees (fileExists, comparisons, AND/OR/NOT, switch), sub-pipelines nest with parent tracking, and runs persist and resume across restarts. Triggers fire manually, on cron, or on domain events; approval gates, dry-run mode, and per-run cost and token rollups round it out.",
          "<b>Ticketing.</b> Vendor-agnostic tickets with full local CRUD and bidirectional Linear sync, organized into color-coded projects with lifecycle status. Tickets carry hierarchy, relations (blocks / relates-to / duplicate-of), collaborators, and a single-owner execution lock with stale recovery; assigning an agent auto-creates a channel and dispatches. Jira and ClickUp providers are scaffolded for a future release.",
          "<b>Messaging and focus mode.</b> Group channels and DMs with @-mentions, threads, and agent dispatch; agent-posed questions render inline as single-select, multi-select, or free-text forms whose answers route back to the blocked agent. Focus mode adds a standalone timer window with pause/resume and session goals, plus a floating compact pill.",
          "<b>Meetings and calendar.</b> Record meetings with on-device microphone and system-audio capture, live Whisper transcription with silence filtering and hallucination rejection, sherpa-onnx speaker diarization, and echo cancellation (signal-level where the platform supports it, text-level everywhere); an AI summary pipeline produces enhanced notes, decisions, and owner-assigned action items. Google Calendar sync adds multi-account support, RSVP to invitations, month/week/day/agenda views, meeting-starting-soon alerts, and record-and-link. These features are desktop-only and not exposed over MCP.",
          "<b>Dashboard, analytics, and notifications.</b> A live fleet dashboard matches real OS processes to running / blocked / failed state, while analytics surface scorecards, XP and levels, tiered achievements, streaks, leaderboards, and workspace health across activity, throughput, and review quality. Cost tracking enforces soft and hard budget thresholds at agent and workspace scope, and desktop notifications add per-category controls, quiet hours, custom sounds, and an in-app activity feed.",
          "<b>Platform and MCP.</b> 71 typed MCP tools expose the agent, review, pipeline, and ticketing surface to any external client over a JSON-RPC server, with <code>workspace_id</code> required on every workspace-scoped tool. A keyboard-centric shell adds customizable keybindings, a command palette, and VS Code-style when-clauses; secure credentials live in the OS keychain; and a newsfeed reads RSS/Atom with EasyList and uBlock Origin ad-blocking.",
          "<b>Look and reach.</b> Light and dark themes built on 80+ semantic design tokens, reduced-motion alternatives throughout, and full localization in 7 languages — English, German, Spanish, French, Italian, Dutch, and Portuguese. macOS is the shipping platform for this candidate; Windows and Linux are in progress.",
        ],
      },
    ],
    note: 'macOS 13+ · Windows and Linux builds are in progress.',
  },
];
