// Comparison data for /compare/. Single source of truth for two consumers:
// the compare page (matrix + per-tool sections) and llms-full.txt (rendered
// as a markdown table).
//
// Factual accuracy rules: every cell is backed by what the product's own site
// or repo publicly claims (checked August 2026). 'partial' means the
// capability exists in a narrower form than Control Center's take on it —
// the per-tool `footnote` says exactly how. When a product simply doesn't
// claim a capability, it gets 'no' rather than a guess. Re-verify before
// editing cells; stale comparison tables are worse than none.

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
  /** 2–3 sentences: what it is, what it's genuinely best at. */
  blurb: string;
  /** "Pick it if …" — the honest case for the competitor. */
  bestFor: string;
  /** Direct answer for the vs-page H1 question, first sentence standalone. */
  verdict?: string;
  /** Where Control Center pulls ahead, for the vs-page. */
  ccEdge?: string;
  cells: Record<string, CellValue>;
  /** How partial cells should be read. */
  footnote?: string;
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
    blurb:
      'One native app for the whole operation: a fleet of agents (built-in runtime plus eight CLI adapters) across copy-on-write worktrees, a PR review cockpit, tickets with Linear sync, DAG pipelines, meetings, calendar, memory and a code graph — with multiplayer roles, presence and per-channel autonomy. One cc_server you own; desktop, web and phone as thin clients.',
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
    blurb:
      'A polished macOS app for running Claude Code, Codex, Cursor and OpenCode in parallel, each task in its own workspace and branch with a dedicated terminal, diff and review path. It clones your GitHub repos, keeps the first-party agents under the hood and brings your subscriptions and API keys.',
    bestFor: 'You live on a Mac, want the smoothest turnkey parallel-agent experience, and don’t need pipelines, meetings or self-hosting.',
    verdict: 'Conductor and Control Center both run parallel agents in isolated worktrees on a Mac — they diverge at everything around the fleet. Conductor is the smoother, simpler start; Control Center is the whole operation: review and merge, tickets, pipelines, meetings, multiplayer and a self-hosted server.',
    ccEdge: 'Everything past the fleet: an in-app review cockpit with merge actions, tickets with Linear sync, DAG pipelines, meetings and calendar, memory and a code graph, multiplayer roles and presence, plus headless-server and phone-client reach.',
    cells: {
      openSource: 'no',
      desktop: 'partial',
      phone: 'no',
      server: 'no',
      worktrees: 'yes',
      review: 'partial',
      pipelines: 'no',
      meetings: 'no',
      teams: 'no',
    },
    footnote: 'macOS-only desktop; per-task diff review with open-PR and merge actions rather than a full review cockpit; Conductor Cloud runs agents hosted (Vercel sandboxes), not self-hosted.',
  },
  {
    id: 'superset',
    name: 'Superset',
    url: 'https://superset.sh/',
    kind: 'Parallel agent desktop',
    blurb:
      'A source-available desktop app (Elastic License 2.0) built to run a hundred-plus CLI coding agents in parallel — Claude Code, Codex, OpenCode and anything else that runs in a terminal — each in its own git worktree and branch, with dashboard diff review and cron-style scheduled runs.',
    bestFor: 'You want maximum parallelism under a lightweight dashboard, and nothing else in the way.',
    verdict: 'Superset and Control Center share the worktree-first model of parallel agents — Superset as a lean agent dashboard, Control Center as the whole operation. Superset maximizes raw parallelism; Control Center wraps the fleet in review, tickets, pipelines and meetings on one self-hosted server.',
    ccEdge: 'The operation around the agents: PR review with merge, tickets, DAG pipelines, meetings and calendar, role-gated memory, a code graph, multiplayer — plus a self-hosted server, web and phone clients, and desktop on all three platforms instead of a Mac-first app.',
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
    footnote: 'Source-available under the Elastic License 2.0 with a free tier, not OSI open source; macOS-first desktop (experimental Linux AppImage, no Windows yet); scheduled runs are cron-style prompts, not pipelines.',
  },
  {
    id: 'orca',
    name: 'Orca',
    url: 'https://www.onorca.dev/',
    kind: 'Agent development environment',
    blurb:
      'An MIT-licensed Agent Development Environment (ADE) from Stably AI: every task gets its own git worktree, agent terminal and browser tab, with fleet tracking across Claude Code, Codex, Gemini, Cursor CLI and more. Desktop apps ship for macOS, Windows and Linux, with iOS and Android companions.',
    bestFor: 'You want a free, cross-platform multi-agent workspace with a mobile companion and browser-per-task isolation.',
    verdict: 'Orca and Control Center are the two fully cross-platform open-source options here, and both ship phone companions — Orca as a free agent development environment, Control Center as the operation deck around the fleet. Orca gives every task a worktree, terminal and browser; Control Center adds everything that happens between tasks.',
    ccEdge: 'The between-tasks surface: review cockpit with merge, tickets with Linear sync, pipelines, meetings and calendar, guardrails with an autonomy dial, agent-to-agent delegation — plus a self-hosted headless server so the fleet runs without your laptop.',
    cells: {
      openSource: 'yes',
      desktop: 'yes',
      phone: 'yes',
      server: 'no',
      worktrees: 'yes',
      review: 'partial',
      pipelines: 'no',
      meetings: 'no',
      teams: 'no',
    },
    footnote: 'In-app review covers diff comments, approvals, CI and conflict resolution but not merging; no headless server mode, pipelines or operation surface beyond the fleet.',
  },
  {
    id: 'paperclip',
    name: 'Paperclip',
    url: 'https://paperclip.ing/',
    kind: 'Agent org platform',
    blurb:
      'An open-source Node.js server and React UI that wraps AI agents in a company structure: org charts, budgets, governance and goals — hire a CEO agent, marketing agents, coding agents, and wake them on schedules. Runs on Claude Code, Codex and other runtimes, with bring-your-own everything.',
    bestFor: 'You want to model an organization of agents — budgets, goals, governance — more than a coding workflow.',
    verdict: 'Paperclip and Control Center both organize AI agents into something bigger than a chat window — Paperclip into a company (org chart, budgets, goals), Control Center into a developer operation (review, tickets, pipelines, meetings). Paperclip is the better business metaphor; Control Center is the better software workflow.',
    ccEdge: 'Execution-native developer tooling: copy-on-write worktrees with OS sandboxing, a real PR review cockpit, Linear-synced tickets, resumable pipelines, on-device meeting capture — in native desktop apps over a server you own.',
    cells: {
      openSource: 'yes',
      desktop: 'no',
      phone: 'no',
      server: 'partial',
      worktrees: 'no',
      review: 'no',
      pipelines: 'partial',
      meetings: 'no',
      teams: 'partial',
    },
    footnote: 'Self-hostable Node deployment with cron-style agent wake-ups; web UI rather than native clients; team-of-agents metaphor rather than human multiplayer.',
  },
  {
    id: 'multica',
    name: 'Multica',
    url: 'https://www.multica.ai/',
    kind: 'PM for human + agent teams',
    blurb:
      'An open-source project-management platform that treats coding agents as teammates: assign issues the way you assign work to a colleague, track progress on dashboards, and let skills compound across tasks. Claude Code, Codex and other agent runtimes are supported.',
    bestFor: 'You want task assignment and progress tracking for agents inside a PM workflow you already understand.',
    verdict: 'Multica and Control Center both make agents teammates — Multica through project management (assign issues, track progress), Control Center through the full developer operation. Multica is the cleaner PM surface; Control Center is where the assigned work actually runs, reviews and merges.',
    ccEdge: 'End-to-end: the worktree the ticket dispatches into, the sandbox it runs in, the PR review it lands in, the pipeline that triggers the next one — plus memory, meetings and a code graph the whole loop learns from.',
    cells: {
      openSource: 'yes',
      desktop: 'yes',
      phone: 'no',
      server: 'yes',
      worktrees: 'no',
      review: 'no',
      pipelines: 'no',
      meetings: 'no',
      teams: 'yes',
    },
    footnote: 'Self-hostable daemon (Docker, single binary or Kubernetes) with native desktop apps on all three platforms; a PM surface — no worktree isolation or review cockpit.',
  },
  {
    id: 'openhands',
    name: 'OpenHands',
    url: 'https://www.openhands.dev/',
    kind: 'Autonomous software engineer',
    blurb:
      'An open-source AI software engineer (formerly OpenDevin) that plans and executes whole tasks on its own or in the cloud, opening pull requests when done. It is an agent, not an orchestrator of the CLI agents you already run.',
    bestFor: 'You want to delegate a whole issue to one autonomous engineer rather than operate a fleet of your own agents.',
    verdict: 'OpenHands and Control Center are complements, not rivals: OpenHands is an autonomous software engineer you delegate whole issues to, Control Center is the deck you operate a fleet from — including, via its runner adapters, agents like OpenHands. Pick OpenHands for hands-off delegation; pick Control Center for the operation.',
    ccEdge: 'Fleet orchestration around any runner: parallel worktrees, review and merge, tickets, pipelines, multiplayer — and OpenHands can be one more runner in that fleet rather than a separate silo.',
    cells: {
      openSource: 'yes',
      desktop: 'no',
      phone: 'no',
      server: 'yes',
      worktrees: 'partial',
      review: 'partial',
      pipelines: 'no',
      meetings: 'no',
      teams: 'no',
    },
    footnote: 'Docker self-hosting is first-class; it opens PRs rather than hosting a review cockpit; no multi-CLI fleet.',
  },
  {
    id: 'goose',
    name: 'Goose',
    url: 'https://goose-docs.ai/',
    kind: 'Extensible single agent',
    blurb:
      'The Apache-2.0 developer agent (born at Block, now in the Agentic AI Foundation): one highly extensible agent with native desktop apps, a CLI and 70+ MCP extensions that works inside your repos. It shines as a single pair-programmer you teach tricks, not a fleet.',
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
    footnote: 'Native desktop apps on all three platforms, but a single-agent surface — no parallel worktree fleet or review cockpit.',
  },
  {
    id: 'cursor',
    name: 'Cursor',
    url: 'https://cursor.com/',
    kind: 'AI-first IDE',
    blurb:
      'The AI-first editor with background agents on cloud machines, scheduled automations and an iOS companion for reviewing and merging on the go. Excellent as an editor with agent assists; the operation around the fleet (tickets, meetings, self-hosting) is out of scope.',
    bestFor: 'You want the best AI editor with occasional background agents, and are happy in the cloud.',
    verdict: 'Cursor and Control Center split the developer stack: Cursor is the AI-first editor you write code in, Control Center is the operation you run agents from — and it opens any PR straight into Cursor on its worktree. Keep both; they do different jobs.',
    ccEdge: 'Fleet-scale orchestration Cursor doesn’t attempt: many agents in parallel local worktrees, merge-ready review with AI verdicts, tickets, pipelines, meetings — self-hosted, multiplayer, on every screen you own.',
    cells: {
      openSource: 'no',
      desktop: 'yes',
      phone: 'partial',
      server: 'no',
      worktrees: 'partial',
      review: 'partial',
      pipelines: 'partial',
      meetings: 'no',
      teams: 'partial',
    },
    footnote: 'Background agents branch in cloud VMs rather than local worktrees; the phone app is iOS-only; automations are cloud schedules; review spans the IDE, the Review bot and mobile; team plans are a billing tier.',
  },
  {
    id: 'terminals',
    name: 'Plain terminals',
    url: 'https://code.claude.com/docs',
    kind: 'The baseline',
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
  'Control Center is the only tool in this table that runs the whole developer operation — parallel agents, PR review and merge, tickets, pipelines, meetings, calendar, memory — in one app you self-host, with native desktop clients on all three platforms, a phone companion and multiplayer for humans and agents. Single-purpose tools do their slice better in isolation: Conductor for a turnkey Mac workforce, Superset for raw parallelism, Orca for a free cross-platform ADE, Paperclip for an agent org chart, Multica for PM-style task assignment. Pick by the slice you actually need — or by whether you want the whole deck.';

/** When the cells above were last checked against each product's site. */
export const compareReviewed = 'August 2026';
