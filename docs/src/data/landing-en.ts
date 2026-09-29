import { faqs } from "./faq";

export const en = {
  meta: {
    title: "Control Center \\\\ A home for your developer day",
    description:
      "Bring tickets, code reviews, AI agents, meetings and pipelines together. A free, open-source developer workspace for desktop, web and phone.",
    imageAlt: "Control Center, your developer operation in one workspace.",
  },
  nav: {
    product: "Product",
    workflows: "Workflows",
    features: "Features",
    docs: "Documentation",
    demo: "Try demo",
    download: "Download",
    menu: "Menu",
    primary: "Primary navigation",
    mobile: "Mobile navigation",
    home: "Control Center home",
    skip: "Skip to content",
    language: "Language",
    appearance: "Appearance",
    light: "Light",
    dark: "Dark",
    system: "System",
  },
  hero: {
    line1: "Many moving parts.",
    line2: "One Control Center.",
    description:
      "A home for your code, agents, reviews and everything else that makes a developer day.",
    download: "Get Control Center",
    demo: "Explore the live demo",
    platforms: "macOS, Windows, Linux",
    web: "Also on web and phone",
  },
  media: {
    phone:
      "Phone companion showing the same workspace, a pending approval and the status of an agent run.",
  },
  tour: {
    label: "Explore Control Center",
    previous: "Previous product view",
    next: "Next product view",
    play: "Play tour",
    pause: "Pause tour",
    videoPlay: "Play preview",
    videoPause: "Pause preview",
    expand: "Expand preview",
    preview: "Product preview",
    close: "Close preview",
    note: "A closer look at your developer day.",
    imageLanguage: "Image / video placeholder",
    stops: [
      {
        kind: "desk",
        label: "Your day",
        title: "Start with what needs you.",
        description:
          "Review requests, approvals and blockers. Your next action, without the tab hunt.",
        alt: "Control Center inbox grouping pull requests by review status and showing a pending approval.",
      },
      {
        kind: "agents",
        label: "Agents",
        title: "Give good work room to happen.",
        description:
          "Run agents in isolated worktrees. Follow their tools, steer the work and keep the context.",
        alt: "An agent conversation in Control Center with its task context and activity.",
      },
      {
        kind: "review",
        label: "Code review",
        title: "Read the change. Know the story.",
        description:
          "Diffs, discussions and checks stay together. Publish the review as yourself.",
        alt: "Control Center pull request review with code changes and review context.",
      },
      {
        kind: "tickets",
        label: "Tickets",
        title: "Keep the next step connected.",
        description:
          "Track priorities and ownership, sync Linear, and link the conversation where work happens.",
        alt: "Control Center ticket board showing tasks grouped by status.",
      },
      {
        kind: "meetings",
        label: "Meetings",
        title: "Keep the decisions after the call.",
        description:
          "Record and transcribe on your server. Get notes and action items when the meeting ends.",
        alt: "A meeting in Control Center with transcript and meeting information.",
      },
      {
        kind: "pipelines",
        label: "Pipelines",
        title: "Make the repeatable work repeatable.",
        description:
          "Build a workflow, choose its trigger and follow every step of the run.",
        alt: "Control Center pipeline view with workflow steps and run status.",
      },
    ],
  },
  integrations: {
    title: "Bring the tools you already work with.",
    note: "Connected through your server, not another copy of your day.",
  },
  grid: {
    title: "The tools you’ll reach for every day.",
    description: "Run the work, review what changed and keep the decisions.",
    more: "Read the documentation",
    items: [
      {
        title: "Parallel agents",
        description:
          "Give each task an isolated Git worktree. Follow the run, steer an agent or take over without disturbing the rest.",
        link: "Run agents in parallel",
        kind: "agents",
        href: "/manual/guides/parallel-agents/",
      },
      {
        title: "Pull request review",
        description:
          "Read diffs with discussions and checks alongside. Add an AI review when it helps, then publish with your own forge account.",
        link: "Review a pull request",
        kind: "review",
        href: "/manual/guides/review-merge-pr/",
      },
      {
        title: "Connected tickets",
        description:
          "Sync Linear, set priorities and assign the work. Link the ticket to the conversation where it gets done.",
        link: "Manage tickets",
        kind: "tickets",
        href: "/manual/guides/manage-tickets/",
      },
      {
        title: "Meeting notes",
        description:
          "Record and transcribe on your server. Keep the decisions and action items after the call ends.",
        link: "Record a meeting",
        kind: "meetings",
        href: "/manual/guides/record-meeting/",
      },
      {
        title: "Repeatable pipelines",
        description:
          "Build a workflow once. Run it on a schedule, from an event or by hand, and inspect every step.",
        link: "Build a pipeline",
        kind: "pipelines",
        href: "/manual/guides/create-pipeline/",
      },
      {
        title: "Account switching",
        description:
          "Choose the accounts each agent can use, then rotate across them without losing the run's context.",
        link: "Manage model providers",
        kind: "accounts",
        href: "/manual/guides/adapters/",
        alt: "Control Center account pool editor showing eligible accounts for an agent.",
      },
      {
        title: "Usage quota",
        description:
          "Check provider allowance and reset times before starting the next run.",
        link: "Manage costs",
        kind: "quota",
        href: "/manual/guides/manage-costs/",
        alt: "Control Center usage panel showing provider quotas and reset times.",
      },
      {
        title: "Soundscapes & focus",
        description:
          "Run a timed focus session, quiet notifications and shape the soundscape playing under it.",
        link: "Use focus mode",
        kind: "focus",
        href: "/manual/guides/focus-mode/",
        alt: "Control Center focus timer and soundscape controls.",
      },
      {
        title: "Observability",
        description:
          "Follow live agents and inspect run costs, token use and latency in your workspace.",
        link: "Inspect agent runs",
        kind: "observability",
        href: "/manual/guides/manage-costs/",
        alt: "Control Center observability view showing live agents and run insights.",
      },
      {
        title: "Skill and agent editors",
        description:
          "Edit workspace skills and configure each agent's model, instructions and permissions.",
        link: "Manage skills",
        kind: "editors",
        href: "/manual/guides/manage-skills/",
        alt: "Control Center skill editor and agent settings.",
      },
    ],
    supporting: [
      {
        title: "One inbox",
        description:
          "Reviews, approvals and blockers in one queue. Jump to the next task with the command palette.",
        href: "/manual/guides/triage-inbox/",
      },
      {
        title: "Check in from your phone",
        description:
          "Follow your runs and handle approvals without returning to your desk.",
        href: "/manual/concepts/remote-control/",
      },
    ],
  },
  workflow: {
    title: "Keep the thread.\nAll the way to shipped.",
    description: "Work moves between tools. Its context should come along.",
    label: "A connected workflow",
    steps: [
      {
        title: "Start with the ticket.",
        text: "Set the priority, name the owner and link the conversation. The ticket keeps the record.",
        kind: "tickets",
        label: "The intent",
      },
      {
        title: "Give the work its own space.",
        text: "Discuss a plan, prepare an isolated worktree and run the agent. Steer or take over when you need to.",
        kind: "agents",
        label: "The work",
      },
      {
        title: "Bring the result into review.",
        text: "Read the changes, follow the discussion and publish with your forge account. The story stays connected.",
        kind: "review",
        label: "The result",
      },
    ],
  },
  boundaries: {
    title: "Approve a push before it runs.",
    description:
      "Put Git pushes, PR publishing and other guarded actions behind an approval. Review what the agent is about to do before it changes anything.",
    media:
      "An agent run paused at a Git push approval request. Show the proposed command, working directory and the operator’s approve/deny controls.",
    note: "No approver connected? The action is denied. Permissions are enforced by your server, not by a prompt.",
    link: "Configure action approvals",
  },
  surfaces: {
    title: "Your desk is a place.\nYour work isn’t.",
    description:
      "Start on desktop. Check in from the browser. Stay close from your phone. One server keeps the operation together.",
    desktop: "Native desktop",
    web: "In your browser",
    phone: "Phone companion",
    note: "Your server owns the data and execution. Your devices stay in sync.",
    link: "Find your platform",
  },
  faq: {
    title: "Good questions.",
    description: "A few things to know before you settle in.",
    items: faqs,
  },
  pilot: {
    controls:
      "3D paraglider. Drag to orbit and steer. Left/right arrows turn; up/down arrows pitch up or down. R resets; Space pauses or resumes flight and wind.",
  },
  install: {
    title: "Make yourself\nat home.",
    description:
      "Your next developer day can start here. Free and open source.",
    mac: "Apple Silicon · macOS 13+",
    windows: "x64 · Windows 10+",
    linux: "x86_64 · AppImage",
    release: "View releases",
    web: "Open the web app",
    phone: "Open the phone companion",
    webNote: "Connect to a server you run.",
    phoneNote: "Pair with your server over a sealed relay.",
    selfHost: "Prefer to host it yourself?",
    server: "Run a headless server",
    guide: "Read the quick-start guide",
  },
  footer: {
    tagline: "A home for your developer day.",
    resources: "Resources",
    source: "Source on GitHub",
    compare: "Compare",
    changelog: "Changelog",
    about: "About",
    contact: "Contact",
    privacy: "Privacy",
    terms: "Terms",
    licenses: "Licenses",
    acknowledgements: "Acknowledgements",
    made: "Built in the open.",
    top: "Back to top",
  },
};

export type LandingCopy = typeof en;
