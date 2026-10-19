/// Seals and opens a Noise session's transport records off the caller's
/// isolate.
///
/// ChaCha20-Poly1305 runs in pure Dart, and every RPC frame and every
/// resource-tunnel body (media, fonts, logos, blobs) crosses it. On the UI
/// isolate that was the largest cost left in a profile build: whole frames of
/// decryption while a space opened. Each session's two directional states
/// move into one worker isolate shared by every session in this isolate; the
/// caller sends records and gets bytes back.
///
/// `isolate_manager` keeps cc_rpc free of `dart:isolate` (it is web-reachable).
/// With no Web Worker wired, the web runs the same worker function inline on
/// the main isolate, which is what it did before.
///
/// Ordering is the security property, and it is preserved end to end:
/// requests reach the worker in call order (one queue, one isolate, FIFO), and
/// each direction's nonce lives with its key in the worker. A record that
/// arrives out of order, or a request lost to a dead worker, fails Noise
/// authentication or times out, and the channel closes; it never yields
/// plaintext out of order.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_rpc/src/crypto/noise_session.dart';
import 'package:isolate_manager/isolate_manager.dart';

/// A worker that does not answer in this long is treated as gone. It is far
/// above any real queue (the channel bounds in-flight records), so only a
/// dead worker reaches it.
const Duration _kWorkerTimeout = Duration(seconds: 30);

IsolateManager<Object?, List<Object?>>? _manager;
Future<void>? _started;
int _nextSessionId = 0;

/// Sends [request] to the shared worker, in call order.
///
/// `IsolateManager.compute` awaits `start()` before it enqueues, and callers
/// that arrive while the manager is starting can resume ahead of the one that
/// started it. Every request therefore waits on the same started future, whose
/// listeners run in registration order, and enqueues from there.
Future<Object?> _send(List<Object?> request) {
  final manager = _manager ??= IsolateManager<Object?, List<Object?>>.create(
    _noiseRecordWorker,
    debugName: 'noise',
  );
  final started = _started ??= manager.start().catchError((
    Object error,
    StackTrace stack,
  ) {
    // Nothing was installed in a worker that never started: let the next
    // session spawn a fresh one rather than inherit this failure.
    _manager = null;
    _started = null;
    Error.throwWithStackTrace(error, stack);
  });
  return started.then((_) => manager.compute(request));
}

/// Encrypts and decrypts one session's records in order, holding its traffic
/// keys in the shared worker rather than in the calling isolate.
final class NoiseRecordCipher {
  /// Takes ownership of [session]: both directions are handed to the worker,
  /// and the keys in [session] are destroyed here.
  factory NoiseRecordCipher(NoiseSession session) {
    final outgoing = session.outgoing.handOff();
    final incoming = session.incoming.handOff();
    final id = _nextSessionId++;
    final installed = _send([
      _opInstall,
      id,
      outgoing.key,
      outgoing.nonce,
      outgoing.lastRekey,
      incoming.key,
      incoming.nonce,
      incoming.lastRekey,
    ]);
    // The request copies the keys when it is sent; drop the local copies only
    // after that, so a request queued behind start-up still carries them.
    unawaited(
      installed
          .whenComplete(() {
            outgoing.key.fillRange(0, outgoing.key.length, 0);
            incoming.key.fillRange(0, incoming.key.length, 0);
          })
          .then<void>((_) {}, onError: (Object _) {}),
    );
    return NoiseRecordCipher._(id, installed);
  }

  NoiseRecordCipher._(this._id, this._installed);

  final int _id;

  /// The install request. Every later request queues behind it on the same
  /// worker, so they need not wait; a failed install fails them too.
  final Future<Object?> _installed;
  bool _destroyed = false;

  /// Encrypts the next outgoing record; returns its base64url wire form.
  Future<String> seal(Uint8List clear) async {
    final sealed = await _call([_opSeal, _id, clear]);
    return sealed! as String;
  }

  /// Authenticates and decrypts the next incoming record from its base64url
  /// wire form.
  Future<Uint8List> open(String sealed) async {
    final clear = await _call([_opOpen, _id, sealed]);
    return clear! as Uint8List;
  }

  Future<Object?> _call(List<Object?> request) async {
    if (_destroyed) {
      throw const NoiseProtocolException('Secure session exhausted or closed');
    }
    try {
      return await _send(request).timeout(_kWorkerTimeout);
    } on Object {
      // Whatever the worker reported (a MAC failure, a malformed record, a
      // missing session), the caller learns only that the record failed. No
      // worker message, record or key material crosses into the error.
      throw const NoiseProtocolException('Secure record rejected');
    }
  }

  /// Erases both directions' keys in the worker. Requests already queued
  /// finish first; later ones fail.
  void destroy() {
    if (_destroyed) {
      return;
    }
    _destroyed = true;
    unawaited(
      _installed
          .then((_) => _send([_opDestroy, _id]))
          .then<void>((_) {}, onError: (Object _) {}),
    );
  }
}

const int _opInstall = 0;
const int _opSeal = 1;
const int _opOpen = 2;
const int _opDestroy = 3;

/// Sessions installed in this worker, by id: (outgoing, incoming).
final Map<int, (NoiseCipherState, NoiseCipherState)> _sessions = {};

/// Runs in the worker isolate (or inline on the web).
@pragma('vm:entry-point')
Future<Object?> _noiseRecordWorker(List<Object?> request) async {
  final op = request[0]! as int;
  final id = request[1]! as int;
  switch (op) {
    case _opInstall:
      final outgoing = request[2]! as Uint8List;
      final incoming = request[5]! as Uint8List;
      try {
        _sessions[id] = (
          NoiseCipherState.resume((
            key: outgoing,
            nonce: request[3]! as int,
            lastRekey: request[4]! as int,
          )),
          NoiseCipherState.resume((
            key: incoming,
            nonce: request[6]! as int,
            lastRekey: request[7]! as int,
          )),
        );
      } finally {
        // The resumed states own copies; erase the received ones.
        outgoing.fillRange(0, outgoing.length, 0);
        incoming.fillRange(0, incoming.length, 0);
      }
      return null;
    case _opSeal:
      final ciphertext = await _session(
        id,
      ).$1.encrypt(request[2]! as Uint8List);
      return base64Url.encode(ciphertext);
    case _opOpen:
      final sealed = base64Url.decode(request[2]! as String);
      return _session(id).$2.decrypt(sealed);
    case _opDestroy:
      final session = _sessions.remove(id);
      session?.$1.destroy();
      session?.$2.destroy();
      return null;
  }
  throw const NoiseProtocolException('Unknown secure record operation');
}

(NoiseCipherState, NoiseCipherState) _session(int id) {
  final session = _sessions[id];
  if (session == null) {
    throw const NoiseProtocolException('Secure session exhausted or closed');
  }
  return session;
}
