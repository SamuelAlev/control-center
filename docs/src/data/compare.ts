// Comparison data for /compare/. Single source of truth for two consumers:
// the compare page (matrix + per-tool sections) and llms-full.txt (rendered
// as a markdown table).
//
// Factual accuracy rules: every cell is backed by what the product's own site
// or repo publicly claims (re-checked September 27, 2026). 'partial' means
// the capability exists in a narrower form than this column's full scope —
// the per-tool `notes` explain exactly how. When a product simply doesn't
// document a capability, it gets 'no' rather than a guess. Re-verify before
// editing cells; stale comparison tables are worse than none.
//
// `price` is the vendor's own published entry price, followed by the cheapest
// paid tier when one exists. Model usage may use a separate provider key or
// subscription, or come with a paid plan; no single billing rule fits all tools.

export type CellValue = 'yes' | 'partial' | 'no';

export interface CompareColumn {
  id: string;
  /** Short label for the matrix header. */
  label: string;
}

export interface CompareTool {
  id: string;
  name: string;
  /** Primary source link — the product's own site. */
  url: string;
  /** One-line category, shown under the name. */
  kind: string;
  /** Entry price, then the cheapest paid tier. Short — it renders in a cell. */
  price: string;
  /** 2–3 sentences: what it is, what it's genuinely best at. */
  blurb: string;
  /** "Pick it if …" — the honest case for the competitor. */
  bestFor: string;
  /** Direct answer for the vs-page H1 question, first sentence standalone. */
  verdict?: string;
  /** Where Control Center pulls ahead, for the vs-page. */
  ccEdge?: string;
  cells: Record<string, CellValue>;
  /**
   * Why a given cell is `partial`, keyed by column id — one sentence, read as
   * the continuation of "Partial — ". This is the ONLY place that explanation
   * lives: the hover/focus tooltip and the screen-reader label are both built
   * from it, so a sighted mouse user and a screen-reader user get the same
   * sentence. Every `partial` cell must carry one; `compare.test.ts` fails the
   * build otherwise, because an unexplained ≈ is worse than no cell at all.
   */
  notes?: Record<string, string>;
  /** Nuances and platform caveats for the comparison. */
  footnote?: string;
}

/**
 * The accessible name for one cell. Cells are glyphs (✓ ≈ —), which carry no
 * text for assistive tech, so every cell renders this alongside as visually
 * hidden text. Kept next to the data so the wording can't drift per page.
 */
export function cellLabel(tool: CompareTool, columnId: string): string {
  const value = tool.cells[columnId];
  if (value === 'yes') return 'Yes';
  if (value === 'no') return 'Not offered';
  const note = tool.notes?.[columnId];
  return note ? `Partial — ${note}` : 'Partial';
}

export const columns: CompareColumn[] = [
  { id: 'openSource', label: 'Free & open source' },
  { id: 'desktop', label: 'Native desktop · mac / win / linux' },
  { id: 'phone', label: 'Phone companion' },
  { id: 'server', label: 'Self-hosted headless server' },
  { id: 'worktrees', label: 'Parallel worktree isolation' },
  // Review=yes requires a linked-repo PR inbox independent of agent chats
  // and worktrees, with in-app review and merge.
  { id: 'review', label: 'Repo-wide PR inbox & merge' },
  { id: 'pipelines', label: 'Pipelines & scheduled triggers' },
  { id: 'meetings', label: 'Meetings & calendar' },
  { id: 'teams', label: 'Multi-user teams' },
];

export const tools: CompareTool[] = [
  {
    id: 'control-center',
    name: 'Control Center',
    url: 'https://usectrl.dev/',
    kind: 'Developer operations deck',
    price: 'Free · self-hosted',
    blurb:
      'One native app for the whole operation: a fleet of agents (built-in runtime plus a Claude Code adapter) across isolated worktrees (copy-on-write where supported), a PR inbox covering open PRs across linked repos regardless of who created them, tickets with Linear sync, DAG pipelines, meetings, calendar, memory and a code graph — with multiplayer roles, presence and per-space autonomy. One cc_server you own; desktop, web and phone as thin clients.',
    bestFor:
      'You want the agents and the operation around them — review, tickets, pipelines, meetings — on one deck you host yourself, on every screen you own.',
    cells: {
      openSource: 'yes',
      desktop: 'yes',
      phone: 'yes',
      server: 'yes',
      worktrees: 'yes',
      review: 'yes',
      pipelines: 'yes',
      meetings: 'yes',
      teams: 'yes',
    },
  },
  {
    id: 'conductor',
    name: 'Conductor',
    url: 'https://www.conductor.build/',
    kind: 'macOS workforce manager',
    price: 'Free · Pro from $50/mo',
    blurb:
      'A macOS app for running Claude Code, Codex, Cursor and OpenCode in parallel, each task in its own workspace and branch with a terminal, diff and GitHub review path. Paid plans add hosted Vercel cloud workspaces, live collaboration, an API and an iOS beta companion.',
    bestFor: 'You want a turnkey Mac workspace for parallel agents, PR review and live collaboration, with optional hosted cloud execution.',
    verdict: 'Conductor and Control Center both run parallel agents in isolated worktrees, review and merge PRs, and offer multiplayer and phone access. Conductor can import an existing PR into a workspace for review; Control Center also lists open PRs from linked repos in a standalone inbox, whether a human or agent opened them, alongside tickets, DAG pipelines, meetings and calendar.',
    ccEdge: 'A repo-wide PR inbox independent of agent workspaces, Linear-synced tickets, DAG pipelines, meetings and calendar, memory and a code graph, plus Windows and Linux desktop clients on a self-hosted server. Conductor offers checks, review threads and merge for workspace-linked PRs, including imported ones, but its cloud workspaces run in hosted Vercel sandboxes.',
    cells: {
      openSource: 'no',
      desktop: 'partial',
      phone: 'partial',
      server: 'no',
      worktrees: 'yes',
      review: 'partial',
      pipelines: 'no',
      meetings: 'no',
      teams: 'yes',
    },
    notes: {
      desktop: 'macOS only — there is no Windows or Linux build.',
      phone: 'An iOS beta companion is available on Pro; no Android app is documented.',
      review: 'Can import an existing PR into a workspace and review or merge it there; a standalone inbox for all linked-repo PRs is not documented.',
    },
    footnote: 'The desktop app is macOS-only. Conductor Cloud runs in hosted Vercel sandboxes, with self-hosted cloud workspaces not yet available. Existing PRs can start a workspace; checks, review threads and merge are in that workspace, not a documented repo-wide inbox. Live collaboration and the iOS beta require Pro ($50/mo), the admin portal requires Teams ($60/user/mo), and SAML SSO/SCIM require Enterprise.',
  },
  {
    id: 'superset',
    name: 'Superset',
    url: 'https://superset.sh/',
    kind: 'Parallel agent desktop',
    price: 'Free · Pro $20/user/mo',
    blurb:
      'A source-available desktop app (Elastic License 2.0) for running CLI coding agents in parallel git worktrees. Its PR inbox lists every PR from connected project repositories, including PRs without a workspace, with in-app review and merge. It also offers a headless host server, relay-connected remote workspaces, an iPhone companion, a CLI/SDK and scheduled automations.',
    bestFor: 'You want high-volume parallel worktrees with an integrated coding and PR review surface, plus optional paid remote access and team sharing.',
    verdict: 'Superset and Control Center both manage parallel worktrees and have independent PR inboxes that review and merge PRs from connected repos, whether or not an agent opened them. Superset is an agent-focused workspace with vendor-relayed remote access; Control Center adds first-party tickets, dependent pipelines, meetings and calendar on a self-hosted control plane.',
    ccEdge: 'First-party tickets with Linear sync, resumable DAG pipelines, meetings and calendar, memory and a code graph, on an MIT-licensed server and desktop clients for macOS, Windows and Linux. Superset runs agents on your own headless host, but remote access and organization metadata use its service.',
    cells: {
      openSource: 'partial',
      desktop: 'partial',
      phone: 'partial',
      server: 'partial',
      worktrees: 'yes',
      review: 'yes',
      pipelines: 'partial',
      meetings: 'no',
      teams: 'yes',
    },
    notes: {
      openSource: 'Source-available under the Elastic License 2.0 — free forever on the desktop, but not OSI open source.',
      desktop: 'macOS is the only tested platform; the Linux x64 AppImage is experimental and Windows is unreleased.',
      phone: 'The iPhone app requires Pro and iOS 26 or later; Android is not yet available.',
      server: 'A headless host server owns workspaces and runs, but remote access uses Superset Relay and account/organization metadata is hosted.',
      pipelines: 'Automations schedule agent sessions, rather than running a DAG of dependent steps.',
    },
    footnote: 'Source-available under Elastic License 2.0, not OSI open source. macOS desktop is supported, Linux AppImage is experimental and Windows is unreleased. Pro is $20/user/month, or $15/user/month billed yearly; it adds iPhone access, remote hosts, scheduled automations and shared host access. Its PR list covers every PR from connected GitHub project repos; remote routing uses Superset Relay.',
  },
  {
    id: 'orca',
    name: 'Orca',
    url: 'https://www.onorca.dev/',
    kind: 'Agent development environment',
    price: 'Free · open source',
    blurb:
      'An MIT-licensed Agent Development Environment for running CLI agents in parallel git worktrees, each with a terminal and browser. Desktop ships for macOS, Windows and Linux with iOS and Android companions. SSH targets or a self-hosted Orca server run the work; the server owns projects and sessions for paired desktop, web and phone clients.',
    bestFor: 'You want a cross-platform agent IDE with browser-per-task isolation, external issue tracking and in-app PR review, without a meeting/calendar deck or dependent DAG pipelines.',
    verdict: 'Orca and Control Center both offer cross-platform desktop and phone clients, isolated worktrees, self-hosted server state and in-app PR review and merge. Orca can open a worktree from an existing PR for review; Control Center also has an independent PR inbox spanning its linked repos, plus first-party tickets, DAG pipelines, meeting capture and calendar, memory and team presence.',
    ccEdge: 'A repo-wide PR inbox without first linking the PR to a worktree, first-party tickets with Linear sync, resumable DAG pipelines, on-device meeting capture and calendar, role-gated memory, a code graph and unified action guardrails. Orca can browse external PRs and open one in a worktree, but its documented full review flow centers that worktree.',
    cells: {
      openSource: 'yes',
      desktop: 'yes',
      phone: 'yes',
      server: 'yes',
      worktrees: 'yes',
      review: 'partial',
      pipelines: 'partial',
      meetings: 'no',
      teams: 'partial',
    },
    notes: {
      review: 'Can browse existing hosted PRs and open a worktree from one for inline review and merge; a standalone inbox with full review across linked repos is not documented.',
      pipelines: 'Scheduled automations across local and remote hosts, rather than a DAG of dependent steps.',
      teams: 'Several paired clients can share a server-owned runtime, but team roles and presence are not documented.',
    },
    footnote: 'GitHub supports inline review, checks, stacks and merge queues; GitLab merge requests use the same worktree review flow with fewer extras. An existing PR can seed a worktree, but full review is centered on that worktree rather than an independent PR inbox. Remote Orca servers own session state and accept paired desktop, web and phone clients. Orca also links external issues, including Linear, to worktrees; automations schedule prompts rather than dependent DAG steps.',
  },
  {
    id: 't3-code',
    name: 'T3 Code',
    url: 'https://t3.codes/',
    kind: 'Multi-harness coding surface',
    price: 'Free · open source',
    blurb:
      'An MIT-licensed control surface for Claude Code, Codex, Cursor, OpenCode, Grok and Antigravity. Run agents on your own machine or a remote host in separate git worktrees, connect from Electron desktop on macOS, Windows and Linux or from web, iOS and Android, then review and merge pull requests in the app.',
    bestFor:
      'You want a free, multi-harness coding workspace with remote access, a phone app and integrated pull-request review, without a larger developer-operations suite.',
    verdict:
      'T3 Code and Control Center both run coding agents in isolated worktrees, offer desktop and phone clients, and review and merge pull requests. T3 Code stays close to the coding thread and supports more external agent CLIs; Control Center adds the operation around that work: tickets, DAG pipelines, meetings, calendar and role-based human collaboration.',
    ccEdge:
      'Tickets with Linear sync, resumable DAG pipelines, meeting capture and calendar, memory and a code graph, plus human teams with roles and presence. T3 Code is a capable self-hosted coding surface with a headless CLI server and remote clients, but does not claim those wider operational workflows.',
    cells: {
      openSource: 'yes',
      desktop: 'yes',
      phone: 'yes',
      server: 'yes',
      worktrees: 'yes',
      review: 'yes',
      pipelines: 'no',
      meetings: 'no',
      teams: 'no',
    },
    footnote: 'The independent Pull requests page reviews and merges existing project PRs, and a PR can be linked to a chat thread afterward; reviews are not limited to agent-created PRs. The full diff and comments are on desktop and web, while phone apps show PR status without the Code-tab diff.',
  },
  {
    id: 'paperclip',
    name: 'Paperclip',
    url: 'https://paperclip.ing/',
    kind: 'Agent org platform',
    price: 'Free · open source',
    blurb:
      'An MIT-licensed platform that wraps AI agents in a company structure: org charts, per-agent budgets, approvals and goals, with human members and company-scoped roles. Its Node server runs with embedded Postgres; experimental isolated workspaces use git worktrees, and staged pipelines coordinate cases, dependencies and human review gates.',
    bestFor: 'You want to run an organization of humans and agents around goals, budgets and staged work, with a web UI rather than a native coding client.',
    verdict: 'Paperclip and Control Center both organize humans and agents, use isolated worktrees and coordinate multi-step work. Paperclip models an agent company with budgets, goals and review gates; Control Center concentrates on the developer operation with a PR review-and-merge cockpit, tickets, meetings and desktop and phone clients.',
    ccEdge: 'A native desktop and phone operation with copy-on-write worktree provisioning where supported, OS sandboxing, a repo-wide human PR inbox and merge, Linear-synced tickets, and on-device meeting capture. Paperclip offers optional git worktrees, staged pipelines and human roles; its experimental GitHub review bot can assess eligible PRs, but human code review and merge remain on GitHub.',
    cells: {
      openSource: 'yes',
      desktop: 'no',
      phone: 'no',
      server: 'yes',
      worktrees: 'partial',
      review: 'no',
      pipelines: 'yes',
      meetings: 'no',
      teams: 'yes',
    },
    notes: {
      worktrees: 'Isolated git worktrees are available through an experimental, opt-in workspace setting.',
    },
    footnote: 'Self-hosted as one Node process with embedded Postgres and no required account; a hosted version is on a waitlist. Staged pipelines support dependencies and review gates, and humans can join with company roles. Isolated worktrees are experimental. An optional experimental review bot can comment on PRs from any author, but human PR review and merge remain in GitHub. The UI is web-based, including mobile browsers, rather than native desktop or phone apps.',
  },
  {
    id: 'multica',
    name: 'Multica',
    url: 'https://www.multica.ai/',
    kind: 'PM for human + agent teams',
    price: 'Free · Cloud price unpublished',
    blurb:
      'A self-hostable project-management platform that assigns issues to coding agents and tracks their runs and review state. A Go backend and local daemon work with two dozen-plus installed agent CLIs; web, Electron desktop on all three platforms and a source-buildable iOS client connect to the same server. GitHub repositories use isolated worktrees by default, while Autopilots start runs on schedules or webhooks.',
    bestFor: 'You want agent assignment and progress tracking inside a PM workflow, with parallel git worktrees and recurring runbooks.',
    verdict: 'Multica and Control Center both assign work to agents in isolated worktrees and offer human teams. Multica focuses on issue handoffs, Autopilots and PR status inside project management; Control Center also reviews and merges PRs in-app, runs dependent DAG pipelines and includes meetings and calendar.',
    ccEdge: 'An integrated PR review-and-merge cockpit, resumable DAG pipelines, meeting capture, calendar, memory and a code graph under an MIT licence. Multica has worktree-isolated runs and scheduled or webhook Autopilots, but its GitHub PR integration is read-only and actual merge happens outside the app.',
    cells: {
      openSource: 'partial',
      desktop: 'yes',
      phone: 'partial',
      server: 'yes',
      worktrees: 'yes',
      review: 'no',
      pipelines: 'partial',
      meetings: 'no',
      teams: 'yes',
    },
    notes: {
      openSource: 'The “Multica License” is Apache 2.0 plus a hosted-service ban, a commercial-embedding restriction and a branding requirement — source-available, not OSI open source.',
      phone: 'The iOS/iPadOS client can be built from source and installed on your device; it is not yet on the App Store and there is no Android client.',
      pipelines: 'Autopilots run agents from cron schedules or webhooks, rather than a DAG of dependent steps.',
    },
    footnote: 'Source-available under the Multica License, not OSI open source. Self-hosting is available and Cloud has public sign-up without a published price. GitHub repos use parallel worktrees; the iOS app requires a source build. An issue can link any accessible PR by URL and show its status, CI and mergeability, but the GitHub integration is read-only: code review and merge remain on GitHub.',
  },
  {
    id: 'openclaw',
    name: 'OpenClaw',
    url: 'https://openclaw.ai/',
    kind: 'Personal assistant agent',
    price: 'Free · open source',
    blurb:
      'An MIT-licensed agent gateway for personal or shared team use. Run agents in managed git worktrees on your own host, connect through desktop and phone apps or chat channels, and use persistent memory, skills and scheduled automations. Optional plugins add multi-step workflows and meeting participation; host tools are available by default unless configured policies or sandboxes restrict them.',
    bestFor: 'You want an always-on assistant reached from chat or first-party clients, with coding worktrees and optional automation plugins alongside everyday tasks.',
    verdict: 'OpenClaw and Control Center both self-host agent work, offer desktop and phone clients, managed git worktrees, scheduled workflows and multi-user access. OpenClaw spans chat channels, personal tasks and optional plugins; Control Center focuses on a developer operation with in-app PR review and merge, first-party tickets, dependent pipelines and a meetings/calendar workspace.',
    ccEdge: 'A first-party PR review-and-merge cockpit, Linear-synced tickets, a built-in DAG pipeline builder, on-device meeting capture and a calendar UI, with unified action guardrails. OpenClaw already offers managed worktrees, team roles, durable workflows and meeting plugins, but those workflows are assembled around a general-purpose agent gateway.',
    cells: {
      openSource: 'yes',
      desktop: 'yes',
      phone: 'yes',
      server: 'yes',
      worktrees: 'yes',
      review: 'no',
      pipelines: 'partial',
      meetings: 'partial',
      teams: 'yes',
    },
    notes: {
      pipelines: 'Cron/webhook jobs and durable Task Flow records can coordinate optional Lobster pipelines; there is no documented built-in DAG pipeline editor.',
      meetings: 'Optional Meet, Teams and Zoom plugins join meetings and save captions or notes; Google Meet can read linked Calendar events, rather than providing an integrated calendar and meeting workspace.',
    },
    footnote: 'Native desktop companions cover macOS, Windows and Linux, and iOS/Android apps include chat as well as device-node features. Managed git worktrees can use filesystem acceleration; optional plugins add multi-step flows and meeting participation. Multi-user mode supports operator roles and live presence within one shared gateway trust domain. The GitHub plugin reads any public PR linked in chat, including its diff and comments, but cannot post reviews or merge and offers no linked-repo PR inbox.',
  },
  {
    id: 'hermes',
    name: 'Hermes Agent',
    url: 'https://hermes-agent.nousresearch.com/',
    kind: 'Self-improving personal agent',
    price: 'Free · Plus from $20/mo',
    blurb:
      'Nous Research’s MIT-licensed agent grows skills from experience and recalls prior conversations. Its CLI, desktop app and browser dashboard support messaging channels, parallel git worktrees, a Kanban board with task dependencies and scheduled jobs; optional Microsoft Teams integration processes meeting transcripts. Linux desktop runs from source rather than a published installer.',
    bestFor: 'You want a self-improving assistant you can also put to work on repository tasks in separate worktrees, with chat, Kanban and scheduled jobs.',
    verdict: 'Hermes Agent and Control Center both support parallel git worktrees, task handoffs and scheduled work. Hermes centers a learning personal agent with a Kanban engineering workflow; Control Center centers a multi-user developer operation with in-app PR review and merge, first-party tickets, a DAG pipeline builder and an integrated meetings/calendar workspace.',
    ccEdge: 'A repo-wide PR inbox with human review and merge, Linear-synced tickets, a general-purpose DAG pipeline builder, on-device meeting capture and calendar, and workspace roles with presence. Hermes has a desktop diff pane and a CLI-powered agent that can review existing PRs, but no documented in-app PR inbox or merge action.',
    cells: {
      openSource: 'yes',
      desktop: 'partial',
      phone: 'partial',
      server: 'yes',
      worktrees: 'yes',
      review: 'no',
      pipelines: 'partial',
      meetings: 'partial',
      teams: 'partial',
    },
    notes: {
      desktop: 'Desktop runs on macOS, Windows and Linux, but published Linux desktop installers are currently disabled.',
      phone: 'A phone can use the authenticated web dashboard or messaging channels; Android/Termux also runs the CLI, but there is no documented native phone companion.',
      pipelines: 'Cron and webhook jobs plus Kanban parent/child dependencies support engineering handoffs, rather than a general-purpose DAG pipeline builder.',
      meetings: 'An optional Microsoft Teams/Graph pipeline processes meeting transcripts and recordings, not a general integrated meetings and calendar workspace.',
      teams: 'A shared gateway can allow several people with admin or user command permissions, but workspace roles and presence are not documented.',
    },
    footnote: 'Free self-hosted software; Nous Plus ($20/month), Super ($100/month) and Ultra ($200/month) add hosted model/tool credits. Git worktrees and a Kanban board support parallel engineering; desktop diffs can create PRs, while a separate agent can review any accessible PR using gh and post feedback. Neither is a native repo-wide PR inbox with merge. Phone use is through web or chat; Microsoft Teams meeting ingestion needs Graph credentials.',
  },
  {
    id: 'goose',
    name: 'Goose',
    url: 'https://goose-docs.ai/',
    kind: 'Extensible agent & workflow runner',
    price: 'Free · open source',
    blurb:
      'The Apache-2.0 developer agent from Block, donated to the Linux Foundation’s Agentic AI Foundation in April 2026, with desktop apps on macOS, Windows and Linux, a CLI, 70+ MCP extensions and 15+ model providers. Subagents and recipes can coordinate parallel work; an early iOS remote client and a headless server let you drive it away from your machine.',
    bestFor: 'You want an extensible coding agent with MCP tools, reusable recipes and delegated work, without a built-in worktree fleet or PR merge cockpit.',
    verdict: 'Goose and Control Center both run coding agents and can coordinate multiple tasks. Goose is an extensible local-first agent with recipes, subagents and remote access; Control Center owns a worktree-isolated fleet and the surrounding PR review, tickets, pipelines and meetings.',
    ccEdge: 'Isolated worktrees (copy-on-write where supported), a repo-wide PR inbox with review and merge, first-party tickets, a DAG pipeline builder, meetings and human team roles. Goose can analyze externally authored PRs through a GitHub Actions recipe, but has no documented in-app PR inbox or merge surface.',
    cells: {
      openSource: 'yes',
      desktop: 'yes',
      phone: 'partial',
      server: 'yes',
      worktrees: 'no',
      review: 'no',
      pipelines: 'partial',
      meetings: 'no',
      teams: 'no',
    },
    notes: {
      phone: 'An early iOS remote client is on the App Store; the Android remote client is planned, with on-device Android execution still experimental.',
      pipelines: 'Scheduled recipes and subagent orchestration support recurring workflows, rather than a first-party configurable DAG pipeline board.',
    },
    footnote: 'Desktop apps cover all three platforms; goose serve can run headlessly and connect to desktop or an early iOS remote client. Recipes schedule and coordinate work, while subagents run parallel tasks. Goose can analyze any PR through a configured GitHub Actions workflow, but no native worktree-isolated fleet, in-app PR inbox/merge or authenticated multi-user roles are documented.',
  },
  {
    id: 'cursor',
    name: 'Cursor',
    url: 'https://cursor.com/',
    kind: 'AI-first IDE',
    price: 'Free · Pro from $20/mo',
    blurb:
      'An AI-first editor with local git worktrees for parallel agent runs, hosted cloud agents, and self-hosted execution workers attached to personal My Machines accounts. Automations react to schedules, repository events, Slack and Linear; iOS can review and merge a teammate’s PR, and the Origin per-repo PR surface is in early beta.',
    bestFor: 'You want an AI editor with parallel agent runs and cloud-backed orchestration, including code execution on your own attached machines.',
    verdict: 'Cursor and Control Center overlap on parallel worktrees, automation, team workflows and PR review. Cursor remains the editor and runs its agent loop in the cloud even when execution uses your machine; Control Center is a self-hosted developer operation for tickets, dependent pipelines, meetings and review.',
    ccEdge: 'A self-owned control plane, first-party tickets with Linear sync, a DAG pipeline builder, an integrated meetings/calendar workspace and role-gated memory. Cursor has local worktrees, cloud automations, mobile PR merge and an early-beta Origin review surface, but its agent loop still runs in Cursor’s cloud.',
    cells: {
      openSource: 'no',
      desktop: 'yes',
      phone: 'partial',
      server: 'partial',
      worktrees: 'yes',
      review: 'partial',
      pipelines: 'partial',
      meetings: 'partial',
      teams: 'yes',
    },
    notes: {
      phone: 'The app is iOS and iPadOS; on Android it is a browser PWA.',
      server: 'Personal My Machines can run file edits and commands on your hardware; team-shared pools require Enterprise, and the agent loop still runs in Cursor’s cloud.',
      review: 'Origin’s early-beta repository PR list reviews existing GitHub-mirrored PRs, but merging mirrored PRs there is not explicitly documented; iOS’s agent-oriented inbox can review and merge a teammate’s PR.',
      pipelines: 'Cloud automations use schedules, repository events, webhooks and integrations, rather than a general-purpose DAG builder.',
      meetings: 'The official Google Calendar plugin reads schedules and manages events, but there is no documented first-party meetings and calendar workspace.',
    },
    footnote: 'Local git worktrees support parallel runs; My Machines attaches personal hardware for execution while Cursor runs the agent loop. Teams ($40/user/month) supports shared context, while team-shared execution pools require Enterprise. iOS can review and merge a teammate’s PR (Android uses the browser PWA). Origin’s early-beta PR list reviews mirrored GitHub PRs, but its docs do not explicitly confirm merging those mirrors. Automations use schedules and event triggers; the Google Calendar plugin handles events rather than an integrated meetings workspace.',
  },
  {
    id: 'terminals',
    name: 'Plain terminals',
    url: 'https://code.claude.com/docs',
    kind: 'The baseline',
    price: 'Free · provider plan extra',
    blurb:
      'Multiple terminal windows and checkouts are the familiar starting point for parallel coding agents. You manage branches, worktrees, provider access and review by hand, without a shared operations view.',
    bestFor: 'You prefer your existing CLI and are willing to manage worktrees, reviews and context yourself.',
    cells: {
      openSource: 'partial',
      desktop: 'yes',
      phone: 'no',
      server: 'no',
      worktrees: 'partial',
      review: 'no',
      pipelines: 'no',
      meetings: 'no',
      teams: 'no',
    },
    notes: {
      openSource: 'Many terminal emulators and coding agents are open source, but the terminal and agent you choose may be proprietary.',
      worktrees: 'Git supports separate worktrees out of the box, but you create and manage each worktree manually.',
    },
    footnote: 'Terminals cost nothing; the agent may need a provider subscription or usage-based billing. Open-source terminal and agent options exist. You can create git worktrees by hand, but terminals have no built-in worktree orchestration, unified review surface or shared state.',
  },
];

/**
 * Tools that get a dedicated `/compare/<id>/` page (one per competitor) and a
 * footer link. Control Center itself and the terminals baseline don't.
 */
export const vsTools = tools.filter((t) => t.id !== 'control-center' && t.id !== 'terminals');

/** Whether a tool has its own `/compare/<id>/` page. */
export function hasVsPage(tool: CompareTool): boolean {
  return tool.id !== 'control-center' && tool.id !== 'terminals';
}

/**
 * Outbound link for a tool with UTM attribution, so the destination's
 * analytics can see the referral. Only actual competitors are tagged —
 * Control Center itself and the terminals baseline stay clean — and
 * llms-full.txt keeps using `tool.url` (AI surfaces get clean links).
 */
export function trackedUrl(tool: CompareTool): string {
  if (tool.id === 'control-center' || tool.id === 'terminals') return tool.url;
  const url = new URL(tool.url);
  url.searchParams.set('utm_source', 'usectrl.dev');
  url.searchParams.set('utm_medium', 'referral');
  url.searchParams.set('utm_campaign', 'compare');
  return url.toString();
}

/** Intro copy reused by the page and llms-full.txt. Answer-first by design. */
export const compareSummary =
  'Control Center’s PR inbox lists any open PR from a linked repo, including human-authored PRs, for in-app review and merge — no agent conversation required. Superset and T3 Code also have independent PR lists; Conductor and Orca can import existing PRs into workspaces for review. Beyond PRs, Control Center combines parallel agents, tickets, dependent pipelines, meetings and calendar on a self-hosted server with desktop and phone clients. Pick the workflow and ownership model you need.';

/** Scope of the review column, shared by HTML and machine-readable pages. */
export const reviewScopeNote =
  'For PRs, ✓ means an inbox for any open PR in a linked repo, with review and merge in app; no agent chat or worktree is required. ≈ means the flow is workspace-bound, early-beta or otherwise narrower — not necessarily restricted to agent-created PRs.';

/** Standing caveat for the price column: model access varies by vendor and plan. */
export const priceNote =
  'Prices are each vendor’s published starting point for the tool. Model access may need your own provider key or subscription, or may be included in a paid plan; compare those costs separately.';

/** When the cells above were last checked against each product's site. */
export const compareReviewed = 'September 27, 2026';
