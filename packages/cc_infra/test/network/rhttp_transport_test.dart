import 'dart:async';
import 'dart:io' as io;

import 'package:cc_infra/src/network/app_network.dart';
import 'package:cc_infra/src/util/http_file_download.dart';
import 'package:cc_natives/cc_natives.dart';
import 'package:rhttp/rhttp.dart';
import 'package:test/test.dart';

void main() {
  final nativePath = resolveRhttpLibraryPath();
  group(
    'native HTTP client identity',
    () {
      late io.HttpServer server;
      List<String>? receivedUserAgents;

      setUpAll(() => initializeRhttp(explicitPath: nativePath));
      setUp(() async {
        receivedUserAgents = null;
        server = await io.HttpServer.bind(io.InternetAddress.loopbackIPv4, 0);
        server.listen((request) async {
          receivedUserAgents = request.headers[io.HttpHeaders.userAgentHeader];
          // GitHub rejects unidentified requests before evaluating credentials.
          request.response.statusCode =
              receivedUserAgents?.length == 1 &&
                  receivedUserAgents!.single.isNotEmpty
              ? 204
              : 403;
          await request.response.close();
        });
      });
      tearDown(() => server.close(force: true));

      RhttpClient buildClient({String? userAgent}) {
        final client = createHttpClient(
          baseUrl: 'http://127.0.0.1:${server.port}',
          settings: ClientSettings(
            proxySettings: const ProxySettings.noProxy(),
            userAgent: userAgent,
          ),
        );
        addTearDown(client.dispose);
        return client;
      }

      test('shared clients satisfy User-Agent-required APIs', () async {
        final response = await buildClient().get('/app/installations');

        expect(response.statusCode, 204);
        expect(receivedUserAgents, [startsWith('ControlCenter/')]);
      });

      test('a configured client identity overrides the default', () async {
        final response = await buildClient(
          userAgent: 'FeedReader/2.0',
        ).get('/feed');

        expect(response.statusCode, 204);
        expect(receivedUserAgents, ['FeedReader/2.0']);
      });

      test('request identity wins regardless of header casing', () async {
        final client = buildClient(userAgent: 'ConfiguredClient/1.0');

        for (final name in ['User-Agent', 'user-agent', 'uSeR-aGeNt']) {
          final response = await client.get(
            '/feed',
            headers: HttpHeaders.rawMap({name: 'RequestReader/3.0'}),
          );

          expect(response.statusCode, 204);
          expect(receivedUserAgents, ['RequestReader/3.0']);
        }
      });
    },
    skip: nativePath == null
        ? 'Build natives and set RHTTP_DYLIB or CC_NATIVE_LIB_DIR.'
        : false,
  );

  group(
    'native HTTP cancellation',
    () {
      late io.HttpServer server;
      late io.Directory directory;
      late RhttpClient client;
      late Completer<void> release;
      late Completer<void> requestArrived;
      late int requests;

      setUpAll(() => initializeRhttp(explicitPath: nativePath));
      setUp(() async {
        server = await io.HttpServer.bind(io.InternetAddress.loopbackIPv4, 0);
        directory = io.Directory.systemTemp.createTempSync('cc-rhttp-test-');
        release = Completer<void>();
        requestArrived = Completer<void>();
        requests = 0;
        server.listen((request) async {
          requests++;
          if (!requestArrived.isCompleted) {
            requestArrived.complete();
          }
          try {
            if (request.uri.path == '/body') {
              request.response.bufferOutput = false;
              request.response.contentLength = 4;
              request.response.add([1, 2]);
              await request.response.flush();
            }
            await release.future;
            request.response.add([3, 4]);
            await request.response.close();
          } on io.HttpException {
            // The client deliberately aborts both stalled responses.
          } on io.SocketException {
            // The client deliberately aborts both stalled responses.
          }
        });
        client = createHttpClient(
          settings: modelDownloadClientSettings.copyWith(
            proxySettings: const ProxySettings.noProxy(),
          ),
        );
      });
      tearDown(() async {
        if (!release.isCompleted) {
          release.complete();
        }
        client.dispose(cancelRunningRequests: true);
        await server.close(force: true);
        directory.deleteSync(recursive: true);
      });

      test('cancellation before dispatch never sends a request', () async {
        final token = CancelToken();
        unawaited(token.cancel());
        await token.whenCancelRequested;
        await expectLater(
          client.get('http://127.0.0.1:${server.port}/', cancelToken: token),
          throwsA(isA<RhttpCancelException>()),
        );
        expect(requests, 0);
      });

      test(
        'cancellation during async authentication prevents dispatch',
        () async {
          final authenticating = Completer<void>();
          final continueAuth = Completer<void>();
          final authenticatedClient = createHttpClient(
            interceptors: [
              SimpleInterceptor(
                beforeRequest: (request) async {
                  authenticating.complete();
                  await continueAuth.future;
                  return Interceptor.next();
                },
              ),
            ],
          );
          addTearDown(
            () => authenticatedClient.dispose(cancelRunningRequests: true),
          );
          final token = CancelToken();
          final failure = expectLater(
            authenticatedClient.get(
              'http://127.0.0.1:${server.port}/',
              cancelToken: token,
            ),
            throwsA(isA<RhttpCancelException>()),
          );
          await authenticating.future;
          unawaited(token.cancel());
          continueAuth.complete();
          await failure;
          expect(requests, 0);
        },
      );

      test(
        'stalled headers time out without creating a partial file',
        () async {
          final destination = '${directory.path}/headers.part';
          final failure = expectLater(
            downloadToFile(
              client,
              'http://127.0.0.1:${server.port}/headers',
              destination,
              idleTimeout: const Duration(milliseconds: 250),
            ),
            throwsA(isA<RhttpTimeoutException>()),
          );
          await requestArrived.future;
          await failure;
          expect(io.File(destination).existsSync(), isFalse);
        },
      );

      test(
        'stalled body preserves timeout through native stream teardown',
        () async {
          final destination = '${directory.path}/body.part';
          var received = 0;
          await expectLater(
            downloadToFile(
              client,
              'http://127.0.0.1:${server.port}/body',
              destination,
              idleTimeout: const Duration(milliseconds: 250),
              onReceiveProgress: (count, _) => received = count,
            ),
            throwsA(isA<RhttpTimeoutException>()),
          );
          expect(received, 2);
        },
      );
    },
    skip: nativePath == null
        ? 'Build natives and set RHTTP_DYLIB or CC_NATIVE_LIB_DIR.'
        : false,
  );
}
