import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_rpc/src/channel/remote_rpc_channel_port.dart';
import 'package:cc_rpc/src/channel/secure_rpc_channel.dart';
import 'package:cc_rpc/src/crypto/noise_session.dart';
import 'package:cc_rpc/src/crypto/server_identity.dart';

/// An authenticated, forward-secret connection. The caller owns [channel].
final class SecureChannelConnection {
  const SecureChannelConnection({
    required this.channel,
    required this.deviceId,
    required this.serverFingerprint,
  });

  final SecureRpcChannel channel;
  final String deviceId;
  final String serverFingerprint;
}

/// Establishes Noise and verifies the server's transcript-bound identity.
/// A missing signature is always fatal, including the first TOFU connection.
Future<SecureChannelConnection> connectSecureChannel({
  required RemoteRpcChannelPort channel,
  required String deviceId,
  required String psk,
  String? pinnedFingerprint,
  Duration timeout = const Duration(seconds: 15),
}) async {
  NoisePskHandshake? handshake;
  SecureRpcChannel? secure;
  try {
    handshake = NoisePskHandshake(
      initiator: true,
      psk: _pairingBytes(psk),
      prologue: _prologue(deviceId),
    );
    final initial = await handshake.writeMessage(const []);
    final reply = _readOne(channel, timeout);
    // A synchronous send failure must not leave a later timeout unhandled.
    unawaited(reply.then<void>((_) {}, onError: (Object _) {}));
    await channel.send({
      'type': 'secure_hello',
      'v': SecureRpcChannel.version,
      'device_id': deviceId,
      'handshake': base64Url.encode(initial),
    });
    final frame = await reply;
    if (frame['type'] == 'secure_denied') {
      throw const SecureHandshakeException('Device authentication rejected');
    }
    final response = _handshakeBytes(frame, 'secure_welcome');
    final clear = await handshake.readMessage(response);
    final identity = jsonDecode(utf8.decode(clear));
    if (identity is! Map<String, dynamic>) {
      throw const SecureHandshakeException('Missing server identity');
    }
    final publicKey = identity['public_key'];
    final signature = identity['signature'];
    if (publicKey is! String ||
        signature is! String ||
        !await ServerIdentityCrypto.verifyChallenge(
          nonce: _identityChallenge(handshake.identityBinding),
          publicKeyB64: publicKey,
          signatureB64: signature,
        )) {
      throw const SecureHandshakeException('Invalid server identity proof');
    }
    final fingerprint = ServerIdentityCrypto.fingerprintOf(publicKey);
    if (pinnedFingerprint != null &&
        pinnedFingerprint.isNotEmpty &&
        pinnedFingerprint != fingerprint) {
      throw ServerIdentityMismatchException(
        expectedFingerprint: pinnedFingerprint,
        actualFingerprint: fingerprint,
      );
    }
    secure = SecureRpcChannel(channel, handshake.takeSession());
    // No early application data. This also proves a live client knows the
    // fresh DH keys: replaying an old initial PSK proof cannot open a session.
    await secure.send(const {'type': 'secure_ready'});
    return SecureChannelConnection(
      channel: secure,
      deviceId: deviceId,
      serverFingerprint: fingerprint,
    );
  } catch (error) {
    await (secure ?? channel).close();
    if (error is ServerIdentityMismatchException ||
        error is SecureHandshakeException) {
      rethrow;
    }
    throw const SecureHandshakeException('Secure handshake failed');
  } finally {
    handshake?.destroy();
  }
}

/// Server half. [readPsk] must enforce active-device/expiry policy before
/// returning a key. The relay never participates in this decision.
Future<SecureChannelConnection> acceptSecureChannel({
  required RemoteRpcChannelPort channel,
  required Future<String?> Function(String deviceId) readPsk,
  required String serverPublicKey,
  required Future<String> Function(String challenge) signIdentity,
  Duration timeout = const Duration(seconds: 15),
}) async {
  NoisePskHandshake? handshake;
  SecureRpcChannel? secure;
  try {
    final hello = await _readOne(channel, timeout);
    final initial = _handshakeBytes(hello, 'secure_hello');
    final deviceId = hello['device_id'];
    if (deviceId is! String || deviceId.isEmpty || deviceId.length > 256) {
      throw const SecureHandshakeException('Invalid device identity');
    }
    final psk = await readPsk(deviceId).timeout(timeout);
    if (psk == null) {
      throw const SecureHandshakeException('Device authentication rejected');
    }
    handshake = NoisePskHandshake(
      initiator: false,
      psk: _pairingBytes(psk),
      prologue: _prologue(deviceId),
    );
    final early = await handshake.readMessage(initial);
    if (early.isNotEmpty) {
      throw const SecureHandshakeException('Early application data forbidden');
    }
    final response = await handshake.writeMessage(
      const [],
      payloadBuilder: (transcript) async => utf8.encode(
        jsonEncode({
          'public_key': serverPublicKey,
          'signature': await signIdentity(_identityChallenge(transcript)),
        }),
      ),
    );
    secure = SecureRpcChannel(channel, handshake.takeSession());
    final ready = _readOne(secure, timeout);
    unawaited(ready.then<void>((_) {}, onError: (Object _) {}));
    await channel.send({
      'type': 'secure_welcome',
      'v': SecureRpcChannel.version,
      'handshake': base64Url.encode(response),
    });
    final confirmation = await ready;
    if (confirmation.length != 1 || confirmation['type'] != 'secure_ready') {
      throw const SecureHandshakeException('Missing session confirmation');
    }
    return SecureChannelConnection(
      channel: secure,
      deviceId: deviceId,
      serverFingerprint: ServerIdentityCrypto.fingerprintOf(serverPublicKey),
    );
  } catch (error) {
    if (secure == null && channel.isOpen) {
      try {
        await channel.send(const {'type': 'secure_denied'});
      } catch (_) {
        // The only pre-auth reply is a generic denial, never policy details.
      }
    }
    await (secure ?? channel).close();
    if (error is SecureHandshakeException) rethrow;
    throw const SecureHandshakeException('Secure handshake failed');
  } finally {
    handshake?.destroy();
  }
}

Future<Map<String, dynamic>> _readOne(
  RemoteRpcChannelPort channel,
  Duration timeout,
) async {
  final next = Completer<Map<String, dynamic>>();
  final sub = channel.incoming.listen(
    (frame) {
      if (!next.isCompleted) next.complete(frame);
    },
    onError: (Object error, StackTrace stack) {
      if (!next.isCompleted) next.completeError(error, stack);
    },
    onDone: () {
      if (!next.isCompleted) {
        next.completeError(const SecureHandshakeException('Peer disconnected'));
      }
    },
  );
  try {
    return await next.future.timeout(timeout);
  } finally {
    await sub.cancel();
  }
}

Uint8List _pairingBytes(String psk) {
  try {
    final bytes = base64Url.decode(base64Url.normalize(psk));
    if (bytes.length == 32) return bytes;
  } catch (_) {
    // FormatException can include its input. Never expose pairing material.
  }
  throw const SecureHandshakeException('Invalid pairing credential');
}

Uint8List _handshakeBytes(Map<String, dynamic> frame, String type) {
  final encoded = frame['handshake'];
  if (frame['type'] != type ||
      frame['v'] != SecureRpcChannel.version ||
      encoded is! String ||
      encoded.length > 8192) {
    throw const SecureHandshakeException('Unsupported secure handshake');
  }
  try {
    return base64Url.decode(encoded);
  } catch (_) {
    throw const SecureHandshakeException('Invalid secure handshake');
  }
}

List<int> _prologue(String deviceId) => utf8.encode(
  jsonEncode([
    'control-center-secure-channel',
    SecureRpcChannel.version,
    deviceId,
  ]),
);
String _identityChallenge(List<int> transcript) =>
    'cc-noise-identity-v1|${base64Url.encode(transcript)}';

final class SecureHandshakeException implements Exception {
  const SecureHandshakeException(this.message);
  final String message;
  @override
  String toString() => 'SecureHandshakeException: $message';
}
