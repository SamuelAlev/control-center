/** Landing recordings. Frame size matches the source (2880×1864, or 2884×1864). */

import { media } from './cdn';

export type ProductCapture = {
  src: string;
  poster: string;
  /** Small 60 fps clip for feature-grid hover. Omitted when the clip is not in the grid. */
  motion?: string;
  width: number;
  height: number;
};

const frame = { width: 2880, height: 1864 } as const;
const wide = { width: 2884, height: 1864 } as const;
const narrow = { width: 2882, height: 1864 } as const;

export const productCaptures = {
  desk: { ...media.inboxReview, ...frame },
  agents: { ...media.agentConversation, ...frame },
  review: { ...media.prDiff, ...frame },
  tickets: { ...media.tickets, ...frame },
  meetings: { ...media.meetings, ...frame },
  pipelines: { ...media.pipelines, ...wide },
  focus: { ...media.soundscape, ...frame },
  quota: { ...media.usageSubscription, ...wide },
} as const satisfies Record<string, ProductCapture>;

/** Feature-grid clips. Some cards use a different recording than the hero stop of the same name. */
export const featureCaptures = {
  agents: { ...media.parallelAgents, ...narrow },
  review: { ...media.aiReview, ...frame },
  pipelines: { ...media.pipelineTemplates, ...frame },
  accounts: { ...media.accountSwitching, ...narrow },
  observability: { ...media.observability, ...frame },
  editors: { ...media.agentsAndSkills, ...frame },
  meetings: productCaptures.meetings,
  tickets: productCaptures.tickets,
  focus: productCaptures.focus,
  quota: productCaptures.quota,
} as const satisfies Record<string, ProductCapture>;

export type CaptureKind = keyof typeof productCaptures;

export function captureFor(kind: string): ProductCapture | undefined {
  if (Object.hasOwn(productCaptures, kind)) return productCaptures[kind as CaptureKind];
  return undefined;
}

export function featureCaptureFor(kind: string): ProductCapture | undefined {
  if (Object.hasOwn(featureCaptures, kind)) return featureCaptures[kind as keyof typeof featureCaptures];
  return undefined;
}

/** Workflow steps. Review follows the pull-request card; the other two follow the hero. */
export function workflowCaptureFor(kind: string): ProductCapture | undefined {
  if (kind === 'review') return featureCaptures.review;
  if (kind === 'agents') return productCaptures.agents;
  if (kind === 'tickets') return productCaptures.tickets;
  return undefined;
}

export const approvalCapture = { ...media.agentPermissions, ...frame } satisfies ProductCapture;
