import 'dart:convert';

/// The set of message types exchanged with the signaling broker.
///
/// The broker is a **stateless dumb relay**: it understands `join`/`signal`/
/// `bye` from a client and `joined`/`peer-left`/`error` from itself, but it
/// never interprets the `payload` of a `signal` (SDP and ICE candidates are
/// opaque blobs to it). See `apps/cc_signaling_server/`.
enum SignalingMessageType {
  /// A client joining a room (outbound).
  join('join'),

  /// Broker ack of a successful join (inbound).
  joined('joined'),

  /// An opaque relayed signaling blob (SDP/ICE), either direction.
  signal('signal'),

  /// A client leaving a room (outbound).
  bye('bye'),

  /// Broker notice that a peer joined the room (inbound). Sent symmetrically
  /// when the room becomes shared.
  peerJoined('peer-joined'),

  /// Broker notice that the peer left the room (inbound).
  peerLeft('peer-left'),

  /// Broker-side error (inbound).
  error('error');

  const SignalingMessageType(this.wire);

  /// The wire string used in the JSON envelope.
  final String wire;

  /// Resolves a wire string back to the enum, or null when unknown.
  static SignalingMessageType? fromWire(String? wire) {
    for (final v in SignalingMessageType.values) {
      if (v.wire == wire) {
        return v;
      }
    }
    return null;
  }
}

/// One signaling frame exchanged with the broker or the peer behind it.
///
/// `kind` disambiguates `signal` payloads: `'offer'`, `'answer'`, or `'ice'`.
/// `payload` carries the opaque SDP (for offer/answer, as `{sdp, type}`) or
/// ICE candidate (as `{candidate, sdpMid, sdpMLineIndex}`).
class SignalingMessage {
  /// Creates a [SignalingMessage].
  SignalingMessage({
    required this.type,
    this.room,
    this.from,
    this.to,
    this.kind,
    this.payload,
    this.error,
  });

  /// Deserializes a [SignalingMessage] from a JSON envelope.
  factory SignalingMessage.fromJson(Map<String, dynamic> json) {
    return SignalingMessage(
      type:
          SignalingMessageType.fromWire(json['type'] as String?) ??
          SignalingMessageType.error,
      room: json['room'] as String?,
      from: json['from'] as String?,
      to: json['to'] as String?,
      kind: json['kind'] as String?,
      payload: json['payload'] is Map<String, dynamic>
          ? json['payload'] as Map<String, dynamic>
          : null,
      error: json['error'] as String?,
    );
  }

  /// The envelope type.
  final SignalingMessageType type;

  /// Room id (the pairing code).
  final String? room;

  /// Sender peer id.
  final String? from;

  /// Recipient peer id.
  final String? to;

  /// For `signal`: `'offer'`, `'answer'`, or `'ice'`.
  final String? kind;

  /// For `signal`: the opaque SDP or ICE-candidate blob.
  final Map<String, dynamic>? payload;

  /// For `error`: the broker's error text.
  final String? error;

  /// Serializes the envelope to JSON.
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'type': type.wire};
    if (room != null) {
      json['room'] = room;
    }
    if (from != null) {
      json['from'] = from;
    }
    if (to != null) {
      json['to'] = to;
    }
    if (kind != null) {
      json['kind'] = kind;
    }
    if (payload != null) {
      json['payload'] = payload;
    }
    if (error != null) {
      json['error'] = error;
    }
    return json;
  }

  @override
  String toString() => jsonEncode(toJson());
}
