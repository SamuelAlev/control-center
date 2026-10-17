import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_server_core/src/push/web_push_repository.dart';
import 'package:webcrypto/webcrypto.dart' as wc;
import 'package:webpush_encryption/webpush_encryption.dart';

String _b64(List<int> bytes) => base64Url.encode(bytes).replaceAll('=', '');
List<int> _decode(String value) => base64Url.decode(base64Url.normalize(value));

/// Only browser push services. A subscription endpoint is attacker-controlled
/// input even though it arrived through an authenticated Noise channel.
Uri validatedPushEndpoint(String value) {
  if (value.length > 2048) {
    throw const FormatException('Invalid push endpoint');
  }
  final uri = Uri.tryParse(value);
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.userInfo.isNotEmpty ||
      uri.hasFragment ||
      uri.host.isEmpty ||
      uri.port != 443 ||
      !const {
        'fcm.googleapis.com',
        'updates.push.services.mozilla.com',
        'web.push.apple.com',
      }.contains(uri.host.toLowerCase()) ||
      uri.path.isEmpty ||
      uri.path == '/') {
    throw const FormatException('Unsupported push provider endpoint');
  }
  return uri;
}

/// RFC 8292 signing key; the raw public key is sent to the browser and to the
/// push service; the private PKCS#8 key remains in FileSecretsStore.
class VapidIdentity {
  /// Pairs the private signer with its base64url-encoded raw public key.
  VapidIdentity(this.privateKey, this.publicKey);

  /// P-256 signer retained only in the server's secret store.
  final wc.EcdsaPrivateKey privateKey;

  /// Uncompressed P-256 public key supplied to browser subscriptions.
  final String publicKey;

  /// Generates a signing identity and its owner-only persistence representation.
  static Future<({VapidIdentity identity, String persisted})> generate() async {
    final keys = await wc.EcdsaPrivateKey.generateKey(wc.EllipticCurve.p256);
    final rawPublic = await keys.publicKey.exportRawKey();
    final privateBytes = await keys.privateKey.exportPkcs8Key();
    return (
      identity: VapidIdentity(keys.privateKey, _b64(rawPublic)),
      persisted: jsonEncode({
        'public': _b64(rawPublic),
        'private': _b64(privateBytes),
      }),
    );
  }

  /// Restores a persisted PKCS#8 signer and associated raw public key.
  static Future<VapidIdentity> restore(String persisted) async {
    final data = jsonDecode(persisted) as Map<String, dynamic>;
    final public = data['public'] as String;
    if (_decode(public).length != 65) {
      throw const FormatException('Invalid VAPID key');
    }
    return VapidIdentity(
      await wc.EcdsaPrivateKey.importPkcs8Key(
        _decode(data['private'] as String),
        wc.EllipticCurve.p256,
      ),
      public,
    );
  }

  /// Signs a one-hour, provider-origin-bound RFC 8292 authorization header.
  Future<String> authorization(Uri endpoint, {DateTime? now}) async {
    final audience = '${endpoint.scheme}://${endpoint.host}';
    final issued =
        (now ?? DateTime.now().toUtc()).millisecondsSinceEpoch ~/ 1000;
    final header = _b64(
      utf8.encode(jsonEncode({'typ': 'JWT', 'alg': 'ES256'})),
    );
    final payload = _b64(
      utf8.encode(
        jsonEncode({
          'aud': audience,
          'exp': issued + 3600,
          'sub': 'https://github.com/SamuelAlev/control-center',
        }),
      ),
    );
    final content = '$header.$payload';
    final signature = await privateKey.signBytes(
      utf8.encode(content),
      wc.Hash.sha256,
    );
    if (signature.length != 64) {
      throw StateError('Invalid ES256 signature');
    }
    return 'vapid t=$content.${_b64(signature)}, k=$publicKey';
  }
}

/// Provider response classification; acceptance does not prove device display.
enum PushDeliveryResult {
  /// The push service accepted the encrypted message.
  delivered,

  /// The push service no longer recognizes the subscription.
  expired,

  /// Delivery failed or was no longer authorized before submission.
  unavailable,
}

/// Exact HTTP fields sent to a push provider, independently testable without
/// a DNS exception or a live third-party endpoint.
typedef WebPushWireMessage = ({
  Uri endpoint,
  Map<String, String> headers,
  Uint8List body,
});

/// Encrypts an RFC 8291 payload and signs provider-bound VAPID headers.
Future<WebPushWireMessage> buildWebPushWireMessage({
  required PushSubscriptionRecord subscription,
  required VapidIdentity vapid,
  required Uint8List payload,
}) async {
  final endpoint = validatedPushEndpoint(subscription.endpoint);
  final publicKey = _decode(subscription.p256dh);
  final authKey = _decode(subscription.auth);
  if (publicKey.length != 65 || publicKey.first != 4 || authKey.length != 16) {
    throw const FormatException('Invalid subscription keys');
  }
  final clientKeys = await PublicWebPushKey.fromMap({
    'p256dh': publicKey,
    'auth': authKey,
  });
  final encrypted = await WebPush().encrypt(
    serverKeys: await WebPushKeySet.newKeyPair(),
    clientKeys: clientKeys,
    plaintext: payload,
  );
  return (
    endpoint: endpoint,
    headers: {
      'Authorization': await vapid.authorization(endpoint),
      'Content-Encoding': 'aes128gcm',
      'Content-Type': 'application/octet-stream',
      'TTL': '300',
      'Urgency': 'normal',
    },
    body: encrypted,
  );
}

/// RFC 8291 `aes128gcm` payload, RFC 8292 VAPID JWT. Never follows redirects.
/// DNS is resolved and checked before dial, then the validated IP is pinned
/// via connectionFactory (a second resolution would permit rebinding).
class WebPushTransport {
  /// Creates a public-HTTPS-only transport with redirect-free, pinned-IP dialing.
  const WebPushTransport();

  /// Rechecks [maySend], when supplied, immediately before the provider POST.
  Future<PushDeliveryResult> send({
    required PushSubscriptionRecord subscription,
    required VapidIdentity vapid,
    required Uint8List payload,
    Future<bool> Function()? maySend,
  }) async {
    final uri = validatedPushEndpoint(subscription.endpoint);
    final addresses = await InternetAddress.lookup(
      uri.host,
    ).timeout(const Duration(seconds: 3));
    if (addresses.isEmpty ||
        addresses.any((address) => !isPublicPushAddress(address))) {
      throw const FormatException(
        'Push endpoint resolves to a private address',
      );
    }
    final address = addresses.firstWhere(
      (value) => value.type == InternetAddressType.IPv4,
      orElse: () => addresses.first,
    );
    final wire = await buildWebPushWireMessage(
      subscription: subscription,
      vapid: vapid,
      payload: payload,
    );
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 4)
      ..findProxy = ((_) => 'DIRECT')
      ..connectionFactory = (target, proxyHost, proxyPort) =>
          Socket.startConnect(address, target.port);
    try {
      if (maySend != null && !await maySend()) {
        return PushDeliveryResult.unavailable;
      }
      final request = await client
          .postUrl(wire.endpoint)
          .timeout(const Duration(seconds: 5));
      request.followRedirects = false;
      wire.headers.forEach((name, value) => request.headers.set(name, value));
      request.contentLength = wire.body.length;
      request.add(wire.body);
      final response = await request.close().timeout(
        const Duration(seconds: 6),
      );
      // Never read/reflect provider response text (which may include the
      // capability URL); closing the client in finally releases its socket.
      if (response.statusCode == 404 || response.statusCode == 410) {
        return PushDeliveryResult.expired;
      }
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return PushDeliveryResult.delivered;
      }
      return PushDeliveryResult.unavailable;
    } on TimeoutException {
      return PushDeliveryResult.unavailable;
    } on SocketException {
      return PushDeliveryResult.unavailable;
    } finally {
      client.close(force: true);
    }
  }
}

/// Rejects private, local and reserved address ranges before pinning the dial.
bool isPublicPushAddress(InternetAddress address) {
  if (address.isLoopback || address.isLinkLocal || address.isMulticast) {
    return false;
  }
  final b = address.rawAddress;
  if (address.type == InternetAddressType.IPv4) {
    final a = b[0], second = b[1];
    return a > 0 &&
        a < 224 &&
        a != 10 &&
        a != 127 &&
        !(a == 100 && second >= 64 && second <= 127) &&
        !(a == 169 && second == 254) &&
        !(a == 172 && second >= 16 && second <= 31) &&
        !(a == 192 &&
            (second == 0 || second == 2 || second == 88 || second == 168)) &&
        !(a == 198 &&
            (second == 18 || second == 19 || (second == 51 && b[2] == 100))) &&
        !(a == 203 && second == 0 && b[2] == 113);
  }
  if (address.type != InternetAddressType.IPv6) {
    return false;
  }
  // Block ULA, unspecified, documentation/reserved and mapped IPv4.
  return b[0] >= 0x20 &&
      b[0] <= 0x3f &&
      !(b[0] == 0x20 && b[1] == 0x01 && b[2] == 0x0d && b[3] == 0xb8);
}
