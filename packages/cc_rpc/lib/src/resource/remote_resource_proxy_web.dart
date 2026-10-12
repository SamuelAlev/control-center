import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import '../resources/resource_tunnel.dart';
import 'local_resource_proxy.dart';

@JS('ccResourceBridge')
external _ResourceBridge get _bridge;

extension type _ResourceBridge(JSObject _) implements JSObject {
  external JSPromise<JSString> open(JSFunction callback);
  external void close(JSString token);
  external void onPort(JSObject port, JSFunction callback);
  external void send(JSObject port, JSString metadata, [JSUint8Array? bytes]);
  external void release(JSObject port);
}

Future<LocalResourceProxy> createLocalResourceProxy(
  RemoteResources Function() resources,
) async {
  final proxy = _BrowserResourceProxy(resources);
  await proxy.start();
  return proxy;
}

class _BrowserResourceProxy implements LocalResourceProxy {
  _BrowserResourceProxy(this._resources);

  final RemoteResources Function() _resources;
  final Set<Future<void> Function()> _active = {};
  late Uri _baseUri;
  late JSFunction _listener;
  bool _closed = false;

  @override
  Uri get baseUri => _baseUri;

  Future<void> start() async {
    _listener = ((JSString raw, JSObject port) {
      if (_closed) {
        _bridge.release(port);
        return;
      }
      final meta = jsonDecode(raw.toDart) as Map<String, dynamic>;
      switch (meta['kind']) {
        case 'http':
          unawaited(_serveHttp(meta, port));
        case 'socket':
          unawaited(_serveSocket(meta, port));
        default:
          _bridge.release(port);
      }
    }).toJS;
    _baseUri = Uri.parse((await _bridge.open(_listener).toDart).toDart);
  }

  void _send(JSObject port, Map<String, Object?> message, [Uint8List? bytes]) =>
      _bridge.send(port, jsonEncode(message).toJS, bytes?.toJS);

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _bridge.close(
      _baseUri.pathSegments.where((part) => part.isNotEmpty).last.toJS,
    );
    await Future.wait([for (final cancel in _active.toList()) cancel()]);
    _active.clear();
  }

  Uri _path(Map<String, dynamic> meta) {
    final raw = meta['path'];
    if (raw is! String ||
        raw.length > 4096 ||
        !raw.startsWith('/') ||
        raw.contains('#') ||
        Uri.parse(raw).hasAuthority) {
      throw const FormatException('Invalid local resource route');
    }
    return Uri.parse(raw);
  }

  Map<String, List<String>> _headers(Map<String, dynamic> meta) {
    final raw = meta['headers'];
    if (raw is! Map || raw.length > 64)
      throw const FormatException('Invalid headers');
    return raw.map(
      (key, value) => MapEntry(
        key.toString(),
        (value as List).map((v) => v as String).toList(),
      ),
    );
  }

  Future<void> _serveHttp(Map<String, dynamic> meta, JSObject port) async {
    RemoteResourceResponse? upstream;
    StreamController<List<int>>? upload;
    StreamIterator<Uint8List>? output;
    Completer<void>? credit;
    var stopped = false;
    Future<void> cancel() async {
      if (stopped) return;
      stopped = true;
      if (credit != null && !credit.isCompleted) credit.complete();
      await output?.cancel();
      if (upload != null) unawaited(upload.close());
      await upstream?.close();
      _bridge.release(port);
    }

    _active.add(cancel);
    try {
      final body = meta['hasBody'] == true;
      if (body) {
        upload = StreamController<List<int>>(
          sync: true,
          onListen: () {
            if (!stopped) _send(port, {'kind': 'uploadCredit'});
          },
          onResume: () {
            if (!stopped) _send(port, {'kind': 'uploadCredit'});
          },
        );
      }
      _bridge.onPort(
        port,
        ((JSString raw, JSUint8Array? bytes) {
          if (stopped) return;
          final frame = jsonDecode(raw.toDart) as Map<String, dynamic>;
          switch (frame['kind']) {
            case 'uploadData':
              if (upload != null && bytes != null) {
                upload.add(bytes.toDart);
                if (upload.hasListener && !upload.isPaused) {
                  _send(port, {'kind': 'uploadCredit'});
                }
              }
            case 'uploadEnd':
              unawaited(upload?.close() ?? Future<void>.value());
            case 'credit':
              if (credit != null && !credit.isCompleted) credit.complete();
            case 'cancel':
              unawaited(cancel());
          }
        }).toJS,
      );
      upstream = await _resources().request(
        meta['method'] as String,
        _path(meta),
        headers: _headers(meta),
        body: upload?.stream,
      );
      if (stopped) {
        await upstream.close();
        return;
      }
      _send(port, {
        'kind': 'headers',
        'status': upstream.statusCode,
        'headers': upstream.headers,
      });
      output = StreamIterator(upstream.body);
      while (!stopped) {
        credit = Completer<void>();
        await credit.future;
        if (stopped) break;
        if (!await output.moveNext()) {
          _send(port, {'kind': 'end'});
          break;
        }
        _send(port, {'kind': 'data'}, output.current);
      }
    } catch (_) {
      if (!stopped) _send(port, {'kind': 'error'});
    } finally {
      await cancel();
      _active.remove(cancel);
    }
  }

  Future<void> _serveSocket(Map<String, dynamic> meta, JSObject port) async {
    RemoteResourceSocket? remote;
    var stopped = false;
    Future<void> cancel([
      int code = 1000,
      String reason = '',
      bool notify = false,
    ]) async {
      if (stopped) return;
      stopped = true;
      try {
        await remote?.close(code, reason);
        if (notify)
          _send(port, {'kind': 'closed', 'code': code, 'reason': reason});
      } finally {
        _bridge.release(port);
      }
    }

    Future<void> stop() => cancel(1001, 'Session closed', true);
    _active.add(stop);
    try {
      remote = await _resources().connectWebSocket(
        _path(meta),
        protocols: (meta['protocols'] as List).cast<String>(),
      );
      if (stopped) {
        await remote.close();
        return;
      }
      _bridge.onPort(
        port,
        ((JSString raw, JSUint8Array? bytes) {
          if (stopped) return;
          final frame = jsonDecode(raw.toDart) as Map<String, dynamic>;
          if (frame['kind'] == 'send') {
            final Object data = bytes?.toDart ?? frame['text'] as String;
            unawaited(
              remote!
                  .send(data)
                  .catchError((Object _) => cancel(1011, '', true)),
            );
          } else if (frame['kind'] == 'close') {
            unawaited(
              cancel(
                frame['code'] as int? ?? 1000,
                frame['reason'] as String? ?? '',
                true,
              ),
            );
          }
        }).toJS,
      );
      _send(port, {'kind': 'open', 'protocol': remote.protocol});
      await for (final message in remote.incoming) {
        if (stopped) break;
        if (message is String) {
          _send(port, {'kind': 'message', 'text': message});
        } else if (message is Uint8List) {
          _send(port, {'kind': 'message'}, message);
        }
      }
      if (!stopped)
        _send(port, {
          'kind': 'closed',
          'code': remote.closeCode ?? 1000,
          'reason': remote.closeReason ?? '',
        });
    } catch (_) {
      if (!stopped) _send(port, {'kind': 'error'});
      if (!stopped) _send(port, {'kind': 'closed', 'code': 1011, 'reason': ''});
    } finally {
      await cancel();
      _active.remove(stop);
    }
  }
}
