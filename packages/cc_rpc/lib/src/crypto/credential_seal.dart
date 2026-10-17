import 'dart:convert';

import 'package:cryptography/cryptography.dart';

/// One-way, client-held encryption for bootstrap credentials. This protects
/// the newly minted PSK from a passive HTTP intermediary; it does NOT
/// authenticate the first-party SSO/web origin or replace the authenticated
/// Noise channel used after pairing.
final class CredentialSeal {
  CredentialSeal._();

  static final _dh = X25519();
  static final _kdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
  static final _cipher = AesGcm.with256bits();
  static final _context = utf8.encode('cc-bootstrap-credential-seal-v1');

  /// Generates a fresh recipient pair for a single browser login or demo join.
  static Future<({String publicKey, String privateKey})> newRecipient() async {
    final pair = await _dh.newKeyPair();
    try {
      final public = await pair.extractPublicKey();
      final private = await pair.extractPrivateKeyBytes();
      return (publicKey: _encode(public.bytes), privateKey: _encode(private));
    } finally {
      pair.destroy();
    }
  }

  /// Only canonical 32-byte X25519 public keys are accepted at login start.
  static bool isValidPublicKey(String? value) {
    if (value == null || !RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(value)) {
      return false;
    }
    try {
      return _decode32(value).any((byte) => byte != 0);
    } catch (_) {
      return false;
    }
  }

  /// Authenticates the plaintext to the recipient key and [context]. Only a
  /// 32-byte X25519 public key is accepted; a missing key must fail closed.
  static Future<Map<String, String>> seal({
    required String recipientPublicKey,
    required Map<String, dynamic> credential,
    required String context,
  }) async {
    final recipient = SimplePublicKey(
      _decode32(recipientPublicKey),
      type: KeyPairType.x25519,
    );
    final ephemeral = await _dh.newKeyPair();
    try {
      final public = await ephemeral.extractPublicKey();
      final key = await _derive(
        ephemeral,
        recipient,
        public.bytes,
        recipient.bytes,
      );
      try {
        final nonce = _cipher.newNonce();
        final box = await _cipher.encrypt(
          utf8.encode(jsonEncode(credential)),
          secretKey: key,
          nonce: nonce,
          aad: _aad(context),
        );
        return {
          'v': '1',
          'e': _encode(public.bytes),
          'c': _encode(box.concatenation()),
        };
      } finally {
        key.destroy();
      }
    } finally {
      ephemeral.destroy();
    }
  }

  /// Decrypts with the key generated before the login began. No plaintext
  /// credential compatibility path is accepted.
  static Future<Map<String, dynamic>> open({
    required String recipientPrivateKey,
    required Map<String, dynamic> envelope,
    required String context,
  }) async {
    if (envelope['v'] != '1' ||
        envelope['e'] is! String ||
        envelope['c'] is! String) {
      throw const FormatException('Invalid credential envelope');
    }
    final pair = await _dh.newKeyPairFromSeed(_decode32(recipientPrivateKey));
    try {
      final public = await pair.extractPublicKey();
      final remote = SimplePublicKey(
        _decode32(envelope['e'] as String),
        type: KeyPairType.x25519,
      );
      final key = await _derive(pair, remote, remote.bytes, public.bytes);
      try {
        final box = SecretBox.fromConcatenation(
          _decode(envelope['c'] as String),
          nonceLength: 12,
          macLength: 16,
        );
        final decoded = jsonDecode(
          utf8.decode(
            await _cipher.decrypt(box, secretKey: key, aad: _aad(context)),
          ),
        );
        if (decoded is! Map<String, dynamic>) {
          throw const FormatException('Invalid credential payload');
        }
        return decoded;
      } finally {
        key.destroy();
      }
    } finally {
      pair.destroy();
    }
  }

  static Future<SecretKeyData> _derive(
    SimpleKeyPair pair,
    SimplePublicKey remote,
    List<int> ephemeralPublic,
    List<int> recipientPublic,
  ) async {
    final shared = await _dh.sharedSecretKey(
      keyPair: pair,
      remotePublicKey: remote,
    );
    try {
      final bytes = await shared.extractBytes();
      if (bytes.every((byte) => byte == 0)) {
        throw const FormatException('Invalid recipient key');
      }
      return await _kdf.deriveKey(
        secretKey: shared,
        nonce: [..._context, ...ephemeralPublic, ...recipientPublic],
      );
    } finally {
      shared.destroy();
    }
  }

  static List<int> _aad(String context) =>
      utf8.encode('cc-bootstrap-credential-v1|$context');
  static String _encode(List<int> bytes) =>
      base64Url.encode(bytes).replaceAll('=', '');
  static List<int> _decode(String value) =>
      base64Url.decode(base64Url.normalize(value));
  static List<int> _decode32(String value) {
    final bytes = _decode(value);
    if (bytes.length != 32) {
      throw const FormatException('Invalid recipient key');
    }
    return bytes;
  }
}
