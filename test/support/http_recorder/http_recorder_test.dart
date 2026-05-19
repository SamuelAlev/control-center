import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'http_recorder.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('cc_cassettes');
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<HttpServer> startServer(void Function(HttpRequest) handle) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen(handle);
    return server;
  }

  test(
    'records a request then replays it byte-identical with no upstream',
    () async {
      const payload = '{"login":"octocat","id":583231}';
      var serverHits = 0;
      final server = await startServer((req) {
        serverHits++;
        req.response
          ..statusCode = 200
          ..headers.contentType = ContentType.json
          ..write(payload);
        req.response.close();
      });
      final base = 'http://${server.address.address}:${server.port}';

      // Record.
      final recordDio = Dio(BaseOptions(responseType: ResponseType.plain));
      final recorder = await HttpRecorder.attach(
        recordDio,
        'github/user',
        mode: RecordMode.record,
        directory: tempDir.path,
      );
      final recorded = await recordDio.get<String>('$base/users/octocat');
      await recorder.save();

      expect(serverHits, 1);
      expect(recorded.data, payload);
      expect(File('${tempDir.path}/github/user.json').existsSync(), isTrue);

      // Shut the server down — replay must not touch the network.
      await server.close(force: true);

      final replayDio = Dio(BaseOptions(responseType: ResponseType.plain));
      final replay = await HttpRecorder.attach(
        replayDio,
        'github/user',
        mode: RecordMode.replay,
        directory: tempDir.path,
      );
      expect(replay.mode, RecordMode.replay);
      final replayed = await replayDio.get<String>('$base/users/octocat');

      expect(replayed.data, payload, reason: 'replay should be byte-identical');
      expect(replayed.statusCode, 200);
      expect(serverHits, 1, reason: 'no extra upstream hit on replay');
    },
  );

  test('auto mode records when missing then replays when present', () async {
    final server = await startServer((req) {
      req.response
        ..statusCode = 200
        ..write('ok');
      req.response.close();
    });
    final base = 'http://${server.address.address}:${server.port}';

    final dio1 = Dio(BaseOptions(responseType: ResponseType.plain));
    final r1 = await HttpRecorder.attach(
      dio1,
      'auto/probe',
      directory: tempDir.path,
      isCi: false,
    );
    expect(r1.mode, RecordMode.record);
    await dio1.get<String>('$base/ping');
    await r1.save();

    final dio2 = Dio(BaseOptions(responseType: ResponseType.plain));
    final r2 = await HttpRecorder.attach(
      dio2,
      'auto/probe',
      directory: tempDir.path,
      isCi: false,
    );
    expect(r2.mode, RecordMode.replay);

    await server.close(force: true);
  });

  test(
    'replay surfaces a request diff when the cassette does not match',
    () async {
      // Hand-write a cassette expecting a different path.
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

      final dio = Dio(BaseOptions(responseType: ResponseType.plain));
      await HttpRecorder.attach(
        dio,
        'mismatch',
        mode: RecordMode.replay,
        directory: tempDir.path,
      );

      await expectLater(
        dio.get<String>('http://localhost/actual'),
        throwsA(
          isA<DioException>().having(
            (e) => '${e.error}',
            'error',
            contains('does not match'),
          ),
        ),
      );
    },
  );

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
    expect(
      File('${tempDir.path}/leaky.json').existsSync(),
      isFalse,
      reason: 'nothing should be written when a secret is found',
    );
  });

  test('replays the committed GitHub cassette byte-identical', () async {
    final dio = Dio(BaseOptions(responseType: ResponseType.json));
    await HttpRecorder.attach(
      dio,
      'github/user-octocat',
      mode: RecordMode.replay,
      directory: 'test/fixtures/recordings',
    );
    final res = await dio.get<dynamic>(
      'https://api.github.com/users/octocat',
      options: Options(headers: {'accept': 'application/vnd.github+json'}),
    );
    expect(res.statusCode, 200);
    expect((res.data as Map)['login'], 'octocat');
    expect((res.data as Map)['id'], 583231);
  });

  test('redacts the Authorization header before writing', () async {
    final server = await startServer((req) {
      req.response
        ..statusCode = 200
        ..write('{}');
      req.response.close();
    });
    final base = 'http://${server.address.address}:${server.port}';

    final dio = Dio(
      BaseOptions(
        responseType: ResponseType.plain,
        headers: {'Authorization': 'Bearer super-secret-token-value-123'},
      ),
    );
    final recorder = await HttpRecorder.attach(
      dio,
      'redacted/call',
      mode: RecordMode.record,
      directory: tempDir.path,
      // Keep the header but scrub its value (default drops it entirely).
      redactor: Redactor.defaults(
        requestHeaderAllowList: ['content-type', 'accept', 'authorization'],
      ),
    );
    await dio.get<String>('$base/me');
    await recorder.save();

    final raw = await File('${tempDir.path}/redacted/call.json').readAsString();
    final cassette = Cassette.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    final headers = cassette.interactions.first.request.headers;
    expect(headers['authorization'], kRedacted);
    expect(raw.contains('super-secret-token-value-123'), isFalse);

    await server.close(force: true);
  });
}
