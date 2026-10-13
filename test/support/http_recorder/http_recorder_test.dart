import 'dart:convert';
import 'dart:io';

import 'package:cc_natives/cc_natives.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhttp/rhttp.dart' as http;

import '../../helpers/stage_server_natives.dart';
import 'http_recorder.dart';

void main() {
  final nativePath = testRhttpLibraryPath;
  group(
    'HttpRecorder over the rhttp native',
    () => _recorderTests(nativePath),
    skip: nativePath == null
        ? 'Build natives and set RHTTP_DYLIB or CC_NATIVE_LIB_DIR.'
        : false,
  );
}

void _recorderTests(String? nativePath) {
  late Directory tempDir;

  setUpAll(() => initializeRhttp(explicitPath: nativePath));
  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('cc_cassettes');
  });
  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  http.RhttpClient clientFor(HttpRecorder recorder) {
    final client = http.RhttpClient.createSync(
      settings: const http.ClientSettings(
        proxySettings: http.ProxySettings.noProxy(),
      ),
      interceptors: [recorder.interceptor],
    );
    addTearDown(client.dispose);
    return client;
  }

  Future<HttpServer> startServer(void Function(HttpRequest) handle) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen(handle);
    addTearDown(() => server.close(force: true));
    return server;
  }

  test(
    'records a request then replays it byte-identical with no upstream',
    () async {
      const payload = '{"login":"octocat","id":583231}';
      var serverHits = 0;
      final server = await startServer((request) {
        serverHits++;
        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType.json
          ..write(payload);
        request.response.close();
      });
      final base = 'http://${server.address.address}:${server.port}';
      final recorder = await HttpRecorder.open(
        'github/user',
        mode: RecordMode.record,
        directory: tempDir.path,
      );
      final recorded = await clientFor(recorder).get('$base/users/octocat');
      await recorder.save();
      expect(serverHits, 1);
      expect(recorded.body, payload);
      await server.close(force: true);

      final replay = await HttpRecorder.open(
        'github/user',
        mode: RecordMode.replay,
        directory: tempDir.path,
      );
      final replayed = await clientFor(replay).get('$base/users/octocat');
      expect(replayed.body, payload);
      expect(replayed.statusCode, 200);
      expect(serverHits, 1, reason: 'replay must not contact upstream');
    },
  );

  test('auto mode records when missing then replays when present', () async {
    final server = await startServer((request) {
      request.response.write('ok');
      request.response.close();
    });
    final url = 'http://${server.address.address}:${server.port}/ping';
    final recorder = await HttpRecorder.open(
      'auto/probe',
      directory: tempDir.path,
      isCi: false,
    );
    await clientFor(recorder).get(url);
    await recorder.save();
    await server.close(force: true);
    final replay = await HttpRecorder.open(
      'auto/probe',
      directory: tempDir.path,
      isCi: false,
    );
    expect((await clientFor(replay).get(url)).body, 'ok');
  });

  test('replay rejects requests not present in the cassette', () async {
    final cassette = Cassette(
      interactions: [
        const HttpInteraction(
          request: RequestSnapshot(
            method: 'GET',
            url: 'http://localhost/expected',
            headers: {},
            body: '',
          ),
          response: ResponseSnapshot(status: 200, headers: {}, body: 'x'),
        ),
      ],
    );
    await CassetteStore(directory: tempDir.path).write('mismatch', cassette);
    final recorder = await HttpRecorder.open(
      'mismatch',
      mode: RecordMode.replay,
      directory: tempDir.path,
    );
    await expectLater(
      clientFor(recorder).get('http://localhost/actual'),
      throwsA(isA<http.RhttpUnknownException>()),
    );
  });

  test('write-guard refuses a cassette containing a secret', () async {
    final cassette = Cassette(
      interactions: [
        HttpInteraction(
          request: const RequestSnapshot(
            method: 'GET',
            url: 'http://localhost/x',
            headers: {},
            body: '',
          ),
          response: ResponseSnapshot(
            status: 200,
            headers: const {},
            body: '{"token":"ghp_${'a' * 30}"}',
          ),
        ),
      ],
    );
    final store = CassetteStore(directory: tempDir.path);
    await expectLater(
      store.write('leaky', cassette),
      throwsA(isA<UnsafeCassetteError>()),
    );
    expect(File('${tempDir.path}/leaky.json').existsSync(), isFalse);
  });

  test('replays the committed GitHub cassette byte-identical', () async {
    final recorder = await HttpRecorder.open(
      'github/user-octocat',
      mode: RecordMode.replay,
      directory: 'test/fixtures/recordings',
    );
    final response = await clientFor(recorder).get(
      'https://api.github.com/users/octocat',
      headers: const http.HttpHeaders.rawMap({
        'accept': 'application/vnd.github+json',
      }),
    );
    expect(response.statusCode, 200);
    expect((response.bodyToJson as Map)['login'], 'octocat');
    expect((response.bodyToJson as Map)['id'], 583231);
  });

  test('redacts the Authorization header before writing', () async {
    final server = await startServer((request) {
      request.response.write('{}');
      request.response.close();
    });
    final recorder = await HttpRecorder.open(
      'redacted/call',
      mode: RecordMode.record,
      directory: tempDir.path,
      redactor: Redactor.defaults(
        requestHeaderAllowList: ['content-type', 'accept', 'authorization'],
      ),
    );
    await clientFor(recorder).get(
      'http://${server.address.address}:${server.port}/me',
      headers: const http.HttpHeaders.rawMap({
        'Authorization': 'Bearer super-secret-token-value-123',
      }),
    );
    await recorder.save();
    final raw = await File('${tempDir.path}/redacted/call.json').readAsString();
    final cassette = Cassette.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    expect(
      cassette.interactions.first.request.headers['authorization'],
      kRedacted,
    );
    expect(raw.contains('super-secret-token-value-123'), isFalse);
  });
}
