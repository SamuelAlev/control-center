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
    question: 'What is Control Center?',
    answer:
      'Control Center is a free and open-source developer operations deck: one native app where you dispatch AI coding agents across isolated Git worktrees, review and merge what they ship, and run the surrounding operation — tickets, pipelines, meetings, calendar, memory — side by side with them. It runs on macOS, Windows and Linux, in the browser and on your phone, all rendered from one server you own.',
    links: [
      { label: 'Read the manual', href: '/manual/' },
      { label: 'What shipped lately', href: '/changelog' },
    ],
  },
  {
    question: 'How is Control Center different from running several Claude Code terminals?',
    answer:
      'Terminals give you N agents and zero cross-agent visibility. Control Center gives each agent its own copy-on-write worktree, sandbox and budget, then adds everything the terminals cannot: a PR review cockpit with AI reviewers and merge actions, pipelines that trigger work on schedules or domain events, durable agent-to-agent messaging, long-term memory and a code graph every run starts from. You steer any run mid-flight, take it over, or hand it back.',
    links: [
      { label: 'How it works', href: '/manual/concepts/architecture/' },
      { label: 'Run agents in parallel', href: '/manual/guides/parallel-agents/' },
    ],
  },
  {
    question: 'Which AI coding agents does Control Center support?',
    answer:
      'Eight runners: a built-in pure-Dart agent runtime that needs no external CLI, plus adapters for Claude Code, Codex, Pi, OpenCode, Gemini CLI, Goose and Cursor. Any OpenAI- or Anthropic-compatible endpoint also joins as a custom provider. You can mix runners in the same fleet and the same pipeline.',
    links: [{ label: 'Agent runners and adapters', href: '/manual/guides/adapters/' }],
  },
  {
    question: 'Does my code or data leave my machine?',
    answer:
      'No, unless you decide to run it that way. Control Center is local-first: state lives in SQLite files you own, meeting transcription and speaker diarization run on-device, and semantic-search embeddings are computed by an on-device model. your code host and Linear are called only from your own server, over credentials stored in your OS keychain.',
    links: [{ label: 'Security model', href: '/manual/concepts/sandbox-security/' }],
  },
  {
    question: 'Can an agent test in a real browser or run risky commands safely?',
    answer:
      'Yes — that is what rigs are for. A rig is a disposable VM the agent drives in real time: a headless browser, a Linux desktop, an Android device, or the machine behind an enclosed terminal. It has its own kernel, a throwaway disk and a network that reaches only the hosts you allow; you watch it live and can take the controls at any moment. Dev servers started inside are forwarded to localhost, to the agent’s browser and to dev domains like https://myapp.test — and nothing inside a rig ever touches your machine.',
    links: [
      { label: 'Give an agent a machine', href: '/manual/guides/use-rigs/' },
      { label: 'How enclosures work', href: '/manual/concepts/rigs/' },
    ],
  },
  {
    question: 'Is Control Center free and open source?',
    answer:
      'Yes — MIT-licensed, source on GitHub, with signed builds for every platform. The desktop apps, the headless server and the phone companion are all free; you bring your own agent subscriptions or API keys, and the built-in runtime can use any provider you can reach.',
    links: [{ label: 'Install it', href: '/#install' }],
  },
  {
    question: 'Which platforms does it run on?',
    answer:
      'Native desktop apps ship together for macOS (Apple Silicon, signed and notarized), Windows and Linux, with auto-updates. The same server also serves a web app at app.usectrl.dev and a phone companion at remote.usectrl.dev, so the operation follows you across screens without a rewrite.',
    links: [{ label: 'Download', href: '/#install' }],
  },
  {
    question: 'Can my team use Control Center together?',
    answer:
      'Yes. Humans and agents are co-equal members with workspace roles — owner, admin, member, viewer or guest — plus per-repo grants, invites and live revocation. Presence shows who is working on what (including watching an agent work), and every channel carries an autonomy dial: propose-only, act-with-approval or act-freely. With one human, the multiplayer chrome simply idles.',
    links: [{ label: 'Multiplayer concepts', href: '/manual/concepts/multiplayer/' }],
  },
  {
    question: 'Which code hosts does Control Center work with?',
    answer:
      'GitHub, GitLab and Bitbucket Cloud — and one workspace can hold repos from all three at once. Each repo is talked to through its own forge with its own credential, and the inbox merges pull requests from every one of them into a single stream. The full loop works everywhere: list and open PRs, read diffs, comment inline and at top level, review, merge, close and create. Forges genuinely differ beyond that (stacked PRs and synced viewed-state are GitHub-only, for instance), so the app hides what a host cannot do rather than showing a control that silently fails.',
    links: [
      { label: 'Connect a code host', href: '/manual/guides/connect-forges/' },
      { label: 'GitHub integration', href: '/manual/guides/github-integration/' },
    ],
  },
  {
    question: 'How does Control Center work with Linear?',
    answer:
      'Linear syncs tickets bidirectionally with projects, statuses, labels and assignees; Jira and ClickUp providers are scaffolded. Tickets themselves are vendor-neutral, so the same board works whichever tracker you sync.',
    links: [{ label: 'Linear integration', href: '/manual/guides/linear-integration/' }],
  },
];
