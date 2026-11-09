import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_connect/src/gcp_auth.dart';
import 'package:cc_connect/src/secrets.dart';
import 'package:cc_connect/src/upstream_http.dart';
import 'package:cc_connect_core/cc_connect_core.dart';
import 'package:cryptography/cryptography.dart';

/// Ciphertext plus the key that made it (a keyring kid, or `kms`).
final class SealCiphertext {
  /// Creates the value.
  const SealCiphertext(this.keyId, this.bytes);

  /// Which key decrypts [bytes].
  final String keyId;

  /// The AEAD output.
  final List<int> bytes;
}

/// The ciphertext did not authenticate (wrong key, wrong AAD, tampered).
/// Always answered `access_denied`.
final class SealDecryptFailed implements Exception {
  /// Creates the exception.
  const SealDecryptFailed();

  @override
  String toString() => 'SealDecryptFailed';
}

/// Symmetric AEAD for credential seals.
abstract interface class SealCipher {
  /// Encrypts [plaintext] bound to [aad] under the active key.
  Future<SealCiphertext> encrypt(List<int> plaintext, List<int> aad);

  /// Decrypts [ciphertext] bound to [aad]. Throws [SealDecryptFailed] when it
  /// does not authenticate, [UpstreamUnavailable] when the key service is
  /// unreachable.
  Future<List<int>> decrypt(SealCiphertext ciphertext, List<int> aad);
}

final RegExp _kidShape = RegExp(r'^[A-Za-z0-9_-]{1,32}$');

/// Parses a local keyring: `kid:base64key,kid:base64key`, first active. Keys
/// are 32 bytes in standard or url-safe base64. Throws [FormatException].
List<({String kid, List<int> key})> parseSealKeyring(String raw) {
  final out = <({String kid, List<int> key})>[];
  final seen = <String>{};
  for (final part in raw.split(',')) {
    final entry = part.trim();
    if (entry.isEmpty) {
      continue;
    }
    final colon = entry.indexOf(':');
    if (colon <= 0) {
      throw const FormatException('seal key entry is kid:base64key');
    }
    final kid = entry.substring(0, colon);
    if (!_kidShape.hasMatch(kid) || !seen.add(kid)) {
      throw const FormatException('seal key id is invalid or repeated');
    }
    final List<int> key;
    try {
      key = unb64url(
        entry.substring(colon + 1).replaceAll('+', '-').replaceAll('/', '_'),
      );
    } on FormatException {
      throw const FormatException('seal key is not base64');
    }
    if (key.length != 32) {
      throw const FormatException('seal keys are 32 bytes');
    }
    out.add((kid: kid, key: key));
  }
  if (out.isEmpty) {
    throw const FormatException('seal keyring is empty');
  }
  return out;
}

/// A fresh keyring entry (`config_tool seal-key`).
String newSealKeyEntry({DateTime? now}) {
  final at = (now ?? DateTime.now()).toUtc();
  final date =
      '${at.year}${'${at.month}'.padLeft(2, '0')}${'${at.day}'.padLeft(2, '0')}';
  final suffix = crockfordBase32(randomBytes(3)).toLowerCase().substring(0, 4);
  return 'k$date$suffix:${base64.encode(randomBytes(32))}';
}

/// AES-256-GCM under a local keyring. The keyring is re-read from its
/// source (file-backed sources refresh every 30 s), so adding a key and then
/// moving it first rotates without a restart.
final class LocalAeadSealCipher implements SealCipher {
  /// Creates the cipher over a keyring source.
  LocalAeadSealCipher(this._keys) {
    _parsed(); // Fail fast at boot on a malformed keyring.
  }

  final SecretSource _keys;
  final AesGcm _aead = AesGcm.with256bits();
  String _lastRaw = '';
  List<({String kid, List<int> key})> _ring = const [];

  List<({String kid, List<int> key})> _parsed() {
    final raw = _keys.value;
    if (raw != _lastRaw || _ring.isEmpty) {
      _ring = parseSealKeyring(raw);
      _lastRaw = raw;
    }
    return _ring;
  }

  @override
  Future<SealCiphertext> encrypt(List<int> plaintext, List<int> aad) async {
    final active = _parsed().first;
    final box = await _aead.encrypt(
      plaintext,
      secretKey: SecretKey(active.key),
      nonce: _aead.newNonce(),
      aad: aad,
    );
    return SealCiphertext(
      active.kid,
      Uint8List.fromList([...box.nonce, ...box.cipherText, ...box.mac.bytes]),
    );
  }

  @override
  Future<List<int>> decrypt(SealCiphertext ciphertext, List<int> aad) async {
    final ({String kid, List<int> key})? entry;
    try {
      entry = _parsed().where((e) => e.kid == ciphertext.keyId).firstOrNull;
    } on FormatException {
      throw const SealDecryptFailed();
    }
    final bytes = ciphertext.bytes;
    const nonceLength = 12;
    const macLength = 16;
    if (entry == null || bytes.length < nonceLength + macLength) {
      throw const SealDecryptFailed();
    }
    final box = SecretBox(
      bytes.sublist(nonceLength, bytes.length - macLength),
      nonce: bytes.sublist(0, nonceLength),
      mac: Mac(bytes.sublist(bytes.length - macLength)),
    );
    try {
      return await _aead.decrypt(
        box,
        secretKey: SecretKey(entry.key),
        aad: aad,
      );
    } on SecretBoxAuthenticationError {
      throw const SealDecryptFailed();
    } on Object {
      throw const SealDecryptFailed();
    }
  }
}

/// Cloud KMS symmetric AEAD (`:encrypt` / `:decrypt` with
/// `additionalAuthenticatedData`). KMS tracks key versions inside its
/// ciphertext, so the key id is always `kms`.
final class GcpKmsSealCipher implements SealCipher {
  /// Creates the cipher for [keyName]
  /// (`projects/…/locations/…/keyRings/…/cryptoKeys/…`).
  GcpKmsSealCipher({
    required this.keyName,
    required this._http,
    required this._tokens,
  });

  /// The KMS key resource name.
  final String keyName;
  final UpstreamHttp _http;
  final GcpTokenSource _tokens;

  /// The key id recorded in seal headers.
  static const String kmsKeyId = 'kms';

  Uri _url(String verb) =>
      Uri.parse('https://cloudkms.googleapis.com/v1/$keyName:$verb');

  Future<UpstreamResponse> _call(String verb, Map<String, Object?> body) async {
    final token = await _tokens.token();
    return _http.send(
      UpstreamRequest.json(
        'POST',
        _url(verb),
        body,
        headers: {'authorization': 'Bearer $token'},
      ),
    );
  }

  @override
  Future<SealCiphertext> encrypt(List<int> plaintext, List<int> aad) async {
    final response = await _call('encrypt', {
      'plaintext': base64.encode(plaintext),
      'additionalAuthenticatedData': base64.encode(aad),
    });
    final ciphertext = response.jsonObject?['ciphertext'];
    if (!response.ok || ciphertext is! String) {
      throw const UpstreamUnavailable('kms encrypt');
    }
    return SealCiphertext(kmsKeyId, base64.decode(ciphertext));
  }

  @override
  Future<List<int>> decrypt(SealCiphertext ciphertext, List<int> aad) async {
    if (ciphertext.keyId != kmsKeyId) {
      throw const SealDecryptFailed();
    }
    final response = await _call('decrypt', {
      'ciphertext': base64.encode(ciphertext.bytes),
      'additionalAuthenticatedData': base64.encode(aad),
    });
    if (response.isTransient ||
        response.status == 401 ||
        response.status == 403) {
      // KMS itself is failing (or our token or IAM grant is): transient,
      // never a verdict on the seal.
      throw const UpstreamUnavailable('kms decrypt');
    }
    final plaintext = response.jsonObject?['plaintext'];
    if (!response.ok || plaintext is! String) {
      throw const SealDecryptFailed();
    }
    try {
      return base64.decode(plaintext);
    } on FormatException {
      throw const SealDecryptFailed();
    }
  }
}
