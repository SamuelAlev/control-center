# Product

## Audience and purpose

Control Center is a developer operations hub for one technical operator supervising concurrent coding agents on isolated Git worktrees alongside PR reviews, tickets, messaging, meetings, calendar, feeds and pipelines. Status, ownership and the next action should be visible without digging through screens. Desktop is keyboard-first and dense; web and phone remain useful, touch-capable ways into the same operation. A single server can execute locally or lease work to headless fleet workers.

Solo use is the default. Team membership, roles, invites, presence, follow/steer and take-over add collaboration without replacing the solo workflow or adding idle roster chrome for one human. Humans and agents are first-class `Principal`s for attribution; team and fleet use must not split the operation into competing sources of truth. See [ARCH.md](ARCH.md) for implementation boundaries.

## Product decisions

- Agents are one pillar, not the whole product. Messaging, tickets, meetings, calendar, newsfeed, PR review, pipelines/plans and observability deserve clear state and actions too.
- Show real state rather than decorative activity. Distinguish running, blocked, complete, recording and syncing; use motion only when it helps the operator read change.
- Keep daily surfaces quiet, dense and consistent. Warmth belongs in direct language and a few earned thresholds, not persistent visual noise. Avoid generic metric-card dashboards and component-kit decoration; legibility of the underlying work is the distinction.
- Preserve continuity across desktop, web and phone, and keep authorship/ownership legible as collaborators join. Do not treat a client as a degraded afterthought.

[DESIGN.md](DESIGN.md) owns visual tokens, contrast, focus, motion and responsive constraints; [SECURITY.md](SECURITY.md) owns trust and credential rules.
