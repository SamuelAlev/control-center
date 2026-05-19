# cc_worker

Headless fleet executor for Control Center. A pure-Dart binary that pairs with a `cc_server`, declares its
capabilities, heartbeats, pulls leased jobs, executes them and streams process
events back over the fleet lease protocol. It holds **no durable state** — a
supervisor restarts it and it re-registers.

## Run

```bash
# Against a paired server (production): the device id + PSK come from
# `cc_server pair --data-dir <dir> --device <worker-id>` (or the desktop
# pairing UI).
dart run cc_worker --server wss://host:9030 --device-id my-worker --psk <psk>

# Against a loopback dev server with no auth handshake:
dart run cc_worker --server ws://localhost:9030
```

Build a self-contained binary the same way as `cc_server`:

```bash
cd apps/cc_worker && dart build cli
```

## Flags

| Flag               | Description                                                                                      | Default     |
| ------------------ | ------------------------------------------------------------------------------------------------ | ----------- |
| `--server <url>`   | cc_server URL (`ws://`/`wss://`; `http(s)` and a missing `/rpc` path are coerced). **Required.** | —           |
| `--name <name>`    | Operator-facing worker name.                                                                     | host name   |
| `--device-id <id>` | Stable paired-device id, also used as the worker id.                                             | `cc-worker` |
| `--psk <key>`      | Paired-device pre-shared key. Omit only for a loopback dev server.                               | —           |

`CC_WORKER_CACHE` overrides the worktree materialization cache dir (default: a
`cc_worker_cache` dir under the system temp dir).

## Protocol loop

`fleet.registerWorker` (aborts if the server reports `compatible: false`) →
`fleet.workerHeartbeat` every 20s → `fleet.workerPoll` every 2s. New leases are
executed; each new `cancelledJobId` cancels its running job. Events are batched
into `WorkerEventFrame`s and flushed via `fleet.workerEvents` (every 250ms or
every 32 events); the job ends with a `DoneEvent` and a `fleet.workerComplete`
report.

## Execution (what is real vs. stubbed)

Execution is a **real subprocess-streaming implementation**, not a full embedded
harness:

- **Materialization**: if a lease carries `repoRemote`, the worker
  `git clone --depth 1` into a remote+SHA-keyed cache dir, then `git fetch` +
  `git checkout <headSha>` (best-effort; guarded), emitting a `materialized …`
  debug event.
- **`agentRun`**: if the lease `env` contains `CC_JOB_COMMAND`, it runs via a
  subprocess in the work dir — stdout → `TextEvent`, stderr → `ErrorEvent`.
  Otherwise it echoes the prompt from the spec so the transport is still
  exercised end to end. **Stubbed:** there is no embedded agent runtime; wiring
  the real agent loop is future work.
- **`benchmark` / `codeIndex` / other kinds**: run a small real command
  (`git rev-parse HEAD`, or `git --version` with no work dir) and stream its
  output. These are honest probes, not full implementations of those kinds.

The lease `env` (short-lived, job-scoped credentials) is injected into every
subprocess and is **never written to a log**.
