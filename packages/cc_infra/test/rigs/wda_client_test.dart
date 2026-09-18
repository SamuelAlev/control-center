import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_infra/src/rigs/wda_client.dart';
import 'package:test/test.dart';

void main() {
  late HttpServer commandServer;
  late HttpServer mjpegServer;
  late WdaClient client;
  late List<({String method, String path, Object? body})> requests;
  late StreamSubscription<HttpRequest> commandSubscription;
  late StreamSubscription<HttpRequest> mjpegSubscription;

  setUp(() async {
    requests = [];
    commandServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    mjpegServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    commandSubscription = commandServer.listen((request) async {
      final text = await utf8.decoder.bind(request).join();
      final body = text.isEmpty ? null : jsonDecode(text);
      requests.add((method: request.method, path: request.uri.toString(), body: body));
      request.response.headers.contentType = ContentType.json;

      Object? value;
      if (request.uri.path == '/session') {
        value = {'sessionId': 'session-1', 'capabilities': <String, Object?>{}};
      } else if (request.uri.path.endsWith('/wda/screen')) {
        value = {'width': 390, 'height': 844, 'scale': 3};
      } else if (request.uri.path.endsWith('/screenshot')) {
        value = base64Encode([1, 2, 3, 4]);
      } else if (request.uri.path.endsWith('/source')) {
        value = {
          'type': 'Application',
          'children': [
            {'type': 'Button', 'label': 'Continue'},
          ],
        };
      } else if (request.uri.path.endsWith('/wda/getPasteboard')) {
        value = base64Encode(utf8.encode('copied'));
      } else if (request.uri.path.endsWith('/wda/apps/launch') &&
          body is Map &&
          body['bundleId'] == 'com.example.bad') {
        request.response.statusCode = HttpStatus.internalServerError;
        value = {
          'error': 'unknown error',
          'message': 'The app could not be launched',
        };
      }
      request.response.write(jsonEncode({'value': value}));
      await request.response.close();
    });
    mjpegSubscription = mjpegServer.listen((request) async {
      request.response.statusCode = HttpStatus.ok;
      request.response.add([0xff, 0xd8, 0xff, 0xd9]);
      await request.response.close();
    });
    client = WdaClient(
      baseUri: Uri.parse(
        'http://${commandServer.address.address}:${commandServer.port}/',
      ),
      mjpegUri: Uri.parse(
        'http://${mjpegServer.address.address}:${mjpegServer.port}/',
      ),
    );
  });

  tearDown(() async {
    await commandSubscription.cancel();
    await mjpegSubscription.cancel();
    await commandServer.close(force: true);
    await mjpegServer.close(force: true);
  });

  test('creates and deletes one W3C session', () async {
    expect(await client.createSession(), 'session-1');
    expect(client.sessionId, 'session-1');
    await client.deleteSession();
    expect(client.sessionId, isNull);
    expect(requests.map((entry) => entry.path), [
      '/session',
      '/session/session-1',
    ]);
  });

  test('parses screen, source and screenshot payloads', () async {
    await client.createSession();
    final screen = await client.screen();
    expect(screen.size.width, 390);
    expect(screen.size.height, 844);
    expect(screen.scale, 3);
    expect(await client.source(), isA<Map>());
    expect(await client.screenshot(), [1, 2, 3, 4]);
    expect(
      requests.map((entry) => entry.path),
      containsAll([
        '/session/session-1/wda/screen',
        '/session/session-1/source?format=json',
        '/session/session-1/screenshot',
      ]),
    );
  });

  test('emits W3C pointer and key action payloads', () async {
    await client.createSession();
    await client.tap(10, 20);
    await client.swipe(
      fromX: 1,
      fromY: 2,
      toX: 30,
      toY: 40,
      duration: const Duration(milliseconds: 450),
    );
    await client.key(['\uE03D', 'a']);

    final actionBodies = requests
        .where((entry) => entry.path.endsWith('/actions'))
        .map((entry) => entry.body as Map)
        .toList();
    expect(actionBodies, hasLength(3));
    expect(
      (((actionBodies[0]['actions'] as List).first as Map)['actions'] as List)
          .map((action) => (action as Map)['type']),
      ['pointerMove', 'pointerDown', 'pause', 'pointerUp'],
    );
    expect(
      (((actionBodies[2]['actions'] as List).first as Map)['actions'] as List)
          .map((action) => (action as Map)['type']),
      ['keyDown', 'keyDown', 'keyUp', 'keyUp'],
    );
  });

  test('maps text, device, app, settings and pasteboard routes', () async {
    await client.createSession();
    await client.typeText('hello');
    await client.home();
    await client.lock();
    await client.unlock();
    await client.launchApp('com.example.app');
    await client.configureMjpeg(fps: 40, scalingFactor: 60, quality: 70);
    await client.setPasteboard(
      contentType: 'plaintext',
      bytes: utf8.encode('pasted'),
    );
    expect(
      utf8.decode(await client.getPasteboard(contentType: 'plaintext')),
      'copied',
    );

    expect(
      requests.map((entry) => entry.path),
      containsAll([
        '/session/session-1/wda/keys',
        '/session/session-1/wda/homescreen',
        '/session/session-1/wda/lock',
        '/session/session-1/wda/unlock',
        '/session/session-1/wda/apps/launch',
        '/session/session-1/appium/settings',
        '/session/session-1/wda/setPasteboard',
        '/session/session-1/wda/getPasteboard',
      ]),
    );
    final settings = requests
        .singleWhere((entry) => entry.path.endsWith('/appium/settings'))
        .body as Map;
    expect((settings['settings'] as Map)['mjpegServerFramerate'], 15);
  });

  test('extracts structured WDA errors', () async {
    await client.createSession();
    await expectLater(
      client.launchApp('com.example.bad'),
      throwsA(
        isA<WdaException>()
            .having((error) => error.code, 'code', 'unknown error')
            .having((error) => error.message, 'message', contains('launched')),
      ),
    );
  });

  test('relays the native MJPEG response body', () async {
    final bytes = await client.openMjpeg().expand((chunk) => chunk).toList();
    expect(bytes, [0xff, 0xd8, 0xff, 0xd9]);
  });
}
