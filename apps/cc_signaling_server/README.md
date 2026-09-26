# cc_signaling_server

Stateless pure-Dart WebSocket relay for `cc_server` rooms. Clients prefer direct loopback/LAN/tailnet/WSS paths and fall back to the relay. The broker admits peers by invite token but never receives the pairing PSK, opens sealed `signal` payloads or persists application data. `RelayFrameCrypto` seals frames end to end.

## Run and package

```sh
# from apps/cc_signaling_server
fvm dart run bin/server.dart --port 8788
fvm dart compile exe bin/server.dart -o signaling-server
./signaling-server --host 0.0.0.0 --port 8788

# from the repo root; Docker builds an unprivileged, AOT binary image
docker build -t cc-signaling-server apps/cc_signaling_server/
docker run --rm -p 8788:8788 cc-signaling-server
```

`--host` defaults to `0.0.0.0`, `--port` to `8788` (`0` is ephemeral), and `--max-peers` to `16` (range 2–256 including the owner). In Docker, `SIGNALING_HOST` and `SIGNALING_PORT` configure the bind; map the matching host/container port. The image has a TCP liveness check and graceful SIGTERM shutdown. Optional `CC_TURN_SECRET` and comma-separated `CC_TURN_URIS` enable TURN credential minting, but no current client consumes it.

Library callers can `import 'package:cc_signaling_server/cc_signaling_server.dart'`, then `final handle = await serveSignaling(host: '0.0.0.0', port: 0);`; `handle.port` is the selected port and `handle.close()` shuts down the broker.

## Protocol and boundaries

All messages are JSON objects. Client messages:

- `join` carries `room`, `from`, optional `owner`/`ownerToken` for the server, or a client `token`; a joiner needs an admitted token preimage, not just a room id. The owner publishes SHA-256 admission hashes with `admit`; removing a hash evicts its peer. The broker stores only `sha256(ownerToken)` and verifies its preimage before replacing a wedged owner.
- `signal` carries `room`, `from`, optional `to`, `kind` and an opaque `payload`; forwarding is verbatim. Unjoined senders are dropped. A signal without another peer is dropped, not queued.
- `bye` leaves the room. Closing the socket has the same effect.

Broker replies are `joined` (ack without `from`), `peer-joined` (to both peers once the room is shared), `peer-left`, owner-only `admit-ok`, optional `turn-credentials` and `error` (then socket close). `peer-joined` is the point at which an offer has a recipient, regardless of join order. Admission failure uses the same `not admitted` response for a nonexistent room, avoiding a room oracle. Capacity violations report `room full`; other rejects include owner conflicts and malformed membership/ownership requests.

Rooms are in memory: an empty room expires after 60 seconds idle, a never-filled room after five minutes. Malformed JSON is logged and ignored. The broker validates admission, **not** application payloads; see [SECURITY.md](../../SECURITY.md) for the end-to-end trust boundary.
