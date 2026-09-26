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

`DemoProfile` is a default-deny RPC-name allowlist. The runtime omits ports for terminal, filesystem, process, git mutation, MCP, OAuth, credentials, SSO, webhooks, backup and font proxy operations. `/mcp`, `/sse` and `attachMainServer` have separate guards. Pipeline execution is refused at the engine, trigger, scheduler, resume and bash-body layers, and mutation names are denied even if accidentally wired. On-device model downloads are disabled. The scripted **agent loop** sits above the provider and ignores tools, so demo runs still produce logs and stream events without executing tools or calling providers. Do not replace it with a scripted provider: provider-emitted tool calls would execute.

The media proxy remains enabled for real newsfeed images. Signed targets are checked against loopback, private/link-local addresses and metadata hosts on the request **and every redirect**; demo fetches carry no bearer credential and are capped at 8 MB. Keep these guards when modifying the public surface. `demo_op_lockdown_ratchet_test.dart` classifies newly declared ops, `demo_client_surface_test.dart` compares client calls against the live demo catalog, and `demo_http_surface_test.dart` covers HTTP refusals. See [security boundaries](../../SECURITY.md) for shared rules.

## Visitor lifecycle

A visitor redeems a warm seeded workspace, gets a synthetic guest and paired device, and expires after 45 minutes. Reaping revokes the paired-device row to close its socket; publishing a membership event alone does not. `<dataDir>/demo/state.json` is reconciled with the registry on boot. A 60-second sweep and claim-time check replace unclaimed workspaces older than the TTL as well as expired claimed ones. Fixture timestamps such as `@-3d` resolve once at seed time. Limits are per IP (`CC_SERVER_DEMO_MAX_PER_IP`, default 3) and disk (`CC_SERVER_DEMO_DISK_BUDGET_MB`, default 8 GB), not a global visitor cap. Shared feeds use the normal defaults and a 10-minute per-URL fetch memo; `.invalid` hosts are skipped.

The demo's `kDemoViewerLogin` presents Maya Okonkwo for PR/inbox display, not authentication; forge mutations remain unavailable. `demo_deep_link_pins_test.dart` keeps the identity consistent with the PR fixtures.

## Fixtures

`demo_fixtures/runs/*.json` holds scripted runs, `demo_fixtures/pull_requests.json` holds PRs, and `demo_fixtures/helix.png` is the seeded logo. From `apps/cc_demo_server`, regenerate committed Dart fixtures with `fvm dart run tool/gen_demo_fixtures.dart`; a test byte-compares the generated output. Keep relative timestamp markers so seeded data stays within retention windows.
