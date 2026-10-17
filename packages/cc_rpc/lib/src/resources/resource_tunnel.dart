import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_rpc/src/channel/remote_rpc_channel_port.dart';

/// The encrypted channel is the only transport for these resource frames.
/// A resource ID belongs to one secure session; it is never rebound on failover.
abstract interface class RemoteResources {
  /// Starts an HTTP exchange on this secure session; the caller consumes or
  /// closes the response to release the transfer and any upload producer.
  Future<RemoteResourceResponse> request(
    String method,
    Uri uri, {
    Map<String, List<String>> headers = const {},
    Stream<List<int>>? body,
  });

  /// Opens a WebSocket tunnel on this secure session. Closing the returned
  /// socket releases its peer and local stream resources.
  Future<RemoteResourceSocket> connectWebSocket(
    Uri uri, {
    Map<String, List<String>> headers = const {},
    List<String> protocols = const [],
  });
}

/// HTTP response metadata and a streamed body owned by one resource transfer.
class RemoteResourceResponse {
  /// Creates a response whose optional close callback aborts its upstream.
  RemoteResourceResponse({
    required this.statusCode,
    required this.headers,
    required this.body,
    this._onClose,
  });

  /// HTTP status returned by the resource handler.
  final int statusCode;

  /// Response headers, preserving multiple values for each name.
  final Map<String, List<String>> headers;

  /// Response bytes; cancelling its listener aborts the transfer.
  final Stream<Uint8List> body;
  final Future<void> Function()? _onClose;

  /// Aborts the transfer, including an upstream upload still in progress.
  Future<void> close() => _onClose?.call() ?? Future<void>.value();
}

/// A bidirectional WebSocket tunneled over the authenticated resource channel.
class RemoteResourceSocket {
  /// Wraps an upstream WebSocket with send, close and peer-close callbacks.
  RemoteResourceSocket({
    required this.incoming,
    required this.protocol,
    required this._onSend,
    required this._onClose,
    this._closeCode,
    this._closeReason,
    this._readCloseCode,
    this._readCloseReason,
  });

  /// Incoming text messages or binary byte sequences.
  final Stream<Object> incoming;

  /// Selected WebSocket subprotocol, or empty when none was negotiated.
  final String protocol;
  final Future<void> Function(Object) _onSend;
  final Future<void> Function(int, String) _onClose;
  final int? Function()? _readCloseCode;
  final String? Function()? _readCloseReason;
  int? _closeCode;
  String? _closeReason;

  /// Peer close code, populated when its close frame arrives.
  int? get closeCode => _readCloseCode?.call() ?? _closeCode;
  set closeCode(int? value) => _closeCode = value;

  /// Peer close reason, populated when its close frame arrives.
  String? get closeReason => _readCloseReason?.call() ?? _closeReason;
  set closeReason(String? value) => _closeReason = value;

  /// Sends one text or binary message, subject to the tunnel's credit window.
  Future<void> send(Object data) => _onSend(data);

  /// Closes the socket and sends a valid WebSocket close code to its peer.
  Future<void> close([int code = 1000, String reason = '']) =>
      _onClose(code, reason);
}

/// Handler input for one authenticated, session-scoped resource operation.
class RemoteResourceRequest {
  /// Creates the request, binding [cancelled] to its transfer's lifetime.
  RemoteResourceRequest({
    required this.method,
    required this.uri,
    required this.headers,
    required this.body,
    this.protocols = const [],
    required this.cancelled,
    required this._isCancelled,
  });

  /// Uppercase HTTP method, or GET for a WebSocket upgrade.
  final String method;

  /// Absolute resource path, without a scheme or authority.
  final Uri uri;

  /// Request headers, preserving multiple values for each name.
  final Map<String, List<String>> headers;

  /// Request upload bytes; its listener is released when the transfer ends.
  final Stream<Uint8List> body;

  /// WebSocket subprotocols offered by the caller.
  final List<String> protocols;

  /// Settles on termination, including normal completion. Check [isCancelled]
  /// before aborting upstream work; settling normally releases listeners.
  final Future<void> cancelled;
  final bool Function() _isCancelled;

  /// Whether this operation was aborted rather than completed normally.
  bool get isCancelled => _isCancelled();
}

const _version = 1;
const _chunk = 32 * 1024;
const _window = 8;
const _maxActive = 32;
// Real code-server extension-host startup emits a single ~1.4 MiB binary frame.
// Keep a bounded message envelope with room for that state, fragmented below.
const _maxMessage = 4 * 1024 * 1024;
const _maxMeta = 16 * 1024;
const _maxHeaders = 64;
const _openTimeout = Duration(seconds: 15);
const _idleTimeout = Duration(seconds: 30);

bool _canSendCloseCode(int code) =>
    (code >= 1000 &&
        code <= 1014 &&
        code != 1004 &&
        code != 1005 &&
        code != 1006) ||
    (code >= 3000 && code <= 4999);

void _validateUri(Uri uri) {
  if (uri.hasScheme ||
      uri.hasAuthority ||
      uri.hasFragment ||
      !uri.path.startsWith('/') ||
      uri.toString().length > 4096) {
    throw const FormatException('Resource URI must be a bounded absolute path');
  }
}

void _validateHeaders(Map<String, List<String>> headers) {
  if (headers.length > _maxHeaders) {
    throw const FormatException('Too many resource headers');
  }
  var length = 0;
  for (final entry in headers.entries) {
    if (entry.value.length > _maxHeaders ||
        entry.key.isEmpty ||
        entry.key.length > _maxMeta ||
        entry.key.contains(RegExp(r'[^!#$%&\x27*+.^_`|~0-9A-Za-z-]'))) {
      throw const FormatException('Invalid resource header');
    }
    length += entry.key.length;
    for (final value in entry.value) {
      if (value.length > _maxMeta ||
          value.contains(RegExp(r'[\x00-\x1f\x7f]'))) {
        throw const FormatException('Invalid resource header value');
      }
      length += utf8.encode(value).length;
      if (length > _maxMeta) {
        throw const FormatException('Resource headers too large');
      }
    }
  }
  if (length > _maxMeta) {
    throw const FormatException('Resource headers too large');
  }
}

Map<String, List<String>> _parseHeaders(Object? raw) {
  if (raw is! Map || raw.length > _maxHeaders) {
    throw const FormatException('Invalid resource headers');
  }
  final headers = <String, List<String>>{};
  for (final entry in raw.entries) {
    if (entry.key is! String ||
        entry.value is! List ||
        (entry.value as List).length > _maxHeaders ||
        (entry.value as List).any((e) => e is! String)) {
      throw const FormatException('Invalid resource header');
    }
    headers[entry.key as String] = List<String>.from(entry.value as List);
  }
  _validateHeaders(headers);
  return headers;
}

Uint8List _decode(Object? raw) {
  if (raw is! String || raw.length > ((_chunk + 2) ~/ 3) * 4 + 4) {
    throw const FormatException('Resource fragment too large');
  }
  final bytes = base64.decode(raw);
  if (bytes.isEmpty || bytes.length > _chunk) {
    throw const FormatException('Invalid resource fragment');
  }
  return bytes;
}

class _Slot {
  _Slot(this.id, this.owner, this.ws) {
    openTimer = Timer(
      _openTimeout,
      () => owner._cancel(this, TimeoutException('Resource opening timed out')),
    );
    _resetTimer(_idleTimeout);
    if (owner is RemoteResourceClient) {
      // Cancellation can beat the caller's await for headers.
      unawaited(opened.future.then<void>((_) {}, onError: (Object _) {}));
    }
    inbound = StreamController<Uint8List>(
      sync: true,
      onListen: () => _grant(_window),
      onResume: _resume,
      onCancel: () {
        if (!endReceived) {
          owner._cancel(this);
        }
      },
    );
    messages = StreamController<Object>(
      sync: true,
      onListen: () => _grant(_window),
      onResume: _resume,
      onCancel: () {
        if (peerCloseCode == null) {
          owner._cancel(this);
        }
      },
    );
  }

  final int id;
  final _Tunnel owner;
  final bool ws;
  late final StreamController<Uint8List> inbound;
  late final StreamController<Object> messages;
  final Completer<void> cancelled = Completer<void>();
  final Completer<Map<String, dynamic>> opened =
      Completer<Map<String, dynamic>>();
  StreamSubscription<List<int>>? producer;
  StreamSubscription<Object>? wsProducer;
  StreamSubscription<Object>? wsConsumer;
  RemoteResourceResponse? response;
  RemoteResourceSocket? socket;
  BytesBuilder? assembling;
  bool? assemblingText;
  int receivedCredit = 0;
  int sendCredit = 0;
  int queuedMessages = 0;
  int pendingCredit = 0;
  int? peerCloseCode;
  String? peerCloseReason;
  bool terminated = false;
  bool aborted = false;
  bool endReceived = false;
  bool endSent = false;
  bool hasUpload = false;
  Timer? timer;
  late final Timer openTimer;
  Completer<void>? creditWait;
  Future<void> sendQueue = Future<void>.value();
  Future<void> disposal = Future<void>.value();

  void _resetTimer(Duration timeout) {
    timer?.cancel();
    timer = Timer(
      timeout,
      () => owner._cancel(this, TimeoutException('Resource stalled')),
    );
  }

  void touch() => _resetTimer(_idleTimeout);

  void _grant(int count) {
    if (terminated || count == 0) {
      return;
    }
    if (!ws && owner is RemoteResourceServer) {
      openTimer.cancel();
    }
    receivedCredit += count;
    owner._send(this, 'credit', {'n': count});
  }

  void _resume() {
    final n = pendingCredit;
    pendingCredit = 0;
    _grant(n);
  }

  void consume(Uint8List data, {bool? text, bool? last}) {
    if (receivedCredit <= 0 || endReceived) {
      throw const FormatException('Unwindowed resource fragment');
    }
    receivedCredit--;
    if (!ws) {
      if (text != null || last != null) {
        throw const FormatException('Invalid HTTP fragment');
      }
      inbound.add(data);
      if (inbound.isPaused) {
        pendingCredit++;
      } else {
        _grant(1);
      }
      return;
    }
    if (text == null || last == null) {
      throw const FormatException('Invalid websocket fragment');
    }
    if (assembling != null && assemblingText != text) {
      throw const FormatException('Changed websocket message type');
    }
    final builder = assembling ??= BytesBuilder(copy: false);
    assemblingText = text;
    if (builder.length + data.length > _maxMessage) {
      throw const FormatException('Websocket message too large');
    }
    builder.add(data);
    if (last) {
      final bytes = builder.takeBytes();
      assembling = null;
      assemblingText = null;
      messages.add(text ? utf8.decode(bytes) : bytes);
      if (messages.isPaused) {
        pendingCredit++;
      } else {
        _grant(1);
      }
    } else {
      // Fragments are retained in a bounded message, not the listener queue.
      _grant(1);
    }
  }

  Future<void> waitCredit() async {
    while (sendCredit == 0 && !terminated) {
      creditWait ??= Completer<void>();
      await creditWait!.future;
    }
    if (terminated || !owner.channel.isOpen) {
      throw StateError('Resource closed');
    }
    sendCredit--;
  }

  void credit(int count) {
    if (count <= 0 || count > _window || sendCredit + count > _window) {
      throw const FormatException('Invalid resource credit');
    }
    if (!ws && hasUpload) {
      openTimer.cancel();
    }
    sendCredit += count;
    final waiter = creditWait;
    creditWait = null;
    if (waiter != null && !waiter.isCompleted) {
      waiter.complete();
    }
  }

  Future<void> sendBytes(List<int> bytes, {bool? text}) async {
    if (ws && bytes.length > _maxMessage) {
      throw const FormatException('Websocket message too large');
    }
    if (bytes.isEmpty) {
      if (ws) {
        await waitCredit();
        await owner._write(this, 'data', {'b': '', 'text': text, 'last': true});
      }
      return;
    }
    for (var offset = 0; offset < bytes.length; offset += _chunk) {
      await waitCredit();
      final end = (offset + _chunk).clamp(0, bytes.length);
      await owner._write(this, 'data', {
        'b': base64.encode(
          bytes is Uint8List
              ? Uint8List.sublistView(bytes, offset, end)
              : bytes.sublist(offset, end),
        ),
        if (ws) 'text': text,
        if (ws) 'last': end == bytes.length,
      });
    }
  }

  void pump(Stream<List<int>> source) {
    producer = source.listen(
      (bytes) {
        sendQueue = sendQueue.then((_) => sendBytes(bytes));
        // pause reports a rejected resume signal to the zone even when the
        // original future has an observer. Resume with the handled future.
        producer?.pause(
          sendQueue.catchError((Object error) => owner._cancel(this, error)),
        );
      },
      onError: (Object error) => owner._cancel(this, error),
      onDone: () {
        unawaited(
          sendQueue
              .then((_) async {
                if (!terminated && !endSent) {
                  endSent = true;
                  await owner._write(this, 'end');
                  owner._maybeFinish(this);
                }
              })
              .catchError((Object error) => owner._cancel(this, error)),
        );
      },
      cancelOnError: true,
    );
  }

  void dispose(Object? error) {
    if (terminated) {
      return;
    }
    terminated = true;
    openTimer.cancel();
    timer?.cancel();
    if (!cancelled.isCompleted) {
      cancelled.complete();
    }
    final waiter = creditWait;
    creditWait = null;
    if (waiter != null && !waiter.isCompleted) {
      waiter.complete();
    }
    final cleanup = <Future<void>>[];
    void addCleanup(
      Future<void> Function() action, {
      bool socketClose = false,
    }) {
      try {
        final future = action();
        cleanup.add(
          socketClose
              ? future.timeout(const Duration(seconds: 5), onTimeout: () {})
              : future,
        );
      } catch (_) {
        // Teardown is best-effort after the transfer has been removed.
      }
    }

    if (producer case final subscription?) {
      addCleanup(subscription.cancel);
    }
    if (wsProducer != null) {
      try {
        cleanup.add(wsProducer!.cancel());
      } catch (_) {
        // Teardown is best-effort after the transfer has been removed.
      }
    }
    if (wsConsumer != null) {
      try {
        cleanup.add(wsConsumer!.cancel());
      } catch (_) {
        // Teardown is best-effort after the transfer has been removed.
      }
    }
    if (response case final resource?) {
      addCleanup(resource.close);
    }
    if (socket case final webSocket?) {
      addCleanup(
        () => webSocket.close(peerCloseCode ?? 1000, peerCloseReason ?? ''),
        socketClose: true,
      );
    }
    disposal = Future.wait(cleanup).then<void>((_) {}, onError: (Object _) {});
    if (!opened.isCompleted && ownerIsClient) {
      opened.completeError(error ?? StateError('Resource closed'));
    }
    if (error != null) {
      if (inbound.hasListener && !inbound.isClosed) {
        inbound.addError(error);
      }
      if (messages.hasListener && !messages.isClosed) {
        messages.addError(error);
      }
    }
    if (!inbound.isClosed) {
      unawaited(inbound.close());
    }
    if (!messages.isClosed) {
      unawaited(messages.close());
    }
    // Adapter close callbacks were started above, independent of a paused
    // consumer's StreamController.close future.
  }
}

abstract class _Tunnel {
  _Tunnel(this.channel) {
    _incoming = channel.incoming.listen(
      (frame) {
        if (frame['type'] != 'resource') {
          return;
        }
        try {
          _accept(frame);
        } catch (_) {
          // A malformed or unwindowed frame is a fatal authenticated-protocol
          // violation, not an error that can be retried on this secure session.
          unawaited(channel.close());
          unawaited(close());
        }
      },
      onDone: () => unawaited(close()),
      onError: (Object error) => unawaited(close()),
    );
    _state = channel.state.listen((state) {
      if (state == RemoteChannelState.closed) {
        unawaited(close());
      }
    });
  }

  final RemoteRpcChannelPort channel;
  final Map<int, _Slot> slots = {};
  final Map<int, bool> finished = {};
  late final StreamSubscription<Map<String, dynamic>> _incoming;
  late final StreamSubscription<RemoteChannelState> _state;
  int _activeData = 0;
  final List<Completer<void>> _dataWaiters = [];

  Future<void> _acquireData(_Slot slot) async {
    if (_activeData >= _window) {
      final waiter = Completer<void>();
      _dataWaiters.add(waiter);
      await Future.any([waiter.future, slot.cancelled.future]);
      if (!waiter.isCompleted) {
        _dataWaiters.remove(waiter);
        throw StateError('Resource cancelled');
      }
    } else {
      _activeData++;
    }
  }

  void _releaseData() {
    if (_dataWaiters.isNotEmpty) {
      _dataWaiters.removeAt(0).complete(); // Transfer the occupied permit.
    } else {
      _activeData--;
    }
  }

  final Completer<void> _done = Completer<void>();
  bool closed = false;
  Future<void> get done => _done.future;

  void _accept(Map<String, dynamic> frame) {
    if (closed ||
        frame['v'] != _version ||
        frame['id'] is! int ||
        (frame['id'] as int) <= 0 ||
        (frame['id'] as int) > 0x1fffffffffffff ||
        frame['op'] is! String) {
      throw const FormatException('Invalid resource envelope');
    }
    final id = frame['id'] as int;
    final op = frame['op'] as String;
    const common = {'type', 'v', 'id', 'op'};
    final fields = switch (op) {
      'open' => {'method', 'uri', 'headers', 'ws', 'protocols'},
      'headers' => {'status', 'headers', 'protocol'},
      'data' => {'b', 'text', 'last'},
      'credit' => {'n'},
      'cancel' => {'reason'},
      'end' => <String>{},
      'wsClose' => {'code', 'reason'},
      _ => throw const FormatException('Unknown resource operation'),
    };
    if (frame.length > common.length + fields.length ||
        frame.keys.any(
          (key) => !common.contains(key) && !fields.contains(key),
        )) {
      throw const FormatException('Invalid resource frame fields');
    }
    if (op == 'open') {
      _open(id, frame);
      return;
    }
    final slot = slots[id];
    if (slot == null) {
      if (finished[id] == true) {
        return; // In-flight frames after cancellation.
      }
      // Credit and cancellation replies may cross the final HTTP end frame.
      if (finished[id] == false &&
          op == 'credit' &&
          frame['n'] is int &&
          (frame['n'] as int) > 0 &&
          (frame['n'] as int) <= _window) {
        return;
      }
      if (finished[id] == false &&
          op == 'cancel' &&
          frame['reason'] is String &&
          (frame['reason'] as String).length <= 256) {
        return;
      }
      throw const FormatException('Unknown resource ID');
    }
    slot.touch();
    switch (op) {
      case 'headers':
        if (slot.opened.isCompleted ||
            !slot.ownerIsClient ||
            frame['status'] is! int ||
            (frame['status'] as int) < 100 ||
            (frame['status'] as int) > 599) {
          throw const FormatException('Invalid resource response');
        }
        final headers = _parseHeaders(frame['headers']);
        final protocol = frame['protocol'];
        if (slot.ws && (protocol is! String || protocol.length > 128)) {
          throw const FormatException('Invalid websocket protocol');
        }
        slot.openTimer.cancel();
        slot.opened.complete({
          'status': frame['status'],
          'headers': headers,
          'protocol': protocol ?? '',
        });
      case 'credit':
        final n = frame['n'];
        if (n is! int) {
          throw const FormatException('Invalid resource credit');
        }
        slot.credit(n);
      case 'data':
        final text = frame['text'];
        final last = frame['last'];
        if (slot.ws && (text is! bool || last is! bool)) {
          throw const FormatException('Invalid websocket fragment');
        }
        final raw = frame['b'];
        if (slot.ws && raw == '') {
          if (slot.receivedCredit <= 0 || slot.endReceived || last != true) {
            throw const FormatException('Unwindowed websocket message');
          }
          slot.receivedCredit--;
          slot.messages.add(text == true ? '' : Uint8List(0));
          if (slot.messages.isPaused) {
            slot.pendingCredit++;
          } else {
            slot._grant(1);
          }
        } else {
          slot.consume(
            _decode(raw),
            text: slot.ws ? text as bool : null,
            last: slot.ws ? last as bool : null,
          );
        }
      case 'end':
        if (slot.ws || slot.endReceived) {
          throw const FormatException('Invalid resource end');
        }
        slot.endReceived = true;
        if (!slot.inbound.isClosed) {
          unawaited(slot.inbound.close());
        }
        if (!slot.messages.isClosed) {
          unawaited(slot.messages.close());
        }
        _maybeFinish(slot);
      case 'cancel':
        final reason = frame['reason'];
        if (reason is! String || reason.length > 256) {
          throw const FormatException('Invalid resource cancellation');
        }
        _terminate(
          slot,
          StateError(reason.isEmpty ? 'Resource cancelled' : reason),
        );
      case 'wsClose':
        if (!slot.ws ||
            frame['code'] is! int ||
            frame['reason'] is! String ||
            (frame['code'] as int) < 1000 ||
            (frame['code'] as int) > 4999 ||
            (!slot.ownerIsClient && !_canSendCloseCode(frame['code'] as int)) ||
            (frame['reason'] as String).length > 123 ||
            utf8.encode(frame['reason'] as String).length > 123) {
          throw const FormatException('Invalid websocket close');
        }
        slot.peerCloseCode = frame['code'] as int;
        slot.peerCloseReason = frame['reason'] as String;
        slot.socket?.closeCode = slot.peerCloseCode;
        slot.socket?.closeReason = slot.peerCloseReason;
        if (!slot.messages.isClosed) {
          unawaited(slot.messages.close());
        }
        _terminate(slot, null, notify: false);
      default:
        throw const FormatException('Unknown resource operation');
    }
  }

  void _open(int id, Map<String, dynamic> frame);

  Future<void> _write(
    _Slot slot,
    String op, [
    Map<String, dynamic> extra = const {},
  ]) async {
    // A client can release its resources without owning the RPC transport.
    // Keep cancellation writable during teardown so the peer stops its work.
    if ((closed && op != 'cancel') || slot.terminated || !channel.isOpen) {
      throw StateError('Resource channel closed');
    }
    if (op == 'data') {
      await _acquireData(slot);
    }
    try {
      if ((closed && op != 'cancel') || slot.terminated || !channel.isOpen) {
        throw StateError('Resource channel closed');
      }
      slot.touch();
      await channel.send({
        'type': 'resource',
        'v': _version,
        'id': slot.id,
        'op': op,
        ...extra,
      });
    } finally {
      if (op == 'data') {
        _releaseData();
      }
    }
  }

  void _send(_Slot slot, String op, [Map<String, dynamic> extra = const {}]) {
    unawaited(
      _write(
        slot,
        op,
        extra,
      ).catchError((Object error) => _terminate(slot, error)),
    );
  }

  void _maybeFinish(_Slot slot) {
    if (slot.endSent && slot.endReceived) {
      _terminate(slot, null, notify: false);
    }
  }

  void _cancel(_Slot slot, [Object? error]) =>
      _terminate(slot, error ?? StateError('Resource cancelled'));

  void _terminate(_Slot slot, Object? error, {bool notify = true}) {
    if (slot.terminated) {
      return;
    }
    slot.aborted =
        slot.ws || error != null || !slot.endSent || !slot.endReceived;
    if (notify && channel.isOpen) {
      // Control frames do not wait for resource data credit.
      _send(slot, 'cancel', {
        'reason': error.toString().length <= 256
            ? error.toString()
            : 'Resource cancelled',
      });
    }
    slots.remove(slot.id);
    finished[slot.id] = slot.aborted;
    while (finished.length > 1024) {
      finished.remove(finished.keys.first);
    }
    slot.dispose(error);
  }

  Future<void> cancelAll() async {
    final active = slots.values.toList();
    for (final slot in active) {
      _cancel(slot);
    }
    await Future.wait(active.map((slot) => slot.disposal));
  }

  Future<void> close() async {
    if (closed) {
      return done;
    }
    closed = true;
    for (final waiter in _dataWaiters) {
      _activeData++; // Every awakened writer releases this reserved permit.
      waiter.complete();
    }
    _dataWaiters.clear();
    final active = slots.values.toList();
    for (final slot in active) {
      _terminate(slot, StateError('Resource channel closed'));
    }
    await _incoming.cancel();
    await _state.cancel();
    await Future.wait(active.map((slot) => slot.disposal));
    if (!_done.isCompleted) {
      _done.complete();
    }
  }
}

extension on _Slot {
  bool get ownerIsClient => owner is RemoteResourceClient;
}

/// Client-side streams are owned by a single authenticated channel, not a
/// reconnecting supervisor. A replacement session must issue new operations.
class RemoteResourceClient extends _Tunnel implements RemoteResources {
  /// Binds resource work to [channel]; closing this client does not close it.
  RemoteResourceClient(super.channel);
  int _nextId = 0;

  _Slot _create(bool ws) {
    if (closed ||
        !channel.isOpen ||
        slots.length >= _maxActive ||
        _nextId >= 0x1fffffffffffff) {
      throw StateError('Resource channel unavailable or full');
    }
    final slot = _Slot(++_nextId, this, ws);
    slots[slot.id] = slot;
    return slot;
  }

  @override
  Future<RemoteResourceResponse> request(
    String method,
    Uri uri, {
    Map<String, List<String>> headers = const {},
    Stream<List<int>>? body,
  }) async {
    _validateUri(uri);
    _validateHeaders(headers);
    if (!RegExp(r'^[A-Z]+$').hasMatch(method) || method.length > 16) {
      throw const FormatException('Invalid HTTP method');
    }
    final slot = _create(false);
    slot.hasUpload = body != null;
    try {
      await _write(slot, 'open', {
        'method': method,
        'uri': uri.toString(),
        'headers': headers,
        'ws': false,
      });
      if (body == null) {
        slot.endSent = true;
        await _write(slot, 'end');
      } else {
        slot.pump(body);
      }
      final metadata = await slot.opened.future;
      final response = RemoteResourceResponse(
        statusCode: metadata['status'] as int,
        headers: metadata['headers'] as Map<String, List<String>>,
        body: slot.inbound.stream,
        onClose: () async => _cancel(slot),
      );
      return response;
    } catch (error) {
      _cancel(slot, error);
      rethrow;
    }
  }

  @override
  Future<RemoteResourceSocket> connectWebSocket(
    Uri uri, {
    Map<String, List<String>> headers = const {},
    List<String> protocols = const [],
  }) async {
    _validateUri(uri);
    _validateHeaders(headers);
    if (protocols.length > 16 ||
        protocols.any(
          (p) =>
              p.isEmpty ||
              p.length > 128 ||
              p.contains(RegExp(r'[^!#$%&\x27*+.^_`|~0-9A-Za-z-]')),
        )) {
      throw const FormatException('Invalid websocket protocols');
    }
    final slot = _create(true);
    try {
      await _write(slot, 'open', {
        'method': 'GET',
        'uri': uri.toString(),
        'headers': headers,
        'ws': true,
        'protocols': protocols,
      });
      final metadata = await slot.opened.future;
      if (metadata['status'] != 101) {
        throw StateError('Websocket upgrade refused: ${metadata['status']}');
      }
      final selected = metadata['protocol'] as String;
      if (selected.isNotEmpty && !protocols.contains(selected)) {
        throw const FormatException('Unexpected websocket protocol');
      }
      final socket = RemoteResourceSocket(
        incoming: slot.messages.stream,
        protocol: selected,
        onSend: (data) {
          if (data is! String && data is! List<int>) {
            throw ArgumentError.value(data, 'data', 'Expected String or bytes');
          }
          if (slot.terminated) {
            return Future.error(StateError('Websocket closed'));
          }
          if (slot.queuedMessages >= _window) {
            return Future.error(StateError('Websocket send queue full'));
          }
          if (data is String && data.length > _maxMessage) {
            return Future.error(
              const FormatException('Websocket message too large'),
            );
          }
          if (data is List<int> && data.length > _maxMessage) {
            return Future.error(
              const FormatException('Websocket message too large'),
            );
          }
          final bytes = data is String ? utf8.encode(data) : data as List<int>;
          if (bytes.length > _maxMessage) {
            return Future.error(
              const FormatException('Websocket message too large'),
            );
          }
          slot.queuedMessages++;
          final result = slot.sendQueue.then(
            (_) => slot.sendBytes(bytes, text: data is String),
          );
          slot.sendQueue = result.then<void>(
            (_) => slot.queuedMessages--,
            onError: (Object _) => slot.queuedMessages--,
          );
          return result;
        },
        onClose: (code, reason) async {
          if (slot.terminated) {
            return;
          }
          if (!_canSendCloseCode(code) ||
              reason.length > 123 ||
              utf8.encode(reason).length > 123) {
            throw const FormatException('Invalid websocket close');
          }
          // Closing must abort an unsent message even when the peer never
          // grants more data credit. Enqueue control before releasing waiters.
          final sent = _write(slot, 'wsClose', {
            'code': code,
            'reason': reason,
          });
          _terminate(slot, null, notify: false);
          await sent;
        },
      );
      slot.socket = socket;
      return socket;
    } catch (error) {
      _cancel(slot, error);
      rethrow;
    }
  }

  @override
  void _open(int id, Map<String, dynamic> frame) =>
      throw const FormatException('Server-initiated resource');
}

/// Handles resources on the same authenticated channel as the RPC session.
/// [cancelAll] revokes active transfers without disabling later requests.
class RemoteResourceServer extends _Tunnel {
  /// Binds handlers to the authenticated [channel] without owning its closure.
  RemoteResourceServer(
    super.channel, {
    required this.onRequest,
    required this.onWebSocket,
  });

  /// Serves HTTP resource requests, including streamed uploads.
  final Future<RemoteResourceResponse> Function(RemoteResourceRequest)
  onRequest;

  /// Upgrades and serves WebSocket resource requests.
  final Future<RemoteResourceSocket> Function(RemoteResourceRequest)
  onWebSocket;
  int _lastId = 0;

  @override
  void _open(int id, Map<String, dynamic> frame) {
    if (id <= _lastId ||
        slots.length >= _maxActive ||
        frame['ws'] is! bool ||
        frame['method'] is! String ||
        frame['uri'] is! String) {
      throw const FormatException('Invalid resource opening');
    }
    _lastId = id;
    final uri = Uri.parse(frame['uri'] as String);
    _validateUri(uri);
    final headers = _parseHeaders(frame['headers']);
    final method = frame['method'] as String;
    if (!RegExp(r'^[A-Z]+$').hasMatch(method) || method.length > 16) {
      throw const FormatException('Invalid HTTP method');
    }
    final ws = frame['ws'] as bool;
    final rawProtocols = frame['protocols'];
    if (ws &&
        (rawProtocols is! List ||
            rawProtocols.length > 16 ||
            rawProtocols.any(
              (p) =>
                  p is! String ||
                  p.isEmpty ||
                  p.length > 128 ||
                  p.contains(RegExp(r'[^!#$%&\x27*+.^_`|~0-9A-Za-z-]')),
            ))) {
      throw const FormatException('Invalid websocket protocols');
    }
    final slot = _Slot(id, this, ws);
    slots[id] = slot;
    final request = RemoteResourceRequest(
      method: method,
      uri: uri,
      headers: headers,
      body: slot.inbound.stream,
      protocols: ws ? List<String>.from(rawProtocols as List) : const [],
      cancelled: slot.cancelled.future,
      isCancelled: () => slot.aborted,
    );
    unawaited(_serve(slot, request));
  }

  Future<void> _serve(_Slot slot, RemoteResourceRequest request) async {
    try {
      if (slot.ws) {
        final socket = await onWebSocket(request);
        if (slot.terminated) {
          await socket.close();
          return;
        }
        slot.socket = socket;
        if (socket.protocol.length > 128 ||
            (socket.protocol.isNotEmpty &&
                !request.protocols.contains(socket.protocol))) {
          throw const FormatException('Invalid selected websocket protocol');
        }
        slot.openTimer.cancel();
        await _write(slot, 'headers', {
          'status': 101,
          'headers': <String, List<String>>{},
          'protocol': socket.protocol,
        });
        slot.wsConsumer = slot.messages.stream.listen(
          (message) {
            try {
              final send = socket.send(message);
              slot.wsConsumer?.pause(
                send.catchError((Object error) => _cancel(slot, error)),
              );
            } catch (error) {
              _cancel(slot, error);
            }
          },
          onError: (Object error) => _cancel(slot, error),
          cancelOnError: true,
        );
        slot.wsProducer = socket.incoming.listen(
          (message) {
            if (message is! String && message is! List<int>) {
              _cancel(slot, StateError('Invalid websocket message'));
              return;
            }
            if ((message is String && message.length > _maxMessage) ||
                (message is List<int> && message.length > _maxMessage)) {
              _cancel(
                slot,
                const FormatException('Websocket message too large'),
              );
              return;
            }
            final bytes = message is String
                ? utf8.encode(message)
                : message as List<int>;
            slot.sendQueue = slot.sendQueue.then(
              (_) => slot.sendBytes(bytes, text: message is String),
            );
            slot.wsProducer?.pause(
              slot.sendQueue.catchError((Object error) => _cancel(slot, error)),
            );
          },
          onDone: () async {
            if (slot.terminated) {
              return;
            }
            try {
              await slot.sendQueue;
              if (slot.terminated) {
                return;
              }
              await _write(slot, 'wsClose', {
                'code': socket.closeCode ?? 1000,
                'reason': socket.closeReason ?? '',
              });
              _terminate(slot, null, notify: false);
            } catch (error) {
              _cancel(slot, error);
            }
          },
          onError: (Object error) => _cancel(slot, error),
          cancelOnError: true,
        );
      } else {
        final response = await onRequest(request);
        if (slot.terminated) {
          await response.close();
          return;
        }
        slot.response = response;
        _validateHeaders(response.headers);
        slot.openTimer.cancel();
        await _write(slot, 'headers', {
          'status': response.statusCode,
          'headers': response.headers,
        });
        slot.pump(response.body);
      }
    } catch (error) {
      _cancel(slot, error);
    }
  }
}
