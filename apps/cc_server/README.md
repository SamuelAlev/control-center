# cc_server

Headless pure-Dart server with the `cc_persistence` Drift/SQLite database and repo-RPC catalog, reachable at `ws://<host>:<port>/rpc`. Desktop and thin web/phone clients connect here. The server depends on `cc_server_core`, not Flutter or the root app. [ARCH.md](../../ARCH.md) describes the shared runtime and persistence; [SECURITY.md](../../SECURITY.md) covers network and credential boundaries.

## Build and run

```sh
# from the repo root; stage all required runtime natives first
scripts/natives/build_natives.sh
cd apps/cc_server
fvm dart build cli
./build/cli/<os_arch>/bundle/bin/cc_server --data-dir ./data --port 9030
```

Use `fvm dart build cli` rather than `dart compile`: the build hooks bundle `libsqlite3` and staged FFI libraries under `<bundle>/lib/`. The server refuses to boot without required natives; rift is exempt only on Windows, which uses `git worktree`. See [cc_natives](../../packages/cc_natives/README.md) for staging, overrides and compile-only exceptions. On-device embedding, diarization and selected speech models download into `<data-dir>/models` at boot; speech recording operations require a restart after download. Code-server is also downloaded at runtime.

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
