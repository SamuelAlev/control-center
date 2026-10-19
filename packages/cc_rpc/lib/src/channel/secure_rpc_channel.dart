import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_rpc/src/channel/frame_codec.dart';
import 'package:cc_rpc/src/channel/remote_rpc_channel_port.dart';
import 'package:cc_rpc/src/crypto/noise_record_cipher.dart';
import 'package:cc_rpc/src/crypto/noise_session.dart';

/// Ordered, authenticated application framing shared by direct and relay RPC.
///
/// The raw transport sees only bounded Noise records. Message boundaries and
/// flow-control credits are encrypted too. A malformed, replayed, reflected or
/// out-of-order record terminates the session; there is no plaintext mode.
final class SecureRpcChannel implements RemoteRpcChannelPort {
  /// Takes ownership of the raw transport and Noise session; closing this
  /// channel closes the transport and destroys both traffic keys. The keys
  /// move to the record cipher's worker ([NoiseRecordCipher]), so sealing and
  /// opening records never runs on the caller's isolate.
  SecureRpcChannel(this._raw, NoiseSession session)
    : _cipher = NoiseRecordCipher(session) {
    _incoming.onListen = _flushPending;
    _input = _raw.incoming.listen(
      _onRecord,
      onDone: () => unawaited(_drainRemote()),
      onError: _fail,
    );
    _rawState = _raw.state.listen((state) {
      if (state == RemoteChannelState.closed && !_closed && !_remoteEnded) {
        // A transport may report closed before its incoming stream delivers
        // queued records. Give that ordered stream a bounded chance to end.
        _eofTimer ??= Timer(
          _stallTimeout,
          () => _fail(const NoiseProtocolException('Secure EOF timed out')),
        );
      }
    });
  }

  /// Wire protocol version accepted by this secure channel.
  static const int version = 1;

  /// Maximum plaintext bytes in one application fragment.
  static const int chunkBytes = 16 * 1024;

  /// Maximum decoded application frame size in bytes.
  static const int maxFrameBytes = 128 * 1024 * 1024;

  /// Maximum outstanding records in one send-credit window.
  static const int windowRecords = 64;

  /// Number of received records between credit acknowledgements.
  static const int creditEvery = 16;
  static const int _maxWireChars = ((chunkBytes + 2 + 16 + 2) ~/ 3) * 4;
  static const int _maxPendingBytes = 8 * 1024 * 1024;
  static const Duration _stallTimeout = Duration(seconds: 30);

  final RemoteRpcChannelPort _raw;
  final NoiseRecordCipher _cipher;
  final _incoming = StreamController<Map<String, dynamic>>.broadcast();
  final _state = StreamController<RemoteChannelState>.broadcast();
  final _pending = <Map<String, dynamic>>[];
  StreamSubscription<Map<String, dynamic>>? _input;
  StreamSubscription<RemoteChannelState>? _rawState;
  Future<void> _writeChain = Future<void>.value();
  Future<void> _sendChain = Future<void>.value();
  Future<void> _readChain = Future<void>.value();
  Completer<void>? _windowWait;
  BytesBuilder? _assembly;
  Timer? _assemblyTimer;
  Timer? _eofTimer;
  int _sent = 0;
  int _credited = 0;
  int _received = 0;
  int _queuedReads = 0;
  int _queuedSends = 0;
  int _pendingBytes = 0;
  bool _closed = false;
  bool _remoteEnded = false;
  Future<void>? _closing;

  /// The terminal cause, without including ciphertext or secret material.
  Object? get failure => _failure;
  Object? _failure;

  @override
  Stream<Map<String, dynamic>> get incoming => _incoming.stream;
  @override
  Stream<RemoteChannelState> get state => _state.stream;
  @override
  bool get isOpen => !_closed && !_remoteEnded && _raw.isOpen;

  @override
  Future<void> send(Map<String, dynamic> frame) {
    if (!isOpen) {
      return Future.error(StateError('Secure channel closed'));
    }
    if (_queuedSends >= windowRecords) {
      final error = StateError('Secure send queue exhausted');
      _fail(error);
      return Future.error(error);
    }
    _queuedSends++;
    final operation = _sendChain.then((_) => _sendFrame(frame));
    _sendChain = operation.then<void>(
      (_) => _queuedSends--,
      onError: (Object error, StackTrace stack) {
        _queuedSends--;
        _fail(error);
      },
    );
    return operation;
  }

  Future<void> _sendFrame(Map<String, dynamic> frame) async {
    if (!isOpen) {
      throw StateError('Secure channel closed');
    }
    final bytes = utf8.encode(await encodeJsonFrame(frame));
    if (bytes.length > maxFrameBytes) {
      throw const NoiseProtocolException('Application frame too large');
    }
    for (var offset = 0; offset < bytes.length; offset += chunkBytes) {
      await _acquireCredit();
      final end = (offset + chunkBytes).clamp(0, bytes.length);
      final record = Uint8List(2 + end - offset);
      record[0] = 0; // application fragment
      record[1] = (offset == 0 ? 1 : 0) | (end == bytes.length ? 2 : 0);
      record.setRange(2, record.length, bytes, offset);
      _sent++;
      await _writeRecord(record);
    }
  }

  Future<void> _acquireCredit() async {
    while (isOpen && _sent - _credited >= windowRecords) {
      final waiter = _windowWait ??= Completer<void>();
      await waiter.future.timeout(_stallTimeout);
    }
    if (!isOpen) {
      throw StateError('Secure channel closed');
    }
  }

  Future<void> _writeRecord(Uint8List clear, {bool credit = false}) {
    // Credits share the cipher's ordering but never wait behind a data sender
    // blocked on credit; otherwise simultaneous large transfers deadlock.
    final operation = _writeChain.then((_) async {
      if (!isOpen) {
        throw StateError('Secure channel closed');
      }
      final sealed = await _cipher.seal(clear);
      if (!isOpen) {
        throw StateError('Secure channel closed');
      }
      await _raw.send({'type': 'secure', 'v': version, 'c': sealed});
    });
    _writeChain = operation.catchError((Object error) {
      // A transport that closed during an outgoing credit does not invalidate
      // already received application records waiting in the read chain.
      if (!credit || isOpen) {
        _fail(error);
      }
    });
    return operation;
  }

  void _onRecord(Map<String, dynamic> frame) {
    if (_closed) {
      return;
    }
    final ciphertext = frame['c'];
    if (frame['type'] != 'secure' ||
        frame['v'] != version ||
        ciphertext is! String ||
        ciphertext.length > _maxWireChars ||
        _queuedReads >= windowRecords * 2) {
      _fail(const NoiseProtocolException('Invalid secure record'));
      return;
    }
    _queuedReads++;
    // Dispatched now, in arrival order, rather than when the read chain gets
    // to it: the worker opens the next record while this isolate is still
    // accepting the previous one. Its failure is handled where it is awaited.
    final opened = _cipher.open(ciphertext);
    unawaited(opened.then<void>((_) {}, onError: (Object _) {}));
    _readChain = _readChain
        .then((_) async {
          try {
            if (_closed) {
              return;
            }
            final clear = await opened;
            if (!_closed) {
              await _accept(clear);
            }
          } finally {
            _queuedReads--;
          }
        })
        .catchError(_fail);
  }

  Future<void> _accept(Uint8List clear) async {
    if (clear.isEmpty) {
      throw const NoiseProtocolException('Empty secure record');
    }
    if (clear[0] == 1) {
      if (clear.length != 5) {
        throw const NoiseProtocolException('Invalid credit record');
      }
      final credit = ByteData.sublistView(clear).getUint32(1, Endian.big);
      if (credit < _credited || credit > _sent) {
        throw const NoiseProtocolException('Invalid secure credit');
      }
      _credited = credit;
      final waiter = _windowWait;
      _windowWait = null;
      if (waiter != null && !waiter.isCompleted) {
        waiter.complete();
      }
      return;
    }
    if (clear[0] != 0 || clear.length < 3 || clear[1] > 3) {
      throw const NoiseProtocolException('Invalid application fragment');
    }
    final first = clear[1] & 1 != 0;
    final last = clear[1] & 2 != 0;
    if (first == (_assembly != null)) {
      throw const NoiseProtocolException('Invalid message boundary');
    }
    if (first && last) {
      await _deliver(Uint8List.sublistView(clear, 2));
    } else {
      final assembly = _assembly ??= BytesBuilder(copy: false);
      if (assembly.length + clear.length - 2 > maxFrameBytes) {
        throw const NoiseProtocolException('Application frame too large');
      }
      assembly.add(Uint8List.sublistView(clear, 2));
      _assemblyTimer?.cancel();
      if (last) {
        _assembly = null;
        await _deliver(assembly.takeBytes());
      } else {
        _assemblyTimer = Timer(
          _stallTimeout,
          () => _fail(const NoiseProtocolException('Incomplete secure frame')),
        );
      }
    }
    _received++;
    if (_received % creditEvery == 0 && isOpen) {
      final credit = Uint8List(5)..[0] = 1;
      ByteData.sublistView(credit).setUint32(1, _received, Endian.big);
      try {
        await _writeRecord(credit, credit: true);
      } catch (_) {
        if (isOpen) {
          rethrow;
        }
      }
    }
  }

  Future<void> _deliver(Uint8List clear) async {
    if (!_incoming.hasListener &&
        (_pending.length >= windowRecords ||
            _pendingBytes + clear.length > _maxPendingBytes)) {
      throw const NoiseProtocolException('Secure receive queue exhausted');
    }
    final frame = await decodeJsonFrame(utf8.decode(clear));
    if (_closed) {
      return;
    }
    if (_incoming.hasListener) {
      _incoming.add(frame);
    } else {
      _pending.add(frame);
      _pendingBytes += clear.length;
    }
  }

  void _flushPending() {
    for (final frame in _pending) {
      _incoming.add(frame);
    }
    _pending.clear();
    _pendingBytes = 0;
  }

  Future<void> _drainRemote() async {
    if (_closed || _remoteEnded) {
      return;
    }
    _remoteEnded = true;
    _eofTimer?.cancel();
    _eofTimer = null;
    try {
      // onDone follows all onData callbacks, including records still awaiting
      // asynchronous decryption or frame decoding in the ordered read chain.
      await _readChain.timeout(_stallTimeout);
    } on TimeoutException {
      _fail(const NoiseProtocolException('Secure EOF drain timed out'));
      return;
    }
    if (_closed) {
      return; // Explicit close or authentication failure won.
    }
    if (_assembly != null) {
      _fail(const NoiseProtocolException('Incomplete secure frame'));
      return;
    }
    await close();
  }

  void _fail(Object error) {
    if (_closed) {
      return;
    }
    _failure ??= error is NoiseProtocolException
        ? error
        : const NoiseProtocolException('Secure channel authentication failed');
    unawaited(close());
  }

  @override
  Future<void> close() => _closing ??= _close();

  Future<void> _close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    _eofTimer?.cancel();
    _assemblyTimer?.cancel();
    _assembly = null;
    _pending.clear();
    _cipher.destroy();
    final waiter = _windowWait;
    _windowWait = null;
    if (waiter != null && !waiter.isCompleted) {
      waiter.complete();
    }
    _state.add(RemoteChannelState.closed);
    try {
      await _input?.cancel();
      await _rawState?.cancel();
      await _raw.close();
    } finally {
      // A paused consumer must not hold transport teardown or key disposal.
      // Its queued done event is delivered when it resumes or cancels.
      unawaited(_incoming.close());
      unawaited(_state.close());
    }
  }
}
