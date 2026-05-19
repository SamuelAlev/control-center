# Product

## Register

product

## Users

A solo, technical operator running a developer operations hub from a quiet, well-instrumented deck. They are tool-fluent (git, terminals, IDEs, GitHub, Linear), impatient with friction, and usually in deep focus while several things run in parallel: AI coding agents on isolated worktrees, a meeting recording and transcribing, a calendar filling up, feeds and conversations updating.

Their job is not a single workflow. It is holding the whole operation in view and acting on whatever needs them next: dispatch and steer agents, review and merge the PRs they produce, capture and act on meeting notes, stay on top of the calendar and the feed, and keep conversations moving. The hard part is not any one action; it is situational command across many pillars without losing the thread.

They move across **three first-class surfaces**: the desktop app (primary, dense, keyboard-driven), a web thin client, and a phone remote-control app. The same operation must feel coherent wherever they pick it up. No surface is a degraded afterthought.

Team use is a near-term horizon, not today's reality. The design optimizes for one operator now, but keeps ownership, attribution, and visibility legible so shared-agent and multi-human use is an additive step rather than a rebuild. Do not bake a single implicit "me" into the information architecture.

## Product Purpose

Control Center is a **unified developer operations hub** for a solo operator. Tools built for one human writing one branch break down when the day spans many concurrent streams of work; Control Center gives one person command over all of them from one place, on any of their devices.

Agent orchestration is a first-class pillar (spawn, direct, watch, review, merge), but it is one pillar among several co-equal ones: **conversation-first messaging**, **meetings** (recording, transcription, notes), **calendar**, **newsfeed**, **PR review**, and the **repos, workspaces, and integrations** (GitHub, Linear, MCP) everything acts through. These are tagged into and threaded through each other rather than siloed.

Success: the operator always knows the state of every pillar and can act on it in one or two moves, from desktop, web, or phone. Running ten concurrent streams should feel as controlled as running one.

## Brand Personality

**Alive, warm, confident.**

- **Alive.** The interface reports real work honestly. An agent thinking, running, blocked, or done; a meeting recording; a sync in flight; a cost ticking up; these feel different at a glance, through genuine presence and status rather than ornament. The UI breathes with real activity, then gets out of the way. "Alive" is earned by representing the underlying model truthfully, never by decoration or whimsy.
- **Warm.** Intelligent, human warmth in the Anthropic register: serious without being cold, corporate, or chrome-heavy. The tool feels considered and on your side, not clinical. Warmth lives in voice, in a few earned brand moments, and in tone, not in noise.
- **Confident.** Direct and technical. No hype, no cute. The feeling target is commanding a fleet from a calm deck: you can see everything, nothing is shouting.

Reference points (for the specific quality, not the whole look):

- **Anthropic.** Intelligent, warm confidence; serious without being cold. The lead reference for the warmth axis.
- **Linear.** Restraint, speed, and a flawless state vocabulary (hover / focus / active / selected); keyboard-first without feeling raw.
- **Stripe.** Precision and calm density; complex, multi-pillar data made legible and trustworthy.
- **Warp.** A developer-native surface that is still genuinely designed; technical without being chrome-heavy.
- **Amp** and **Cursor.** Agent activity treated as a first-class, legible part of a developer surface, not bolted on.

## Anti-references

Two hard constraints. If a surface drifts toward either, it is wrong.

- **Generic SaaS dashboard.** Gradient hero-metric cards, identical rounded card grids repeated down the page, decorative charts, purple gradients. The hero-metric template and identical card grids are banned outright.
- **Default component-kit / template feel.** The out-of-the-box component-kit / Tailwind-template reading. This is the specific thing the work is escaping: the foundation stays, the generic-kit look must go. Distinction comes from making the model legible, not from decoration.

Two former anti-references were deliberately relaxed and are **not** hard constraints, with limits:

- **Density and developer-tool surfaces are welcome.** The operator deck is dense by design. The line is hierarchy: dense-with-hierarchy is good; cluttered gray-on-gray with no hierarchy is not.
- **Measured approachability is allowed.** Warmth and a light touch of personality fit "alive, warm, confident." The shared motion floor still holds: no bounce, no elastic, no toy-like or emoji-heavy treatment.

## Design Principles

1. **Presence over decoration.** Every bit of motion, color, or "life" must report real state, an agent thinking / running / blocked / done / costing, a meeting recording, a sync in flight, a feed updating. If it is not conveying what something is actually doing, it does not belong. This is how the app earns "alive" without becoming playful.
2. **Situational command in one glance.** The operator juggling agents, meetings, a calendar, and conversations should never hunt for "what is happening and what needs me." Surface status, ownership, and the next action by default, across every pillar; bury nothing essential a level deep.
3. **Distinctive through behavior, not skins.** The point of difference is *how* the app represents living, multi-pillar work, not a louder palette. Escape the default-component-kit feel by making the model legible and characterful, not by adding decoration.
4. **Warm confidence, earned.** Warmth and expression are intelligent and calm, carried by voice, tone, and a few thresholds (onboarding, the dashboard deck, the shader backgrounds), never sprinkled across the app. Day-to-day surfaces (lists, diffs, settings, tables, feeds) stay quiet, dense, and consistent, with one component vocabulary everywhere.
5. **Solo-first, multi-platform continuity.** Optimize for one operator today, but the same operation must feel coherent across desktop, web, and phone, with no surface a degraded afterthought. Keep attribution, ownership, and visibility legible so shared-agent and team use is an additive step, not a rewrite.

## Accessibility & Inclusion

Target **WCAG 2.1 AAA where feasible, with AA as the hard floor.**

- **Contrast.** Push body text toward AAA (7:1) where practical; AA (4.5:1) is the minimum, never the target. Placeholder and muted text must still clear 4.5:1, not drift into low-contrast gray. Maintain WCAG line-heights (≥1.5 for body).
- **Never status by color alone.** Every agent, PR, pipeline, meeting, and sync state pairs color with an icon, label, or shape. This matters more here than usual given the rich, multi-pillar status vocabulary, and it covers color-blind users directly.
- **Full reduced-motion alternatives.** Every animation, including the "alive" presence motion and the shader backgrounds, has a `prefers-reduced-motion` path: a static or crossfade equivalent, never a blank surface or a reveal that fails to fire.
- **Keyboard-first and touch-ergonomic.** The desktop operator lives on the keyboard: every action reachable without a mouse, with visible focus (keep the 2px focus rings). The phone remote is touch-first: ≥44px targets, no hover-only affordances, gestures that degrade gracefully.
- **Legible by default across surfaces.** The same content must stay legible and operable on the dense desktop deck, the web client, and the phone, not just the surface it was designed on first.
