import 'dart:async';
import 'dart:io';

/// The one WebSocket capability the Socket Mode client needs.
///
/// A seam, not an abstraction for its own sake: the real socket is a `dart:io`
/// `WebSocket`, and tests drive the envelope protocol (acks, `disconnect`
/// refreshes, reconnect backoff) through an in-memory implementation instead of
/// standing up a TLS server.
abstract interface class SlackSocket {
  /// Inbound frames as Slack sent them (text frames, still JSON strings).
  Stream<dynamic> get messages;

  /// Whether the socket is still open.
  bool get isOpen;

  /// Sends a text frame (an envelope ack).
  void send(String message);

  /// Closes the socket.
  Future<void> close();
}

/// Opens a Socket Mode WebSocket to [url].
typedef SlackSocketConnector = Future<SlackSocket> Function(Uri url);

/// The production [SlackSocketConnector] — a `dart:io` WebSocket.
///
/// `pingInterval` matters: Slack's side goes quiet between events, and without
/// a ping a half-open connection (laptop slept, NAT dropped the flow) looks
/// alive forever and the bridge silently stops receiving. With it, the socket
/// errors out and the client reconnects.
Future<SlackSocket> connectSlackSocket(Uri url) async {
  // Ownership transfers to the returned _IoSlackSocket, which closes it.
  // ignore: close_sinks
  final socket = await WebSocket.connect(url.toString());
  socket.pingInterval = const Duration(seconds: 30);
  return _IoSlackSocket(socket);
}

class _IoSlackSocket implements SlackSocket {
  _IoSlackSocket(this._socket);

  final WebSocket _socket;

  @override
  Stream<dynamic> get messages => _socket;

  @override
  bool get isOpen => _socket.readyState == WebSocket.open;

  @override
  void send(String message) => _socket.add(message);

  @override
  Future<void> close() async {
    try {
      await _socket.close();
    } on Object {
      // Closing a socket that already failed is not a failure of its own.
    }
  }
}
