import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_server_core/src/push/web_push_service.dart';
import 'package:cc_server_core/src/push/web_push_repository.dart';
import 'package:cc_server_core/src/push/web_push_transport.dart';
import 'package:test/test.dart';
import 'package:webcrypto/webcrypto.dart' as wc;
import 'package:webpush_encryption/webpush_encryption.dart';

void main() {
  test('VAPID persists one P-256 identity and signs an origin-bound ES256 JWT', () async {
    final generated = await VapidIdentity.generate();
    final restored = await VapidIdentity.restore(generated.persisted);
    expect(restored.publicKey, generated.identity.publicKey);
    final endpoint = validatedPushEndpoint('https://fcm.googleapis.com/fcm/send/opaque');
    final authorization = await restored.authorization(endpoint,
        now: DateTime.utc(2026, 1, 1));
    expect(authorization, startsWith('vapid t='));
    final token = authorization.split(',').first.substring('vapid t='.length);
    final fields = token.split('.');
    expect(fields, hasLength(3));
    final claims = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(fields[1])))) as Map;
    expect(claims['aud'], 'https://fcm.googleapis.com');
    expect(claims['exp'], DateTime.utc(2026, 1, 1).millisecondsSinceEpoch ~/ 1000 + 3600);
    final public = await wc.EcdsaPublicKey.importRawKey(
      base64Url.decode(base64Url.normalize(restored.publicKey)), wc.EllipticCurve.p256);
    expect(await public.verifyBytes(
      base64Url.decode(base64Url.normalize(fields[2])),
      utf8.encode('${fields[0]}.${fields[1]}'), wc.Hash.sha256), isTrue);
  });

  test('RFC8291 encrypted payload can be decrypted by subscription keys', () async {
    final browserKeys = await WebPushKeySet.newKeyPair();
    final serverKeys = await WebPushKeySet.newKeyPair();
    final payload = Uint8List.fromList(utf8.encode('{"v":1,"route":"/inbox"}'));
    final encrypted = await WebPush().encrypt(
      serverKeys: serverKeys,
      clientKeys: browserKeys.publicKey,
      plaintext: payload,
      salt: Uint8List.fromList(List<int>.generate(16, (i) => i)),
    );
    expect(encrypted.length, greaterThan(payload.length));
    expect(await WebPush().decrypt(browserKeys, encrypted), payload);
  });

  test('HTTP message carries encrypted body and exact VAPID/TTL headers', () async {
    final recipient = await WebPushKeySet.newKeyPair();
    final identity = (await VapidIdentity.generate()).identity;
    final plaintext = Uint8List.fromList(utf8.encode(
      '{\"v\":1,\"route\":\"/spaces/s-1?workspace_id=w-1\"}'));
    final request = await buildWebPushWireMessage(
      subscription: PushSubscriptionRecord(
        endpoint: 'https://updates.push.services.mozilla.com/wpush/v2/opaque',
        p256dh: recipient.publicKey.p256dh,
        auth: recipient.publicKey.auth,
        categories: const {'newMessage'},
        quiet: false,
      ),
      vapid: identity,
      payload: plaintext,
    );
    expect(request.endpoint.host, 'updates.push.services.mozilla.com');
    expect(request.headers['Content-Encoding'], 'aes128gcm');
    expect(request.headers['Content-Type'], 'application/octet-stream');
    expect(request.headers['TTL'], '300');
    expect(request.headers['Authorization'], startsWith('vapid t='));
    expect(request.body, isNot(plaintext));
    expect(await WebPush().decrypt(recipient, request.body), plaintext);
  });

  test('resolved addresses reject private, metadata and mapped-loopback targets', () {
    for (final address in [
      '127.0.0.1', '10.2.3.4', '172.16.0.1', '192.168.1.1',
      '169.254.169.254', '100.100.100.200', '0.0.0.0',
      '192.0.2.1', '198.51.100.2', '203.0.113.1',
      '::1', 'fc00::1', 'fe80::1', '::ffff:127.0.0.1',
    ]) {
      expect(isPublicPushAddress(InternetAddress(address)), isFalse,
          reason: address);
    }
    expect(isPublicPushAddress(InternetAddress('8.8.8.8')), isTrue);
    expect(isPublicPushAddress(InternetAddress('2607:f8b0:4000::1')), isTrue);
  });

  test('endpoint allowlist prevents SSRF, downgraded or redirected targets', () {
    expect(validatedPushEndpoint('https://web.push.apple.com/Q/token').host,
        'web.push.apple.com');
    for (final invalid in [
      'http://fcm.googleapis.com/fcm/send/id',
      'https://fcm.googleapis.com.evil.test/send',
      'https://localhost/fcm/send',
      'https://127.0.0.1/fcm/send',
      'https://[::1]/fcm/send',
      'https://user@fcm.googleapis.com/fcm/send/id',
      'https://fcm.googleapis.com:444/fcm/send/id',
      'https://fcm.googleapis.com/fcm/send/id#fragment',
    ]) {
      expect(() => validatedPushEndpoint(invalid), throwsFormatException,
          reason: invalid);
    }
  });

  test('push principal routing and route omit preview, URLs and unauthorized targets', () {
    final message = <String, dynamic>{
      'workspace_id': 'ws-1', 'space_id': 'space-1',
      'conversation_id': 'convo-1', 'message_id': 'msg-1',
      'is_agent_message': true, 'requested_by_user_id': 'alice',
      'sender_user_id': 'bob', 'content_preview': 'private text',
      'link': 'https://evil.test/credential',
    };
    expect(pushFrameTargetsUser('notifications/message_received', message, 'alice'), isTrue);
    expect(pushFrameTargetsUser('notifications/message_received', message, 'carol'), isFalse);
    expect(pushFrameTargetsUser('notifications/message_received', message, 'bob'), isFalse);
    final route = safePushRoute('ws-1', 'notifications/message_received', message);
    expect(route, contains('workspace_id=ws-1'));
    expect(route, contains('conversation_id=convo-1'));
    expect(route, contains('message_id=msg-1'));
    expect(route, isNot(contains('private text')));
    expect(route, isNot(contains('evil.test')));
    expect(pushFrameTargetsUser('notifications/pr_approved',
      {'for_user_id': 'alice'}, 'carol'), isFalse);
    expect(pushFrameTargetsUser('notifications/ticket_assigned',
      {'assignee_type': 'user', 'assigned_agent_id': 'alice'}, 'carol'), isFalse);
    expect(safePushRoute('ws-1', 'notifications/calendar_auth_expired',
      {'meeting_url': 'https://evil.test'}), '/inbox?workspace_id=ws-1');
  });
}
