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
    id: "v0-0-11",
    version: "v0.0.11",
    date: "Oct 27, 2026",
    isoDate: "2026-10-27",
    tag: "Patch release",
    title: "The phone app grows up",
    lead: "The phone app can now manage conversations, spaces, runs, plans, tickets, permissions and pull request discussions, and it sends background notifications. On desktop, agent runs wait for an expired Claude sign-in instead of failing, approved plans run reliably, and opening spaces is smoother.",
    latest: true,
    note: "The phone app is the installed web app (PWA). Background notifications use Web Push through FCM, Mozilla or Apple push services. Background decryption of server traffic applies to the desktop app; the web and phone apps still decrypt inline. Host-side SSH commit signing for sandboxed agents is macOS only. Building cc_server from source now requires CMake on <code>PATH</code>.",
    changes: [
      {
        type: "new",
        items: [
          "<b>Phone conversations.</b> Browse, create, rename, archive and restore conversations and threads, search and page through history, and copy links to a message. Text and attachment drafts are kept for each conversation, and failed uploads can be retried or removed.",
          "<b>Phone runs and progress.</b> A Progress view shows the conversation goal, editable tasks, agent runs with cost and health, context usage and recent outputs. Stop, retry, pause and resume runs, and edit, reorder or steer queued messages.",
          "<b>Phone spaces and work.</b> Create and manage spaces with their people, agents, linked repositories, base branch and mode. Create and edit tickets, discuss pull requests in inline review threads, review, approve, reject or stop plans, and start supervised goals within cost caps.",
          "<b>Phone inbox and permissions.</b> Activity history with read state, plus inbox lanes for questions, approvals and credentials that block runs. See effective allow, ask and deny rules; workspace admins can edit rules, view history and verify the audit chain.",
          "<b>Phone connections and notifications.</b> Connect personal forge and Linear accounts, and, as the server owner, model-provider keys. Background notifications have categories and a quiet mode, show only &ldquo;Control Center&rdquo; and open the inbox or space when tapped.",
          "Pull request diffs on the phone are syntax-highlighted with the desktop themes. The highlighter loads only when you open the first diff.",
          "When a Claude sign-in expires, the turn shows a sign-in notice instead of a raw error. A sign-in dialog lists each affected account with its status and a copyable <code>claude auth login</code> command.",
          "On macOS, sandboxed agents can create SSH-signed commits, including with 1Password, when your global Git configuration signs with SSH. Signing happens on the host and only for the server owner&rsquo;s runs.",
          "A plan whose run failed can be approved again, which rebuilds the run from the plan.",
          "Opening or switching to a chat tab places the cursor in the message box.",
        ],
      },
      {
        type: "improved",
        items: [
          "If a Claude sign-in expires partway through a turn, the run waits for you to sign in again and then continues. Retrying no longer replays the prompt and repeats the work.",
          "Each step of an approved plan runs in its own conversation in the space.",
          "Approving a pushing shell command also covers that run&rsquo;s follow-up push check for 15 minutes, limited to the branches the command named; deny rules still apply. Push approvals can be remembered for a limited time when the destination branch is known, and a push to several branches lists every branch.",
          "The desktop app decrypts server traffic in the background, so opening spaces and loading media no longer blocks the interface.",
          "Code blocks in a language seen for the first time render plain for a moment instead of freezing the interface while highlighting loads.",
          "Launching with a saved server opens straight into the main window. Switching servers keeps the window&rsquo;s position, size and full-screen state.",
          "Images an agent reads appear inline in the transcript and open in an editor tab beside the chat.",
          "Transcript error rows show up to three lines, and stacks of linked pull requests start collapsed.",
          "On the phone, all six tabs fit a 320&nbsp;px screen in both reading directions, content stays above the on-screen keyboard, and the language setting is a single select that includes the system language.",
          "Saving or removing model-provider keys, custom providers, model overrides and provider sign-ins now requires the server owner.",
          "The notification feed only shows items for repositories and spaces you can access.",
          "Updated the built-in code editor (code-server 4.143.1), speech recognition (sherpa-onnx 2.0) and the PDF viewer engine (PDFium 158).",
        ],
      },
      {
        type: "fixed",
        items: [
          "Sandboxed Claude Code accounts on macOS are no longer signed out about once a day when a token refresh was lost.",
          "Approving a plan no longer leaves the space stuck in read-only plan mode, and its steps no longer fail with &ldquo;no conversation to work in&rdquo;.",
          "Plan steps that wait on several earlier steps no longer run twice, plan summaries report failed steps, and plan drift detection works.",
          "Replying to a pending plan stores the message once, keeps its attachments and refines the plan in that conversation.",
          "A permission request appears only in the conversation that asked for it, opens that tab from the inbox and stays in the floating approval panel while the tab is in the background.",
          "Remote connections no longer reconnect repeatedly under heavy update traffic.",
          "On macOS, new main, setup and error windows no longer appear invisible or black at launch.",
          "Opening a conversation with highlighted code no longer makes the sidebar stutter.",
          "In multi-select dropdowns, Enter and Space toggle the highlighted row.",
          "Dragging the focus, meeting or soundscape window moves that window instead of the main one.",
          "Answers to agent questions are validated, the first answer wins, and the phone&rsquo;s &ldquo;Needs your input&rdquo; ignores questions whose agent is no longer waiting.",
          "Reopening a pairing link that matches the saved pairing reconnects without asking again.",
          "New audit decisions are hashed at the timestamp precision SQLite stores, so a chain verifies immediately after it is written. Chains still report a break at the first decision written before this release; those hashes are not rewritten.",
          "On the phone, notification permission is requested directly from the Enable button and never prompts again after being denied. Sent images load and open in a zoomable viewer with a retry option.",
        ],
      },
    ],
  },
  {
    id: "v0-0-10",
    version: "v0.0.10",
    date: "Oct 16, 2026",
    isoDate: "2026-10-16",
    tag: "Patch release",
    title: "Restore conversations and see server progress",
    lead: "Browse and restore archived conversations, choose your language before signing in and track server startup and model downloads. This update also fixes macOS startup and reconnecting to saved servers.",
    changes: [
      {
        type: "new",
        items: [
          "Browse archived conversations in a space and restore them directly into an active tab.",
          "Choose your language from the login and onboarding screens without opening settings.",
          "A floating activity panel shows server startup, connection progress and model downloads, with error details and retry actions where available.",
        ],
      },
      {
        type: "improved",
        items: [
          "Desktop update checks now run on login and server setup screens as well as inside the app.",
        ],
      },
      {
        type: "fixed",
        items: [
          "Fixed a macOS startup crash and unintended exits when replacing the setup window or switching servers.",
          "Reconnect to a saved server using its stored device credentials without entering a new pairing code.",
          "Closed and merged pull requests show their final status even when they retain a draft flag.",
        ],
      },
    ],
  },
  {
    id: "v0-0-9",
    version: "v0.0.9",
    date: "Oct 16, 2026",
    isoDate: "2026-10-16",
    tag: "Patch release",
    title: "Faster space switching and clearer approvals",
    lead: "This update expands the command palette, keeps space editors warm and improves conversation rendering. It also fixes Claude Code token refresh and commit authorship.",
    changes: [
      {
        type: "improved",
        items: [
          "Search and open spaces, conversations and settings from the command palette.",
          "Space editors stay warm to reduce reloads when switching between conversations.",
          "Updated conversation sidebars, message rendering and built-in harness guidance and skills.",
          "Follow mode now targets human users only; agent following has been removed.",
        ],
      },
      {
        type: "fixed",
        items: [
          "Approval prompts and agent questions render Markdown consistently on desktop and phone.",
          "Claude Code accounts can refresh authentication tokens inside the sandbox.",
          "Agent commits use the connected user's identity rather than the bot as their author.",
          "GitHub device sign-in closes after approval and updates the connected account without a second login, even if the code dialog was closed.",
          "Fixed Windows PDF renderer builds.",
        ],
      },
    ],
  },
  {
    id: "v0-0-1",
    version: "v0.0.1",
    date: "Sep 10, 2026",
    isoDate: "2026-09-10",
    tag: "Release candidate",
    title: "Control Center takes off",
    lead: "The first release candidate ships the whole product at once: a native desktop app for running a fleet of AI coding agents across isolated Git worktrees, reviewing and merging their PRs and orchestrating the work as pipelines and tickets, with OS-native sandboxing, code-graph and hybrid semantic memory search, on-device meeting transcription, multiplayer for humans and agents and 100+ MCP tools, in 7 languages — on macOS, Windows and Linux, with web and phone companions over one self-hosted cc_server.",
    showViz: true,
    vizBranch: "feature/onboarding",
    changes: [
      {
        type: "new",
        items: [
          "<b>Agent orchestration.</b> Hire, configure and fire AI agents with custom roles, personas, skills, effort and monthly budgets; group them into teams; and run many concurrently in isolated sessions across <code>chat</code>, <code>review</code> and <code>plan</code> modes. One agent loop, two runners: a built-in pure-Dart runtime (streaming, tool calls, compaction, steering, subagents) that needs no external CLI, plus a Claude Code adapter for an existing Claude Code plan. Codex, Cursor and the other model providers attach to the built-in loop; any OpenAI- or Anthropic-compatible endpoint joins as a custom provider.",
          "<b>Enclosures (rigs).</b> Agents can open a disposable machine to test in — a headless browser, Linux desktop, Android emulator or iOS Simulator — and drive it with <code>computer_use</code>, <code>browser_use</code>, <code>mobile_use</code> and <code>ios_use</code>. You watch live at full resolution while the agent uses a separate downscaled image lane, can take control at any moment, and every input is attributed. VM-backed rigs keep deny-by-default networking, short-lived brokered credentials and throwaway disks. Android and iOS are explicit host-managed exceptions: their emulator devices are disposable, but networking follows the server host. iOS rigs create and delete a CoreSimulator device per session and install or launch simulator app bundles through a checksum-pinned WebDriverAgent bridge.",
          "<b>Ports out of the VM.</b> Start a dev server inside an enclosed terminal and the plug icon lights up: every listening port is discovered with its process name and forwarded automatically — to <code>localhost</code> on your machine, to <code>localhost</code> inside the conversation&rsquo;s Browser (VM) so an agent can test what you just started, optionally to your network at a deliberate random port, and optionally under a dev domain where <code>https://myapp.test</code> opens in the enclosed browser with a valid padlock, served by a certificate authority minted on your own server whose keys never enter any guest.",
          "<b>OS-native sandboxing.</b> Agents run under macOS Seatbelt or Linux bubblewrap with filesystem allow-lists and network egress controls and per-space capabilities (git push, GitHub API, ticketing, network) gate credential injection so a token is minted only when you explicitly enable it. Where neither sandbox backend is available, agents run unsandboxed.",
          "<b>Workspace isolation.</b> Workspaces are hard-boundary tenants that auto-seed a CEO agent plus specialists; registered repos provision copy-on-write worktrees per space via rift FFI (<code>git worktree</code> is the backend on Windows, where there is no CoW native) and every workspace-scoped query is filtered so one tenant's data never surfaces in another.",
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
          "<b>Autonomy dial and unified guardrails.</b> Every space carries a named autonomy profile — propose-only, act-with-approval or act-freely — over one policy store covering 13 action classes (git push, PR create, network egress, secret access, package install, …). Resolution is most-specific-scope-wins (space > agent > workspace > mode preset) and a prompt with no approver connected is denied, fail-closed.",
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
