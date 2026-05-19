// Comparison data for /compare/. Single source of truth for two consumers:
// the compare page (matrix + per-tool sections) and llms-full.txt (rendered
// as a markdown table).
//
// Factual accuracy rules: every cell is backed by what the product's own site
// or repo publicly claims (re-checked end of August 2026). 'partial' means the
// capability exists in a narrower form than Control Center's take on it —
// the per-tool `footnote` says exactly how. When a product simply doesn't
// claim a capability, it gets 'no' rather than a guess. Re-verify before
// editing cells; stale comparison tables are worse than none.
//
// `price` is the vendor's own list price, phrased as "starts at": the entry
// point first, then the cheapest paid tier when one exists. Never a
// third-party estimate, and never inclusive of model spend — every tool here
// bills your model provider separately, which the page states once.

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
  /** How partial cells should be read. */
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
  { id: 'review', label: 'In-app PR review & merge' },
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
      'One native app for the whole operation: a fleet of agents (built-in runtime plus eight CLI adapters) across copy-on-write worktrees, a PR review cockpit, tickets with Linear sync, DAG pipelines, meetings, calendar, memory and a code graph — with multiplayer roles, presence and per-space autonomy. One cc_server you own; desktop, web and phone as thin clients.',
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
      'A polished macOS app for running Claude Code, Codex, Cursor and OpenCode in parallel, each task in its own workspace and branch with a dedicated terminal, diff and review path. Since July 2026 the paid tiers add Conductor Cloud — the same workspaces running in hosted Vercel sandboxes — plus early-access multiplayer, stacked branches, an API and a Conductor MCP server.',
    bestFor: 'You live on a Mac, want the smoothest turnkey parallel-agent experience, and are happy for the hosted half to run on someone else’s servers.',
    verdict: 'Conductor and Control Center both run parallel agents in isolated worktrees on a Mac — they diverge at everything around the fleet. Conductor is the smoother, simpler start; Control Center is the whole operation: review and merge, tickets, pipelines, meetings, multiplayer and a server you actually host.',
    ccEdge: 'Everything past the fleet, and on hardware you own: an in-app review cockpit with merge actions, tickets with Linear sync, DAG pipelines, meetings and calendar, memory and a code graph, plus desktop on all three platforms, a phone client and a headless server — where Conductor is Mac-only and its cloud tier is hosted for you.',
    cells: {
      openSource: 'no',
      desktop: 'partial',
      phone: 'no',
      server: 'no',
      worktrees: 'yes',
      review: 'partial',
      pipelines: 'no',
      meetings: 'no',
      teams: 'partial',
    },
    notes: {
      desktop: 'macOS only — there is no Windows or Linux build.',
      review: 'A per-task diff with open-PR, stack and merge actions, rather than a review cockpit with threads, checks and verdicts.',
      teams: 'Multiplayer is early access, and the admin portal, SAML SSO and SCIM sit on the paid Teams and Enterprise plans.',
    },
    footnote: 'macOS-only desktop, with no Windows or Linux build; per-task diff review with open-PR, stack and merge actions rather than a full review cockpit; Conductor Cloud runs workspaces in hosted Vercel sandboxes and self-hosting is announced but unshipped; multiplayer, the admin portal and SSO are paid tiers (Pro $50/mo, Teams $60/user/mo, Enterprise custom), and the mobile app is still listed as coming soon.',
  },
  {
    id: 'superset',
    name: 'Superset',
    url: 'https://superset.sh/',
    kind: 'Parallel agent desktop',
    price: 'Free · teams from $15/user',
    blurb:
      'A source-available desktop app (Elastic License 2.0) built to run a hundred-plus CLI coding agents in parallel — Claude Code, Codex, Cursor, OpenCode, Gemini CLI and anything else that runs in a terminal — each in its own git worktree and branch. It adds a built-in diff reviewer, SSH-backed remote workspaces that survive a sleeping laptop, a CLI/SDK for CI, and cron-style automations.',
    bestFor: 'You want maximum parallelism under a lightweight dashboard, and nothing else in the way.',
    verdict: 'Superset and Control Center share the worktree-first model of parallel agents — Superset as a lean agent dashboard, Control Center as the whole operation. Superset maximizes raw parallelism; Control Center wraps the fleet in review, tickets, pipelines and meetings on one self-hosted server.',
    ccEdge: 'The operation around the agents: PR review with merge, tickets, DAG pipelines, meetings and calendar, role-gated memory, a code graph, multiplayer — plus a self-hosted server, web and phone clients, and MIT-licensed desktop on all three platforms instead of a source-available Mac-first app.',
    cells: {
      openSource: 'partial',
      desktop: 'partial',
      phone: 'no',
      server: 'no',
      worktrees: 'yes',
      review: 'partial',
      pipelines: 'partial',
      meetings: 'no',
      teams: 'no',
    },
    notes: {
      openSource: 'Source-available under the Elastic License 2.0 — free forever on the desktop, but not OSI open source.',
      desktop: 'macOS is the only tested platform; the Linux x64 AppImage is experimental and Windows is unreleased.',
      review: 'A built-in diff viewer for inspecting, commenting on and editing changes before commit — not a pull-request surface.',
      pipelines: 'Automations run an agent session on a schedule; there is no DAG of dependent steps.',
    },
    footnote: 'Source-available under the Elastic License 2.0 — the desktop app is free forever, but it is not OSI open source; macOS is the only tested platform (the Linux x64 AppImage is experimental, Windows is unreleased and the iOS app is “coming soon”); automations are scheduled agent sessions, not DAG pipelines; the $15/user/month team plan is a billing tier rather than shared workspaces.',
  },
  {
    id: 'orca',
    name: 'Orca',
    url: 'https://www.onorca.dev/',
    kind: 'Agent development environment',
    price: 'Free · open source',
    blurb:
      'An MIT-licensed Agent Development Environment (ADE) from Stably: 40+ CLI agents in parallel, every task in its own git worktree with its own terminal and embedded Chromium tab. Desktop ships for macOS, Windows and Linux with iOS and Android companions, agents can run on SSH targets or self-hosted Orca servers, and the GitHub surface now covers inline review, checks, stacked PRs and merge.',
    bestFor: 'You want a free, cross-platform agent IDE with a phone companion, browser-per-task isolation and the most complete pull-request surface in this table — without tickets, meetings or an operation around it.',
    verdict: 'Orca is the closest tool to Control Center here: both are MIT-licensed, ship desktop on all three platforms plus phone companions, isolate every task in a real worktree, and review and merge pull requests in-app. They diverge on scope — Orca is an agent IDE, Control Center is the operation deck around it: tickets with Linear sync, DAG pipelines, meetings and calendar, memory, guardrails and human multiplayer on a server that owns the state.',
    ccEdge: 'Everything that is not the IDE: Linear-synced tickets that dispatch straight into worktrees, resumable DAG pipelines instead of scheduled prompts, on-device meeting capture and calendar, role-gated memory and a code graph, unified action guardrails with a per-space autonomy dial, and human multiplayer with presence — over one cc_server that holds the state, so desktop, web and phone all see the same operation rather than each desktop holding its own.',
    cells: {
      openSource: 'yes',
      desktop: 'yes',
      phone: 'yes',
      server: 'partial',
      worktrees: 'yes',
      review: 'yes',
      pipelines: 'partial',
      meetings: 'no',
      teams: 'no',
    },
    notes: {
      server: '“Self-hosted Orca servers” are remote compute an agent runs on, not a server your clients read state from — the desktop stays the source of truth.',
      pipelines: 'Scheduled automations across local and remote hosts, rather than a DAG of dependent steps.',
    },
    footnote: 'Review is complete on GitHub (inline comments, checks, stacked PRs with atomic stack merge and merge-queue support) and thinner on GitLab; “self-hosted Orca servers” are remote compute targets agents run on, not a server your clients read state from; automations are scheduled runs, not DAG pipelines; no human multiplayer, tickets or meetings.',
  },
  {
    id: 'paperclip',
    name: 'Paperclip',
    url: 'https://paperclip.ing/',
    kind: 'Agent org platform',
    price: 'Free · open source',
    blurb:
      'An MIT-licensed platform that wraps AI agents in a company structure: org charts with reporting lines, per-agent monthly budgets that pause at 100%, board-level approval for hiring and strategy, and goals every task traces back to. It runs as a single Node process with an embedded Postgres and no required account, agent-agnostic across Claude, Codex, Gemini, Cursor, Hermes, OpenClaw and Pi.',
    bestFor: 'You want to model an organization of agents — budgets, goals, governance — more than a coding workflow.',
    verdict: 'Paperclip and Control Center both organize AI agents into something bigger than a chat window — Paperclip into a company (org chart, budgets, goals), Control Center into a developer operation (review, tickets, pipelines, meetings). Paperclip is the better business metaphor; Control Center is the better software workflow.',
    ccEdge: 'Execution-native developer tooling: copy-on-write worktrees with OS sandboxing, a real PR review cockpit, Linear-synced tickets, resumable pipelines, on-device meeting capture — in native desktop and phone clients over a server you own.',
    cells: {
      openSource: 'yes',
      desktop: 'no',
      phone: 'no',
      server: 'yes',
      worktrees: 'no',
      review: 'no',
      pipelines: 'partial',
      meetings: 'no',
      teams: 'partial',
    },
    notes: {
      pipelines: 'Agents wake on a heartbeat or an event, rather than running a DAG of dependent steps.',
      teams: 'The org chart models a team of agents — reporting lines, budgets, approvals — not human multiplayer with roles and presence.',
    },
    footnote: 'Fully self-hosted — one Node process, embedded Postgres, no Paperclip account — with heartbeat and event-driven wake-ups rather than DAG pipelines; a web UI rather than native desktop or phone clients; the team metaphor is an org of agents, not human multiplayer; no git worktrees or review surface.',
  },
  {
    id: 'multica',
    name: 'Multica',
    url: 'https://www.multica.ai/',
    kind: 'PM for human + agent teams',
    price: 'Free · cloud on request',
    blurb:
      'A self-hostable project-management platform that treats coding agents as teammates: assign an issue the way you’d assign it to a colleague and the agent picks it up, reports blockers and hands it back for review. A Go daemon auto-detects the 23 CLIs you already have installed, behind a Next.js web app, an Electron desktop app on all three platforms and a CLI.',
    bestFor: 'You want task assignment and progress tracking for agents inside a PM workflow you already understand.',
    verdict: 'Multica and Control Center both make agents teammates — Multica through project management (assign issues, track progress), Control Center through the full developer operation. Multica is the cleaner PM surface; Control Center is where the assigned work actually runs, reviews and merges.',
    ccEdge: 'End-to-end, under a plain MIT licence: the worktree the ticket dispatches into, the sandbox it runs in, the PR review it lands in, the pipeline that triggers the next one — plus memory, meetings, a code graph and a phone client the whole loop learns from.',
    cells: {
      openSource: 'partial',
      desktop: 'yes',
      phone: 'no',
      server: 'yes',
      worktrees: 'no',
      review: 'no',
      pipelines: 'no',
      meetings: 'no',
      teams: 'yes',
    },
    notes: {
      openSource: 'The “Multica License” is Apache 2.0 plus a hosted-service ban, a commercial-embedding restriction and a branding requirement — source-available, not OSI open source.',
    },
    footnote: 'The “Multica License” is Apache 2.0 plus conditions — no hosted service for third parties, no commercial embedding without a licence, and the branding has to stay — so source-available rather than OSI open source. Self-hostable by Docker Compose, single binary or Kubernetes (a hosted cloud exists but publishes no pricing); a PM surface, with no worktree isolation, review cockpit or phone client.',
  },
  {
    id: 'openclaw',
    name: 'OpenClaw',
    url: 'https://openclaw.ai/',
    kind: 'Personal assistant agent',
    price: 'Free · open source',
    blurb:
      'The MIT-licensed personal AI assistant that went mainstream in 2026, now stewarded by the non-profit OpenClaw Foundation after its creator joined OpenAI. One gateway process on your own machine or a VPS, reachable from the ~29 chat surfaces you already use — WhatsApp, Telegram, Discord, Slack, iMessage, Signal — with persistent memory, full system access, cron jobs and a marketplace of skills it can extend itself.',
    bestFor: 'You want one always-on assistant for the whole of life — inbox, calendar, bookings, errands — driven from the chat app already open on your phone, rather than a coding fleet.',
    verdict: 'OpenClaw and Control Center both run on a server you own, and that is where the resemblance ends. OpenClaw is a general-purpose personal assistant you reach from WhatsApp; Control Center is a developer operations deck — parallel coding agents in git worktrees, PR review and merge, tickets, pipelines and meetings. Pick OpenClaw for life admin over chat; pick Control Center for the software operation.',
    ccEdge: 'Everything a codebase needs: copy-on-write worktrees with OS sandboxing so agents never touch your checkout, a PR review cockpit with merge, Linear-synced tickets, resumable DAG pipelines, meetings and calendar, and unified action guardrails with a per-space autonomy dial — a bounded operation rather than one general-purpose assistant holding full system access.',
    cells: {
      openSource: 'yes',
      desktop: 'partial',
      phone: 'partial',
      server: 'yes',
      worktrees: 'no',
      review: 'no',
      pipelines: 'partial',
      meetings: 'no',
      teams: 'partial',
    },
    notes: {
      desktop: 'Native apps cover macOS and Windows; Linux installs through the CLI.',
      phone: 'The iOS and Android apps are pairing “nodes” that lend the gateway a camera, screen and voice — the everyday phone surface is whichever chat app you already use.',
      pipelines: 'Cron jobs and background tasks, rather than a DAG of dependent steps.',
      teams: 'One gateway can run as a shared team deployment, but there are no per-member roles or presence.',
    },
    footnote: 'Native desktop apps cover macOS and Windows; Linux installs through the CLI. The iOS and Android apps are pairing “nodes” that lend the gateway a camera, screen and voice rather than full clients — the everyday phone surface is whichever chat app you already use. Automation is cron and background tasks, not pipelines; one gateway can run as a shared team deployment; no git worktrees, review surface or calendar.',
  },
  {
    id: 'hermes',
    name: 'Hermes Agent',
    url: 'https://hermes-agent.nousresearch.com/',
    kind: 'Self-improving personal agent',
    price: 'Free · Plus from $20/mo',
    blurb:
      'Nous Research’s MIT-licensed take on the same idea, with a learning loop as the differentiator: it writes skills from experience, sharpens them in use and searches past conversations for context. A CLI and desktop installers on all three platforms, ~20 messaging surfaces, terminal backends from local and Docker to SSH, Singularity, Daytona and Modal — and a one-command migration from an existing OpenClaw install.',
    bestFor: 'You want a personal agent that compounds — building and refining its own skills over time — and you are happy driving it from a terminal or a chat thread.',
    verdict: 'Hermes Agent and Control Center are not competing for the same job: Hermes is a self-improving personal assistant reachable from chat, Control Center is a developer operations deck for a fleet of coding agents. Pick Hermes if you want one agent that learns you; pick Control Center when the work is a repository — worktrees, review, tickets, pipelines.',
    ccEdge: 'The software operation Hermes doesn’t attempt: many agents at once in copy-on-write worktrees under OS sandboxing, a PR review cockpit with merge, Linear-synced tickets, DAG pipelines, meetings and calendar, human multiplayer with roles and presence — and a memory system scoped by policy and grants rather than one agent’s private notebook.',
    cells: {
      openSource: 'yes',
      desktop: 'yes',
      phone: 'no',
      server: 'yes',
      worktrees: 'no',
      review: 'no',
      pipelines: 'partial',
      meetings: 'no',
      teams: 'no',
    },
    notes: {
      pipelines: 'A built-in cron that takes natural-language schedules, rather than a DAG of dependent steps.',
    },
    footnote: 'Self-hosted anywhere from a laptop to Docker, SSH, Singularity, Daytona or Modal, and free to run against your own keys — the Plus/Super/Ultra tiers ($20/$100/$200 a month) buy hosted model credits, not the software. No mobile app: a phone reaches it through the messaging gateway. The built-in cron takes natural-language schedules; “teams” means a roster of specialist bots in a group chat, not human multiplayer; no git worktrees or review surface.',
  },
  {
    id: 'goose',
    name: 'Goose',
    url: 'https://goose-docs.ai/',
    kind: 'Extensible single agent',
    price: 'Free · open source',
    blurb:
      'The Apache-2.0 developer agent born at Block and handed to the Linux Foundation’s Agentic AI Foundation in April 2026: one highly extensible agent with native desktop apps on all three platforms, a CLI, 70+ MCP extensions and 15+ model providers. Subagents fan a task out, but it is a single pair-programmer you teach tricks, not a fleet.',
    bestFor: 'You want one teachable agent and an MCP extension ecosystem, without fleet orchestration.',
    verdict: 'Goose and Control Center solve different sizes of the same problem: Goose is one excellent extensible agent, Control Center runs many — including Goose itself, via its runner adapters. Pick Goose for a single teachable pair-programmer; pick Control Center when one agent becomes a fleet.',
    ccEdge: 'N-to-N instead of one-to-one: many agents in isolated worktrees, agent-to-agent delegation under autonomy guardrails, review and tickets and pipelines — with Goose still in the loop as one runner among eight.',
    cells: {
      openSource: 'yes',
      desktop: 'yes',
      phone: 'no',
      server: 'no',
      worktrees: 'no',
      review: 'no',
      pipelines: 'no',
      meetings: 'no',
      teams: 'no',
    },
    footnote: 'Native desktop apps on all three platforms, and subagents parallelize sub-tasks inside one run — but it stays a single-agent surface, with no worktree-isolated fleet, review cockpit or server for clients to share.',
  },
  {
    id: 'cursor',
    name: 'Cursor',
    url: 'https://cursor.com/',
    kind: 'AI-first IDE',
    price: 'Free · Pro from $20/mo',
    blurb:
      'The AI-first editor, now with real local git worktrees (`/worktree`, `/best-of-n`) for parallel agent runs, cloud agents on isolated VMs you can hand back and forth with your machine, Automations triggered by schedules and by Slack, Linear, GitHub or PagerDuty, and an iOS app for steering runs on the move. Excellent as an editor with agent assists; the operation around the fleet is out of scope.',
    bestFor: 'You want the best AI editor with parallel agent runs beside it, and are happy for the heavy lifting to happen in the cloud.',
    verdict: 'Cursor and Control Center split the developer stack: Cursor is the AI-first editor you write code in, Control Center is the operation you run agents from — and it opens any PR straight into Cursor on its worktree. Keep both; they do different jobs.',
    ccEdge: 'Fleet-scale orchestration Cursor doesn’t attempt: merge-ready review with AI verdicts, tickets with Linear sync, DAG pipelines, meetings and calendar, role-gated memory — self-hosted end to end and MIT-licensed, on every screen you own rather than an Enterprise add-on.',
    cells: {
      openSource: 'no',
      desktop: 'yes',
      phone: 'partial',
      server: 'partial',
      worktrees: 'yes',
      review: 'partial',
      pipelines: 'partial',
      meetings: 'no',
      teams: 'partial',
    },
    notes: {
      phone: 'The app is iOS and iPadOS; on Android it is a browser PWA.',
      server: 'Self-hosted cloud agents keep the code on your own infrastructure, but they are Enterprise-only and the control plane stays Cursor’s.',
      review: 'Review is split across the IDE, the Review bot and mobile rather than gathered into one surface, and there is no merge queue of your own.',
      pipelines: 'Automations are cloud-run schedules and event triggers, rather than a DAG of dependent steps.',
      teams: 'Team features sit behind the paid Teams and Enterprise plans.',
    },
    footnote: 'Worktrees are real and local, but cloud agents still branch in hosted Ubuntu VMs and self-hosted cloud agents are Enterprise-only; the phone app is iOS and iPadOS (Android is a browser PWA); Automations are cloud-run schedules and event triggers, not DAG pipelines; review spans the IDE, the Review bot and mobile; team features sit behind Teams ($40/user/mo) and Enterprise plans.',
  },
  {
    id: 'terminals',
    name: 'Plain terminals',
    url: 'https://code.claude.com/docs',
    kind: 'The baseline',
    price: 'Free · agents bill per token',
    blurb:
      'N terminal windows, N checkouts, zero cross-agent visibility: the way everyone starts. It is exactly what every tool above exists to replace — the floor, not a competitor.',
    bestFor: 'You run one agent at a time and already have the muscle memory.',
    cells: {
      openSource: 'no',
      desktop: 'yes',
      phone: 'no',
      server: 'no',
      worktrees: 'no',
      review: 'no',
      pipelines: 'no',
      meetings: 'no',
      teams: 'no',
    },
    footnote: 'The terminals are free but the agents bill per token; no isolation, no review surface, no shared state.',
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
  'Control Center is the only tool in this table that runs the whole developer operation — parallel agents, PR review and merge, tickets, pipelines, meetings, calendar, memory — in one app you self-host, with native desktop clients on all three platforms, a phone companion and multiplayer for humans and agents. Single-purpose tools do their slice better in isolation: Conductor for a turnkey Mac workforce, Superset for raw parallelism, Orca for a free cross-platform agent IDE with the most complete pull-request surface here, Paperclip for an agent org chart, Multica for PM-style task assignment, OpenClaw and Hermes Agent for a personal assistant rather than a coding fleet. Pick by the slice you actually need — or by whether you want the whole deck.';

/** Standing caveat for the price column: nothing here includes model spend. */
export const priceNote =
  'Prices are each vendor’s own list price to use the tool. Every option here bills your model provider separately — you bring your own keys or subscription.';

/** When the cells above were last checked against each product's site. */
export const compareReviewed = 'August 2026';
