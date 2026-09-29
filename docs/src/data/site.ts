// Site-wide constants and the canonical product overview. Single source for
// the landing markdown twin, llms.txt, llms-full.txt and the MCP page index,
// so every agent-facing surface describes the product identically.

export const SITE_NAME = 'Control Center';
export const REPO_URL = 'https://github.com/SamuelAlev/control-center';
export const ISSUES_URL = `${REPO_URL}/issues`;
export const WEB_APP_URL = 'https://app.usectrl.dev';

export const OVERVIEW = `Control Center is a developer operations hub for one person running many streams of work. Tickets, pull requests, agents, conversations, meetings, calendar, pipelines and a personal feed share one place.

- One server, every surface: desktop, web and a paired phone render the same server-owned state. The server owns databases, credentials, external APIs and execution. The phone does not run agents. Optional fleet workers execute leased jobs without owning databases, credentials or budgets.
- Connected work: a ticket is the record. Execution happens in a conversation and its isolated copy-on-write worktree; Windows uses git worktree. Plan Studio opens from the conversation's plan row. In orchestrate mode, hiring waits for approval.
- Your next action: the inbox groups pull requests and pins approval and failed-sync blockers. Tickets, projects, a command palette and implemented Linear sync keep work connected. Jira and ClickUp are reserved names with no adapter.
- Review with context: commit-range diffs, threads, checks and deployment previews sit beside the work. A review you publish uses your forge account; agent and background publishing use the app identity. Ship, show, ask is advisory, not a mandatory gate.
- The rest of the day: read-only Google Calendar, with RSVP where permitted; server-side meeting recording and transcription, speakers, notes, decisions and action items. Summarization follows recording. RSS reading is personal, not workspace-scoped.
- Your boundaries: per-conversation propose only, act with approval or act freely profiles operate within permission policies and budgets. Soft budgets warn; hard budgets pause an agent. An approval prompt without a connected approver is denied.
- Soundscape: generative focus, relax, sleep and rise moods shaped by time and server-fetched weather. The same conditions produce the same piece.
- Solo first: collaboration chrome stays hidden with one human. Members, roles and ephemeral presence layer on when needed.
- Product media: the landing inbox is a silent looping capture of pull requests grouped by review status. Other slots are described placeholders. The separate public demo uses invented data and scripted agents with a locked-down mutating surface.
- Source: https://github.com/SamuelAlev/control-center`;
