import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/cc_domain.dart'
    show NetworkException, ValidationException;
import 'package:cc_infra/testing/http_client.dart';
import 'package:cc_server_core/src/connect/connect_client.dart';
import 'package:cc_server_core/src/connect/connect_settings.dart';
import 'package:cc_server_core/src/connect/klipy_gifs.dart';
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:cc_server_core/src/identity/workspace_provider_app_settings.dart';
import 'package:rhttp/rhttp.dart' show ClientSettings;
import 'package:test/test.dart';

/// GIF search resolves per call: the operator's own key, else Connect's
/// Klipy lane (proxy or handed-out key), else nothing. Media URLs off Klipy's
/// CDN never reach a client.
void main() {
  late Directory dir;
  late FileSecretsStore secrets;
  late TestHttpClient klipy;
  late _FakeConnect fakeConnect;

  const cdnPreview = 'https://static.klipy.com/sm.gif';
  const cdnGif = 'https://static.klipy.com/hd.gif';

  Map<String, Object?> klipyItem(int id, {String host = 'static.klipy.com'}) =>
      {
        'id': id,
        'title': 'gif $id',
        'file': {
          'sm': {
            'gif': {'url': 'https://$host/sm.gif', 'width': 10, 'height': 8},
          },
          'hd': {
            'gif': {'url': 'https://$host/hd.gif', 'width': 20, 'height': 16},
          },
        },
      };

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('cc_klipy_gifs_');
    secrets = FileSecretsStore(dataDir: dir.path);
    klipy = TestHttpClient(
      settings: const ClientSettings(baseUrl: 'https://api.klipy.com'),
      handler: (request) => httpTextResponse(request, {
        'data': {
          'data': [klipyItem(1), klipyItem(2, host: 'tracker.example')],
        },
      }),
    );
    fakeConnect = await _FakeConnect.start();
  });

  tearDown(() async {
    await fakeConnect.close();
    dir.deleteSync(recursive: true);
  });

  Future<ConnectClient> connectFor({Map<String, Object?>? klipyLane}) async {
    final settings = ConnectSettings(secrets: secrets);
    if (klipyLane != null) {
      fakeConnect.klipyLane = klipyLane;
      await settings.setChoice(ConnectMode.custom, url: fakeConnect.base);
    }
    return ConnectClient(settings: settings);
  }

  test('with no Connect chosen the own key applies and its results stay on '
      'the CDN', () async {
    final gifs = KlipyGifs(
      connect: await connectFor(),
      ownAppKey: 'OWN-KEY',
      transport: () => klipy,
    );
    expect(await gifs.source(), KlipyLaneSource.own);
    final found = await gifs.search('ws-1', 'cats');

    expect(
      httpRequestUri(klipy.requests.single).path,
      '/api/v1/OWN-KEY/gifs/search',
    );
    expect(fakeConnect.searches, 0);
    expect(found.single.toJson(), {
      'id': '1',
      'title': 'gif 1',
      'width': 20,
      'height': 16,
      'preview_url': cdnPreview,
      'gif_url': cdnGif,
    });
  });

  test('a chosen Connect wins over the own key', () async {
    final gifs = KlipyGifs(
      connect: await connectFor(klipyLane: {'mode': 'proxy'}),
      ownAppKey: 'OWN-KEY',
      transport: () => klipy,
    );
    expect(await gifs.source(), KlipyLaneSource.connect);
    await gifs.search('ws-1', 'cats');
    expect(fakeConnect.searches, 1);
    expect(klipy.requests, isEmpty);
  });

  test('nothing configured answers nothing', () async {
    final gifs = KlipyGifs(connect: await connectFor(), transport: () => klipy);
    expect(await gifs.source(), KlipyLaneSource.off);
    expect(await gifs.search('ws-1', 'cats'), isEmpty);
    expect(await gifs.trending('ws-1'), isEmpty);
    expect(klipy.requests, isEmpty);
  });

  test('Connect proxy mode searches through Connect', () async {
    final gifs = KlipyGifs(
      connect: await connectFor(klipyLane: {'mode': 'proxy'}),
      transport: () => klipy,
    );
    expect(await gifs.source(), KlipyLaneSource.connect);
    final found = await gifs.search('ws-1', 'cats');
    expect(fakeConnect.lastQuery, 'cats');
    expect([for (final g in found) g.id], ['ok']);
    expect(klipy.requests, isEmpty);
  });

  test('a Connect outage is an error, not a silent empty list', () async {
    final gifs = KlipyGifs(
      connect: await connectFor(klipyLane: {'mode': 'proxy'}),
      transport: () => klipy,
    );
    fakeConnect.failSearch = true;
    await expectLater(gifs.trending('ws-1'), throwsA(isA<NetworkException>()));
  });

  test('Connect key mode calls Klipy with the handed-out key', () async {
    final gifs = KlipyGifs(
      connect: await connectFor(
        klipyLane: {'mode': 'key', 'app_key': 'CONNECT-KEY'},
      ),
      transport: () => klipy,
    );
    final found = await gifs.trending('ws-1');
    expect(
      httpRequestUri(klipy.requests.single).path,
      '/api/v1/CONNECT-KEY/gifs/trending',
    );
    expect([for (final g in found) g.id], ['1']);
  });

  group("a workspace's own Klipy key", () {
    late WorkspaceProviderAppSettings workspaceApps;

    setUp(() => workspaceApps = WorkspaceProviderAppSettings(secrets));

    test('wins for that workspace only', () async {
      await workspaceApps.save('ws-own', WorkspaceAppProvider.klipy, {
        'app_key': 'WS-KEY',
      });
      final gifs = KlipyGifs(
        connect: await connectFor(klipyLane: {'mode': 'proxy'}),
        ownAppKey: 'OWN-KEY',
        workspaceApps: workspaceApps,
        transport: () => klipy,
      );
      await gifs.search('ws-own', 'cats');
      await gifs.search('ws-other', 'cats');
      expect(
        [for (final r in klipy.requests) httpRequestUri(r).path],
        ['/api/v1/WS-KEY/gifs/search'],
      );
      // The other workspace inherits: the chosen Connect, not the own key.
      expect(fakeConnect.searches, 1);
    });

    test('missing is an error, never the server key or Connect', () async {
      await workspaceApps.setMode(
        'ws-own',
        WorkspaceAppProvider.klipy,
        WorkspaceAppMode.own,
      );
      final gifs = KlipyGifs(
        connect: await connectFor(klipyLane: {'mode': 'proxy'}),
        ownAppKey: 'OWN-KEY',
        workspaceApps: workspaceApps,
        transport: () => klipy,
      );
      await expectLater(
        gifs.search('ws-own', 'cats'),
        throwsA(isA<ValidationException>()),
      );
      expect(klipy.requests, isEmpty);
      expect(fakeConnect.searches, 0);
    });
  });
}

/// A self-hosted Connect on loopback serving `/v1/config` and the Klipy
/// proxy. Signatures are not checked: the client under test is what is
/// being exercised.
class _FakeConnect {
  _FakeConnect._(this._server) {
    _server.listen(_handle);
  }

  static Future<_FakeConnect> start() async =>
      _FakeConnect._(await HttpServer.bind(InternetAddress.loopbackIPv4, 0));

  final HttpServer _server;

  Map<String, Object?> klipyLane = const {'mode': 'proxy'};
  bool failSearch = false;
  int searches = 0;
  String lastQuery = '';

  String get base => 'http://127.0.0.1:${_server.port}';

  Future<void> _handle(HttpRequest request) async {
    final body = await utf8.decoder.bind(request).join();
    final response = request.response..headers.contentType = ContentType.json;
    switch (request.uri.path) {
      case '/v1/config':
        response.write(
          jsonEncode({
            'protocol': 1,
            'epoch': 1,
            'issued_at': DateTime.now().toUtc().toIso8601String(),
            'klipy': klipyLane,
          }),
        );
      case '/v1/klipy/search' || '/v1/klipy/trending':
        searches++;
        if (failSearch) {
          response
            ..statusCode = HttpStatus.serviceUnavailable
            ..write(jsonEncode({'error': 'provider_unavailable'}));
          break;
        }
        final decoded = body.isEmpty ? const {} : jsonDecode(body) as Map;
        lastQuery = '${decoded['q'] ?? ''}';
        response.write(
          jsonEncode({
            'gifs': [
              {
                'id': 'ok',
                'title': 'fine',
                'width': 1,
                'height': 1,
                'preview_url': 'https://static.klipy.com/a.gif',
                'gif_url': 'https://static.klipy.com/b.gif',
              },
              {
                'id': 'off-cdn',
                'title': 'tracker',
                'width': 1,
                'height': 1,
                'preview_url': 'https://tracker.example/a.gif',
                'gif_url': 'https://static.klipy.com/b.gif',
              },
            ],
          }),
        );
      default:
        response.statusCode = HttpStatus.notFound;
    }
    await response.close();
  }

  Future<void> close() => _server.close(force: true);
}
