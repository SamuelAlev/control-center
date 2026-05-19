# Product

## Register

product

## Users

A solo developer operating a fleet of AI coding agents from the desktop. They are technical and tool-fluent (git, terminals, IDEs, GitHub, Linear), impatient with friction, and almost always in deep focus while several agents work in parallel across isolated Git worktrees.

Their job, on any given screen: dispatch work to agents, keep situational awareness of what every agent is doing, review and merge the PRs those agents produce, and manage the repos, workspaces, and integrations the agents act through. The hard part is not any single action; it is holding the whole fleet in view at once without losing the thread.

Team use is a near-term horizon, not today's reality. The design optimizes for one operator now, but must keep ownership, attribution, and visibility legible so shared-agent and multi-human use is an additive step rather than a rebuild. Do not bake a single implicit "me" into the information architecture.

## Product Purpose

Control Center is the cockpit for multi-agent software development. It exists because orchestrating several autonomous coding agents at once (each on its own branch and worktree, each producing PRs, logs, costs, and messages) overwhelms tools built for one human writing one branch.

It gives one operator command over a fleet: spawn and direct agents, watch their work unfold in real time, review and merge their output, and manage the repos, workspaces, and integrations (GitHub, Linear, MCP) they act through.

Success: the operator always knows what every agent is doing and can act on it in one or two moves. Running ten agents should feel as controlled as running one.

## Brand Personality

A **living, agentic system** with the **restraint of an operator tool**. Three words: **alive, composed, precise.**

The interface should convey that autonomous work is happening, through honest presence and status rather than ornament. An agent that is thinking, running, blocked, or done should feel different at a glance. The UI breathes with real work, then gets out of the way. "Alive" is earned by representing the agent model truthfully, never by decoration or whimsy.

Voice is direct and technical. No hype, no cute. The feeling target is commanding a fleet from a quiet, well-instrumented deck: you can see everything, nothing is shouting.

Reference points (for the specific quality, not the whole look):

- **Linear** — restraint, speed, and a flawless state vocabulary (hover / focus / active / selected); keyboard-first without feeling raw.
- **Warp** — a developer-native surface that is still genuinely designed; technical without being chrome-heavy.
- **Stripe** — precision and calm density; complex data made legible and trustworthy.
- **Anthropic** — intelligent, warm confidence; serious without being cold or corporate.
- **Amp** and **Cursor** — agent activity treated as a first-class, legible part of a developer surface, not bolted on.

## Anti-references

All four are hard constraints. If a surface drifts toward any of them, it is wrong.

- **Generic SaaS dashboard.** Gradient hero-metric cards, identical rounded card grids repeated down the page, decorative charts, purple gradients. The hero-metric template and identical card grids are banned outright.
- **Heavy enterprise IDE chrome.** Cluttered gray-on-gray toolbars, deeply nested panels, Jenkins / Jira density with no hierarchy. Density is fine; density without hierarchy is not.
- **Default component-kit / Tailwind template.** The out-of-the-box component-kit feel. This is the specific thing the work is escaping: the foundation stays, the generic-kit reading must go.
- **Playful / consumer / cute.** Emoji-heavy, springy or elastic motion, toy-like rounded blobs. Too casual for a serious operator tool. (Reinforces the shared no-bounce, no-elastic motion rule.)

## Design Principles

1. **Presence over decoration.** Every bit of motion, color, or "life" must report real agent state (thinking, running, blocked, done, cost). If it is not conveying what an agent is actually doing, it does not belong. This is how the app earns "living" without becoming playful.
2. **Situational command in one glance.** The operator running ten agents should never hunt for "what is happening and what needs me." Surface status, ownership, and the next action by default; bury nothing essential a level deep.
3. **Distinctive through behavior, not skins.** The point of difference is *how* the app represents living agent work, not a louder palette. Escape the default-component-kit feel by making the agent model legible and characterful, not by adding decoration.
4. **Product discipline, earned brand moments.** Day-to-day surfaces (lists, diffs, settings, tables) stay quiet, dense, and consistent, with one component vocabulary everywhere. Expressive treatment (the shader backgrounds, onboarding, the dashboard "deck") is reserved for a few thresholds, never sprinkled across the app.
5. **Team-ready, solo-first.** Optimize for one operator today, but keep attribution, ownership, and visibility legible so shared-agent and team use is additive, not a rewrite.

## Accessibility & Inclusion

Target **WCAG 2.1 AA** across the app.

- **Never status by color alone.** Every agent, PR, and pipeline state pairs color with an icon, label, or shape. This matters more here than usual given the rich status vocabulary, and it covers color-blind users directly.
- **Full reduced-motion alternatives.** Every animation, including the "living" presence motion and the shader backgrounds, has a `prefers-reduced-motion` path: a static or crossfade equivalent, never a blank surface or a reveal that fails to fire.
- **Keyboard-first.** The operator lives on the keyboard; every action is reachable without a mouse, with visible focus (keep the existing 2px focus rings).
- **Legible by default.** Maintain WCAG line-heights (≥1.5 for body); placeholder and muted text must still clear 4.5:1, not drift into low-contrast gray.
