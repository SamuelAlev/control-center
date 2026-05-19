import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/rigs/domain/value_objects/rig_clipboard.dart';
import 'package:cc_infra/src/rigs/guest_agent_client.dart';
import 'package:test/test.dart';

/// `/version` is the forward-compatibility seam: it must answer for images
/// that have it and stay SILENT for images that do not, because every image
/// built before the endpoint existed is still a perfectly good rig. Treating
/// the 404 as a fault would break machines that work.
void main() {
  group('GuestAgentClient.version', () {
    late HttpServer server;
    late GuestAgentClient client;
    int status = 200;
    String body = '{"protocol": 1, "agent": "cc-guest-agent/1"}';
    final seenAuth = <String>[];

    setUp(() async {
      status = 200;
      body = '{"protocol": 1, "agent": "cc-guest-agent/1"}';
      seenAuth.clear();
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        seenAuth.add(
          request.headers.value(HttpHeaders.authorizationHeader) ?? '',
        );
        final bytes = utf8.encode(body);
        request.response.statusCode = status;
        request.response.headers.contentType = ContentType.json;
        request.response.add(bytes);
        await request.response.close();
      });
      client = GuestAgentClient(port: server.port, token: 'tok-1');
    });

    tearDown(() async {
      client.close();
      await server.close(force: true);
    });

    test(
      'parses the protocol and build, and carries the bearer token',
      () async {
        final version = await client.version();

        expect(version, isNotNull);
        expect(version!.protocol, 1);
        expect(version.agent, 'cc-guest-agent/1');
        expect(seenAuth.single, 'Bearer tok-1');
      },
    );

    test(
      'an image that predates the endpoint returns null, not a throw',
      () async {
        status = HttpStatus.notFound;
        body = '{"error": "no such endpoint"}';

        expect(await client.version(), isNull);
      },
    );

    test('a fail-closed guest (503 with its cause) throws with the cause '
        'in the message', () async {
      status = HttpStatus.serviceUnavailable;
      body =
          '{"error": "guest agent is unconfigured", "cause": "seed missing"}';

      await expectLater(
        client.version(),
        throwsA(
          isA<GuestAgentException>().having(
            (e) => e.message,
            'message',
            allOf(contains('503'), contains('seed missing')),
          ),
        ),
      );
    });

    test('a malformed reply throws rather than inventing a version', () async {
      body = 'not json at all';

      await expectLater(client.version(), throwsA(isA<GuestAgentException>()));
    });

    test('a missing protocol field reads as 0 — older than the first one '
        'that announced itself', () {
      final version = GuestAgentVersion.fromJson(const {'agent': 'x'});

      expect(version.protocol, 0);
      expect(version.agent, 'x');
    });
  });

  /// The clipboard lane. Its whole job is to be honest about three different
  /// "nothing came back" states: an empty clipboard, an image too big to
  /// carry, and an image that predates the endpoint entirely.
  group('GuestAgentClient clipboard', () {
    late HttpServer server;
    late GuestAgentClient client;
    int status = 200;
    String body = '{}';
    final requests = <({String method, String path, String body})>[];

    setUp(() async {
      status = 200;
      body = '{}';
      requests.clear();
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        final received = await utf8.decoder.bind(request).join();
        requests.add((
          method: request.method,
          path: request.uri.toString(),
          body: received,
        ));
        final bytes = utf8.encode(body);
        request.response.statusCode = status;
        request.response.headers.contentType = ContentType.json;
        request.response.add(bytes);
        await request.response.close();
      });
      client = GuestAgentClient(port: server.port, token: 'tok-1');
    });

    tearDown(() async {
      client.close();
      await server.close(force: true);
    });

    test('asks for the named selection and parses every flavour', () async {
      body = jsonEncode({
        'text': 'hello',
        'image': 'QUFB',
        'image_media_type': 'image/png',
        'files': [
          {'guest_path': '/home/cc/a.txt', 'name': 'a.txt', 'size_bytes': 3},
        ],
      });

      final data = await client.readClipboard(RigClipboardSelection.xdnd);

      expect(requests.single.path, '/clipboard?sel=xdnd');
      expect(data.text, 'hello');
      expect(data.imageBase64, 'QUFB');
      expect(data.files.single.guestPath, '/home/cc/a.txt');
    });

    test('an empty clipboard is a normal answer, not an error', () async {
      final data = await client.readClipboard(RigClipboardSelection.clipboard);

      expect(data.isEmpty, isTrue);
      expect(data.imageSkippedBytes, isNull);
    });

    test('an oversized image is dropped and its size reported', () async {
      // Half a PNG is a corrupt PNG, so it is left behind entirely — and the
      // caller is told how big it was so it can say so.
      final oversized =
          'A' * ((RigClipboardData.maxImageBytes + 1024) ~/ 3 * 4);
      body = jsonEncode({'image': oversized});

      final data = await client.readClipboard(RigClipboardSelection.clipboard);

      expect(data.hasImage, isFalse);
      expect(
        data.imageSkippedBytes,
        greaterThan(RigClipboardData.maxImageBytes),
      );
    });

    test('an image that predates the endpoint reads as an OLD image', () async {
      // A 404 here means the qcow2 on disk was built before protocol 2. That
      // is fixed by rebuilding an image, not by debugging a VM — so it must
      // not look like a machine fault.
      status = HttpStatus.notFound;
      body = '{"error": "no such endpoint"}';

      await expectLater(
        client.readClipboard(RigClipboardSelection.clipboard),
        throwsA(
          isA<GuestAgentTooOld>().having(
            (e) => e.endpoint,
            'endpoint',
            '/clipboard',
          ),
        ),
      );
    });

    test('writes only the flavours it was given', () async {
      await client.writeClipboard(RigClipboardData.ofText('hi'));

      final sent = jsonDecode(requests.single.body) as Map<String, dynamic>;
      expect(requests.single.method, 'POST');
      expect(sent, {'text': 'hi'});
      expect(sent.containsKey('image'), isFalse);
    });

    test('writes an image with its media type', () async {
      await client.writeClipboard(
        const RigClipboardData(
          imageBase64: 'QUFB',
          imageMediaType: 'image/png',
        ),
      );

      final sent = jsonDecode(requests.single.body) as Map<String, dynamic>;
      expect(sent['image'], 'QUFB');
      expect(sent['image_media_type'], 'image/png');
    });

    test('writes files as guest PATHS, never as bytes', () async {
      await client.writeClipboard(
        const RigClipboardData(
          files: [RigGuestFile(name: 'a.txt', guestPath: '/home/cc/a.txt')],
        ),
      );

      final sent = jsonDecode(requests.single.body) as Map<String, dynamic>;
      expect(sent['files'], ['/home/cc/a.txt']);
    });
  });
}
