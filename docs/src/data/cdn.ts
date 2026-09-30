/** Content-hashed files published at files.usectrl.dev. Paths match docs/public. */

export const FILES_ORIGIN = 'https://files.usectrl.dev';

const file = (path: string) => `${FILES_ORIGIN}${path}`;

export const cdn = {
  favicon: file('/favicon.b67c6019.svg'),
  ogImage: file('/og.208bcc4b.png'),
  feedIcon: file('/feed-icon.00ee24a8.png'),
  fonts: {
    manrope: file('/fonts/Manrope-Variable.5ae62fba.woff2'),
    firaCode: file('/fonts/FiraCode-VF.408e876a.woff2'),
  },
  alpine: {
    hero: {
      model: file('/alpine/hero-pilot.8bf5c131.glb'),
      poster: file('/alpine/hero-pilot.39056fc1.webp'),
    },
    install: {
      model: file('/alpine/install-pilot.ab7164a7.glb'),
      poster: file('/alpine/install-pilot.e09a7419.webp'),
    },
  },
} as const;

export const media = {
  inboxReview: {
    src: file('/media/inbox-review.131a7b26.mp4'),
    poster: file('/media/inbox-review.f5e789b8.webp'),
  },
  agentConversation: {
    src: file('/media/agent-conversation.745704de.mp4'),
    poster: file('/media/agent-conversation.7bbdf48c.webp'),
    motion: file('/media/agent-conversation-hover.d576466e.mp4'),
  },
  prDiff: {
    src: file('/media/pr-diff.e232d637.mp4'),
    poster: file('/media/pr-diff.f63ce4fc.webp'),
    motion: file('/media/pr-diff-hover.45cba1db.mp4'),
  },
  tickets: {
    src: file('/media/tickets.e636de87.mp4'),
    poster: file('/media/tickets.abcbfb0b.webp'),
    motion: file('/media/tickets-hover.bff34061.mp4'),
  },
  meetings: {
    src: file('/media/meetings.ee388d38.mp4'),
    poster: file('/media/meetings.2fde5b3d.webp'),
    motion: file('/media/meetings-hover.df202c39.mp4'),
  },
  pipelines: {
    src: file('/media/pipelines.734dbc3d.mp4'),
    poster: file('/media/pipelines.132302c0.webp'),
    motion: file('/media/pipelines-hover.3a8f5bcb.mp4'),
  },
  soundscape: {
    src: file('/media/soundscape.1d8bdc98.mp4'),
    poster: file('/media/soundscape.d02f76a1.webp'),
    motion: file('/media/soundscape-hover.687b641e.mp4'),
  },
  usageSubscription: {
    src: file('/media/usage-subscription.44b25dd5.mp4'),
    poster: file('/media/usage-subscription.4e0244a0.webp'),
    motion: file('/media/usage-subscription-hover.ab6c67b0.mp4'),
  },
  accountSwitching: {
    src: file('/media/account-switching.40d146ad.mp4'),
    poster: file('/media/account-switching.70aed6db.webp'),
    motion: file('/media/account-switching-hover.7d3358d7.mp4'),
  },
  aiReview: {
    src: file('/media/ai-review.901e288f.mp4'),
    poster: file('/media/ai-review.08ad31cf.webp'),
    motion: file('/media/ai-review-hover.91bfcfff.mp4'),
  },
  observability: {
    src: file('/media/observability.9996df05.mp4'),
    poster: file('/media/observability.064b9ad3.webp'),
    motion: file('/media/observability-hover.45811608.mp4'),
  },
  parallelAgents: {
    src: file('/media/parallel-agents.da43e022.mp4'),
    poster: file('/media/parallel-agents.482b05f8.webp'),
    motion: file('/media/parallel-agents-hover.a22183ae.mp4'),
  },
  pipelineTemplates: {
    src: file('/media/pipeline-templates.e8000d64.mp4'),
    poster: file('/media/pipeline-templates.40342601.webp'),
    motion: file('/media/pipeline-templates-hover.2cb68657.mp4'),
  },
  agentsAndSkills: {
    src: file('/media/agents-and-skills.52466165.mp4'),
    poster: file('/media/agents-and-skills.2e4bc4f3.webp'),
    motion: file('/media/agents-and-skills-hover.04525a01.mp4'),
  },
  agentPermissions: {
    src: file('/media/agent-permissions.8c6f6f60.mp4'),
    poster: file('/media/agent-permissions.41407480.webp'),
    motion: file('/media/agent-permissions-hover.bd297bd6.mp4'),
  },
} as const;
