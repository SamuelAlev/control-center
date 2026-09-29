# Control Center

Control Center coordinates coding agents across workspaces and repositories. It provides conversations, isolated worktrees, run logs, ticket and PR review, and pipelines through a Flutter desktop/web client backed by `cc_server`. Agents can use the built-in runtime or a configured external runner.

[Live demo](https://demo.usectrl.dev/#eyJzZXJ2ZXIiOiJ3c3M6Ly9kZW1vLWFwaS51c2VjdHJsLmRldi9ycGMiLCJpbnZpdGUiOiJkZW1vIn0) · [Manual](https://usectrl.dev/manual) · [Quick start](https://usectrl.dev/manual/quick-start/) · [Releases](https://github.com/SamuelAlev/control-center/releases/latest) · [MIT license](LICENSE)

## Install

Download the [latest release](https://github.com/SamuelAlev/control-center/releases/latest): a macOS DMG, Windows installer/portable zip, Linux AppImage/tarball and standalone `cc_server` archives. For browser access, open [app.usectrl.dev](https://app.usectrl.dev) and connect to your own server at `ws://localhost:9030` or a remotely reachable `wss://` endpoint; see [headless server setup](https://usectrl.dev/manual/guides/run-headless-server/). The browser cannot host `cc_server` itself.

Before using agents, install Git, configure a model-provider API key for the built-in runtime or an available agent CLI, and connect GitHub through the app. Server-side credentials are not stored in browser or phone clients. See the [quick start](https://usectrl.dev/manual/quick-start/) for setup and first dispatch.

## Build from source

Install [fvm](https://fvm.app) and the Flutter SDK pinned by `.fvmrc`; enable the desktop target for your OS. Native libraries are mandatory: a missing library prevents `cc_server` from booting.

```bash
scripts/natives/build_natives.sh
fvm flutter pub get
fvm flutter pub run build_runner build --delete-conflicting-outputs
fvm flutter gen-l10n
fvm flutter run -d macos   # or windows, linux
```

On Windows, build natives with `scripts/release/windows_natives.sh` instead; see [RELEASING.md](RELEASING.md) for platform prerequisites and packaging. On macOS, persisting client pairing keys requires an Apple-team-signed development app (a free Apple ID works). Follow [local development signing](RELEASING.md#local-development-signing-macos); the app can otherwise launch without secure storage.

## How it works

A workspace scopes agents, registered repositories, spaces and memory. Mention an agent in a space to dispatch a run against an isolated branch/worktree, then inspect its output and review its PR. Conversations have `chat`, `plan`, `review` or `orchestrate` modes that constrain prompts and permitted actions. Desktop and web clients use server RPC; the server also exposes tools over MCP. For domain terms and isolation rules, see [GLOSSARY.md](GLOSSARY.md) and [SECURITY.md](SECURITY.md).

## Documentation

- [Manual](https://usectrl.dev/manual): installation, operation and product guides.
- [ARCH.md](ARCH.md): architecture, runtime/data flow and subsystem constraints.
- [GLOSSARY.md](GLOSSARY.md): domain vocabulary and distinctions.
- [RELEASING.md](RELEASING.md): release procedure, signing and verification.
- [AGENTS.md](AGENTS.md): contributor conventions and commands.
