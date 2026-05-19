import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/ports/credential_broker_port.dart';
import 'package:cc_domain/core/domain/value_objects/agent_capabilities.dart';
import 'package:cc_infra/src/rigs/guest_credential_service.dart';
import 'package:test/test.dart';

/// A broker that answers with a fixed token and records what it was asked for.
class _FakeBroker implements CredentialBrokerPort {
  _FakeBroker();

  static const String token = 'ghp_fake';
  bool fail = false;
  int mints = 0;
  final List<String> revoked = [];
  final List<String?> mintedFor = [];

  @override
  Future<ScopedCredentials> mint({
    required String conversationId,
    required AgentCapabilities capabilities,
    String? repoOwner,
    String? repoName,
    String? actingUserId,
  }) async {
    if (fail) {
      throw StateError('no credential available');
    }
    mints++;
    mintedFor.add(actingUserId);
    return ScopedCredentials(
      handle: 'handle-$mints',
      environment: {'GITHUB_TOKEN': token},
      expiresAt: DateTime.utc(2030),
    );
  }

  @override
  Future<void> revoke(String handle) async => revoked.add(handle);
}

/// The host-side broker endpoint is the ONE thing standing between a guest and
/// a real forge token, and it is reachable by every local process on the
/// machine as well as by the guest. Its hard rules — the allowlist, the rate
/// limit, indistinguishable rejections, revoke-on-close, the body cap — had no
/// test at all, so a regression in any of them would have been silent.
void main() {
  late _FakeBroker broker;
  late GuestCredentialService service;
  late int port;
  late HttpClient client;

  setUp(() async {
    broker = _FakeBroker();
    service = GuestCredentialService(broker: broker);
    port = await service.start();
    client = HttpClient();
  });

  tearDown(() async {
    client.close(force: true);
    await service.stop();
  });

  void register({
    String rigId = 'rig-1',
    String secret = 's3cret',
    Set<String> hosts = const {'github.com'},
    String? actingUserId,
  }) => service.registerRig(
    rigId: rigId,
    workspaceId: 'ws-1',
    conversationId: 'conv-1',
    secret: secret,
    allowedHosts: hosts,
    capabilities: const AgentCapabilities(canPushToRepo: true),
    actingUserId: actingUserId,
  );

  Future<HttpClientResponse> post(Object? body, {String path = '/credential'}) async {
    final request = await client.post('127.0.0.1', port, path);
    final bytes = utf8.encode(body is String ? body : jsonEncode(body));
    request.headers.contentType = ContentType.json;
    request.contentLength = bytes.length;
    request.add(bytes);
    return request.close();
  }

  Future<Map<String, dynamic>> readJson(HttpClientResponse response) async {
    final text = await response.transform(utf8.decoder).join();
    return jsonDecode(text) as Map<String, dynamic>;
  }

  group('happy path', () {
    test('mints a git-shaped credential for an allowed host', () async {
      register();
      final response = await post({
        'rig_id': 'rig-1',
        'secret': 's3cret',
        'host': 'github.com',
      });
      expect(response.statusCode, HttpStatus.ok);
      final body = await readJson(response);
      // The username half is not cosmetic: each forge treats a different
      // literal as significant, so a shared placeholder authenticates on
      // exactly one of the three.
      expect(body['username'], 'x-access-token');
      expect(body['password'], 'ghp_fake');
      expect(broker.mints, 1);
    });

    test('the answer is never cached', () async {
      register();
      final response = await post({
        'rig_id': 'rig-1',
        'secret': 's3cret',
        'host': 'github.com',
      });
      expect(response.headers.value(HttpHeaders.cacheControlHeader), 'no-store');
      await response.drain<void>();
    });
  });

  group('rejection', () {
    test('an unknown rig and a wrong secret are INDISTINGUISHABLE', () async {
      // Otherwise a local process can enumerate live rig ids by probing.
      register();
      final unknown = await post({
        'rig_id': 'rig-nope',
        'secret': 's3cret',
        'host': 'github.com',
      });
      final wrongSecret = await post({
        'rig_id': 'rig-1',
        'secret': 'wrong',
        'host': 'github.com',
      });
      expect(unknown.statusCode, HttpStatus.forbidden);
      expect(wrongSecret.statusCode, HttpStatus.forbidden);
      await unknown.drain<void>();
      await wrongSecret.drain<void>();
      expect(broker.mints, 0);
    });

    test('a host outside the rig allowlist is refused', () async {
      // The egress allowlist and this list are one policy seen from two sides:
      // a host the guest cannot reach must never be one we hand it a token for.
      register(hosts: {'github.com'});
      final response = await post({
        'rig_id': 'rig-1',
        'secret': 's3cret',
        'host': 'gitlab.com',
      });
      expect(response.statusCode, HttpStatus.forbidden);
      await response.drain<void>();
      expect(broker.mints, 0);
    });

    test('a rig registered with NO hosts gets nothing', () async {
      register(hosts: const {});
      final response = await post({
        'rig_id': 'rig-1',
        'secret': 's3cret',
        'host': 'github.com',
      });
      expect(response.statusCode, HttpStatus.forbidden);
      await response.drain<void>();
    });

    test('the host match is case-insensitive on both sides', () async {
      register(hosts: {'GitHub.com'});
      final response = await post({
        'rig_id': 'rig-1',
        'secret': 's3cret',
        'host': 'GITHUB.COM',
      });
      expect(response.statusCode, HttpStatus.ok);
      await response.drain<void>();
    });

    test('a non-POST or wrong path is a 404', () async {
      register();
      final get = await (await client.get('127.0.0.1', port, '/credential'))
          .close();
      expect(get.statusCode, HttpStatus.notFound);
      await get.drain<void>();
      final wrongPath = await post({
        'rig_id': 'rig-1',
      }, path: '/anything-else');
      expect(wrongPath.statusCode, HttpStatus.notFound);
      await wrongPath.drain<void>();
    });

    test('a malformed or non-object body is a 400', () async {
      register();
      for (final body in const ['not json', '[]', '"a string"']) {
        final response = await post(body);
        expect(response.statusCode, HttpStatus.badRequest, reason: body);
        await response.drain<void>();
      }
    });

    test('missing fields are a 400, not a crash', () async {
      register();
      final response = await post({'rig_id': 'rig-1'});
      expect(response.statusCode, HttpStatus.badRequest);
      await response.drain<void>();
    });

    test('a broker that cannot mint is a 503, not a 200 with no token',
        () async {
      register();
      broker.fail = true;
      final response = await post({
        'rig_id': 'rig-1',
        'secret': 's3cret',
        'host': 'github.com',
      });
      expect(response.statusCode, HttpStatus.serviceUnavailable);
      await response.drain<void>();
    });
  });

  group('body cap', () {
    test('an oversized body is refused', () async {
      // Every policy check runs only AFTER the body is buffered, and this
      // endpoint is reachable by every local process — so an unbounded read
      // let an unauthenticated caller allocate the server's heap without ever
      // passing the first check.
      register();
      final huge = jsonEncode({
        'rig_id': 'rig-1',
        'secret': 's3cret',
        'host': 'github.com',
        'padding': 'A' * (64 * 1024),
      });
      final response = await post(huge);
      expect(response.statusCode, HttpStatus.requestEntityTooLarge);
      await response.drain<void>();
      expect(broker.mints, 0);
    });

    test('a CHUNKED oversized body is refused too', () async {
      // A `Content-Length` header is a claim, not a fact; a chunked body
      // carries none at all, so the running total is what enforces the cap.
      register();
      final request = await client.post('127.0.0.1', port, '/credential');
      request.headers.contentType = ContentType.json;
      for (var i = 0; i < 16; i++) {
        request.add(utf8.encode('A' * 4096));
      }
      // Windows aborts the CLIENT's writer (WSAECONNABORTED, errno 10053)
      // when the server refuses mid-body and closes with data still
      // unread — the refusal itself was correct, which `mints` proves.
      final HttpClientResponse response;
      try {
        response = await request.close();
      } on SocketException {
        expect(broker.mints, 0);
        return;
      }
      expect(response.statusCode, HttpStatus.requestEntityTooLarge);
      await response.drain<void>();
      expect(broker.mints, 0);
    });
  });

  group('rate limit', () {
    test('30 mints a minute, then 429', () async {
      register();
      for (var i = 0; i < 30; i++) {
        final response = await post({
          'rig_id': 'rig-1',
          'secret': 's3cret',
          'host': 'github.com',
        });
        expect(response.statusCode, HttpStatus.ok, reason: 'request $i');
        await response.drain<void>();
      }
      final over = await post({
        'rig_id': 'rig-1',
        'secret': 's3cret',
        'host': 'github.com',
      });
      expect(over.statusCode, HttpStatus.tooManyRequests);
      await over.drain<void>();
      expect(broker.mints, 30);
    });

    test('the limit is PER RIG, not global', () async {
      register();
      register(rigId: 'rig-2', secret: 'other');
      for (var i = 0; i < 30; i++) {
        await (await post({
          'rig_id': 'rig-1',
          'secret': 's3cret',
          'host': 'github.com',
        })).drain<void>();
      }
      final second = await post({
        'rig_id': 'rig-2',
        'secret': 'other',
        'host': 'github.com',
      });
      expect(second.statusCode, HttpStatus.ok);
      await second.drain<void>();
    });
  });

  group('revocation', () {
    test('closing a rig revokes every token it was ever handed', () async {
      register();
      for (var i = 0; i < 3; i++) {
        await (await post({
          'rig_id': 'rig-1',
          'secret': 's3cret',
          'host': 'github.com',
        })).drain<void>();
      }
      await service.unregisterRig('rig-1');
      expect(broker.revoked, ['handle-1', 'handle-2', 'handle-3']);
    });

    test('an unregistered rig can no longer mint', () async {
      register();
      await service.unregisterRig('rig-1');
      final response = await post({
        'rig_id': 'rig-1',
        'secret': 's3cret',
        'host': 'github.com',
      });
      expect(response.statusCode, HttpStatus.forbidden);
      await response.drain<void>();
    });

    test('stop() revokes every outstanding grant', () async {
      register();
      register(rigId: 'rig-2', secret: 'other');
      await (await post({
        'rig_id': 'rig-1',
        'secret': 's3cret',
        'host': 'github.com',
      })).drain<void>();
      await (await post({
        'rig_id': 'rig-2',
        'secret': 'other',
        'host': 'github.com',
      })).drain<void>();
      await service.stop();
      expect(broker.revoked, hasLength(2));
      expect(service.isRunning, isFalse);
    });

    test('unregistering an unknown rig is a no-op, not a throw', () async {
      await service.unregisterRig('never-existed');
      expect(broker.revoked, isEmpty);
    });
  });

  group('lifecycle', () {
    test('start() is idempotent and keeps the same port', () async {
      final again = await service.start();
      expect(again, port);
    });
  });

  group('the guest credential is bound to the rig\'s opener', () {
    test('mints for the member who opened the rig, not the server', () async {
      // A rig cannot tell WHICH process inside it is asking — an agent and a
      // human shell reach this endpoint identically. Binding the grant to the
      // opener is what stops an enclosure handing out more forge access than
      // the person who asked for it already had, whatever the spec's
      // capability flags say.
      register(actingUserId: 'user-alice');
      final response = await post({
        'rig_id': 'rig-1',
        'secret': 's3cret',
        'host': 'github.com',
      });
      expect(response.statusCode, 200);
      await response.drain<void>();

      expect(broker.mintedFor, ['user-alice']);
    });

    test('falls back to the server when nobody opened it', () async {
      // A rig opened by background work is the server acting as itself.
      register();
      final response = await post({
        'rig_id': 'rig-1',
        'secret': 's3cret',
        'host': 'github.com',
      });
      expect(response.statusCode, 200);
      await response.drain<void>();

      expect(broker.mintedFor, [null]);
    });
  });
}
