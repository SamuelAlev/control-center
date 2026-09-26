import type { LandingCopy } from './landing-en';

export const enGb: LandingCopy = {
  meta: {
    title: 'Control Center | A home for your developer day',
    description: 'Bring tickets, code reviews, AI agents, meetings and pipelines together. A free, open-source developer workspace for desktop, web and phone.',
    imageAlt: 'Control Center, your developer operation in one workspace.',
  },
  nav: { product: 'Product', workflows: 'Workflows', features: 'Features', docs: 'Documentation', demo: 'Try demo', download: 'Download', menu: 'Menu', primary: 'Primary navigation', mobile: 'Mobile navigation', home: 'Control Center home', skip: 'Skip to content', language: 'Language', appearance: 'Appearance', light: 'Light', dark: 'Dark', system: 'System' },
  hero: {
    line1: 'Many moving parts.',
    line2: 'One Control Center.',
    description: 'A home for your code, agents, reviews and everything else that makes a developer day.',
    download: 'Get Control Center',
    demo: 'Explore the live demo',
    platforms: 'macOS, Windows, Linux',
    web: 'Also on the web and your phone',
  },
  media: {
    phone: 'Phone companion showing the same workspace, a pending approval and the status of an agent run.',
  },
  tour: {
    label: 'Explore Control Center',
    previous: 'Previous product view', next: 'Next product view',
    play: 'Play tour', pause: 'Pause tour', expand: 'Expand preview', close: 'Close preview',
    preview: 'Product preview', note: 'A closer look at your developer day.', imageLanguage: 'Image or video placeholder',
    stops: [
      { kind: 'desk', label: 'Your day', title: 'Start with what needs you.', description: 'Review requests, approvals and blockers. Your next action, without the tab hunt.', alt: 'Control Center inbox grouping pull requests by review status and showing a sync blocker.' },
      { kind: 'agents', label: 'Agents', title: 'Give good work room to happen.', description: 'Run agents in isolated worktrees. Follow their tools, steer the work and keep the context.', alt: 'An agent conversation in Control Center with its task context and activity.' },
      { kind: 'review', label: 'Code review', title: 'Read the change. Know the story.', description: 'Diffs, discussions and checks stay together. Publish the review as yourself.', alt: 'Control Center pull request review with code changes and review context.' },
      { kind: 'tickets', label: 'Tickets', title: 'Keep the next step connected.', description: 'Track priorities and ownership, sync Linear, and link the conversation where work happens.', alt: 'Control Center ticket board showing tasks grouped by status.' },
      { kind: 'meetings', label: 'Meetings', title: 'Keep the decisions after the call.', description: 'Record and transcribe on your server. Get notes and action items when the meeting ends.', alt: 'A meeting in Control Center with transcript and meeting information.' },
      { kind: 'pipelines', label: 'Pipelines', title: 'Make the repeatable work repeatable.', description: 'Build a workflow, choose its trigger and follow every step of the run.', alt: 'Control Center pipeline view with workflow steps and run status.' },
    ],
  },
  integrations: { title: 'Bring the tools you already work with.', note: 'Connected through your server, not another copy of your day.' },
  grid: {
    title: 'The tools you’ll reach for every day.',
    description: 'Run the work, review what changed and keep the decisions.',
    more: 'Read the documentation',
    items: [
      { title: 'Parallel agents', description: 'Give each task an isolated Git worktree. Follow the run, steer an agent or take over without disturbing the rest.', link: 'Run agents in parallel', kind: 'agents', href: '/manual/guides/parallel-agents/' },
      { title: 'Pull request review', description: 'Read diffs with discussions and checks alongside. Add an AI review when it helps, then publish with your own forge account.', link: 'Review a pull request', kind: 'review', href: '/manual/guides/review-merge-pr/' },
      { title: 'Connected tickets', description: 'Sync Linear, set priorities and assign the work. Link the ticket to the conversation where it gets done.', link: 'Manage tickets', kind: 'tickets', href: '/manual/guides/manage-tickets/' },
      { title: 'Meeting notes', description: 'Record and transcribe on your server. Keep the decisions and action items after the call ends.', link: 'Record a meeting', kind: 'meetings', href: '/manual/guides/record-meeting/' },
      { title: 'Repeatable pipelines', description: 'Build a workflow once. Run it on a schedule, from an event or by hand, and inspect every step.', link: 'Build a pipeline', kind: 'pipelines', href: '/manual/guides/create-pipeline/' },
    ],
    supporting: [
      { title: 'One inbox', description: 'Reviews, approvals and blockers in one queue. Jump to the next task with the command palette.', href: '/manual/guides/triage-inbox/' },
      { title: 'Time to focus', description: 'Quiet notifications, start a focus session and choose a generative soundscape.', href: '/manual/guides/focus-mode/' },
      { title: 'Check in from your phone', description: 'Follow your runs and handle approvals without returning to your desk.', href: '/manual/concepts/remote-control/' },
    ],
  },
  workflow: {
    title: 'Keep the thread.\nAll the way to shipped.',
    description: 'Work moves between tools. Its context should come along.',
    label: 'A connected workflow',
    steps: [
      { title: 'Start with the ticket.', text: 'Set the priority, name the owner and link the conversation. The ticket keeps the record.', kind: 'tickets', label: 'The intent' },
      { title: 'Give the work its own space.', text: 'Discuss a plan, prepare an isolated worktree and run the agent. Steer or take over when you need to.', kind: 'agents', label: 'The work' },
      { title: 'Bring the result into review.', text: 'Read the changes, follow the discussion and publish with your forge account. The story stays connected.', kind: 'review', label: 'The result' },
    ],
  },
  boundaries: {
    title: 'Approve a push before it runs.',
    description: 'Put Git pushes, PR publishing and other guarded actions behind an approval. Review what the agent is about to do before it changes anything.',
    media: 'An agent run paused at a Git push approval request. Show the proposed command, working directory and the operator’s approve or deny controls.',
    note: 'No approver connected? The action is denied. Permissions are enforced by your server, not by a prompt.',
    link: 'Configure action approvals',
  },
  surfaces: {
    title: 'Your desk is a place.\nYour work isn’t.',
    description: 'Start on desktop. Check in from the browser. Stay close from your phone. One server keeps the operation together.',
    desktop: 'Native desktop', web: 'In your browser', phone: 'Phone companion',
    note: 'Your server owns the data and execution. Your devices stay in sync.',
    link: 'Find your platform',
  },
  faq: {
    title: 'Good questions.', description: 'A few things to know before you settle in.',
    items: [
      { question: 'Is Control Center only for AI agents?', answer: 'No. Control Center puts tickets, pull requests, conversations, meetings, calendar, pipelines, agents and a personal RSS reader in one workspace. Agents are one part of the desk, not a prerequisite for using the others.', links: [{ label: 'Explore the features', href: '/en-GB/#features' }] },
      { question: 'What is the difference between a ticket and a conversation?', answer: 'A ticket records the work and its status; execution happens in a conversation. The conversation can provision an isolated copy-on-write worktree before an agent run. On Windows, provisioning uses a Git worktree.', links: [{ label: 'Follow a sample workflow', href: '/en-GB/#workflows' }] },
      { question: 'Where do agents run, and what does the server do?', answer: 'The server owns the workspace database, credentials, APIs and agent execution; desktop and browser clients display and control that work. Optional fleet workers pull leased jobs and stream events, but do not hold the database, credentials or budgets.', links: [{ label: 'Read the architecture guide', href: '/manual/concepts/architecture/' }] },
      { question: 'How much control do I have over an agent run?', answer: 'Each conversation can use Propose only, Act with approval or Act freely. Permissions and a sandbox still bound allowed actions; approval requests without an approver are denied. Soft budget limits warn, hard limits pause, and runs keep a log.', links: [{ label: 'Preview the controls', href: '/en-GB/#boundaries' }] },
      { question: 'Does an orchestrate plan hire agents automatically?', answer: 'No. Orchestrate can research and propose roles, child tickets and a plan, but hiring waits for approval. Plan Studio opens from the plan row in the originating conversation; a ticket assignment alone does not start a run.', links: [{ label: 'Follow the sample workflow', href: '/en-GB/#workflows' }] },
      { question: 'Can I run agents from the paired phone?', answer: 'The paired phone is a thin client for the same server-backed workspace, not a second execution host. Desktop, browser and phone show the same operation; agents execute on the server or on optional leased fleet workers.', links: [{ label: 'See the connected surfaces', href: '/en-GB/#surfaces' }] },
      { question: 'Which integrations can I use?', answer: 'Linear ticket sync is implemented; Jira and ClickUp do not have adapters. Connected Google Calendar events are read-only, with RSVP only when the calendar grants write permission. Slack threads can bridge into conversations, and connected code hosts supply pull requests and checks.', links: [{ label: 'Read the manual', href: '/manual/' }] },
      { question: 'When do meeting notes and action items appear?', answer: 'The live transcript can separate speakers while recording. After you stop, the summariser processes the meeting and stores its notes, decisions and action items; recording and processing are distinct states.', links: [{ label: 'See the day in context', href: '/en-GB/#day' }] },
      { question: 'Is the public demo a live workspace?', answer: 'The public demo is a separate, locked-down build with invented data and scripted agents. Its records and runs are examples, not your own work.', links: [{ label: 'Explore the live demo', href: '/demo' }] },
    ],
  },
  pilot: {
      controls: '3D paraglider. Drag to orbit and steer. Left/right arrows turn; up/down arrows pitch up or down. R resets; Space pauses or resumes flight and wind.',
    },
  install: {
    title: 'Make yourself\nat home.', description: 'Your next developer day can start here. Free and open source.',
    mac: 'Apple Silicon · macOS 13+', windows: 'x64 · Windows 10+', linux: 'x86_64 · AppImage',
    release: 'View releases', web: 'Open the web app', phone: 'Open the phone companion',
    webNote: 'Connect to a server you run.', phoneNote: 'Pair with your server over a sealed relay.',
    selfHost: 'Prefer to host it yourself?', server: 'Run a headless server', guide: 'Read the quick-start guide',
  },
  footer: { tagline: 'A home for your developer day.', resources: 'Resources', source: 'Source on GitHub', compare: 'Compare', changelog: 'Changelog', about: 'About', contact: 'Contact', privacy: 'Privacy', terms: 'Terms', licenses: 'Licences', acknowledgements: 'Acknowledgements', made: 'Built in the open.', top: 'Back to top' },
};
