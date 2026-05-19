// The four controllers created in [InProcessRpcChannel.pair] are handed to the
// two channels, which close them in [close]; the analyzer can't see that
// ownership transfer across the factory.
// ignore_for_file: close_sinks
import 'dart:async';

import 'package:cc_rpc/src/channel/remote_rpc_channel_port.dart';

/// An in-memory [RemoteRpcChannelPort] connecting two endpoints with no real
/// transport.
///
/// Two roles share one channel: the **server** endpoint (consumed by a
/// `RemoteRpcSession`) and the **client** endpoint (used by a `RemoteConnection`
/// or a test). What the client sends arrives on the server's [incoming] and
/// vice-versa. This is:
///   1. the desktop-LOCAL "be your own server" data path (no serialization, no
///      sockets), and
///   2. the fast protocol-conformance harness — drive the full repo-RPC +
///      subscription surface through it and assert parity with direct calls,
///      with no WebRTC/WSS in the test path.
///
/// Construct a pair with [InProcessRpcChannel.pair]; the two returned channels
/// are wired back-to-back and share a single open/closed lifecycle.
class InProcessRpcChannel implements RemoteRpcChannelPort {
  InProcessRpcChannel._(this._outbound, this._inbound, this._stateController);

  /// Creates a connected (server, client) pair. A frame sent on one surfaces on
  /// the other's [incoming]. Both start [RemoteChannelState.open].
  static (InProcessRpcChannel server, InProcessRpcChannel client) pair() {
    final toServer = StreamController<Map<String, dynamic>>.broadcast();
    final toClient = StreamController<Map<String, dynamic>>.broadcast();
    final serverState = StreamController<RemoteChannelState>.broadcast();
    final clientState = StreamController<RemoteChannelState>.broadcast();
    final server = InProcessRpcChannel._(toClient, toServer, serverState);
    final client = InProcessRpcChannel._(toServer, toClient, clientState);
    server._peer = client;
    client._peer = server;
    // Emit `open` asynchronously so late listeners (attached right after pair())
    // still observe the transition, matching real transports.
    scheduleMicrotask(() {
      if (!serverState.isClosed) {
        serverState.add(RemoteChannelState.open);
      }
      if (!clientState.isClosed) {
        clientState.add(RemoteChannelState.open);
      }
    });
    return (server, client);
  }

  /// Frames written by this endpoint go here (the peer's inbound).
  final StreamController<Map<String, dynamic>> _outbound;

  /// Frames written by the peer arrive here (this endpoint's inbound).
  final StreamController<Map<String, dynamic>> _inbound;

  final StreamController<RemoteChannelState> _stateController;
  InProcessRpcChannel? _peer;
  bool _open = true;

  @override
  Stream<Map<String, dynamic>> get incoming => _inbound.stream;

  @override
  Stream<RemoteChannelState> get state => _stateController.stream;

  @override
  bool get isOpen => _open;

  @override
  Future<void> send(Map<String, dynamic> frame) async {
    if (!_open || _outbound.isClosed) {
      return;
    }
    _outbound.add(frame);
  }

  @override
  Future<void> close() async {
    if (!_open) {
      return;
    }
    _open = false;
    if (!_stateController.isClosed) {
      _stateController.add(RemoteChannelState.closed);
      unawaited(_stateController.close());
    }
    if (!_inbound.isClosed) {
      await _inbound.close();
    }
    // Closing one end closes the conversation; tear the peer down too.
    final peer = _peer;
    _peer = null;
    if (peer != null) {
      await peer.close();
    }
  }
}
