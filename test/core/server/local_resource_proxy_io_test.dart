import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/server/client_resource_proxy.dart';
import 'package:test/test.dart';

class _Resources implements RemoteResources {
  final requests = <Uri>[];
  final uploads = <int>[];
  int aborts = 0;

  @override
  Future<RemoteResourceResponse> request(
    String method,
    Uri uri, {
    Map<String, List<String>> headers = const {},
    Stream<List<int>>? body,
  }) async {
    requests.add(uri);
    if (body != null) {
      await for (final chunk in body) {
        uploads.addAll(chunk);
      }
    }
    return RemoteResourceResponse(
      statusCode: headers['range']?.first == 'bytes=2-4' ? 206 : 200,
      headers: {
        'content-type': ['application/octet-stream'],
        'content-range': ['bytes 2-4/10'],
        'content-length': ['3'],
      },
      body: Stream.value(Uint8List.fromList([2, 3, 4])),
      onClose: () async {
        aborts++;
      },
    );
  }

  @override
  Future<RemoteResourceSocket> connectWebSocket(
    Uri uri, {
    Map<String, List<String>> headers = const {},
    List<String> protocols = const [],
  }) async {
    final incoming = StreamController<Object>();
    return RemoteResourceSocket(
      incoming: incoming.stream,
      protocol: protocols.firstOrNull ?? '',
      onSend: (message) async {
        incoming.add(message);
      },
      onClose: (code, reason) async {
        await incoming.close();
      },
    );
  }
}

class _ClosingResources extends _Resources {
  _ClosingResources({this.rejectSends = false});
  final bool rejectSends;
  final closed = StreamController<(int, String)>.broadcast();
  final closeCalls = <(int, String)>[];

  @override
  Future<RemoteResourceSocket> connectWebSocket(
    Uri uri, {
    Map<String, List<String>> headers = const {},
    List<String> protocols = const [],
  }) async {
    final incoming = StreamController<Object>();
    return RemoteResourceSocket(
      incoming: incoming.stream,
      protocol: '',
      onSend: (_) async {
        if (rejectSends) {
          throw StateError('Encrypted channel rejected the send');
        }
      },
      onClose: (code, reason) async {
        closeCalls.add((code, reason));
        closed.add((code, reason));
        await incoming.close();
      },
    );
  }
}

class _PeerClosingResources extends _Resources {
  final connected = StreamController<StreamController<Object>>.broadcast();
  final closeCalls = <(int, String)>[];
  int closeCode = 4003;
  String closeReason = 'upstream';

  @override
  Future<RemoteResourceSocket> connectWebSocket(
    Uri uri, {
    Map<String, List<String>> headers = const {},
    List<String> protocols = const [],
  }) async {
    final incoming = StreamController<Object>();
    connected.add(incoming);
    return RemoteResourceSocket(
      incoming: incoming.stream,
      protocol: '',
      onSend: (_) async {},
      onClose: (code, reason) async {
        closeCalls.add((code, reason));
        await incoming.close();
      },
      readCloseCode: () => closeCode,
      readCloseReason: () => closeReason,
    );
  }
}

class _HtmlResources extends _Resources {
  @override
  Future<RemoteResourceResponse> request(
    String method,
    Uri uri, {
    Map<String, List<String>> headers = const {},
    Stream<List<int>>? body,
  }) async {
    requests.add(uri);
    if (uri.path.endsWith('/redirect')) {
      return RemoteResourceResponse(
        statusCode: 302,
        headers: {
          'location': ['/proxy/vscode/session/'],
        },
        body: const Stream.empty(),
      );
    }
    if (uri.path.endsWith('/external')) {
      return RemoteResourceResponse(
        statusCode: 302,
        headers: {
          'location': ['https://server.example/private'],
        },
        body: const Stream.empty(),
      );
    }
    if (uri.path.endsWith('/html-nonce')) {
      return RemoteResourceResponse(
        statusCode: 200,
        headers: {
          'content-type': ['text/html; charset=utf-8'],
        },
        body: Stream.fromIterable([
          Uint8List.fromList('<html><head><scr'.codeUnits),
          Uint8List.fromList(
            'ipt nonce="SGVhZE5vbmNl" src="/app.js"></script></head></html>'
                .codeUnits,
          ),
        ]),
      );
    }
    return RemoteResourceResponse(
      statusCode: 200,
      headers: {
        'content-type': ['text/html; charset=utf-8'],
        'content-security-policy': [
          "script-src 'nonce-UHJveHlOb25jZQ==' 'strict-dynamic'",
        ],
      },
      body: Stream.value(
        Uint8List.fromList(
          '<!doctype html><html><head><title>Code</title></head><body>ok</body></html>'
              .codeUnits,
        ),
      ),
    );
  }
}

class _StreamingFailureResources extends _Resources {
  _StreamingFailureResources({required this.knownLength});
  final bool knownLength;
  @override
  Future<RemoteResourceResponse> request(
    String method,
    Uri uri, {
    Map<String, List<String>> headers = const {},
    Stream<List<int>>? body,
  }) async {
    requests.add(uri);
    Stream<Uint8List> interruptedBody() async* {
      yield Uint8List.fromList([7]);
      throw StateError('upstream stopped');
    }

    return RemoteResourceResponse(
      statusCode: 200,
      headers: {
        if (knownLength) 'content-length': ['2'],
      },
      body: interruptedBody(),
    );
  }
}

class _IdleResources extends _Resources {
  final body = StreamController<Uint8List>();
  final closed = Completer<void>();

  @override
  Future<RemoteResourceResponse> request(
    String method,
    Uri uri, {
    Map<String, List<String>> headers = const {},
    Stream<List<int>>? body,
  }) async {
    return RemoteResourceResponse(
      statusCode: 200,
      headers: {
        'content-type': ['application/octet-stream'],
      },
      body: this.body.stream,
      onClose: () async {
        if (!closed.isCompleted) {
          closed.complete();
        }
        await this.body.close();
      },
    );
  }
}

void main() {
  test(
    'loopback facade preserves Range, query, upload bytes, and the local capability',
    () async {
      final resources = _Resources();
      final facade = await createClientResourceProxy(() => resources);
      addTearDown(facade.close);
      final base = facade.baseUri;
      expect(base.host, '127.0.0.1');
      expect(base.path, startsWith('/_cc_resource/'));
      final client = HttpClient();
      addTearDown(client.close);
      final route = base.replace(
        path: '${base.path}blob',
        query: 'w=one%2Ftwo',
      );
      final request = await client.postUrl(route);
      request.headers.set(HttpHeaders.rangeHeader, 'bytes=2-4');
      request.add([9, 8, 7]);
      final response = await request.close();
      expect(response.statusCode, 206);
      expect(response.headers.contentLength, 3);
      expect(
        response.headers.value(HttpHeaders.contentRangeHeader),
        'bytes 2-4/10',
      );
      expect(await response.expand((bytes) => bytes).toList(), [2, 3, 4]);
      expect(response.headers.value('x-frame-options'), 'SAMEORIGIN');
      expect(resources.requests.single.toString(), '/blob?w=one%2Ftwo');
      expect(resources.uploads, [9, 8, 7]);
      expect(resources.aborts, 1);

      final missing = await (await client.getUrl(
        base.replace(path: '/blob'),
      )).close();
      expect(missing.statusCode, 404);
      expect(resources.requests.length, 1);
      final forged = await client.getUrl(route);
      forged.headers.set(HttpHeaders.hostHeader, 'evil.example');
      expect((await forged.close()).statusCode, 404);
      expect(resources.requests.length, 1);

      final wrongOrigin = await client.getUrl(route);
      wrongOrigin.headers.set('origin', 'http://evil.example');
      expect((await wrongOrigin.close()).statusCode, 404);
      expect(resources.requests.length, 1);
    },
  );

  test(
    'native HEAD preserves length without consuming a response body',
    () async {
      final facade = await createClientResourceProxy(_Resources.new);
      addTearDown(facade.close);
      final client = HttpClient();
      addTearDown(client.close);
      final response = await (await client.openUrl(
        'HEAD',
        facade.baseUri.resolve('blob'),
      )).close();
      expect(response.statusCode, 200);
      expect(response.headers.contentLength, 3);
      expect(await response.expand((chunk) => chunk).toList(), isEmpty);
    },
  );

  test(
    'native facade cancels a stalled download when its client disconnects',
    () async {
      final resources = _IdleResources();
      final facade = await createClientResourceProxy(() => resources);
      addTearDown(facade.close);
      final client = HttpClient();
      final response = await (await client.getUrl(
        facade.baseUri.resolve('blob'),
      )).close();
      final subscription = response.listen((_) {}, onError: (Object _) {});
      client.close(force: true);
      await subscription.cancel();
      await resources.closed.future.timeout(const Duration(seconds: 5));
    },
  );

  for (final knownLength in [false, true]) {
    test(
      'interrupted ${knownLength ? 'fixed-length' : 'chunked'} body fails after headers',
      () async {
        final resources = _StreamingFailureResources(knownLength: knownLength);
        final facade = await createClientResourceProxy(() => resources);
        addTearDown(facade.close);
        final client = HttpClient();
        addTearDown(client.close);
        final response = await (await client.getUrl(
          facade.baseUri.resolve('blob'),
        )).close();
        expect(response.statusCode, 200);
        await expectLater(
          response.drain<void>(),
          throwsA(isA<HttpException>()),
        );
      },
    );
  }
  test('native WebSocket without a status closes its resource once', () async {
    final resources = _ClosingResources();
    final facade = await createClientResourceProxy(() => resources);
    addTearDown(facade.close);
    final closed = resources.closed.stream.first;
    final socket = await WebSocket.connect(
      facade.baseUri
          .resolve('proxy/vscode/session/ws')
          .replace(scheme: 'ws')
          .toString(),
    );
    final ended = socket.drain<void>();
    await socket.close();
    expect(await closed.timeout(const Duration(seconds: 5)), (1000, ''));
    await ended;
    expect(resources.closeCalls, [(1000, '')]);
  });

  test(
    'native WebSocket reports a rejected encrypted send as a failure',
    () async {
      final resources = _ClosingResources(rejectSends: true);
      final facade = await createClientResourceProxy(() => resources);
      addTearDown(facade.close);
      final socket = await WebSocket.connect(
        facade.baseUri
            .resolve('proxy/vscode/session/ws')
            .replace(scheme: 'ws')
            .toString(),
      );
      addTearDown(socket.close);
      final ended = socket.drain<void>();
      socket.add('keystroke');
      await ended.timeout(const Duration(seconds: 5));
      expect(socket.closeCode, WebSocketStatus.internalServerError);
      expect(
        resources.closeCalls.single.$1,
        WebSocketStatus.internalServerError,
      );
    },
  );

  test(
    'native WebSocket forwards valid application closes unchanged',
    () async {
      final resources = _ClosingResources();
      final facade = await createClientResourceProxy(() => resources);
      addTearDown(facade.close);
      final url = facade.baseUri
          .resolve('proxy/vscode/session/ws')
          .replace(scheme: 'ws')
          .toString();
      for (final code in [4001, 4002]) {
        final close = resources.closed.stream.first;
        final socket = await WebSocket.connect(url);
        await socket.close(code, 'application');
        expect(await close.timeout(const Duration(seconds: 5)), (
          code,
          'application',
        ));
      }
      expect(resources.closeCalls, [
        (4001, 'application'),
        (4002, 'application'),
      ]);
    },
  );
  test(
    'native WebSocket forwards upstream close metadata without replying twice',
    () async {
      final resources = _PeerClosingResources();
      final facade = await createClientResourceProxy(() => resources);
      addTearDown(facade.close);
      final url = facade.baseUri
          .resolve('proxy/vscode/session/ws')
          .replace(scheme: 'ws')
          .toString();
      for (final (code, reason, expected) in [
        (4003, 'upstream', 4003),
        (1006, 'abnormal', WebSocketStatus.internalServerError),
      ]) {
        resources.closeCode = code;
        resources.closeReason = reason;
        final connected = resources.connected.stream.first;
        final socket = await WebSocket.connect(url);
        addTearDown(socket.close);
        final incoming = await connected;
        await incoming.close();
        await socket.drain<void>();
        expect(socket.closeCode, expected);
        expect(socket.closeReason, reason);
        expect(resources.closeCalls, isEmpty);
      }
    },
  );

  test(
    'native WebSocket keeps negotiated protocol and text/binary distinction',
    () async {
      final resources = _Resources();
      final facade = await createClientResourceProxy(() => resources);
      addTearDown(facade.close);
      final base = facade.baseUri;
      final ws = await WebSocket.connect(
        base
            .replace(scheme: 'ws', path: '${base.path}proxy/vscode/session/ws')
            .toString(),
        protocols: ['code-server'],
      );
      expect(ws.protocol, 'code-server');
      ws.add('hello');
      ws.add(Uint8List.fromList([0, 1, 2]));
      final received = await ws.take(2).toList();
      expect(received[0], 'hello');
      expect(received[1], [0, 1, 2]);
      await ws.close();
    },
  );
  test(
    'native code-server HTML installs shim before app scripts and keeps redirects local',
    () async {
      final resources = _HtmlResources();
      final facade = await createClientResourceProxy(() => resources);
      addTearDown(facade.close);
      final client = HttpClient();
      addTearDown(client.close);
      final base = facade.baseUri;
      final page = base.replace(path: '${base.path}proxy/vscode/session/');
      final html = await (await client.getUrl(page)).close();
      final text = await utf8.decoder.bind(html).join();
      expect(
        text,
        contains(
          '<head><script nonce="UHJveHlOb25jZQ==" '
          'src="${base.path}_cc_native_ws_shim.js"></script>',
        ),
      );
      expect(html.headers.value('x-frame-options'), isNull);
      expect(html.headers.value(HttpHeaders.cacheControlHeader), 'no-store');

      final asset = await client.getUrl(
        base.replace(path: '/static/workbench.js'),
      );
      asset.headers.set(HttpHeaders.refererHeader, page.toString());
      expect((await asset.close()).statusCode, 200);
      expect(
        resources.requests.last.path,
        '/proxy/vscode/session/static/workbench.js',
      );

      final redirect = await client.getUrl(
        base.replace(path: '${base.path}proxy/vscode/session/redirect'),
      );
      redirect.followRedirects = false;
      final moved = await redirect.close();
      expect(moved.headers.value(HttpHeaders.locationHeader), page.toString());

      final outside = await client.getUrl(
        base.replace(path: '${base.path}proxy/vscode/session/external'),
      );
      outside.followRedirects = false;
      expect((await outside.close()).statusCode, 502);
    },
  );
  test(
    'native HTML shim reuses the first script nonce across chunks',
    () async {
      final resources = _HtmlResources();
      final facade = await createClientResourceProxy(() => resources);
      addTearDown(facade.close);
      final client = HttpClient();
      addTearDown(client.close);
      final page = facade.baseUri.resolve('proxy/vscode/session/html-nonce');
      final html = await (await client.getUrl(page)).close();
      final text = await utf8.decoder.bind(html).join();
      expect(
        text,
        contains(
          '<head><script nonce="SGVhZE5vbmNl" '
          'src="${facade.baseUri.path}_cc_native_ws_shim.js"></script>'
          '<script nonce="SGVhZE5vbmNl" src="/app.js">',
        ),
      );
      expect(html.headers.value('x-frame-options'), isNull);
    },
  );
}
