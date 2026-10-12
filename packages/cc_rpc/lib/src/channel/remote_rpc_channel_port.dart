import 'dart:async';

/// Connection state of a [RemoteRpcChannelPort].
enum RemoteChannelState {
  /// The underlying transport is not yet open.
  connecting,

  /// The transport is open and frames can flow in both directions.
  open,

  /// The transport has closed (cleanly or on error) and will not reopen.
  closed,
}

/// A bidirectional, framed-JSON transport that carries JSON-RPC traffic
/// between a first-party client and its server.
///
/// This is the transport seam: the `RemoteRpcSession` is agnostic of *how*
/// frames move — it only consumes [incoming] and calls [send]. Direct WebSocket
/// and broker-relayed channels share this contract, so sessions can be tested
/// without a live network connection.
abstract interface class RemoteRpcChannelPort {
  /// A stream of decoded JSON-RPC frames (each a decoded [Map]) received from
  /// the remote peer. Emits once per inbound transport message.
  Stream<Map<String, dynamic>> get incoming;

  /// The current connection [RemoteChannelState], plus subsequent changes.
  Stream<RemoteChannelState> get state;

  /// Whether the channel is currently [RemoteChannelState.open].
  bool get isOpen;

  /// Sends a single JSON-RPC frame ([frame]) to the remote peer.
  ///
  /// Completes when the frame was handed to the transport. Throws when the
  /// channel is not open.
  Future<void> send(Map<String, dynamic> frame);

  /// Closes the transport. Idempotent. After this returns, [state] emits
  /// [RemoteChannelState.closed] and [incoming] done.
  Future<void> close();
}
