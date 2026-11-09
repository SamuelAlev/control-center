# cc_connect

Control Center Connect is the small service that runs provider OAuth on behalf
of `cc_server` installs. A server signs every call with its per-Connect Ed25519
install key (RFC 9421). Connect runs the browser sign-in, exchanges the code and
returns two things: an access token, which the server keeps in RAM only, and a
`credential_seal`, an AEAD blob that only this Connect can open and only for
the install and workspace that created it.

The wire contract (signatures, DTOs, lanes, `/v1/config`) lives in
[`packages/cc_connect_core`](../../packages/cc_connect_core), shared with
`cc_server`.

For operators, the manual covers the same service:
[Run a Connect server](../../docs/src/content/docs/manual/guides/run-connect.mdx)
walks through a self-hosted deploy, and the
[Connect reference](../../docs/src/content/docs/manual/reference/connect.mdx)
covers what a server sees: modes, install identity, seals and status codes.
Releasing the image and signing the hosted `/v1/config` are in
[RELEASING.md](../../RELEASING.md#control-center-connect).

## What Connect holds, and what it never holds

Connect holds:

- OAuth client secrets for the shared GitHub App, Google, and Slack apps, with
  a current and a previous generation of each.
- The Klipy API key.
- The seal key: a local AES-256-GCM keyring or a Cloud KMS key.
- Short-lived state, never longer than 15 minutes: staged logins, nonces,
  seal handoffs, GitHub read caches, and Slack event references.
- Install bindings. A GitHub installation maps to the installs authorized on
  it. A Slack team maps to the one install it is bound to.

Connect never holds:

- A GitHub App private key or webhook secret. One-repository tokens come from
  `POST /applications/{client_id}/token/scoped`.
- Refresh tokens at rest. They exist only inside seals, which servers store.
- Source code, repository contents, Slack message text, or Linear secrets.
  The Linear code is handed back to the server, which runs the exchange
  itself. The one exception is slash-command argument text (at most 500
  characters), which is queued for the bound server for up to 10 minutes so
  it can draft from it.

Connect never echoes an upstream body. Every failure is
`{"error":"<code>"}` with the status from `ConnectErrorCode`. Logs carry
allowlisted fields only, and install and team ids appear only as HMAC tags.

## Routes

All paths are relative to `CONNECT_PUBLIC_URL`. Mounted at `/connect`, for
example, `/v1/config` is served at `/connect/v1/config`. Every answer carries
`Cache-Control: no-store`, `X-Content-Type-Options: nosniff` and
`Referrer-Policy: no-referrer`. Connect sends no CORS headers. A signed body
is capped at 16 KB.

| Route | Auth | Purpose |
| --- | --- | --- |
| `GET /healthz` | none | Liveness. |
| `GET /v1/version` | none | `protocol`, `version`, and `image_digest` when set. |
| `GET /v1/config` | install signature | Lanes and epoch. A hosted Connect serves its offline-signed file byte for byte. A self-hosted one generates the config from its complete lanes. |
| `POST /v1/oauth/{lane}/start` | install signature | Lanes are `github`, `google`, `linear`, `linear_app` and `slack`. Returns `login_id` plus an authorize URL that Connect checks with `validateAuthorizeUrl` before returning it. |
| `GET /oauth/{segment}/callback` | single-use `state` | Provider redirect. Segments are `github`, `google`, `linear`, `linear_app`, `slack_oidc` and `slack`. Stashes the code, sets the `__Host-cc_connect` cookie, and answers 303 to `/oauth/{lane}/done`. |
| `GET /oauth/{lane}/done` | `__Host-` cookie | Static page with the 8-character confirm code and a `control-center://oauth-done` link. Its CSP is `default-src 'none'` with a hashed style, it has no script, and it cannot be framed. |
| `POST /v1/oauth/{lane}/claim` | signature, confirm code, PKCE verifier | Single use, and five wrong attempts burn the login. Exchanges the code, checks fixed scopes, and returns a `SealedGrant`. For Linear it returns a `LinearCodeGrant`. For Slack, the OIDC pre-check reserves the team so only one sign-in at a time can run the bot exchange (which rotates the team's single bot token), and a team's first binding needs the approving person to be a workspace admin or owner (`not_admin` otherwise). |
| `GET /oauth/github/setup` | single-use install ticket | GitHub App `setup_url`. Binds the installation to the ticket's install when the installer is an org admin or owns the personal account, and that install is still allowed (a ticket held by a since-blocked install binds nothing). |
| `POST /v1/github/refresh`, `/v1/google/refresh`, `/v1/slack/refresh` | signature + seal | Fresh access token plus a rotated seal. A retried old seal replays the rotation for 5 minutes (`seal_handoff`), so a lost response never burns a single-use refresh token. |
| `POST /v1/github/scope` | signature + seal | Mints one token for one `repo_id`, clamped to the caller's repository role. The parent token is refreshed first when it has under 65 minutes left. Organization installs must be bound to the install. |
| `POST /v1/github/install/start` | signature + seal | Returns the app's install URL with a 15-minute ticket. |
| `POST /v1/github/installations` | signature + seal | The person's installations of the app, each with `bound_here` and `caller_is_admin`. |
| `POST /v1/github/authorize_server` | signature + seal | An org admin binds this install to an existing installation. |
| `POST /v1/github/revoke` | signature + seal | Deletes the grant, or one scoped token when `scoped_token` is set. A scoped token is revoked only for the install it was minted for. |
| `POST /v1/slack/revoke` | signature + seal | `auth.revoke`, then releases the team binding. Only the bound install can call it. |
| `POST /v1/events/poll` | install signature | Long poll of up to 25 s for Slack event and command references for teams bound to the caller. At most two concurrent polls per install. |
| `POST /v1/hooks/slack/events` | `X-Slack-Signature` | Events API intake. Bodies are capped at 256 KB. The text is dropped and a reference is queued. `app_uninstalled` and bot `tokens_revoked` release the team once per event id, and only when the event is newer than the current binding, so a retry or replay never frees a team that was connected again. |
| `POST /v1/hooks/slack/commands` | `X-Slack-Signature` | Slash commands get a fixed ephemeral answer. A bounded reference is queued. |
| `POST /v1/klipy/search`, `/v1/klipy/trending` | install signature | GIF proxy in `proxy` mode. URLs off Klipy's CDN are dropped. |
| `POST /v1/chat/{provider}/act` | install signature | Reserved for chat bots that have no per-workspace token. Always `provider_unavailable` today. |

Signed requests are checked in this order:

1. Body cap.
2. RFC 9421 verification. The target URI is `CONNECT_PUBLIC_URL` plus the
   path; `Host` and `X-Forwarded-*` are never read.
3. Allow and deny list (`install_blocked`).
4. Nonce replay cache (`stale_request`).
5. Per-install budget.

A seal is opened only with the verified install id and the body's
`workspace_id`. A seal from another install, workspace or Connect fails to
decrypt and is answered `access_denied`.

## Configuration

All settings come from environment variables. Connect refuses to start (exit
78) on an open, unsafe or half-configured setup.

Any secret below can come from a mounted file instead: set `NAME_FILE` in
place of `NAME`. Connect re-reads the file at most every 30 s and keeps the
last good value. Setting both `NAME` and `NAME_FILE` is refused. Variables
marked "dual" also accept `NAME_PREVIOUS` (or `NAME_PREVIOUS_FILE`) for the
previous generation.

| Variable | Default | Notes |
| --- | --- | --- |
| `CONNECT_PUBLIC_URL` | required | Canonical public base URL. Must be https, or http on loopback only. A path means a mount, for example `https://cc.example/connect`. No query or fragment. |
| `CONNECT_ALLOWED_INSTALLS` | required | Comma-separated install ids. `*` (anyone) is accepted only together with a signed config (`CONNECT_SIGNED_CONFIG` or `CONNECT_SIGNED_CONFIG_FILE`). |
| `CONNECT_DENY_INSTALLS` | | Ids refused even under `*`. |
| `CONNECT_HOST`, `CONNECT_PORT` | `0.0.0.0`, `8790` | Bind address and port. |
| `CONNECT_TRUST_PROXY` | `0` | Number of trusted proxy hops in `X-Forwarded-For`. Used only for the per-IP budget. |
| `CONNECT_GITHUB_APP_ID`, `_APP_SLUG`, `_CLIENT_ID` | | The shared GitHub App. |
| `CONNECT_GITHUB_CLIENT_SECRET` | | Secret, dual. |
| `CONNECT_GITHUB_SECRET_GENERATION` | `1` | The generation recorded in new seals. |
| `CONNECT_GITHUB_MIN_SEAL_GENERATION` | `1` | Seals below this answer `needs_sign_in`. |
| `CONNECT_GITHUB_ACCEPTS_NEW` | `true` | `false` stops new sign-ins; refresh keeps working. |
| `CONNECT_GITHUB_ALLOWED_OWNERS` | | Numeric repository-owner ids that scoped mints are limited to. |
| `CONNECT_GOOGLE_CLIENT_ID`, `CONNECT_GOOGLE_CLIENT_SECRET` | | The secret is dual. Also `_SECRET_GENERATION`, `_MIN_SEAL_GENERATION` and `_ACCEPTS_NEW`. |
| `CONNECT_LINEAR_CLIENT_ID` | | Also `_ACCEPTS_NEW`. No secret: the server exchanges the code. |
| `CONNECT_SLACK_APP_ID`, `_CLIENT_ID` | | The shared Slack app. Token rotation must be on. |
| `CONNECT_SLACK_CLIENT_SECRET`, `CONNECT_SLACK_SIGNING_SECRET` | | Secrets, dual. Also `_SECRET_GENERATION`, `_MIN_SEAL_GENERATION` and `_ACCEPTS_NEW`. |
| `CONNECT_KLIPY_APP_KEY` | | Secret, dual. |
| `CONNECT_KLIPY_MODE` | `proxy` | `proxy` serves `/v1/klipy/*`. `key` publishes the key in `/v1/config` so servers call Klipy directly. |
| `CONNECT_SEAL_BACKEND` | `local` | `local` or `gcp-kms`. |
| `CONNECT_SEAL_KEYS` | | Secret, required for `local`. Comma-separated `kid:base64(32 bytes)`, newest first. Older entries still decrypt. |
| `CONNECT_KMS_KEY` | | `projects/…/locations/…/keyRings/…/cryptoKeys/…`, required for `gcp-kms`. Boot encrypts and decrypts a throwaway value with the seal cipher and refuses to start if the key or its IAM grant does not work. |
| `CONNECT_STATE` | `memory` | `memory` (one instance) or `redis`. |
| `CONNECT_REDIS_URL` | | Secret. `redis://` or `rediss://[user:pass@]host[:port][/db]`. |
| `CONNECT_REDIS_CA_FILE` | | PEM bundle for `rediss://`, for example the Memorystore server CA. |
| `CONNECT_BINDINGS` | `file` | `file` or `firestore`. |
| `CONNECT_DATA_DIR` | `data` (`/data` in the image) | Where `bindings.json` lives. The directory is mode 0700 and the file 0600. |
| `CONNECT_FIRESTORE_PROJECT`, `CONNECT_FIRESTORE_DATABASE` | `(default)` database | Bindings in `cc_connect_github` and `cc_connect_slack`. Uses metadata-server credentials. |
| `CONNECT_SIGNED_CONFIG_FILE` | | Hosted only. The offline-signed `/v1/config`, served verbatim and re-read every 30 s. An epoch rollback is ignored. Its lanes must match the credentials above, or Connect will not start. |
| `CONNECT_SIGNED_CONFIG` | | The same signed config inline, for hosts that cannot mount a file. Read once at boot: a new one needs a restart. Setting both is refused. |
| `CONNECT_CONFIG_PUBLIC_KEYS` | | Comma-separated Ed25519 keys the signed file must verify against. Also checked: the built-in `hostedConfigRootKeys`. A signed file with no key at all (neither here nor built in) refuses boot. |
| `CONNECT_CONFIG_EPOCH` | `1` | The epoch of a generated (self-hosted) config. |
| `CONNECT_LOG_HMAC_KEY` | random per process | Secret. Set it to keep log tags stable across instances and restarts. |
| `CONNECT_VERSION`, `CONNECT_IMAGE_DIGEST` | | Reported by `/v1/version`. |
| `CONNECT_RATE_INSTALL_PER_MINUTE` | `600` | Per-install request budget. |
| `CONNECT_RATE_IP_PER_MINUTE` | `300` | Per-IP budget. Slack hooks are exempt. |
| `CONNECT_RATE_GLOBAL_PER_SECOND` | `500` | Whole-service budget. |
| `CONNECT_RATE_SLACK_TEAM_PER_MINUTE` | `600` | Per Slack team, shared across instances through the state store. |
| `CONNECT_RATE_KLIPY_PER_MINUTE` | `120` | Klipy calls per install. |

A lane is served only when all of its variables are set. A partial lane is
simply absent from `/v1/config`, and its routes answer `provider_unavailable`.

### Provider registrations

Register these URLs with each provider, with `<base>` standing for
`CONNECT_PUBLIC_URL`:

- **GitHub App:**
  - Callback URL: `<base>/oauth/github/callback`.
  - Setup URL: `<base>/oauth/github/setup`, with "Redirect on update" enabled.
  - Leave "Request user authorization (OAuth) during installation" off.
    When it is on, GitHub ignores the setup URL.
  - Keep user-token expiration on. Connect requires refresh tokens.
- **Google:** redirect URI `<base>/oauth/google/callback`.
- **Linear:** `<base>/oauth/linear/callback` and
  `<base>/oauth/linear_app/callback`.
- **Slack:**
  - Redirect URLs: `<base>/oauth/slack_oidc/callback` and
    `<base>/oauth/slack/callback`.
  - Event Subscriptions: `<base>/v1/hooks/slack/events`. Subscribe to
    `app_mention`, `message.*`, `assistant_thread_*`, `app_uninstalled` and
    `tokens_revoked`.
  - Slash commands: `<base>/v1/hooks/slack/commands`.
  - Token rotation: on.

## Self-hosting with Docker

The release workflow publishes `ghcr.io/<owner>/cc-connect:<version>` and
`:latest` with SLSA provenance. To build it locally:

```bash
docker buildx build --build-context core=packages/cc_connect_core \
  -t cc-connect apps/cc_connect
```

Generate a seal key once and store it as a secret file:

```bash
docker run --rm cc-connect cc-connect-config seal-key > seal_keys
chmod 600 seal_keys
```

Then run it:

```bash
docker run -d --name cc-connect -p 8790:8790 \
  -e CONNECT_PUBLIC_URL=https://connect.example.com \
  -e CONNECT_ALLOWED_INSTALLS=<install id> \
  -e CONNECT_SEAL_KEYS_FILE=/run/secrets/seal_keys \
  -v "$PWD/seal_keys:/run/secrets/seal_keys:ro" \
  -e CONNECT_GITHUB_APP_ID=… -e CONNECT_GITHUB_APP_SLUG=… \
  -e CONNECT_GITHUB_CLIENT_ID=… \
  -e CONNECT_GITHUB_CLIENT_SECRET_FILE=/run/secrets/github \
  -v "$PWD/github_secret:/run/secrets/github:ro" \
  -v cc-connect-data:/data \
  cc-connect
```

Notes on the image:

- It runs as uid 10001 with PID 1 being the binary itself.
- `HEALTHCHECK` runs `cc-connect --healthcheck`.
- Put it behind TLS: `CONNECT_PUBLIC_URL` must be https off loopback.
- A single instance with `CONNECT_STATE=memory` is fine. Several instances
  need `CONNECT_STATE=redis`, and either a shared `CONNECT_DATA_DIR` or
  `CONNECT_BINDINGS=firestore`.

Install ids are per Connect origin. Point a server at this Connect first
(**Settings → Server → Single sign-on → Control Center Connect → Use a custom
Connect server**, or `cc_server connect enable --url <base>`); its card and
`cc_server connect status` then show its id for this Connect. Add it to
`CONNECT_ALLOWED_INSTALLS` and restart. Until then the server reports
`install_blocked`.

## Embedding in cc_server

`ConnectService` is a plain `dart:io` handler:

```dart
final service = await ConnectService.start(
  ConnectServiceConfig.fromEnvironment(Platform.environment),
);
// For each request: if (service.ownsPath(request.uri.path)) service.handle(request);
```

`cc_server` with `CC_SERVER_CONNECT_HOST=on` mounts it this way at
`<origin>/connect` (`apps/cc_server/lib/embedded_connect_host.dart`):

- Only `CONNECT_*` variables from the server's environment and `.env` reach the
  service, so it never sees the server's own provider apps.
- `CONNECT_PUBLIC_URL` defaults to the server's public origin plus `/connect`.
  Set it explicitly behind a proxy. Its path must be exactly `/connect`, and it
  must be https unless it is loopback. Signatures, seals and OAuth redirects are
  all bound to it.
- `CONNECT_ALLOWED_INSTALLS` is still required, including for the hosting
  server's own install id.
- The mount is routed after the server's own `/oauth/github/manifest/` and
  `/oauth/` handlers. A configuration error fails the server's boot instead of
  serving an open broker. The demo server never mounts it.

Connect's requests must bypass the host's session, CORS and body middleware.
The handler sets its own headers and closes the response. If a reverse proxy
strips the mount prefix, Connect still routes `/v1/*`, `/oauth/*` and
`/healthz`, and signatures still cover the full public URL.

## Hosted operation

- **Topology:**
  - Cloud Run service `cc-connect`, autoscaling from 1 to N, behind an
    External HTTPS Load Balancer with Cloud Armor. The `run.app` URL is
    disabled.
  - `CONNECT_STATE=redis` on Memorystore, with TLS and `CONNECT_REDIS_CA_FILE`.
  - `CONNECT_BINDINGS=firestore`.
  - `CONNECT_SEAL_BACKEND=gcp-kms` on an HSM key in a key-custody project. Only
    the runtime service account has `cloudkms.cryptoKeyEncrypterDecrypter`.
  - Secrets come from Secret Manager volumes (`*_FILE`). `CONNECT_TRUST_PROXY=1`.
- **Config:**
  - Write a payload and sign it offline with
    `cc-connect-config sign --seed seed --payload payload.json --out signed.json`.
  - Mount the result as `CONNECT_SIGNED_CONFIG_FILE` (or paste it into
    `CONNECT_SIGNED_CONFIG` where files cannot be mounted) together with
    `CONNECT_ALLOWED_INSTALLS=*`.
  - `cc-connect-config keygen --out seed` creates the signing seed. Keep it
    offline. Its public key goes in `hostedConfigRootKeys`; until a release
    carries one, servers report hosted mode as `hosted_unprovisioned`.
  - `cc-connect-config verify --key <pub> signed.json` checks a file.
  - The full procedure, payload shape and epoch rules are in
    [RELEASING.md](../../RELEASING.md#signing-v1config).
- **Deploy:** there is no deploy workflow. Deploy a released tag by digest after
  `gh attestation verify`, as described in
  [RELEASING.md](../../RELEASING.md#hosted-deploy).
- **Logs:** exclude `/oauth/*` from Cloud Run request logs at the Log Router
  so provider codes never reach a log. Application logs are already
  allowlisted JSON lines on stderr.
- **KMS outages:** a 5xx or 401 from KMS answers `provider_unavailable`,
  never `access_denied`, so servers keep their seals.

### Rotating a secret (under 60 seconds, nobody signed out)

1. Create the new secret at the provider, keeping the old one.
2. Move the old value to `NAME_PREVIOUS`, put the new one in `NAME`, and bump
   `CONNECT_<LANE>_SECRET_GENERATION`. File mounts are picked up within 30 s.
3. Run a refresh. New seals record the new generation. An `invalid_client`
   during propagation is retried once with the previous secret.
4. Delete the old secret at the provider, then remove `NAME_PREVIOUS`.

The Slack signing secret and the Klipy key rotate the same way, and both
values are accepted during the overlap. To rotate a local seal key, prepend a
new `cc-connect-config seal-key` entry to `CONNECT_SEAL_KEYS`. Keep the old
entry until its seals have been refreshed.

### Incident runbook

1. **A secret leaked, with no code execution in Connect:** rotate it as above.
   Revoke the old generation at the provider.
2. **Suspected code execution in Connect:**
   1. Revoke the runtime service account's KMS grant.
   2. Publish a signed config with `accepts_new_authorizations: false`.
   3. Rotate the GitHub, Google, Slack and Klipy secrets.
   4. Destroy the KMS key versions, which invalidates every seal including
      attacker-minted ones.
   5. Redeploy a clean, attested tag with a fresh key.
   6. Publish a new signed config at `epoch + 1` with a raised
      `min_seal_generation`, so affected users sign in again cleanly.

To block one install immediately, add it to `CONNECT_DENY_INSTALLS`.

## The reserved chat gateway

`POST /v1/chat/{provider}/act` is the outbound gateway for chat
bots whose token controls every tenant, such as Discord or Telegram. The
token would stay in Connect. A bound server would ask Connect to act, and
Connect would verify guild or chat ownership, send empty `allowed_mentions`,
and apply per-tenant budgets. The route is signed and routed today but always
answers `503 provider_unavailable`, so adding adapters keeps `/v1` additive.

## Development

```bash
cd apps/cc_connect
fvm dart analyze
fvm dart test --concurrency=2
```

To build the two native binaries without Docker (`dart compile exe` does not
create the output directory):

```bash
cd apps/cc_connect
mkdir -p build
fvm dart compile exe bin/server.dart -o build/cc-connect
fvm dart compile exe bin/config_tool.dart -o build/cc-connect-config
```

### Run locally

Plain http is accepted on loopback, so a development Connect needs only an
allowlist and a seal key:

```bash
cd apps/cc_connect
CONNECT_PUBLIC_URL=http://127.0.0.1:8790 \
CONNECT_ALLOWED_INSTALLS=<install id> \
CONNECT_SEAL_KEYS="$(fvm dart run cc_connect:config_tool seal-key)" \
CONNECT_GITHUB_APP_ID=… CONNECT_GITHUB_APP_SLUG=… \
CONNECT_GITHUB_CLIENT_ID=… CONNECT_GITHUB_CLIENT_SECRET=… \
fvm dart run bin/server.dart
```

Then point a local server at it with
`cc_server connect enable --url http://127.0.0.1:8790`; `cc_server connect
status` prints the install id to put in `CONNECT_ALLOWED_INSTALLS`. Register
the provider redirects against `http://127.0.0.1:8790`. Every lane is optional:
leave a provider's variables out and its lane is absent from `/v1/config`.

`config_tool` (the image's `cc-connect-config`) has four commands: `seal-key`,
`keygen --out <seed>`, `sign --seed <seed> --payload <json> [--out <file>]` and
`verify --key <public key> <signed.json>`.

The tests run a real `HttpServer` on loopback against a scripted
`UpstreamHttp`, plus an in-test RESP server for `RedisStateStore`. No test
reaches the network.
