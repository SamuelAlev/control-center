# cc_remote

Phone web PWA for server-owned operations over JSON-RPC. Persistence, forge API calls and agent execution stay on the server. [`cc_rpc`](../../packages/cc_rpc/README.md) resolves a v2 `ConnectionDescriptor` across reachable paths (LAN, tailnet, WSS or broker relay), handles PSK authentication and TOFU identity verification, and maintains one resilient RPC client whose subscriptions re-register with fresh snapshots after reconnect. In a browser, only TLS-compatible paths and the relay are usable. [`cc_data`](../../packages/cc_data/README.md) supplies the remote repository adapters.

```sh
# from apps/cc_remote
fvm flutter build web --release --wasm --enable-wasm-deferred-loading
node ../../tool/stage_resource_assets.mjs build/web
```

Run `fvm flutter test --concurrency=2` for the VM suite, including filesystem boundary checks. Run the browser surfaces separately:

```sh
fvm flutter test --platform chrome --concurrency=2 \
  test/remote_conversation_route_test.dart test/pairing_lifecycle_test.dart \
  test/diff_view_test.dart test/approval_surface_test.dart \
  test/conversation_drafts_test.dart test/attachment_upload_test.dart \
  test/conversation_progress_model_test.dart test/pr_review_threads_test.dart \
  test/media_proxy_test.dart test/space_folders_widget_test.dart \
  test/space_folders_test.dart test/live_turns_test.dart \
  test/remote_feed_window_test.dart test/remote_locales_test.dart \
  test/rtl_locale_test.dart test/bottom_tabs_test.dart \
  test/agent_transcript_test.dart test/sent_attachments_test.dart \
  test/push_browser_test.dart test/settings_language_test.dart
```

The filesystem checks in `material_free_test.dart` cannot run on Chrome. Chrome currently ignores the concurrency option; retain the package cap in commands.

Deploy `build/web` to Cloudflare Pages using `wrangler.jsonc` (SPA fallback). HTTPS is required for service workers and IndexedDB. The server-side pairing panel encodes the deployed PWA URL into its QR link. This app imports only web-safe `cc_ui`, `cc_domain`, `cc_rpc` and `cc_data`, never the root `control_center` app, `dart:io` or native plugins. It uses `WidgetsApp.router`, `CcTheme` and go_router, not Material widgets; `lib/app_icons.dart` avoids the large icon class that overflows web DDC.

Presentation files keep the standard 250-line screen and 300-line widget
budgets. Adjacent same-library parts hold private rendering, form and action
helpers without moving state ownership out of the screen or widget. Run
`fvm flutter test test/tooling/remote_size_budget_ratchet_test.dart --concurrency=1`
from the repository root when splitting these files; do not raise the baseline.

## Pairing and session

`lib/pairing/pairing_store.dart` reads the v2 fragment payload (`{v:2, d:descriptor, i:deviceId, k:psk, x:expiry}`) and strips the secret-bearing fragment before presenting a new trust decision. A new or changed pairing **requires explicit confirmation** of the server; a forged fragment must not auto-pair. Reopening an offer matching the saved server ID, device ID, PSK and verified fingerprint resumes the saved pairing instead, using its stored descriptor and pin rather than adopting paths from the offer. This also permits reopening an expired copy of an already-trusted offer. New expired offers are not accepted.

The device credential, descriptor and TOFU fingerprint persist in IndexedDB. `lib/app_connection.dart` manages connecting, retry, unpairing and active workspace state. A handshake fingerprint mismatch is terminal: remove the pairing and re-scan, never continue past it. Reconnection refreshes the descriptor for changed network paths. The `cc_server pair` CLI prints a different v1 web-client link, **not** a phone v2 pairing payload. See [SECURITY.md](../../SECURITY.md) for shared trust rules.

## Phone-specific behavior

Bottom tabs are Inbox, Tickets, Chat, PRs, Calendar and News. All six fit a 320 px phone in LTR and RTL while retaining at least 44 px tap targets. Workspace and space actions expose the additional operations without adding more bottom tabs.

| Surface | Mobile operations |
| --- | --- |
| Inbox and Activity | Independent approval, live question and credential-block discovery; durable notification history with read/unread and dismiss state; exact space/conversation navigation. PR loading failures do not block requests. |
| Spaces | Search and folders; create, rename, archive and reopen; manage people, agents and linked repositories; choose creation-time branches; inspect or change supported modes and admin-controlled autonomy overrides; inspect activity, unread state and live question attention without treating unanswered history as a current request. |
| Conversations | Browse active and archived conversations and threads; create, rename, archive and restore; search and page history; copy exact workspace/conversation/message links; retain scoped text and attachment drafts; send or steer queued work. |
| Progress | Conversation goals and editable TODOs; current runs and costs; available context, outputs and changes; stop/retry and capability-gated pause/resume; inspect, edit and remove queued steering. |
| Permissions | Effective workspace/agent/space action decisions, remembered-grant expiry and recent audit history; workspace-admin policy editing and chain verification. Mobile controls do not bypass server policy. |
| PRs | Review decisions, bounded full-file diffs, inline comments, thread replies and resolve/reopen actions. Unified diffs reuse `cc_domain`'s parser, stay collapsed by default and respect `kDiffRowBudget`. Compact source rows scroll horizontally with a visible scrollbar; a separate touch-sized selector chooses changed lines for comments without inflating code spacing. |
| Tickets | Create native tickets; search/filter; edit ticket fields, status, priority and assignment. Forge/tracker actions still require the configured server integration and the caller's authority. |
| Plans and goals | Review plan revisions and selected steps, approve and run through existing guarded operations, widen supported review scopes, inspect organizational goals and control supervised goal runs within server-enforced budgets. |
| Settings | Theme and a single language select, including system language and RTL locales; personal provider connections, server-owner harness credentials, notification preferences, browser push, quiet mode and category selection. Secrets remain server-side; unsupported host-only login methods are not emulated. |

Calendar remains an agenda, not a desktop grid. The phone does not host terminals, sandboxes, a database or a second agent runtime.

Drafts are session-memory state keyed by workspace, space and conversation. They survive navigation and transport reconnects but not a tab reload, forgetting the server or changing the pairing. Failed uploads keep their picked bytes for retry/remove; sending waits for durable catalog `file_id` and blob references. An ambiguous send retry keeps its original idempotency key and send-versus-queue decision instead of silently changing the operation.

Sent image attachments load their signed blob bytes directly through the encrypted resource channel, scoped to the message's workspace rather than the active workspace. Thumbnails expand into the shared zoomable image viewer; failed loads offer Retry. File attachments retain signed download links.

Transcript tool rows show localized names for Control Center tools and readable names for external MCP tools. Expanded details retain the exact selectable protocol identifier; display names never change tool dispatch or permission keys.

Agent approvals use server-provided intent and risk text. The Chat thread shows only the oldest pending approval inline, with a waiting count for the rest; the Inbox keeps every pending request accessible. Both bound long explanations and full Bash scripts in a scrollable body with a visible scrollbar while leaving decisions visible. Scripts render as LTR code regardless of locale, preserve line boundaries with horizontal scrolling, and have a one-tap Copy command action that copies the exact source, including blank lines and trailing newlines.

The authenticated direct or relay session also supplies a local encrypted resource facade, so attachments, media and fonts do not require a reachable remote HTTP origin. Workspace logos retain their bounded `workspace.logo` RPC/session cache. Every workspace-scoped stream must pass `workspace_id` explicitly **and** watch `activeWorkspaceIdProvider`: otherwise a subscription re-registers with its old captured workspace after switching. Phone-local presentation code (scroll-to-latest, avatars, transcript rows, markdown wiring and formatting) stays local; diff parsing is shared. The shared worker/bridge/shim assets are linked from the root `web/` directory, not maintained as a separate implementation. See [ARCH.md](../../ARCH.md) for the cross-client data flow.

## Background alerts

Push registration is an explicit user action in Settings, requires a secure browser context and a supported Push API, and is bound to the authenticated paired device. An undecided (`default`) permission is requested directly from the Enable tap, before awaiting worker setup or RPC. Granted permission does not re-prompt. A browser-reported denial can come from site, browser or device policy without a previous site prompt; change those settings, then use Refresh or return to the app to recheck. The app cannot override a browser denial. iOS requires a supported installed home-screen PWA. Unsupported or denied subscriptions are never reported as enabled.

The server persists its VAPID identity and subscriptions, encrypts Web Push payloads and sends only generic alerts with scoped navigation identifiers. Opening an alert still passes normal workspace and repository authorization. Disabling alerts or forgetting the server removes the device registration; server-side device revocation also removes it. A live push provider and OS permission are needed for actual background delivery. See [server push boundaries](../../SECURITY.md#browser-push-alerts).
