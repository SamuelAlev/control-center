// The two non-Chromium engine clients, against fake endpoints.
//
// A rig cannot be booted in CI, so these pin the parts that are protocol
// rather than browser: the handshake Firefox refuses without, the request
// shape classic WebDriver refuses with, and the two history models that stand
// in for reachability neither protocol reports. Each one here corresponds to a
// failure that produced a rig which connected and then did nothing.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/rigs/domain/value_objects/rig_browser_engine.dart';
import 'package:cc_infra/src/rigs/bidi_client.dart';
import 'package:cc_infra/src/rigs/browser_engine_client.dart';
import 'package:cc_infra/src/rigs/webdriver_client.dart';
import 'package:test/test.dart';

/// A stand-in for Firefox's remote agent: one WebSocket, BiDi framing, and
/// the Host-header check that is the whole reason the client sends one.
class _FakeBidiAgent {
  _FakeBidiAgent({this.requiredHost});

  /// The `Host` the agent will accept, or null to accept anything.
  final String? requiredHost;

  HttpServer? _server;
  WebSocket? _socket;

  /// Every command the client sent, in order.
  final List<Map<String, dynamic>> received = [];

  /// Per-method canned results, consulted before the defaults.
  final Map<String, Map<String, dynamic>> results = {};

  /// Per-method canned errors: method → (error token, message).
  final Map<String, (String, String)> errors = {};

  /// Host-header values the agent rejected.
  final List<String> rejectedHosts = [];

  int get port => _server!.port;

  Future<void> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server = server;
    unawaited(
      server.forEach((request) async {
        final host = request.headers.value(HttpHeaders.hostHeader);
        if (requiredHost != null && host != requiredHost) {
          // Exactly what Firefox does: a bare 400, no explanation, no clue
          // that the PORT is what it disliked.
          rejectedHosts.add(host ?? '<none>');
          request.response.statusCode = HttpStatus.badRequest;
          await request.response.close();
          return;
        }
        // Closed with the fake in `stop()`.
        // ignore: close_sinks
        final socket = await WebSocketTransformer.upgrade(request);
        _socket = socket;
        socket.listen((raw) {
          final message = (jsonDecode(raw as String) as Map)
              .cast<String, dynamic>();
          received.add(message);
          final method = message['method'] as String;
          final id = message['id'];
          final failure = errors[method];
          if (failure != null) {
            socket.add(
              jsonEncode({
                'type': 'error',
                'id': id,
                'error': failure.$1,
                'message': failure.$2,
              }),
            );
            return;
          }
          socket.add(
            jsonEncode({
              'type': 'success',
              'id': id,
              'result': results[method] ?? _defaultResult(method),
            }),
          );
        });
      }),
    );
  }

  Map<String, dynamic> _defaultResult(String method) => switch (method) {
    'session.new' => {'sessionId': 's1'},
    'browsingContext.getTree' => {
      'contexts': [
        {'context': 'ctx-1', 'url': 'https://example.test/'},
      ],
    },
    'browsingContext.captureScreenshot' => {'data': 'AAAA'},
    'script.evaluate' => {
      'type': 'success',
      'result': {'type': 'string', 'value': '{"ok":true}'},
    },
    _ => <String, dynamic>{},
  };

  /// Pushes an unsolicited event, as the real agent does.
  void emit(String method, Map<String, dynamic> params) {
    _socket?.add(
      jsonEncode({'type': 'event', 'method': method, 'params': params}),
    );
  }

  /// The params of the last call to [method].
  Map<String, dynamic> paramsOf(String method) =>
      (received.lastWhere((m) => m['method'] == method)['params'] as Map)
          .cast<String, dynamic>();

  bool sent(String method) => received.any((m) => m['method'] == method);

  Future<void> stop() async {
    await _socket?.close();
    await _server?.close(force: true);
  }
}

/// A stand-in for `WebKitWebDriver`: classic WebDriver framing, and a record
/// of whether each request carried a body.
class _FakeWebDriver {
  HttpServer? _server;

  /// Every request, as (method, path, body-or-null).
  final List<(String, String, String?)> received = [];

  /// Per-path canned values, keyed `METHOD path`.
  final Map<String, Object?> values = {};

  /// The URL `GET /url` reports, mutated by the fake's own navigations.
  String url = 'about:blank';

  int get port => _server!.port;

  Future<void> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server = server;
    unawaited(
      server.forEach((request) async {
        final body = await utf8.decoder.bind(request).join();
        final path = request.uri.path;
        received.add((request.method, path, body.isEmpty ? null : body));
        Object? value;
        if (path == '/session' && request.method == 'POST') {
          value = {'sessionId': 'wd-1', 'capabilities': <String, dynamic>{}};
        } else if (path.endsWith('/url') && request.method == 'GET') {
          value = url;
        } else if (path.endsWith('/url') && request.method == 'POST') {
          url = (jsonDecode(body) as Map)['url'] as String;
        } else if (path.endsWith('/back')) {
          url = 'about:blank';
        } else if (path.endsWith('/element')) {
          value = {'element-6066-11e4-a52e-4f735466cecc': 'el-1'};
        } else {
          value = values['${request.method} $path'];
        }
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({'value': value}));
        await request.response.close();
      }),
    );
  }

  /// Requests whose path ends with `suffix` and that carried a body.
  Iterable<(String, String, String?)> bodied(String suffix) =>
      received.where((r) => r.$2.endsWith(suffix) && r.$3 != null);

  Future<void> stop() async => _server?.close(force: true);
}

void main() {
  group('BidiClient', () {
    late _FakeBidiAgent agent;

    tearDown(() async => agent.stop());

    test('sends the Host the agent believes it serves, not the one it '
        'dialled', () async {
      // The measured failure: Firefox rejects an upgrade whose Host names any
      // port but its own, with a bare 400 and no diagnostic. Every Firefox rig
      // failed to attach until the client sent the GUEST-side authority.
      agent = _FakeBidiAgent();
      await agent.start();
      final client = await BidiClient.attach(
        host: '127.0.0.1',
        port: agent.port,
        guestPort: 9223,
      );
      expect(client.hostAuthority, '127.0.0.1:9223');
      expect(client.engine, RigBrowserEngine.firefox);
      await client.close();
    });

    test(
      'an agent that only accepts its own Host still gets a session',
      () async {
        agent = _FakeBidiAgent(requiredHost: '127.0.0.1:9223');
        await agent.start();
        final client = await BidiClient.attach(
          host: '127.0.0.1',
          port: agent.port,
          guestPort: 9223,
          timeout: const Duration(seconds: 5),
        );
        expect(agent.rejectedHosts, isEmpty);
        expect(agent.sent('session.new'), isTrue);
        expect(agent.sent('browsingContext.getTree'), isTrue);
        expect(agent.sent('session.subscribe'), isTrue);
        await client.close();
      },
    );

    test('a mismatched Host fails with a message naming the cause', () async {
      agent = _FakeBidiAgent(requiredHost: '127.0.0.1:9999');
      await agent.start();
      await expectLater(
        BidiClient.attach(
          host: '127.0.0.1',
          port: agent.port,
          guestPort: 9223,
          timeout: const Duration(seconds: 2),
        ),
        throwsA(
          isA<BidiException>().having(
            (e) => e.message,
            'message',
            allOf(contains('Host: 127.0.0.1:9223'), contains('BiDi')),
          ),
        ),
      );
      expect(agent.rejectedHosts, isNotEmpty);
    });

    test('reload never sends ignoreCache, even when a hard reload is asked '
        'for', () async {
      // Firefox rejects the argument outright ("not supported yet"), which
      // fails the whole command — so a hard reload is a normal reload here,
      // and sending the flag conditionally would only make it fail sometimes.
      agent = _FakeBidiAgent();
      await agent.start();
      final client = await BidiClient.attach(
        host: '127.0.0.1',
        port: agent.port,
        guestPort: 9223,
      );
      await client.reload(ignoreCache: true);
      expect(
        agent.paramsOf('browsingContext.reload'),
        isNot(contains('ignoreCache')),
      );
      expect(agent.paramsOf('browsingContext.reload')['wait'], 'complete');
      await client.close();
    });

    test('screenshots ask for JPEG with a fractional quality', () async {
      agent = _FakeBidiAgent();
      await agent.start();
      final client = await BidiClient.attach(
        host: '127.0.0.1',
        port: agent.port,
        guestPort: 9223,
      );
      await client.captureScreenshot(quality: 60);
      final format =
          agent.paramsOf('browsingContext.captureScreenshot')['format']
              as Map<String, dynamic>;
      expect(format['type'], 'image/jpeg');
      // BiDi takes 0..1, unlike CDP's 1..100. Sending 60 asks for a quality
      // above the maximum and the command fails.
      expect(format['quality'], closeTo(0.6, 0.001));
      await client.close();
    });

    test('history reachability follows what the engine actually did', () async {
      agent = _FakeBidiAgent();
      await agent.start();
      final client = await BidiClient.attach(
        host: '127.0.0.1',
        port: agent.port,
        guestPort: 9223,
      );
      // Nothing has been visited: back is not on offer.
      expect((await client.navigationState()).canGoBack, isFalse);

      agent.emit('browsingContext.load', {
        'context': 'ctx-1',
        'url': 'https://example.test/one',
      });
      agent.emit('browsingContext.load', {
        'context': 'ctx-1',
        'url': 'https://example.test/two',
      });
      await Future<void>.delayed(const Duration(milliseconds: 50));
      var state = await client.navigationState();
      expect(state.canGoBack, isTrue);
      expect(state.canGoForward, isFalse);

      expect(await client.goHistory(-1), isTrue);
      state = await client.navigationState();
      expect(state.canGoForward, isTrue);

      // The engine is authoritative at the end of the history, and its
      // refusal corrects the model rather than being reported as a move.
      agent.errors['browsingContext.traverseHistory'] = (
        'no such history entry',
        'History entry with delta -5 not found',
      );
      expect(await client.goHistory(-5), isFalse);
      expect((await client.navigationState()).canGoBack, isFalse);
      await client.close();
    });

    test('a subframe navigation is not the address bar\'s business', () async {
      agent = _FakeBidiAgent();
      await agent.start();
      final client = await BidiClient.attach(
        host: '127.0.0.1',
        port: agent.port,
        guestPort: 9223,
      );
      final seen = <String>[];
      client.pageEvents.listen((e) {
        if (e is BrowserPageUrlChanged) {
          seen.add(e.url);
        }
      });
      agent.emit('browsingContext.load', {
        'context': 'an-ad-iframe',
        'url': 'https://ads.test/pixel',
      });
      agent.emit('browsingContext.load', {
        'context': 'ctx-1',
        'url': 'https://example.test/real',
      });
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(seen, ['https://example.test/real']);
      await client.close();
    });

    test('console entries are buffered, not streamed at the agent', () async {
      agent = _FakeBidiAgent();
      await agent.start();
      final client = await BidiClient.attach(
        host: '127.0.0.1',
        port: agent.port,
        guestPort: 9223,
      );
      agent.emit('log.entryAdded', {'level': 'warn', 'text': 'careful'});
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(client.drainConsole(), ['[warn] careful']);
      expect(
        client.drainConsole(),
        isEmpty,
        reason: 'A drain empties the buffer, so a second read is not a repeat.',
      );
      expect(client.consoleCaveat, isNull);
      await client.close();
    });

    test(
      'a page script that throws reads as no answer, never as a crash',
      () async {
        agent = _FakeBidiAgent();
        await agent.start();
        agent.results['script.evaluate'] = {
          'type': 'exception',
          'exceptionDetails': {'text': 'ReferenceError: x is not defined'},
        };
        final client = await BidiClient.attach(
          host: '127.0.0.1',
          port: agent.port,
          guestPort: 9223,
        );
        expect(await client.centerOf('#nope'), isNull);
        expect(await client.readSelectionText(), '');
        await client.close();
      },
    );
  });

  group('WebDriverClient', () {
    late _FakeWebDriver driver;

    tearDown(() async => driver.stop());

    test('a GET carries no body', () async {
      // `dart:io` fixes content-length at 0 for a GET, so writing the `{}`
      // that every WebDriver POST needs throws before the request is sent.
      // That one mistake broke every READ command: url, screenshot, state.
      driver = _FakeWebDriver();
      await driver.start();
      final client = await WebDriverClient.attach(
        host: '127.0.0.1',
        port: driver.port,
      );
      await client.navigationState();
      expect(driver.bodied('/url').where((r) => r.$1 == 'GET'), isEmpty);
      expect(
        driver.received.any((r) => r.$1 == 'GET' && r.$2.endsWith('/url')),
        isTrue,
      );
      await client.close();
    });

    test('every POST carries one, even a command with no arguments', () async {
      driver = _FakeWebDriver();
      await driver.start();
      final client = await WebDriverClient.attach(
        host: '127.0.0.1',
        port: driver.port,
      );
      await client.navigate('https://example.test/one');
      await client.goHistory(-1);
      final backs = driver.received.where((r) => r.$2.endsWith('/back'));
      expect(backs, isNotEmpty);
      expect(
        backs.every((r) => r.$3 != null),
        isTrue,
        reason: 'Some drivers answer a bodyless POST with a 400.',
      );
      await client.close();
    });

    test(
      'back at the start of the history is refused, not reported as a move',
      () async {
        // Classic WebDriver's `back` is a SILENT no-op at the ends of the
        // history: it returns success and nothing moves.
        driver = _FakeWebDriver();
        await driver.start();
        final client = await WebDriverClient.attach(
          host: '127.0.0.1',
          port: driver.port,
        );
        expect(await client.goHistory(-1), isFalse);
        expect(
          driver.received.any((r) => r.$2.endsWith('/back')),
          isFalse,
          reason: 'The model refuses before the request is even made.',
        );
        await client.navigate('https://example.test/one');
        expect(await client.goHistory(-1), isTrue);
        expect((await client.navigationState()).canGoForward, isTrue);
        await client.close();
      },
    );

    test('the viewport is corrected for the browser chrome', () async {
      // `POST /window/rect` sizes the WINDOW. Measured on MiniBrowser, an
      // 800 px window is a 762 px viewport, and every coordinate an agent
      // sends is viewport-relative.
      driver = _FakeWebDriver();
      await driver.start();
      driver.values['POST /session/wd-1/execute/sync'] = '{"w":1280,"h":762}';
      final client = await WebDriverClient.attach(
        host: '127.0.0.1',
        port: driver.port,
      );
      await client.setViewport(width: 1280, height: 800);
      final rects = driver.received
          .where((r) => r.$2.endsWith('/window/rect'))
          .toList();
      expect(rects.length, 2, reason: 'One pass to size, one to correct.');
      expect(jsonDecode(rects.first.$3!), {'width': 1280, 'height': 800});
      expect(jsonDecode(rects.last.$3!), {'width': 1280, 'height': 838});
      await client.close();
    });

    test('says what its console lane cannot see', () async {
      driver = _FakeWebDriver();
      await driver.start();
      final client = await WebDriverClient.attach(
        host: '127.0.0.1',
        port: driver.port,
      );
      expect(client.engine, RigBrowserEngine.webkit);
      expect(
        client.consoleCaveat,
        isNotNull,
        reason:
            'An empty console means "the page logged nothing" on the other '
            'engines and can mean "it logged before we could listen" here. '
            'Reporting the first when the second happened sends someone '
            'hunting the wrong bug.',
      );
      await client.close();
    });

    test(
      'a file input is pointed at guest paths, and a miss is a false',
      () async {
        driver = _FakeWebDriver();
        await driver.start();
        final client = await WebDriverClient.attach(
          host: '127.0.0.1',
          port: driver.port,
        );
        expect(
          await client.setFileInputFiles(
            selector: 'input[type=file]',
            guestPaths: ['/tmp/a.png', '/tmp/b.png'],
          ),
          isTrue,
        );
        final sent = driver.received.lastWhere((r) => r.$2.endsWith('/value'));
        expect(
          (jsonDecode(sent.$3!) as Map)['text'],
          '/tmp/a.png\n/tmp/b.png',
          reason: 'Newline-separated is how a multiple file input is filled.',
        );
        expect(
          await client.setFileInputFiles(selector: '#x', guestPaths: const []),
          isFalse,
        );
        await client.close();
      },
    );

    test('no engine but Chromium can synthesize a real drop', () async {
      driver = _FakeWebDriver();
      await driver.start();
      final client = await WebDriverClient.attach(
        host: '127.0.0.1',
        port: driver.port,
      );
      expect(
        await client.dropFiles(guestPaths: ['/tmp/a.png'], x: 10, y: 10),
        isFalse,
        reason:
            'JavaScript cannot manufacture a File for a path it may not read, '
            'and the caller has honest words for "the page did not take it".',
      );
      await client.close();
    });
  });

  group('the W3C action vocabulary', () {
    test('named keys are the spec codepoints, not their names', () {
      // Sending the literal string "Enter" types five characters.
      expect(W3cActions.namedKey('Enter'), '\u{E007}');
      expect(W3cActions.namedKey('enter'), '\u{E007}');
      expect(W3cActions.namedKey('ArrowDown'), '\u{E015}');
      expect(W3cActions.namedKey('F5'), '\u{E035}');
      expect(W3cActions.namedKey('PageDown'), '\u{E00F}');
      expect(W3cActions.namedKey('Nope'), isNull);
    });

    test('meta is not silently translated to control', () {
      // The guest is Linux in every rig, so ctrl+c is the copy chord — but a
      // caller that asked for meta asked for something else, and answering a
      // different chord hides the mistake.
      expect(W3cActions.modifierKey('control'), '\u{E009}');
      expect(W3cActions.modifierKey('meta'), '\u{E03D}');
      expect(
        W3cActions.modifierKey('meta'),
        isNot(W3cActions.modifierKey('control')),
      );
    });

    test('a pointer source is addressed in viewport coordinates', () {
      final move = W3cActions.move(40, 60);
      expect(move['origin'], 'viewport');
      expect(move['x'], 40);
      expect(move['y'], 60);
      expect(W3cActions.buttonNumber('right'), 2);
      expect(W3cActions.buttonNumber('middle'), 1);
      expect(W3cActions.buttonNumber('left'), 0);
    });

    test('a selector is escaped into the page script it lands in', () {
      // `</script>` inside a selector would otherwise end the element the
      // engine wraps the expression in.
      expect(browserJsString('a[href="</script>"]'), isNot(contains('</')));
      expect(
        browserJsString('a[href="</script>"]'),
        contains(r'\u003C/script'),
      );
      // The quoting itself still round-trips: the escape is additional, not a
      // replacement for JSON encoding.
      expect(jsonDecode(browserJsString('#id .cls')), '#id .cls');
    });
  });
}
