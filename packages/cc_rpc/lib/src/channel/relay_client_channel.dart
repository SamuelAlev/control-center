import 'dart:async';

import 'package:cc_rpc/src/channel/chunked_relay_codec.dart';
import 'package:cc_rpc/src/channel/relay_signaling_channel.dart';
import 'package:cc_rpc/src/channel/remote_rpc_channel_port.dart';
import 'package:cc_rpc/src/crypto/remote_control_crypto.dart';

/// The client half of the broker-relayed RPC path — the guaranteed
/// NAT-traversal fallback (PRD 15 §2/§3).
///
/// Joins the server's relay room with the PSK-derived admission token,
/// addresses every frame to the room **owner** (the cc_server), seals frames
/// end-to-end ([ChunkedRelaySession]), and presents the standard
/// [RemoteRpcChannelPort] so `authenticateRemoteChannel` + `RemoteRpcClient`
/// run over it unchanged. Works on the VM, web, and the phone PWA.
class RelayClientChannel implements RemoteRpcChannelPort {
  RelayClientChannel._(this._signaling, this._psk);

  /// Connects through [signalingUrl]'s broker into the server's relay [room].
  ///
  /// Derives the admission token from [psk] + [room]; when the server is not
  /// yet in the room (a restart gap), waits up to [ownerWait] for it to
  /// appear before failing. Once the owner is present, announces [deviceId]
  /// with a cleartext `hello` so the server can bind this peer to its PSK —
  /// routing information only; authentication is the sealed PSK handshake
  /// that follows. Throws [RelaySignalingException] on refusal
  /// (`not admitted` = the device was revoked or the room rotated).
  static Future<RelayClientChannel> connect({
    required String signalingUrl,
    required String room,
    required String deviceId,
    required String psk,
    String? peerId,
    Duration timeout = const Duration(seconds: 15),
    Duration ownerWait = const Duration(seconds: 20),
  }) async {
    final signaling = await RelaySignalingChannel.joinAsClient(
      signalingUrl: signalingUrl,
      room: room,
      token: RemoteControlCrypto.relayAdmissionToken(psk: psk, room: room),
      peerId: peerId,
      timeout: timeout,
    );
    final channel = RelayClientChannel._(signaling, psk);
    try {
      await channel._start(ownerWait);
      channel._signaling.sendSignal(
        to: channel._ownerPeer,
        kind: 'hello',
        payload: {'d': deviceId},
      );
    } catch (_) {
      await channel.close();
      rethrow;
    }
    return channel;
  }

  final RelaySignalingChannel _signaling;
  final String _psk;

  late ChunkedRelaySession _session;
  String? _ownerPeer;
  StreamSubscription<Map<String, dynamic>>? _sub;

  final StreamController<Map<String, dynamic>> _incoming =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<RemoteChannelState> _state =
      StreamController<RemoteChannelState>.broadcast();
  final StreamController<RelayTransferProgress> _progress =
      StreamController<RelayTransferProgress>.broadcast();
  final List<Map<String, dynamic>> _pending = [];
  bool _open = false;

  /// Progress of large transfers over this relayed link (bulk fallback UI).
  Stream<RelayTransferProgress> get transferProgress => _progress.stream;

  Future<void> _start(Duration ownerWait) async {
    var ownerPeer = _signaling.joinAck.ownerPeer;
    final events = StreamController<Map<String, dynamic>>.broadcast();
    _sub = _signaling.incoming.listen(
      events.add,
      onDone: () {
        if (!events.isClosed) {
          events.close();
        }
        _onClosed();
      },
    );

    if (ownerPeer == null) {
      // The server is momentarily absent (restart / broker blip). Wait for
      // its owner join instead of failing the whole connection attempt.
      try {
        final joined = await events.stream
            .firstWhere((f) => f['type'] == 'peer-joined' && f['owner'] == true)
            .timeout(ownerWait);
        ownerPeer = joined['from'] as String?;
      } on TimeoutException {
        throw const RelaySignalingException(
          'server is not connected to the relay room',
        );
      }
    }
    if (ownerPeer == null || ownerPeer.isEmpty) {
      throw const RelaySignalingException('relay room has no owner peer');
    }
    _ownerPeer = ownerPeer;

    _session = ChunkedRelaySession(
      psk: _psk,
      sendPayload: (payload) =>
          _signaling.sendSignal(to: _ownerPeer, payload: payload),
      onFrame: (frame) {
        if (_incoming.hasListener) {
          _incoming.add(frame);
        } else {
          // Buffer-until-listener: the auth handshake's first reply must
          // never be dropped before a listener attaches.
          _pending.add(frame);
        }
      },
      onProgress: (p) {
        if (!_progress.isClosed) {
          _progress.add(p);
        }
      },
    );
    _incoming.onListen = _flushPending;

    events.stream.listen((frame) {
      final type = frame['type'];
      if (type == 'signal' && frame['from'] == _ownerPeer) {
        final payload = frame['payload'];
        if (payload is Map) {
          _session.handlePayload(payload.cast<String, dynamic>());
        }
        return;
      }
      if (type == 'peer-left' &&
          (frame['from'] == _ownerPeer || frame['reason'] == 'socket-closed')) {
        // The server left (or our broker socket died) — this connection is
        // over; the resolver owns reconnecting.
        _onClosed();
      }
    });

    _open = true;
    _state.add(RemoteChannelState.open);
  }

  void _flushPending() {
    if (_pending.isEmpty) {
      return;
    }
    final buffered = List<Map<String, dynamic>>.of(_pending);
    _pending.clear();
    for (final f in buffered) {
      _incoming.add(f);
    }
  }

  @override
  Stream<Map<String, dynamic>> get incoming => _incoming.stream;

  @override
  Stream<RemoteChannelState> get state => _state.stream;

  @override
  bool get isOpen => _open;

  @override
  Future<void> send(Map<String, dynamic> frame) async {
    if (!_open) {
      throw StateError('RelayClientChannel is not open');
    }
    await _session.sendFrame(frame);
  }

  @override
  Future<void> close() async {
    _onClosed();
    await _signaling.close();
    if (!_incoming.isClosed) {
      await _incoming.close();
    }
    if (!_progress.isClosed) {
      await _progress.close();
    }
    if (!_state.isClosed) {
      await _state.close();
    }
  }

  void _onClosed() {
    if (!_open) {
      return;
    }
    _open = false;
    _session.close();
    unawaited(_sub?.cancel());
    if (!_state.isClosed) {
      _state.add(RemoteChannelState.closed);
    }
  }

  /// Probes the relay path: joins the room with the admission token, reads
  /// owner presence + round-trip latency from the join ack, and leaves.
  /// Returns null when the path is unusable (unreachable broker, refused
  /// admission, or no server in the room).
  static Future<Duration?> probe({
    required String signalingUrl,
    required String room,
    required String psk,
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final started = DateTime.now();
    RelaySignalingChannel? signaling;
    try {
      signaling = await RelaySignalingChannel.joinAsClient(
        signalingUrl: signalingUrl,
        room: room,
        token: RemoteControlCrypto.relayAdmissionToken(psk: psk, room: room),
        timeout: timeout,
      );
      if (!signaling.joinAck.ownerPresent) {
        return null;
      }
      return DateTime.now().difference(started);
    } catch (_) {
      return null;
    } finally {
      unawaited(signaling?.close());
    }
  }
}
