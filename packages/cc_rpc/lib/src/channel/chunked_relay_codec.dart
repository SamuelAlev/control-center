import 'dart:async';
import 'dart:convert';

import 'package:cc_rpc/src/channel/frame_codec.dart';
import 'package:cc_rpc/src/crypto/relay_frame_crypto.dart';
import 'package:isolate_manager/isolate_manager.dart';

/// Direction of a relay transfer, for progress reporting.
enum RelayTransferDirection {
  /// Bytes leaving this side.
  send,

  /// Bytes arriving at this side.
  receive,
}

/// Progress of one multi-chunk relay transfer (a large frame in flight).
class RelayTransferProgress {
  /// Creates a [RelayTransferProgress].
  const RelayTransferProgress({
    required this.direction,
    required this.frameId,
    required this.transferredChunks,
    required this.totalChunks,
    required this.transferredChars,
    required this.totalChars,
  });

  /// Which way the frame is moving.
  final RelayTransferDirection direction;

  /// The sender-local id of the frame being transferred.
  final int frameId;

  /// Chunks moved so far.
  final int transferredChunks;

  /// Total chunks in this frame.
  final int totalChunks;

  /// Sealed characters moved so far (~bytes; base64url is 1 char ≈ 0.75 byte
  /// of plaintext).
  final int transferredChars;

  /// Total sealed characters in this frame.
  final int totalChars;

  /// Completion in [0, 1].
  double get fraction => totalChunks == 0 ? 1 : transferredChunks / totalChunks;
}

/// Chunking + credit-based backpressure for the sealed relay data plane (PRD 15 §11).
///
/// A TURN-style relayed channel is a control-plane transport: one unbounded send can stall
/// every session sharing the broker.
/// This codec seals each JSON-RPC frame with the link PSK ([RelayFrameCrypto]), splits the
/// sealed text into ≤[maxChunkChars] pieces and paces the sender with a cumulative **credit
/// window**: at most [windowChunks] un-acknowledged chunks may be in flight; the receiver
/// returns sealed credit frames every [creditEvery] chunks.
class ChunkedRelaySession {
  /// Creates one side of a relay link.
  ///
  /// [_sendPayload] hands a wire payload to the transport (a broker `signal`
  /// send). [_onFrame] receives each fully reassembled, authenticated JSON-RPC
  /// frame. [_onProgress] (optional) observes multi-chunk transfers.
  ChunkedRelaySession({
    required this._psk,
    required this._sendPayload,
    required this._onFrame,
    this._onProgress,
    this.maxChunkChars = 16 * 1024,
    this.windowChunks = 64,
    this.creditEvery = 16,
    this.maxAssemblyChars = 128 * 1024 * 1024,
    this.maxConcurrentAssemblies = 8,
    this.sendStallTimeout = const Duration(seconds: 30),
  });

  /// Maximum sealed characters per relayed piece (~16 KB SCTP-friendly).
  final int maxChunkChars;

  /// Maximum un-credited chunks in flight before the sender pauses. Must be
  /// at least 2 × [creditEvery] so batched credits always arrive before the
  /// window can exhaust on steady traffic.
  final int windowChunks;

  /// The receiver acks every this-many chunks.
  final int creditEvery;

  /// Hard cap on one reassembling frame (DoS guard).
  final int maxAssemblyChars;

  /// Hard cap on concurrent reassemblies from one peer (DoS guard).
  final int maxConcurrentAssemblies;

  /// How long a full send window may stall before the link is declared dead.
  final Duration sendStallTimeout;

  final String _psk;
  final void Function(Map<String, dynamic> payload) _sendPayload;
  final void Function(Map<String, dynamic> frame) _onFrame;
  final void Function(RelayTransferProgress progress)? _onProgress;

  int _nextFrameId = 0;
  int _chunksSent = 0;
  int _chunksCredited = 0;
  int _chunksReceived = 0;
  int _lastCreditSentAt = 0;
  Completer<void>? _windowWait;
  bool _closed = false;

  final Map<int, _Assembly> _assemblies = {};

  /// Serializes sends so interleaved large frames can't interleave chunks of
  /// the same id out of order.
  Future<void> _sendChain = Future.value();

  /// Serializes delivery of reassembled frames. A large frame is opened and
  /// decoded off this isolate; a later small frame must not be handed to
  /// [_onFrame] first. Credit frames are not part of that order — they only
  /// move the send window, and holding them behind a decode would stall the
  /// sender.
  Future<void> _orderChain = Future<void>.value();

  /// Frames whose delivery is queued behind an off-isolate decode, including
  /// that decode itself. Zero means a small frame can be delivered inline.
  int _orderedPending = 0;

  /// Sends one JSON-RPC [frame], sealing and chunking as needed. Completes
  /// when every piece has been handed to the transport (which, under a full
  /// window, means after the receiver granted credits). Throws
  /// [RelayBackpressureStallException] when the window stays full past
  /// [sendStallTimeout] — the link is effectively dead.
  Future<void> sendFrame(Map<String, dynamic> frame) {
    final chained = _sendChain.then((_) => _sendFrameNow(frame));
    // Keep the chain alive even when a send fails, so a stalled frame does
    // not wedge every later small frame behind a completed error.
    _sendChain = chained.catchError((_) {});
    return chained;
  }

  Future<void> _sendFrameNow(Map<String, dynamic> frame) async {
    if (_closed) {
      throw StateError('relay session is closed');
    }
    // Large frames encode off this isolate; the send chain above still
    // orders them. Small frames encode inline inside [encodeJsonFrame].
    final sealed = RelayFrameCrypto.seal(await encodeJsonFrame(frame), _psk);
    if (sealed.length <= maxChunkChars) {
      await _acquireWindow(1);
      _chunksSent++;
      _sendPayload({'e': sealed});
      return;
    }
    final id = _nextFrameId++;
    final total = (sealed.length + maxChunkChars - 1) ~/ maxChunkChars;
    for (var i = 0; i < total; i++) {
      await _acquireWindow(1);
      final start = i * maxChunkChars;
      final end = (start + maxChunkChars).clamp(0, sealed.length);
      _chunksSent++;
      _sendPayload({
        'c': sealed.substring(start, end),
        'id': id,
        'i': i,
        'n': total,
      });
      _onProgress?.call(
        RelayTransferProgress(
          direction: RelayTransferDirection.send,
          frameId: id,
          transferredChunks: i + 1,
          totalChunks: total,
          transferredChars: end,
          totalChars: sealed.length,
        ),
      );
    }
  }

  Future<void> _acquireWindow(int chunks) async {
    while (!_closed && _chunksSent + chunks - _chunksCredited > windowChunks) {
      final wait = _windowWait ??= Completer<void>();
      try {
        await wait.future.timeout(sendStallTimeout);
      } on TimeoutException {
        throw const RelayBackpressureStallException();
      }
    }
    if (_closed) {
      throw StateError('relay session is closed');
    }
  }

  /// Routes one inbound wire payload: reassembles chunks, opens sealed
  /// frames, absorbs credit frames, surfaces JSON-RPC frames via `onFrame`.
  /// Unauthenticated or malformed payloads are dropped (fail closed).
  void handlePayload(Map<String, dynamic> payload) {
    if (_closed) {
      return;
    }
    final whole = payload['e'];
    if (whole is String) {
      _countReceived(1);
      _openAndDispatch(whole);
      return;
    }
    final piece = payload['c'];
    final id = payload['id'];
    final index = payload['i'];
    final total = payload['n'];
    if (piece is! String || id is! int || index is! int || total is! int) {
      return;
    }
    if (total < 1 || index < 0 || index >= total) {
      return;
    }
    _countReceived(1);
    var assembly = _assemblies[id];
    if (assembly == null) {
      if (_assemblies.length >= maxConcurrentAssemblies) {
        // Evict the stalest assembly rather than accept unbounded state.
        final stalest = _assemblies.entries.reduce(
          (a, b) => a.value.lastTouch.isBefore(b.value.lastTouch) ? a : b,
        );
        _assemblies.remove(stalest.key);
      }
      assembly = _Assembly(total);
      _assemblies[id] = assembly;
    }
    if (assembly.total != total) {
      // Total mismatch for the same id — hostile or corrupt; restart clean.
      assembly = _Assembly(total);
      _assemblies[id] = assembly;
    }
    assembly.pieces[index] = piece;
    assembly.receivedChars += piece.length;
    assembly.lastTouch = DateTime.now();
    if (assembly.receivedChars > maxAssemblyChars) {
      _assemblies.remove(id);
      return;
    }
    _onProgress?.call(
      RelayTransferProgress(
        direction: RelayTransferDirection.receive,
        frameId: id,
        transferredChunks: assembly.pieces.values.length,
        totalChunks: total,
        transferredChars: assembly.receivedChars,
        // The sealed size is unknown until the last piece; a chunk-count
        // upper bound keeps the fraction monotonic for progress UI.
        totalChars: total * maxChunkChars,
      ),
    );
    if (assembly.pieces.length == total) {
      _assemblies.remove(id);
      final buffer = StringBuffer();
      for (var i = 0; i < total; i++) {
        buffer.write(assembly.pieces[i]);
      }
      _openAndDispatch(buffer.toString());
    }
  }

  void _countReceived(int chunks) {
    _chunksReceived += chunks;
    if (_chunksReceived - _lastCreditSentAt >= creditEvery) {
      _sendCredit();
    }
  }

  void _sendCredit() {
    _lastCreditSentAt = _chunksReceived;
    final sealed = RelayFrameCrypto.seal(
      jsonEncode({'__cc_credit': _chunksReceived}),
      _psk,
    );
    _sendPayload({'e': sealed});
  }

  void _openAndDispatch(String sealed) {
    if (_closed) {
      return;
    }
    // Sealed text is base64url of the plaintext, so this is a ceiling on the
    // JSON size. Under it, opening and decoding inline is cheaper than an
    // isolate hop — and it keeps credit frames synchronous, which the send
    // window awaits.
    if (sealed.length < _offloadSealedChars) {
      final decoded = _decodeSealedFrame(sealed, _psk);
      if (decoded == null) {
        return;
      }
      if (_applyCredit(decoded)) {
        return;
      }
      if (_orderedPending == 0) {
        _onFrame(decoded);
        return;
      }
      _enqueueOrdered(Future<Map<String, dynamic>?>.value(decoded));
      return;
    }
    // Started now, not inside the chain, so two large frames decode in
    // parallel. The chain only orders [_onFrame]. The closure must not
    // capture this session: it holds futures, which cannot cross an isolate.
    final psk = _psk;
    final pending = IsolateManager.run(() => _decodeSealedFrame(sealed, psk));
    _enqueueOrdered(pending);
  }

  /// Queues [pending] behind whatever frame is already decoding. A failure,
  /// including one thrown by [_onFrame], must not strand every later frame.
  void _enqueueOrdered(Future<Map<String, dynamic>?> pending) {
    _orderedPending++;
    final step = _orderChain.then((_) async {
      try {
        if (_closed) {
          return;
        }
        final decoded = await pending;
        if (decoded == null || _closed) {
          return;
        }
        if (_applyCredit(decoded)) {
          return;
        }
        _onFrame(decoded);
      } finally {
        _orderedPending--;
      }
    });
    _orderChain = step.catchError((Object _) {});
  }

  /// Applies a credit frame. Returns true when [decoded] was one.
  bool _applyCredit(Map<String, dynamic> decoded) {
    final credit = decoded['__cc_credit'];
    if (credit is! int) {
      return false;
    }
    if (credit > _chunksCredited) {
      _chunksCredited = credit;
    }
    final wait = _windowWait;
    if (wait != null && !wait.isCompleted) {
      _windowWait = null;
      wait.complete();
    }
    return true;
  }

  /// Releases waiters and refuses further work. Idempotent.
  void close() {
    if (_closed) {
      return;
    }
    _closed = true;
    _assemblies.clear();
    final wait = _windowWait;
    if (wait != null && !wait.isCompleted) {
      _windowWait = null;
      wait.complete();
    }
  }
}

/// Thrown when the credit window stays exhausted past the stall timeout —
/// the peer is gone or wedged; callers close the channel.
class RelayBackpressureStallException implements Exception {
  /// Creates a [RelayBackpressureStallException].
  const RelayBackpressureStallException();

  @override
  String toString() =>
      'RelayBackpressureStallException: relay peer granted no send credits '
      'within the stall timeout — closing the link.';
}

/// Sealed frames at least this long are opened and decoded off-isolate.
///
/// Base64url expands the plaintext by 4/3, so this lines up with
/// [kIsolateDecodeThresholdChars] of JSON rather than with the sealed
/// character count itself.
const int _offloadSealedChars = (kIsolateDecodeThresholdChars * 4) ~/ 3;

/// Opens and decodes one sealed relay frame.
///
/// Returns null for a failed tag, a truncated token, or a payload that is
/// not a JSON object. Null is the isolate-friendly form of "drop it": an
/// exception thrown inside [IsolateManager.run] would surface as a delivery
/// failure instead of a skipped frame.
Map<String, dynamic>? _decodeSealedFrame(String sealed, String psk) {
  final String clear;
  try {
    clear = RelayFrameCrypto.open(sealed, psk);
  } on RelayFrameAuthException {
    return null;
  }
  try {
    final decoded = jsonDecode(clear);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
  } catch (_) {
    return null;
  }
  return null;
}

class _Assembly {
  _Assembly(this.total) : lastTouch = DateTime.now();

  final int total;
  final Map<int, String> pieces = {};
  int receivedChars = 0;
  DateTime lastTouch;
}
