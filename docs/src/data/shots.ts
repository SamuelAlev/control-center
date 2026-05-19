// The app captures the landing page waits on. Single source of truth for two
// consumers: the hero carousel (which cycles a subset) and the pillar sections
// (which show one each), so a capture is briefed once and both places stay in
// step.
//
// Each entry names the file to drop under `docs/public/shots/` and describes
// exactly what the frame must show. Read the description before capturing:
// the point of the shot is the state it proves (running / blocked / cost /
// ownership), never a pretty empty screen.

export interface Shot {
  /** Stable key, used for tab ids and lookups. */
  id: string;
  /** Capture number, rendered as `NN` in the placeholder. */
  n: string;
  /** Full name of the screen, e.g. "The deck". */
  title: string;
  /** Short label for the carousel tab rail. */
  label: string;
  /** What the capture must show. */
  description: string;
  /** Suggested file under docs/public. */
  file: string;
  /** Capture theme. */
  theme?: 'light' | 'dark';
}

export const shots = {
  deck: {
    id: 'deck',
    n: '01',
    title: 'The deck',
    label: 'Deck',
    file: 'shots/01-dashboard.png',
    description:
      'Full app window, light theme, real data: sidebar with the pillar rail, the agents grid with live status pills (running, blocked, done), one agent transcript streaming on the right, today’s meetings in the agenda and the token-cost ticker in the header.',
  },
  agents: {
    id: 'agents',
    n: '02',
    title: 'Agents',
    label: 'Agents',
    file: 'shots/02-agents.png',
    description:
      'The agents grid mid-flight: six agent cards with status pills (two running, one blocked on an approval, the rest done), a live transcript streaming in the side panel and per-run token cost in the card footer.',
  },
  rigs: {
    id: 'rigs',
    n: '03',
    title: 'Rigs',
    label: 'Rigs',
    file: 'shots/03-rigs.png',
    description:
      'A Browser (VM) tab beside the chat: the live machine view with the agent mid-click, the Take control button in the header, the forwarded-ports popover showing 3000 → 3000 (node) and the enclosed terminal’s VM badge.',
  },
  review: {
    id: 'review',
    n: '04',
    title: 'PR review',
    label: 'Review',
    file: 'shots/04-review.png',
    description:
      'The review surface on a real diff: syntax-highlighted hunks, two inline comment threads, an AI reviewer’s rolled-up verdict with P0–P3 findings and the ship / hold / block actions in the header.',
  },
  meetings: {
    id: 'meetings',
    n: '05',
    title: 'Meetings & calendar',
    label: 'Meetings',
    file: 'shots/05-meetings.png',
    description:
      'A recorded meeting’s notes next to the calendar week: diarized transcript with speaker names, the AI summary, extracted action items with owners and the on-device privacy marker.',
  },
  pipelines: {
    id: 'pipelines',
    n: '06',
    title: 'Pipelines',
    label: 'Pipelines',
    file: 'shots/06-pipelines.png',
    description:
      'Plan Studio with a pipeline run in flight: the DAG with trigger, fan-out reviewers and join nodes, one node mid-retry showing its attempt counter and the per-run cost rollup at the bottom.',
  },
} satisfies Record<string, Shot>;

/**
 * What the hero cycles through: the whole deck first, then the four surfaces
 * that carry the operation. Pipelines is deliberately left to its own section —
 * a hero rail long enough to need a second row stops reading as one glance.
 */
export const heroShots: Shot[] = [
  shots.deck,
  shots.agents,
  shots.rigs,
  shots.review,
  shots.meetings,
];
