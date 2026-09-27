# Security policy

## Reporting a vulnerability

Do not open a public issue. Use this repository's [private vulnerability reporting](https://github.com/SamuelAlev/control-center/security/advisories/new) with impact, reproduction/PoC, affected component and version/commit. Reports receive acknowledgement and a fix or mitigation plan after triage; allow time to remediate before disclosure.

The server, relay, clients, workers, external tools and disposable rigs have different trust levels. This document owns their security contracts; [ARCH.md](ARCH.md) covers implementation flow and [AGENTS.md](AGENTS.md) the coding rules.

## Authorization and isolation

- The server owns data, policy, external APIs and execution. A device PSK authenticates a device, not membership in any workspace. `Principal` distinguishes humans and agents; rate limits are per principal across devices.
- Workspace operations require an explicit `workspace_id`. Check the registered, non-deleted workspace **before** membership lookup or opening its database; even role lookup can otherwise create an empty database for an unknown ID.
- Enforce `WorkspaceRoleResolver` membership at every inbound lane: `repo/call`, `sub/subscribe`, `tools/call`, and HTTP media/backup handlers. Workspace sessions are not a substitute for per-call scoping. Phone tools additionally use default-deny `RemoteToolPolicy` and `RemoteRateLimiter`, with tighter mutation caps.
- Scope ID lookups or reject `entity.workspaceId != workspaceId` at the read/write chokepoint (`WorkspaceMismatchException` or explicit MCP error). Repo tools also verify `isRepoLinkedToWorkspace`; per-repo grants must not exceed forge access.
- `GlobalDatabase` contains only explicitly shared state; each workspace has its own file. Never cache a workspace DAO. Use `CrossWorkspaceQueries` plus a `CROSS-WORKSPACE BY DESIGN` explanation for legitimate fan-out; no ad hoc workspace enumeration. Pre-auth IDs route through `workspace_routes`, with no scan-on-miss fallback.
- Filter cross-workspace `watchAll` results per subscriber (`_visibleRows`), events in `RemoteEventForwarder`, and presence by repo grant. `WorkspaceMemberRemoved` drops that workspace's subscriptions and invalidates cached membership. Device revocation watches `paired_devices` and terminates its sessions.
- Request cancellation is scoped to the authenticated connection and targets only reads or subscription setup. Unknown IDs leave no tombstone; other sessions and mutations are unaffected. Cancellation does not free a running handler's concurrency slot early, so cancel/reissue cannot bypass admission limits.
- Registry operations self-gate: workspace update requires admin, delete requires owner, reorder filters to the caller's workspaces; `confirmation.respond` requires member. Server settings/MCP/model operations use `requireServerAdmin`/`serverOwnerUserId`, not a workspace role.
- `/meeting/audio` and `/workspace-logo` verify membership after PSK authentication. Backup HTTP routes independently enforce workspace admin for export, workspace owner for restore, and install owner for whole-install snapshots; see [backup lifecycle](ARCH.md#backup-and-restore).

Regression coverage: `cc_persistence/test/workspace_isolation_ratchet_test.dart`, `cc_host` dispatcher/subscription/session tests, `cc_server_core/test/fresh_boot_first_workspace_test.dart` and remote-event-forwarder tests. New workspace surfaces need behavioral cross-workspace denial coverage, not only structural checks.

## Credentials

Provider tokens live on the server, never in client storage or RPC responses. The client keychain (`flutter_secure_storage`) holds only its device credential. Existing client provider tokens migrate once through `credential_migration.dart`, then are deleted locally. `shared_preferences` is for non-sensitive, per-user synced preferences.

Client read snapshots contain previously authorized presentation data, not credentials or authorization decisions. They are isolated by verified server identity and authenticated user, with workspace/query arguments in each entry. Desktop files are owner-private; web snapshots are origin-local IndexedDB data. Fresh membership reads prune revoked workspace data, explicit authorization failures evict affected snapshots, and forgetting/disconnecting a server removes its persisted snapshots. Cached data never bypasses the cold-start authentication gate or authorizes a write.

Server credential lanes under `packages/cc_server_core/lib/src/identity/`:

| Lane | Storage and authority |
| --- | --- |
| Per-user `UserCredentialsStore` | `user_forge_<forge>_<userId>` / `user_ticket_<provider>_<userId>` in 0600 `FileSecretsStore`; JSON access/refresh/expiry/source/account envelope. `credentials.*` always targets `ctx.userId`. |
| App identity (`ProviderAppSettings`, `GitHubAppClient`) | Operator-only `providerApps.*`; non-secrets in `server_settings`, secrets in the secrets file. Environment seeds each field once; stored values then win. |
| Environment | CI/headless credentials declared in [.env.template](.env.template). |

`ForgeCredentials` resolution is deliberate:

- With a calling user: that user's credential, otherwise nothing. Never silently borrow the server environment for their authentication.
- Without a caller: app identity → server owner's credential → environment.
- Human-driven forge writes use `tokenForActor(forge,userId)`: the person's credential first, then the no-caller chain only if they have not connected the forge. `actsAsSelf` reports the result. Thread `ctx.userId` through per-actor factories (`forgeDioFactoryForActor`, `forgeRegistryForActor`, `prLifecycleRepositoryForActor`, `ReviewPublisherService.githubPrClientFor`). Include acting user in `prRepoCache` keys so cached authenticated clients cannot misattribute another person's writes.
- MCP, polling, webhooks and automatic agent review publication pass no user and use background identity.

GitHub sign-in is server-run device flow (`ProviderOAuthService`, `oauth.begin`), with no callback URL and no required client secret. A secret is needed to refresh expiring tokens. Linear uses `/oauth/<provider>/callback` with single-use, TTL-bounded state bound server-side to `(user,provider)`. PAT entry remains available; host `gh` credentials are not an authentication method.

Provider credentials may be configured through supported Settings fields or the environment, never command-line flags. `cc_server` reads `.env` from its working directory, beneath real environment values (`environmentWithDotenv`); clients do not forward it. `CcServerConfig.pickCredential` may fall back to release-baked **non-confidential** values only: Google device-code client, Klipy key, GitHub client ID. Never bake a GitHub private key or client secret. The shipped client ID enables sign-in, not installation-token background access; an operator with token expiry enabled supplies their own refresh secret. Connection RPCs return status/account only; secret settings are write-only, with presence flags returned.

SSO, owner identity and other mutable settings belong in Settings. `CC_SERVER_*`/matching flags are for pre-boot process configuration (paths, bind, port, TLS, logging), not a second settings store. Redact logged command output before display.

## Execution and untrusted input

### Actions, tools and skills

`ActionClass` is a closed effect taxonomy. Every mutating tool declares its classes; the ratchet rejects undeclared tools. Policy precedence is `space > agent > workspace > mode preset > built-in default`; within a scope, longest-prefix then most-restrictive wins. `prompt` without a connected approver denies. Per-space autonomy profiles use this same store; delegation enforces depth, cycles, budget and autonomy ceilings server-side.

`SkillBundleService` scans between fetch and write. No skill bytes or frontmatter enter disk/prompt without a `pass`/`warn`/`quarantine` verdict. Mandatory static rules and capability manifests execute nothing; LLM review is additive. Trust tiers express provenance, never bypass scanning. **Bytes scanned = bytes written = bytes hash-locked.** Repo skills use the same gate; context symlinks resolve only into explicitly permitted roots, never by recursively following repo-directory links.

External MCP servers and guest-extracted content are untrusted. Strip ANSI/control characters and cap external tool descriptions/results; external tools default to the cautious approval tier. `wrapUntrustedRigContent` labels guest data as data, not instructions. Framing is not enforcement: approval, filesystem/network limits and server authorization remain necessary. Deferred harness schemas never widen the admitted tool surface or bypass guards.

### Sandboxes and rigs

- Copy-on-write provisioning must not write branches, registrations or FETCH_HEAD into source checkouts. No silent git-worktree fallback where rift is supported; Windows is the explicit backend exception. Required native failures are fatal, not degraded operation.
- Restricted QEMU argv uses `restrict=on`, loopback-only `hostfwd`, read-only base plus per-session overlay, and no `-virtfs`/`-fsdev`. Egress passes through `guestfwd` to `SandboxHttpProxy`/`SandboxSocksProxy` on host loopback.
- Restricted smolvm argv uses `--outbound-localhost-only`, one `--allow-host` per admitted host, and broker credentials via `--secret-file`, not persisted environment values. Docker Hub image-maintenance hosts join the same gate.
- Only an install-owner-confirmed restart sets `RigSpec.unrestrictedNetwork`. QEMU omits `restrict=on`, smolvm uses bare `--net`, proxy policy widens too, and the UI retains a warning. Pin both restricted/unrestricted argv paths in tests.
- Android/iOS are host-managed with host networking; do not advertise them as enclosed or offer an unenforceable egress switch. Developer commands remain device/simulator argv, never a host shell.
- Guests receive only per-VM broker secrets for short-lived, scoped, per-operation tokens: allowlisted, rate-limited and revoked at close. No durable provider credential enters an enclosure.
- `RigService.act` blocks agent mutations during human control. Input is attributed and sequenced transactionally. Guest capture is unprivileged; QEMU input is injected via the hypervisor. Clipboard crossing requires per-user/per-direction permission before reading/transferring.
- `enclosureControl` is denied in read-only modes. `SandboxBackend.microvm` is probe-gated and cannot downgrade to a host shell. Bound lifetimes/resources, recover only owned devices, and tear down owned machines at shutdown. Boot artifacts are checksum/digest-pinned; control sockets are private and reject symlinked namespaces. See [enclosure operational constraints](ARCH.md#enclosures).

## Network boundaries

- Non-loopback server binds require TLS (`--tls-cert`/`--tls-key`), or explicit `--insecure` behind a trusted TLS-terminating proxy.
- `/proxy/media` requires PSK-signed URLs and checks every target and redirect against SSRF blocks: loopback, link-local, cloud metadata, private IPv4 and IPv6 ULA.
- The signaling broker relays sealed application frames without seeing the PSK. Rooms are invite-gated, capacity-bounded, rate-limited and reaped when idle; room ID alone grants no access. It is an N-peer relay, not a two-peer authentication boundary. See [broker protocol](apps/cc_signaling_server/README.md).

## Dependencies

[dependency-audit.yml](.github/workflows/dependency-audit.yml) runs weekly, fails on pub.dev advisories and retracted/discontinued dependencies, and reports outdated packages. Native source/provenance and packaging requirements are documented under [cc_natives](packages/cc_natives/README.md).
