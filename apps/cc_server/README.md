# cc_server

Control Center as a **headless server** — a **pure-Dart native binary** (no
Flutter engine). It owns the data layer (the `cc_persistence` Drift/SQLite
database) and serves the repo-RPC catalog (tickets / messaging / newsfeed) over
a WebSocket `LocalRpcServer`.

Paired phones (`cc_remote`), the full **web build** and (Fork A) the desktop
all connect here over `ws://<host>:<port>/rpc`.

## Dependencies

`cc_server` depends **only** on `cc_server_core` (→ `cc_host` + `cc_persistence`

- `cc_domain` + `cc_rpc`). It does **not** depend on `flutter` or the
  `control_center` app package — so it compiles to a self-contained native
  executable.

## Build & run

`sqlite3` uses native-asset build hooks, so build with **`dart build cli`**. The bundle ships `libsqlite3` alongside the binary — no system sqlite or Flutter engine needed.

The other runtime natives (rift / fff / ccpty / tree-sitter + grammars / lame /
sherpa-onnx / onnxruntime) travel the SAME way: `hook/build.dart` re-emits
whatever is staged in `<repo>/build/natives/` (override with
the repo-root `.cc_natives_prebuilt_dir` pointer file) as `DynamicLoadingBundled` code assets and
`dart build cli` drops them into `<bundle>/lib/` beside `libsqlite3`. Stage them
once before building:

```sh
# from the repo root — builds every native into build/natives
# (rift, fff, tree-sitter + grammars, aec, lame, pty, cc_watcher, cc_inference)
scripts/natives/build_natives.sh
```

The natives are **required**: the server refuses to boot when any of
fff / pty / tree-sitter / cc_inference is missing (no degraded mode). The only
runtime downloads are the on-device **models** (embedding + diarization are
force-installed at boot into `<data-dir>/models`; the ASR voice model stays
opt-in) and code-server.

```sh
# from apps/cc_server (use the repo's pinned SDK):
dart build cli
./build/cli/<os_arch>/bundle/bin/cc_server --data-dir ./data --port 9030
```

Config (CLI flag overrides env, env overrides default):

| Flag         | Env                  | Default                              | Meaning                                                                                     |
| ------------ | -------------------- | ------------------------------------ | ------------------------------------------------------------------------------------------- |
| `--data-dir` | `CC_SERVER_DATA_DIR` | the OS per-user application-data dir | `global.db` + one `<workspaceId>/workspace.db` per workspace, paired-device secrets, models |
| `--port`     | `CC_SERVER_PORT`     | `9030`                               | TCP port (`0` = ephemeral)                                                                  |
| `--bind`     | `CC_SERVER_BIND`     | `loopback`                           | `loopback` or `any` (`any` requires TLS)                                                    |

## Pair a thin client

A fresh `--data-dir` has no workspace, no `paired_devices` row and no PSK, so
the server has nothing to authenticate against and a thin client's "pairing key"
prompt can't be satisfied. Provision one with the `pair` subcommand **before**
starting the server (it opens the DB directly, so the server must not be running
yet):

```sh
# mint a key for the web client (default device id `web-client`)
cc_server pair --data-dir ./data --port 9030

# …and print a QR a phone can scan to open the deployed web client and connect
cc_server pair --data-dir ./data --port 9030 \
  --bind any --host 192.168.1.42 --client-url https://your-web-app.example
```

`pair` mints a PSK, upserts an
`active` device, writes the PSK to `<data-dir>/secrets.json` and
prints the `Server` / `Device id` / `Pairing key` to paste into the web client's
connect form. With `--client-url` it also prints the deep link
(`<client-url>/#<base64url{s,i,k}>`) as a terminal-scannable QR. Flags:
`--device` (default `web-client`), `--label`, `--host`
(the host in the printed URL — loopback isn't reachable from a phone; pass the
LAN IP), `--client-url` (the web build's origin). Re-running rotates the PSK.

> **Scope.** `pair` provisions the **WebSocket-RPC** path used by the web build
> (and any thin client that dials `…/rpc`) and emits a **v1** deep link. The
> phone **Remote** app (`apps/cc_remote`) pairs with a different **v2**
> `PairingPayload` minted from the app's pairing panel, carrying a full
> `ConnectionDescriptor`. The two are not interchangeable.
>
> The phone is **not** WebRTC and does not pair against a running desktop: it
> reaches this server over the best available path (loopback, LAN, tailnet,
> `wss://`), falling back to a relay room this server owns on the signaling
> broker, which forwards only end-to-end-sealed frames. `flutter_webrtc` is
> still a pubspec dependency but no Dart file imports it and the broker's TURN
> credential minting has no consumer.

Then start the server and point the client at `ws://localhost:9030/rpc`.

## Current scope

`cc_server` is the whole product surface, not a subset: the thin-client data
path (`initialize`, `session/*`, `repo/call`, `sub/*` reactive subscriptions),
the MCP tool endpoint on the same port, inbound webhooks, the media and font
proxies, single sign-on callbacks, the fleet lease protocol, server-side RSS
fetching on a schedule and vector search.

The dispatcher is **stateless** — there is no per-session workspace binding.
Every workspace-scoped call carries its own `workspace_id` and access is
decided by the caller's workspace membership and role, not by holding a PSK.

The three gaps this section used to list are all closed: MCP `tools/call` is
served (there is no `NoToolsRpcDispatcher` in the wiring), RSS fetching runs
server-side on a schedule and `sqlite_vector` is registered as a process-global
auto-extension for every connection.
