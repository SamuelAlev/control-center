# cc_signaling_server

A pure-Dart, **stateless** WebSocket relay broker for Control Center. Drop this
single binary on a reachable host and run it — a `cc_server` owns a room here,
and clients that cannot reach it directly (a phone behind NAT, a browser on
another network) join that room and exchange **end-to-end-sealed** JSON-RPC
frames through it.

It is a **dumb relay**. It holds no application data, never sees the pairing
pre-shared key, never persists anything and never interprets a payload —
`signal` bodies are forwarded verbatim, byte-for-byte. It verifies _admission_
(that a joiner holds a valid invite) and nothing else.

> Direct paths are always preferred: a client uses loopback, LAN, tailnet or
> `wss://` when one is reachable and only falls back to this relay when none
> is. The relay is a fallback transport, not the normal one.

## Run

```sh
dart run bin/server.dart --port 8788
# listening on 0.0.0.0:8788
```

Flags (all optional):

| Flag          | Default   | Meaning                                           |
| ------------- | --------- | ------------------------------------------------- |
| `--host`      | `0.0.0.0` | Network interface to bind.                        |
| `--port`      | `8788`    | TCP port (`0` picks an ephemeral port).           |
| `--max-peers` | `16`      | Peers per room (2–256): one owner plus N clients. |

Two environment variables enable optional TURN credential minting:
`CC_TURN_SECRET` and `CC_TURN_URIS` (comma-separated). Nothing in the product
consumes these yet.

## Compile to a native binary

```sh
dart compile exe bin/server.dart -o signaling-server
./signaling-server --host 0.0.0.0 --port 8788
```

The resulting `signaling-server` is a standalone executable with no Dart SDK
required on the target host.

## Run in Docker

Build and run the AOT-compiled binary in a minimal, non-root container:

```sh
docker build -t cc-signaling-server apps/cc_signaling_server/
docker run --rm -p 8788:8788 cc-signaling-server
# listening on 0.0.0.0:8788
```

The image is a two-stage build: a Dart SDK stage compiles `bin/server.dart` to a
self-contained native executable, then ships just that binary in a
`debian:bookworm-slim` runtime. Configure the bind interface and port with
environment variables (no Flutter SDK or network needed at build time):

```sh
docker run --rm -p 9000:9000 -e SIGNALING_HOST=0.0.0.0 -e SIGNALING_PORT=9000 cc-signaling-server
```

The container runs as an unprivileged user, exposes `8788`, ships a TCP liveness
`HEALTHCHECK` and the binary is PID 1 so `docker stop` triggers its graceful
SIGTERM shutdown.

## Message protocol

Every frame is a JSON object; the broker only inspects `type`.

### Client → broker

| `type`   | Fields                                                      | Effect                                                                                                                                                                       |
| -------- | ----------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `join`   | `room`, `from`, `owner`?, `ownerToken`?, `token`?, `admit`? | Enter a room. The owner (the `cc_server`) joins with `owner: true` and an `ownerToken`; every other peer MUST present a `token` whose SHA-256 is in the room's admitted set. |
| `signal` | `room`, `from`, `to`?, `kind`, `payload`                    | Relay the opaque `payload` to another peer in the room.                                                                                                                      |
| `admit`  | `room`, admission hashes                                    | Owner-only. Publishes or updates the set of admitted token hashes.                                                                                                           |
| `bye`    | `room`                                                      | Leave the room.                                                                                                                                                              |

### Broker → client

| `type`             | Fields      | Sent when…                                                                                                                                                          |
| ------------------ | ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `joined`           | `room`      | Your `join` succeeded (the join ack — it carries **no** `from`).                                                                                                    |
| `peer-joined`      | `room`      | The room is now shared. Emitted **symmetrically to both peers** the instant a second peer joins, so an offerer can fire its offer on this regardless of join order. |
| `peer-left`        | `room`      | The other peer left (disconnect, `bye`, or room garbage collection).                                                                                                |
| `admit-ok`         | `room`      | Your `admit` was applied (owner only).                                                                                                                              |
| `turn-credentials` | credentials | Short-lived TURN credentials, when the broker is configured with `CC_TURN_SECRET`/`CC_TURN_URIS`.                                                                   |
| `error`            | `error`     | Rejection — `not admitted`, `owner conflict`, `room full`, `invalid join`, `already joined`, `not a member`, `not owner`, `server busy`. The socket is then closed. |

### Behavior notes

- **Rooms hold at most `--max-peers` peers (default 16, range 2–256)**: one owner
  (the `cc_server`) plus N clients. A join beyond that is rejected with
  `{"type":"error","error":"room full"}` and the socket is closed.
- **Joining is invite-gated — knowing the room id is not enough.** A client join
  must carry a `token` whose SHA-256 is in the room's admitted set, published by
  the owner via `admit`. A joiner with a valid room id but no invite-derived
  token is refused before any frame is relayed, with the uniform error
  `not admitted` — the same answer a nonexistent room gives, so the broker is
  not a room oracle. Removing an admission hash evicts any peer that joined with
  it (live revocation).
- **The owner is verified by preimage.** The broker stores only
  `sha256(ownerToken)` at room creation and checks the preimage on every
  re-claim, so a wedged owner socket can be superseded by the real server but
  never by a client.
- **`signal` payloads are forwarded verbatim** — the broker never inspects
  `kind` or `payload`. A `signal` with no other peer in the room is silently
  dropped (logged). A `signal` from a peer that has not joined is dropped.
- **`signal` is fire-and-forget.** Because `peer-joined` only fires once the
  room is shared, an offerer that sends its offer in response to `peer-joined`
  is guaranteed a recipient.
- **Disconnect** (socket close or `bye`) removes the peer and notifies the
  remaining peer with `peer-left`.
- **Garbage collection.** Rooms are reaped by a periodic sweep: an empty room
  after 60 s idle and a room that never filled after 5 min. (Both durations are
  constructor parameters on `SignalingBroker` for testability.)
- **Malformed JSON** is logged and ignored — never crashes the broker.

## Library use

The broker is also usable as a library (e.g. from tests or an embedding host):

```dart
import 'package:cc_signaling_server/cc_signaling_server.dart';

final handle = await serveSignaling(host: '0.0.0.0', port: 0);
print('listening on ${handle.port}'); // ephemeral port
// handle.close() stops the broker and the server.
```

## What this broker does _not_ do

- It does **not** see the pairing PSK. It verifies _admission_ (a hash preimage
  proving the joiner holds a valid invite) but never learns the secret that
  seals the traffic — every payload it forwards is sealed end-to-end
  (`RelayFrameCrypto`) before it arrives.
- It does **not** inspect, validate, or store payloads; `signal` bodies are
  forwarded verbatim, byte for byte.
- It does **not** persist any state to disk; in-memory rooms only.
