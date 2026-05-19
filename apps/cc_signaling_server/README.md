# cc_signaling_server

A pure-Dart, **stateless** WebSocket signaling broker for Control Center WebRTC
pairing. Drop this single binary on your STUN box and run it — the desktop app
and the `cc_remote` phone PWA rendezvous here to exchange opaque SDP/ICE blobs
before opening a direct, end-to-end-encrypted WebRTC data channel.

It is a **dumb relay**. It holds no application data, never sees the pairing
pre-shared key (PSK), never persists anything, and **never interprets SDP or
ICE** — `signal` payloads are forwarded verbatim, byte-for-byte.

## Run

```sh
dart run bin/server.dart --port 8788
# listening on 0.0.0.0:8788
```

Flags (all optional):

| Flag      | Default   | Meaning                                  |
| --------- | --------- | ---------------------------------------- |
| `--host`  | `0.0.0.0` | Network interface to bind.               |
| `--port`  | `8788`    | TCP port (`0` picks an ephemeral port).  |

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
`HEALTHCHECK`, and the binary is PID 1 so `docker stop` triggers its graceful
SIGTERM shutdown.

## Message protocol

Every frame is a JSON object; the broker only inspects `type`.

### Client → broker

| `type`   | Fields                                  | Effect                                            |
| -------- | --------------------------------------- | ------------------------------------------------- |
| `join`   | `room`, `from`                          | Enter a room (created on first join; capacity 2). |
| `signal` | `room`, `from`, `to`?, `kind`, `payload` | Relay the opaque `payload` to the other peer.   |
| `bye`    | `room`                                  | Leave the room.                                   |

### Broker → client

| `type`        | Fields       | Sent when…                                                              |
| ------------- | ------------ | ----------------------------------------------------------------------- |
| `joined`      | `room`       | Your `join` succeeded (the join ack — it carries **no** `from`).        |
| `peer-joined` | `room`       | The room is now shared. Emitted **symmetrically to both peers** the instant a second peer joins, so an offerer can fire its offer on this regardless of join order. |
| `peer-left`   | `room`       | The other peer left (disconnect, `bye`, or room garbage collection).    |
| `error`       | `error`      | Rejection, e.g. `room full` (capacity 2) — the socket is then closed.   |

### Behavior notes

- **Rooms hold at most 2 peers.** A third `join` is rejected with
  `{"type":"error","error":"room full"}` and the socket is closed.
- **`signal` payloads are forwarded verbatim** — the broker never inspects
  `kind` or `payload`. A `signal` with no other peer in the room is silently
  dropped (logged). A `signal` from a peer that has not joined is dropped.
- **`signal` is fire-and-forget.** Because `peer-joined` only fires once the
  room is shared, an offerer that sends its offer in response to `peer-joined`
  is guaranteed a recipient.
- **Disconnect** (socket close or `bye`) removes the peer and notifies the
  remaining peer with `peer-left`.
- **Garbage collection.** Rooms are reaped by a periodic sweep: an empty room
  after 60 s idle, and a room that never filled after 5 min. (Both durations are
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

## What this broker does *not* do

- It does **not** authenticate peers or verify the PSK — the QR's PSK travels
  only in the URL fragment and is used end-to-end by the two WebRTC peers.
- It does **not** inspect, validate, or store SDP/ICE.
- It does **not** persist any state to disk; in-memory rooms only.
