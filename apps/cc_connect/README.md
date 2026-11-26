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
- The shared GitHub App's private key. It signs the App JWT for exactly three
  calls: finding the installation that covers one repository
  (`GET /repos/{owner}/{repo}/installation`), finding the owner's
  installation when the repository has none (`GET /users/{owner}/installation`,
  which tells `repo_not_selected` from `not_installed`), and minting a
  one-repository installation token (`as: app`) after the asking person's
  own sealed grant proved they can see that repository with the asked
  permission.
- The Klipy API key.
- The seal key: a local AES-256-GCM keyring or a Cloud KMS key.
- Short-lived state: staged logins with their consent-page form token, and
  Slack event references (10 minutes), nonces and seal handoffs (5 minutes), rotation leases (30
  seconds), and a person's GitHub installation listing (5 minutes). Every
  read that authorizes a mint (the installation, the repository permission)
  is fresh, so a demoted role or an uninstall applies at once.
- For each GitHub token minted `as: user`, until it expires (at most 8
  hours): which install and account may revoke it, and a copy sealed to the
  sign-in that minted it, so a later mint can reuse it and a disconnect can
  revoke it.
- The retired installs: every install id whose own key retired it
  (`POST /v1/install/retire`), for good, in the binding store, at most
  100,000 of them.
- Fixed-window counters for the budgets in [Budgets](#budgets), in the state
  store.
- Slack bindings. A Slack team maps to the one install it is bound to, and
  its bot user. Writes are compare-and-set; a file write that fails leaves
  nothing changed in memory. GitHub installations have no binding: any
  server a member signs in on may mint against the account's installation,
  and each token is that member's own, clamped to their role.

Connect never holds:

- A GitHub webhook secret, or an installation token after it answered:
  servers revoke installation tokens themselves (`DELETE
  /installation/token`).
- Refresh tokens at rest. They exist only inside seals, which servers store.
- Source code, repository contents, Slack message text, or Linear secrets.
  The Linear code is handed back to the server, which runs the exchange
  itself. The one exception is slash-command argument text (at most 500
  characters), which is queued for the bound server for up to 10 minutes so
  it can draft from it.

Connect never echoes an upstream body. Every failure is
`{"error":"<code>"}` with the status from `ConnectErrorCode`. Logs carry
allowlisted fields only (see [Logs and monitoring](#logs-and-monitoring)).

## Routes

All paths are relative to `CONNECT_PUBLIC_URL`. Mounted at `/connect`, for
example, `/v1/config` is served at `/connect/v1/config`. Every answer carries
`Cache-Control: no-store`, `X-Content-Type-Options: nosniff`,
`Referrer-Policy: no-referrer`, an `X-Request-Id` that its log lines carry,
and `Strict-Transport-Security: max-age=31536000` when `CONNECT_PUBLIC_URL`
is https. The consent page alone carries `Referrer-Policy: same-origin`
instead: under `no-referrer` a browser sends `Origin: null` with the page's
own form post, and `same-origin` makes it send Connect's origin there while
still sending nothing to any other origin. Connect sends no CORS headers. A
signed body is capped at 16 KB.

| Route | Auth | Purpose |
| --- | --- | --- |
| `GET /healthz` | none | Liveness: the process answers. Spends no rate-limit token. |
| `GET /readyz` | none | Readiness: the state store and the binding store answer and, on Redis, `maxmemory-policy` is still `noeviction` (`503` when not), checked at most every 5 s. Spends no rate-limit token. |
| `GET /v1/version` | none | `protocol`, `version`, and `image_digest` when set. |
| `GET /v1/config` | install signature | Lanes and epoch. A hosted Connect serves its offline-signed file byte for byte. A self-hosted one generates the config from its complete lanes. |
| `POST /v1/oauth/{lane}/start` | install signature | Lanes are `github`, `google`, `linear`, `linear_app` and `slack`. Returns `login_id` plus an authorize URL that Connect checks with `validateAuthorizeUrl` before returning it. GitHub's carries `prompt=select_account`, the only `prompt` GitHub documents, so the account picker always appears. Records the caller's truncated address for the consent page. One address may start `CONNECT_RATE_LOGINS_IP_PER_10_MINUTES` logins per 10 minutes, which also caps its outstanding logins (a login lives 10 minutes). |
| `GET /oauth/{segment}/callback` | single-use `state` | Provider redirect. Segments are `github`, `google`, `linear`, `linear_app`, `slack_oidc` and `slack`. Stashes the code, sets the `__Host-cc_connect` cookie (`SameSite=Lax`, `HttpOnly`), and answers 303 to `/oauth/{lane}/done`. |
| `GET /oauth/{lane}/done` | `__Host-` cookie | The consent page. It says in plain words what the server that started the sign-in will be able to do and for how long, that Connect cannot tell who runs that server, and to close the page if someone sent the link. When the browser's truncated address differs from the one the sign-in was started from, it adds that this is normal for a hosted server or another device and is also what phishing looks like; that sentence changes nothing else. Two buttons post back to the same path: continue and cancel. It shows no code and no deep link. Its CSP allows `form-action 'self'`; every other page has `form-action 'none'`. |
| `POST /oauth/{lane}/done` | `__Host-` cookie and the page's form token | The consent page's answer (`action=continue` or `action=cancel` with `token`, at most 256 bytes). Each consent page carries a fresh 256-bit form token, kept with the login and good for one answer; a post without it, or with another, is refused (`oauth.done_refused` reason `token`) and leaves the login as it was. Continue shows the 8-character confirm code and the `control-center://oauth-done` link, with the warning that anyone who gets the code gets the access just approved. Cancel burns the login, so the provider's code is never exchanged. A request whose `Sec-Fetch-Site` is present and not `same-origin`, whose `Origin` names an origin other than Connect's public one, or that carries neither is refused (`oauth.done_refused` reason `cross_site`, `origin` or `no_origin`). `Origin: null` names no origin and counts as not sent: a browser writes it when the posting page withholds its origin, so such a post rests on `Sec-Fetch-Site` alone. Every page has `default-src 'none'` with a hashed style, no script, and cannot be framed. |
| `POST /v1/oauth/{lane}/claim` | signature, confirm code, PKCE verifier | Single use, and five wrong attempts burn the login. Exchanges the code, checks fixed scopes, and returns a `SealedGrant`. For Linear it returns a `LinearCodeGrant`. For Slack, a claim holds the team's exchange mark (`slackclaim:<team>`, 2 minutes) before the login is spent, so only one bot exchange (which rotates the team's single bot token) runs at a time; a claim that finds it held answers `rate_limited` (`slack_exchange_busy`) and can be retried. A team's first binding needs the approving person to be a workspace admin or owner (`not_admin` otherwise). A GitHub claim spends the GitHub budgets before the login is spent (see [Budgets](#budgets)). |
| `GET /oauth/github/setup` | none | GitHub App `setup_url`. Records nothing; a static page says whether the app was installed, updated or requested. |
| `POST /v1/github/refresh`, `/v1/google/refresh`, `/v1/slack/refresh` | signature + seal | Fresh access token plus a rotated seal, always: the parent refresh token is single use, so a still-fresh access token is not handed back unrotated (a scope mint does reuse a still-fresh parent). One rotation per seal runs at a time, under a 30-second lease its holder renews and releases; a crashed holder's lease lapses. A retried old seal replays the rotation for 5 minutes (`seal_handoff`), so a lost response never burns a single-use refresh token; a handoff that cannot be written is retried once and logged (`seal.handoff_unsaved`). |
| `POST /v1/github/scope` | signature + seal | Mints one token for one `repo_id`, clamped to the caller's repository role, when the app is installed on the repository's owner. `as` picks whose: `user` is a child of the person's user token (`/applications/{client_id}/token/scoped`); `app` is an installation token of the App (`POST /app/installations/{id}/access_tokens` with `repository_ids: [repo_id]` and the clamped permissions), found through `GET /repos/{o}/{r}/installation`. `app` mints `read`, `review` and `comment` for every install, and `bot` (which writes pull requests: reviews) only for installs listed in `CONNECT_GITHUB_REVIEW_BOT_INSTALLS`; anything else answers `needs_requester` (403, reason `github_app_review_scope` or `github_app_write_scope`) before GitHub is asked, since nothing binds an organization's installation to one server. The server then mints the same scope `as: user`, which GitHub clamps to the person. An installation on the owner that does not include the repository answers `repo_not_selected`. Either answer must cover exactly that repository with exactly the granted permissions, or it is revoked and refused; both carry `repository_selection`, `repositories` and `permissions` so the server checks the same. A `user` mint reuses a live child minted for the same install, workspace, GitHub account, repository, permissions and parent (sealed under the caller's binding) instead of minting another, until it is revoked or has under 65 minutes left; the audit line says `reused`. The parent token is refreshed first when it has under 65 minutes left. |
| `POST /v1/github/review_comments` | signature + seal | Proxies a batch of up to 25 inline pull-request review comments (`256 KB` body cap) for any Connect install as the shared App's bot without exposing a `pull_requests: write` token. Connect checks the person's own fresh `GET /repos/{o}/{r}` (`push` role or higher and matching `repo_id`) and `GET /user` (matching `account_id`), mints a single-repository `{metadata: read, pull_requests: write}` installation token, prefixes every comment with `**Control Center** (for @login): ` from the verified GitHub account, neutralizes `@`-mentions, posts to `POST /repos/{o}/{r}/pulls/{n}/comments` (returning per-comment `posted`, `out_of_diff` or `failed` status), and immediately revokes the installation token in `finally`. Comment bodies and file paths are transient in RAM and never logged. |
| `POST /v1/github/installations` | signature + seal | The person's installations of the app, each with `suspended`. |
| `POST /v1/github/revoke` | signature + seal | Revokes this sign-in only. It spends the seal's refresh token once (a refresh, under the seal's rotation lease), deletes the access token that refresh returned and the seal's own user token (`DELETE /applications/{client_id}/token`), seals nothing, and revokes every child Connect minted for the same install, workspace and GitHub account. A copy of the seal kept anywhere then answers `needs_sign_in`. The person's sign-ins on other servers keep working; the App's authorization is never deleted. With `scoped_token`, revokes that one child, and only with a seal of the same install and the same GitHub account it was minted for. |
| `POST /v1/install/retire` | install signature; `{seal, workspace_id}` | Retires the install that signed it, for good: its id joins the retired set in the binding store and every later request it signs answers `install_blocked`. The body names any credential seal Connect made for that install (any lane, any workspace, any generation the keyring still opens): Connect retires only when it opens under the signing install, and asks no provider. No seal is `invalid_request`; a seal of another install or workspace is `access_denied`. So only an install that signed someone in can reach the retired set. Never reachable unsigned. One address (an IPv6 /48) may retire `CONNECT_RATE_RETIRE_IP_PER_HOUR` installs an hour. When the set holds 100,000 ids, retire answers `provider_unavailable` and logs `install.retire_refused` at error. The install's Slack team bindings are released (compare-and-set, `slack.released` reason `retired`), so those teams can connect another server without uninstalling the bot. Tokens already handed out are not revoked: user tokens and one-repository children live at most 8 hours, installation tokens 1 hour. A server calls it with its old key and one stored seal before it switches to a new key, and skips a Connect it holds no seal of. |
| `POST /v1/slack/revoke` | signature + seal | `auth.revoke`, then releases the team binding. Only the bound install can call it. |
| `POST /v1/events/poll` | install signature | Long poll of up to 25 s for Slack event and command references for teams bound to the caller. At most two concurrent polls per install. |
| `POST /v1/hooks/slack/events` | `X-Slack-Signature` | Events API intake. Bodies are capped at 256 KB. A request without Slack's headers, with a timestamp off by more than 5 minutes, or over the cap is refused before its body is buffered or hashed. Every signed event is answered 200, even when it cannot be queued, so Slack does not disable the subscription; one that failed is not marked seen, so Slack's retry is taken. An event is routed by the installation Slack delivered it for: the workspace its `authorizations` entries name, which must all agree. One without `authorizations`, or whose entry names no workspace (an organization-wide installation), is dropped (`slack.event_dropped`, `no_authorization`). The envelope's `team_id`, which in a channel shared between workspaces names where the event happened, is only logged. The text is dropped and a reference is queued. `app_uninstalled` and bot `tokens_revoked` release the team once per event id, for `tokens_revoked` only when the revoked bots include the bound bot user, and only when the event is newer than the current binding, so a retry or replay never frees a team that was connected again. |
| `POST /v1/hooks/slack/commands` | `X-Slack-Signature` | Slash commands get a fixed ephemeral answer. A bounded reference is queued. The same pre-checks as events apply. |
| `POST /v1/klipy/search`, `/v1/klipy/trending` | install signature | GIF proxy in `proxy` mode, on a budget per install and one per client address shared by every install. URLs off Klipy's CDN are dropped. |

Every request except `/healthz` and `/readyz` first takes a token from its
client address's bucket (an IPv6 address counts per /64), then from the
instance-wide one; the Slack hooks have buckets of their own. Signed requests
are then checked in this order:

1. Body cap.
2. Allow and deny list for the install id the signature claims
   (`install_blocked`), before any signature work.
3. RFC 9421 verification. The target URI is `CONNECT_PUBLIC_URL` plus the
   path; `Host` and `X-Forwarded-*` are never read.
4. Allow and deny list for the verified install id.
5. The retired set (`install_blocked`): an install retired by its own key is
   refused on every route, for good.
6. Nonce replay cache (`stale_request`).
7. Per-install budget.

The request buckets above are per instance. The Slack team budget and the
budgets in [Budgets](#budgets) are kept in the state store, so they hold
across instances.

A seal is opened only with the verified install id and the body's
`workspace_id`. A seal from another install, workspace or Connect fails to
decrypt and is answered `access_denied`, before anything else about it (a
Slack team's binding included) is looked at. The record Connect keeps of a
child token is sealed under a context of its own, so it never opens as a
grant.

## Budgets

Fixed-window counters in the state store, shared by every instance. Each is
checked before anything is counted, so a refused call spends nothing. Past
one, the call answers `rate_limited` and logs `ratelimit.hit` with the
bucket. `rate_limited` is transient: `ConnectErrorCode.clearsGrant` is true
only for `needs_sign_in`, so a server retries later and never drops a grant
for it.

| Bucket | Counts | Limit |
| --- | --- | --- |
| `logins_ip` | Logins started, per client address | `CONNECT_RATE_LOGINS_IP_PER_10_MINUTES` (60) per 10 minutes |
| `github_account` | GitHub token-endpoint calls (code exchange, refresh, user child) per GitHub account and install: one server spends only its own share of a person's budget | `CONNECT_RATE_GITHUB_TOKENS_ACCOUNT_PER_HOUR` (30) |
| `github_account_ceiling` | The same calls per GitHub account across every install | `CONNECT_RATE_GITHUB_TOKENS_ACCOUNT_CEILING_PER_HOUR` (four shares, 120) |
| `github_address` | The same calls per client address | `CONNECT_RATE_GITHUB_TOKENS_IP_PER_HOUR` (600) |
| `github_exchange_ceiling` | Code exchanges (new sign-ins) for the whole App | `CONNECT_RATE_GITHUB_EXCHANGE_CEILING_PER_HOUR` (500) |
| `github_ceiling` | Refreshes and user children for the whole App | `CONNECT_RATE_GITHUB_TOKEN_CEILING_PER_HOUR` (1,500) |
| `github_app_install` | `as: app` mints per install | `CONNECT_RATE_GITHUB_APP_MINTS_INSTALL_PER_HOUR` (120) |
| `github_app_account` | `as: app` mints per asking GitHub account, across installs | `CONNECT_RATE_GITHUB_APP_MINTS_ACCOUNT_PER_HOUR` (240) |
| `github_app_ceiling` | `as: app` mints (App JWT calls) for the whole App | `CONNECT_RATE_GITHUB_APP_CEILING_PER_HOUR` (3,000) |
| `klipy_ip` | Klipy calls per client address | `CONNECT_RATE_KLIPY_IP_PER_MINUTE` (240) |
| `retire_ip` | Install retirements per client address (an IPv6 /48) | `CONNECT_RATE_RETIRE_IP_PER_HOUR` (10) |
| `slack_exchange_busy` | Not a counter: a Slack claim while another exchange for the team runs | One at a time per team |

How the GitHub calls are refused:

- A code exchange (a claim) is refused per address and by the sign-in
  ceiling (`github_exchange_ceiling`) before the login is spent, so it can be
  retried. Sign-ins never count against `github_ceiling`, so a flood of them
  cannot hold refreshes and children back. Once the exchange names the
  account, it counts against that account's share for the install and its
  account-wide ceiling; over either, the token just minted is revoked at
  GitHub and the claim answers `rate_limited` instead of a grant.
- A refresh and a new user child are refused by the account's share, its
  ceiling, the address or `github_ceiling`.
- An `as: app` mint is refused by its install, the asking account or the
  App-wide bot ceiling, checked once the seal opened and before GitHub is
  asked.
- A disconnect's one refresh is counted and never refused.
- `github.token_cap` (warn, sampled) is logged when one GitHub account holds
  more than `CONNECT_GITHUB_TOKEN_CAP_WARN` (10) live children across all
  installs, counted per 8-hour window of their lifetime.

Why these numbers, and what is documented:

- **Documented** for OAuth apps, not GitHub Apps: GitHub issues at most ten
  tokens per user, application and scope combination, and creates at most ten
  tokens per hour for that combination. Past ten live tokens it revokes one:
  the oldest never-used one older than a minute, else the least recently used,
  else the oldest. Hitting the hourly limit revokes nothing; the person sees a
  re-authorization prompt.
- **Not documented** for GitHub Apps: any limit on user tokens per person, on
  `POST /applications/{client_id}/token/scoped`, or on the token endpoint per
  hour. Whether a refresh invalidates the previous access token is not
  documented either. The figure of about 2,000 token-endpoint calls an hour
  per App is an assumption, not a documented limit; the ceiling (1,500) stays
  below it.
- **Assumed:** that GitHub Apps follow the OAuth-app rules above. The per
  account default (30 an hour) allows a sign-in, its refreshes and a working
  day's children; the warning threshold (10) is the documented OAuth-app count
  at which GitHub starts revoking. Connect does not evict children itself: it
  refuses before the budget is spent and warns at the threshold.
- **Verify before relying on it:** whether the shared App's live user tokens
  per person are capped (and which one GitHub revokes past the cap), by
  minting more than ten children for one test account and checking which
  still answer `GET /user`.

## The shared bot

Every server that uses one Connect gets the same GitHub App bot: GitHub shows
the same actor whichever server minted the token, and nothing binds an
organization's installation to one server.

- `read`, `review` and `comment` may be minted `as: app` for every install.
  `comment` is `{metadata: read, issues: write}`: comments on the
  conversation, labels, assignees and reactions, nothing on pull request
  reviews or code. An unlisted server's bot can therefore comment and label
  on any repository its person can push to.
- `bot` (`pull_requests: write`: reviews) may be minted `as: app` only for an
  install listed in `CONNECT_GITHUB_REVIEW_BOT_INSTALLS`, which must also pass
  the allow and deny lists. Every other install's request answers
  `needs_requester` before GitHub is asked, and the server mints the same
  scope `as: user`: the review is then the person's, clamped by GitHub.
- Inline review comments from the AI review UI (`POST /v1/github/review_comments`)
  post as the shared App's bot for **every** install without listing install
  ids: Connect keeps the single-repo `pull_requests: write` installation token
  in memory, verifies `push` access and the caller's GitHub login, applies
  `**Control Center** (for @login): ` attribution and mention neutralization,
  posts only inline review comments (never `APPROVE`, dismissals or PR edits),
  and revokes the installation token immediately. Because comment bodies and
  paths pass transiently through Connect RAM (zero-retention, never logged),
  strict zero-egress organizations use an own GitHub App or self-hosted
  Connect.
- `write` is never minted `as: app` on Connect.
- A self-hoster lists their own servers' install ids
  (`cc_server connect status` prints them) to let them review as the bot.

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
| `CONNECT_TRUST_PROXY` | `0` | Number of trusted proxy hops in `X-Forwarded-For`. Used only for the per-address budgets, the consent page's network hint and the logged `ip`. Behind a proxy, leaving it at `0` puts every client in the proxy's bucket: the first request carrying `X-Forwarded-For` while it is `0` logs `config.trust_proxy_unset` once. |
| `CONNECT_GITHUB_APP_ID`, `_APP_SLUG`, `_CLIENT_ID` | | The shared GitHub App. |
| `CONNECT_GITHUB_CLIENT_SECRET` | | Secret, dual. |
| `CONNECT_GITHUB_APP_PRIVATE_KEY` | | Secret (PEM). Required for the GitHub lane: signs the App JWT that mints one-repository installation tokens (`as: app`), each authorized by the asking person's own sealed grant. On a host without secret files set it as a sealed variable: the PEM as downloaded, on one line with literal `\n` escapes or spaces for line breaks, or base64-encoded whole (`base64 -i key.pem`) are all read as the same key. |
| `CONNECT_GITHUB_SECRET_GENERATION` | `1` | The generation recorded in new seals. |
| `CONNECT_GITHUB_MIN_SEAL_GENERATION` | `1` | Seals below this answer `needs_sign_in`. |
| `CONNECT_GITHUB_ACCEPTS_NEW` | `true` | `false` stops new sign-ins; refresh keeps working. |
| `CONNECT_GITHUB_ALLOWED_OWNERS` | | Numeric repository-owner ids that scoped mints (`/v1/github/scope`) are limited to. A mint filter, not a sign-in filter: anyone allowed to use this Connect can still sign in, receive their full App user token and list every installation of the App. To serve one organization only, keep the App private to it. |
| `CONNECT_GITHUB_REVIEW_BOT_INSTALLS` | | Comma-separated install ids whose `as: app` mints may carry `bot` (pull request reviews as the App's bot). Empty by default; `*` is refused, and each id must also pass `CONNECT_ALLOWED_INSTALLS` and `CONNECT_DENY_INSTALLS` or Connect will not start. See [The shared bot](#the-shared-bot). |
| `CONNECT_GOOGLE_CLIENT_ID`, `CONNECT_GOOGLE_CLIENT_SECRET` | | The secret is dual. Also `_SECRET_GENERATION`, `_MIN_SEAL_GENERATION` and `_ACCEPTS_NEW`. |
| `CONNECT_LINEAR_CLIENT_ID` | | Also `_ACCEPTS_NEW`. No secret: the server exchanges the code. |
| `CONNECT_SLACK_APP_ID`, `_CLIENT_ID` | | The shared Slack app. Token rotation must be on. |
| `CONNECT_SLACK_CLIENT_SECRET`, `CONNECT_SLACK_SIGNING_SECRET` | | Secrets, dual. Also `_SECRET_GENERATION`, `_MIN_SEAL_GENERATION` and `_ACCEPTS_NEW`. |
| `CONNECT_KLIPY_APP_KEY` | | Secret, dual. |
| `CONNECT_KLIPY_MODE` | `proxy` | `proxy` serves `/v1/klipy/*`. `key` publishes the key in `/v1/config` so servers call Klipy directly. |
| `CONNECT_SEAL_BACKEND` | `local` | `local` or `gcp-kms`. |
| `CONNECT_SEAL_KEYS` | | Secret, required for `local`. Comma-separated `kid:base64(32 bytes)`, newest first. Older entries still decrypt. |
| `CONNECT_KMS_KEY` | | `projects/…/locations/…/keyRings/…/cryptoKeys/…`, required for `gcp-kms`. Boot encrypts and decrypts a throwaway value with the seal cipher and refuses to start if the key or its IAM grant does not work. |
| `CONNECT_STATE` | `memory` | `memory` (one instance) or `redis`. The memory store holds at most 200,000 entries and 200,000 nonces; when full it refuses new writes (`provider_unavailable`, logged as `state.full`) and never evicts a live entry. |
| `CONNECT_REDIS_URL` | | Secret. `redis://` or `rediss://[user:pass@]host[:port][/db]`. Needs Redis 6.2 or later (`GETDEL`) and `maxmemory-policy noeviction`, both checked at boot (`INFO memory`; anything else exits 78): an evicted nonce, lease or budget counter would allow a replay, a double rotation or a fresh budget. |
| `CONNECT_REDIS_CA_FILE` | | PEM bundle for `rediss://`, for example the Memorystore server CA. |
| `CONNECT_BINDINGS` | `file` | `file` or `firestore`. |
| `CONNECT_DATA_DIR` | `data` (`/data` in the image) | Where `bindings.json` lives. The directory is mode 0700. The file is written to a temporary file created 0600 (never chmod-ed after the fact) and renamed. Connect holds an exclusive lock on `bindings.lock` there, so a second Connect on the same directory refuses to start. A `bindings.json` in any other shape is refused. |
| `CONNECT_FIRESTORE_PROJECT`, `CONNECT_FIRESTORE_DATABASE` | `(default)` database | Slack bindings in `cc_connect_slack`. Uses metadata-server credentials. Boot reads one document and refuses to start if Firestore does not answer. |
| `CONNECT_SIGNED_CONFIG_FILE` | | Hosted only. The offline-signed `/v1/config`, served verbatim and re-read every 30 s. An epoch rollback is ignored. Its lanes must match the credentials above, or Connect will not start. |
| `CONNECT_SIGNED_CONFIG` | | The same signed config inline, for hosts that cannot mount a file. Read once at boot: a new one needs a restart. Setting both is refused. |
| `CONNECT_CONFIG_PUBLIC_KEYS` | | Comma-separated Ed25519 keys the signed file must verify against. Also checked: the built-in `hostedConfigRootKeys`. A signed file with no key at all (neither here nor built in) refuses boot. When `CONNECT_ALLOWED_INSTALLS=*` is served under a config that verifies only under a key from this list, boot logs `config.open_to_any_install` at error: every install on the internet may then use this Connect's apps and secrets. |
| `CONNECT_CONFIG_EPOCH` | `1` | The epoch of a generated (self-hosted) config. |
| `CONNECT_LOG_HMAC_KEY` | random per process | Secret. Set it to keep log tags stable across instances and restarts. |
| `CONNECT_SENTRY_DSN` | | Secret. Reports error lines to Sentry (see [Sentry](#sentry)). Must be an https DSN. |
| `CONNECT_SENTRY_ENVIRONMENT` | `hosted` or `self-hosted` | The Sentry environment, up to 64 letters, digits, `_`, `.` or `-`. |
| `CONNECT_VERSION`, `CONNECT_IMAGE_DIGEST` | | Reported by `/v1/version`. |
| `CONNECT_RATE_INSTALL_PER_MINUTE` | `600` | Per-install request budget. |
| `CONNECT_RATE_IP_PER_MINUTE` | `300` | Per-IP budget, per instance. Not used by the Slack hooks. |
| `CONNECT_RATE_GLOBAL_PER_SECOND` | `500` | Budget of the whole instance. Not used by the Slack hooks. |
| `CONNECT_RATE_SLACK_HOOK_IP_PER_MINUTE` | `600` | Per-IP budget of the two Slack hooks, per instance. |
| `CONNECT_RATE_SLACK_HOOK_GLOBAL_PER_SECOND` | `100` | Budget of the two Slack hooks on the whole instance. |
| `CONNECT_RATE_SLACK_TEAM_PER_MINUTE` | `600` | Per Slack team, shared across instances through the state store. |
| `CONNECT_RATE_KLIPY_PER_MINUTE` | `120` | Klipy calls per install. |
| `CONNECT_RATE_KLIPY_IP_PER_MINUTE` | `240` | Klipy calls per client address, across installs and instances. |
| `CONNECT_RATE_LOGINS_IP_PER_10_MINUTES` | `60` | Logins started per client address. |
| `CONNECT_RATE_GITHUB_TOKENS_ACCOUNT_PER_HOUR` | `30` | GitHub token-endpoint calls per GitHub account and install. |
| `CONNECT_RATE_GITHUB_TOKENS_ACCOUNT_CEILING_PER_HOUR` | four times the share (`120`) | GitHub token-endpoint calls per GitHub account across installs; at least the share. |
| `CONNECT_RATE_GITHUB_TOKENS_IP_PER_HOUR` | `600` | GitHub token-endpoint calls per client address. |
| `CONNECT_RATE_GITHUB_EXCHANGE_CEILING_PER_HOUR` | `500` | App-wide ceiling on code exchanges (new sign-ins). |
| `CONNECT_RATE_GITHUB_APP_MINTS_INSTALL_PER_HOUR` | `120` | `as: app` mints per install. |
| `CONNECT_RATE_GITHUB_APP_MINTS_ACCOUNT_PER_HOUR` | `240` | `as: app` mints per asking GitHub account, across installs. |
| `CONNECT_RATE_GITHUB_APP_CEILING_PER_HOUR` | `3000` | App-wide ceiling on `as: app` mints. |
| `CONNECT_RATE_GITHUB_TOKEN_CEILING_PER_HOUR` | `1500` | App-wide ceiling on refreshes and child mints; sign-ins have their own. |
| `CONNECT_GITHUB_TOKEN_CAP_WARN` | `10` | Live children one GitHub account may hold across installs before `github.token_cap` is logged. |
| `CONNECT_RATE_RETIRE_IP_PER_HOUR` | `10` | Install retirements per client address (an IPv6 /48). |

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
  -e CONNECT_GITHUB_APP_PRIVATE_KEY_FILE=/run/secrets/github_key \
  -v "$PWD/github_app_key.pem:/run/secrets/github_key:ro" \
  -v cc-connect-data:/data \
  cc-connect
```

Notes on the image:

- It runs as uid 10001 with PID 1 being the binary itself.
- `HEALTHCHECK` runs `cc-connect --healthcheck`, which probes `/healthz`
  (liveness). Point an orchestrator's readiness check at `/readyz`.
- Put it behind TLS: `CONNECT_PUBLIC_URL` must be https off loopback.
- A single instance with `CONNECT_STATE=memory` and file bindings is fine.
  Several instances need `CONNECT_STATE=redis` and
  `CONNECT_BINDINGS=firestore`: file bindings lock their directory, so a
  shared `CONNECT_DATA_DIR` is refused.

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
strips the mount prefix, Connect still routes `/v1/*`, `/oauth/*`,
`/healthz` and `/readyz`, and signatures still cover the full public URL.

## Logs and monitoring

Every log line is one JSON object on one line: `ts`, `level` (`info`, `warn`
or `error`), `message` and `event` (both the event name), and the fields
that event carries. Lines written while a request runs also carry its
`request_id` (the `X-Request-Id` answered), its `route` and, once the
signature verified, the caller's `install` tag. `info` and `warn` lines go to
stdout, `error` lines to stderr.

Only allowlisted fields are written, and only short identifier-shaped values
that carry no GitHub token prefix (`ghp_`, `gho_`, `ghu_`, `ghs_`, `ghr_`,
`github_pat_`). A field outside the list, or a value of the wrong shape, is
replaced by a
`log.field_dropped` line naming the event and the field, never written. A
test checks every field used in the code against the list.

What identifies whom:

- GitHub user ids (`github_user_id`), installation ids and repository ids are
  logged as they are.
- Install ids and Slack team ids appear only as `install` and `team` tags, an
  HMAC of the id. Set `CONNECT_LOG_HMAC_KEY` to keep tags stable across
  restarts and replicas; without it each process picks a random key and the
  same install gets a new tag after every restart.
- Client addresses (`ip`) are truncated to their /24 (IPv4) or /48 (IPv6).
- A GitHub token Connect hands out or rotates is logged only as
  `hashed_token`: base64 of its SHA-256, the value GitHub's organization audit
  log shows for the same token (`echo -n TOKEN | openssl dgst -sha256 -binary
  | base64`), so an organization owner can match the two. `github_request_id`
  is GitHub's `X-GitHub-Request-Id` for a mint and for a failed GitHub call.

Audit and security events:

| Event | Level | When |
| --- | --- | --- |
| `http.request` | info | Every request: `method`, `status`, `ms`. |
| `http.refused` | warn | A request refused with a wire code (`error`, `reason`), or a store or provider outage (`backend`, `reason`). |
| `http.client_aborted` | warn | The client closed the connection before its request body arrived in full. Never reported to Sentry. |
| `http.error` | error | Anything unexpected. `exception` is the runtime type only, never the message. Reported to Sentry. |
| `auth.refused` | warn | A signed request refused: `reason` is `malformed`, `digest`, `stale`, `signature`, `replay`, `blocked` or `retired`, with `ip`. |
| `ratelimit.hit` | warn | A bucket ran dry: `bucket` (`ip`, `global`, `hook_ip`, `hook_global`, `install`, `verify`, or one of [Budgets](#budgets)), with `ip`, `install` or `github_user_id`. |
| `github.token_cap` | warn | One GitHub account holds more live children across installs than `CONNECT_GITHUB_TOKEN_CAP_WARN`: `github_user_id`, `count`. |
| `install.retired`, `install.retire_refused` | info, error | An install retired itself (`install` tag), or a retirement was refused because the retired set is full. |
| `slack.released`, `slack.release_failed` | info, error | A Slack team binding was released (`team` tag, `reason`: `revoke`, `retired` or the Slack event type), or a retirement could not release its teams. |
| `oauth.done_refused`, `oauth.cancelled` | warn, info | A consent-page post refused (`reason`: `cross_site`, `action`, `login_unknown`, `token`), or a person cancelled a sign-in. |
| `config.open_to_any_install` | error | At boot: `CONNECT_ALLOWED_INSTALLS=*` under a signed config that verifies only under an operator key. |
| `config.trust_proxy_unset` | warn | Once per process: a request carried `X-Forwarded-For` while `CONNECT_TRUST_PROXY` is 0. |
| `seal.refused` | warn | A seal that does not open or is not accepted: `provider`, `reason` (`malformed`, `provider`, `decrypt`, `retired_app`, `below_min_generation`). |
| `seal.encrypt_failed` | error | Sealing failed after three attempts. The provider already rotated the grant, so that person must sign in again. |
| `seal.keyring_reload_failed` | error | A changed `CONNECT_SEAL_KEYS` file does not parse; the last good keyring stays in use. |
| `seal.handoff_unsaved` | error | A rotation's handoff could not be written. |
| `github.signed_in`, `github.rotated` | info | A person's user token was issued or rotated: `github_user_id`, `hashed_token`. |
| `github.mint` | info, warn | A one-repository token: `as`, `outcome` (`ok` or `refused`), ids, scopes, `reused`, `hashed_token`, `github_request_id`; a refusal carries `error` and `reason`. |
| `github.child_revoked`, `grant.revoked` | info | A revoke: `outcome`, or `scope: token`, `reason` (`refresh_spent` or `refresh_already_spent`) and the `count` of children revoked with the sign-in. |
| `github.token_budget` | warn, error | Calls to GitHub's token endpoints (code exchanges, refreshes and child mints) in the last hour, shared by every server on the App. Written at most every 10 minutes while above 1,000 (warn), and at error above 1,800. |
| `upstream.failed` | warn, info | A provider call failed: `upstream`, `upstream_status` or `reason`, `github_request_id`. Transport errors, 429 and 5xx are warn. |
| `oauth.callback_refused`, `oauth.claim_refused`, `oauth.claim_failed` | warn | A browser callback or a claim refused, with its `reason`. |
| `config.changed`, `config.reload_failed`, `config.rollback_ignored` | warn, error | The signed config file changed (`epoch`, `lanes`, `paused`), or a new one was not taken. |
| `slack.signature_refused`, `slack.event_dropped`, `slack.event_failed` | warn, error | A Slack hook refused (`reason`: `headers`, `stale`, `signature`), or an event not queued. |
| `state.full` | error | The memory state store refused a write. |
| `readyz.failed` | warn | `/readyz` found a backend down. |
| `readyz.eviction_policy` | error, info | Once per change: Redis's `maxmemory-policy` is no longer `noeviction` (`reason` is the policy; `/readyz` answers 503), or is again. |

Refusal events (`auth.refused`, `ratelimit.hit`, `seal.refused`,
`slack.signature_refused`, `state.full`, `log.field_dropped`) are sampled:
the first line per key and minute is written, and the next one counts what
was held back in `suppressed`.

### Sentry

Set `CONNECT_SENTRY_DSN` (or `CONNECT_SENTRY_DSN_FILE`) to report `http.error`
and every other `error` line to Sentry. Connect posts an envelope to
`https://<dsn host>/api/<project>/envelope/` itself; there is no SDK, and the
DSN's host is added to the upstream allowlist only when the variable is set.
An event holds only: an event id, the timestamp, the level, logger
`cc_connect`, the release (`CONNECT_VERSION`), the environment (`hosted` when
a signed config is served, otherwise `self-hosted`, or
`CONNECT_SENTRY_ENVIRONMENT`), the tags `route`, `request_id` and `error`,
and for an exception its type and stack frames (function, file, line). Never
an exception message, a body, a header, a cookie, a query string or an
install id. Refusals (a wire error code) are never reported.

Reporting never touches a request: at most 4 sends at once, each bounded to
5 seconds, at most 30 events a minute, one per exception type and route. A
failed send is logged once a minute as `sentry.report_failed` at warn.

## Hosted operation

The hosted Connect's platform settings are not in this repository: this
section says what the code allows and requires of a host, and what a
single-container deployment lacks compared with the GCP design the code also
supports.

### Single-container deployment

- **Topology:** one service, one replica, deployed from a released image by
  digest after `gh attestation verify` (see
  [RELEASING.md](../../RELEASING.md#hosted-deploy)). The platform's edge
  terminates TLS. `CONNECT_BINDINGS=file` on a persistent volume mounted at
  `/data`. Firestore and Cloud KMS need the GCP metadata server, so without
  it a second replica is not possible: file bindings refuse a second Connect
  on the same directory.
- **Variables to set** (secrets as sealed or secret variables):
  - `CONNECT_PUBLIC_URL`, `CONNECT_ALLOWED_INSTALLS=*` and
    `CONNECT_SIGNED_CONFIG` (inline: read once at boot, so a new config is a
    redeploy), plus `CONNECT_CONFIG_PUBLIC_KEYS` until a release carries
    `hostedConfigRootKeys`.
  - The lane credentials, `CONNECT_GITHUB_APP_PRIVATE_KEY` included.
  - `CONNECT_SEAL_KEYS`: the seal keyring is a secret variable
    (`cc-connect-config seal-key`), not a KMS key.
  - `CONNECT_STATE=redis` with `CONNECT_REDIS_URL` on a Redis 6.2 or later
    set to `maxmemory-policy noeviction`. `memory` works for the single
    replica but is lost on every deploy: sign-ins in progress are cancelled,
    a disconnect no longer finds the children minted before it, and the
    nonces of the last 5 minutes are forgotten.
  - `CONNECT_DATA_DIR=/data` (the image default) on the volume.
  - `CONNECT_TRUST_PROXY=1`. Verify before relying on it: how the edge
    writes `X-Forwarded-For` (how many hops, and whether it replaces or
    appends a client-sent value) decides whether the per-IP budget sees the
    real client.
  - `CONNECT_LOG_HMAC_KEY`, so log tags survive deploys.
  - `CONNECT_SENTRY_DSN`: without a log drain, Sentry is where errors alert.
  - `CONNECT_VERSION` and `CONNECT_IMAGE_DIGEST` from the release.
- **Health checks:** point the platform's healthcheck at `/readyz`, so a
  deploy whose Redis is unreachable is not promoted. The image's own
  `HEALTHCHECK` stays on `/healthz`.
- **Logs:** Connect writes one JSON object per line with `message` and
  `level`, which most platforms parse as structured logs. Platforms that rate
  limit log lines drop the excess; refusal events are sampled for that
  reason.

What a single-container deployment lacks, compared with the GCP design:

- **No HSM boundary for the seal key.** The keyring is an environment
  variable: anyone who can read the service's variables, or the process's
  memory, can open every seal.
- **The App private key is in an environment variable.** GitHub recommends
  keeping an App's private key in a key vault that only signs; a variable is
  readable in full by anyone with access to it. This is a known gap.
- **No edge WAF.** Only Connect's own per-replica buckets limit traffic.
- **Platform request logs.** Verify before relying on it: whether the
  platform's HTTP logs record query strings. If they do, the `code` and
  `state` of OAuth callbacks reach them; both are single use and expire
  within 10 minutes.

### Facts every operator and organization should know

- An organization that enforces a GitHub IP allow list cannot use the hosted
  Connect: its addresses are not stable or published. Such an organization
  should register its own GitHub App and run its own Connect.
- For the calls only the person can make (listing their installations,
  reading a repository as them), Connect hands a server the person's App user
  token, not a one-repository child. Signing in on a server is trusting that
  server with that token.
- Disconnecting GitHub in Control Center revokes only that server's sign-in.
  To remove Control Center from a GitHub account entirely, revoke it in
  GitHub: **Settings → Applications → Authorized GitHub Apps → Revoke**.

### What remains for organization owners and members

These hold however Connect is configured:

- **A server you sign in on holds your App user token**, for up to 8 hours
  per token and renewed until you disconnect. It can act as you on every
  repository the shared App is installed on that you can reach, in every
  organization. Connect can cut an install off for good (deny list, or the
  install retiring itself), which stops its refreshes and mints, but a token
  already handed out stays valid until it expires.
- **Installing the shared App consents for every Control Center server** a
  member signs in on, not for one server. The consent page tells the person
  that Connect cannot tell who runs the server.
- **The bot is shared** by every server on the Connect (see
  [The shared bot](#the-shared-bot)): an organization cannot tell on GitHub
  which server acted as the bot.
- **Your own GitHub App plus your own Connect is the boundary** for an
  organization that wants one: then only the servers you allow can use the
  App, and the bot is yours alone.

### The GCP design

- Cloud Run service `cc-connect`, autoscaling from 1 to N, behind an External
  HTTPS Load Balancer with Cloud Armor. The `run.app` URL is disabled.
- `CONNECT_STATE=redis` on Memorystore (Redis 6.2 or later, `noeviction`),
  with TLS and `CONNECT_REDIS_CA_FILE`. `CONNECT_BINDINGS=firestore`.
- `CONNECT_SEAL_BACKEND=gcp-kms` on an HSM key in a key-custody project. Only
  the runtime service account has `cloudkms.cryptoKeyEncrypterDecrypter`. A
  5xx or 401 from KMS answers `provider_unavailable`, never `access_denied`,
  so servers keep their seals.
- Secrets from Secret Manager volumes (`*_FILE`), re-read every 30 s.
- Exclude `/oauth/*` from Cloud Run request logs at the Log Router so provider
  codes never reach a log.

### Signed config

- Write a payload and sign it offline with
  `cc-connect-config sign --seed seed --payload payload.json --out signed.json`.
- Set it as `CONNECT_SIGNED_CONFIG` (inline) or mount it as
  `CONNECT_SIGNED_CONFIG_FILE`, together with `CONNECT_ALLOWED_INSTALLS=*`.
- `cc-connect-config keygen --out seed` creates the signing seed. Keep it
  offline. Its public key goes in `hostedConfigRootKeys`; until a release
  carries one, servers report hosted mode as `hosted_unprovisioned`.
- `cc-connect-config verify --key <pub> signed.json` checks a file.
- The full procedure, payload shape and epoch rules are in
  [RELEASING.md](../../RELEASING.md#signing-v1config).

### Rotating a secret (nobody signed out)

1. Create the new secret at the provider, keeping the old one.
2. Move the old value to `NAME_PREVIOUS`, put the new one in `NAME`, and bump
   `CONNECT_<LANE>_SECRET_GENERATION`. Inline variables take a redeploy;
   file mounts are picked up within 30 s.
3. Run a refresh. New seals record the new generation. An `invalid_client`
   during propagation is retried once with the previous secret.
4. Delete the old secret at the provider, then remove `NAME_PREVIOUS`.

The Slack signing secret and the Klipy key rotate the same way, and both
values are accepted during the overlap. To rotate a local seal key, prepend a
new `cc-connect-config seal-key` entry to `CONNECT_SEAL_KEYS`. Keep the old
entry until its seals have been refreshed.

### Incident runbook

Every step is a variable change plus a redeploy, a change at a
provider, or a GitHub setting.

1. **A secret leaked, with no code execution in Connect:** rotate it as
   above, then revoke the old generation at the provider.
2. **One install misbehaves:** add it to `CONNECT_DENY_INSTALLS` and
   redeploy. An install whose key leaked can also retire itself: its owner
   rotates the key, which retires the old id at Connect for good.
3. **Suspected code execution in Connect:**
   1. Take the service's active deployment down, so nothing answers.
   2. Rotate every credential at its provider and in the variables: the
      GitHub client secret, the GitHub App private key (generate a new one in
      the App settings, then delete the old one), the Google, Slack client
      and Slack signing secrets, the Klipy key and `CONNECT_LOG_HMAC_KEY`.
   3. Replace `CONNECT_SEAL_KEYS` with a single new entry. Every existing seal,
      attacker-made ones included, stops opening; people sign in again.
   4. Sign a config at `epoch + 1` with a raised `min_seal_generation` and set
      it as `CONNECT_SIGNED_CONFIG`.
   5. Redeploy a clean, attested release by digest.
   6. Access tokens already handed out stay valid until they expire: an
      hour for installation tokens, eight hours for user tokens. A refresh
      token read from memory cannot be redeemed without the new client
      secret. Tell organization owners which `hashed_token` values Connect
      logged in the window, so they can match them in their GitHub audit log.

On GCP the seal key is a KMS key instead: revoke the runtime service
account's grant first, and destroy the key versions in place of step 3.3.

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
CONNECT_GITHUB_APP_PRIVATE_KEY_FILE=./github_app_key.pem \
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
