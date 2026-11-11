import 'dart:convert';
import 'dart:io';

import 'package:cc_connect_core/cc_connect_core.dart' show ConnectException;
import 'package:cc_host/cc_host.dart' show CcHostLog;
import 'package:cc_server_core/src/connect/connect_client.dart';
import 'package:cc_server_core/src/connect/connect_settings.dart';
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:test/test.dart';

/// A failed call to Connect leaves one `connect.call_failed` line that names
/// Connect's own request id, so the call can be found in Connect's log, and
/// nothing a reader could reuse: no signature, no install key, no body.
void main() {
  late Directory dir;
  late HttpServer connect;
  late ConnectClient client;
  late List<String> lines;
  late Map<String, String> received;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('cc_connect_call_failed_');
    received = {};
    connect = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    connect.listen((request) async {
      request.headers.forEach((name, values) => received[name] = values.join());
      await request.drain<void>();
      request.response
        ..statusCode = HttpStatus.tooManyRequests
        ..headers.contentType = ContentType.json
        ..headers.set('x-request-id', 'req-7f3a')
        ..write(jsonEncode({'error': 'rate_limited'}));
      await request.response.close();
    });
    final settings = ConnectSettings(
      secrets: FileSecretsStore(dataDir: dir.path),
    );
    await settings.setChoice(
      ConnectMode.custom,
      url: 'http://127.0.0.1:${connect.port}',
    );
    client = ConnectClient(settings: settings);

    lines = [];
    final previous = CcHostLog.sink;
    CcHostLog.sink = (level, message, [error, stack]) => lines.add(message);
    addTearDown(() => CcHostLog.sink = previous);
  });

  tearDown(() async {
    await connect.close(force: true);
    dir.deleteSync(recursive: true);
  });

  Map<String, Object?> failure() {
    final line = lines.singleWhere((l) => l.contains('connect.call_failed'));
    return jsonDecode(line.substring(line.indexOf('{')))
        as Map<String, Object?>;
  }

  test("a refused call carries Connect's request id and no secret", () async {
    await expectLater(
      client.klipySearch(await client.serverTarget(), 'private query'),
      throwsA(isA<ConnectException>()),
    );

    final event = failure();
    expect(event['connect_request_id'], 'req-7f3a');
    expect(event['status'], HttpStatus.tooManyRequests);
    expect(event['error'], 'rate_limited');
    expect(event['method'], 'POST');
    expect(event['path'], '/v1/klipy/search');

    final logged = lines.join('\n');
    expect(logged, isNot(contains('private query')));
    // Every header the request was signed with stays out of the log.
    expect(received.keys, contains('signature'));
    for (final MapEntry(key: name, value: value) in received.entries) {
      if (const {
        'signature',
        'signature-input',
        'content-digest',
      }.contains(name)) {
        expect(logged, isNot(contains(value)), reason: name);
      }
    }
  });

  test('an unreachable Connect is logged without a request id', () async {
    final port = connect.port;
    await connect.close(force: true);
    connect = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);

    await expectLater(
      client.klipySearch(await client.serverTarget(), 'q'),
      throwsA(isA<ConnectException>()),
    );

    final event = failure();
    expect(event.containsKey('connect_request_id'), isFalse);
    expect(event['error'], startsWith('network:'));
    expect(event['origin'], 'http://127.0.0.1:$port');
  });
}
