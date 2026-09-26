// Landing-page FAQ. Single source of truth for two consumers: the Faq
// component on the landing page (question-shaped H3s + FAQPage JSON-LD) and
// llms-full.txt (plain-text answers, verbatim). Keep answers plain text —
// links live in `links`, so the JSON-LD and the LLM dump never need to strip
// markup. Question-shaped headings + answer-first copy are deliberate: they
// are what featured snippets and AI Overviews extract.

export interface FaqItem {
  question: string;
  /** Plain-text answer. The first sentence must stand alone as the answer. */
  answer: string;
  /** Optional deeper links (label + in-app path). */
  links?: { label: string; href: string }[];
}

export const faqs: FaqItem[] = [
  {
    question: 'Is Control Center only for AI agents?',
    answer:
      'No. Control Center puts tickets, pull requests, conversations, meetings, calendar, pipelines, agents and a personal RSS reader in one workspace. Agents are one part of the desk, not a prerequisite for using the others.',
    links: [{ label: 'Explore the features', href: '/#features' }],
  },
  {
    question: 'What is the difference between a ticket and a conversation?',
    answer:
      'A ticket records the work and its status; execution happens in a conversation. The conversation can provision an isolated copy-on-write worktree before an agent run. On Windows, provisioning uses a Git worktree.',
    links: [{ label: 'Follow a sample workflow', href: '/#workflows' }],
  },
  {
    question: 'Where do agents run, and what does the server do?',
    answer:
      'The server owns the workspace database, credentials, APIs and agent execution; desktop and browser clients display and control that work. Optional fleet workers pull leased jobs and stream events, but do not hold the database, credentials or budgets.',
    links: [{ label: 'Read the architecture guide', href: '/manual/concepts/architecture/' }],
  },
  {
    question: 'How much control do I have over an agent run?',
    answer:
      'Each conversation can use Propose only, Act with approval or Act freely. Permissions and a sandbox still bound allowed actions; approval requests without an approver are denied. Soft budget limits warn, hard limits pause, and runs keep a log.',
    links: [{ label: 'Preview the controls', href: '/#boundaries' }],
  },
  {
    question: 'Does an orchestrate plan hire agents automatically?',
    answer:
      'No. Orchestrate can research and propose roles, child tickets and a plan, but hiring waits for approval. Plan Studio opens from the plan row in the originating conversation; a ticket assignment alone does not start a run.',
    links: [{ label: 'Follow the sample workflow', href: '/#workflows' }],
  },
  {
    question: 'Can I run agents from the paired phone?',
    answer:
      'The paired phone is a thin client for the same server-backed workspace, not a second execution host. Desktop, browser and phone show the same operation; agents execute on the server or on optional leased fleet workers.',
    links: [{ label: 'See the connected surfaces', href: '/#surfaces' }],
  },
  {
    question: 'Which integrations can I use?',
    answer:
      'Linear ticket sync is implemented; Jira and ClickUp do not have adapters. Connected Google Calendar events are read-only, with RSVP only when the calendar grants write permission. Slack threads can bridge into conversations, and connected code hosts supply pull requests and checks.',
    links: [{ label: 'Read the manual', href: '/manual/' }],
  },
  {
    question: 'When do meeting notes and action items appear?',
    answer:
      'The live transcript can separate speakers while recording. After you stop, the summarizer processes the meeting and stores its notes, decisions and action items; recording and processing are distinct states.',
    links: [{ label: 'See the day in context', href: '/#day' }],
  },
  {
    question: 'Is the public demo a live workspace?',
    answer:
      'The public demo is a separate, locked-down build with invented data and scripted agents. Its records and runs are examples, not your own work.',
    links: [{ label: 'Explore the live demo', href: '/demo' }],
  },
];
