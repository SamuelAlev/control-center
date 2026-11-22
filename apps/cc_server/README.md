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

CMake must be on `PATH` for the Web Crypto native build hook. Apply repository patches after every pub get. The CLI bundle includes `libwebcrypto` for VAPID signing and Web Push encryption, not a second inference runtime.

The server refuses to boot without required natives; on Windows, `rift` (Windows uses `git worktree`) and, for now, `cc_window` are exempt (`scripts/lib/natives.sh`). See [cc_natives](../../packages/cc_natives/README.md) for staging, overrides and compile-only exceptions. On-device embedding, diarization and selected speech models download into `<data-dir>/models` at boot; speech recording operations require a restart after download. Code-server is also downloaded at runtime.

`cc_server agent-run <verb>` is internal: the client an agent run's shims and Claude Code's permission hook start inside the run's sandbox to reach the server's loopback [agent run gateway](../../SECURITY.md#agent-run-gateway). It takes the run's token from its environment and holds no other secret, and it is why nothing in a run depends on `curl`.

CLI flags override environment variables, which override defaults:

| Flag | Environment | Default / use |
| --- | --- | --- |
| `--data-dir` | `CC_SERVER_DATA_DIR` | Per-user application-data dir; `global.db`, per-workspace databases, secrets and models. |
| `--port` | `CC_SERVER_PORT` | `9030`; `0` selects an ephemeral port. |
| `--bind` | `CC_SERVER_BIND` | `loopback`; `any` requires TLS. |
| `--code-mode-max-processes` | `CC_SERVER_CODE_MODE_MAX_PROCESSES` | Runner slots ("scripts at once" in the startup line): scripts that hold one run and start tools; `min(16, 2 × cores)` by default; 1 to 64. From 2 up, one workspace gets at most this less a quarter of it (at least one less), so no one workspace takes them all, though two busy workspaces can together leave a third none until one frees. Up to four times as many runners may be parked on a person besides, one workspace at most three quarters of them: they start no tool until the person answers and they hold a slot again, but they can still compute within their CPU budget. |
| `--code-mode-max-heap-mb` | `CC_SERVER_CODE_MODE_MAX_HEAP_MB` | `1024`; the most heap one script may use, 16 to 1024 MiB. A workspace's higher heap limit is lowered to it. |

A value either code mode flag does not accept (a number out of range, or not a number) stops the server at start with a message naming the accepted values; it is never read as the default. Any other flag the server does not know is ignored. A refused value or a path is printed with its controls, format characters, separators and non-ASCII spaces as code points (letters outside ASCII kept), at most 80 characters of a value, 300 of an operating system error or a finding and 1,024 of a path, with secrets redacted before the cut.

At start the server runs the code mode runner's lockdown self-test and prints one line with the result before it accepts a run (at the default log level; `--log-level error` silences it). A runner whose self-test does not report a release build (a debug build, or one that does not say) is `unavailable`, and the version shown is one line of at most 80 printable characters, from a runner that passed:

```text
cc_server: code_mode=available (cc_codemode 0.1.0 quickjs-ng 0.16.2 protocol 2; 16 scripts at once, at most 12 per workspace; up to 64 more runners kept for scripts waiting on a person; heap at most 1024 MiB per script)
cc_server: code_mode=unavailable (<reason>) — runs on this host get no repl tool; scripts never run without full lockdown
```

The worst case these two flags allow: the server keeps up to cap + parked pool = 5 × `--code-mode-max-processes` runners alive (80 at the default cap of 16), each with up to `--code-mode-max-heap-mb` of interpreter heap (80 GiB at the defaults: the 1024 MiB default clamps nothing), each computing on one thread within its CPU budget, all at once in the worst case (a parked runner starts no tool but is not paused). On its own heap the server holds, per runner, counted in memory rather than as JSON: at most 64 MiB of replies the runner has not read; its unanswered call arguments, weighed by what they take decoded, up to 64 MiB plus one call of at most 7.5 MiB (a call's arguments are at most 1 MiB and 16,384 values); the results of its calls in flight while it waits for a slot, kept as JSON bytes (32 MiB at the default limits); its call rows without their results (about 10 MiB at 500 calls); up to 24 Mi characters of output (about 100 MiB at four bytes a character); about 6 MiB of store writes; under 2 MiB of question records and 1 MiB of the loop's call record; and the transcript rows of its calls while the turn streams (8 KiB of arguments and 8 KiB of result per call, 256 KiB per script: at most 1.6 MiB at 500 calls, 11 MiB at 5,000). That is about 290 MiB per runner at the default workspace limits and 480 MiB at their ceilings, so about 23 GiB and 37.5 GiB across 80 runners, plus one frame being decoded at a time per isolate (at most 32 MiB) and a tool's JSON text result being decoded for its script, one at a time per isolate (at most about 60 MiB). These are live bounds; the process's resident size can sit above them until the collector runs (about 200 MiB above the baseline while one script settled 500 results just under the item limit). A runner parked on a person lives at most its wall clock plus 10 approval cards × 1 hour plus 10 questions × 30 minutes, 15 h 25 min at the 1,500 s wall-clock ceiling. Size both flags to the host; the workspace limits bound the rest of the server-heap figure.

The runner is found beside the executable (`bin/codemode/`), under `CC_NATIVE_LIB_DIR`, under the data directory, or at `CC_CODEMODE_RUNNER`; both variables count only when exported to the process, never from `.env` (the data directory itself may come from `.env`). Records of scripts a stopped server left running are finished as `server_stopped` once a new server holds its port, with one log line saying how many. No script is admitted into a workspace before its records were swept; one whose sweep failed is swept again for each script that arrives, which is refused until a sweep succeeds (the failure is logged once). Nothing stops two servers on one data directory; one on another port finishes the first one's running scripts that way.

`unavailable` means the runner is in the bundle but cannot confine itself on this host (a container profile that refuses a seccomp or rlimit step, for example). The server still starts; no run there gets `repl`, and Settings → Workspace → Code mode shows the reason. A bundle without the runner does not start at all: like any missing required native library, it is one line naming what is missing and where it was looked for, and exit code 78. The check comes before the server opens, creates or migrates any database or writes anything in the data directory (it may have created the directory itself, empty and owner-only), so a refused start leaves the data directory's contents as they were. A data directory that cannot be created or is not a directory is refused the same way, and any other error the boot raises before the server is ready ends it with one line (secrets redacted, at most 300 characters of the error) and exit code 70 (a port already in use with exit code 1), the stack going to the log file when one is open. An error raised outside the boot's own awaits (in a timer or a callback the boot started) is logged and does not end the process. `pair` and `connect` check before any database too and refuse the same way; `update` does not look for native libraries and runs as usual.

A runner that does not speak the server's protocol (2) is refused at the self-test and code mode is `unavailable` until the natives are rebuilt (`scripts/natives/build_natives.sh`, then `scripts/build_server.sh`).

Beside the ready banner the server prints one line saying where the boot went (`boot took 93ms (loading harness model catalog 54ms), 124 MB resident, up from 63 MB when boot began (…)`), and 90 seconds and 10 minutes later what it holds: resident memory, its peak, and each open workspace database with what keeps it open. All three print at the default log level; `--log-level info` adds every boot phase.

Run the server with `DART_VM_OPTIONS=--new_gen_semi_max_size=8`. The desktop app and the container image set it; a server started by hand or from a service unit takes it from you. Without it the Dart VM grows its young generation to two 16 MB halves and keeps them, some 25 MB more than an idle server needs (150 to 157 MB against 127 MB written, measured with two workspaces). The variable is read by the executable itself, before `main`, so it cannot come from `.env`.

Provider secrets (`GITHUB_APP_PRIVATE_KEY`, `GITHUB_CLIENT_SECRET`, `GOOGLE_OAUTH_CLIENT_SECRET`, `LINEAR_API_KEY`, any `SLACK_*SECRET*`) come from a `.env` file or Settings, never the exported environment: the server refuses to boot when one is exported. It reads `.env` from its working directory, beside the executable, or a source checkout above it (copy [`.env.template`](../../.env.template)). In Docker, mount the file at `/app/bin/.env` (`-v /secure/cc.env:/app/bin/.env:ro`) instead of passing `-e` or `--env-file`.

## Agent shell hooks

The server owner may give an agent shell hooks in `<data dir>/_agent_hooks/<workspace id>/<agent slug>/hooks.json`, by hand on the server's machine; nothing in a client writes it. The file maps five keys to scripts by paths relative to that folder: `sessionStart`, `preTool`, `postTool`, `stop` (exit 2 with text keeps the run going, at most 3 times a run; anything else ends the turn) and `preCompact` (its stdout, up to 1,000 characters, is added to the compaction's focus). `stop` and `preCompact` also run for Claude Code runs, through the run gateway; the other three apply to the built-in harness only. What each receives and its limits: the manual's [agent configuration reference](../../docs/src/content/docs/manual/reference/agent-configuration.mdx#shell-hooks); what a hook can reach: [SECURITY.md](../../SECURITY.md#sandboxes-and-rigs).

## Pair a web client

On a new data dir, pair **before** starting the server; `pair` opens the database directly and must not run alongside it:

```sh
# from apps/cc_server, after building
./build/cli/<os_arch>/bundle/bin/cc_server pair --data-dir ./data --port 9030
./build/cli/<os_arch>/bundle/bin/cc_server pair --data-dir ./data --port 9030 \
  --bind any --host 192.168.1.42 --client-url https://your-client.example
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
