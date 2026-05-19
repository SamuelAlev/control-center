# cc_demo_server

The public demo: **the real `cc_server` composition**, booted with demo wiring.
Same RPC catalog, same client, same persistence — only the data is invented and
the brain is scripted.

```bash
scripts/natives/build_natives.sh          # required; there is no degraded mode
cd apps/cc_demo_server && dart build cli
./build/cli/<arch>/bundle/bin/cc_demo_server --data-dir /tmp/demo --port 9030 \
  --allowed-origins https://demo.usectrl.dev
```

Then open the web client at a fragment naming this server and the demo code:

```
https://demo.usectrl.dev/#<base64url({"server":"ws://127.0.0.1:9030/rpc","invite":"demo"})>
```

The client's existing auto-redeem path takes it from there — `bootstrap_web`
sees an invite with no PSK, POSTs `/invites/redeem`, and connects with the
descriptor it gets back. **No client changes are needed to connect.**

## Why a separate binary, not `cc_server --demo`

1. **A flag would ship the fixtures to every desktop install.** The demo's run
   scripts and pull-request world compile *into* the binary — a demo whose data
   lives in a sibling directory fails as an *empty* demo, which is the worst
   failure shape because it still looks like it booted. A runtime
   `if (demoMode)` branch inside `runCcServer` is reachable code, so nothing
   could be tree-shaken. Measured, with the separate entrypoint:
   `Parced`, `escrow-review`, `EscrowTimeline` and `demo-person-maya` all
   appear in `cc_demo_server` and **zero times** in `cc_server`.
2. **A flag can be forgotten.** A public endpoint whose lockdown depends on
   `CC_SERVER_DEMO=1` becomes a fully armed server the first time a deployment
   drops that variable. Deploying this artifact *is* the lockdown.

`runCcServer` therefore takes a `DemoWiringBuilder?`, and `apps/cc_server`'s
`main` never mentions it.

## What is unreachable, and how

**Layer 1 — structural absence.** The runtime passes `null` for ~31 ports, so
the ops are never built into the registry and `RepoOpDispatcher` answers
`opUnknown`, exactly as for an op that does not exist: terminals, rigs,
code-server, the filesystem surface, process control, repo scripts, every
git-mutating verb, MCP, OAuth, provider apps, forge and user credentials, SSO,
webhooks, backup/export, and the font proxy.

Two things the null ports do *not* cover, closed separately:

- **`mcpControl.startIfEnabled()` mounts `/mcp` + `/sse` independently** of the
  catalog wiring. Nulling the port only removed the `mcp.*` ops; the HTTP
  surface stayed live (and `/sse` held the connection open). Both the mount and
  the `attachMainServer` call are now demo-guarded.
- **The on-device model downloads** (~700 MB: embedding + diarization + speech)
  are the largest outbound transfer the server can make. Skipped in demo.

**Layer 2 — `DemoProfile`**, a default-deny name allowlist rebuilt into the
registry. It is a *name* allowlist rather than an `ActionClass` denylist for a
measured reason: the catalog declares 548 ops, 326 mutating, and `terminal.spawn`
declared no ActionClass at all, so a class-based denylist would have admitted the
terminal. (That gap is now also fixed — see below.)

**Layer 3 — the ratchets.** `demo_op_lockdown_ratchet_test.dart` fails by name
when an op is added that nobody classified, so the surface cannot widen by
accident. `demo_client_surface_test.dart` closes the opposite direction: it
boots a real demo server, reads its actual op catalogue, and diffs it against
every `.call('x.y')` in the Flutter client AND in `packages/cc_data` (where
three quarters of them live). A screen that calls a denied op fails there,
naming the file, instead of rendering `RemoteRpcException(-33006)` in red where
its content should be.

## The media proxy is ON, deliberately

Every other byte route is closed. `/proxy/media` is not, because the newsfeed
reads REAL feeds and a feed stripped of its images is the one surface nobody
wants a screenshot of. What makes that safe is not absence:

- the target URL is signed against the calling device's PSK;
- `isBlockedProxyTarget` + `resolvesToBlockedAddress` refuse loopback,
  link-local (including `169.254.169.254`), `metadata.google.internal` and
  RFC-1918 / IPv6-ULA — on the request **and on every redirect hop**;
- `mediaCredential` is null on a demo, so a fetch carries no bearer token;
- `mediaProxyMaxBytes` drops the body ceiling from 96 MB to 8 MB, because a
  public host has no business relaying video for anonymous visitors.

`demo_http_surface_test.dart` pins each of those refusals.

## The agent lane

`ScriptedAgentLoop` is injected into `SandboxedAgentDispatchAdapter`, one level
**above** the provider. That placement is the whole safety argument: a dispatched
run builds its real tool surface, so a scripted *provider* emitting a `bash` call
would really run bash. A scripted *loop* ignores `tools` and `provider`
entirely — zero tools execute, nothing is dialled — while run logs, message
transcript segments, the NDJSON run log, the live stream, cost accounting and
`AgentRunCompleted` all behave exactly as on a real run.
`scripted_dispatch_session_test.dart` pins that end to end.

## Visitors

Each visitor claims a pre-seeded workspace from a warm pool, gets a synthetic
guest user and a paired device, and is reaped on a fixed 45-minute TTL. Reaping
revokes the **paired-device row** — that is what actually closes the socket
(`LocalRpcServer` watches it); publishing `WorkspaceMemberRemoved` alone only
drops subscriptions.

Bookkeeping lives in `<dataDir>/demo/state.json`, not in `workspace_meta`
(which is fixed-column self-identification and explicitly not a settings table),
and is reconciled against the registry at boot so a hard kill self-heals.

**No demo database on disk is ever older than the TTL**, claimed or not. A
claimed workspace is reaped 45 minutes after redemption; an UNCLAIMED one in
the warm pool is deleted and reseeded on the same clock. That second half is
not about storage — the demo world is anchored to the moment it was seeded,
because the fixtures carry relative markers (`@-3d`, `@-20h`) that the seeder
resolves to absolute timestamps exactly once. The pool used to be write-once,
so a workspace seeded at boot sat there for the life of the process and handed
its eventual visitor a calendar week that had already ended and a meeting "20
hours ago" that was really 20 hours plus however long the container had been
up. Staleness is checked both by the 60-second sweep and again at claim time,
so an entry that expires between sweeps is still never handed out. A pool entry
written before this carried a `seeded_at` stamp is read as already stale:
reseeding one needlessly is free, shipping a week-old demo is not.

There is **no cap on concurrent visitors** — the bounds are per-IP
(`CC_SERVER_DEMO_MAX_PER_IP`, default 3), the 45-minute TTL and a disk budget
(`CC_SERVER_DEMO_DISK_BUDGET_MB`, default 8 GB). Measured cost is roughly
**5–10 MB per visitor**, essentially all of it the seeded `workspace.db`, so the
default budget covers several hundred concurrent visitors before it refuses.

Two per-visitor costs were removed rather than budgeted for:

- The demo used to seed a fictional in-house feed on a `.invalid` host. RFC 2606
  guarantees that name never resolves, so every visitor spent a DNS lookup to
  log a `SocketException`. Feeds are now the product's own `kDefaultFeeds`, all
  real, and `_refreshOne` skips a `.invalid` host outright.
- Feeds are per-user rows, so N visitors subscribed to the same publication
  meant N fetches of a byte-identical body — linear in visitors, and TLDR
  started answering 429 during testing. `DaoNewsfeedRepository` now memoizes a
  fetch by URL for 10 minutes and re-keys the parse onto each subscribing feed
  row (articles dedup on `(feed_id, guid)`, so it is the same write the network
  would have produced). That fix is not demo-specific: a five-person team
  subscribed to Hacker News now costs one fetch too.

## The viewer identity

A demo holds no forge credential, so `forge.listConnections` is absent and the
viewer login resolved to the empty string — which silently emptied every surface
keyed on *"is this mine?"*: the inbox review queue, "requested from you", the PR
list's own-authorship grouping. The client answers that question locally instead
(`kDemoViewerLogin`), casting the visitor as **Maya Okonkwo** — the reviewer the
fixtures already address. It is a display identity: it authenticates nothing,
and every forge mutation is absent from the op registry regardless.
`demo_deep_link_pins_test.dart` pins the login against `pull_requests.json`, so
an identity that stopped matching a real reviewer fails there rather than
showing up as an inbox that is merely empty.

## Editing the fixtures

```
demo_fixtures/runs/*.json        # agent run scripts
demo_fixtures/pull_requests.json # the PR world, in the real PrCacheCodec shape
fvm dart run tool/gen_demo_fixtures.dart
```

The generated Dart is committed and a test byte-diffs it, so a stale fixture
fails CI instead of silently shipping yesterday's demo. Timestamps are
`@-3d`-style markers the seeder resolves at seed time, so the demo is always
"today" and every row stays inside the retention windows.

## Deployment

The release workflow builds this alongside `cc_server` and publishes it to
GHCR as **`ghcr.io/<owner>/cc-server-demo`** (`:<version>` and `:latest`), with
a signed provenance attestation. It is the same Dockerfile as `cc-server`,
selected by the `CC_SERVER_BINARY` build arg over a different bundle.

Deploy it straight from the registry — Railway, Render and Fly all inject
`PORT` and a public hostname, and the image's entry shim maps those onto
`--port` and `CC_SERVER_PUBLIC_URL` (which the redeem envelope and connection
descriptor need; without it a hosted server hands clients a loopback path).

See **`docker/cc_demo_server/README.md`** for the Railway walkthrough, the
variables to set, and how to build the image locally.
