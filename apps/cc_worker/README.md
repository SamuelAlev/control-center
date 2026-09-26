# cc_worker

Headless pure-Dart fleet executor. It pairs with `cc_server`, registers capabilities, heartbeats, polls leases and streams process events back. It keeps no durable state; a supervisor restarts it and it re-registers. **This is a subprocess-streaming worker, not an embedded agent runtime or full implementation of every job kind.**

```sh
# from apps/cc_worker, against a paired production server
fvm dart run cc_worker --server wss://host:9030 --device-id my-worker --psk <psk>
# pair on the server first: cc_server pair --data-dir <dir> --device my-worker

# loopback development server without an auth handshake
fvm dart run cc_worker --server ws://localhost:9030

# native bundle
fvm dart build cli
```

`--server` is required and accepts `ws://`/`wss://` (HTTP(S) and a missing `/rpc` are coerced). `--name` defaults to the host name; `--device-id` defaults to `cc-worker` and doubles as the worker ID. `--psk` is required except against a loopback development server without authentication. `CC_WORKER_CACHE` overrides the default temp-directory `cc_worker_cache` materialization cache.

The worker calls `fleet.registerWorker` (aborting on `compatible: false`), heartbeats every 20 seconds and polls every 2 seconds. New leases start jobs and `cancelledJobId` cancels running ones. It flushes `WorkerEventFrame` batches every 250 ms or 32 events, then reports `DoneEvent` and `fleet.workerComplete`.

A `repoRemote` lease uses a remote+SHA-keyed cache: `git clone --depth 1`, then guarded `git fetch`/`git checkout <headSha>` when supplied. An `agentRun` lease executes `env['CC_JOB_COMMAND']` as a **shell command line** (`/bin/sh -c` or Windows `cmd.exe /c`) in the work directory, streaming stdout/stderr as text/error events. Without that variable it **only echoes the prompt**; no agent loop runs. `pipelineStep`, `codeIndex`, `goldenRender`, `benchmark` and `evalBatch` only probe with `git rev-parse HEAD` in a work directory or `git --version` without one. Do not treat a successful probe as completion of those workloads. Short-lived lease credentials in `env` go to subprocesses and are not logged. See [ARCH.md](../../ARCH.md) for the wider fleet architecture.
