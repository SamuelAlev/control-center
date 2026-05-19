# Product

## Register

product

## Users

A solo, technical, multi-platform operator: one developer running many concurrent streams of work (coding agents on isolated Git worktrees, meetings being recorded, a calendar filling up, PRs to review, feeds and conversations updating) and holding all of it in view at once. They keep the app open all day next to real work, on desktop (keyboard-first, dense), web, and phone (touch-first remote). The operation can also span machines: headless fleet workers (`cc_worker`) execute leased jobs while one server stays the source of truth.

Team use is shipped and additive, never a rewrite: workspace members, roles, and invites are real, humans and agents share one roster as co-equal `Principal`s, and presence, follow-mode, and steer/take-over layer on top. With one human, the presence lane idles and no roster chrome appears — solo stays the default shape; attribution stays legible as more humans join.

## Product Purpose

Control Center is a unified developer operations hub: a native GUI for orchestrating AI agents across isolated Git worktrees with GitHub/Linear integration, PR review, meetings, calendar, messaging, ticketing, pipelines, and workspace management. Agents are one pillar among co-equal ones (messaging, tickets, meetings, calendar, newsfeed, PR review, pipelines and plans, observability). Success looks like situational command in one glance: status, ownership, and the next action surfaced by default across every pillar, with nothing essential buried a level deep. One operator can run the whole thing from one machine; the same server can fan execution out to fleet workers and open the workspace to teammates without changing shape.

## Brand Personality

**Alive, warm, confident.** Alive because the surface reports real machine state as it happens (an agent thinking/running/blocked/done/costing, a meeting recording, a sync in flight). Warm in the Anthropic register: intelligent, on-your-side, never cold or corporate. Confident: direct and technical, no hype. Warmth and expression live in voice and a few earned thresholds (onboarding, the dashboard deck, shader backgrounds); day-to-day surfaces stay quiet, dense, and consistent.

## Anti-references

- **Generic SaaS dashboard.** No gradient hero-metric cards, no identical rounded card grids, no decorative charts, no purple gradients.
- **Default component-kit / template feel.** Distinction comes from making the model legible (an agent thinking vs. blocked, a meeting recording, a conversation threading a PR), never from decoration or skins.

## Design Principles

1. **Presence over decoration.** Motion, color, and "life" must report real state, or they are cut.
2. **Situational command in one glance.** Surface status, ownership, and the next action by default; bury nothing essential a level deep.
3. **Distinctive through behavior, not skins.** Escape the component-kit feel by making the model legible, not by adding decoration.
4. **Warm confidence, earned.** Warmth lives in voice and a few thresholds; everyday surfaces stay quiet, dense, and consistent with one component vocabulary.
5. **Solo-first, team-capable, multi-platform continuity.** Optimize for one operator; multiplayer (members, roles, presence, follow/steer) and fleet execution layer on additively, and with one human the collaboration chrome disappears. Keep the operation coherent across desktop/web/phone (no surface a degraded afterthought), and keep attribution legible — every actor, human or agent, is a first-class Principal — so team use is additive, not a rewrite.

## Accessibility & Inclusion

WCAG 2.1 AAA where feasible, AA as the hard floor. Never status-by-color-alone (every state pairs color with an icon/shape and a text label). Full reduced-motion alternatives for every animated/presence element. Keyboard-first on desktop (always-visible focus rings) and touch-ergonomic on phone (≥44px targets, no hover-only affordances).
