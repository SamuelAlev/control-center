# cc_server

Headless pure-Dart server with the `cc_persistence` Drift/SQLite database and repo-RPC catalog, reachable at `ws://<host>:<port>/rpc`. Desktop and thin web/phone clients connect here. The server depends on `cc_server_core`, not Flutter or the root app. [ARCH.md](../../ARCH.md) describes the shared runtime and persistence; [SECURITY.md](../../SECURITY.md) covers network and credential boundaries.

## Build and run

```sh
# from the repo root; stage all required runtime natives first
scripts/natives/build_natives.sh
cd apps/cc_server
../../scripts/build_server.sh
./build/cli/<os_arch>/bundle/bin/cc_server --data-dir ./data --port 9030
```

Use `scripts/build_server.sh` rather than raw `dart build cli` or `dart compile`. It runs the CLI build with the repo-pinned SDK, then stages and verifies the complete managed media directory under `<bundle>/bin/media/`; the Dart build hooks bundle `libsqlite3` and staged FFI libraries under `<bundle>/lib/`. The resulting bundle works with any `--data-dir`, without `CC_MEDIA_TOOLS_DIR`. Raw `dart build cli` alone does not bundle the media executables, fonts or licenses. On Windows ARM64, run `scripts/build_server.sh cc_server arm64` from Git Bash.

CMake must be on `PATH` for the Web Crypto native build hook. The tracked `native_toolchain_cmake` patch supports the pinned Dart SDK; apply repository patches after every pub get. The CLI bundle includes `libwebcrypto` for VAPID signing and Web Push encryption, not a second inference runtime.

The server refuses to boot without required natives; rift is exempt only on Windows, which uses `git worktree`. See [cc_natives](../../packages/cc_natives/README.md) for staging, overrides and compile-only exceptions. On-device embedding, diarization and selected speech models download into `<data-dir>/models` at boot; speech recording operations require a restart after download. Code-server is also downloaded at runtime.

CLI flags override environment variables, which override defaults:

| Flag | Environment | Default / use |
| --- | --- | --- |
| `--data-dir` | `CC_SERVER_DATA_DIR` | Per-user application-data dir; `global.db`, per-workspace databases, secrets and models. |
| `--port` | `CC_SERVER_PORT` | `9030`; `0` selects an ephemeral port. |
| `--bind` | `CC_SERVER_BIND` | `loopback`; `any` requires TLS. |

## Pair a web client

On a new data dir, pair **before** starting the server; `pair` opens the database directly and must not run alongside it:

```sh
# from apps/cc_server, after building
./build/cli/<os_arch>/bundle/bin/cc_server pair --data-dir ./data --port 9030
./build/cli/<os_arch>/bundle/bin/cc_server pair --data-dir ./data --port 9030 \
  --bind any --host 192.168.1.42 --client-url https://your-web-app.example
```

`pair` upserts an active device, mints a PSK, writes it to `<data-dir>/secrets.json` and prints the server address, device ID and key. With `--client-url`, it also prints a QR/deep link for the web client. `--device` defaults to `web-client`; `--label` and `--host` control the display name and reachable URL. Re-pairing rotates the PSK. The printed **v1** link pairs WebSocket-RPC web clients; the phone app requires a separate **v2** `PairingPayload` from the first-party pairing panel, including its full connection descriptor. Do not use the CLI's v1 QR for `cc_remote`.

After pairing, start the server and connect a web client to `ws://localhost:9030/rpc`. The server also serves MCP tools, webhooks, proxies, scheduled RSS and vector search. Each workspace-scoped RPC call must carry `workspace_id`; access depends on membership and role, not merely possession of a PSK.

## Encrypted client sessions

First-party clients use the signed-identity Noise protocol on both direct
WebSockets and the relay. Sensitive HTTP/binary routes return `426` on the
public listener and are available through the encrypted resource tunnel,
preserving their workspace/role/signature checks.

The trusted browser editor runs on the web app's own origin. Its Service Worker
passes HTTP and WebSocket requests through the authenticated encrypted session.
`cc_server` decrypts those requests, forwards them to its local code-server
backend, and encrypts the responses. Files and execution remain on the server.
Web clients need HTTPS or secure loopback for Service Workers; their build
scripts package the shared resource assets. Native clients use a
capability-scoped loopback facade.

The server-launched code-server extension receives a separate private loopback
report/command URL. Never expose it through a public reverse proxy.
See [SECURITY.md](../../SECURITY.md#network-boundaries) for metadata visibility,
bootstrap trust and the boundaries this transport encryption does not cover.

## Browser push alerts

The phone's `push.status`, `push.register` and `push.remove` operations target only the authenticated active device. VAPID key material and subscription secrets are stored in the owner-private secrets store. No additional push API key is required; delivery uses the browser's allowlisted HTTPS push endpoint.

Alerts originate from persisted notification-feed entries, recheck current recipient/workspace/repository visibility before external delivery, and never include message text or commands. Device revocation and unpairing remove registrations. Endpoint validation, public-address DNS pinning and redirect refusal are described in [SECURITY.md](../../SECURITY.md#browser-push-alerts).
