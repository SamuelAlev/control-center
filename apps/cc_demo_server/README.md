# cc_demo_server

A separate binary running the real `cc_server` composition with seeded workspaces and a scripted agent loop. The client and RPC catalog are shared; demo-only fixtures never ship in the production binary. Deploy this artifact rather than relying on a runtime demo flag to restrict a public server.

```sh
# from the repo root; natives are required
scripts/natives/build_natives.sh
cd apps/cc_demo_server
fvm dart build cli
./build/cli/<arch>/bundle/bin/cc_demo_server --data-dir /tmp/demo --port 9030 \
  --allowed-origins https://demo.usectrl.dev
```

Open `https://demo.usectrl.dev/#<base64url({"server":"ws://127.0.0.1:9030/rpc","invite":"demo"})>`. The web client's existing invite flow redeems the code through `/invites/redeem`. For a hosted deployment, set `CC_SERVER_PUBLIC_URL` to the reachable URL or redeemed clients receive a loopback address. See [the Docker deployment guide](../../docker/cc_demo_server/README.md) for image build, GHCR publishing and hosting variables.

## Public-host boundary

`DemoProfile` is a default-deny RPC-name allowlist. The runtime omits ports for terminal, filesystem, process, git mutation, MCP, OAuth, credentials, SSO, webhooks, backup and font proxy operations. `/mcp`, `/sse` and `attachMainServer` have separate guards. Managed code-server download and warm-up are skipped entirely in demo mode. Pipeline execution is refused at the engine, trigger, scheduler, resume and bash-body layers, and mutation names are denied even if accidentally wired. On-device model downloads are disabled. The scripted **agent loop** sits above the provider and ignores tools, so demo runs still produce logs and stream events without executing tools or calling providers. Do not replace it with a scripted provider: provider-emitted tool calls would execute.

The media proxy remains enabled for real newsfeed images. Signed targets are checked against loopback, private/link-local addresses and metadata hosts on the request **and every redirect**; demo fetches carry no bearer credential and are capped at 8 MB. Keep these guards when modifying the public surface. `demo_op_lockdown_ratchet_test.dart` classifies newly declared ops, `demo_client_surface_test.dart` compares client calls against the live demo catalog, and `demo_http_surface_test.dart` covers HTTP refusals. See [security boundaries](../../SECURITY.md) for shared rules.

## Visitor lifecycle

A visitor redeems a warm seeded workspace, gets a synthetic guest and paired device, and expires after 45 minutes. Reaping revokes the paired-device row to close its socket; publishing a membership event alone does not. `<dataDir>/demo/state.json` is reconciled with the registry on boot. A 60-second sweep and claim-time check replace unclaimed workspaces older than the TTL as well as expired claimed ones. Fixture timestamps such as `@-3d` resolve once at seed time. Limits are per IP (`CC_SERVER_DEMO_MAX_PER_IP`, default 3) and disk (`CC_SERVER_DEMO_DISK_BUDGET_MB`, default 8 GB), not a global visitor cap. Shared feeds use the normal defaults and a 10-minute per-URL fetch memo; `.invalid` hosts are skipped.

The demo's `kDemoViewerLogin` presents Maya Okonkwo for PR/inbox display, not authentication; forge mutations remain unavailable. `demo_deep_link_pins_test.dart` keeps the identity consistent with the PR fixtures.

## Fixtures

`packages/cc_server_core/demo_fixtures/runs/*.json` holds scripted runs, `pull_requests.json` holds PRs, and `helix.png` is the seeded logo. From the repository root, regenerate committed Dart fixtures with `fvm dart run tool/gen_demo_fixtures.dart`; a test byte-compares the generated output. Keep relative timestamp markers so seeded data stays within retention windows.

## Landing capture checklist

The media briefs are `docs/src/data/landing-en.ts` and the slots are in `docs/src/components/landing/`. The six hero stops are **Your day**, **Agents**, **Code review**, **Tickets**, **Meetings** and **Pipelines**. The feature grid reuses five of these; the connected workflow reuses tickets, agents and review. There are three additional shots: the action approval, desktop/web paired with a phone, and the expanded hero preview (the currently selected stop).

| Shot | Public demo data and safe interaction | Use a real server instead for |
| --- | --- | --- |
| Inbox / your day | Seeded PR groups, sync blocker and a pending **git push** confirmation linked to a fictional agent run. Approve/deny only resolves an in-memory prompt; no command runs. | An actual guarded push or resuming an agent process after approval. |
| Agents / spaces | Helix spaces, personal Evaluation/Planning folders, multiple conversations and a reply thread in `eval-review`; scripted agent turns stream tool cards and usage without executing tools. The two-agent handoff shows fictional code editing and a reply-back. | Real isolated Git worktrees, shell, file edits, or agent-driven pushes. |
| PR review | Cached #412 diff, discussions, checks and AI-review findings. Local demo review comments/drafts can be edited. | Publishing a review, merging, or any forge write. |
| Tickets | A populated Helix Q3 board around HX-118, HX-124 and HX-129, with varied statuses, priorities, assignments and linked context; workspace-local edits work. | A live Linear sync. |
| Meetings | Finished meetings, transcripts, speakers, decisions and action items; note edits work. **Meetings → Record** starts a simulated meeting and reveals a fictional transcript live; pause/resume/stop operate on the simulation. | Capturing actual audio, transcribing speech, playback or recording directly from a calendar event. |
| Pipelines | Two curated templates and completed/failed runs with step rows. Inspect existing runs only. | Authoring/running a workflow, schedules, triggers or `bash.script` steps. |
| Subscription pill | Fictional Claude Code, Codex, Cursor, z.ai and Kimi quota windows with rolling reset times; `subscriptions.usage` is the sole admitted subscription read. | Actual account/plan usage. |
| Desktop + phone | The web demo shows the workspace and approval on desktop or a narrow browser viewport. | A genuine paired phone companion: pairing is deliberately unavailable on the public host. |

The public demo's approval, tool output, quotas, meeting transcript and worktree-looking file snapshot are **fictional**. Never record these as proof that a push, shell command, clone, audio capture, provider quota fetch or external publication actually happened. Do not enable execution to improve a marketing shot; capture real execution against an operator-controlled `cc_server` instead. The landing site still has `ProductMedia.astro` placeholders until actual captures are supplied and integrated.

Record desktop at the slot's 1440 × 900 source size and the phone composition at 390 × 844. Capture the action, not just the final state; the landing media implementation still needs accessible controls, captions/transcript for video and a paused/reduced-motion path as described in `docs/README.md`. Seeded approval is registered on visitor claim so it survives an unclaimed pool carried through a server restart.

### Capture sequence

1. Redeem a fresh visitor and verify `/healthz` reports `demo: true` for the newly deployed build; the hosted demo may still serve an older binary until redeployed. Visitor workspaces expire after 45 minutes.
2. For the two-agent handoff, open **eval-review → HX-124 · Shared run-group walkthrough**, select **Ravi** only, and send `@Ravi shared run-group walkthrough`. Ravi asks Juno; Juno's own turn streams fictional read/edit/test cards and pings back; Ravi follows up. These cards do not touch the server's filesystem or execute a shell.
3. For the approval, open **eval-review → Release gate · Shared run groups** and Ravi's run, then the Inbox approval titled **Ravi wants to push the #412 budget fix**. Approve or deny to clear the request and see the run resolve; neither decision runs `git push`.
4. For the meeting, use **Meetings → Record**, wait for speaker-attributed segments, pause and resume to show the feed stopping and restarting, then stop to inspect the completed fictional transcript. The browser must not request microphone or screen permission.
