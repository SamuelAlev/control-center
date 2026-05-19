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
    id: 'v0-2-0',
    version: 'v0.2.0',
    date: 'Jun 5, 2026',
    isoDate: '2026-06-05',
    tag: 'Feature release',
    title: 'Pipelines, Focus Mode, and an MCP surface',
    lead: 'The fleet learns to run itself. Chain agents into DAG pipelines, review their pull requests without leaving the keyboard, and drive the whole cockpit from any MCP client.',
    latest: true,
    showViz: true,
    vizBranch: 'feature/onboarding',
    changes: [
      {
        type: 'new',
        items: [
          '<b>DAG pipelines.</b> Compose multi-step agent work as a directed graph. Wire stages, fan-out, and gates in the visual template editor; the execution engine runs each stage across isolated worktrees.',
          '<b>Focus Mode.</b> An ephemeral, distraction-free PR review surface — open a pull request, read the diff with inline comments, and merge without leaving the keyboard.',
          '<b>MCP server with 70 typed tools.</b> Control Center now exposes its own MCP server, so any MCP client can dispatch agents, read and update tickets, and query workspace memory.',
          '<b>Agent teams.</b> Group agents into teams and dispatch coordinated work to all of them in a single move.',
        ],
      },
      {
        type: 'improved',
        items: [
          '<b>Honest dashboard.</b> The global dashboard now matches live OS processes to their agents, so a busy fleet reports real CPU and cost per agent.',
          "<b>Loud workspace isolation.</b> Cross-workspace reads fail with a clear <code>WorkspaceMismatchException</code> instead of silently returning empty — one workspace's data never surfaces in another.",
          '<b>Keyboard everywhere.</b> Every action on the PR and ticket surfaces is reachable without a mouse, with the 2px focus ring visible throughout.',
        ],
      },
      {
        type: 'fixed',
        items: [
          '<b>Status is never color alone.</b> Every agent, PR, and pipeline state now pairs its color with an icon and a label — legible for color-blind operators.',
          '<b>Reduced-motion gaps.</b> Presence animations and the shader backgrounds now have a full reduced-motion path; none fall back to a blank surface.',
          '<b>Secret redaction.</b> Command output is scrubbed before it reaches agent run logs — tokens and keys no longer leak into history.',
        ],
      },
    ],
  },
  {
    id: 'v0-1-0',
    version: 'v0.1.0',
    date: 'May 20, 2026',
    isoDate: '2026-05-20',
    tag: 'Initial release',
    title: 'Control Center takes off',
    lead: 'The first public build, for macOS 13 and later. Spawn a fleet of coding agents, each in its own Git worktree, and command the whole thing from one deck.',
    changes: [
      {
        type: 'new',
        items: [
          "<b>Live agent presence.</b> Watch every agent's state at a glance — thinking, running, blocked, failed, or done — on a dashboard that breathes with real work.",
          '<b>Pull-request review.</b> A built-in diff viewer with inline comments and review sessions, so you approve and merge agent output in place.',
          '<b>GitHub & Linear.</b> Authenticate with a GitHub PAT or the <code>gh</code> CLI; track work through vendor-agnostic tickets backed by Local or Linear.',
          '<b>OS-native sandboxing.</b> Agents run inside platform sandboxes with capability controls and brokered credentials — they touch only what you allow.',
          '<b>Workspace memory.</b> A workspace-scoped knowledge base with embeddings and a knowledge graph that agents read from and write back to.',
        ],
      },
    ],
    note: 'macOS 13+ · Windows and Linux builds are in testing.',
  },
];
