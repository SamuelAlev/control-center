# cc_signaling_server

Stateless pure-Dart WebSocket relay for `cc_server` rooms. Clients prefer direct loopback/LAN/tailnet/WSS paths and fall back to the relay. The broker admits peers by invite token but never receives the pairing PSK, decrypts Noise `secure` records, or persists application data. The ordered secure channel encrypts application frames and credits end to end.

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
- `signal` carries `room`, `from`, optional `to`, `kind` and an opaque `payload`; forwarding is verbatim except that the broker stamps the authenticated room peer's `from`. Unjoined senders are dropped. A signal without another peer is dropped, not queued. Encrypted data signals are directed `kind: "rpc"` frames whose outer `payload` has `type: "secure"`, `v: 1`, and a string `c` ciphertext. The broker recognizes only this public envelope; it cannot inspect decrypted data or credits.
- `bye` leaves the room. Closing the socket has the same effect.

Broker replies are `joined` (ack without `from`), `peer-joined` (to both peers once the room is shared), `peer-left`, owner-only `admit-ok`, optional `turn-credentials` and `error` (then socket close). `peer-joined` is the point at which an offer has a recipient, regardless of join order. Admission failure uses the same `not admitted` response for a nonexistent room, avoiding a room oracle. Capacity violations report `room full`; other rejects include owner conflicts and malformed membership/ownership requests.

Rooms are in memory: an empty room expires after 60 seconds idle, a never-filled room after five minutes. Malformed JSON is logged and ignored. The broker validates admission, **not** application payloads; see [SECURITY.md](../../SECURITY.md) for the end-to-end trust boundary.

## Streaming and abuse limits

The default 64 KiB inbound frame limit and 8 MiB outbound queue limit per recipient still apply. Admission, membership, room ownership, connection (8192), room (4096), and peer-per-room (16) caps are unchanged. Pre-join messages, malformed frames, legacy signals, `join`, `admit`, `turn-request`, and `bye` consume strict control budgets: 200 frames per socket and 2000 per room per 10 seconds. Over-budget control frames are dropped. Do not use control/legacy signals for ordered encrypted application records.

Directed Noise `secure` records instead consume byte-based token buckets: per socket 8 MiB per 10 seconds with a 512 KiB burst, per room 32 MiB per 10 seconds with a 2 MiB burst. Each record is charged the **entire outer wire frame** or at least 8 KiB (whichever is larger), so forged tiny `secure` envelopes cannot bypass control flood protection. With smaller configured bursts, the minimum charge shrinks to fit them. Rates and bursts are constructor options (`dataBytesPerWindow`, `roomDataBytesPerWindow`, `dataBurstBytes`, `roomDataBurstBytes`); `rateWindow` governs both budgets. Each peer has one active quota reservation in a FIFO room queue and a bounded input FIFO (256 records / 4 MiB, with a 128 MiB broker-wide ceiling). WebSocket input remains readable so close/control frames are not trapped behind a paused data subscription. The production Noise credit window bounds legitimate senders; a sender exceeding the FIFO limit is disconnected rather than consuming unbounded memory. Socket close, room-owner re-claim, admission revocation and broker shutdown cancel queued quota waits. Records are paced in order, **never selectively dropped**. A recipient exceeding its 8 MiB unaccepted outbound buffer is likewise disconnected. These are conservative shared ceilings, not guaranteed throughput: roughly 0.8 MiB/s sustained per peer after its initial burst and 3.2 MiB/s aggregate per room.

Integration requires the relay client and server to direct every Noise record (including encrypted flow-control credits) as `signal` with `kind: "rpc"`, a nonempty `to` peer id, and `payload: {"type":"secure","v":1,"c":"..."}`. Do not broadcast secure records, split an ordered channel across different peer ids, or exceed the 64 KiB outer frame cap; on peer disconnect/revocation terminate the secure session and reconnect with a fresh handshake, never resume its implicit nonce sequence. Credit windows must allow for the configured pacing and room contention (the secure channel's 30-second stall timeout is not a broker guarantee under arbitrary competition).

Directed `kind: "close"` signals are ordering barriers in the same paced FIFO.
They cannot overtake a final encrypted response while the owner's shared room
socket remains open. Admission/revocation controls still run independently;
an actual socket disconnect or `bye` cancels that connection's queued work.
